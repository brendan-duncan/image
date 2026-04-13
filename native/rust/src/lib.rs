use image::imageops::{self, FilterType};
use image::{ImageBuffer as RgbaImageBuffer, Rgba};
use std::cell::RefCell;
use std::ffi::{CStr, CString, c_char};
use std::ptr::{self, NonNull};
use std::slice;

const IMAGE_OK: i32 = 0;
const IMAGE_ERROR: i32 = 1;

#[repr(C)]
pub struct ImageBuffer {
    pub data: *mut u8,
    pub release_handle: *mut std::ffi::c_void,
    pub width: i32,
    pub height: i32,
    pub channels: i32,
    pub stride: i32,
}

#[repr(C)]
pub struct ImageResult {
    pub code: i32,
    pub buffer: ImageBuffer,
}

thread_local! {
    static LAST_ERROR: RefCell<Option<CString>> = const { RefCell::new(None) };
}

fn empty_buffer() -> ImageBuffer {
    ImageBuffer {
        data: ptr::null_mut(),
        release_handle: ptr::null_mut(),
        width: 0,
        height: 0,
        channels: 0,
        stride: 0,
    }
}

struct BufferRelease {
    ptr: NonNull<u8>,
    len: usize,
    capacity: usize,
}

fn success(mut data: Vec<u8>, width: i32, height: i32, channels: i32) -> ImageResult {
    let stride = width.saturating_mul(channels);
    let ptr = data.as_mut_ptr();
    let len = data.len();
    let capacity = data.capacity();
    let release_handle = Box::into_raw(Box::new(BufferRelease {
        ptr: NonNull::new(ptr).expect("vector pointer should not be null"),
        len,
        capacity,
    })) as *mut std::ffi::c_void;
    std::mem::forget(data);
    ImageResult {
        code: IMAGE_OK,
        buffer: ImageBuffer {
            data: ptr,
            release_handle,
            width,
            height,
            channels,
            stride,
        },
    }
}

fn error(message: impl Into<String>) -> ImageResult {
    let message = sanitize_message(message.into());
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() = Some(CString::new(message).expect("sanitized error message"));
    });
    ImageResult {
        code: IMAGE_ERROR,
        buffer: empty_buffer(),
    }
}

fn sanitize_message(message: String) -> String {
    if message.as_bytes().contains(&0) {
        message.replace('\0', " ")
    } else {
        message
    }
}

unsafe fn input_rgba_image<'a>(
    data: *const u8,
    width: i32,
    height: i32,
    channels: i32,
) -> Result<RgbaImageBuffer<Rgba<u8>, &'a [u8]>, String> {
    if data.is_null() {
        return Err("input buffer is null".to_string());
    }
    if width <= 0 || height <= 0 {
        return Err("image dimensions must be positive".to_string());
    }
    if channels != 4 {
        return Err(format!("expected 4 channels, got {channels}"));
    }

    let len = width as usize * height as usize * channels as usize;
    let bytes = unsafe { slice::from_raw_parts(data, len) };
    RgbaImageBuffer::from_raw(width as u32, height as u32, bytes)
        .ok_or_else(|| "failed to create RGBA image".to_string())
}

fn interpolation_filter(interpolation: i32) -> Result<FilterType, String> {
    match interpolation {
        0 => Ok(FilterType::Nearest),
        1 => Ok(FilterType::Triangle),
        value => Err(format!("unsupported interpolation value {value}")),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn image_resize_rgba8(
    data: *const u8,
    width: i32,
    height: i32,
    channels: i32,
    target_width: i32,
    target_height: i32,
    interpolation: i32,
) -> ImageResult {
    let filter = match interpolation_filter(interpolation) {
        Ok(filter) => filter,
        Err(message) => return error(message),
    };
    if target_width <= 0 || target_height <= 0 {
        return error("target dimensions must be positive");
    }

    let src = match unsafe { input_rgba_image(data, width, height, channels) } {
        Ok(image) => image,
        Err(message) => return error(message),
    };

    let resized = imageops::resize(&src, target_width as u32, target_height as u32, filter);
    success(resized.into_raw(), target_width, target_height, 4)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn image_crop_rgba8(
    data: *const u8,
    width: i32,
    height: i32,
    channels: i32,
    x: i32,
    y: i32,
    crop_width: i32,
    crop_height: i32,
) -> ImageResult {
    if crop_width <= 0 || crop_height <= 0 {
        return error("crop dimensions must be positive");
    }

    let src = match unsafe { input_rgba_image(data, width, height, channels) } {
        Ok(image) => image,
        Err(message) => return error(message),
    };

    let max_width = width.saturating_sub(x).max(0);
    let max_height = height.saturating_sub(y).max(0);
    let bounded_width = crop_width.min(max_width);
    let bounded_height = crop_height.min(max_height);

    if x < 0 || y < 0 || bounded_width <= 0 || bounded_height <= 0 {
        return error("crop rectangle is outside image bounds");
    }

    let cropped = imageops::crop_imm(
        &src,
        x as u32,
        y as u32,
        bounded_width as u32,
        bounded_height as u32,
    )
    .to_image();
    success(cropped.into_raw(), bounded_width, bounded_height, 4)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn image_free_buffer(release_handle: *mut std::ffi::c_void) {
    if release_handle.is_null() {
        return;
    }

    let release = unsafe { Box::from_raw(release_handle as *mut BufferRelease) };
    unsafe {
        let _ = Vec::from_raw_parts(release.ptr.as_ptr(), release.len, release.capacity);
    };
}

#[unsafe(no_mangle)]
pub extern "C" fn image_last_error_message() -> *const c_char {
    LAST_ERROR.with(|slot| {
        slot.borrow()
            .as_ref()
            .map(|message| message.as_ptr())
            .unwrap_or(CStr::from_bytes_with_nul(b"\0").unwrap().as_ptr())
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_rgba(width: i32, height: i32) -> Vec<u8> {
        let mut out = Vec::with_capacity((width * height * 4) as usize);
        for y in 0..height {
            for x in 0..width {
                out.extend_from_slice(&[x as u8 * 10, y as u8 * 20, 127, 255]);
            }
        }
        out
    }

    #[test]
    fn resize_returns_pixels() {
        let input = sample_rgba(2, 2);
        let result = unsafe { image_resize_rgba8(input.as_ptr(), 2, 2, 4, 4, 4, 0) };
        assert_eq!(result.code, IMAGE_OK);
        assert_eq!(result.buffer.width, 4);
        assert_eq!(result.buffer.height, 4);
        assert!(!result.buffer.data.is_null());
        unsafe {
            image_free_buffer(result.buffer.release_handle);
        }
    }

    #[test]
    fn crop_rejects_invalid_channels() {
        let input = sample_rgba(2, 2);
        let result = unsafe { image_crop_rgba8(input.as_ptr(), 2, 2, 3, 0, 0, 1, 1) };
        assert_eq!(result.code, IMAGE_ERROR);
        assert!(result.buffer.data.is_null());
    }
}

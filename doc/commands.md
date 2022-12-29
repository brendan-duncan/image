# Commands and Async Execution

The Command API allows sequences of image commands to be batched and optionally executed on a separate Isolate
thread.

```dart
final cmd = Command()
  ..decodePngFile('image.png')
  ..sepia(amount: 0.5)
  ..vignette()
  ..writeToFile('processedImage.png');
  // Nothing has actually been performed yet;
  // the commands have recorded the information necessary to execute later. 

const useIsolate = true;
if (useIsolate) {
  await cmd.executeThread(); // Executes in a separate Isolate thread.
} else {
  await cmd.execute(); // Executes in the main thread. It is still an async method because file IO is async.
}
```

## Executing Commands in Isolate Threads

Loading and manipulating images is expensive in terms of performance. Image files tend to be large, and Dart has limited
options for high performance execution. One way to help keep the performance issues from affecting your app is to use
multi-threading. For platforms that support it (not the web), Dart provides Isolates as its solution for
multi-threading.

The Command.executeThread() method will execute the commands in a separate isolate thread, resolving the promise when
it has finished. There is some performance overhead to running in an Isolate thread as it has to copy the Image data
from the Isolate to the main thread, but it has the benefit of not locking up the main thread. 

For platforms that do not support Isolates, executeThread will be the same as execute and run in the main thread.


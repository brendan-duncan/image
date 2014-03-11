part of image;

class ImfHeader {
  /*Header (int width = 64,
      int height = 64,
      float pixelAspectRatio = 1,
      const IMATH_NAMESPACE::V2f &screenWindowCenter = IMATH_NAMESPACE::V2f (0, 0),
      float screenWindowWidth = 1,
      LineOrder lineOrder = INCREASING_Y,
      Compression = ZIP_COMPRESSION);


    //--------------------------------------------------------------------
    // Constructor -- the data window is specified explicitly; the display
    // window is set to Box2i (V2i (0, 0), V2i (width-1, height-1).
    //--------------------------------------------------------------------

    Header (int width,
      int height,
      const IMATH_NAMESPACE::Box2i &dataWindow,
      float pixelAspectRatio = 1,
      const IMATH_NAMESPACE::V2f &screenWindowCenter = IMATH_NAMESPACE::V2f (0, 0),
      float screenWindowWidth = 1,
      LineOrder lineOrder = INCREASING_Y,
      Compression = ZIP_COMPRESSION);


    //----------------------------------------------------------
    // Constructor -- the display window and the data window are
    // both specified explicitly.
    //----------------------------------------------------------

    Header (const IMATH_NAMESPACE::Box2i &displayWindow,
      const IMATH_NAMESPACE::Box2i &dataWindow,
      float pixelAspectRatio = 1,
      const IMATH_NAMESPACE::V2f &screenWindowCenter = IMATH_NAMESPACE::V2f (0, 0),
      float screenWindowWidth = 1,
      LineOrder lineOrder = INCREASING_Y,
      Compression = ZIP_COMPRESSION);


    //-----------------
    // Copy constructor
    //-----------------

    Header (const Header &other);


    //-----------
    // Destructor
    //-----------

    ~Header ();


    //-----------
    // Assignment
    //-----------

    Header &      operator = (const Header &other);


    //---------------------------------------------------------------
    // Add an attribute:
    //
    // insert(n,attr) If no attribute with name n exists, a new
    //      attribute with name n, and the same type as
    //      attr, is added, and the value of attr is
    //      copied into the new attribute.
    //
    //      If an attribute with name n exists, and its
    //      type is the same as attr, the value of attr
    //      is copied into this attribute.
    //
    //      If an attribute with name n exists, and its
    //      type is different from attr, an IEX_NAMESPACE::TypeExc
    //      is thrown.
    //
    //---------------------------------------------------------------

    void      insert (const char name[],
                const Attribute &attribute);

    void      insert (const std::string &name,
                const Attribute &attribute);

    //---------------------------------------------------------------
    // Remove an attribute:
    //
    // remove(n)       If an attribute with name n exists, then it
    //                 is removed from the map of present attributes.
    //
    //                 If no attribute with name n exists, then this
    //                 functions becomes a 'no-op'
    //
    //---------------------------------------------------------------
    void                        erase (const char name[]);
    void                        erase (const std::string &name);



    //------------------------------------------------------------------
    // Access to existing attributes:
    //
    // [n]      Returns a reference to the attribute
    //        with name n.  If no attribute with
    //        name n exists, an IEX_NAMESPACE::ArgExc is thrown.
    //
    // typedAttribute<T>(n) Returns a reference to the attribute
    //        with name n and type T.  If no attribute
    //        with name n exists, an IEX_NAMESPACE::ArgExc is
    //        thrown.  If an attribute with name n
    //        exists, but its type is not T, an
    //        IEX_NAMESPACE::TypeExc is thrown.
    //
    // findTypedAttribute<T>(n) Returns a pointer to the attribute with
    //        name n and type T, or 0 if no attribute
    //        with name n and type T exists.
    //
    //------------------------------------------------------------------

    Attribute &     operator [] (const char name[]);
    const Attribute &   operator [] (const char name[]) const;

    Attribute &     operator [] (const std::string &name);
    const Attribute &   operator [] (const std::string &name) const;

    template <class T> T& typedAttribute (const char name[]);
    template <class T> const T& typedAttribute (const char name[]) const;

    template <class T> T& typedAttribute (const std::string &name);
    template <class T> const T& typedAttribute (const std::string &name) const;

    template <class T> T* findTypedAttribute (const char name[]);
    template <class T> const T* findTypedAttribute (const char name[]) const;

    template <class T> T* findTypedAttribute (const std::string &name);
    template <class T> const T* findTypedAttribute (const std::string &name)
                       const;

    //---------------------------------------------
    // Iterator-style access to existing attributes
    //---------------------------------------------

    typedef std::map <Name, Attribute *> AttributeMap;

    class Iterator;
    class ConstIterator;

    Iterator      begin ();
    ConstIterator   begin () const;

    Iterator      end ();
    ConstIterator   end () const;

    Iterator      find (const char name[]);
    ConstIterator   find (const char name[]) const;

    Iterator      find (const std::string &name);
    ConstIterator   find (const std::string &name) const;


    //--------------------------------
    // Access to predefined attributes
    //--------------------------------

    IMATH_NAMESPACE::Box2i &    displayWindow ();
    const IMATH_NAMESPACE::Box2i &  displayWindow () const;

    IMATH_NAMESPACE::Box2i &    dataWindow ();
    const IMATH_NAMESPACE::Box2i &  dataWindow () const;

    float &     pixelAspectRatio ();
    const float &   pixelAspectRatio () const;

    IMATH_NAMESPACE::V2f &    screenWindowCenter ();
    const IMATH_NAMESPACE::V2f &    screenWindowCenter () const;

    float &     screenWindowWidth ();
    const float &   screenWindowWidth () const;

    ChannelList &   channels ();
    const ChannelList &   channels () const;

    LineOrder &     lineOrder ();
    const LineOrder &   lineOrder () const;

    Compression &   compression ();
    const Compression &   compression () const;


    //-----------------------------------------------------
    // Access to required attributes for multipart files
    // They are optional to non-multipart files and mandatory
    // for multipart files.
    //-----------------------------------------------------
    void                        setName (const string& name);

    string&                     name();
    const string&               name() const;

    bool                        hasName() const;

    void                        setType (const string& Type);

    string&                     type();
    const string&               type() const;

    bool                        hasType() const;

    void                        setVersion (const int version);

    int&                        version();
    const int&                  version() const;

    bool                        hasVersion() const;

    //
    // the chunkCount attribute is set automatically when a file is written.
    // There is no need to set it manually
    //
    void                        setChunkCount(int chunks);
    bool                        hasChunkCount() const;
    const int &                 chunkCount() const;
    int &                       chunkCount();


    //
    // for multipart files, return whether the file has a view string attribute
    // (for the deprecated single part multiview format EXR, see ImfMultiView.h)
    //
    void                       setView(const string & view);
    bool                       hasView() const;
    string &                   view();
    const string &             view() const;


    //----------------------------------------------------------------------
    // Tile Description:
    //
    // The tile description is a TileDescriptionAttribute whose name
    // is "tiles".  The "tiles" attribute must be present in any tiled
    // image file. When present, it describes various properties of the
    // tiles that make up the file.
    //
    // Convenience functions:
    //
    // setTileDescription(td)
    //     calls insert ("tiles", TileDescriptionAttribute (td))
    //
    // tileDescription()
    //     returns typedAttribute<TileDescriptionAttribute>("tiles").value()
    //
    // hasTileDescription()
    //     return findTypedAttribute<TileDescriptionAttribute>("tiles") != 0
    //
    //----------------------------------------------------------------------

    void      setTileDescription (const TileDescription & td);

    TileDescription &   tileDescription ();
    const TileDescription & tileDescription () const;

    bool      hasTileDescription() const;


    //----------------------------------------------------------------------
    // Preview image:
    //
    // The preview image is a PreviewImageAttribute whose name is "preview".
    // This attribute is special -- while an image file is being written,
    // the pixels of the preview image can be changed repeatedly by calling
    // OutputFile::updatePreviewImage().
    //
    // Convenience functions:
    //
    // setPreviewImage(p)
    //     calls insert ("preview", PreviewImageAttribute (p))
    //
    // previewImage()
    //     returns typedAttribute<PreviewImageAttribute>("preview").value()
    //
    // hasPreviewImage()
    //     return findTypedAttribute<PreviewImageAttribute>("preview") != 0
    //
    //----------------------------------------------------------------------

    void      setPreviewImage (const PreviewImage &p);

    PreviewImage &    previewImage ();
    const PreviewImage &  previewImage () const;

    bool      hasPreviewImage () const;


    //-------------------------------------------------------------
    // Sanity check -- examines the header, and throws an exception
    // if it finds something wrong (empty display window, negative
    // pixel aspect ratio, unknown compression sceme etc.)
    //
    // set isTiled to true if you are checking a tiled/multi-res
    // header
    //-------------------------------------------------------------

    void      sanityCheck (bool isTiled = false,
                           bool isMultipartFile = false) const;


    //----------------------------------------------------------------
    // Maximum image size and maximim tile size:
    //
    // sanityCheck() will throw an exception if the width or height of
    // the data window exceeds the maximum image width or height, or
    // if the size of a tile exceeds the maximum tile width or height.
    //
    // At program startup the maximum image and tile width and height
    // are set to zero, meaning that width and height are unlimited.
    //
    // Limiting image and tile width and height limits how much memory
    // will be allocated when a file is opened.  This can help protect
    // applications from running out of memory while trying to read
    // a damaged image file.
    //----------------------------------------------------------------

    static void     setMaxImageSize (int maxWidth, int maxHeight);
    static void     setMaxTileSize (int maxWidth, int maxHeight);

    //
    // Check if the header reads nothing.
    //
    bool                        readsNothing();


    //------------------------------------------------------------------
    // Input and output:
    //
    // If the header contains a preview image attribute, then writeTo()
    // returns the position of that attribute in the output stream; this
    // information is used by OutputFile::updatePreviewImage().
    // If the header contains no preview image attribute, then writeTo()
    // returns 0.
    //------------------------------------------------------------------


    Int64     writeTo (OPENEXR_IMF_INTERNAL_NAMESPACE::OStream &os,
           bool isTiled = false) const;

  void readFrom(InputStream input, int version);


  AttributeMap _map;

  bool _readsNothing;*/
}

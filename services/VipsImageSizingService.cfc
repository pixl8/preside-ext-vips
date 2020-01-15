/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          boolean maintainAspectRatio = false
		,          string  focalPoint          = ""
		,          struct  cropHintArea        = {}
		,          boolean useCropHint         = false
		,          struct  fileProperties      = {}
	) {
		try {
			var vipsImage = _getVipsImage( arguments.asset );

			if ( vipsImage.getWidth() == arguments.width && wipsImage.getHeight() == arguments.height ) {
				return arguments.asset;
			}

			vipsImage.autoRotate();


			if ( !arguments.height ) {
				_scaleToFit( vipsImage, arguments.width, 0 );
			} else if ( !arguments.width ) {
				_scaleToFit( vipsImage, 0, arguments.height );
			} else {
				var requiresResize = true;

				if ( arguments.useCropHint && !arguments.cropHintArea.isEmpty() ) {
					vipsImage.crop( _getRectangle( argumentCollection=arguments.cropHintArea ) );
				} else {
					if ( maintainAspectRatio ) {
						var currentAspectRatio = vipsImage.getWidth() / vipsImage.getHeight();
						var targetAspectRatio  = arguments.width / arguments.height;

						if ( targetAspectRatio != currentAspectRatio ) {
							if ( currentAspectRatio > targetAspectRatio ) {
								_scaleToFit( vipsImage, 0, arguments.height );
							} else {
								_scaleToFit( vipsImage, arguments.width, 0 );
							}
							vipsImage.crop( _getFocalPointRectangle( argumentCollection=arguments, vipsImage=vipsImage ) );
							requiresResize = false;
						}
					}
				}

				if ( requiresResize ) {
					var newDimensions = _getDimension( arguments.width, arguments.height );
					var scale         = JavaCast( "boolean", !arguments.maintainAspectRatio );

					vipsImage.resize( newDimensions, scale );
				}
			}

			var newFileType = _getOutputFileType( arguments.fileProperties );
			var stripMeta   = JavaCast( "boolean", true );
			var binary      = vipsImage.writeToArray( newFileType, stripMeta );

		} catch( any e ) {
			rethrow;
		} finally {
			vipsImage.release();
		}

		return binary;
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          struct  fileProperties      = {}
	) {
		try {
			var vipsImage = _getVipsImage( arguments.asset );
			if ( vipsImage.getWidth() <= arguments.width && vipsImage.getHeight() <= arguments.height ) {
				return arguments.asset;
			}

			var currentAspectRatio = vipsImage.getWidth() / vipsImage.getHeight();
			var targetAspectRatio  = arguments.width / arguments.height;

			if ( targetAspectRatio == currentAspectRatio ) {
				var newDimensions = _getDimension( arguments.width, arguments.height );
				var scale         = JavaCast( "boolean", false );

				vipsImage.resize( newDimensions, scale );
			} else if ( currentAspectRatio > targetAspectRatio ) {
				_scaleToFit( vipsImage, 0, arguments.height );
			} else {
				_scaleToFit( vipsImage, arguments.width, 0 );
			}

			if ( vipsImage.getWidth() > arguments.width ) {
				_scaleToFit( vipsImage, arguments.width, 0 );
			} else if ( vipsImage.getHeight() > arguments.height ){
				_scaleToFit( vipsImage, 0, arguments.height );
			}

			var newFileType   = _getOutputFileType( arguments.fileProperties );
			var stripMeta     = JavaCast( "boolean", true );

			var binary = vipsImage.writeToArray( newFileType, stripMeta );
		} catch( any e ) {
			rethrow;
		} finally {
			vipsImage.release();
		}

		return binary;
	}

// PRIVATE HELPERS
	private any function _getFocalPointRectangle(
		  required any     vipsImage
		, required numeric width
		, required numeric height
		, required string  focalPoint
	) {
		var originX     = 0;
		var originY     = 0;
		var cropCentreX = originX + int( arguments.width  / 2 );
		var cropCentreY = originY + int( arguments.height / 2 );
		var focalPoint  = len( arguments.focalPoint ) ? arguments.focalPoint : "0.5,0.5";
		var focalPointX = int( listFirst( focalPoint ) * vipsImage.getWidth()  );
		var focalPointY = int( listLast(  focalPoint ) * vipsImage.getHeight() );

		if ( focalPointX > cropCentreX ) {
			originX = min( originX + ( focalPointX - cropCentreX ), vipsImage.getWidth() - arguments.width );
		}
		if ( focalPointY > cropCentreY ) {
			originY = min( originY + ( focalPointY - cropCentreY ), vipsImage.getHeight() - arguments.height );
		}

		return _getRectangle( originX, originY, arguments.width, arguments.height );
	}

	private void function _scaleToFit(
		  required any     vipsImage
		, required numeric width
		, required numeric height
	) {
		if ( !arguments.height ) {
			arguments.height = vipsImage.getHeight() * ( arguments.width / vipsImage.getWidth() );
		} else if ( !arguments.width ) {
			arguments.width = vipsImage.getWidth() * ( arguments.height / vipsImage.getHeight() );
		}
		var newDimensions = _getDimension( arguments.width, arguments.height );
		var scale         = JavaCast( "boolean", false );

		vipsImage.resize( newDimensions, scale );
	}

	private any function _getVipsImage( required binary imageBinary ) {
		return _jvipsObj( "VipsImageImpl" ).init( arguments.imageBinary, JavaCast( "int", Len( arguments.imageBinary ) ) );
	}

	private any function _getOutputFileType( required struct fileProperties ) {
		switch( arguments.fileProperties.fileExt ?: "" ){
			case "png":
			case "gif":
				arguments.fileProperties.fileExt = "png";
				return _jvipsObj( "ImageFormat" ).PNG;
		}

		arguments.fileProperties.fileExt = "jpg";
		return _jvipsObj( "ImageFormat" ).JPG;
	}

	private any function _getDimension( required numeric width, required numeric height ) {
		return CreateObject( "java", "java.awt.Dimension" ).init( JavaCast( "int", arguments.width ), JavaCast( "int", arguments.height ) );
	}

	private any function _getRectangle( required numeric x, required numeric y, required numeric width, required numeric height ) {
		return CreateObject( "java", "java.awt.Rectangle" ).init( JavaCast( "int", arguments.x ), JavaCast( "int", arguments.y ), JavaCast( "int", arguments.width ), JavaCast( "int", arguments.height ) );
	}

	private any function _jvipsObj( required string className ) {
		return CreateObject( "java", "com.criteo.vips.#arguments.className#", _getLib() );
	}

	private array function _getLib() {
		return _lib ?: _initLib();
	}

	private array function _initLib() {
		var libDir = ExpandPath( "/app/extensions/preside-ext-vips/services/lib" );
		variables._lib = DirectoryList( libDir, false, "path", "*.jar" );

		return variables._lib;
	}

// GETTERS AND SETTERS

}
/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @vipsSettings.inject    coldbox:setting:vips
	 *
	 */
	public any function init( required struct vipsSettings ) {
		_setBinDir( arguments.vipsSettings.binDir ?: "/usr/bin" );
		_setTimeout( Val( arguments.vipsSettings.timeout ?: 60 ) );
		_setVipsTmpDirectory( GetTempDirectory() & "/vips/" );

		return this;
	}

// PUBLIC API METHODS
	public string function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
		,          string  focalPoint          = ""
		,          boolean autoFocalPoint      = false
		,          struct  cropHintArea        = {}
		,          boolean useCropHint         = false
		,          string  outputFormat        = ""
		,          struct  fileProperties      = {}
	) {
		var originalFileExt = fileProperties.fileExt ?: "";
		var isSvg           = originalFileExt == "svg";
		var isGif           = originalFileExt == "gif";

		if ( isSvg ) {
			fileProperties.fileExt = "png";
		}
		if ( len( arguments.outputFormat ) ) {
			fileProperties.fileExt = arguments.outputFormat;
		}

		var sourceFile         = _tmpFile( arguments.asset );
		var targetFile         = sourceFile & "_#CreateUUId()#.#( fileProperties.fileExt ?: '' )#";
		var imageInfo          = getImageInformation( filePath=sourceFile );
		var vipsQuality        = _cfToVipsQuality( arguments.quality, fileProperties.fileExt ?: "" );
		var requiresConversion = ( fileProperties.fileExt ?: "" ) != originalFileExt;

		if ( imageInfo.width == arguments.width && imageInfo.height == arguments.height && !requiresConversion ) {
			return arguments.asset;
		}

		FileCopy( sourceFile, targetFile );
		if ( imageInfo.requiresOrientation || isGif ) {
			targetFile = _autoRotate( targetFile, vipsQuality );
		}

		if ( !arguments.height ) {
			targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0, vipsQuality );
		} else if ( !arguments.width ) {
			targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height, vipsQuality );
		} else {
			var requiresResize    = true;
			var useAutoFocalPoint = false;

			if ( arguments.useCropHint && !arguments.cropHintArea.isEmpty() ) {
				targetFile = _crop( targetFile, imageInfo, arguments.cropHintArea, vipsQuality );
				imageInfo  = getImageInformation( filePath=targetFile );
			} else {
				if ( maintainAspectRatio ) {
					var currentAspectRatio = imageInfo.width / imageInfo.height;
					var targetAspectRatio  = arguments.width / arguments.height;
					useAutoFocalPoint      = arguments.autoFocalPoint && !len( arguments.focalPoint );

					if ( targetAspectRatio != currentAspectRatio && !useAutoFocalPoint ) {
						if ( currentAspectRatio > targetAspectRatio ) {
							targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height, vipsQuality );
						} else {
							targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0, vipsQuality );
						}

						imageInfo = getImageInformation( filePath=targetFile );
						targetFile = _cropToFocalPoint( argumentCollection=arguments, targetFile=targetFile, imageInfo=imageInfo, vipsQuality=vipsQuality );
						requiresResize = false;
					}
				}
			}

			if ( requiresResize ) {
				targetFile = _thumbnail( targetFile, imageInfo, arguments.width, arguments.height, vipsQuality, useAutoFocalPoint );
			}
		}

		var binary = FileReadBinary( targetFile );
		_deleteFile( targetFile );
		return binary;
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          string  quality        = "highPerformance"
		,          string  outputFormat   = ""
		,          struct  fileProperties = {}
	) {
		var originalFileExt = fileProperties.fileExt ?: "";
		var isSvg           = originalFileExt == "svg";
		var isGif           = originalFileExt == "gif";

		if ( isSvg ) {
			fileProperties.fileExt = "png";
		}
		if ( len( arguments.outputFormat ) ) {
			fileProperties.fileExt = arguments.outputFormat;
		}

		var sourceFile         = _tmpFile( arguments.asset );
		var targetFile         = sourceFile & "_#CreateUUId()#.#( fileProperties.fileExt ?: '' )#";
		var imageInfo          = getImageInformation( filePath=sourceFile );
		var vipsQuality        = _cfToVipsQuality( arguments.quality, fileProperties.fileExt ?: "" );
		var requiresConversion = ( fileProperties.fileExt ?: "" ) != originalFileExt;

		if ( imageInfo.width <= arguments.width && imageInfo.height <= arguments.height && !requiresConversion ) {
			return arguments.asset;
		}

		FileCopy( sourceFile, targetFile );
		if ( imageInfo.requiresOrientation || isGif ) {
			targetFile = _autoRotate( targetFile, vipsQuality );
			imageInfo  = getImageInformation( filePath=targetFile );
		}

		var currentAspectRatio = imageInfo.width / imageInfo.height;
		var targetAspectRatio  = arguments.width / arguments.height;
		var requiresShrinking  = imageInfo.width > arguments.width || imageInfo.height > arguments.height;

		if ( requiresShrinking ) {
			if ( targetAspectRatio == currentAspectRatio ) {
				targetFile = _thumbnail( targetFile, imageInfo, arguments.width, arguments.height, vipsQuality );
			} else if ( currentAspectRatio > targetAspectRatio ) {
				targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height, vipsQuality );
			} else {
				targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0, vipsQuality );
			}

			imageInfo = getImageInformation( filePath=targetFile );

			if ( imageInfo.width > arguments.width ) {
				targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0, vipsQuality );
			} else if ( imageInfo.height > arguments.height ){
				targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height, vipsQuality );
			}
		} else if ( requiresConversion ) {
			targetFile = _thumbnail( targetFile, imageInfo, imageInfo.width, imageInfo.height, vipsQuality );
		}

		var binary = FileReadBinary( targetFile );
		_deleteFile( targetFile );

		return binary;
	}

	public struct function getImageInformation( binary asset, string filePath=_tmpFile( arguments.asset ) ) {
		var rawInfo = Trim( _exec( command="vipsheader", args='-a "#arguments.filePath#"' ) );
		var info = {};
		var key = "";
		var value = "";

		for( var line in ListToArray( rawInfo, Chr(10) & Chr(13) ) ) {
			if ( ListLen( line, ":" ) > 1 ) {
				info[ Trim( ListFirst( line, ":" ) ) ] = Trim( ListRest( line, ":" ) );
			}
		}

		if ( Val( info.width ?: "" ) && Val( info.height ?: "" ) ) {
			var orientation = Val( info.orientation ?: ( info[ "exif-ifd0-Orientation" ] ?: 1 ) );

			if ( orientation == 8 || orientation == 6 ) {
				info.requiresOrientation = true;
				var tmpWidth = info.width;
				info.width = info.height;
				info.height = tmpWidth;
			} else {
				info.requiresOrientation = false;
			}

			return info;
		}

		throw( type="AssetTransformer.shrinkToFit.notAnImage" );
	}

	public struct function getCropHintArea(
		  required binary  image
		, required numeric width
		, required numeric height
		, required string  cropHint
	) {
		var imageInfo      = getImageInformation( arguments.image );
		var targetWidth    = arguments.width;
		var targetHeight   = arguments.height;
		var targetRatio    = targetWidth / targetHeight;
		var cropHintCoords = arguments.cropHint.listToArray();
		var cropX          = int( cropHintCoords[ 1 ] * imageInfo.width );
		var cropY          = int( cropHintCoords[ 2 ] * imageInfo.height );
		var cropWidth      = int( cropHintCoords[ 3 ] * imageInfo.width );
		var cropHeight     = int( cropHintCoords[ 4 ] * imageInfo.height );
		var cropHintRatio  = cropWidth / cropHeight;
		var prevCropWidth  = 0;
		var prevCropHeight = 0;
		var widthRatio     = 0;
		var heightRatio    = 0;

		if ( cropHintRatio > targetRatio ) {
			prevCropHeight = cropHeight;
			cropHeight     = int( cropHeight * ( cropHintRatio / targetRatio ) );
			cropY          = int( cropY - ( ( cropHeight - prevCropHeight ) / 2 ) );
		} else if ( cropHintRatio < targetRatio ) {
			prevCropWidth = cropWidth;
			cropWidth     = int( cropWidth * ( targetRatio / cropHintRatio ) );
			cropX         = int( cropX - ( ( cropWidth - prevCropWidth ) / 2 ) );
		}

		if ( targetWidth > cropWidth ) {
			prevCropWidth  = cropWidth;
			widthRatio     = targetWidth / cropWidth;
			cropWidth      = int( cropWidth  * widthRatio );
			cropX          = int( cropX - ( ( cropWidth  - prevCropWidth ) / 2 ) );
		}
		if ( targetHeight > cropHeight ) {
			prevCropHeight = cropHeight;
			heightRatio    = targetHeight / cropHeight;
			cropHeight     = int( cropHeight * heightRatio );
			cropY          = int( cropY - ( ( cropHeight - prevCropHeight ) / 2 ) );
		}


		if ( cropWidth > imageInfo.width || cropHeight > imageInfo.height ) {
			var fitRatio   = min( imageInfo.width / cropWidth, imageInfo.height / cropHeight );
			prevCropWidth  = cropWidth;
			prevCropHeight = cropHeight;
			cropWidth      = int( cropWidth  * fitRatio );
			cropX          = int( cropX - ( ( cropWidth  - prevCropWidth ) / 2 ) );
			cropHeight     = int( cropHeight * fitRatio );
			cropY          = int( cropY - ( ( cropHeight - prevCropHeight ) / 2 ) );
		}

		cropX = max( cropX, 0 );
		cropY = max( cropY, 0 );
		cropX = min( cropX, imageInfo.width - cropWidth );
		cropY = min( cropY, imageInfo.height - cropHeight );

		return {
			  x      = cropX
			, y      = cropY
			, width  = cropWidth
			, height = cropHeight
		}
	}

// PRIVATE HELPERS
	private string function _exec( required string command, required string args ) {
		var result  = "";

		execute name      = _getBinDir() & arguments.command
				arguments = arguments.args
				timeout   = _getTimeout()
				variable  = "result";

		return result;
	}

	private string function _tmpFile( required binary asset ) {
		var filePath = _getVipsTmpDirectory() & Hash( asset );

		if ( !FileExists( filePath ) ) {
			FileWrite( filePath, arguments.asset );
		}

		return filePath;
	}

	private number function _int( required numeric value ) {
		return numberFormat( arguments.value, "0" );
	}

	private string function _cfToVipsQuality( required string quality, required string fileExtension ) {
		var pngExtensions = [ "gif", "png" ];

		if ( ArrayFindNoCase( [ "gif", "png" ], arguments.fileExtension ) ) {
			switch( arguments.quality ) {
				case "highestQuality":
					return "compression=3";

				case "highQuality":
				case "mediumPerformance":
					return "compression=5";

				case "mediumQuality":
				case "highPerformance":
					return "compression=6";

				case "highestPerformance":
					return "compression=9";
				default:
					return "compression=6";
			}
		}

		switch( arguments.quality ) {
			case "highestQuality":
				return "Q=95";

			case "highQuality":
			case "mediumPerformance":
				return "Q=85";

			case "mediumQuality":
			case "highPerformance":
				return "Q=80";

			case "highestPerformance":
				return "Q=75";
		}

		return "Q=80";
	}

	private struct function _getFocalPointRectangle(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  focalPoint
	) {
		var originX     = 0;
		var originY     = 0;
		var cropCentreX = originX + _int( arguments.width  / 2 );
		var cropCentreY = originY + _int( arguments.height / 2 );
		var focalPoint  = len( arguments.focalPoint ) ? arguments.focalPoint : "0.5,0.5";
		var focalPointX = _int( listFirst( focalPoint ) * imageInfo.width  );
		var focalPointY = _int( listLast(  focalPoint ) * imageInfo.height );

		if ( focalPointX > cropCentreX ) {
			originX = min( originX + ( focalPointX - cropCentreX ), imageInfo.width - arguments.width );
		}
		if ( focalPointY > cropCentreY ) {
			originY = min( originY + ( focalPointY - cropCentreY ), imageInfo.height - arguments.height );
		}

		return {
			  x      = originX
			, y      = originY
			, width  = arguments.width
			, height = arguments.height
		};
	}

	private string function _scaleToFit(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  vipsQuality
	) {
		if ( !arguments.height ) {
			arguments.height = imageInfo.height * ( arguments.width / imageInfo.width );
		} else if ( !arguments.width ) {
			arguments.width = imageInfo.width * ( arguments.height / imageInfo.height );
		}

		return _thumbnail( argumentCollection=arguments );
	}

	private string function _thumbnail(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  vipsQuality
		,          boolean smartcrop = false
	){
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "tn_" );
		var outputFormat  = "tn_%s.#ListLast( newTargetFile, '.' )#";
		var size          = "#_int( arguments.width )#x#_int( arguments.height )#";
		var smartcrop     = arguments.smartcrop ? "--smartcrop attention" : "";

		try {
			_exec( "vipsthumbnail", """#arguments.targetFile#"" -s #size# #smartcrop# -d -o ""#outputFormat#[#arguments.vipsQuality#,strip]""" );
		} finally {
			_deleteFile( arguments.targetFile );
		}

		return newTargetFile;
	}

	private string function _crop(
		  required string  targetFile
		, required struct  imageInfo
		, required struct  cropArea
		, required string  vipsQuality
	) {
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "crop_" );
		try {
			_exec( "vips", 'crop "#targetFile#" """#newTargetFile#[#arguments.vipsQuality#,strip]""" #_int( cropArea.x )# #_int( cropArea.y )# #_int( cropArea.width )# #_int( cropArea.height )#' );
		} finally {
			_deleteFile( arguments.targetFile );
		}

		return newTargetFile;
	}

	private string function _cropToFocalPoint(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  focalPoint
		, required boolean autoFocalPoint
		, required string  vipsQuality
	) {
		if ( autoFocalPoint && !len( focalPoint ) ) {
			return targetFile;
		}
		var rectangle = _getFocalPointRectangle( argumentCollection=arguments );

		if ( rectangle.x < 0 || ( rectangle.x + rectangle.width ) > imageInfo.width ) {
			return targetFile;
		}
		if ( rectangle.y < 0 || ( rectangle.y + rectangle.height ) > imageInfo.height ) {
			return targetFile;
		}

		return _crop( targetFile, imageInfo, rectangle, vipsQuality );
	}

	private string function _autoRotate(
		  required string targetFile
		, required string vipsQuality
	) {
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "crop_" ).reReplace( "\.gif$", ".png" );
		try {
			_exec( "vips", 'autorot "#targetFile#" """#newTargetFile#[#arguments.vipsQuality#]"""' );
		} finally {
			_deleteFile( arguments.targetFile );
		}

		return newTargetFile;
	}

	private void function _deleteFile( required string path ) {
		try {
			FileDelete( arguments.path );
		} catch( any e ) {}
	}

	private string function _pathFileNamePrefix( required string path, required string prefix ) {
		var fileName = ListLast( arguments.path, "\/" );
		var dirName = GetDirectoryFromPath( arguments.path );

		return dirName & arguments.prefix & fileName;
	}

// GETTERS AND SETTERS
	private string function _getVipsTmpDirectory() {
		return _vipsTmpDirectory;
	}
	private void function _setVipsTmpDirectory( required string vipsTmpDirectory ) {
		_vipsTmpDirectory = arguments.vipsTmpDirectory;

		DirectoryCreate( _vipsTmpDirectory, true, true );
	}

	private string function _getBinDir() {
		return _binDir;
	}
	private void function _setBinDir( required string binDir ) {
		_binDir = arguments.binDir;
		_binDir = Replace( _binDir, "\", "/", "all" );
		_binDir = ReReplace( _binDir, "([^/])$", "\1/" );
	}

	private numeric function _getTimeout() {
		return _timeout;
	}
	private void function _setTimeout( required numeric timeout ) {
		_timeout = arguments.timeout;
	}
}
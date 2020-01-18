/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @svgToPngService.inject svgToPngService
	 * @vipsSettings.inject    coldbox:setting:vips
	 *
	 */
	public any function init( required any svgToPngService, required struct vipsSettings ) {
		_setSvgToPngService( arguments.svgToPngService );
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
		,          boolean maintainAspectRatio = false
		,          string  focalPoint          = ""
		,          struct  cropHintArea        = {}
		,          boolean useCropHint         = false
		,          struct  fileProperties      = {}
	) {
		var isSvg = ( fileProperties.fileExt ?: "" ) == "svg";
		if ( isSvg ) {
			arguments.asset = _getSvgToPngService().SVGToPngBinary( arguments.asset, arguments.width, arguments.height );
			fileProperties.fileExt = "png";

			return arguments.asset;
		}

		var sourceFile = _tmpFile( arguments.asset );
		var targetFile = sourceFile & "_#CreateUUId()#.#( fileProperties.fileExt ?: '' )#";
		var imageInfo  = getImageInformation( filePath=sourceFile );

		if ( imageInfo.width == arguments.width && imageInfo.height == arguments.height ) {
			return arguments.asset;
		}

		FileCopy( sourceFile, targetFile );
		if ( imageInfo.requiresOrientation ) {
			targetFile = _autoRotate( targetFile );
		}

		if ( !arguments.height ) {
			targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0 );
		} else if ( !arguments.width ) {
			targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height );
		} else {
			var requiresResize = true;

			if ( arguments.useCropHint && !arguments.cropHintArea.isEmpty() ) {
				targetFile = _crop( targetFile, imageInfo, arguments.cropHintArea );
				imageInfo = getImageInformation( filePath=targetFile );
			} else {
				if ( maintainAspectRatio ) {
					var currentAspectRatio = imageInfo.width / imageInfo.height;
					var targetAspectRatio  = arguments.width / arguments.height;

					if ( targetAspectRatio != currentAspectRatio ) {
						if ( currentAspectRatio > targetAspectRatio ) {
							targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height );
						} else {
							targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0 );
						}

						imageInfo = getImageInformation( filePath=targetFile );
						targetFile = _cropToFocalPoint( argumentCollection=arguments, targetFile=targetFile, imageInfo=imageInfo );
						requiresResize = false;
					}
				}
			}

			if ( requiresResize ) {
				targetFile = _thumbnail( targetFile, imageInfo, arguments.width, arguments.height );
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
		,          struct  fileProperties      = {}
	) {
		var isSvg = ( fileProperties.fileExt ?: "" ) == "svg";
		if ( isSvg ) {
			arguments.asset = _getSvgToPngService().SVGToPngBinary( arguments.asset, arguments.width, arguments.height );
			fileProperties.fileExt = "png";

			return arguments.asset;
		}

		var sourceFile = _tmpFile( arguments.asset );
		var targetFile = sourceFile & "_#CreateUUId()#.#( fileProperties.fileExt ?: '' )#";
		var imageInfo  = getImageInformation( filePath=sourceFile );

		if ( imageInfo.width <= arguments.width && imageInfo.height <= arguments.height ) {
			return arguments.asset;
		}

		FileCopy( sourceFile, targetFile );
		if ( imageInfo.requiresOrientation ) {
			targetFile = _autoRotate( targetFile );
		}

		var currentAspectRatio = imageInfo.width / imageInfo.height;
		var targetAspectRatio  = arguments.width / arguments.height;

		if ( targetAspectRatio == currentAspectRatio ) {
			targetFile = _thumbnail( targetFile, imageInfo, arguments.width, arguments.height );
		} else if ( currentAspectRatio > targetAspectRatio ) {
			targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height );
		} else {
			targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0 );
		}

		imageInfo = getImageInformation( filePath=targetFile );

		if ( imageInfo.width > arguments.width ) {
			targetFile = _scaleToFit( targetFile, imageInfo, arguments.width, 0 );
		} else if ( imageInfo.height > arguments.height ){
			targetFile = _scaleToFit( targetFile, imageInfo, 0, arguments.height );
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

	private struct function _getFocalPointRectangle(
		  required string  targetFile
		, required struct  imageInfo
		, required numeric width
		, required numeric height
		, required string  focalPoint
	) {
		var originX     = 0;
		var originY     = 0;
		var cropCentreX = originX + int( arguments.width  / 2 );
		var cropCentreY = originY + int( arguments.height / 2 );
		var focalPoint  = len( arguments.focalPoint ) ? arguments.focalPoint : "0.5,0.5";
		var focalPointX = int( listFirst( focalPoint ) * imageInfo.width  );
		var focalPointY = int( listLast(  focalPoint ) * imageInfo.height );

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
	){
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "tn_" );
		var outputFormat  = "tn_%s.#ListLast( newTargetFile, '.' )#";
		try {
			_exec( "vipsthumbnail", "-s #arguments.width#x#arguments.height# -d -o #outputFormat# ""#arguments.targetFile#""" );
		} finally {
			_deleteFile( arguments.targetFile );
		}

		return newTargetFile;
	}

	private string function _crop(
		  required string  targetFile
		, required struct  imageInfo
		, required struct  cropArea
	) {
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "crop_" );
		try {
			_exec( "vips", 'crop "#targetFile#" "#newTargetFile#" #cropArea.x# #cropArea.y# #cropArea.width# #cropArea.height#' );
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
	) {
		var rectangle = _getFocalPointRectangle( argumentCollection=arguments );

		if ( rectangle.x < 0 || ( rectangle.x + rectangle.width ) > imageInfo.width ) {
			return targetFile;
		}
		if ( rectangle.y < 0 || ( rectangle.y + rectangle.height ) > imageInfo.height ) {
			return targetFile;
		}

		return _crop( targetFile, imageInfo, rectangle );
	}

	private string function _autoRotate( required string targetFile ) {
		var newTargetFile = _pathFileNamePrefix( arguments.targetFile, "crop_" );
		try {
			_exec( "vips", 'autorot "#targetFile#" "#newTargetFile#"' );
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
	private any function _getSvgToPngService() {
		return _svgToPngService;
	}
	private void function _setSvgToPngService( required any svgToPngService ) {
		_svgToPngService = arguments.svgToPngService;
	}

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
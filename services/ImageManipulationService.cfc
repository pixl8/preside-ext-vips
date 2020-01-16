component extends="preside.system.services.assetManager.ImageManipulationService" {

	/**
     * @nativeImageImplementation.inject nativeImageService
     * @imageMagickImplementation.inject imageMagickService
     * @vipsImageSizingService.inject    vipsImageSizingService
     *
     */
    public any function init(
          required any nativeImageImplementation
        , required any imageMagickImplementation
        , required any vipsImageSizingService
    ) {
    	super.init( argumentCollection=arguments );

    	_setVipsImageSizingService( arguments.vipsImageSizingService )

        return this;
    }


	public struct function getImageInformation( required binary asset ) {
		return _getVipsImageSizingService( ).getImageInformation( arguments.asset );
	}

// PRIVATE
	private any function _getVipsImageSizingService() {
	    return _vipsImageSizingService;
	}
	private void function _setVipsImageSizingService( required any vipsImageSizingService ) {
	    _vipsImageSizingService = arguments.vipsImageSizingService;
	}

}
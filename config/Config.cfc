component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		settings.vips = settings.vips ?: {};
		settings.vips.binDir  = settings.env.VIPS_BINDIR ?: ( settings.vips.binDir ?: "/usr/bin" );
		settings.vips.timeout = Val( settings.env.VIPS_TIMEOUT ?: ( settings.vips.timeout ?: 60 ) );

		settings.assetManager.types.image.webp = { serveAsAttachment=false, mimeType="image/webp" };
	}

}

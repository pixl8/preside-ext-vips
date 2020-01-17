component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		settings.vips = settings.vips ?: {};
		settings.vips.binDir  = settings.vips.binDir ?: "/usr/bin";
		settings.vips.timeout = Val( settings.vips.timeout ?: 60 );
	}

}

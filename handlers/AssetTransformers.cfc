component {
	property name="vipsImageSizingService" inject="vipsImageSizingService";

	private binary function resize( event, rc, prc, args={} ) {
		var useCropHint = isTrue( args.useCropHint ?: "" );
		var cropHint    = args.cropHint ?: "";

		if ( useCropHint && cropHint.len() ) {
			args.cropHintArea = vipsImageSizingService.getCropHintArea(
				  image    = args.asset
				, width    = args.width  ?: 0
				, height   = args.height ?: 0
				, cropHint = cropHint
			);
		}
		return vipsImageSizingService.resize( argumentCollection=args );
	}

	private binary function shrinkToFit( event, rc, prc, args={} ) {
		return vipsImageSizingService.shrinkToFit( argumentCollection=args );
	}

}
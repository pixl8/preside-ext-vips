component {
	property name="vipsImageSizingService" inject="vipsImageSizingService";

	private binary function resize( event, rc, prc, args={} ) {
		if ( args.useCropHint && args.cropHint.len() ) {
			args.cropHintArea = vipsImageSizingService.getCropHintArea(
				  image    = args.asset
				, width    = args.width
				, height   = args.height
				, cropHint = args.cropHint
			);
		}
		return vipsImageSizingService.resize( argumentCollection=args );
	}

	private binary function shrinkToFit( event, rc, prc, args={} ) {
		return vipsImageSizingService.shrinkToFit( argumentCollection=args );
	}

}
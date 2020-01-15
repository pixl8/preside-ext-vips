component {
	property name="vipsImageSizingService" inject="vipsImageSizingService";

	private binary function resize( event, rc, prc, args={} ) {
		return vipsImageSizingService.resize( argumentCollection=args );
	}

	private binary function shrinkToFit( event, rc, prc, args={} ) {
		return vipsImageSizingService.shrinkToFit( argumentCollection=args );
	}

}
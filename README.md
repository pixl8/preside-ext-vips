# VIPS Image processor

This extension swaps out the ImageMagick/native lucee implementation of image resizing in favour of using [libvips](https://libvips.github.io/libvips/).

## Pre-requisites and configuration

It is expected that [libvips](https://libvips.github.io/libvips/) be installed on your system, along with `libexif`. For example, on Ubuntu:

```bash
apt install libvips libvips-tools libexif12
```

Once installed, you can configure vips in your `Config.cfc`. **Note:** You only need to do this if you need non-default values. Defaults are shown below:

```cfc
function configure() {
	// ...

	settings.vips.binDir  = "/usr/bin/"; // where vips tools binary files are found
	settings.vips.timeout = 60;          // longest time to wait for a VIPs operation to complete
	
	// ...
}
```

## Limitations

* We have not yet implemented the conversion of pages of PDFs into jpgs. We leave the PDF Preview transformation to ImageMagick/native Lucee implementation.
# VIPS Image processor

This extension swaps out the ImageMagick/native lucee implementation of image resizing in favour of using [libvips](https://libvips.github.io/libvips/).



**It requires Preside 10.11 or greater (recommended 10.11.25) and as of 10.14.0, is included in the Preside core (so not required).**

## Installation

```
box install preside-ext-vips
```

## Pre-requisites and configuration

It is expected that [libvips](https://libvips.github.io/libvips/) be installed on your system, along with `libexif`. For example, on Ubuntu:

```bash
apt install libvips-tools --no-install-recommends
```

Or on MacOS, install with [Homebrew](https://brew.sh/):

```bash
brew install vips
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

(If installing on MacOS via Homebrew, your `binDir` is likely to be `/usr/local/bin/`.)

### Environment variables

You can also configure vips [using environment variables](https://docs.preside.org/devguides/config.html#injecting-environment-variables), and this is in fact *the method we would recommend*, both for dev and live environments.

In a `.env` file for your site, tyou could set:

```
VIPS_BINDIR=/usr/bin/
VIPS_TIMEOUT=60
```

And by setting `PRESIDE_VIPS_BINDIR` or `PRESIDE_VIPS_TIMEOUT` as environment variables on a local dev environment, those values will be picked up by every Preside site running under CommandBox - no further configuration required!


## Additional features

There are a couple of additional features that are available to your derivatives when using the VIPS extension.

### outputFormat

Normally, an image will be output in the same format as the original (unless the original image is an SVG file, in which case a PNG will be generated).

By adding the `outputFormat` argument to a derivative, you can specify which format the resulting image should be in. This is especially useful for a modern format such as WebP. You could specify `outputFormat="webp"` and the resulting images would be generated in the WebP format.

(Note that you would want to implement these images as _alternate_ sources using the `<picture>` element, as not all browsers support WebP).

Related to this, `.webp` is added to Preside's known image formats by the VIPS extension.

### autoFocalPoint

**Note: this is only available if your version of `libvips` is `8.5.0` or above. Some Linux distributions may not meet this requirement.**

You already have the ability to specify the focal point of an image manually. However, if you set `autoFocalPoint=true` on your derivative, then VIPS will make a smart guess at where the centre of attention of the image is. This would be especially useful for portraits, where you might want to automatically crop to a person's face.

Of course, if you manually set the focal point, then that will be used in preference - there may be occasions where the algorithm doesn't pick out the focal point you desire.

## Limitations

* We have not yet implemented the conversion of pages of PDFs into jpgs. We leave the PDF Preview transformation to ImageMagick/native Lucee implementation.

## License

This project is licensed under the GPLv2 License - see the [LICENSE.txt](https://github.com/pixl8/preside-ext-vips/blob/stable/LICENSE.txt) file for details.

## Authors

The project is maintained by [The Pixl8 Group](https://www.pixl8.co.uk). The lead developer is [Dominic Watson](https://github.com/DominicWatson). Contribution in the form of issues, ideas and pull requests is most welcome and encouraged.

## Code of conduct

We are a small, friendly and professional community. For the eradication of doubt, we publish a simple [code of conduct](https://github.com/pixl8/preside-ext-vips/blob/stable/CODE_OF_CONDUCT.md) and expect all contributors, users and passers-by to observe it.
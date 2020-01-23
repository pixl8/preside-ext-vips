# VIPS Image processor

This extension swaps out the ImageMagick/native lucee implementation of image resizing in favour of using [libvips](https://libvips.github.io/libvips/).

**It requires Preside 10.11 or greater (recommended 10.11.25).**

## Pre-requisites and configuration

It is expected that [libvips](https://libvips.github.io/libvips/) be installed on your system, along with `libexif`. For example, on Ubuntu:

```bash
apt install libvips libvips-tools libexif12
```

Or on MacOS, install [Homebrew](https://brew.sh/) and run:

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

## Limitations

* We have not yet implemented the conversion of pages of PDFs into jpgs. We leave the PDF Preview transformation to ImageMagick/native Lucee implementation.

## License

This project is licensed under the GPLv2 License - see the [LICENSE.txt](https://github.com/pixl8/preside-ext-vips/blob/stable/LICENSE.txt) file for details.

## Authors

The project is maintained by [The Pixl8 Group](https://www.pixl8.co.uk). The lead developer is [Dominic Watson](https://github.com/DominicWatson). Contribution in the form of issues, ideas and pull requests is most welcome and encouraged.

## Code of conduct

We are a small, friendly and professional community. For the eradication of doubt, we publish a simple [code of conduct](https://github.com/pixl8/preside-ext-vips/blob/stable/CODE_OF_CONDUCT.md) and expect all contributors, users and passers-by to observe it.
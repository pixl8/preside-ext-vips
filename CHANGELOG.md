# Changelog

## v1.0.11

* [#23](https://github.com/pixl8/preside-ext-vips/issues/23) Fix issues with Lucee deleting the tmp directory that we create for VIPS operations. Always ensure it exists when retreiving it for use.

## v1.0.10

* [#22](https://github.com/pixl8/preside-ext-vips/issues/22) Ensure scaleToFit operations cannot make resultant image smaller than the provided dimension
* Convert to Github actions publishing flow

## v1.0.9

* [#21](https://github.com/pixl8/preside-ext-vips/issues/21) Return width and height of generated asset derivative

## v1.0.8

* [#20](https://github.com/pixl8/preside-ext-vips/issues/20) Issue with dimension rounding and certain combinations of source/target sizes

## v1.0.7

* [#19](https://github.com/pixl8/preside-ext-vips/issues/19) Fix regression where SVG resizing was not working on all systems (revert previous change).

## v1.0.6

* [#17](https://github.com/pixl8/preside-ext-vips/issues/17)  AutoFocalPoint fails on older versions of libvips

## v1.0.5

* [#13](https://github.com/pixl8/preside-ext-vips/issues/13) Configure VIPS using environment variables
* [#14](https://github.com/pixl8/preside-ext-vips/issues/14) Update Ubuntu install instructions

## v1.0.4

* [#7](https://github.com/pixl8/preside-ext-vips/issues/7) Use VIPS for SVG-to-PNG conversion
* [#8](https://github.com/pixl8/preside-ext-vips/issues/8) Allow derivatives to specify an output format
* [#9](https://github.com/pixl8/preside-ext-vips/issues/9) Add .webp as a recognized image format
* [#10](https://github.com/pixl8/preside-ext-vips/issues/10) Add automatic focal point detection
* [#11](https://github.com/pixl8/preside-ext-vips/issues/11) Fix crop hints being ignored by the VIPS processor

## v1.0.3

* [#3](https://github.com/pixl8/preside-ext-vips/issues/3) Fix further rounding issues (workaround Lucee 5 bug)
* [#5](https://github.com/pixl8/preside-ext-vips/issues/5) Strip EXIF metadata when producing thumbnails
* [#6](https://github.com/pixl8/preside-ext-vips/issues/6) Implement image quality settings

## v1.0.2

* [#1](https://github.com/pixl8/preside-ext-vips/issues/1) Fix issue with non-integer dimension handling
* Added OSX installation instructions for libvips binaries

## v1.0.1

* Fix download location for box install

## v1.0.0

Initial release with support for resizing images (no PDF image sizing). Image quality arguments are also ignored in this release.

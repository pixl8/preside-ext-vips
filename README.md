# VIPS Image processor

This extension swaps out the ImageMagick/native lucee implementation of image resizing in favour of using libvips. All that is needed is to install the extension.

## Limitations

* Libvips cannot convert pages of PDFs into jpgs. We leave the PDF Preview transformation to ImageMagick/native Lucee implementation.

## Build notes

We had to build the `services/lib/JVips-1.0.0.jar` file from source in order to include it in this project. This was achieved in a linux environment by:

1. Cloning this project: [https://github.com/criteo/JVips](https://github.com/criteo/JVips)
2. Running `./setup-for-ubuntu-wsl-linux-target.sh` from the above project
3. Running `./build.sh --without-w64` from the above project

This created the jar file at `~/.m2/repository/JVips/JVips/1.0.0` which was then copied into this project.
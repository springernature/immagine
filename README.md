# Immagine

Immagine is the image manipulation service for [nature.com](http://nature.com).

[![Build status][shield-build]][info-build]
[![GPLv3 licensed][shield-license]][info-license]

## Running an Immagine Server

Immagine is a Ruby application, so you need to be comfortable running Ruby applications in your infrastructure.  It should work with any rack compatible web server, but we run it with and recommend [puma] proxied behind [NGINX] configured with a file based cache (see the example [nginx.conf]) for pretty acceptable results.

**TODO: ADD AN EXAMPLE NGINX CONFIG**

### Dependencies

* Ruby - see [.ruby-version] for the version currently targeted.
* [Imagemagick] - Immagine uses imagemagick to do all the hard work with the images.  You'll need at least version 2.7+ to take full advantage of all of Immagines' capabilities.
* [FFMpeg](https://www.ffmpeg.org/) - ffmpeg is required to take screenshots from videos (mov flv mp4 avi mpg and wmv are currently supported)
* A rack application server - again, we recommend [puma].
* A proxying web server - again, we recommend [NGINX].

### Configuration

Immagine is configured via a `config/application.yml` file.  Here is an example config:

```yaml
source_folder: ./test-data/src
format_whitelist:
  - w100h100  # Example cropped thumbnail
  - h125      # At a glance thumbnails
  - w250      # Figure index page thumbnails
  - w450      # At a glance popups
  - w926      # Full size figures
  - m685      # Article figures
  - relative  # Illustrations
```

Here's a brief description of the available options:

* `source_folder` - \[required\] - the directory of images that you'd like Immagine to handle/serve.
* `format_whitelist` - \[optional\] - a list of allowable image manipulation options (see [Requesting Images](#requesting-images) for further details), if a request comes through with a format that is not on this list, Immagine will respond with a not found response (404).  This is used to limit potential abuse of the system - i.e. automated requests for images with random processing options that could lead to a DOS situation.
* `statsd_host` - \[optional\] - the address of your statsd server (if you use statsd) for performance/usage metrics.
* `statsd_port` - \[optional\] - the port that your statsd server listens on.

## <a name="requesting-images"></a>Requesting Images

Immagine removes the need to create multiple resized versions of the same image to suit your design requirements. A single high-resolution image can instead be requested using a custom URL structure, and Immagine will resize & serve the image. Caching is handled by NGINX, and Immagine also manages all the HTTP headers you would expect for assets. 

[A presentation describing the basics of Immagine](https://dl.dropboxusercontent.com/u/239388/Immagine%20Talk/immagine.pdf)

### Original (Unmodified) Images

Unresized images can be requested by users via the URL structure `/{path}/{file_name}`

We recommend serving unresized images via Immagine to ensure:

* consistent URLs for all images across your application
* consistent cache control (set by Immagine)

### Modified Images

## URL structure

The basic URL structure for serving modified (resized, cropped, blurred, overlaid) images is `/{path}/{format_code}/{file_name}'

Here's a rundown of the basic formatting options and how they can be passed into Immagine:

* `wXXX` - alter an images width. Set this to a pixel value (i.e. `w200`) and the image will have its width reduced to that number of pixels. If the image is already smaller (less-wide) than this setting, the width will not be altered or stretched to fit.
* `hXXX` - alter an images height. As with the width, set this to a pixel value (i.e. `h200`) and the image will have its height reduced to that number of pixels. If the image is already smaller (less-tall) than this setting, the height will not be altered or stretched to fit.
* `mXXX` - max. Resize by width or height, whichever is largest
* `cXX-XXX-XXX-XX` - crop an image. See [Image Cropping](#image-cropping) for full details.
* `bXX-XX` - blur an image. See [Blurring an Image](#image-blurring) for full details.
* `ovXXX-XX` - overlay an image with a transparent color. See [Overlaying an Image](#image-overlay) for full details.

The formatting options can be combined, when they do not conflict. See [Combining Options](#combining-options)

#### <a name="image-cropping"></a>Image Cropping

Image cropping in Immagine is quite a powerful thing, here is the full info on the format string allowed:

```
c{gravity}-{width}-{height}-{resize_ratio}
```

* `gravity` - \[required\] - where to focus the cropping of the image, acceptable options for this are:
  * `C` - center
  * `N` - north
  * `E` - east
  * `S` - south
  * `W` - west
  * `NE` - north east
  * `NW` - north west
  * `SE` - south east
  * `SW` - south west
* `width` - \[required\] - width (in pixels) of the final cropped image.
* `height` - \[required\] - height (in pixels) of the final cropped image.
* `resize_ratio` - \[optional\] - resize the image (using this ratio) prior to cropping.  I.e. a ratio of '0.5' would reduce the image by half (in both width and height) before cropping.

Of the above options, `resize_ratio` is the only optional property.  Here are a couple of examples to show you how cropping can be used:

* `cC-500-100-0.5` - first reduce an image to half its original size (0.5 `resize_ratio`), then crop it in the center to 500 pixels wide by 100 pixels tall.
* `cSW-100-100` - Do not resize the image prior to cropping, just crop it to 100x100 pixels in the bottom-left.

#### <a name="image-blurring"></a>Blurring an Image

Sometimes your images are just too sharp, it's OK, Immagine has your back.  Here's the format string for adding some blur to your images:

```
b{radius}-{sigma}
```

* `radius` - \[required\]
* `sigma` - \[optional\]

#### <a name="image-overlay"></a>Overlaying an Image

You can also add a transparent colour overlay to your images with Immagine:

```
ov{colour}-{opacity}
```

* `colour` - \[optional\] - the hex code for the colour to use in the overlay (minus the hash - these are NOT allowed in URLs) - i.e. `FFF`. Another acceptable value for this is the string `dominant` (this is the default if the `colour` is omitted) - this tells Immagine to extract the most dominant colour from the image ([read more on this below](#dominant-colour)) and use that as the colour overlay.
* `opacity` - \[optional\] -


### <a name="combining-options"></a>Combining Formatting Options

The above options can be combined in various ways, with the exception of the resizing options which cannot *all* be combined with each other.

Valid combinations might be:

* `b2m100` - blur and resize by max
* `w1000cW-100-100-0.5` - resize by width and crop
* `ovb1.1-11cNW-100-100` - overlay and crop
* `w100h200` - resize by width and resize by height

**Invalid** combinations might be:

* `m100h100` - resize by max and resize by height
* `cNW-100` - crop (without all required parameters - see [Image Cropping](#image-cropping))
* `m100w100` - resize by max and resize by width

As you can see, the formatting codes can get quite complex, but you can make them a little more readable if you use a sensible delimiter - i.e. an underscore.

## Colour Analysis

To analyse the colour in an image, use the following URL structure: `/analyse/{path}/{file_name}`

### <a name="average-colour"></a>Average Colour

To find the average colour of an image, Immagine first shrinks the image to 1x1px in size, and extracts the colour from this pixel.

### <a name="dominant-colour"></a>Dominant Colour

To find the dominant colour of an image, Immagine first shrinks the image to 300x300px, then counts the top 10 most used colours in this image. The 10 colours are ranked in order of most used. The first colour which has a lightness of less than 0.7 is picked as the dominant colour (or, if none of the colours have a lightness less than 0.7, the most common colour is picked). 

The lightness factor is used to ensure that an image which consists of coloured artefacts on a white background does not return white as the most common colour.

## Contributing



    bundle
    cp config/application.yml.sample config/application.yml
    rake # it runs specs and features
    foreman start

Go to:

    http://localhost:3000/live/images/w250/matz.jpg

## Licence

[&copy; 2015, Macmillan Publishers](LICENSE.txt).

Immagine is licensed under the [GNU General Public License 3.0][gpl].

[puma]: http://puma.io
[nginx]: http://nginx.org/
[.ruby-version]: https://github.com/nature/immagine/blob/master/.ruby-version
[imagemagick]: http://www.imagemagick.org/
[gpl]: http://www.gnu.org/licenses/gpl-3.0.html
[info-license]: LICENSE
[info-build]: https://travis-ci.org/nature/immagine
[shield-license]: https://img.shields.io/badge/license-GPLv3-blue.svg
[shield-build]: https://img.shields.io/travis/nature/immagine/master.svg

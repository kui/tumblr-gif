tumblr-gif
==============

GIF generator for tumblr.

Requirement
-------------

* `avconv` : included on [libav][])
* `covert` : included on [ImageMagick][])

[ImageMagick]: http://www.imagemagick.org/
[libav]: http://libav.org/

On Ubuntu:

```sh
apt-get install avconv imagemagick
```

Installation
-------------

In terminal:

```sh
wget https://raw.github.com/kui/tumblr-gif/master/bin/tumblr-gif
chmod +x tumblr-gif
./tumblr-gif
```

Or move your favorite location included on `PATH` env.


Usage
-----------

In terminal:

```sh
./tumblr-gif view <path to video file> '0:10:4' 10
# generating frame images
# then delete unwanted frame images
./tumblr-gif build /tmp/t.gif
# generating /tmp/t.gif with generated frame images
```

And `~/.tumblr-gif-rc.sh` might help you to build a GIF.

tumblr-gif
==============

__NO LONGER MAINTAINED__: new implimented by [kui/tumblr-gif-py](https://github.com/kui/tumblr-gif-py)

GIF generator for the tumblr spec.

Requirement
-------------

* `avconv` : included on [libav][]
* `covert` : included on [ImageMagick][]

[ImageMagick]: http://www.imagemagick.org/
[libav]: http://libav.org/

On Ubuntu:

```sh
apt-get install libav-tools imagemagick
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
$ ./tumblr-gif view /path/to/video.mp4 '0:10:4' 11
# generating frame images from '0:10:4' for 11 secounds
# then delete unwanted frame images
$ ./tumblr-gif gen /tmp/t.gif
# generating /tmp/t.gif with generated frame images
```

`~/.tumblr-gif-rc.sh` and `$ ./tumblr-gif gen -h` might help you to build a GIF.

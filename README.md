# coordcon

Commandline tool to convert geo coordinates between utm and latitute/longitude.


## Requirements

* Python 3.7 or newer
* [utm](https://github.com/Turbo87/utm)


## Install

* from Source: ```make install```
* deb-Package: ```make deb```
* [AUR](https://aur.archlinux.org/packages/coordcon)


## Usage:

```
$ coordcon  50 10
> 571666.448 5539109.816 32 U
$ echo "50 10" | coordcon | coordcon
> 50.000000 10.000000
$ echo "571666.448 5539109.816 32U" | coordcon
> 50.000000 10.000000
$ echo "32U 571666.448 5539109.816" | coordcon
> 50.000000 10.000000
$ coordcon input.csv output.csv
$ cat input.csv | coordcon > output.csv
```

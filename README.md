# Arduino Makefile

This repository contains a simple Makefile that can be used with many Arudino sketches, so that the sketch may be compiled and uploaded via the command line.
If you dislike the Arduino IDE, this Makefile will help quickly build and upload the sketches.

The Makefile has been tested for use with the latest versions of Arduino and avrdude.

Depending on your purposes, this makefile might also be able to upload a sketch to a raw ATMEL chip via a programmer.

### Latest versions tested:
- Arduino 1.6.5
- avrdude 6.1

## Quick Start

Hook up an Arduino via USB.
Move the Makefile to the root of your Arduino Sketch folder.
Double-check the Makefile and verify the settings are correct for your setup.
In particular, please assure that you:
- Edit the Makefile `PROJECT` variable to reflect the name of the .ino file.
- Edit the `ARDUINO_MODEL` variable to reflect the name of the device you're using
- Edit the `PORT` variable for the communication port (usually /dev/ttyACM\*)
- Add any external libraries that are needed via the `USER_LIBS` and `ARDUINO_LIBS` variables.

Following the edits to the Makefile, you can compile and upload the code via:

```bash
$ make
$ make upload
```

## Acknowledgments
Much of the footwork for this Makefile was done by [sudar's Arduino-Mk](https://github.com/sudar/Arduino-Makefile/).

## License
```
The MIT License (MIT)

Copyright © 2015 Tom Swartz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

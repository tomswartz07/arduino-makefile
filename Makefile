# Makefile for building Arduino sketches (programs) with Arduino from the
# command line.
#
#  * By default compiles with a lot more warnings, to detect shoddy progamming.
#    Comment out some of the OPT_WARN lines to turn this off.
#  * To make your C++ source files (.cpp) compile with any Arduino version, use
#    something like this:
#      #if ARDUINO >= 100
#      #include <Arduino.h>
#      #else
#      #include <WProgram.h>
#      #endif
#
# Detailed instructions for using this Makefile:
#
#  1. Copy this file into the directory with your sketch.
#     There should be a file with the extension .ino (previously .pde).
#     cd into this directory.
#
#  2. Below, modify the settings of various variables, but at least
#        PROJECT
#        ARDUINO_MODEL
#        PORT
#        ARDUINO
#        ARDUINO_DIR
#        ARDUINO_VARIANT
#        ARDUINO_LIBS and USER_LIBS
#
#     Check the other variables, but they're not likely needing to change.
#     See the descriptions at the variables for details.
#
#  3. Function prototypes. (Not super necessary, but helps if you have issues)
#     Sorry, they're necessary with every programming. The Arduino IDE tries
#     to create them automatically and does get it mostly (but not always)
#     right.
#     If you know of a way to create prototypes automaticlly, let me know.
#     It might be easiest to start with the prototypes created by the IDE.
#     Run the build in the IDE, locate the project source file created by the
#     IDE (for a project XYZ it's something like
#     /tmp/build4303013692903917981.tmp/XYZ.cpp, and copy the prototypes.
#     They're just before the first variable that is declared.
#
#     If you have multiple .ino/.pde files, put the prototypes for all of them
#     into the main file (XYZ.ino).
#
#  4. Run "make" to compile/verify your program.
#
#  5. Run "make upload" (or "make up" for short) to upload your program to the
#     Arduino board. The board is reset first.
#
#  6. Run "make help" for more options.
#
#
# ToDo:
#  * Expand the USB_PID and USB_VID detection for other build_extras, as defined
#    in the Platforms.txt and Boards.txt files.
#
#
# Makefile version (only used for help text).
MKVERSION = 1.0

# Determine operating system environment.
# Possible values are (tested): Linux, FreeBSD (on 8.1), ...
OSNAME =	$(shell uname)

# Name of the program and source .ino (previously .pde) file.
# No extension here (e.g. PROJECT = Blink).
PROJECT ?=	Blink

# Project version. Only used for packing the source into an archive.
VERSION ?=	1.0

# Arduino model. E.g. atmega328, mega2560, uno.
# Valid model names can be found in $(ARDUINO_DIR)/hardware/arduino/avr/boards.txt
# This must be set to a valid model name.
ARDUINO_MODEL ?= micro
#ARDUINO_MODEL = uno
#ARDUINO_MODEL = nano328  # Is set to a 168 CPU
#ARDUINO_MODEL = atmega2560

# Arduino family E.g. mega, diecimila, nano.
# Valid family names can be found in $(ARDUINO_Dir)/hardware/arduino/avr/boards.txt
# Set this if your card is a part of a subset
#ARDUINO_FAMILY = mega

# Arduino variant (for Arduino 1.0+).
# Directory containing the pins_arduino.h file.
#ARDUINO_VARIANT=$(ARDUINO_DIR)/hardware/arduino/avr/variants/micro

# MCU architecture.
# Currently hardcoded to avr (sam, etc. are unsupported.)
ARCH ?= avr

# USB port the Arduino board is connected to.
# Linux: e.g. /dev/ttyUSB0, or /dev/ttyACM0 for the Uno.
# BSD:   e.g. /dev/cuaU0
# USBASP: e.g. /dev/ttyS0
# It is a good idea to use udev rules to create a device name that is constant,
# based on the serial number etc. of the USB device.
PORT ?=		/dev/serial/by-id/*Arduino*

# Arduino version (e.g. 23 for 0023, or 105 for 1.0.5).
# Make sure this matches ARDUINO_DIR below!
#ARDUINO = 	23
ARDUINO ?= 	161

# Location of the official Arduino IDE.
# E.g. /usr/local/arduino, or $(HOME)/arduino
# Make sure this matches ARDUINO above!
#ARDUINO_DIR =	/usr/local/pckg/arduino/arduino-0023
ARDUINO_DIR ?=	/usr/share/arduino

# Arduino 0.x based on 328P now need the new programmer protocol.
# Arduino 1.6+ uses the avr109 programmer by default
# ICSP programmers can also be used, for example: usbasp
# If unset, a default is chosen based on ARDUINO_MODEL and ARDUINO_FAMILY.
#AVRDUDE_PROGRAMMER = usbasp
AVRDUDE_PROGRAMMER = avr109

# Arduino core sources.
#ARDUINO_CORE ?=	$(ARDUINO_DIR)/hardware/arduino/avr/cores/arduino

# Standard Arduino libraries used, e.g. EEPROM, LiquidCrystal.
# Give the name of the directory containing the library source files.
ifndef ARDUINO_LIBS
ARDUINO_LIBS =
ARDUINO_LIBS += EEPROM
ARDUINO_LIBS += Wire
ARDUINO_LIBS += SPI
ifdef SD  # Comment out this condition to always use the SD library.
ARDUINO_LIBS += SD
endif
endif

# User libraries (in ~/sketchbook/libraries/).
# Give the name of the directory containing the library source files.
USER_LIBDIR ?=	./libraries
USER_LIBS ?=

# Additional pre-compiled libraries to link with.
# Always leave the math (m) library last!
# The Arduino core library is automatically linked in.
# If the library is in a location the compiler doesn't already know, also
# give the directory with -L.
# Note this is dealing with real libraries (libXXX.a), not Arduino "libraries"!
LDLIBS ?=
LDLIBS +=	-lm

LISTING_ARGS =	-h -S
LISTING_ARGS += -t -l -C -w

SYMBOL_ARGS =	-n
SYMBOL_ARGS +=	-C

# Directory in which files are created.
# Using the current directory ('.') is untested (and probably unwise).
OUTPUT ?=	bin

# Where are tools like avr-gcc located on your system?
# If you set this, it must end with a slash!
#AVR_TOOLS_PATH = $(ARDUINO_DIR)/hardware/tools/avr/bin/
#AVR_TOOLS_PATH = /usr/bin/
AVR_TOOLS_PATH ?=

# Reset command to use.
# Possible values are: "stty", "python", "perl".
#RESETCMD =	stty

### Macro definitions. Place -D or -U options here.
CDEFS ?=
ifdef LTO
CDEFS +=	-DLTO
endif
ifdef SD
CDEFS +=	-DUSE_SD
endif
ifdef mega
CDEFS +=	-DARDUINO_MEGA
endif

############################################################################
# Below here nothing should need to be changed.
############################################################################

# Output hex format.
HEXFORMAT =	ihex

# Name of the dependencies file (used for "make depend").
# This doesn't work too well.
# Maybe drop this idea and use auto-generated dependencies (*.d) instead?
DEPFILE =	$(OUTPUT)/Makefile.depend

# Name of the tar file in which to pack the user program up in.
TARFILE =	$(PROJECT)-$(VERSION).tar

# Default reset command if still unset.
RESETCMD ?=	stty

# Set Arduino core sources location to default, if still unset.
ARDUINO_CORE ?= $(ARDUINO_DIR)/hardware/arduino/avr/cores/arduino

# Get the upload rate, CPU model, CPU frequency, avrdude programmer type
# and other variables from the IDE files.

ifdef ARDUINO_FAMILY
MODEL_PATTERN_MATCHING = $(ARDUINO_MODEL)\|$(ARDUINO_FAMILY)
else
MODEL_PATTERN_MATCHING = $(ARDUINO_MODEL)
endif

getboardvar = $(shell \
	sed "/^\($(MODEL_PATTERN_MATCHING)\)\.$(1)=/ { s/.*=//; q }; d" \
		$(ARDUINO_DIR)/hardware/arduino/avr/boards.txt \
	)

UPLOAD_RATE ?=	$(call getboardvar,upload.speed)
MCU ?=		$(call getboardvar,build.mcu)
F_CPU ?=	$(call getboardvar,build.f_cpu)
AVRDUDE_PROGRAMMER ?= $(call getboardvar,upload.protocol)
VID ?=		$(call getboardvar,build.vid)
PID ?=		$(call getboardvar,build.pid)
BOARD ?=	$(call getboardvar,build.board)

# Try and guess PORT if it wasn't set previously.
# Note using shell globs most likely won't work, so try first port.
ifeq "$(OSNAME)" "Linux"
ifeq ("$(ARDUINO_MODEL)", $(filter "$(ARDUINO_MODEL)", "uno" "mega2560"))
    PORT ?= /dev/ttyACM0
else
    PORT ?= /dev/ttyUSB0
endif
else
    # Not Linux, so try BSD port name
    PORT ?= /dev/cuaU0
endif

# Try and guess ARDUINO_VARIANT if it wasn't set previously.
# Possible values for Arduino 1.0 are:
#   eightanaloginputs leonardo mega micro standard
# This makefile part is incomplete. Best set variant explicitly at the top.
# Default is "standard".
ifeq ($(ARDUINO_VARIANT),)
ifeq ("$(ARDUINO_MODEL)", $(filter "$(ARDUINO_MODEL)", "mega" "mega2560"))
ARDUINO_VARIANT ?= $(ARDUINO_DIR)/hardware/arduino/avr/variants/mega
else
ifeq "$(ARDUINO_MODEL)" "micro"
ARDUINO_VARIANT ?= $(ARDUINO_DIR)/hardware/arduino/avr/variants/micro
else
ARDUINO_VARIANT ?= $(ARDUINO_DIR)/hardware/arduino/avr/variants/standard
endif
endif
endif


### Sources

# Arduino core sources.
CORESRC =	$(wildcard $(ARDUINO_CORE)/*.c)
CORECXXSRC =	$(wildcard $(ARDUINO_CORE)/*.cpp)
COREASMSRC =	$(wildcard $(ARDUINO_CORE)/*.S)

# Arduino official library sources.
# 1.0.x: search in root and utility folders
# 1.5.x: search in src folder as well.
# 1.5.x: search also in src/$(ARCH) (for Servo)
# https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5:-Library-specification
# 1.5.x: search in hardware folder + utility (for Wire/twi)
# https://github.com/arduino/Arduino/wiki/Arduino-IDE-1.5---3rd-party-Hardware-specification
ALIBDIRS = $(wildcard \
		$(ARDUINO_LIBS:%=$(ARDUINO_DIR)/libraries/%) \
		$(ARDUINO_LIBS:%=$(ARDUINO_DIR)/libraries/%/utility) \
		$(ARDUINO_LIBS:%=$(ARDUINO_DIR)/libraries/%/src) \
		$(ARDUINO_LIBS:%=$(ARDUINO_DIR)/libraries/%/src/$(ARCH)) \
		$(ARDUINO_LIBS:%=$(ARDUINO_DIR)/hardware/arduino/avr/libraries/%) \
		$(ARDUINO_LIBS:%=$(ARDUINO_DIR)/hardware/arduino/avr/libraries/%/utility) \
		)
ALIBSRC =	$(wildcard $(ALIBDIRS:%=%/*.c))
ALIBCXXSRC =	$(wildcard $(ALIBDIRS:%=%/*.cpp))
ALIBASMSRC =	$(wildcard $(ALIBDIRS:%=%/*.S))

# All Arduino library sources.
ARDUINO_ALL_LIBS = $(notdir $(wildcard $(ARDUINO_DIR)/libraries/*))
ALIBALLDIRS = $(wildcard \
		$(ARDUINO_ALL_LIBS:%=$(ARDUINO_DIR)/libraries/%) \
		$(ARDUINO_ALL_LIBS:%=$(ARDUINO_DIR)/libraries/%/utility) \
		)
ALIBALLSRC =	$(wildcard $(ALIBALLDIRS:%=%/*.c))
ALIBALLCXXSRC =	$(wildcard $(ALIBALLDIRS:%=%/*.cpp))
ALIBALLASMSRC =	$(wildcard $(ALIBALLDIRS:%=%/*.S))

# User library sources.
ULIBDIRS = $(wildcard \
		$(USER_LIBS:%=$(USER_LIBDIR)/%) \
		$(USER_LIBS:%=$(USER_LIBDIR)/%/utility) \
		)
ULIBSRC =	$(wildcard $(ULIBDIRS:%=%/*.c))
ULIBCXXSRC =	$(wildcard $(ULIBDIRS:%=%/*.cpp))
ULIBASMSRC =	$(wildcard $(ULIBDIRS:%=%/*.S))

# User program sources.
SRC =		$(wildcard *.c)
CXXSRC =
CXXSRCINO =	$(wildcard *.ino) $(wildcard *.pde)
prjino :=	$(findstring $(PROJECT).ino,$(CXXSRCINO))
prjpde :=	$(findstring $(PROJECT).pde,$(CXXSRCINO))
# Remove project.ino and project.pde from compilation.
CXXSRCINO :=	$(filter-out $(PROJECT).ino $(PROJECT).pde,$(CXXSRCINO))
# If project.ino or project.pde exist, add output/project.cpp to compilation.
ifneq "" "$(prjino)$(prjpde)"
CXXSRC +=	$(OUTPUT)$(if $(OUTPUT),/)$(PROJECT).cpp
# Remove project.cpp from compilation if project.ino or project.pde exist.
# (This will cause problems if OUTPUT is "."!)
#CXXSRC :=	$(filter-out $(PROJECT).cpp,$(CXXSRC))
endif
# Add the remaining C++ sources; put project.* first to find errors soon.
CXXSRC +=	$(wildcard *.cpp)
# Assembler sources.
ASRC =		$(wildcard *.S)

# Paths to check for source files (pre-requisites).
# (Note: The vpath directive clears the path if the argument is empty!)
ifneq "$(ARDUINO_CORE)" ""
  vpath % $(ARDUINO_CORE)
endif
ifneq "$(ALIBDIRS)" ""
  vpath % $(ALIBDIRS)
endif

ifneq "$(ULIBDIRS)" ""
  vpath % $(ULIBDIRS)
endif
vpath % .
ifneq "$(ALIBALLDIRS)" ""
  vpath % $(ALIBALLDIRS)
endif
# Either ensure the path to vpath is not empty, or use the VPATH variable.
# The manual says to separate paths with ":", but " " works as well.
#VPATH = 	$(ARDUINO_CORE) $(ALIBDIRS) $(ULIBDIRS) . $(ALIBALLDIRS)


### Include directories.
CINCS = \
	-I$(ARDUINO_CORE) \
	-I$(ARDUINO_VARIANT) \
	$(ALIBDIRS:%=-I%) \
	$(ULIBDIRS:%=-I%) \
	-I.


### Object and dependencies files.

# Arduino core.
COREOBJ =	$(addprefix $(OUTPUT)/,$(notdir \
			$(CORESRC:.c=.c.o) \
			$(CORECXXSRC:.cpp=.cpp.o) \
			$(COREASMSRC:.S=.S.o) \
		))

# Arduino libraries used.
ALIBOBJ =	$(addprefix $(OUTPUT)/,$(notdir \
			$(ALIBSRC:.c=.c.o) \
			$(ALIBCXXSRC:.cpp=.cpp.o) \
			$(ALIBASMSRC:.S=.S.o) \
		))

# All Arduino libraries.
ALIBALLOBJ =	$(addprefix $(OUTPUT)/,$(notdir \
			$(ALIBALLSRC:.c=.c.o) \
			$(ALIBALLCXXSRC:.cpp=.cpp.o) \
			$(ALIBALLASMSRC:.S=.S.o) \
		))

# User libraries used.
ULIBOBJ =	$(addprefix $(OUTPUT)/,$(notdir \
			$(ULIBSRC:.c=.c.o) \
			$(ULIBCXXSRC:.cpp=.cpp.o) \
			$(ULIBASMSRC:.S=.S.o) \
		))

# User program.
OBJ =		$(addprefix $(OUTPUT)/,$(notdir \
			$(SRC:.c=.c.o) \
			$(CXXSRC:.cpp=.cpp.o) \
			$(ASRC:.S=.S.o) \
		))

# All object files.
#ALLOBJ =	$(COREOBJ) $(ALIBOBJ) $(ULIBOBJ) $(OBJ)
ALLOBJ =	$(OBJ) $(ULIBOBJ) $(ALIBOBJ) $(COREOBJ)

# All dependencies files.
ALLDEPS =	$(ALLOBJ:%.o=%.d)


### More macro definitions.
# -DF_CPU and -DARDUINO are mandatory.
CDEFS += 	-DF_CPU=$(F_CPU) -DARDUINO=$(ARDUINO)
CDEFS +=	-DARDUINO_$(BOARD)
CDEFS +=	-DARDUINO_ARCH_$(shell echo $(ARCH) | tr '[a-z]' '[A-Z]')


### C/C++ Compiler flags.

# C standard level.
# c89   - ISO C90 ("ANSI" C)
# gnu89 - c89 plus GCC extensions
# c99   - ISO C99 standard (not yet fully implemented)
# gnu99 - c99 plus GCC extensions (default for C)
CSTANDARD =	-std=gnu99

# C++ standard level.
# empty   - default
# c++98   - 1998 ISO C++ standard plus amendments. ("ANSI" C++)
# gnu++98 - c++98 plus GNU extensions (default for C++)
# c++0x   - working draft of upcoming ISO C++0x standard; experimental
# gnu++0x - c++0x plus GNU extensions
CXXSTANDARD =	-std=gnu++0x

# Optimisations.
OPT_OPTIMS =	-Os
OPT_OPTIMS +=	-ffunction-sections -fdata-sections
OPT_OPTIMS +=	-mrelax
# -mrelax crashes binutils 2.22, 2.19.1 gives 878 byte shorter program.
# The crash with binutils 2.22 needs a patch. See sourceware #12161.
ifdef LTO
OPT_OPTIMS +=	-flto
#OPT_OPTIMS +=	-flto-report
#OPT_OPTIMS +=	-fwhole-program
# -fuse-linker-plugin requires gcc be compiled with --enable-gold, and requires
# the gold linker to be available (GNU ld 2.21+ ?).
#OPT_OPTIMS +=	-fuse-linker-plugin
endif

# Debugging format.
# Native formats for AVR-GCC's -g are stabs [default], or dwarf-2.
# AVR (extended) COFF requires stabs, plus an avr-objcopy run.
OPT_DEBUG =	-g2 -gstabs

# Warnings.
# A bug in gcc 4.3.x related to progmem might turn a warning into an error
# when using -pedantic. This patch works around the problem:
# http://volker.top.geek.nz/arduino/avr-libc-3.7.1-pgmspace_progmem-fix.diff
# Turning on all warnings shows a large number of less-than-optimal program
# locations in the Arduino sources. Some might turn into errors. Either fix
# your Arduino sources, or turn the warnings off.
ifndef OPT_WARN
OPT_WARN =	-Wall
OPT_WARN +=	-pedantic
OPT_WARN +=	-Wextra
OPT_WARN +=	-Wmissing-declarations
OPT_WARN +=	-Wmissing-field-initializers
OPT_WARN +=	-Wsystem-headers
OPT_WARN +=	-Wno-variadic-macros
endif
ifndef OPT_WARN_C
OPT_WARN_C =	$(OPT_WARN)
OPT_WARN_C +=	-Wmissing-prototypes
endif
ifndef OPT_WARN_CXX
OPT_WARN_CXX =	$(OPT_WARN)
endif

# Other.
ifndef OPT_OTHER
OPT_OTHER =
# Save gcc temp files (pre-processor, assembler):
#OPT_OTHER +=	-save-temps

# Automatically enable build.extra_flags if needed
# Used by Micro and other devices to fill in USB_PID and USB_VID
OPT_OTHER +=	-DUSB_VID=$(VID) -DUSB_PID=$(PID)
OPT_OTHER += -fno-use-cxa-atexit
endif

# Final combined.
CFLAGS =	-mmcu=$(MCU) \
		$(OPT_OPTIMS) $(OPT_DEBUG) $(CSTANDARD) $(CDEFS) \
		$(OPT_WARN) $(OPT_OTHER) $(CEXTRA)
CXXFLAGS =	-mmcu=$(MCU) \
		$(OPT_OPTIMS) $(OPT_DEBUG) $(CXXSTANDARD) $(CDEFS) \
		$(OPT_WARN) $(OPT_OTHER) $(CEXTRA)


### Assembler flags.

#ASFLAGS = -Wa,-adhlns=$(<:.S=.lst),-gstabs

# Assembler standard level.
ASTANDARD =	-x assembler-with-cpp

# Final combined.
ASFLAGS =	-mmcu=$(MCU) \
		$(CDEFS) \
		$(ASTANDARD) $(ASEXTRA)


### Linker flags.

# Optimisation setting must match compiler's, esp. for -flto.

LDFLAGS =	-mmcu=$(MCU)
LDFLAGS +=	$(OPT_OPTIMS)
LDFLAGS +=	-Wl,--gc-sections
#LDFLAGS +=	-Wl,--print-gc-sections


### Programming / program uploading.

AVRDUDE_FLAGS =

# Do not verify.
#AVRDUDE_FLAGS+= -V

# Override invalid signature check.
#AVRDUDE_FLAGS+= -F

# Disable auto erase for flash memory. (IDE uses this too.)
AVRDUDE_FLAGS+= -D

# Quiet -q -qq / Verbose -v -vv.
AVRDUDE_FLAGS+= -q

AVRDUDE_FLAGS+= -p $(MCU) -c $(AVRDUDE_PROGRAMMER) -b $(UPLOAD_RATE)
AVRDUDE_FLAGS+= -P $(PORT)

# avrdude config file
AVRDUDE_FLAGS+= -C /etc/avrdude.conf
#AVRDUDE_FLAGS+= -C $(ARDUINO_DIR)/hardware/tools/avr/etc/avrdude.conf

AVRDUDE_WRITE_FLASH = -U flash:w:$(OUTPUT)/$(PROJECT).hex:i


### Programs

AVRPREFIX =	avr-
CC =		$(AVR_TOOLS_PATH)$(AVRPREFIX)gcc
CXX =		$(AVR_TOOLS_PATH)$(AVRPREFIX)g++
OBJCOPY =	$(AVR_TOOLS_PATH)$(AVRPREFIX)objcopy
OBJDUMP =	$(AVR_TOOLS_PATH)$(AVRPREFIX)objdump
AR =		$(AVR_TOOLS_PATH)$(AVRPREFIX)ar
SIZE =		$(AVR_TOOLS_PATH)$(AVRPREFIX)size
NM =		$(AVR_TOOLS_PATH)$(AVRPREFIX)nm
AVRDUDE =	$(AVR_TOOLS_PATH)avrdude
#AVRDUDE =	$(ARDUINO_DIR)/hardware/tools/avrdude
RM =		rm -f
RMDIR = 	rmdir
MV =		mv -f
ifeq "$(OSNAME)" "Linux"
    STTY =	stty -F $(PORT)
else
    # BSD uses small f
    STTY =	stty -f $(PORT)
endif


### Implicit rules

.SUFFIXES: .ino .pde .elf .hex .eep .lss .listing .sym .symbol
.SUFFIXES: .cpp .c .S .o .a

# Compile: create object files from C++ source files.
%.cpp.o $(OUTPUT)/%.cpp.o: %.cpp
	$(CXX) -o $@ -c $(CXXFLAGS) $< \
	  -MMD -MP -MF"$(@:%.cpp.o=%.d)" -MT"$@ $(@:%.cpp.o=%.S) $(@:%.cpp.o=%.d)" \
	  $(CINCS)
	if [ -f "$(notdir $(@:.cpp.o=.s))" -a ! -f "$(@:.cpp.o=.s)" ]; then \
	  mv "$(notdir $(@:.cpp.o=.s))" "$(dir $@)"; fi
	if [ -f "$(notdir $(@:.cpp.o=.ii))" -a ! -f "$(@:.cpp.o=.ii)" ]; then \
	  mv "$(notdir $(@:.cpp.o=.ii))" "$(dir $@)"; fi

# Compile: create object files from C source files.
%.c.o $(OUTPUT)/%.c.o: %.c
	$(CC) -o $@ -c $(CFLAGS) $< \
	  -MMD -MP -MF"$(@:%.c.o=%.d)" -MT"$@ $(@:%.c.o=%.S) $(@:%.c.o=%.d)" \
	  $(CINCS)
	if [ -f "$(notdir $(@:.c.o=.s))" -a ! -f "$(@:.c.o=.s)" ]; then \
	  mv "$(notdir $(@:.c.o=.s))" "$(dir $@)"; fi
	if [ -f "$(notdir $(@:.c.o=.i))" -a ! -f "$(@:.c.o=.i)" ]; then \
	  mv "$(notdir $(@:.c.o=.i))" "$(dir $@)"; fi

# Compile: create assembler files from C++ source files.
%.S $(OUTPUT)/%.S: %.cpp
	$(CXX) -o $@ -S $(CXXFLAGS) $< \
	  -MMD -MP -MF"$(@:%.S=%.d)" -MT"$(@:%.S=%.o) $@ $(@:%.S=%.d)" \
	  $(CINCS)

# Compile: create assembler files from C source files.
%.S $(OUTPUT)/%.S: %.c
	$(CC) -o $@ -S $(CFLAGS) $< \
	  -MMD -MP -MF"$(@:%.S=%.d)" -MT"$(@:%.S=%.o) $@ $(@:%.S=%.d)" \
	  $(CINCS)

# Assemble: create object files from assembler source files.
%.S.o $(OUTPUT)/%.S.o: %.S
	$(CC) -o $@ -c $(ASFLAGS) $< \
	  -MMD -MP -MF"$(@:%.S.o=%.d)" -MT"$@ $(@:%.S.o=%.S) $(@:%.S.o=%.d)" \
	  $(CINCS)

# Create extended listing file from object file.
%.lss %.listing: %.o
	$(OBJDUMP) $(LISTING_ARGS) $< > $@

%.hex: %.elf
	$(OBJCOPY) -O $(HEXFORMAT) -R .eeprom $< $@

%.eep: %.elf
	-$(OBJCOPY) -j .eeprom \
	--set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 \
	-O $(HEXFORMAT) $< $@

# Create extended listing file from ELF output file.
%.lss %.listing: %.elf
	$(OBJDUMP) $(LISTING_ARGS) $< > $@

# Create a symbol table from ELF output file.
%.sym %.symbol: %.elf
#	$(NM) $(SYMBOL_ARGS) $< > $@
	$(NM) $(SYMBOL_ARGS) $< | uniq > $@

# Pre-processing of Arduino .ino/.pde source files.
# It creates a .cpp file based with the same name as the .pde file.
# On top of the new .cpp file comes the Arduino.h/WProgram.h header.
# Then the .cpp file will be compiled. Errors during compile will
# refer to this new, automatically generated, file.
# Not the original .pde file you actually edit...
$(OUTPUT)/%.cpp: %.ino
	echo >  $@ "// Automatically generated by Makefile. Don't edit."
	echo >> $@ "#include <Arduino.h>"
	cat  >> $@ $< $(CXXSRCINO)
$(OUTPUT)/%.cpp: %.pde
	echo > $@ "// Automatically generated by Makefile. Don't edit."
	echo >> $@ "#if ARDUINO >= 100"
	echo >> $@ "#include <Arduino.h>"
	echo >> $@ "#else"
	echo >> $@ "#include <WProgram.h>"
	echo >> $@ "#endif"
	cat  >> $@ $< $(CXXSRCINO)


### Explicit rules.

.PHONY: all build elf hex eep lss lst sym listing symbol size tar help extra
.PHONY: coff extcoff
.PHONY: reset reset_stty reset_python reset_perl upload up clean depend mkout
.PHONY: showvars showvars2

# Default target.
all:	elf hex eep listing symbol size

build:	elf hex

elf:	$(OUTPUT) $(OUTPUT)/$(PROJECT).elf
hex:	$(OUTPUT) $(OUTPUT)/$(PROJECT).hex
eep:	$(OUTPUT) $(OUTPUT)/$(PROJECT).eep
lss:	$(OUTPUT) $(OUTPUT)/$(PROJECT).lss
lst:	$(OUTPUT) $(OUTPUT)/$(PROJECT).lss
sym:	$(OUTPUT) $(OUTPUT)/$(PROJECT).sym
listing: $(OUTPUT) $(OUTPUT)/$(PROJECT).listing
symbol: $(OUTPUT) $(OUTPUT)/$(PROJECT).symbol
tar:	$(TARFILE).xz
extra:	$(patsubst %,$(OUTPUT)/$(PROJECT)_2%, .elf .hex .listing .symbol) \
	$(patsubst %,$(OUTPUT)/$(PROJECT)_3%, .elf .hex .listing .symbol) \
	$(patsubst %,$(OUTPUT)/$(PROJECT)_4%, .elf .hex .listing .symbol) \
	$(patsubst %,$(OUTPUT)/$(PROJECT)_6%, .elf .hex .listing .symbol) \
	$(patsubst %,$(OUTPUT)/$(PROJECT)_8%, .elf .hex .listing .symbol) \
	$(patsubst %,$(OUTPUT)/$(PROJECT)_9%, .elf .hex .listing .symbol) \
	$(patsubst %,$(OUTPUT)/$(PROJECT)_A%, .elf .hex .listing .symbol)

help:
	@printf "\
Arduino Makefile version $(MKVERSION) by Volker Kuhlmann\n\
Makefile targets (run \"make <target>\"):\n\
   all           Compile program and create listing, symbol list etc.\n\
   upload        Upload program to Arduino board (or just use 'up')\n\
   size          Show size of all .elf and .hex files in output directory\n\
   reset         Reset Arduino board\n\
   reset_stty    Reset using stty\n\
   reset_python  Reset using Python program\n\
   reset_perl    Reset using perl program\n\
   tar           Create tar file of program\n\
   dtr           Show current state of serial port's DTR line\n\
   showvars      Show almost all makefile variables\n\
   mkout         Create output directory\n\
   depend        Put all dependencies into one file. Doesn't work, don't use.\n\
   clean         Delete all generated files\n\
"

# Show variables. Essential when developing this makefile.
showvars:
	@make --no-print-directory $(MAKEVARS) showvars2 | $${PAGER:-less}
showvars2:
	: PROJECT = "$(PROJECT)", VERSION = "$(VERSION)"
	: ARDUINO = "$(ARDUINO)"
	: ARDUINO_MODEL = "$(ARDUINO_MODEL)"
	: ARDUINO_FAMILY = "$(ARDUINO_FAMILY)"
	: F_CPU = "$(F_CPU)"
	: PORT = "$(PORT)"
	: UPLOAD_RATE = "$(UPLOAD_RATE)"
	: MCU = "$(MCU)"
	: AVRDUDE_PROGRAMMER = "$(AVRDUDE_PROGRAMMER)"
	: AVRDUDE = "$(AVRDUDE)"
	: AVRDUDE_FLAGS = "$(AVRDUDE_FLAGS)"
	: AVRDUDE_WRITE_FLASH = "$(AVRDUDE_WRITE_FLASH)"
	: ARDUINO_DIR = "$(ARDUINO_DIR)"
	: ARDUINO_CORE = "$(ARDUINO_CORE)"
	: ARDUINO_VARIANT = "$(ARDUINO_VARIANT)"
	: ARDUINO_LIBS = "$(ARDUINO_LIBS)"
	: ALIBDIRS = "$(ALIBDIRS)"
	: USER_LIBS = "$(USER_LIBS)"
	: ULIBDIRS = "$(ULIBDIRS)"
	: CINCS = "$(CINCS)"
	: SRC = "$(SRC)"
	: CXXSRC = "$(CXXSRC)"
	: CXXSRCINO = "$(CXXSRCINO)"
	: ASRC = "$(ASRC)"
	: ULIBSRC = "$(ULIBSRC)"
	: ULIBCXXSRC = "$(ULIBCXXSRC)"
	: ALIBSRC = "$(ALIBSRC)"
	: ALIBCXXSRC = "$(ALIBCXXSRC)"
	: CORESRC = "$(CORESRC)"
	: CORECXXSRC = "$(CORECXXSRC)"
	: CFLAGS = "$(CFLAGS)"
	: CXXFLAGS = "$(CXXFLAGS)"
	: COREOBJ = "$(COREOBJ)"
	: ALIBOBJ = "$(ALIBOBJ)"
	: ULIBOBJ = "$(ULIBOBJ)"
	: OBJ = "$(OBJ)"
	: ALLOBJ = "$(ALLOBJ)"
	: ALLDEPS = "$(ALLDEPS)"
	: VPATH = "$(VPATH)"
	: VID = "$(VID)"
	: PID = "$(PID)"
	: MODEL_PATTERN_MATCHING = "$(MODEL_PATTERN_MATCHING)"

mkout $(OUTPUT):
	mkdir -p $(OUTPUT)

# Create core library.
$(OUTPUT)/libcore.a: $(COREOBJ)
	$(AR) rcsv $@ $(COREOBJ)

# Creating these other .a libraries is an experiment to find out whether
# it reduces code size further. It doesn't, except for libcore.a.
$(OUTPUT)/libduino.a: $(ALIBOBJ)
	$(AR) rcsv $@ $(ALIBOBJ)

$(OUTPUT)/libduinoall.a: CINCS += $(ALIBALLDIRS:%=-I%)
$(OUTPUT)/libduinoall.a: $(ALIBALLOBJ)
	$(AR) rcsv $@ $(ALIBALLOBJ)

$(OUTPUT)/libuser.a: $(ULIBOBJ)
	$(AR) rcsv $@ $(ULIBOBJ)

$(OUTPUT)/libapp.a: $(OBJ)
	$(AR) rcsv $@ $(OBJ)

$(OUTPUT)/libapp2.a: $(OBJ)
	$(AR) rcsv $@ $(filter-out $(OUTPUT)/$(PROJECT).o,$(OBJ))

$(OUTPUT)/liball.a: $(ULIBOBJ) $(ALIBOBJ) $(COREOBJ)
	$(AR) rcsv $@ $(ULIBOBJ) $(ALIBOBJ) $(COREOBJ)

# Link program from objects and libraries.
$(OUTPUT)/$(PROJECT).elf: $(ALLOBJ) $(OUTPUT)/libcore.a
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(OBJ) \
		$(ULIBOBJ) \
		$(ALIBOBJ) \
		-L$(OUTPUT) -lcore $(LDLIBS)

# Alternative linking. Experimental, goes with the additional .a libraries.
# Don't make this dependent on $(OUTPUT), or circular re-makes occur.
# _5.elf fails linking with unresolved setup(), loop().
$(OUTPUT)/$(PROJECT)_2.elf: $(ALLOBJ)
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(OBJ) $(ULIBOBJ) $(ALIBOBJ) $(COREOBJ) \
		$(LDLIBS)
$(OUTPUT)/$(PROJECT)_3.elf: $(ALLOBJ)
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(COREOBJ) $(ALIBOBJ) $(ULIBOBJ) $(OBJ) \
		$(LDLIBS)
$(OUTPUT)/$(PROJECT)_4.elf: $(ALLOBJ) $(OUTPUT)/libcore.a \
				$(OUTPUT)/libduino.a $(OUTPUT)/libuser.a
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(OBJ) \
		-L$(OUTPUT) -luser -lduino -lcore $(LDLIBS)
$(OUTPUT)/$(PROJECT)_5.elf: $(ALLOBJ) $(OUTPUT)/libcore.a \
		   $(OUTPUT)/libduino.a $(OUTPUT)/libuser.a $(OUTPUT)/libapp.a
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		-L$(OUTPUT) -lapp -luser -lduino -lcore $(LDLIBS)
$(OUTPUT)/$(PROJECT)_6.elf: $(ALLOBJ) $(OUTPUT)/libcore.a \
		   $(OUTPUT)/libduino.a $(OUTPUT)/libuser.a $(OUTPUT)/libapp2.a
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(OUTPUT)/$(PROJECT).o \
		-L$(OUTPUT) -lapp2 -luser -lduino -lcore $(LDLIBS)
# Try compiling in one big step, to ensure LTO works.
# Doesn't link - collect2 says Wire.cpp has undef refs to functions in twi.c.
# Changing order of sources doesn't fix that.
$(OUTPUT)/$(PROJECT)_7.elf: $(ALLOBJ) $(OUTPUT)/libcore.a \
		   $(OUTPUT)/libduino.a $(OUTPUT)/libuser.a $(OUTPUT)/libapp.a
	$(CXX) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(SRC) $(CXXSRC) \
		$(ULIBSRC) $(ULIBCXXSRC) \
		$(ALIBSRC) $(ALIBCXXSRC) \
		$(CORESRC) $(CORECXXSRC) \
		$(filter-out -g2 -gstabs -std=gnu++0x -pedantic \
			-Wextra,$(CXXFLAGS)) -fwhole-program -v \
		$(CINCS) \
		$(LDLIBS)
$(OUTPUT)/$(PROJECT)_8.elf: $(ALLOBJ) $(OUTPUT)/libcore.a \
				$(OUTPUT)/libduinoall.a
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(OBJ) \
		$(ULIBOBJ) \
		-L$(OUTPUT) -lduinoall -lcore $(LDLIBS)
$(OUTPUT)/$(PROJECT)_9.elf: $(ALLOBJ) $(OUTPUT)/liball.a
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(OBJ) \
		-L$(OUTPUT) -lall $(LDLIBS)
$(OUTPUT)/$(PROJECT)_A.elf: $(ALLOBJ) $(OUTPUT)/libcore.a \
				$(OUTPUT)/libduino.a
	$(CC) $(LDFLAGS) -Wl,-Map,$*.map,--cref -o $@ \
		$(OBJ) $(ULIBOBJ) \
		-L$(OUTPUT) -lduino -lcore $(LDLIBS)

# Convert ELF to COFF for use in debugging / simulating in AVR Studio or VMLAB.
# UNTESTED
COFFCONVERT=$(OBJCOPY) --debugging \
    --change-section-address .data-0x800000 \
    --change-section-address .bss-0x800000 \
    --change-section-address .noinit-0x800000 \
    --change-section-address .eeprom-0x810000
coff: $(OUTPUT)/$(PROJECT).elf
	$(COFFCONVERT) -O coff-avr $(OUTPUT)/$(PROJECT).elf $(PROJECT).cof
extcoff: $(OUTPUT)/$(PROJECT).elf
	$(COFFCONVERT) -O coff-ext-avr $(OUTPUT)/$(PROJECT).elf $(PROJECT).cof

# Display size of file.
# (Actually, sizes of all $(PROJECT) .elf and .hex in $(OUTPUT).)
size:
	@echo; #echo
	-$(SIZE) $(OUTPUT)/$(PROJECT)*.elf
	@echo
	-$(SIZE) --target=$(HEXFORMAT) $(OUTPUT)/$(PROJECT)*.hex
	@#echo

# Reset the Arduino board before uploading a new program.
# The Arduino is reset on a rising edge of DTR; to make it always happen,
# make sure to set the output low before setting it high.
# Alternatively perl and python programs can be used (stty is faster).
reset: reset_$(RESETCMD)
reset_stty:
	$(STTY) -hupcl; sleep 0.1
	$(STTY) hupcl; sleep 0.1
	$(STTY) -hupcl

# Reset the Arduino board: Perl version needs libdevice-serialport-perl.
# zypper -vv in perl-Device-SerialPort
reset_perl:
	perl -MDevice::SerialPort -e \
	  'Device::SerialPort->new("$(PORT)")->pulse_dtr_off(100)'

# Reset the Arduino board: Python version needs python-serial.
# zypper -vv in python-serial
reset_python:
	python -c "\
	import serial; import time; \
	p = serial.Serial('$(PORT)', 57600); \
	p.setDTR(False); \
	time.sleep(0.1); \
	p.setDTR(True)"

# Show the current state of the DTR line.
dtr:
	$(STTY) -a | tr ' ' '\n' | grep hupcl

# Program the Arduino board (upload program).
upload up: hex reset
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)

# Create tar file.
# TODO: Dependencies on the header files are missing.
TAREXCL=	$(OUTPUT) back build debug
$(TARFILE).bz2: $(SRC) $(CXXSRC)
	PRJBASE=$$(basename "$$PWD"); \
	cd ..; \
	tar -cvf "$(TARFILE)$(suffix $@)" --bzip2 \
	  $(patsubst %,--exclude "%", $(TAREXCL)) \
	  $(patsubst %,--exclude "$(TARFILE)%", $(suffix $@) .??? .??) \
	  --owner=root --group=root "$$PRJBASE" \
	&& mv "$(TARFILE)$(suffix $@)" "$$OLDPWD" \
	&& echo "" && echo "Created $(TARFILE)$(suffix $@)"
$(TARFILE).xz: $(SRC) $(CXXSRC)
	PRJBASE=$$(basename "$$PWD"); \
	cd ..; \
	tar -cvf "$(TARFILE)$(suffix $@)" --xz \
	  $(patsubst %,--exclude "%", $(TAREXCL)) \
	  $(patsubst %,--exclude "$(TARFILE)%", $(suffix $@) .??? .??) \
	  --owner=root --group=root "$$PRJBASE" \
	&& mv "$(TARFILE)$(suffix $@)" "$$OLDPWD" \
	&& echo "" && echo "Created $(TARFILE)$(suffix $@)"

# Single dependencies file for all sources.
# This doesn't really work, so don't use it.
depend: $(OUTPUT) $(CXXSRCINO)
	$(CC) -M -mmcu=$(MCU) $(CDEFS) \
	    $(CINCS) \
	    $(CORESRC) \
	    $(ALIBSRC) \
	    $(ULIBSRC) \
	    $(SRC) $(ASRC) \
	    > $(DEPFILE)
	$(CXX) -M -mmcu=$(MCU) $(CDEFS) \
	    $(CINCS) \
	    $(CORECXXSRC) \
	    $(ALIBCXXSRC) \
	    $(ULIBCXXSRC) \
	    $(CXXSRC) \
	    >> $(DEPFILE)

# Target: clean project.
CLEANEXT = .elf .hex .eep .cof .lss .sym .listing .symbol .map .log
CLEANPRG = $(foreach p,_2 _3 _4 _5 _6 _7 _8 _9 _A,$(patsubst %,$p%,$(CLEANEXT)))
clean:
	-$(RM) \
	  $(DEPFILE) \
	  $(OUTPUT)/$(PROJECT).cpp \
	  $(CLEANEXT:%=$(OUTPUT)/$(PROJECT)%) \
	  $(CLEANPRG:%=$(OUTPUT)/$(PROJECT)%) \
	  $(patsubst %,$(OUTPUT)/lib%.a,core duino user app app2 duinoall all) \
	  $(ALLOBJ) \
	  $(ALLDEPS) \
	  $(ALLOBJ:%.o=%.S) \
	  $(ALIBALLOBJ) $(ALIBALLOBJ:.o=.d) \
	  $(ALLOBJ:%.o=%.s) \
	  $(ALLOBJ:%.o=%.i) \
	  $(ALLOBJ:%.o=%.ii) \
	  $(notdir $(ALLOBJ:%.o=%.s) $(ALLOBJ:%.o=%.i) $(ALLOBJ:%.o=%.ii))
	-test ! -d $(OUTPUT) || $(RMDIR) $(OUTPUT)


### Dependencies file and source path.

# This must be after the first explicit rule.

-include $(DEPFILE)

-include $(ALLDEPS)

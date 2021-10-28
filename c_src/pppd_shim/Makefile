# Makefile for building the pppd shim
#
# Makefile targets:
#
# all/install   build and install the SHIM
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_APP_PATH  path to the build directory
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# LDFLAGS	linker flags for linking all binaries

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj/pppd_shim

SHIM = $(PREFIX)/pppd_shim.so

CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter -pedantic
LDFLAGS += -fPIC -shared -ldl
CFLAGS += -fPIC

# Check that we're on a supported build platform
ifeq ($(CROSSCOMPILE),)
    # Not crosscompiling, so check that we're on Linux.
    ifneq ($(shell uname -s),Linux)
        $(warning VintageNetMobile only works on Nerves and Linux platforms.)
        $(warning Skipping compilation.)
        SHIM :=
    endif
endif

SRC = pppd_shim.c
OBJ = $(SRC:%.c=$(BUILD)/%.o)

all: install

install: $(PREFIX) $(BUILD) $(SHIM)

$(OBJ): $(HEADERS) Makefile

$(BUILD)/%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(SHIM): $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $^

$(PREFIX) $(BUILD):
	mkdir -p $@

clean:
	$(RM) $(SHIM) $(OBJ)

.PHONY: all clean install

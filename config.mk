# output program shall be APPNAME.elf.  default is commented out beneath.
#APPNAME := $(shell basename $(CURDIR))
APPNAME := $(shell basename $(CURDIR))
BUILD_CORTEX_M0 := true


CFLAGS_TARG =
#add lib(s) according to flags
ifeq ($(BUILD_CORTEX_M0), true)
CFLAGS_TARG+=-mlittle-endian -mcpu=cortex-m0  -march=armv6-m -mthumb
endif
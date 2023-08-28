# chip-specific parameters
BUILD_CORTEX_M0 := true

CFLAGS_TARG :=
#add lib(s) according to flags
ifeq ($(BUILD_CORTEX_M0), true)
CFLAGS_TARG+=-mlittle-endian -mcpu=cortex-m0  -march=armv6-m -mthumb
endif
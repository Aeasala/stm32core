#simple flags for adding certain libraries
BUILD_SDL := false
BUILD_WINSOCK := false

#add lib(s) according to flags
ifeq ($(BUILD_SDL), true)
LIBADD += -lSDL2
endif

ifeq ($(BUILD_WINSOCK), true)
LIBADD += -lws2_32 -lmswsock -ladvapi32
endif
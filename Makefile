# Initial template: Credits to Tom Daley
#     https://gist.github.com/tomdaley92/190c68e8a84038cc91a5459409e007df

# A generic build template for C/C++ programs

# executable name: default is containing folder's name.
SRCS = src/main.c src/system_stm32f0xx.c

EXE = $(shell basename $(CURDIR))
BSP=BSP
STD_PERIPH_LIB=$(BSP)
LDSCRIPT_INC=Device/ldscripts

GCC_BASE = C:/ARM/12_3_rel1/bin
# C compiler
CC = "$(GCC_BASE)/arm-none-eabi-gcc.exe"
# C++ compiler
CXX = "$(GCC_BASE)/arm-none-eabi-g++.exe"
# linker
LD = "$(GCC_BASE)/arm-none-eabi-g++.exe"

#other utils
OBJCOPY="$(GCC_BASE)/arm-none-eabi-objcopy.exe"
OBJDUMP="$(GCC_BASE)/arm-none-eabi-objdump.exe"
SIZE="$(GCC_BASE)/arm-none-eabi-size.exe"


# get target-specific flags
-include targets.mk

# C flags
CFLAGS  = -Wall -g -std=c99 -Os  
CFLAGS += $(CFLAGS_TARG)
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections -Wl,-Map=$(BIN)/$(EXE).map

##########################################

vpath %.c src
vpath %.a $(STD_PERIPH_LIB)

ROOT=$(shell pwd)

CFLAGS += -I inc -I $(STD_PERIPH_LIB) -I $(STD_PERIPH_LIB)/CMSIS/Device/ST/STM32F0xx/Include
CFLAGS += -I $(STD_PERIPH_LIB)/CMSIS/Include -I $(STD_PERIPH_LIB)/STM32F0xx_StdPeriph_Driver/inc
CFLAGS += -include $(STD_PERIPH_LIB)/stm32f0xx_conf.h

SRCS += Device/startup_stm32f0xx.s # add startup file to build
OBJS = $(SRCS:.c=.o)

# dependency-generation flags
DEPFLAGS = -MM -MG -MT

# primary linker flags
# win
ifeq ($(shell uname -a | grep -ic CYGWIN_NT), 1)
LDFLAGS +=
# lin
else ifeq ($(shell uname -a | grep -ic Linux), 1)
ENTRYPT = _start	
LDFLAGS += -Wl,--entry=$(ENTRYPT) -lm
# etc
else
LDFLAGS +=
endif

ifneq ($(MAKECMDGOALS),nomap)
LDFLAGS += -Wl,-Map=$(BIN)/$(EXE).map -lm -Wl,--cref
endif

#additional linker flags
LDFLAGS += 

# library flags, pulled from the concat within libs.mk
-include libs.mk
LDLIBS = $(LIBADD)

# build directories
BIN = bin
OBJ = obj
SRC = src
	


# TODO
#-include $(SRC)/subdir.mk
	
# include compiler-generated dependency rules
#  | sed "s,\(\)\.o[ :]*,\1.o $@ $(@:.d=.pp) $(@:.d=.su) : ,g"
DEPENDS := $(OBJECTS:.o=.d)
DEPEND.c = $(CC) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.c) 
DEPEND.cxx = $(CXX) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.cpp) 


# compile C source
COMPILE.c = $(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ -L$(STD_PERIPH_LIB) -lstm32f0 -L$(LDSCRIPT_INC) -Tstm32f0.ld
# compile C++ source
COMPILE.cxx = $(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ -L$(STD_PERIPH_LIB) -lstm32f0 -L$(LDSCRIPT_INC) -Tstm32f0.ld
# link objects
LINK.o = $(LD) $(LDFLAGS) $(OBJECTS) -o $@ $(LDLIBS)

.DEFAULT_GOAL = all

.PHONY: lib all nomap
all nomap: lib $(BIN)/$(EXE).elf 
	
	
lib:
	$(MAKE) -C $(STD_PERIPH_LIB)

$(BIN)/$(EXE).elf: $(SRCS)
	$(CC) $(CFLAGS) $^ -o $@ -L$(STD_PERIPH_LIB) -lstm32f0 -L$(LDSCRIPT_INC) -Tstm32f0.ld
	$(OBJCOPY) -O ihex $(BIN)/$(EXE).elf $(BIN)/$(EXE).hex
	$(OBJCOPY) -O binary $(BIN)/$(EXE).elf $(BIN)/$(EXE).bin
	$(OBJDUMP) -St $(BIN)/$(EXE).elf >$(BIN)/$(EXE).lst
	$(SIZE) $(BIN)/$(EXE).elf

	$(info Linking target $@ from $<)

$(SRC):
	$(info ./$(SRC) directory not found, creating ./$(SRC))
	@mkdir -p $(SRC)

$(OBJ):
	$(info ./$(OBJ) directory not found, creating ./$(OBJ))
	@mkdir -p $(OBJ)

$(BIN):
	$(info ./$(BIN) directory not found, creating ./$(BIN))
	@mkdir -p $(BIN)


# force rebuild
.PHONY: remake
remake:	clean $(BIN)/$(EXE).elf

# execute the program
.PHONY: run
run: $(BIN)/$(EXE).elf
	@./$(BIN)/$(EXE).elf

# remove previous build and objects
.PHONY: clean
clean:
	$(info Removing (.o)bject files...)
	@$(RM) $(OBJECTS)
	$(info Removing (.d)ependencies...)
	@$(RM) $(DEPENDS)
	$(info Removing binaries/executables...)
	@$(RM) $(BIN)/$(EXE)
	@$(RM) $(BIN)/$(EXE).elf
	@$(RM) $(BIN)/$(EXE).map

# remove everything except source
.PHONY: reset
reset:
	$(RM) -r $(OBJ)
	$(RM) -r $(BIN)

# dependencies want to get rebuilt on clean for some reason, bluntly ignore it
ifneq ($(MAKECMDGOALS),clean)
-include $(DEPENDS)
endif

# Initial template: Credits to Tom Daley
#     https://gist.github.com/tomdaley92/190c68e8a84038cc91a5459409e007df

# A generic build template for C/C++ programs

####################################################################################
####################################################################################

include config.mk
# executable name: default is containing folder's name.
EXE = $(APPNAME)

# BSP and provided linker scripts
BSP=bsp
STD_PERIPH_LIB=$(SRC)/$(BSP)
LDSCRIPT_INC=$(SRC)/dev

####################################################################################
####################################################################################

# C compiler
CC = arm-none-eabi-gcc
# C++ compiler
CXX = arm-none-eabi-g++
# linker
LD = arm-none-eabi-g++
#other utils
OBJCOPY=arm-none-eabi-objcopy
OBJDUMP=arm-none-eabi-objdump
SIZE=arm-none-eabi-size


# get target-specific flags
-include targets.mk

# C flags. CFLAGS_TARG is chip-specific to the STM32.
CFLAGS  = -Wall -g -std=c99 -Os  
CFLAGS += $(CFLAGS_TARG)
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections

####################################################################################
####################################################################################

# dependencies and includes.  may remove
vpath %.c src
vpath %.a $(STD_PERIPH_LIB)

ROOT=$(shell pwd)

# keep these as is.
CFLAGS += -I inc -I$(STD_PERIPH_LIB) -I $(STD_PERIPH_LIB)/CMSIS/Device/ST/STM32F0xx/Include
CFLAGS += -I $(STD_PERIPH_LIB)/CMSIS/Include -I $(STD_PERIPH_LIB)/STM32F0xx_StdPeriph_Driver/inc
FLAGS += -include $(SRC)/stm32f0xx_conf.h

####################################################################################
####################################################################################

# build directories and eventual item goals
BIN = bin
OBJ = obj
SRC = src

SOURCES := $(wildcard $(SRC)/dev/*.s $(SRC)/*.c $(SRC)/*.cc $(SRC)/*.cpp $(SRC)/*.cxx)
OBJECTS := \
	$(patsubst $(SRC)/dev/%.s,$(SRC)/dev/%.o,$(wildcard $(SRC)/dev/*.s)) \
	$(patsubst $(SRC)/%.c,$(SRC)/%.o,$(wildcard $(SRC)/*.c)) \
	$(patsubst $(SRC)/%.cc,$(SRC)/%.o,$(wildcard $(SRC)/*.cc)) \
	$(patsubst $(SRC)/%.cpp,$(SRC)/%.o,$(wildcard $(SRC)/*.cpp)) \
	$(patsubst $(SRC)/%.cxx,$(SRC)/%.o,$(wildcard $(SRC)/*.cxx))

#for subdirectory inclusion, if specified.
-include $(SRC)/subdir.mk

####################################################################################
####################################################################################

# primary linker flags -- do we need a specific entry point?
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

#make a .map file of our linked program.
ifneq ($(MAKECMDGOALS),nomap)
LDFLAGS += -Wl,-Map=$(BIN)/$(EXE).map -lm -Wl,--cref
endif

#additional linker flags
LDFLAGS += 

# library flags, pulled from the concat within libs.mk
-include libs.mk
LDLIBS = $(LIBADD)

####################################################################################
####################################################################################
	
# TODO
#-include $(SRC)/subdir.mk
	
# include compiler-generated dependency rules
# dependency-generation flags
DEPFLAGS = -MM -MG -MT
#  | sed "s,\(\)\.o[ :]*,\1.o $@ $(@:.d=.pp) $(@:.d=.su) : ,g"
DEPENDS := $(OBJECTS:.o=.d)
DEPEND.c = $(CC) $(CFLAGS) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.c) 
DEPEND.s = $(CC) $(CFLAGS) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.s) 
DEPEND.cxx = $(CXX) $(CFLAGS) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.cpp) 

# dependencies want to get rebuilt on clean for some reason, bluntly ignore it
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),cleanall)
ifneq ($(MAKECMDGOALS),lib)
-include $(DEPENDS)
endif
endif
endif

# compile C source
COMPILE.c = $(CC) $(FLAGS) $(CFLAGS) -c -o $@ -L$(STD_PERIPH_LIB) -lstm32f0 -L$(LDSCRIPT_INC)
# compile C++ source
COMPILE.cxx = $(CXX) $(FLAGS) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ -L$(STD_PERIPH_LIB) -lstm32f0 -L$(LDSCRIPT_INC) -Tstm32f0.ld
# link objects
LINK.o = $(LD) $(FLAGS) $(CFLAGS) $(LDFLAGS) -o $@ -L$(STD_PERIPH_LIB) -lstm32f0 -L$(LDSCRIPT_INC) -Tstm32f0.ld $(LDLIBS)

####################################################################################
####################################################################################

#Targets 

.DEFAULT_GOAL = all

.PHONY: all nomap
all nomap: $(BIN)/$(EXE).elf

.PHONY: lib
lib: $(SRC)/bsp/libstm32f0.a
$(SRC)/bsp/libstm32f0.a:
	$(MAKE) -C $(STD_PERIPH_LIB)
	# removes object files after library built - no point in keeping them with the lib
	$(MAKE) -C $(STD_PERIPH_LIB) clean
	

#.elf requires the lib file (made in bsp folder)
#Linking
$(BIN)/$(EXE).elf: $(BIN)/$(EXE).ld $(OBJECTS) $(SRC)/bsp/libstm32f0.a 
	$(info Linking target $@ from $<)
	$(LINK.o) $(OBJECTS)
	$(OBJCOPY) -O ihex $(BIN)/$(EXE).elf $(BIN)/$(EXE).hex
	$(OBJCOPY) -O binary $(BIN)/$(EXE).elf $(BIN)/$(EXE).bin
	$(OBJDUMP) -St $(BIN)/$(EXE).elf >$(BIN)/$(EXE).lst
	$(SIZE) $(BIN)/$(EXE).elf
	
$(BIN)/$(EXE).ld: $(SRC)/Application.h $(LDSCRIPT_INC)/stm32f0.ld $(OBJECTS)
	$(info yahooooooooooooo)
	@$(CC) -I$(SRC)/Application.h -P -E -x c $(SRC)/dev/stm32f0.ld -o $(BIN)/$(EXE).ld
	
$(SRC):
	$(info ./$(SRC) directory not found, creating ./$(SRC))
	@mkdir -p $(SRC)

$(BIN):
	$(info ./$(BIN) directory not found, creating ./$(BIN))
	@mkdir -p $(BIN)

#Dependency building.
%.d: %.s
	$(info Rebuilding dependencies for $(@:.d=.s))
	@$(DEPEND.s) $< > $@

%.d: %.c
	$(info Rebuilding dependencies for $(@:.d=.c))
	@$(DEPEND.c) $< > $@

%.d: %.cc
	$(info Rebuilding dependencies for $(@:.d=.cc))
	@$(DEPEND.cxx) $< > $@

%.d: %.cpp
	$(info Rebuilding dependencies for $(@:.d=.cpp))
	@$(DEPEND.cxx) $< > $@

%.d: %.cxx
	$(info Rebuilding dependencies for $(@:.d=.cxx))
	@$(DEPEND.cxx) $< > $@

#Compiling
%.o: %.s
	$(info Compiling assembly file)
	$(info ..... ./$(@:.o=.s) ==> ./$(@))
	@$(COMPILE.c) $< 

%.o: %.c
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.c) ==> ./$(@))
	@$(COMPILE.c) $< 

%.o: %.cc
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.cc) ==> ./$(@))
	@$(COMPILE.cxx) $<

%.o: %.cpp
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.cpp) ==> ./$(@))
	@$(COMPILE.cxx) $<

%.o: %.cxx
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.cxx) ==> ./$(@))
	@$(COMPILE.cxx) $<

%.dasm: %.elf
	$(info Disassembling elf)
	$(info ..... ./$(@:.elf=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.elf) > $@

%.dasm: %.o
	$(info Disassembling object)
	$(info ..... ./$(@:.o=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.o) > $@
	
%.dasm: %.a
	$(info Disassembling library)
	$(info ..... ./$(@:.a=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.a) > $@

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
	@$(RM) $(BIN)/$(EXE).bin
	@$(RM) $(BIN)/$(EXE).hex
	@$(RM) $(BIN)/$(EXE).lst
	@$(RM) $(BIN)/$(EXE).dasm
	@$(RM) $(BIN)/$(EXE).ld
	@$(RM) $(OBJECTS:.o=.dasm)
	@$(RM) $(SRC)/bsp/libstm32f0.dasm

#remove everything, including the lib file
.PHONY: cleanall
cleanall: clean
	$(MAKE) -C $(STD_PERIPH_LIB) cleanTrue
	
.PHONY: dasm
dasm: $(BIN)/$(EXE).dasm
	$(info Disassembling "$(BIN)/$(EXE).elf" to "$(BIN)/$(EXE).dasm")
	@$(OBJDUMP) -d $(BIN)/$(EXE).elf > $(BIN)/$(EXE).dasm

.PHONY: dasmall
dasmall: $(BIN)/$(EXE).dasm $(OBJECTS:.o=.dasm) $(SRC)/bsp/libstm32f0.dasm
	
# remove everything except source
.PHONY: reset
reset:
	$(RM) -r $(BIN)

.PHONY: help
help:
	$(info clean: removes all objects, dependencies, and executables)
	$(info cleanall: removes everything from clean as well as the generated library file)
	$(info remake: cleans and rebuilds the program)
	$(info nomap: omits the map file)
	$(info lib: just generate the library)
	$(info dasmall: disassemble everything)
	$(info dasm: disassemble the elf)
	
	
	
# By: Evan MacDonald
# STM32 Core Template.

####################################################################################
####################################################################################

# executable name: default is containing folder's name.
ifdef APPNAME
	EXE = $(APPNAME)
else
	EXE = $(shell basename $(CURDIR))
endif

# BSP and provided linker scripts.  APPBIN is app-level output folder. (end result goes out here)
APPBIN = bin

# Stuff within this folder.
BIN = $(CORE)/bin
BSP = $(CORE)/bsp
LDSCRIPT_INC=$(CORE)/dev

####################################################################################
# Toolchain Aliases ################################################################
####################################################################################

# C compiler
CC = arm-none-eabi-gcc
# linker
LD = arm-none-eabi-gcc
#other utils
OBJCOPY=arm-none-eabi-objcopy
OBJDUMP=arm-none-eabi-objdump
SIZE=arm-none-eabi-size

####################################################################################
# Compiler and Linker flags ########################################################
####################################################################################

include $(CORE)/coretarget.mk

# Common to all.
FLAGS :=

# C flags. CFLAGS_TARG is chip-specific to the STM32.
CFLAGS = $(FLAGS)
CFLAGS += -Wall -g -std=c99 -Os  
CFLAGS += $(CFLAGS_TARG)
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections

# Linker flags.  CFLAGS are tied-in.
# Creates a .map of the program, unless the target specifies.
LDFLAGS = $(FLAGS)
LDFLAGS += $(CFLAGS)
ifneq ($(MAKECMDGOALS),nomap)
LDFLAGS += -Wl,-Map=$(APPBIN)/$(EXE).map -lm -Wl,--cref
endif

ADDLIBS = -L$(BSP) -lstm32f0

####################################################################################
# Path and File includes ###########################################################
####################################################################################

# The CMSIS and StdPeriph libraries are required.
# Application.h contains preprocessor directives that are required.
INCLUDES = -I $(BSP)/CMSIS/Device/ST/STM32F0xx/Include
INCLUDES += -I $(BSP)/CMSIS/Include -I $(BSP)/STM32F0xx_StdPeriph_Driver/inc
INCLUDES += -I. -include Application.h

####################################################################################
# Target Gathering #################################################################
####################################################################################

# All files at the top level, i.e. ./CORE/*, will be compiled and linked.
CORESOURCES := $(wildcard $(CORE)/dev/*.s $(CORE)/*.c)
COREOBJECTS := \
	$(patsubst $(CORE)/dev/%.s,$(CORE)/dev/%.o,$(wildcard $(CORE)/dev/*.s)) \
	$(patsubst $(CORE)/%.c,$(CORE)/%.o,$(wildcard $(CORE)/*.c))

# Any additional folders to be compiled should be defined in "coremodules.mk".
# This include call will append onto CORESOURCES, COREOBJECTS
-include $(CORE)/coremodules.mk
include $(patsubst %,$(CORE)/%/subdir.mk,$(COREMODULES))

ALLSOURCES := $(CORESOURCES) $(SOURCES)
ALLOBJECTS := $(COREOBJECTS) $(OBJECTS)

####################################################################################
# Dependencies of Gathered Targets #################################################
####################################################################################

# Flags to create dependencies from a provided source file list.
DEPFLAGS = -MM -MG -MT

# Dependencies shall be named after their origin, placed in the same folder.
DEPENDS := $(ALLOBJECTS:.o=.d)

# dependencies want to get rebuilt on clean for some reason, bluntly ignore it
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),cleanall)
ifneq ($(MAKECMDGOALS),lib)
ifneq ($(MAKECMDGOALS),remake)
-include $(DEPENDS)
endif
endif
endif
endif

####################################################################################
# Methods to reach target goals ####################################################
####################################################################################

# create dependencies of C or asm file.  asm is non-functional, but here.
DEPEND.s = $(CC) $(INCLUDES) $(FLAGS) $(CFLAGS) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.s) 
DEPEND.c = $(CC) $(INCLUDES) $(FLAGS) $(CFLAGS) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.c) 

# compile C (or asm) source. -c is compile without linking
COMPILE.c = $(CC) $(INCLUDES) $(FLAGS) $(CFLAGS) -c -o $@ 
# link objects.  need build-specific ld file
LINK.o = $(LD) $(INCLUDES) $(FLAGS) $(LDFLAGS) -o $@ -L$(APPBIN) -T$(EXE).ld

####################################################################################
# Goals and routines ###############################################################
####################################################################################
.DEFAULT_GOAL = all

.PHONY: all nomap
all nomap: $(APPBIN)/$(EXE).elf

.PHONY: lib
lib: $(BSP)/libstm32f0.a
$(BSP)/libstm32f0.a:
	$(info Rebuilding $(@))
	$(info )
	@$(MAKE) --no-print-directory -C $(BSP)
	@$(MAKE) --no-print-directory -C $(BSP) clean

# Conditions/requires to prevent out-of-order assembling.
$(DEPENDS): $(BSP)/libstm32f0.a
$(COREOBJECTS): $(BSP)/libstm32f0.a

# Final goal: elf file.  Follows tree of needing .ld, library, and compiled objects.
$(APPBIN)/$(EXE).elf: $(APPBIN)/$(EXE).ld $(BSP)/libstm32f0.a $(ALLOBJECTS)
	@mkdir -p bin
	$(info Linking target "$@" using "$<"...)
	@$(LINK.o) $(ALLOBJECTS) $(ADDLIBS)
	$(info Creating hex...)
	@$(OBJCOPY) -O ihex $(APPBIN)/$(EXE).elf $(APPBIN)/$(EXE).hex
	$(info Creating bin...)
	@$(OBJCOPY) -O binary $(APPBIN)/$(EXE).elf $(APPBIN)/$(EXE).bin
	$(info Dumping symbol table...)
	@$(OBJDUMP) -St $(APPBIN)/$(EXE).elf >$(APPBIN)/$(EXE).lst
	$(info ---------------------------------------)
	$(info Done.  Executable size/composition:)
	@$(SIZE) $(APPBIN)/$(EXE).elf

#application-specific .ld generation.  based on preproc defs in Application.h, such as the chip #define
$(APPBIN)/$(EXE).ld: Application.h $(LDSCRIPT_INC)/core.ld $(BSP)/libstm32f0.a $(ALLOBJECTS)
	@mkdir -p bin
	$(info Generating linker-directive file "$@" from preprocessor definitions...)
	@$(CC) $(INCLUDES) -P -E -x c $(LDSCRIPT_INC)/core.ld -o $(APPBIN)/$(EXE).ld

###############################
# Dependency Generation #######
###############################
%.d: %.s
	$(info Rebuilding dependencies for $(@:.d=.s))
	@$(DEPEND.s) $< > $@ $(ADDLIBS)

%.d: %.c
	$(info Rebuilding dependencies for $(@:.d=.c))
	@$(DEPEND.c) $< > $@ $(ADDLIBS)

###############################
# Compiling ###################
###############################
%.o: %.s
	$(info Compiling assembly file)
	$(info ..... ./$(@:.o=.s) ==> ./$(@))
	@$(COMPILE.c) $< $(ADDLIBS) 
	$(info )

%.o: %.c
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.c) ==> ./$(@))
	@$(COMPILE.c) $< $(ADDLIBS) 
	$(info )

###############################
# Disassembly #################
###############################
%.dasm: %.elf
	$(info Disassembling elf)
	$(info ..... ./$(@:.elf=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.elf) > $@
	$(info )

%.dasm: %.o
	$(info Disassembling object)
	$(info ..... ./$(@:.o=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.o) > $@
	$(info )

%.dasm: %.a
	$(info Disassembling library)
	$(info ..... ./$(@:.a=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.a) > $@
	$(info )

###############################
# Other goals #################
###############################
# force rebuild
.PHONY: remake
remake: clean
	@$(MAKE) --no-print-directory $(APPBIN)/$(EXE).elf

# remove previous build and objects
.PHONY: clean
clean:
	$(info Removing (.o)bject files...)
	@$(RM) $(ALLOBJECTS)
	$(info Removing (.d)ependencies...)
	@$(RM) $(DEPENDS)
	$(info Removing binaries/executables...)
	@$(RM) $(APPBIN)/$(EXE)
	@$(RM) $(APPBIN)/$(EXE).elf
	@$(RM) $(APPBIN)/$(EXE).map
	@$(RM) $(APPBIN)/$(EXE).bin
	@$(RM) $(APPBIN)/$(EXE).hex
	@$(RM) $(APPBIN)/$(EXE).lst
	@$(RM) $(APPBIN)/$(EXE).dasm
	@$(RM) $(APPBIN)/$(EXE).ld
	@$(RM) $(OBJECTS:.o=.dasm)
	@$(RM) $(BSP)/libstm32f0.dasm

#remove everything, including the lib file
.PHONY: cleanall
cleanall: clean
	@$(MAKE) --no-print-directory -C $(BSP) cleanTrue

#disassemble the elf, or everything
.PHONY: dasm
dasm: $(APPBIN)/$(EXE).dasm
	$(info Disassembling "$(APPBIN)/$(EXE).elf" to "$(APPBIN)/$(EXE).dasm")
	@$(OBJDUMP) -d $(APPBIN)/$(EXE).elf > $(APPBIN)/$(EXE).dasm

.PHONY: dasmall
dasmall: $(APPBIN)/$(EXE).dasm $(OBJECTS:.o=.dasm) $(BSP)/libstm32f0.dasm
	
#what's on the menu?
.PHONY: help
help:
	@echo > /dev/null
	$(info clean: removes all objects, dependencies, and executables)
	$(info cleanall: removes everything from clean as well as the generated library file)
	$(info remake: cleans and rebuilds the program)
	$(info nomap: omits the map file)
	$(info lib: just generate the library)
	$(info dasmall: disassemble everything)
	$(info dasm: disassemble the elf)
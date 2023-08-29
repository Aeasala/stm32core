# By: Evan MacDonald
# STM32 Core Template.
# Makefile in directory above defines $(CORE) as this folder.  working-directory is above.

####################################################################################
####################################################################################

# executable name: default is containing folder's name. ?= sets a default if upper-level makefile didn't
APPNAME ?= $(shell basename $(CURDIR))
EXE = $(APPNAME)

# APPBIN is app-level output folder. (technically ../bin w.r.t. this file's path)
APPBIN = bin

# Stuff within this folder.  
BIN = $(CORE)/bin
BSP = $(CORE)/bsp
LDSCRIPT_INC = $(CORE)/dev

####################################################################################
# Toolchain Aliases ################################################################
####################################################################################

# C compiler
CC = arm-none-eabi-gcc
# linker
LD = arm-none-eabi-gcc
#other utils
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size

####################################################################################
# Compiler and Linker flags ########################################################
####################################################################################

# Common to all.
FLAGS :=

# defines chip architecture, e.g. cortex m0
include $(CORE)/coretarget.mk

# C flags. CFLAGS_TARG is chip-specific to the STM32, from coretarget.mk
CFLAGS := $(FLAGS)
CFLAGS += $(CFLAGS_TARG)
CFLAGS += -Wall -g -std=c99 -Os  
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections

# Linker flags.  CFLAGS are tied-in.
LDFLAGS := $(FLAGS)
LDFLAGS += $(CFLAGS)
# are we also making a map?
ifneq ($(MAKECMDGOALS),nomap)
	LDFLAGS += -Wl,-Map=$(APPBIN)/$(EXE).map -lm -Wl,--cref
endif

# use libstm32f0.a if any references/functions needed from pre-included STM library
ADDLIBS = -L$(BSP) -lstm32f0

####################################################################################
# Path and File includes ###########################################################
####################################################################################

# The CMSIS and StdPeriph headers are required.  any of their compiled objects will be pulled from ADDLIBS
# Application.h contains preprocessor directives that are required.
INCLUDES = -I $(BSP)/CMSIS/Device/ST/STM32F0xx/Include
INCLUDES += -I $(BSP)/CMSIS/Include -I $(BSP)/STM32F0xx_StdPeriph_Driver/inc
INCLUDES += -I. -include Application.h

####################################################################################
# Target Gathering #################################################################
####################################################################################

# All files at the top level, including .s (typ. bootloader) in dev/
CORESOURCES := $(wildcard $(CORE)/dev/*.s $(CORE)/*.c)
# object files will neighbor sources, i.e. path stays same but becomes *.o
COREOBJECTS := \
	$(patsubst $(CORE)/dev/%.s,$(CORE)/dev/%.o,$(wildcard $(CORE)/dev/*.s)) \
	$(patsubst $(CORE)/%.c,$(CORE)/%.o,$(wildcard $(CORE)/*.c))


# Any additional folders to be compiled should be defined in "coremodules.mk".
include $(CORE)/coremodules.mk
# This include call will append onto CORESOURCES, COREOBJECTS from the imported list above
include $(patsubst %,$(CORE)/%/subdir.mk,$(COREMODULES))

# stitch together
ALLSOURCES = $(CORESOURCES) $(SOURCES)
ALLOBJECTS = $(COREOBJECTS) $(OBJECTS)

####################################################################################
# Dependencies of Gathered Targets #################################################
####################################################################################

# Flags to create dependencies from a provided source file list.
DEPFLAGS := -MM -MG -MT

# Dependencies shall be named after their origin, placed in the same folder.
DEPENDS = $(ALLOBJECTS:.o=.d)

# dependencies want to get rebuilt on clean for some reason, bluntly ignore it
# including the DEPENDS list will make our makefile super smart and recompile only what's needed
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
# Finally: Methods to reach target goals ###########################################
####################################################################################

# note: addlibs should come AFTER sources/objects on the COMPILE or LINK calls.
# if included before, unresolved references (functions) will not be sought out.
# ordering will resolve undefined refs on the left using remaining refs on the right

# create dependencies of a single C or asm file.  asm is non-functional, but here.
DEPEND.c = $(CC) $(INCLUDES) $(CFLAGS) $(DEPFLAGS) 
DEPEND.s = $(CC) $(INCLUDES) $(CFLAGS) $(DEPFLAGS)

# compile a single C (or asm) source. -c is compile without linking
COMPILE.c = $(CC) $(INCLUDES) $(CFLAGS) -c -o $@ 
COMPILE.s = $(CC) $(INCLUDES) $(CFLAGS) -c -o $@ 

# link a list of objects.  need build-specific ld file (found in APPBIN)
LINK.o = $(LD) $(INCLUDES) $(LDFLAGS) -o $@ -L$(APPBIN) -T$(EXE).ld

####################################################################################
# Goals and routines ###############################################################
####################################################################################
.DEFAULT_GOAL = all

# APPBIN/EXE.elf is the top-level output.  needed targets branch out from there.
.PHONY: all nomap
all nomap: $(APPBIN)/$(EXE).elf

# (B) make the library
# calls makefile in bsp/ directory
.PHONY: lib
lib: $(BSP)/libstm32f0.a
$(BSP)/libstm32f0.a:
	$(info Rebuilding $(@))
	$(info )
	@$(MAKE) --no-print-directory -C $(BSP)
	@$(MAKE) --no-print-directory -C $(BSP) clean

# Conditions/requires to prevent out-of-order assembling.  lib must be able to compile successfully before our program.
$(DEPENDS): $(BSP)/libstm32f0.a
$(ALLOBJECTS): $(BSP)/libstm32f0.a

########
# Final goal: elf file.  needs processed (A) linker script, (B) lib, and (C) compiled objects
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

# (A) application-specific .ld generation.  based on preproc defs in Application.h, such as the chip #define
# needs app.h preproc defs, raw linker script, (B) lib, and (C) compiled objects.
$(APPBIN)/$(EXE).ld: Application.h $(LDSCRIPT_INC)/core.ld
	@mkdir -p bin
	$(info Generating linker-directive file "$@" from preprocessor definitions...)
	@$(CC) $(INCLUDES) -P -E -x c $(LDSCRIPT_INC)/core.ld -o $(APPBIN)/$(EXE).ld

###############################
# Dependency Generation #######
###############################
# the sed call will also include the .d filename into the .d file

# make dependencies for an asm .s file
%.d: %.s
	$(info Rebuilding dependencies for "$(@:.d=.s)")
	@$(DEPEND.s) $(@:.d=.o) $< $(ADDLIBS) | sed "s,\(\)\.o[ :]*,\1.o $@ : ,g" > $@

# make dependencies for a .c file
%.d: %.c
	$(info Rebuilding dependencies for "$(@:.d=.c)")
	@$(DEPEND.c) $(@:.d=.o) $< $(ADDLIBS) | sed "s,\(\)\.o[ :]*,\1.o $@ : ,g" > $@

###############################
# Compiling ###################
###############################

# (C) compile an asm .s file to an object
%.o: %.s
	$(info Compiling assembly file)
	$(info ..... "./$(@:.o=.s)" ==> "./$(@)")
	@$(COMPILE.s) $< $(ADDLIBS) 
	$(info )

# (C) compile a .c file to an object
%.o: %.c
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.c) ==> ./$(@))
	@$(COMPILE.c) $< $(ADDLIBS) 
	$(info )

###############################
# Disassembly #################
###############################

# disassemble an elf executable
%.dasm: %.elf
	$(info Disassembling elf)
	$(info ..... ./$(@:.elf=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.elf) > $@
	$(info )

# disassemble an object
%.dasm: %.o
	$(info Disassembling object)
	$(info ..... ./$(@:.o=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.o) > $@
	$(info )

# disassemble a library
%.dasm: %.a
	$(info Disassembling library)
	$(info ..... ./$(@:.a=.dasm) ==> ./$(@))
	@$(OBJDUMP) -d $(@:.dasm=.a) > $@
	$(info )

###############################
# Other goals (utilities) #####
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
	@$(RM) $(APPBIN)/$(EXE).ld
	$(info Removing disassemblies...)
	@$(RM) $(APPBIN)/$(EXE).dasm
	@$(RM) $(ALLOBJECTS:.o=.dasm)
	@$(RM) $(BSP)/libstm32f0.dasm

#remove everything, including the lib file
.PHONY: cleanall
cleanall: clean
	$(info Removing library...)
	@$(MAKE) --no-print-directory -C $(BSP) cleanTrue

#disassemble the elf, or everything
.PHONY: dasm
dasm: $(APPBIN)/$(EXE).dasm
	$(info Disassembling "$(APPBIN)/$(EXE).elf" to "$(APPBIN)/$(EXE).dasm")
	@$(OBJDUMP) -d $(APPBIN)/$(EXE).elf > $(APPBIN)/$(EXE).dasm

# disassemble everything we know
.PHONY: dasmall
dasmall: $(APPBIN)/$(EXE).dasm $(ALLOBJECTS:.o=.dasm) $(BSP)/libstm32f0.dasm
	
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
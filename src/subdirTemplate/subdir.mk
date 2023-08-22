# When this .mk is implicitly included into the main Makefile (via src/subdir.mk), all of the source files in this directory will be included in compiling/linking.


# notation: when a makefile is included, it will (1) appear at the end of $(MAKEFILE_LIST), and (2) run.  convenient!
thisDir = $(dir $(lastword $(MAKEFILE_LIST)))

SOURCES += $(wildcard $(thisDir)*.s $(thisDir)*.c $(thisDir)*.cc $(thisDir)*.cpp $(thisDir)*.cxx)
OBJECTS += \
	$(patsubst $(thisDir)%.s,$(thisDir)%.o,$(wildcard $(thisDir)*.s)) \
	$(patsubst $(thisDir)%.c,$(thisDir)%.o,$(wildcard $(thisDir)*.c)) \
	$(patsubst $(thisDir)%.cc,$(thisDir)%.o,$(wildcard $(thisDir)*.cc)) \
	$(patsubst $(thisDir)%.cpp,$(thisDir)%.o,$(wildcard $(thisDir)*.cpp)) \
	$(patsubst $(thisDir)%.cxx,$(thisDir)%.o,$(wildcard $(thisDir)*.cxx))

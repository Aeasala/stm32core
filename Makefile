# Initial template: Credits to Tom Daley
#     https://gist.github.com/tomdaley92/190c68e8a84038cc91a5459409e007df

# A generic build template for C/C++ programs

# executable name: default is containing folder's name.

EXE = $(shell basename $(CURDIR))

# C compiler
CC = gcc
# C++ compiler
CXX = g++
# linker
LD = g++

# C flags
CFLAGS = 
# C++ flags
CXXFLAGS = 
# C/C++ flags
CPPFLAGS = -Wall
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

SOURCES := $(wildcard $(SRC)/*.c $(SRC)/*.cc $(SRC)/*.cpp $(SRC)/*.cxx)

OBJECTS := \
	$(patsubst $(SRC)/%.c, $(OBJ)/%.o, $(wildcard $(SRC)/*.c)) \
	$(patsubst $(SRC)/%.cc, $(OBJ)/%.o, $(wildcard $(SRC)/*.cc)) \
	$(patsubst $(SRC)/%.cpp, $(OBJ)/%.o, $(wildcard $(SRC)/*.cpp)) \
	$(patsubst $(SRC)/%.cxx, $(OBJ)/%.o, $(wildcard $(SRC)/*.cxx))

# TODO
#-include $(SRC)/subdir.mk
	
# include compiler-generated dependency rules
#  | sed "s,\(\)\.o[ :]*,\1.o $@ $(@:.d=.pp) $(@:.d=.su) : ,g"
DEPENDS := $(OBJECTS:.o=.d)
DEPEND.c = $(CC) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.c) 
DEPEND.cxx = $(CXX) $(DEPFLAGS) $(@:.d=.o) $(@:.d=.cpp) 

# compile C source
COMPILE.c = $(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@
# compile C++ source
COMPILE.cxx = $(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@
# link objects
LINK.o = $(LD) $(LDFLAGS) $(OBJECTS) -o $@ $(LDLIBS)

.DEFAULT_GOAL = all

.PHONY: all nomap
all nomap: $(BIN)/$(EXE)
	
$(BIN)/$(EXE): $(SRC) $(OBJ) $(BIN) $(OBJECTS)
	$(info Linking target $@ from $<)
	$(LINK.o)

$(SRC):
	$(info ./$(SRC) directory not found, creating ./$(SRC))
	@mkdir -p $(SRC)

$(OBJ):
	$(info ./$(OBJ) directory not found, creating ./$(OBJ))
	@mkdir -p $(OBJ)

$(BIN):
	$(info ./$(BIN) directory not found, creating ./$(BIN))
	@mkdir -p $(BIN)

$(OBJ)/%.d:	$(SRC)/%.c
	$(info Rebuilding dependencies for $(@:.d=.c))
	@$(DEPEND.c) $< > $@

$(OBJ)/%.d:	$(SRC)/%.cc
	$(info Rebuilding dependencies for $(@:.d=.cc))
	@$(DEPEND.cxx) $< > $@

$(OBJ)/%.d:	$(SRC)/%.cpp
	$(info Rebuilding dependencies for $(@:.d=.cpp))
	@$(DEPEND.cxx) $< > $@

$(OBJ)/%.d:	$(SRC)/%.cxx
	$(info Rebuilding dependencies for $(@:.d=.cxx))
	@$(DEPEND.cxx) $< > $@

$(OBJ)/%.o:	$(SRC)/%.c
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.c) ==> ./$(@))
	@$(COMPILE.c) $<

$(OBJ)/%.o:	$(SRC)/%.cc
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.cc) ==> ./$(@))
	@$(COMPILE.cxx) $<

$(OBJ)/%.o:	$(SRC)/%.cpp
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.cpp) ==> ./$(@))
	@$(COMPILE.cxx) $<

$(OBJ)/%.o:	$(SRC)/%.cxx
	$(info Compiling source file)
	$(info ..... ./$(@:.o=.cxx) ==> ./$(@))
	@$(COMPILE.cxx) $<

# force rebuild
.PHONY: remake
remake:	clean $(BIN)/$(EXE)

# execute the program
.PHONY: run
run: $(BIN)/$(EXE)
	@./$(BIN)/$(EXE)

# remove previous build and objects
.PHONY: clean
clean:
	$(info Removing (.o)bject files...)
	@$(RM) $(OBJECTS)
	$(info Removing (.d)ependencies...)
	@$(RM) $(DEPENDS)
	$(info Removing binaries/executables...)
	@$(RM) $(BIN)/$(EXE)
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

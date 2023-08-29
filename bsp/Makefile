CC=arm-none-eabi-gcc
AR=arm-none-eabi-ar

###########################################

include ../coretarget.mk

#vpath %.c STM32F0xx_StdPeriph_Driver/src

CFLAGS  = -g -O2 -Wall
CFLAGS += $(CFLAGS_TARG)
CFLAGS += -ffreestanding -nostdlib
CFLAGS += -ICMSIS/Include -ICMSIS/Device/ST/STM32F0xx/Include -ISTM32F0xx_StdPeriph_Driver/inc -I../ -I../../ -includeApplication.h -includestm32f0xx_conf.h 

LIBSOURCES = $(wildcard STM32F0xx_StdPeriph_Driver/src/*.c)
LIBOBJECTS = $(LIBSOURCES:.c=.o)

.PHONY: libstm32f0.a

all: libstm32f0.a

%.o : %.c
	$(info Compiling source file for stm32 library:)
	$(info ..... <stmperiph>/src/$(notdir $(@:.o=.c)) ==> <stmperiph>/src/$(notdir $(@)))
	@$(CC) $(INCLUDES) $(CFLAGS) -c -o $@ $^
	$(info )

libstm32f0.a: $(LIBOBJECTS)
	$(info Building library "$(@)"...)
	@$(AR) -c -r $@ $(LIBOBJECTS)
	$(info Done building "$(@)".)

clean:
	@rm -f $(LIBOBJECTS)

cleanTrue:
	@rm -f $(LIBOBJECTS) libstm32f0.a

CC=arm-none-eabi-gcc
AR=arm-none-eabi-ar

###########################################

include ../target.mk

#vpath %.c STM32F0xx_StdPeriph_Driver/src

CFLAGS  = -g -O2 -Wall
CFLAGS += $(CFLAGS_TARG)
CFLAGS += -ffreestanding -nostdlib
CFLAGS += -ICMSIS/Include -ICMSIS/Device/ST/STM32F0xx/Include -ISTM32F0xx_StdPeriph_Driver/inc -I../ -I../../ -includeApplication.h -includestm32f0xx_conf.h 

SRCS = $(wildcard STM32F0xx_StdPeriph_Driver/src/*.c)
OBJS = $(SRCS:.c=.o)

.PHONY: libstm32f0.a

all: libstm32f0.a

%.o : %.c
	$(info Compiling source file for stm32 library:)
	$(info ..... <stmperiph>/src/$(notdir $(@:.o=.c)) ==> <stmperiph>/src/$(notdir $(@)))
	@$(CC) $(INCLUDES) $(CFLAGS) -c -o $@ $^
	$(info )

libstm32f0.a: $(OBJS)
	$(info Building library "$(@)"...)
	@$(AR) -c -r $@ $(OBJS)
	$(info Done building "$(@)".)

clean:
	@rm -f $(OBJS)

cleanTrue:
	@rm -f $(OBJS) libstm32f0.a

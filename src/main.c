#include "Application.h"
#include "stm32f0xx_conf.h"
#include "system_stm32f0xx.h"

// SysTick_Handler is a defined interrupt label.  view src/dev/startup_stm32f0xx.s line 146 onward (g_pfnVectors) for available vectors
void SysTick_Handler(void) {
	static uint16_t tick = 0;
	switch (tick++) {
			case 10:
				GPIOC->ODR ^= (1 << 8);	// Flip one
				break;
			case 20:
				tick = 0;
				GPIOC->ODR ^= (3 << 8); // Flip both
				break;
	}
}

int main(void)
{
	RCC->AHBENR |= RCC_AHBENR_GPIOCEN; 	// enable the clock to GPIOC
	//(RM0091 lists this as IOPCEN, not GPIOCEN)

	// There are two bits to configure each pin.  e.g., pin 8's intended config is shifted by 16, pin 7 by 14, etc.
	GPIOC->MODER &= 0;
	GPIOC->MODER |= (GPIO_Mode_OUT << 16);
	GPIOC->MODER |= (GPIO_Mode_OUT << 18);


	// SysTick: triggers SysTick_Handler every 1/n'th of a second, where this argument is (SystemCoreClock/n)
	SysTick_Config(SystemCoreClock/10);

	while(1)
	{
		// do nothing and rely on the systick interrupts for the routines.
	}
	return 0;
}
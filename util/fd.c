//////////////
/* Includes */
#include "stm32core/stm32f0xx_conf.h"
#include "stm32core/util/fd.h"
////////////////////
/* Private Macros */

///////////////////
/* Private Types */

//////////////////
/* Private Data */

/////////////////////////////////
/* Private Function Prototypes */

/////////////////////////////////
/* Public Function Definitions */
void _exit(int a) { for(;;); }
int _sbrk() { return -1; }
int _close() { return -1; }
int _read() { return -1; }
int _fstat() { return -1; }
int _isatty() { return -1; }
int _lseek() { return -1; }

int _write(int file, char* ptr, int len)
{
   nop();
   return 0;
}

//////////////////////////////////
/* Private Function Definitions */
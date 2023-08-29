#ifndef __util_fd_h_
#define __util_fd_h_

//////////////
/* Includes */

///////////////////
/* Public Macros */
#define nop()  __asm__("nop")

//////////////////
/* Public Types */

/////////////////
/* Public Data */

////////////////////////////////
/* Public Function Prototypes */
void _exit(int a);
int _sbrk(void);
int _close(void);
int _read(void);
int _fstat(void);
int _isatty(void);
int _lseek(void);
int _write(int file, char* ptr, int len);

#endif /* __util_fd_h_ */
# stm32core
## Core for STM32-based ARM projects and software
### What's Needed
1) [ARM GNU Toolchain, none-eabi](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)

    *  [direct link](https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-mingw-w64-i686-arm-none-eabi.exe?rev=aa6116d1af064a16bdf76e4e58ad7d9f&hash=366EA764314E1A4615E216DDBE7C437E)

2) [Cygwin](https://www.cygwin.com/setup-x86_64.exe)

    *  GCC, Make, git should all be installed.

### What needs to be configured.
Several directories of Cygwin and the ARM toolchain need to be added to Windows' PATH environment variable.

Specifically:
1)  {cygwin's root}/bin
2)  {cygwin's root}/lib
3)  {cygwin's root}
4)  {ARM toolchain's root}/bin

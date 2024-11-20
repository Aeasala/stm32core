#ifndef __bsp_dma_h_
#define __bsp_dma_h_

//////////////
/* Includes */
#include "stm32core/typedefs.h"

///////////////////
/* Public Macros */
typedef enum  {
    BYTE = 0,
    WORD = 1,
    DWORD = 2,
} DMA_Sizing_t;
//////////////////
/* Public Types */

/////////////////
/* Public Data */

////////////////////////////////
/* Public Function Prototypes */
void DMA_Init(void);
void DMA_StartTransfer(DMA_Sizing_t chunkSize, uint32_t* source, uint32_t* dest, uint32_t numChunks);
#endif /* __bsp_dma_h_ */
#ifndef __util_buffer_h_
#define __util_buffer_h_
//////////////
/* Includes */
#include "arm_math.h"
///////////////////
/* Public Macros */

//////////////////
/* Public Types */
typedef struct __attribute__((packed)) __attribute__((aligned(4))){
    uint32_t length;  // in bytes
    uint32_t size;
    uint32_t tail;
    uint32_t head;
    union __attribute__((aligned(4))){
        void* __root; // for assignment only.
        uint8_t* bytes;
        uint16_t* words;
        uint32_t* dwords;
        float* floats;
    } data;
} Buffer_t;

/////////////////
/* Public Data */

////////////////////////////////
/* Public Function Prototypes */
void Buffer_Init(Buffer_t* buffer, uint16_t length, void* bufferStart);
uint16_t Buffer_Read(Buffer_t* buffer, uint8_t* out, uint16_t maxBytes);
uint16_t Buffer_Write(Buffer_t* buffer, uint8_t* in, uint16_t maxBytes);
#endif /* __util_buffer_h_ */
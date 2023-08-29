//////////////
/* Includes */
#include "stm32core/stm32f0xx_conf.h"
#include "stm32core/util/buffer.h"
#include "stm32core/util/math.h"
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
void Buffer_Init(Buffer_t* buffer, uint16_t length, void* bufferStart) {
    // root is true 0-index.  head, tail, also start there.
    buffer->data.__root = bufferStart;
    buffer->tail = buffer->head = 0;
    buffer->length = length;
    buffer->size = 0;
}
uint16_t Buffer_Read(Buffer_t* buffer, uint8_t* out, uint16_t maxBytes) {
    uint16_t available = min(buffer->size, maxBytes);
    for(uint16_t i = 0; i < available; i++){
        out[i] = buffer->data.bytes[buffer->tail];
        buffer->tail = (buffer->tail + 1) % buffer->length;
    }
    buffer->size -= available;
    return available;
}
uint16_t Buffer_Write(Buffer_t* buffer, uint8_t* in, uint16_t maxBytes) {
    uint16_t available = min(buffer->length - buffer->size, maxBytes);
    for(uint16_t i = 0; i < available; i++){
        buffer->data.bytes[buffer->head] = in[i];
        buffer->head = (buffer->head + 1) % buffer->length;
    }
    buffer->size += available;
    return available;
}

//////////////////////////////////
/* Private Function Definitions */
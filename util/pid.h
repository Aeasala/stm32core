#ifndef __util_pid_h_
#define __util_pid_h_

//////////////
/* Includes */
#include "stm32core/typedefs.h"

///////////////////
/* Public Macros */

//////////////////
/* Public Types */
typedef struct PID_Struct_t {
    struct {
        float32_t Kp;
        float32_t Ki;
        float32_t Kb;
    } gains;
    struct {
        float32_t min;
        float32_t max;
    } limiter;
    float32_t timebase_dt;
    float32_t integral;
    float32_t output;
}PI_Struct_t;
/////////////////
/* Public Data */

////////////////////////////////
/* Public Function Prototypes */
float32_t PI_Update(PI_Struct_t* Controller, float32_t error);
#endif /* __util_pid_h_ */
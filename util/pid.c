//////////////
/* Includes */
#include "stm32core/stm32f0xx_conf.h"
#include "pid.h"

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
float32_t PI_Update(PI_Struct_t* Controller, float32_t error) {
    float32_t integralDelta = Controller->gains.Ki * error * Controller->timebase_dt;
    Controller->integral += integralDelta;
    float32_t preOutput = (Controller->output)
        + Controller->gains.Kp * error
        + Controller->integral;
    if(preOutput > Controller->limiter.max) {
        preOutput = Controller->limiter.max;
        Controller->integral = Controller->integral - (integralDelta * Controller->gains.Kb);
    }
    else if (preOutput < Controller->limiter.min) {
        preOutput = Controller->limiter.min;
        Controller->integral = Controller->integral - (integralDelta * Controller->gains.Kb);
    }
    Controller->output = preOutput;
    return preOutput;
}
//////////////////////////////////
/* Private Function Definitions */
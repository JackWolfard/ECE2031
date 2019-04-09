Main:
    OUT    RESETPOS    ; reset the odometry to 0,0,0
    ; configure timer interrupt for the movement control code
    LOADI  10          ; period = (10 ms * 10) = 0.1s, or 10Hz.
    OUT    CTIMER      ; turn on timer peripheral
    SEI    &B0010      ; enable interrupts from source 2 (timer)
    ; at this point, timer interrupts will be firing at 10Hz, and
    ; code in that ISR will attempt to control the robot.
    ; If you want to take manual control of the robot,
    ; execute CLI &B0010 to disable the timer interrupt.
    
    LOADI  90
    STORE  DTheta      ; use API to get robot to face 90 degrees
TurnLoop:
    IN     Theta
    ADDI   -90
    CALL   Abs         ; get abs(currentAngle - 90)
    ADDI   -3
    JPOS   TurnLoop    ; if angle error > 3, keep checking
    ; at this point, robot should be within 3 degrees of 90
    LOAD   FMid
    STORE  DVel        ; use API to move forward

InfLoop: 
    JUMP   InfLoop
    ; note that the movement API will still be running during this
    ; infinite loop, because it uses the timer interrupt, so the
    ; robot will continue to attempt to match DTheta and DVel
    
    

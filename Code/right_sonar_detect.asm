
;***************************************************************
;* Main code
;***************************************************************
Main:
    OUT    RESETPOS    ; reset the odometry to 0,0,0
    ; configure timer interrupt for the movement control code
    LOADI  10          ; period = (10 ms * 10) = 0.1s, or 10Hz.
    OUT    CTIMER      ; turn on timer peripheral
    ;SEI    &B0010      ; enable interrupts from source 2 (timer)
    ; at this point, timer interrupts will be firing at 10Hz, and
    ; code in that ISR will attempt to control the robot.
    ; If you want to take manual control of the robot,
    ; execute CLI &B0010 to disable the timer interrupt.
    ;SEI    &B0001
    LOADI  32
    OUT    SONAREN
    ;OUT    SONARINT
    ;LOADI  &H4C3
    ;OUT    SONALARM
MOVE:
    LOAD   RSLOW
    OUT    RVELCMD
    LOAD   FSLOW
    OUT    LVELCMD
    IN     DIST5
    OUT    SSEG2
    ADDI   -600
    ADDI   -619
    JNEG   INF_LOOP
    JUMP   MOVE
    

INF_LOOP:
    LOADI  0
    OUT    RVELCMD
    OUT    LVELCMD
    JUMP   INF_LOOP

    ; note that the movement API will still be running during this
    ; infinite loop, because it uses the timer interrupt, so the
    ; robot will continue to attempt to match DTheta and DVel
    
Found_Thing:
    CLI    &B1111
    LOADI  0
    OUT    RVELCMD
    OUT    LVELCMD
    JUMP   INF_LOOP


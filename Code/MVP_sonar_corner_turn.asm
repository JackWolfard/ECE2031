Main:
    ; starting information
    OUT     RESETPOS
    LOADI   10          ; 10ms increment * 10 = 100ms
    OUT     CTIMER      ; setup movement api to interrupt every 100ms
    SEI     &B0010      ; enable CTIMER interrupts

    ; SW15 & SW14 are used to determine which state to start in for the robot
    ; default (both low) is state 0. encoded in binary
    IN      SWITCHES    ; 0b 1100 0000 0000 0000 // two highlighted we need
    SHIFT   -14         ; 0b 0000 0000 0000 0011
    AND     THREE       ; masking last two bits
    STORE   STATE
    OUT     LCD

    SUB     STATE_DRIVE_DESK_TO_CORNER      ; if we're following left wall
    JNEG    MAIN_SETUP_SONARS_ELSE          ; then enable left sonars
    CALL    ENABLE_LEFT_SONARS              ; else enable right sonars
    CALL    SONAR_READ
    JUMP    SWITCH_STATE
MAIN_SETUP_SONARS_ELSE:
    CALL    ENABLE_RIGHT_SONARS

MAIN_LOOP:
    CALL    SONAR_READ                  ; ouputs debug info
    CALL    SWITCH_STATE                ; switches to current state handler
    JUMP    MAIN_LOOP

SWITCH_STATE:
    LOAD    STATE
    JZERO   CALL_DRIVE_PODIUM_TO_CORNER
    ADDI    -1
    JZERO   CALL_DRIVE_CORNER_TO_DESK
    ADDI    -1
    JZERO   CALL_DRIVE_DESK_TO_CORNER
    CALL    DRIVE_CORNER_TO_PODIUM
    RETURN
CALL_DRIVE_PODIUM_TO_CORNER:
    CALL    DRIVE_PODIUM_TO_CORNER
    RETURN
CALL_DRIVE_CORNER_TO_DESK:
    CALL    DRIVE_CORNER_TO_DESK
    RETURN
CALL_DRIVE_DESK_TO_CORNER:
    CALL    DRIVE_DESK_TO_CORNER
    RETURN

ENABLE_LEFT_SONARS:
    LOAD    MASK4
    ADD     MASK5
    ADD     MASK6
    ADD     MASK2
    OUT     SONAREN
    RETURN

ENABLE_RIGHT_SONARS:
    LOAD    MASK0
    ADD     MASK1
    ADD     MASK7
    ADD     MASK3
    OUT     SONAREN
    RETURN

DRIVE_PODIUM_TO_CORNER:
    IN      DIST3
    CALL    AVG_SONAR_VALS
    JZERO   FOLLOW_RIGHT_WALL
    CALL    BIG_TURN_LEFT
    OUT     RESETPOS
    LOAD    STATE_DRIVE_CORNER_TO_DESK
    STORE   STATE
    RETURN
DRIVE_CORNER_TO_DESK:
    IN      DIST3
    CALL    AVG_SONAR_VALS
    JZERO   FOLLOW_RIGHT_WALL
    CALL    TURN_AROUND
    OUT     RESETPOS
    CALL    ENABLE_LEFT_SONARS
    LOAD    STATE_DRIVE_DESK_TO_CORNER
    STORE   STATE
    RETURN
FOLLOW_RIGHT_WALL:
    IN      DIST4
    SUB     MAX
    JNEG    TURN_LEFT
    IN      DIST6
    SUB	    MAX
    JNEG    TURN_RIGHT
    IN      DIST5
    SUB	    MAX
    JZERO   TURN_RIGHT
    IN      DIST5
    SUB     WALL_CLOSE_LIMIT
    JNEG    TURN_LEFT
    IN      DIST5
    SUB     WALL_FAR_LIMIT
    JPOS    TURN_RIGHT
    LOADI   0
    STORE   DTheta
    LOAD    FFast
    STORE   DVel
    RETURN

DRIVE_DESK_TO_CORNER:
    IN      DIST2
    CALL    AVG_SONAR_VALS
    JZERO   FOLLOW_LEFT_WALL
    CALL    BIG_TURN_RIGHT
    OUT     RESETPOS
    LOAD    STATE_DRIVE_CORNER_TO_PODIUM
    STORE   STATE
    RETURN
DRIVE_CORNER_TO_PODIUM:
    IN      DIST2
    CALL    AVG_SONAR_VALS
    JZERO   FOLLOW_LEFT_WALL
    CALL    TURN_AROUND
    OUT     RESETPOS
    CALL    ENABLE_RIGHT_SONARS
    LOAD    STATE_DRIVE_PODIUM_TO_CORNER
    STORE   STATE
    RETURN
FOLLOW_LEFT_WALL:
    IN      DIST7
    SUB     MAX
    JNEG    TURN_LEFT
    IN      DIST1
    SUB	    MAX
    JNEG    TURN_RIGHT
    IN      DIST0
    SUB	    MAX
    JZERO   TURN_LEFT
    IN      DIST0
    SUB     WALL_CLOSE_LIMIT
    JNEG    TURN_RIGHT
    IN      DIST0
    SUB     WALL_FAR_LIMIT
    JPOS    TURN_LEFT
    LOADI   0
    STORE   DTheta
    LOAD    FFast
    STORE   DVel
    RETURN


TURN_LEFT:
    LOAD    CORRECTION
    STORE   DTheta
    LOAD    FFast
    STORE   Dvel
    RETURN

TURN_RIGHT:
    LOADI   0
    SUB     CORRECTION          ; right turn is negative, should be -CORRECTION
    STORE   DTheta
    LOAD    FFast
    STORE   Dvel
    RETURN

TURN_AROUND:
    OUT     RESETPOS
    LOADI   179
    STORE   DTheta
TURN_AROUND_LOOP:
    IN      Theta
    ADDI    -179
    CALL    Abs
    ADDI    -3
    JPOS    TURN_AROUND_LOOP
    OUT     RESETPOS
    LOADI   0               ; assume we're going straight
    OUT     DTheta
    RETURN

; At corner, need to do a 90* turn
BIG_TURN_LEFT:
    OUT     RESETPOS                ; reset odometry
    LOADI   90
    STORE   DTheta
BIG_TURN_LEFT_LOOP:
    IN      Theta
    ADDI    -90                     ; while (abs(THETA - 90) > 3)
    CALL    Abs
    ADDI    -3
    JPOS    BIG_TURN_LEFT_LOOP
    RETURN

BIG_TURN_RIGHT:
    OUT     RESETPOS
    LOADI   -90
    STORE   DTheta
BIG_TURN_RIGHT_LOOP:
    IN      Theta
    ADDI    -270                      ; while (abs(THETA - 270) > 3)
    CALL    Abs
    ADDI    -3
    JPOS    BIG_TURN_RIGHT_LOOP
    RETURN

; debug block
; results in going to SWITCH_STATE after debugging is over
SONAR_READ:                 ; switch (current switch)
    IN DIST2
    OUT SSEG1
    IN DIST3
    OUT SSEG2
    LOAD STATE
    OUT LCD
    RETURN


; average sonar values
;   records last AVG_SONAR_VALS_AMOUNT sonar values and if they're within
;   turn_limit three times in a row, then will return True
;   otherwise return False
;
; parameters:
;   - acc:          value of DIST2 or DIST3 depending on which wall being
;                   followed
;   - turn_limit:   mem position storing how close it should be before a turn
; returns:
;   - acc:          boolean value (0 or 1) for whether or not to
;                   transition to next state
AVG_SONAR_VALS:
    SUB         TURN_LIMIT
    JPOS        AVG_SONAR_VALS_ADD_ZERO
    LOADI       1
    JUMP        AVG_SONAR_VALS_STORE
AVG_SONAR_VALS_ADD_ZERO:
    LOADI       0
AVG_SONAR_VALS_STORE:
    STORE       AVG_SONAR_VALS_ADD
    LOAD        AVG_SONAR_VALS_AVG
    SHIFT       1                       ; left 1 position, add a zero in place
    AND         AVG_SONAR_VALS_AMOUNT   ; mask to cut off overflowed vals
    ADD         AVG_SONAR_VALS_ADD
    OUT         LEDS
    STORE       AVG_SONAR_VALS_AVG
    SUB         AVG_SONAR_VALS_AMOUNT
    JZERO       AVG_SONAR_VALS_RETURN   ; if avg != amount then
    LOADI       0                       ;   return 0
    RETURN
AVG_SONAR_VALS_RETURN:                  ; else
    LOADI       0                       ;   reset avg to 0
    STORE       AVG_SONAR_VALS_AVG      ;   return 1
    LOADI       1
    RETURN

STATE_DRIVE_PODIUM_TO_CORNER:   DW      0
STATE_DRIVE_CORNER_TO_DESK:     DW      1
STATE_DRIVE_DESK_TO_CORNER:     DW      2
STATE_DRIVE_CORNER_TO_PODIUM:   DW      3
WALL_CLOSE_LIMIT:               DW      190         ; 190mm from wall
WALL_FAR_LIMIT:                 DW      210         ; 210mm from wall
CORRECTION:                     DW      5           ; 5 degrees
Mask8:                          DW      &B100       ; 0001 0000 0000
Mask9:                          DW      &H200       ; 0010 0000 0000
MAX:                            DW      &H7FFF      ; max value sonars read
State:                          DW      0
TURN_LIMIT:                     DW      &H0250      ; ?? mm best val
AVG_SONAR_VALS_AVG:             DW      0
AVG_SONAR_VALS_ADD:             DW      0
AVG_SONAR_VALS_AMOUNT:          DW      &B111       ; need five ones in a row
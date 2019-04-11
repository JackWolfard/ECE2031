Main:
    ; starting information
    OUT     RESETPOS
    LOADI   10
    OUT     CTIMER      ; setup movement api
    SEI     &B0010

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
    CALL    SONAR_READ      ; sonar read: occurs at end of each iter.
                            ;             outputs debugging info.
    JUMP    SWITCH_STATE

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
    JPOS    BIG_TURN_LEFT
    JUMP    FOLLOW_RIGHT_WALL

DRIVE_CORNER_TO_DESK:
    IN      DIST3
    CALL    AVG_SONAR_VALS
    JPOS    TURN_AROUND_DESK
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
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

DRIVE_DESK_TO_CORNER:
    IN      DIST2
    CALL    AVG_SONAR_VALS
    JPOS    BIG_TURN_RIGHT
    JUMP    FOLLOW_LEFT_WALL

DRIVE_CORNER_TO_PODIUM:
    IN      DIST2
    CALL    AVG_SONAR_VALS
    JPOS    TURN_AROUND_PODIUM
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
    CALL    SONAR_READ
    JUMP    SWITCH_STATE


TURN_LEFT:
    LOAD    CORRECTION
    STORE   DTheta
    LOAD    FFast
    STORE   Dvel
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

TURN_RIGHT:
    LOAD    CORRECTION
    STORE   DTheta
    LOAD    FFast
    STORE   Dvel
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

TURN_AROUND_DESK:
    OUT     RESETPOS
    LOADI   179
    STORE   DTheta
TURN_AROUND_DESK_LOOP:
    IN     Theta
    ADDI    -179
    CALL    Abs
    ADDI    -3
    JPOS    TURN_AROUND_DESK_LOOP
    LOAD    STATE_DRIVE_DESK_TO_CORNER
    STORE   STATE
    ; Switch sonars being used
    CALL    ENABLE_RIGHT_SONARS
    OUT     RESETPOS
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

TURN_AROUND_PODIUM:
    OUT     RESETPOS
    LOADI   179
    STORE   DTheta
TURN_AROUND_PODIUM_LOOP:
    IN      Theta
    ADDI    -179
    CALL    Abs
    ADDI    -3
    JPOS    TURN_AROUND_PODIUM_LOOP
    LOAD    STATE_DRIVE_PODIUM_TO_CORNER
    STORE   STATE
    ; Switch sonars being used
    CALL    ENABLE_LEFT_SONARS
    OUT     RESETPOS
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

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
    LOAD    STATE_DRIVE_CORNER_TO_DESK
    STORE   STATE
    OUT     RESETPOS
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

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
    LOAD    STATE_DRIVE_CORNER_TO_PODIUM
    STORE   STATE
    OUT     RESETPOS
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; debug block
; results in going to SWITCH_STATE after debugging is over
SONAR_READ:                 ; switch (current switch)
    IN      SWITCHES
    AND     MASK0           ; case SW_1
    JZERO   SW_1            ;       print DIST0
    IN      DIST0
    OUT     LCD
    RETURN
SW_1:
    IN      SWITCHES
    AND     MASK1
    JZERO   SW_4
    IN      DIST1
    OUT     LCD
    RETURN
SW_4:
    IN      SWITCHES
    AND     MASK4
    JZERO   SW_5
    IN      DIST4
    OUT     LCD
    RETURN
SW_5:
    IN      SWITCHES
    AND     MASK5
    JZERO   SW_6
    IN      DIST5
    OUT	    LCD
    RETURN
SW_6:
    IN      SWITCHES
    AND     MASK6
    JZERO   SW_7
    IN      DIST6
    OUT     LCD
    RETURN
SW_7:
    IN      SWITCHES
    AND     MASK7
    JZERO   DIST_DBG
    IN      DIST7
    OUT     LCD
    RETURN
DIST_DBG:
    IN      SWITCHES
    AND     MASK2
    JZERO   WALL_RIGHT
    IN      XPOS
    OUT     LCD
    RETURN
WALL_RIGHT:
    IN      SWITCHES
    AND     MASK8
    JZERO   WALL_LEFT
    IN      DIST4
    OUT	    SSEG1
    IN      DIST6
    OUT	    SSEG2
    IN      DIST5
    OUT     LCD
    RETURN
WALL_LEFT:
    IN      SWITCHES
    AND     MASK3
    JZERO   CHECK_STATE
    IN      DIST1
    OUT     SSEG1
    IN      DIST7
    OUT     SSEG2
    IN      DIST0
    OUT     LCD
    RETURN
CHECK_STATE:
    IN      SWITCHES
    AND     MASK9
    JZERO   SONAR_READ_END
    LOAD    STATE
    OUT     LCD
SONAR_READ_END:
    RETURN

SWITCH_STATE:
    LOAD    STATE
    JZERO   DRIVE_PODIUM_TO_CORNER
    ADDI    -1
    JZERO   DRIVE_CORNER_TO_DESK
    ADDI    -1
    JZERO   DRIVE_DESK_TO_CORNER
    ADDI    -1
    JZERO   DRIVE_CORNER_TO_PODIUM

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
WALL_CLOSE_LIMIT:               DW      190
WALL_FAR_LIMIT:                 DW      210
CORRECTION:                     DW      5
Mask8:                          DW      &B100000000
Mask9:                          DW      &B1000000000
MAX:                            DW      &H7FFF
State:                          DW      0
TURN_LIMIT:                     DW      &H00C8      ; 200mm
AVG_SONAR_VALS_AVG:             DW      0
AVG_SONAR_VALS_ADD:             DW      0
AVG_SONAR_VALS_AMOUNT:          DW      &B11111     ; need five ones in a row
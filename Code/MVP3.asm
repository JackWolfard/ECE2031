;~~~~~~~~~~~~~~~~
; INITIALIZATION
;~~~~~~~~~~~~~~~~
Main:
    OUT     RESETPOS    ; Reset position
    LOADI   10
    OUT     CTIMER      ; Setup movement api
    SEI     &B0010

    ; SW15 & SW14 are used to determine which state to start in for the robot
    ; Default (both low) is state 0. Encoded in binary
    ;   Loads switches, shifts them so 14 & 15 are last, masks it with 3
    IN      SWITCHES
    SHIFT   -14
    AND     THREE
    STORE   STATE

    ; Sets the starting state and enables correct sonars
    ; State 0/1 => right sonars
    ; State 2/3 => left sonars
    SUB     STATE_DRIVE_DESK_TO_CORNER
    JNEG    MAIN_SETUP_SONARS_ELSE
    CALL    ENABLE_LEFT_SONARS
    CALL    SONAR_READ
    JUMP    SWITCH_STATE
MAIN_SETUP_SONARS_ELSE:
    CALL    ENABLE_RIGHT_SONARS
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; Enables sonars for following the left wall
ENABLE_LEFT_SONARS: ; TODO: make a new bit mask that has all 3 sonar bits
    LOAD    MASK4
    ADD     MASK5
    ADD     MASK6
    OUT     SONAREN
    RETURN

; Enables sonars for following the right wall
ENABLE_RIGHT_SONARS:    ; TODO: make a new bit mask that has all 3 sonar bits
    LOAD    MASK0
    ADD     MASK1
    ADD     MASK7
    OUT     SONAREN
    RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; STATE MACHINE
;
; Contains all the states and corresponding code for them
; General state progression:
; RESET --> DRIVE_PODIUM_TO_CORNER --> BIG_TURN_LEFT  --> DRIVE_CORNER_TO_DESK
;  _________________________________________________________________________/
; /
; \__> TURN_AROUND_DESK --> DRIVE_DESK_TO_CORNER --> BIG_TURN_RIGHT
;  ______________________________________________________________/
; /
; \__> DRIVE_CORNER_TO_PODIUM --> TURN_AROUND_PODIUM --> RESET
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; STATE 0
DRIVE_PODIUM_TO_CORNER:
    ; check if should turn right
    IN      XPOS
    SUB     Leg1
    JPOS    BIG_TURN_LEFT
    ; otherwise follow the wall
    JUMP    FOLLOW_RIGHT_WALL

; STATE 1
DRIVE_CORNER_TO_DESK:
    ; check if should turn around
    IN      XPOS
    SUB     Leg2
    JPOS    TURN_AROUND_DESK
    ; otherwise follow the wall
    JUMP    FOLLOW_RIGHT_WALL

; STATE 2
DRIVE_DESK_TO_CORNER:
    ; check if should turn right
    IN      XPOS
    SUB     Leg2
    JPOS    BIG_TURN_RIGHT
    ; otherwise follow the wall
    JUMP    FOLLOW_LEFT_WALL

; STATE 3
DRIVE_CORNER_TO_PODIUM:
    ; check if should turn left
    IN      XPOS
    SUB     Leg1
    JPOS    TURN_AROUND_PODIUM
    ; otherwise follow the wall
    JUMP    FOLLOW_LEFT_WALL

; Turn around at the desk
TURN_AROUND_DESK:
    LOAD    ZERO
    STORE   L_SPEED_CORRECT
    ; Start the turn
    OUT     RESETPOS
    LOADI   179
    STORE   DTheta
    ; Check if target heading is reached
TURN_AROUND_DESK_LOOP:
    IN      Theta
    ADDI    -179
    CALL    Abs
    ADDI    -3      ; TODO: make the thresholds smaller & a variable
    JPOS    TURN_AROUND_DESK_LOOP
    ; Change states
    LOAD    STATE_DRIVE_DESK_TO_CORNER
    STORE   STATE
    ; Switch sonars being used & reset heading
    CALL    ENABLE_RIGHT_SONARS
    OUT     RESETPOS
    LOADI   0       ; TODO: immediately reset the heading after ending turn
    STORE   DTheta
    ; Debug & switch states
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; Turn around at the podium
TURN_AROUND_PODIUM:
    LOAD    ZERO
    STORE   L_SPEED_CORRECT
    ; Start the turn
    OUT     RESETPOS
    LOADI   179
    STORE   DTheta
TURN_AROUND_PODIUM_LOOP:
    IN      Theta
    ADDI    -179
    CALL    Abs
    ADDI    -3      ; TODO: make the thresholds smaller & a variable
    ; Check if target heading is reached
    JPOS    TURN_AROUND_PODIUM_LOOP
    ; Change states
    LOAD    STATE_DRIVE_PODIUM_TO_CORNER
    STORE   STATE
    ; Switch sonars being used
    CALL    ENABLE_LEFT_SONARS
    OUT     RESETPOS
    LOADI   0       ; TODO: immediately reset the heading after ending turn
    STORE   DTheta
    ; Debug & switch states
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; At corner, do a 90* turn left
BIG_TURN_LEFT:
    LOAD    ZERO
    STORE   L_SPEED_CORRECT
    ; Start the turn
    OUT     RESETPOS
    LOADI   90
    STORE   DTheta
BIG_TURN_LEFT_LOOP:
    IN      Theta
    ADDI    -90
    CALL    Abs
    ADDI    -3      ; TODO: make the thresholds smaller & a variable
    ; Check if target heading is reached
    JPOS    BIG_TURN_LEFT_LOOP
    ; Change states, reset heading, and debug
    LOAD    STATE_DRIVE_CORNER_TO_DESK
    STORE   STATE
    OUT     RESETPOS
    LOADI   0       ; TODO: immediately reset the heading after ending turn
    STORE   DTheta
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; At corner, do a 90* turn right
BIG_TURN_RIGHT:
    LOAD    ZERO
    STORE   L_SPEED_CORRECT
    ; Start the turn
    OUT     RESETPOS
    LOADI   -90
    STORE   DTheta
BIG_TURN_RIGHT_LOOP:
    IN      Theta
    ADDI    -270
    CALL    Abs
    ADDI    -3
    ; Check if target heading is reached
    JPOS    BIG_TURN_RIGHT_LOOP
    ; Change states, reset heading, and debug
    LOAD    STATE_DRIVE_CORNER_TO_PODIUM
    STORE   STATE
    OUT     RESETPOS
    LOADI   0       ; TODO: immediately reset the heading after ending turn
    STORE   DTheta
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; TURNING & FOLLOWING FUNCTIONS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FOLLOW_RIGHT_WALL: ; TODO: Make this a subroutine
    ; if turning away, turn left
    IN      DIST4
    SUB     MAX
    JNEG    TURN_LEFT
    ; if turning towards, turn right
    IN      DIST6
    SUB     MAX
    JNEG    TURN_RIGHT
    ; if can't see the wall, turn right
    IN      DIST5
    SUB     MAX
    JZERO   TURN_RIGHT
    ; if too close to the wall, turn left
    IN      DIST5
    SUB     WALL_CLOSE_LIMIT
    JNEG    TURN_LEFT
    ; if too far away from wall, turn right
    IN      DIST5
    SUB     WALL_FAR_LIMIT
    JPOS    TURN_RIGHT
    ; if no changes are detected, stay straight
    LOAD    ZERO
    STORE   L_SPEED_CORRECT
    ; set velocity to fast
    LOAD    FFast
    STORE   DVel
    ; debug and switch state if needed
    CALL    SONAR_READ
    JUMP    SWITCH_STATE    ; TODO: remove for subroutine

FOLLOW_LEFT_WALL: ; TODO: Make this a subroutine
    ; if turning towards, turn right
    IN      DIST1
    SUB     MAX
    JNEG    TURN_RIGHT
    ; if turning away, turn left
    IN      DIST7
    SUB     MAX
    JNEG    TURN_LEFT
    ; if can't see the wall, turn left
    IN      DIST0
    SUB     MAX
    JZERO   TURN_LEFT
    ; if too close to the wall, turn right
    IN      DIST0
    SUB     WALL_CLOSE_LIMIT
    JNEG    TURN_RIGHT
    ; if too close to the wall, turn left
    IN      DIST0
    SUB     WALL_FAR_LIMIT
    JPOS    TURN_LEFT
    ; if no changes are detected, stay straight
    LOAD    ZERO
    STORE   L_SPEED_CORRECT
    ; set velocity to fast
    LOAD    FFast
    STORE   DVel
    ; debug and switch state if necessary
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; Small turn left for following the wall
TURN_LEFT:      ; TODO: make this a subroutine
    LOAD    FFast
    STORE   DVel
    LOAD    ZERO
    SUB     CORRECTION
    STORE   L_SPEED_CORRECT
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; Small turn right for following the wall
TURN_RIGHT:     ; TODO: make this a subroutine
    LOAD    FFast
    STORE   DVel
    LOAD    ZERO
    ADD     CORRECTION
    STORE   L_SPEED_CORRECT
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; SONAR_READ
;
; Subtroutine for debugging issues by displaying values on the LCD
; Values displayed are determined by the switches on
;   Switch 0: sonar 0 distance
;   Switch 1: sonar 1 distance
;   Switch 2: encoder distance
;   Switch 4: sonar 4 distance
;   Switch 5: sonar 5 distance
;   Switch 6: sonar 6 distance
;   Switch 7: sonar 7 distance
;   Switch 9: current state
; Special outputs:
;   Switch 3: sonar 1 on 7-seg1, sonar 0 on LCD, sonar 7 on 7-seg2
;   Switch 8: sonar 4 on 7-seg1, sonar 5 on LCD, sonar 6 on 7-seg2
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SONAR_READ:
    IN      SWITCHES
    AND     MASK0
    JZERO   SW_1
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
    OUT     LCD
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
    RETURN
    IN      XPOS
    OUT     LCD
    RETURN
WALL_RIGHT:
    IN      SWITCHES
    AND     MASK8
    JZERO   WALL_LEFT
    IN      DIST4
    OUT     SSEG1
    IN      DIST6
    OUT     SSEG2
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

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; STATES
;
; States are stored as integers (0-3)
; The states and the corresponding numbers are found below
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SWITCH_STATE:   ; TODO: Make this a subroutine
    LOAD    STATE
    JZERO   DRIVE_PODIUM_TO_CORNER
    ADDI    -1
    JZERO   DRIVE_CORNER_TO_DESK
    ADDI    -1
    JZERO   DRIVE_DESK_TO_CORNER
    ADDI    -1
    JZERO   DRIVE_CORNER_TO_PODIUM

STATE_DRIVE_PODIUM_TO_CORNER:   DW  0   ; 1st half of starting leg
STATE_DRIVE_CORNER_TO_DESK:     DW  1   ; 2nd half of starting leg
STATE_DRIVE_DESK_TO_CORNER:     DW  2   ; 1st half of returning leg
STATE_DRIVE_CORNER_TO_PODIUM:   DW  3   ; 2nd half of returning leg

;~~~~~~~~~~~
; CONSTANTS
;~~~~~~~~~~~
WALL_CLOSE_LIMIT:   DW  190     ; Lower threshold for DSP control
WALL_FAR_LIMIT:     DW  210     ; Upper threshold for DSP control
CORRECTION:         DW  5       ; Correction to heading for turning
L_SPEED_CORRECT:    DW  0       ; Correction to left wheel speed for turning
Max:                DW  &H7FFF  ; Maximum distance read by sonars
Leg1:               DW  3200    ; Encoder distance for 1st half of leg
Leg2:               DW  3800    ; Encoder distance for 2nd half of leg
State:              DW  0       ; Default state = 0

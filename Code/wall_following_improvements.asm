Main:
    ; starting information
    OUT     RESETPOS
    LOADI   10
    OUT     CTIMER
    SEI     &B0010
    LOAD	MASK4
    ADD		MASK5
    ADD		MASK6
    OUT     SONAREN
    LOAD    STATE_DRIVE_PODIUM_TO_CORNER ; Start STATE = 0
    STORE   STATE
  	CALL	SONAR_READ      ; sonar read: occurs at end of each iter.
                            ;             outputs debugging info.
    JUMP    SWITCH_STATE

DRIVE_PODIUM_TO_CORNER:
	IN		XPOS
	SUB		Leg1            ; Leg1 = half a leg, podium to corner
	JPOS	BIG_TURN_LEFT
    JUMP    FOLLOW_RIGHT_WALL

DRIVE_CORNER_TO_DESK:
	IN		XPOS
	SUB		Leg2
	JPOS	TURN_AROUND_DESK
FOLLOW_RIGHT_WALL:
    IN      DIST4
    SUB		MAX
    JNEG	TURN_LEFT
    IN      DIST6
    SUB		MAX
    JNEG	TURN_RIGHT
    IN		DIST5
    SUB		MAX
    JZERO	TURN_RIGHT
    IN		DIST5
    SUB     WALL_CLOSE_LIMIT
    JNEG	TURN_LEFT
    IN		DIST5
    SUB     WALL_FAR_LIMIT
    JPOS	TURN_RIGHT
    LOAD	ZERO
    STORE	L_SPEED_CORRECT
    LOAD    FFast
    STORE   DVel
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

DRIVE_DESK_TO_CORNER:
	IN		XPOS
	SUB		Leg2
	JPOS	BIG_TURN_RIGHT
    JUMP    FOLLOW_LEFT_WALL

DRIVE_CORNER_TO_PODIUM:
	IN		XPOS
	SUB		Leg1
	JPOS	TURN_AROUND_PODIUM
FOLLOW_LEFT_WALL:
    IN      DIST1
    SUB		MAX
    JNEG	TURN_RIGHT
    IN      DIST7
    SUB		MAX
    JNEG	TURN_LEFT
    IN		DIST0
    SUB		MAX
    JZERO	TURN_LEFT
    IN		DIST0
    SUB     WALL_CLOSE_LIMIT
    JNEG	TURN_RIGHT
    IN		DIST0
    SUB     WALL_FAR_LIMIT
    JPOS	TURN_LEFT
    LOAD	ZERO
    STORE	L_SPEED_CORRECT
    LOAD    FFast
    STORE   DVel
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

TURN_LEFT:
	LOAD    FFast
    STORE   DVel
	LOAD	ZERO
    SUB		CORRECTION
    STORE	L_SPEED_CORRECT
    CALL	SONAR_READ
    JUMP	SWITCH_STATE

TURN_RIGHT:
	LOAD    FFast
    STORE   DVel
    LOAD	ZERO
    ADD		CORRECTION
    STORE	L_SPEED_CORRECT
    CALL	SONAR_READ
    JUMP	SWITCH_STATE
	
TURN_AROUND_DESK:
	LOAD	ZERO
	STORE	L_SPEED_CORRECT
    OUT     RESETPOS
	LOADI	179
	STORE	DTheta
TURN_AROUND_DESK_LOOP:
	IN		Theta
	ADDI	-179
	CALL	Abs
	ADDI	-3
	JPOS	TURN_AROUND_DESK_LOOP
	LOAD    STATE_DRIVE_DESK_TO_CORNER
    STORE   STATE
	; Switch sonars being used
	LOAD	MASK0
    ADD		MASK1
    ADD		MASK7
    OUT     SONAREN
	OUT     RESETPOS
	LOADI	0
	STORE	DTheta
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

TURN_AROUND_PODIUM:
	LOAD	ZERO
	STORE	L_SPEED_CORRECT
    OUT     RESETPOS
	LOADI	179
	STORE	DTheta
TURN_AROUND_PODIUM_LOOP:
	IN		Theta
	ADDI	-179
	CALL	Abs
	ADDI	-3
	JPOS	TURN_AROUND_PODIUM_LOOP
    LOAD    STATE_DRIVE_PODIUM_TO_CORNER
    STORE   STATE
	; Switch sonars being used
	LOAD	MASK4
    ADD		MASK5
    ADD		MASK6
    OUT     SONAREN
	OUT     RESETPOS
	LOADI	0
	STORE	DTheta
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; At corner, need to do a 90* turn
BIG_TURN_LEFT:
	LOAD	STATE
	ADDI	-1
	JZERO	SWITCH_STATE
	LOAD	ZERO
	STORE	L_SPEED_CORRECT
    OUT     RESETPOS                ; reset odometry
	LOADI	90
	STORE	DTheta
BIG_TURN_LEFT_LOOP:
	IN		Theta
	ADDI	-90                     ; while (abs(THETA - 90) - 3 > 0)
	CALL	Abs
	ADDI	-3
	JPOS	BIG_TURN_LEFT_LOOP
	LOAD    STATE_DRIVE_CORNER_TO_DESK
    STORE   STATE
	OUT     RESETPOS
	LOADI	0
	STORE	DTheta
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

BIG_TURN_RIGHT:
	LOAD	ZERO
	STORE	L_SPEED_CORRECT
	OUT     RESETPOS
	LOADI	-90
	STORE	DTheta
BIG_TURN_RIGHT_LOOP:
	IN		Theta
	ADDI	-270                      ; while (abs(THETA - 270) > 3)
	CALL	Abs
	ADDI	-3
	JPOS	BIG_TURN_RIGHT_LOOP
	LOAD	STATE_DRIVE_CORNER_TO_PODIUM
	STORE	STATE
	OUT     RESETPOS
	LOADI	0
	STORE	DTheta
    CALL    SONAR_READ
    JUMP    SWITCH_STATE

; debug block
; results in going to SWITCH_STATE after debugging is over
SONAR_READ:                 ; switch (current switch)
	IN 		SWITCHES
	AND		MASK0
	JZERO	SW_1            ; case SW_1:
                            ;       print DIST0
	IN		DIST0
	OUT		LCD
	RETURN
SW_1:
	IN		SWITCHES
	AND		MASK1
	JZERO	SW_4
	IN		DIST1
	OUT		LCD
	RETURN
SW_4:
	IN		SWITCHES
	AND		MASK4
	JZERO	SW_5
	IN		DIST4
	OUT		LCD
	RETURN
SW_5:
	IN 		SWITCHES
	AND 	MASK5
	JZERO	SW_6
	IN		DIST5
	OUT		LCD
	RETURN
SW_6:
	IN		SWITCHES
	AND		MASK6
	JZERO	SW_7
	IN		DIST6
	OUT		LCD
	RETURN
SW_7:
	IN		SWITCHES
	AND		MASK7
	JZERO	DIST_DBG
	IN		DIST7
	OUT		LCD
	RETURN
DIST_DBG:
	IN		SWITCHES
	AND		MASK2
	JZERO	WALL_RIGHT
	IN		XPOS
	OUT		LCD
	RETURN
WALL_RIGHT:
	IN 		SWITCHES
	AND		MASK8
	JZERO	WALL_LEFT
	IN		DIST4
	OUT		SSEG1
	IN		DIST6
	OUT		SSEG2
	IN		DIST5
	OUT		LCD
	RETURN
WALL_LEFT:
	IN 		SWITCHES
	AND		MASK3
	JZERO	CHECK_STATE
	IN		DIST1
	OUT		SSEG1
	IN		DIST7
	OUT		SSEG2
	IN		DIST0
	OUT		LCD
	RETURN
CHECK_STATE:
	IN		SWITCHES
	AND		MASK9
	JZERO	SONAR_READ_END
	LOAD	STATE
	OUT		LCD
SONAR_READ_END:
	RETURN

; switch (STATE)
;       case ZERO:
;           DRIVE_THERE_1();
;           break;
SWITCH_STATE:
	LOAD	STATE
	JZERO	DRIVE_PODIUM_TO_CORNER
	ADDI	-1
	JZERO	DRIVE_CORNER_TO_DESK
	ADDI	-1
	JZERO	DRIVE_DESK_TO_CORNER
	ADDI	-1
	JZERO	DRIVE_CORNER_TO_PODIUM

; Make state labels:
; DRIVE_THERE_1: &DW 1
STATE_DRIVE_PODIUM_TO_CORNER:    DW  0
STATE_DRIVE_CORNER_TO_DESK:      DW  1
STATE_DRIVE_DESK_TO_CORNER:      DW  2
STATE_DRIVE_CORNER_TO_PODIUM:   DW  3
WALL_CLOSE_LIMIT:               DW  190
WALL_FAR_LIMIT:                 DW  210
CORRECTION:                     DW 	100
L_SPEED_CORRECT:				DW	0
Mask8:	  			DW &B100000000
Mask9:	  			DW &B1000000000
Max:	 			DW &H7FFF
Leg1:	 			DW 3000
Leg2:	  			DW 3800
State:	  			DW 0 
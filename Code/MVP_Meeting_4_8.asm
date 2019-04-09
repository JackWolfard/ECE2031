Main:
    ; starting information
    OUT     RESETPOS
    LOADI   10
    OUT     CTIMER
    SEI     &B0010
    LOAD    MASK4
    ADD     MASK5
    ADD     MASK6
    OUT     SONAREN
    LOADI   0            ; Start STATE = 0
    STORE   STATE
    JUMP    SONAR_READ      ; sonar read: occurs at end of each iter.
                            ;             outputs debugging info.

DRIVE_THERE_1:
    IN      XPOS
    SUB     Leg1            ; Leg1 = half a leg, podium to corner
    JPOS    BIG_TURN_LEFT
    ; if XPOS > Leg1:
    ;       big turn
    ; else
    ;       dsp algo
    IN      DIST4
    SUB     MAX
    JNEG    TURN_LEFT
    IN      DIST6
    SUB     MAX
    JNEG    TURN_RIGHT
    IN      DIST5
    SUB     MAX
    JZERO   TURN_RIGHT
    IN      DIST5
    ADDI    &D-190          ; make this a label
    JNEG    TURN_LEFT
    IN      DIST5
    ADDI    -210
    JPOS    TURN_RIGHT
    LOADI   0               ; ACC = 0
    STORE   DTheta          ; stop correcting
    LOAD    FFast
    STORE   DVel
    JUMP    SONAR_READ      ; debug, then SWITCH_STATE

DRIVE_THERE_2:
    IN      XPOS
    SUB     Leg2
    JPOS    TURN_AROUND_BACK
    IN      DIST4
    SUB     MAX
    JNEG    TURN_LEFT
    IN      DIST6
    SUB     MAX
    JNEG    TURN_RIGHT
    IN      DIST5
    SUB     MAX
    JZERO   TURN_RIGHT
    IN      DIST5
    ADDI    -190
    JNEG    TURN_LEFT
    IN      DIST5
    ADDI    -210
    JPOS    TURN_RIGHT
    LOADI   0
    STORE   DTheta
    LOAD    FFast
    STORE   DVel
    JUMP    SONAR_READ

DRIVE_BACK_2:
    IN      XPOS
    SUB     Leg2
    JPOS    BIG_TURN_RIGHT
    IN      DIST7
    SUB     MAX
    JNEG    TURN_LEFT
    IN      DIST1
    SUB     MAX
    JNEG    TURN_RIGHT
    IN      DIST0
    SUB     MAX
    JZERO   TURN_LEFT
    IN      DIST0
    ADDI    -190
    JNEG    TURN_LEFT
    IN      DIST0
    ADDI    -210
    JPOS    TURN_RIGHT
    LOADI   0
    STORE   DTheta
    LOAD    FFast
    STORE   DVel
    JUMP    SONAR_READ

DRIVE_BACK_1:
    IN      XPOS
    SUB     Leg1
    JPOS    TURN_AROUND_THERE
    IN      DIST7
    SUB     MAX
    JNEG    TURN_LEFT
    IN      DIST1
    SUB     MAX
    JNEG    TURN_RIGHT
    IN      DIST0
    SUB     MAX
    JZERO   TURN_LEFT
    IN      DIST0
    ADDI    -190
    JNEG    TURN_LEFT
    IN      DIST0
    ADDI    -210
    JPOS    TURN_RIGHT
    LOADI   0
    STORE   DTheta
    LOAD    FFast
    STORE   DVel
    JUMP    SONAR_READ

TURN_LEFT:
    LOADI   -5
    STORE   DTheta
    LOAD    FFast
    STORE   Dvel
    JUMP    SONAR_READ

TURN_RIGHT:
    LOADI   5
    STORE   DTheta
    LOAD    FFast
    STORE   Dvel
    JUMP    SONAR_READ

TURN_AROUND_BACK:
    OUT     RESETPOS
    LOADI   179
    STORE   DTheta

TURN_AROUND_BACK_LOOP:
    IN      Theta
    ADDI    -179
    CALL    Abs
    ADDI    -3
    JPOS    TURN_AROUND_BACK_LOOP
    LOAD    STATE
    ADDI    1
    STORE   STATE
    ; Switch sonars being used
    LOAD    MASK0
    ADD     MASK1
    ADD     MASK7
    OUT     SONAREN
    OUT     RESETPOS
    JUMP    SONAR_READ

TURN_AROUND_THERE:
    OUT     RESETPOS
    LOADI   179
    STORE   DTheta
TURN_AROUND_THERE_LOOP:
    IN      Theta
    ADDI    -179
    CALL    Abs
    ADDI    -3
    JPOS    TURN_AROUND_THERE_LOOP
    LOADI   0
    STORE   STATE
    ; Switch sonars being used
    LOAD    MASK4
    ADD     MASK5
    ADD     MASK6
    OUT     SONAREN
    OUT     RESETPOS
    JUMP    SONAR_READ

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
    LOAD    STATE                   ; make state transitions rely on labels
    ADDI    1
    STORE   STATE
    OUT     RESETPOS
    JUMP    SONAR_READ

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
    LOAD    STATE
    ADDI    1
    STORE   STATE
    OUT     RESETPOS
    JUMP    SONAR_READ

; debug block
; results in going to SWITCH_STATE after debugging is over
SONAR_READ:                 ; switch (current switch)
    IN      SWITCHES
    AND     MASK0
    JZERO   SW_1            ; case SW_1:
                            ;       print DIST0
    IN      DIST0
    OUT     LCD
    JUMP    SWITCH_STATE
SW_1:
    IN      SWITCHES
    AND     MASK1
    JZERO   SW_4
    IN      DIST1
    OUT     LCD
    JUMP    SWITCH_STATE
SW_4:
    IN      SWITCHES
    AND     MASK4
    JZERO   SW_5
    IN      DIST4
    OUT     LCD
    JUMP    SWITCH_STATE
SW_5:
    IN      SWITCHES
    AND     MASK5
    JZERO   SW_6
    IN      DIST5
    OUT     LCD
    JUMP    SWITCH_STATE
SW_6:
    IN      SWITCHES
    AND     MASK6
    JZERO   SW_7
    IN      DIST6
    OUT     LCD
    JUMP    SWITCH_STATE
SW_7:
    IN      SWITCHES
    AND     MASK7
    JZERO   DIST_DBG
    IN      DIST7
    OUT     LCD
    JUMP    SWITCH_STATE
DIST_DBG:
    IN      SWITCHES
    AND     MASK2
    JZERO   SWITCH_STATE
    IN      XPOS
    OUT     LCD
    JUMP    SWITCH_STATE

; switch (STATE)
;       case ZERO:
;           DRIVE_THERE_1();
;           break;



SWITCH_STATE:
    LOAD    STATE
    JZERO   DRIVE_THERE_1
    ADDI    -1
    JZERO   DRIVE_THERE_2
    ADDI    -1
    JZERO   DRIVE_BACK_2
    ADDI    -1
    JZERO   DRIVE_BACK_1

; Make state labels:
; DRIVE_THERE_1: &DW 1


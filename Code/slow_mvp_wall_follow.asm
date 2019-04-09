Main:
    OUT     RESETPOS
    LOADI   10
    OUT     CTIMER
    LOAD    MASK4
    ADD     MASK5
    ADD     MASK6
    OUT     SONAREN
    
DRIVE:
    IN      DIST4
    SUB     MAX
    JNEG    TURN_LEFT
    IN      DIST6
    SUB     MAX     
    JNEG    TURN_RIGHT
    LOAD    FMID
    OUT     LVELCMD
    LOAD    FMID
    OUT     RVELCMD
    JUMP    SONAR_READ
TURN_LEFT:
    LOAD    FMID
    ADDI    -120
    OUT     LVELCMD
    LOAD    FMID
    OUT     RVELCMD
    JUMP    SONAR_READ
TURN_RIGHT:
    LOAD    FMID
    ADDI    120
    OUT     LVELCMD
    LOAD    FMID
    OUT     RVELCMD
    JUMP    SONAR_READ

SONAR_READ:
    IN      SWITCHES
    AND     MASK4
    JZERO   SW_5
    IN      DIST4
    OUT     LCD
    JUMP    DRIVE
SW_5:
    IN      SWITCHES
    AND     MASK5
    JZERO   SW_6
    IN      DIST5
    OUT     LCD
    JUMP    DRIVE
SW_6:
    IN      SWITCHES
    AND     MASK6
    JZERO   DRIVE
    IN      DIST6
    OUT     LCD
    JUMP    DRIVE    

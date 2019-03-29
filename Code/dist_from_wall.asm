Main:
    OUT     RESETPOS
    LOADI   10
    OUT     CTIMER
    LOADI   32
    OUT     SONAREN
DRIVE:
    IN      DIST5
    ADDI    -400
    ADD     RSLOW
    OUT     RVELCMD
    LOAD    RSLOW
    OUT     LVELCMD
    JUMP    DRIVE

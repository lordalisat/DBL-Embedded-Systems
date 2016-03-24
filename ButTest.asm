@DATA

       BUTBUF		DS	8		; the previous button input
       CURBUT		DS	8		;
	DELTA		DW	1		; value for timer delay
	 STEP		DW	0		; current step, for PWM
	  PWM		DW	3		; max value for PWM
	MOTOR		DS	1		; variable for motor state
	STATE		DS	3		; variable for state ColorLight:ProxLightW:ProxLightB
       PAUSED		DW	1		;
        ABORT		DW	1		;
       LTIMER		DW	0		; variable for the empty detector

@CODE

      IO_AREA		EQU	-16		; base address of the I/O-Area
        TIMER		EQU	13		; timer register
       OUTPUT		EQU	11		; the 8 outputs
	 LEDS		EQU	10		; the 3 LEDs above the 3 slide switches
       DSPDIG		EQU	9		; register selecting the active display element
       DSPSEG		EQU	8		; register for the pattern on the active display element
        INPUT		EQU	7		; the 8 inputs
      ADCONVS		EQU	6		; the outputs, concatenated, of the 2 A/D-converters
	
			; Button and Detector values
       STARTB		EQU	%000000001	; location of the Start/Stop button
       ABORTB		EQU	%000000010	; location of the Abort button
	   S1		EQU	%000001000	; location of S1
	   S2		EQU	%000010000	; location of S2
	PROXB		EQU	%000100000	; location of PROXB
	PROXW		EQU	%001000000	; location of PROXW
	PROXE		EQU	%010000000	; location of PROXE
	
       LCOLOR		EQU	2		; ColorDetLight in the state variable
       LPROXW		EQU	1		; ProxLightW in the state variable
       LPROXB		EQU	0		; ProxLightB in the state variable
	
      MOTORCW		EQU	%010		; Binary expression for clockwise motor turns
     MOTORCCW		EQU	%001		; Binary expression for counterclockwise motor turns
     MOTOROFF		EQU	%000		; Binary expression for no motor turns
     
     	   ON		EQU	%01		; Binary on
     	  OFF		EQU	%00		; Binary off
      
        BLACK		EQU	%010101000	; colordet 168 for black
        ETIME		EQU	1700		; 11 ms marge van 1590
	


Main:
	LOAD		R5		IO_AREA				; Load the base I/O address
	LOAD		R0		%0111					; Set the first LED to be on
	STOR		R0		[R5+LEDS]			; And put it in the register

	LOAD		R4		[GB+ABORT]
	 BNE		DoLedsThird

DoLedsFirst:
	LOAD		R0		%101					; Set the first LED to be on
	STOR		R0		[R5+LEDS]			; And put it in the register
	BRA		DoLedsFirst

DoLedsThird:
	LOAD		R0		%100					; Set the first LED to be on
	STOR		R0		[R5+LEDS]			; And put it in the register
	BRA		DoLedsThird

ButtonCheck:
	LOAD		R3		[GB+BUTBUF]
	LOAD		R0		[R5+INPUT]
	 XOR		R3		%011111111
	 AND		R3		R0
	STOR		R3		[GB+CURBUT]
	STOR		R0		[GB+BUTBUF]
	 RTS							; Returns the new current pressed buttons in CURBUT, saves all current buttons pressed in BUTBUF

	

@END

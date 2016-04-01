;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	2IO70 - DBL Embedded Systems	;
;		Assembly program	;
;					;
;	Bram Wieringa			;
;	Yorick Spenrath			;
;	Niek Morskieft			;
;	Martijn Janssen			;
;	Wessel van Lierop		;
;	Ralph Bens			;
;					;
;	Assembly by:	Bram Wieringa	;
;			Ralph Bens	;
;					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@DATA
	DELTA		DW	1				; Value for timer delay
	 STEP		DW	0				; Current step, for PWM
	  PWM		DW	3				; Max value for PWM

	ERROR		DS	1				; Hexadecimal code for error
       CERROR		DS	1				; Hexadecimal code for last color

       BUTBUF		DS	1				; The previous button input
       CURBUT		DS	1				; The current input buffer
      STOPBUF		DS	1				; The previous stop button input
      CURSTOP		DS	1				; The current input buffer

	MOTOR		DS	1				; Variable for motor state
	STATE		DS	3				; Variable for state LCOLOR:LPROXW:LPROXB
       PAUSED		DW	1				; Variable storing pause state
        ABORT		DW	0				; Variable storing abort state
     FINISHED		DW	0				; Variable for finished state

       LTIMER		DW	0				; Variable for the empty detector
       BLACKE		DW	0				; For when disks do a flip
       WHITEE		DW	0				; For when disks do a flip

       DIGITS		DS	6				; Binary patterns for display
       CDIGIT		DS	1				; Number of the next digit
       NDIGIT		DS	1				; Binary pattern for next digit

@CODE
      IO_AREA		EQU	-16				; Base address of the I/O-Area
        TIMER		EQU	13				; Timer register
       OUTPUT		EQU	11				; The 8 outputs
	 LEDS		EQU	10				; The 3 LEDs above the 3 slide switches
       DSPDIG		EQU	9				; Register selecting the active display element
       DSPSEG		EQU	8				; Register for the pattern on the active display element
        INPUT		EQU	7				; The 8 inputs
      ADCONVS		EQU	6				; The outputs, concatenated, of the 2 A/D-converters

       LCOLOR		EQU	2				; Location of ColorDetLight in the state (Output 2)
       LPROXW		EQU	1				; Location of ProxLightW in the state (Output 1)
       LPROXB		EQU	0				; Location of ProxLightB in the state (Output 0)

        BLACK		EQU	179				; The value above which a disk is black
        ETIME		EQU	1800				; Delay for turning on lights (margin of 20 ms from 1600)

       ABORTB		EQU	%000000001			; Location of the Abort button (Input 0)
       STARTB		EQU	%000000010			; Location of the Start/Stop button (Input 1)
	   S1		EQU	%000001000			; Location of S1 (Input 3)
	   S2		EQU	%000010000			; Location of S2 (Input 4)
	PROXB		EQU	%000100000			; Location of PROXB (Input 5)
	PROXW		EQU	%001000000			; Location of PROXW (Input 6)
	PROXE		EQU	%010000000			; Location of PROXE (Input 7)

     	   ON		EQU	%01				; Binary on
     	  OFF		EQU	%00				; Binary off
      MOTORCW		EQU	%010				; Binary expression for clockwise motor turns
     MOTORCCW		EQU	%001				; Binary expression for counterclockwise motor turns
     MOTOROFF		EQU	%000				; Binary expression for no motor turns

       HEXOFF		EQU	%00000000			; 7-segment pattern for off
         HEX0		EQU	%01111110			; 7-segment pattern for '0'
         HEX1		EQU	%00110000			; 7-segment pattern for '1'
         HEX2		EQU	%01101101			; 7-segment pattern for '2'
         HEX3		EQU	%01111001			; 7-segment pattern for '3'
         HEX4		EQU	%00110011			; 7-segment pattern for '4'
         HEX5		EQU	%01011011			; 7-segment pattern for '5'
         HEX6		EQU	%01011111			; 7-segment pattern for '6'
         HEX7		EQU	%01110000			; 7-segment pattern for '7'
         HEX8		EQU	%01111111			; 7-segment pattern for '8'
         HEX9		EQU	%01111011			; 7-segment pattern for '9'
         HEXA		EQU	%01110111			; 7-segment pattern for 'A'
         HEXB		EQU	%00011111			; 7-segment pattern for 'b'
         HEXC		EQU	%01001110			; 7-segment pattern for 'C'
         HEXD		EQU	%00111101			; 7-segment pattern for 'd'
         HEXE		EQU	%01001111			; 7-segment pattern for 'E'
         HEXF		EQU	%01000111			; 7-segment pattern for 'F'
         HEXR		EQU	%00000101			; 7-segment pattern for 'R'
         HEXW		EQU	%01011100			; 7-segment pattern for 'W'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interrupt Enable	;
; Sets the ISR to run TimerISR	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableInterrupt:
	LOAD		R0		TimerISR		; Store the address of the ISR part in R0
	 ADD		R0		R5			; Add datapath to the code
	LOAD		R1		16			; Set R1 := 16
	STOR		R0		[R1]			; Save R0 in the address of R1
	 BRA		Main					; Get started with the main program

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interrupt		;
; Handles all returning tasks	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TimerISR:
	LOAD		R0		[GB+DELTA]		; Get the timer interrupt delay
	STOR		R0		[R5+TIMER]		; Store it in the timer to get an initial delay
	 BRS		AbortCheck				; Checking if the abort button has been pressed
	 BRS		StopCheck				; Checking if the stop button has been pressed
	 BRS		LightTimerDecrease			; Decrease for the timer of the color detector light
	 BRS		UpdateDisplay				; Subroutine for updating the display
	 BRS		Output					; Subroutine for the outputs
	SETI		8					; Enable the interrupt again
	 RTE							; Return from exception

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Abort and Pause Check	;
; Subroutines to check buttons	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AbortCheck:
	LOAD		R1		[R5+INPUT]		; Load the current inputs
	 AND		R1		ABORTB			; Check if the input at ABORTB is high
	 BEQ		AbortReturn				; If the result == 0, go to AbortReturn
	LOAD		R4		1			; Otherwise, load 1 to R4
	STOR		R4		[GB+ABORT]		; And set it in the ABORT variable
	  
AbortReturn:
	 RTS							; Return from subroutine

StopCheck:
	 BRS		StopButtonCheck				; Run the StopButtonCheck subroutine
	LOAD		R1		[GB+PAUSED]		; Get the PAUSED variable
	 BNE		StopReturn				; See if it's 1, go to StopReturn
	LOAD		R1		[GB+CURSTOP]		; Get the current stop button state
	 AND		R1		STARTB			; See if the input at STARTB is high
	 BEQ		StopReturn				; If it's not, go to StopReturn				; To-Do: Check if this is done properly
	LOAD		R4		1			; Otherwise, set R4 to 1
	STOR		R4		[GB+PAUSED]		; And put it in the PAUSED variable
	  
StopReturn:
	 RTS							; Return from subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	LightTimer		;
; Decreases the light timer	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LightTimerDecrease:
	LOAD		R0		[GB+LTIMER]		; Load the current LTIMER value
	 SUB		R0		1			; Subtract one
	STOR		R0		[GB+LTIMER]		; Store it back in LTIMER
	 RTS							; And return from subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Display			;
; Updates the 7-segment display	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateDisplay:
	LOAD		R0		[GB+CDIGIT]		; Get the CDIGIT value
	 CMP		R0		5			; See if we've arrived at the right-most digit
	 BEQ		UpdateFinalDigit			; If so, proceed with digit 5

UpdateDigit:
	LOAD		R1		R0			; Now load CDIGIT into R1
	 ADD		R1		DIGITS			; R1 := offset(DIGITS[CDIGIT])
	LOAD		R1		[GB+R1]			; R1 := DIGITS[CDIGIT]
	STOR		R1		[R5+DSPSEG]		; Display the pattern on the next digit
	 ADD		R0		1			; Add 1 to R0
	STOR		R0		[GB+CDIGIT]		; Store the R0 in CDIGIT
	LOAD		R0		[GB+NDIGIT]		; Get the next display value
	STOR		R0		[R5+DSPDIG]		; And activate it
	 ADD		R0		R0			; Multiply R0 by 2
	STOR		R0		[GB+NDIGIT]		; And store it in NDIGIT
	 RTS							; Now return from subroutine

UpdateFinalDigit:
 	LOAD		R1		[GB+DIGITS+5]		; Directly load the digit value
	STOR		R1		[R5+DSPSEG]		; Display it the correct segment
	LOAD		R0		0			; Set R0 to 0
	STOR		R0		[GB+CDIGIT]		; And store it in CDIGIT
	LOAD		R0		[GB+NDIGIT]		; Get the next display value
	STOR		R0		[R5+DSPDIG]		; And activate it
	LOAD		R0		1			; Set R0 to 1
	STOR		R0		[GB+NDIGIT]		; Store R0 in NDIGIT
	 RTS							; Return from subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Output			;
; Updates outputs and apply PWM	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Output:
	LOAD		R1		%00000000		; Initialize R1 at no bits to be on
	LOAD		R2		[GB+STATE+LPROXB]	; Get the LPROXB bit
	  OR		R1		R2			; Set the bit to be in the 1st position on R1
	LOAD		R2		[GB+STATE+LPROXW]	; Get the LPROXW bit
	MULS		R2		%0010			; Move the bit to the 2nd position
	  OR		R1		R2			; Set the bit on position 2
	LOAD		R2		[GB+STATE+LCOLOR]	; Get the LCOLOR bit
	MULS		R2		%0100			; Move the bit to the 3rd position
	  OR		R1		R2			; Finally compile the whole thing in R1

MotorCheck:
	LOAD		R0		[GB+STEP]		; Load STEP in R0
	 CMP		R0		[GB+PWM]		; See if R0 is smaller than PWM
	 BCS		MotorOn					; Branch to MotorOn
	 BRA		MotorOff				; Otherwise to MotorOff

MotorOff:
	LOAD		R2		MOTOROFF		; Get the MOTOROFF state
	 BRA		Motor					; Branch to Motor

MotorOn:
	LOAD		R2		[GB+MOTOR]		; Load the MOTOR value that we want

Motor:
	MULS		R2		%010000			; Multiply by 16
	  OR		R1		R2			; Or the light state and motor state

Step:
	STOR		R1		[R5+OUTPUT]		; Set the calculated output
	 MOD		R0		4			; Modulo step by 4
	 ADD		R0		1			; Add one to the step
	STOR		R0		[GB+STEP]		; Store it back in STEP
	 RTS							; Return from subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Main states		;
; The beginning and the end 	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Main:
	LOAD		R5		IO_AREA			; Load the base I/O address
	LOAD		R0		[GB+DELTA]		; Set R0 := DELTA
	 SUB		R0		[R5+TIMER]		; R0 := -TIMER
	STOR		R0		[R5+TIMER]		; TIMER := TIMER+R0
	SETI		8					; Enable the interrupt service routine

Off:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTORCW			; Load the MOTORCW value
	STOR		R2		[GB+MOTOR]		; Set the motor to turn CW
	 BRA		ToIdle					; Branch to ToIdle

Finished:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
 	LOAD		R2		MOTORCW			; Set R2 to MOTORCW
	STOR		R2		[GB+MOTOR]		; And set it to rotate CW
	LOAD		R4		[GB+FINISHED]		; Load the FINISHED value
	 BEQ		EmptyCheck				; If zero, then go to EmptyCheck
	LOAD		R4		0			; Set R4 to 0
	STOR		R4		[GB+FINISHED]		; Store R4 to FINISHED
	LOAD		R0		OFF			; Get the OFF value
	STOR		R0		[GB+STATE+LPROXB]	; Set LPROXB off
	STOR		R0		[GB+STATE+LPROXW]	; Set LPROXW off
	STOR		R0		[GB+STATE+LCOLOR]	; Set LCOLOR off
	 BRA		ToIdle1					; Then go to ToIdle1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Required idle states	;
; Fool proof idle state checks	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ToIdle:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Run the ButtonCheck
	LOAD		R1		[GB+CURBUT]		; Get the CURBUT state in R1
	 AND		R1		S1			; Check if S1 is high
	 BNE		ToIdle1					; If it is, go to ToIdle1
	LOAD		R1		[GB+CURBUT]		; Load CURBUT in R1 again
	 AND		R1		S2			; Check if S2 is high
	 BNE		ToIdle2					; If it is, go to ToIdle2
	 BRA		ToIdle					; Otherwise, keep looping

ToIdle1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Run the ButtonCheck
	LOAD		R1		[GB+CURBUT]		; Set CURBUT to R1
	 AND		R1		S1			; Test if S1 is high
	 BNE		Abort0					; If it is, abort with code 0
	LOAD		R1		[GB+CURBUT]		; Get CURBUT again
	 AND		R1		S2			; Test if S2 is high
	 BNE		IdleFill				; If it is, go to IdleFill
	 BRA		ToIdle1					; Otherwise, keep looping

ToIdle2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Run the ButtonCheck subroutine
	LOAD		R1		[GB+CURBUT]		; Load CURBUT to R1
	 AND		R1		S1			; Check if S1 is high
	 BNE		ToIdle1					; If is is, go back to ToIdle1
	LOAD		R1		[GB+CURBUT]		; Load CURBUT
	 AND		R1		S2			; And compare with S2
	 BNE		Abort1					; If it's high, abort with code 1
	 BRA		ToIdle2					; Otherwise, keep looping

IdleFill:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTOROFF		; Load the MOTOROFF value
	STOR		R2		[GB+MOTOR]		; Set the motor to be OFF
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R0		STARTB			; Check if STARTB is high
	 BNE		IdleCheckInit				; If it is, go to IdleCheckInit
	 BRA		IdleFill				; Loop through IdleFill

IdleCheckInit:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R4		0			; Load 0 into R4
	STOR		R4		[GB+PAUSED]		; Unpause the machine
	LOAD		R2		ON			; Load the ON value
	STOR		R2		[GB+STATE+LPROXB]	; Set the PROXB light to be ON
	STOR		R2		[GB+STATE+LPROXW]	; Set the PROXW light to be ON
	STOR		R2		[GB+STATE+LCOLOR]	; Set the COLOR light to be ON
	 BRS		LightSwitch				; Let the program wait for the lights to turn on
	 BRS		ButtonCheck				; Run the ButtonCheck
	LOAD		R2		MOTORCW			; Load the MOTORCW value
	STOR 		R2		[GB+MOTOR]		; Set the motor to turn CW

IdleCheck:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R0		0			; Set R0 to 0
	STOR		R0		[GB+BLACKE]		; Reset BLACKE to 0
	STOR		R0		[GB+WHITEE]		; Reset WHITEE to 0
	 BRS		ButtonCheck				; Get the button state
;	LOAD		R1		[GB+CURBUT]		; Get the input values
;	 AND		R1		PROXB			; Check if PROXB is high
;	 BNE		Abortn					; If it is, abort
;	LOAD		R1		[GB+CURBUT]		; Get the input values
;	 AND		R1		PROXW			; Check if PROXW is high
;	 BNE		Abortn					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		Idle					; If it is, go to Idle
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		Abort2					; If it is, abort with code 2
	 BRA		IdleCheck				; Loop through TurnBlack2

Idle:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTOROFF		; Load MOTOROFF in R2
	STOR		R2		[GB+MOTOR]		; Set the MOTOR
	LOAD		R4		[GB+PAUSED]		; Set R4 as PAUSED
	 BNE		IdlePausedInit				; Check if we have to go to PAUSED
	 BRA		Scanning				; Go to the Scanning state

IdlePausedInit:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R0		OFF			; Set R0 to OFF
	STOR		R0		[GB+STATE+LPROXB]	; Set LPROXB to off
	STOR		R0		[GB+STATE+LPROXW]	; Set LPROXW to off
	LOAD		R1		[R5+INPUT]		; Get the input before turning LCOLOR off
	STOR		R0		[GB+STATE+LCOLOR]	; Turn it off as well
	 AND		R1		PROXE			; Check if PROXE is high
	 BEQ		IdlePaused				; If it is, go to IdlePaused
	LOAD		R2		MOTORCW			; Set R2 to MOTORCW value
	STOR		R2		[GB+MOTOR]		; Set the MOTOR to use R2
	 BRA		ToIdle1					; Go back to ToIdle1

IdlePaused:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Run the ButtonCheck subroutine
	LOAD		R1		[GB+CURBUT]		; Get the CURBUT state
	 AND		R1		STARTB			; See if the input at STARTB is high
	 BEQ		IdlePaused				; If it's not, then keep looping
	LOAD		R0		0			; Set R0 to 0
	STOR		R0		[GB+PAUSED]		; Reset R0 to 0
	LOAD		R0		ON			; Get the ON binary value
	STOR		R0		[GB+STATE+LPROXB]	; SET LPROXB on
	STOR		R0		[GB+STATE+LPROXW]	; SET LPROXW on
	STOR		R0		[GB+STATE+LCOLOR]	; SET LCOLOR on
	 BRS		LightSwitch				; Wait for them to be on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Scanning states		;
; All states while scanning	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Scanning:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R1		[R5+INPUT]		; Get the current input
	 AND		R1		PROXE			; And see if PROXE is high
	 BNE		Finished				; If it is, we go to Finished
	LOAD		R4		0			; Set R4 to 0
	STOR		R4		[GB+FINISHED]		; Store R4 to FINISHED
	LOAD		R1		[R5+ADCONVS]		; Get the color value
	DVMD		R1		256			; Get the modulo 256 value
	LOAD		R4		R2			; Temporarily store this in R4
	DVMD		R2		10			; R2,R3 = R2 / 10, R2 % 10
	LOAD		R0		R3			; R0 := R3
	 BRS		Hex2Seg7				; Convert to 7-segment
	STOR		R1		[GB+DIGITS+0]		; Store it in DIGITS+0
	DVMD		R2		10			; R2,R3 = R2 / 10, R2 % 10
	LOAD		R0		R3			; R0 := R3
	 BRS		Hex2Seg7				; Convert to 7-segment
	STOR		R1		[GB+DIGITS+1]		; Store it in DIGITS+1
	DVMD		R2		10			; R2,R3 = R2 / 10, R2 % 10
	LOAD		R0		R3			; R0 := R3
	 BRS		Hex2Seg7				; Convert to 7-segment
	STOR		R1		[GB+DIGITS+2]		; Store it in DIGITS+2
	LOAD		R2		OFF			; Get the OFF value
	STOR		R2		[GB+CERROR]		; And clear CERROR
	 CMP		R4		BLACK			; Now compare stored R4 with BLACK
	 BPL		TurnBlack				; If BLACK < R4 go to TurnBlack
	 BRA		TurnWhite				; Otherwise, go to TurnWhite

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	EmptyCheck states	;
; All states while empty	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmptyCheck:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R4		1			; Set R4 to 1
	STOR		R4		[GB+FINISHED]		; Store R4 into FINISHED
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		AbortB					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		IdleCheck				; If it is, go to IdleCheck
	 BRA		EmptyCheck				; Loop through EmptyCheck

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Black disk states	;
;  All states while turning CW	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TurnBlack:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTORCW			; Load the CW value
	STOR		R2		[GB+MOTOR]		; Make the motor rotate CW
	LOAD		R2		HEXB			; Get the B hex display
	STOR		R2		[GB+CERROR]		; Store it in CERROR

TurnBlack1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
;	LOAD		R1		[GB+CURBUT]		; Get the input values
;	 AND		R1		PROXB			; Check if PROXB is high
;	 BNE		Abortn					; If it is, abort
;	LOAD		R1		[GB+CURBUT]		; Get the input values
;	 AND		R1		PROXW			; Check if PROXW is high
;	 BNE		Abortn					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		Abort3					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		TurnBlack2				; If it is, go to TurnBlack2
	 BRA		TurnBlack1				; Loop through TurnBlack1

TurnBlack2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXB			; Check if PROXB is high
	 BNE		IdleCheck				; If it is, go to IdleCheck
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; Check if PROXW is high
	 BNE		Abort4					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		FlipErrorB				; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		Abort5					; If it is, abort
	 BRA		TurnBlack2				; Loop through TurnBlack2

FlipErrorB:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R1		[GB+BLACKE]		; Load the BLACKE value
	 BNE		Abort9					; If it's already 1, abort with code 9
	LOAD		R0		1			; Otherwise set R0 to 1
	STOR		R0		[GB+BLACKE]		; Set BLACKE to 1
	 BRA		Idle					; And branch back to Idle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	White disk states	;
;  All states while turning CCW	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TurnWhite:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTORCCW		; Load the CCW value
	STOR		R2		[GB+MOTOR]		; Make the motor rotate CCW
	LOAD		R2		HEXW			; Get the W hex value
	STOR		R2		[GB+CERROR]		; And store it in CERROR

TurnWhite1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
;	LOAD		R1		[GB+CURBUT]		; Get the input values
;	 AND		R1		PROXB			; Check if PROXB is high
;	 BNE		Abortn					; If it is, abort
;	LOAD		R1		[GB+CURBUT]		; Get the input values
;	 AND		R1		PROXW			; Check if PROXW is high
;	 BNE		Abortn					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		Abort6					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		TurnWhite2				; If it is, go to TurnWhite2
	 BRA		TurnWhite1				; Loop through TurnWhite1

TurnWhite2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button states
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXB			; Check if PROXB is high
	 BNE		Abort7					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; Check if PROXW is high
	 BNE		IdleCheck				; If it is, go to IdleCheck
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		FlipErrorW				; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		Abort8					; If it is, abort
	 BRA		TurnWhite2				; Loop through TurnWhite2

FlipErrorW:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R1		[GB+WHITEE]		; Load the WHITEE value
	 BNE		AbortA					; If it's already 1, abort with code A
	LOAD		R0		1			; Otherwise, set R0 to 1
	STOR		R0		[GB+WHITEE]		; And store it in WHITEE
	 BRA		Idle					; After that branch to Idle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Abort states		;
;  Allows for error code ids	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Abort0:
	LOAD		R0		HEX0			; Set R0 := HEX0
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort1:
	LOAD		R0		HEX1			; Set R0 := HEX1
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort2:
	LOAD		R0		HEX2			; Set R0 := HEX2
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort3:
	LOAD		R0		HEX3			; Set R0 := HEX3
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort4:
	LOAD		R0		HEX4			; Set R0 := HEX4
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort5:
	LOAD		R0		HEX5			; Set R0 := HEX5
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort6:
	LOAD		R0		HEX6			; Set R0 := HEX6
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort7:
	LOAD		R0		HEX7			; Set R0 := HEX7
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort8:
	LOAD		R0		HEX8			; Set R0 := HEX8
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort9:
	LOAD		R0		HEX9			; Set R0 := HEX9
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

AbortA:
	LOAD		R0		HEXA			; Set R0 := HEXA
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

AbortB:
	LOAD		R0		HEXB			; Set R0 := HEXA
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

Abort:
	LOAD		R0		HEXOFF			; Set R0 := HEXOFF
	STOR		R0		[GB+ERROR]		; Store it in ERROR
	 BRA		AbortLoop				; Go to the AbortLoop

AbortLoop:
	LOAD		R0		%0111			; Get value of all 3 leds on
	STOR		R0		[R5+LEDS]		; And store it in LEDS
	LOAD		R4		0			; Set R4 := 0
	STOR		R4		[GB+ABORT]		; And set the ABORT variable back to 0
	LOAD		R0		OFF			; Get the OFF state
	STOR		R0		[GB+STATE+LPROXB]	; Apply to LPROXB
	STOR		R0		[GB+STATE+LPROXW]	; Apply to LPROXW
	STOR		R0		[GB+STATE+LCOLOR]	; Apply to LCOLOR
	LOAD		R2		MOTOROFF		; Get the MOTOROFF
	STOR		R2		[GB+MOTOR]		; And put it in MOTOR
	LOAD		R0		[GB+ERROR]		; Get the current ERROR code
	STOR		R0		[GB+DIGITS+5]		; Put it in the last display
	LOAD		R0		[GB+CERROR]		; Get the CERROR color
	STOR		R0		[GB+DIGITS+4]		; Put it in the 2nd last display
	LOAD		R0		HEXE			; Get the 'E' value
	STOR		R0		[GB+DIGITS+2]		; Write it to display 2
	LOAD		R0		HEXR			; And get the 'r' value
	STOR		R0		[GB+DIGITS+1]		; Write it to display 1
	STOR		R0		[GB+DIGITS+0]		; And display 0
	 BRS		ButtonCheck				; Run the ButtonCheck subroutine
	LOAD		R1		[GB+CURBUT]		; Load CURBUT to R1
	 AND		R1		STARTB			; And see if STARTB is high
	 BEQ		AbortLoop				; While it's not, keep looping
	LOAD		R0		%0000			; Otherwise, set R0 to 0
	STOR		R0		[R5+LEDS]		; And turn off the LEDS
	LOAD		R0		HEXOFF			; Get the blank 7-segment value
	STOR		R0		[GB+DIGITS+0]		; And turn off display 0
	STOR		R0		[GB+DIGITS+1]		; As well as display 1
	STOR		R0		[GB+DIGITS+2]		; And display 2
	STOR		R0		[GB+DIGITS+3]		; Don't forget display 3
	STOR		R0		[GB+DIGITS+4]		; Hey, 4 might still be on
	STOR		R0		[GB+DIGITS+5]		; And finally set 5 to be off
	 BRA		Off					; Go back to the Off state to start over

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	LightSwitch		;
;  Waits for the lights to warm	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LightSwitch:
	LOAD		R4		[GB+ABORT]		; Get the ABORT value
	 BNE		LightSwitchDone				; If we abort, get out
	LOAD		R0		ETIME			; Otherwise, load ETIME in R0
	STOR		R0		[GB+LTIMER]		; And store it in LTMIMER

LightSwitchLoop:
	LOAD		R4		[GB+ABORT]		; Again, check the ABORT
	 BNE		LightSwitchDone				; Break out if we aborted
	LOAD		R0		[GB+LTIMER]		; Get the LTIMER value
	 BNE		LightSwitchLoop				; Keep looping while it's not 0

LightSwitchDone:
	 RTS							; Return from subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      Display Converters	;
; Convert digit to 7-segment	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Hex2Seg7:
	 BRS		Hex2Seg7Begin

Hex2Seg7Data:							; Define all hexadecimal digits as constants
	CONS		HEX0					; Get HEX0 value and define as constant
	CONS		HEX1					; Get HEX1 value and define as constant
	CONS		HEX2					; Get HEX2 value and define as constant
	CONS		HEX3					; Get HEX3 value and define as constant
	CONS		HEX4					; Get HEX4 value and define as constant
	CONS		HEX5					; Get HEX5 value and define as constant
	CONS		HEX6					; Get HEX6 value and define as constant
	CONS		HEX7					; Get HEX7 value and define as constant
	CONS		HEX8					; Get HEX8 value and define as constant
	CONS		HEX9					; Get HEX9 value and define as constant
	CONS		HEXA					; Get HEXA value and define as constant
	CONS		HEXB					; Get HEXB value and define as constant
	CONS		HEXC					; Get HEXC value and define as constant
	CONS		HEXD					; Get HEXD value and define as constant
	CONS		HEXE					; Get HEXE value and define as constant
	CONS		HEXF					; Get HEXF value and define as constant
	CONS		HEXOFF					; Get HEXOFF value and define as constant

Hex2Seg7Begin:
	 CMP		R0		16			; Check if R0 is smaller than 16
	 BCS		Hex2Seg7End				; If it is, end right away
	LOAD		R0		16			; Otherwise, set it 16

Hex2Seg7End:
	LOAD		R1		[SP++]			; R1 := address(tbl) from stack
	LOAD		R1		[R1+R0]			; R1 := tbl[R0]
	 RTS							; Return from subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Button Checks		;
; Returns changed button inputs	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ButtonCheck:
	LOAD		R3		[GB+BUTBUF]		; Get the current BUTBUF in R3 (previous inputs)
	LOAD		R0		[R5+INPUT]		; Loads the current inputs in R0
	 XOR		R3		%011111111		; Inverts the previous inputs
	 AND		R3		R0			; Checks R0 with R3 to get all changed inputs
	STOR		R3		[GB+CURBUT]		; Store changed inputs in CURBUT
	STOR		R0		[GB+BUTBUF]		; Store the current input in BUTBUF
	 RTS							; Returns the new current pressed buttons in CURBUT, saves all current buttons pressed in BUTBUF

StopButtonCheck:
	LOAD		R3		[GB+STOPBUF]		; Get the current STOPBUF in R3 (previous inputs)
	LOAD		R0		[R5+INPUT]		; Loads the current inputs in R0
	 XOR		R3		%011111111		; Inverts the previous inputs
	 AND		R3		R0			; Checks R0 with R3 to get all changed inputs
	STOR		R3		[GB+CURSTOP]		; Store changed inputs in CURSTOP
	STOR		R0		[GB+STOPBUF]		; Store the current input in STOPBUF
	 RTS							; Returns the new current pressed buttons in CURSTOP, saves all current buttons pressed in STOPBUF	

@END
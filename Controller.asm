@DATA

       BUTBUF		DS	1		; the previous button input
       CURBUT		DS	1		;
	DELTA		DW	10		; value for timer delay
	 STEP		DW	0		; current step, for PWM
	  PWM		DW	3		; max value for PWM
	MOTOR		DS	1		; variable for motor state
	STATE		DS	3		; variable for state ColorLight:ProxLightW:ProxLightB
       PAUSED		DW	1		;
        ABORT		DW	0		;
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
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interrupt Enable	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableInterrupt:
	LOAD		R0		TimerISR		; Store the address of the ISR part in R0
	 ADD		R0		R5			; Add datapath to the code
	LOAD		R1		16			; Set R1 := 16
	STOR		R0		[R1]			; Save R0 in the address of R1
	 BRA		Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interupt		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TimerISR:
	LOAD		R0		[GB+DELTA]
	STOR		R0		[R5+TIMER]
	 BRS		AbortCheck				; Checking if the abort button has been pressed
	 BRS		StopCheck				; Checking if the stop button has been pressed
	 BRS		LightTimerDecrease			; Decrease for the timer of the color detector light
	 BRS		Output					; Subroutine for the outputs
	SETI		8
	 RTE
	 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interupt Subs	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Abort and Pause Check	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AbortCheck:
	LOAD		R1		[R5+INPUT]
	 AND		R1		ABORTB
	 BEQ		AbortReturn
	LOAD		R4		1
	STOR		R4		[GB+ABORT]
	  
AbortReturn:
	 RTS

StopCheck:
	 BRS		ButtonCheck
	LOAD		R1		[GB+PAUSED]
	 BNE		StopReturn
	LOAD		R1		[GB+CURBUT]
	 AND		R1		STARTB
	 BEQ		StopReturn
	LOAD		R4		1
	STOR		R4		[GB+PAUSED]
	  
StopReturn:
	 RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	LightTimer		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LightTimerDecrease:
	LOAD		R0		[GB+LTIMER]
	 SUB		R0		1
	STOR		R0		[GB+LTIMER]
	 RTS
	 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Output			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Output:
	LOAD		R1		[GB+STATE]		; Load state of lights

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
	 MOD		R0		4			; Modulo step by 4 (NOTE: 0:0 - 
	 ADD		R0		1			; Add one to the step	(NOTE: 0:1 - 
	STOR		R0		[GB+STEP]		; Store it back in STEP
	 RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Main			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Main:
	LOAD		R5		IO_AREA			; Load the base I/O address
	LOAD		R0		[GB+DELTA]		; Set R0 := DELTA
	 SUB		R0		[R5+TIMER]		; R0 := -TIMER
	STOR		R0		[R5+TIMER]		; TIMER := TIMER+R0
	SETI		8					; Enable the interrupt service routine
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	States			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Off:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTORCW			; Load the MOTORCW value
	STOR		R2		[GB+MOTOR]		; Set the motor to turn CW

ToIdle:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S1
	 BNE		ToIdle1
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S2
	 BNE		ToIdle2
	 BRA		ToIdle
	 
ToIdle1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S1
	 BNE		Abort
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S2
	 BNE		IdleFill
	 BRA		ToIdle1
	 
ToIdle2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S1
	 BNE		ToIdle1
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S2
	 BNE		Abort
	 BRA		ToIdle2
	
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
	LOAD		R2		MOTORCW			; Load the MOTORCW value
	STOR 		R2		[GB+MOTOR]		; Set the motor to turn CW
	LOAD		R2		ON			; Load the ON value
	STOR		R2		[GB+STATE+LPROXB]	; Set the PROX lights to be ON
	STOR		R2		[GB+STATE+LPROXW]

IdleCheck:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXB			; Check if PROXB is high
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; Check if PROXW is high
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		Idle					; If it is, go to Idle
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		Abort					; If it is, abort
	 BRA		IdleCheck				; Loop through TurnBlack2
	 
Idle:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTOROFF
	STOR		R2		[GB+MOTOR]
	LOAD		R4		[GB+PAUSED]
	 BNE		IdlePausedInit
	 BRA		Scanning
	 
IdlePausedInit:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		LightSwitch
	LOAD		R1		[R5+INPUT]
	 AND		R1		PROXE
	 BNE		IdlePaused
	LOAD		R2		MOTORCW
	STOR		R2		[GB+MOTOR]
	 BRA		ToIdle1
	 
IdlePaused:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 AND		R1		STARTB
	 BNE		Scanning
	 BRA		IdlePaused

Scanning:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		LightSwitch
	LOAD		R1		[R5+INPUT]
	 AND		R1		PROXE
	 BNE		Finished
	LOAD		R1		[R5+ADCONVS]
	DVMD		R1		256
	 CMP		R2		BLACK
	 BPL		TurnBlack
	 BRA		TurnWhite

TurnBlack:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTORCW			; Load the CW value
	STOR		R2		[GB+MOTOR]		; Make the motor rotate CW
	LOAD		R2		ON			; Load the on variable
	STOR		R2		[GB+STATE+LPROXB]	; Set the PROX lights to be ON
	STOR		R2		[GB+STATE+LPROXW]
	
TurnBlack1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXB			; Check if PROXB is high
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; Check if PROXW is high
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		Abort					; If it is, abort
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
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		Abort					; If it is, abort
	 BRA		TurnBlack2				; Loop through TurnBlack2

TurnWhite:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTORCCW		; Load the CCW value
	STOR		R2		[GB+MOTOR]		; Make the motor rotate CCW
	LOAD		R2		ON			; Load the on variable
	STOR		R2		[GB+STATE+LPROXB]	; Set the PROX lights to be ON
	STOR		R2		[GB+STATE+LPROXW]
	
TurnWhite1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXB			; Check if PROXB is high
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; Check if PROXW is high
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		Abort					; If it is, abort
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
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; Check if PROXW is high
	 BNE		IdleCheck				; If it is, go to IdleCheck
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BNE		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		Abort					; If it is, abort
	 BRA		TurnWhite2				; Loop through TurnWhite2

Finished:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTORCW
	STOR		R2		[GB+MOTOR]
	 BRA		ToIdle1
	
Abort:
	LOAD		R0		%0111
	STOR		R0		[R5+LEDS]
	
	LOAD		R4		0
	STOR		R4		[GB+ABORT]
	LOAD		R0		OFF
	STOR		R0		[GB+STATE+LPROXB]
	STOR		R0		[GB+STATE+LPROXW]
	STOR		R0		[GB+STATE+LCOLOR]
	LOAD		R2		MOTOROFF
	STOR		R2		[GB+MOTOR]
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 AND		R1		STARTB
	 BNE		Off  
	 BRA		Abort

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	LightSwitch		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LightSwitch:
	LOAD		R4		[GB+ABORT]
	 BNE		LightSwitchDone
	LOAD		R0		ETIME
	STOR		R0		[GB+LTIMER]
	LOAD		R2		ON
	STOR		R2		[GB+STATE+LCOLOR]
	
LightSwitchLoop:
	LOAD		R4		[GB+ABORT]
	 BNE		LightSwitchDone
	LOAD		R0		[GB+LTIMER]
	 BNE		LightSwitchLoop
	 
LightSwitchFinish:
	LOAD		R4		[GB+ABORT]
	 BNE		LightSwitchDone
	LOAD		R2		OFF
	STOR		R2		[GB+STATE+LCOLOR]
	
LightSwitchDone:
	 RTS							; Subrouting for turning the color detector light on, takes 1700 ticks to warm up
	 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Button Checks		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ButtonCheck:
	LOAD		R3		[GB+BUTBUF]
	LOAD		R0		[R5+INPUT]
	 XOR		R3		%011111111
	 AND		R3		R0
	STOR		R3		[GB+CURBUT]
	STOR		R0		[GB+BUTBUF]
	 RTS							; Returns the new current pressed buttons in CURBUT, saves all current buttons pressed in BUTBUF

	

@END

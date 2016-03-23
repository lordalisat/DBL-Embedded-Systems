@DATA

       BUTBUF		DW	0		; the previous button input
       CURBUT		DW	0		;
      STOPBUF		DW	0		; the previous stop button input
      STOPBUT		DW	0		;
	DELTA		DW	1		; value for timer delay
	 STEP		DW	0		; current step, for PWM
	  PWM		DW	3		; max value for PWM
	MOTOR		DS	2		; variable for motor state
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
	
       LCOLOR		EQU	2
       LPROXW		EQU	1
       LPROXB		EQU	0
	
	
      MOTORCW		EQU	%010
     MOTORCCW		EQU	%001
     MOTOROFF		EQU	%000
     
     	   ON		EQU	%01
     	  OFF		EQU	%00
      
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
	SETI		8					; Enable the interrupt service routine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Initialization		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	LOAD		R5		IO_AREA			; Load the base I/O address
	LOAD		R0		[GB+DELTA]		; Set R0 := DELTA
	SUB		R0		[R5+TIMER]		; R0 := -TIMER
	STOR		R0		[R5+TIMER]		; TIMER := TIMER+R0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	States			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



Off:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	LOAD		R2		MOTORCW
	STOR		R2		[GB+MOTOR]

ToIdle:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 BEQ		ToIdle1
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S2
	 BEQ		ToIdle2
	 BRA		ToIdle
	 
ToIdle1:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S1
	 BEQ		Abort
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S2
	 BEQ		IdleFill
	 BRA		ToIdle1
	 
ToIdle2:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S1
	 BEQ		ToIdle1
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S2
	 BEQ		Abort
	 BRA		ToIdle2
	
IdleFill:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	LOAD		R2		MOTOROFF
	STOR		R2		[GB+MOTOR]
	 BRS		StopButtonCheck
	LOAD		R1		[GB+STOPBUT]
	 AND		R0		STARTB
	 BNE		IdleFill
	LOAD		R4		0
	STOR		R4		[GB+PAUSED]
	LOAD		R2		MOTORCW
	STOR 		R2		[GB+MOTOR]
	 BEQ		IdleCheckInit
	 
IdleCheckInit:
	LOAD		R2		ON
	STOR		R2		[GB+STATE+LPROXB]
	STOR		R2		[GB+STATE+LPROXW]


IdleCheck:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	 BRS		ButtonCheck
	LOAD		R1		[GB+CURBUT]
	 AND		R1		S1
	 BEQ		Idle
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BEQ		Abort					; If it is, abort
	 BRA		IdleCheck
	 
Idle:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	LOAD		R2		MOTOROFF
	STOR		R2		[GB+MOTOR]
	LOAD		R4		[GB+PAUSED]
	 BEQ		IdlePausedInit
	 BRA		Scanning
	 
IdlePausedInit:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	 BRS		LightSwitch
	LOAD		R1		[R5+INPUT]
	 AND		R1		PROXE
	 BEQ		IdlePaused
	LOAD		R2		MOTORCW
	STOR		R2		[GB+MOTOR]
	 BRA		ToIdle1
	 
IdlePaused:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	 BRS		StopButtonCheck
	LOAD		R1		[GB+STOPBUT]
	 AND		R1		STARTB
	 BNE		Scanning
	 BRA		IdlePaused

Scanning:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	 BRS		LightSwitch
	LOAD		R1		[R5+INPUT]
	 AND		R1		PROXE
	 BEQ		Finished
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
	 AND		R1		PROXB			; See if PROXB is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; See if PROXW is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BEQ		TurnBlack2				; If it is, go to TurnBlack2
	 BRA		TurnBlack1
	
TurnBlack2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXB			; See if PROXB is high
	 BEQ		IdleCheck				; If it is, go to IdleCheck
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; See if PROXB is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BEQ		Abort					; If it is, abort
	 BRA		TurnBlack2				; Return to the idle check where everything is disabled

TurnWhite:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R2		MOTORCCW		; Load the CCW value
	STOR		R2		[GB+MOTOR]		; Make the motor rotate CW
	LOAD		R2		ON			; Load the on variable
	STOR		R2		[GB+STATE+LPROXB]	; Set the PROXB light to be ON
	STOR		R2		[GB+STATE+LPROXW]
	
TurnWhite1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXB			; See if PROXB is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; See if PROXW is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BEQ		TurnWhite2				; While it isn't, keep turning
	 BRA		TurnWhite1
	
TurnWhite2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXB			; See if PROXB is high
	 BEQ		Abort					; While it isn't high, keep checking
	LOAD		R1		[GB+CURBUT]		; Get the input values
	 AND		R1		PROXW			; See if PROXB is high
	 BEQ		IdleCheck				; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BEQ		Abort					; If it is, abort
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BEQ		Abort					; If it is, abort
	 BRA		TurnWhite2				; Return to the idle check where everything is disabled

Finished:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	LOAD		R2		MOTORCW
	STOR		R2		[GB+MOTOR]
	 BRA		ToIdle1
	
Abort:
	LOAD		R0		OFF
	STOR		R0		[GB+STATE+LPROXB]
	STOR		R0		[GB+STATE+LPROXW]
	STOR		R0		[GB+STATE+LCOLOR]
	LOAD		R2		MOTOROFF
	STOR		R2		[GB+MOTOR]
	
	 BRS		StopButtonCheck
	LOAD		R1		[GB+STOPBUT]
	 AND		R1		STARTB
	 BNE		AbortContinue  
	 BRA		Abort
	
AbortContinue:
	LOAD		R4		0
	STOR		R4		[GB+ABORT]
	 BRA		Off



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
	 RTS
	 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Button Checks		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopButtonCheck:
	LOAD		R3		[GB+STOPBUF]
	LOAD		R0		[R5+INPUT]
	 XOR		R3		%011111111
	 AND		R3		R0
	STOR		R3		[GB+STOPBUT]
	STOR		R0		[GB+STOPBUF]
	 RTS

ButtonCheck:
	LOAD		R3		[GB+BUTBUF]
	LOAD		R0		[R5+INPUT]
	 XOR		R3		%011111111
	 AND		R3		R0
	STOR		R3		[GB+CURBUT]
	STOR		R0		[GB+BUTBUF]
	 RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interupt Subs	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Abort and Pause Check	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AbortCheck:
	LOAD		R1		[R5+INPUT]
	 AND		R1		ABORTB
	 BNE		AbortReturn
	LOAD		R4		1
	STOR		R4		[GB+ABORT]
	  
AbortReturn:
	 RTS

StopCheck:
	 BRS		StopButtonCheck
	LOAD		R1		[GB+STOPBUT]
	 AND		R1		STARTB
	 BNE		StopReturn
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
	LOAD		R1		[GB+STATE]

MotorCheck:
	LOAD		R0		[GB+STEP]
	 CMP		R0		[GB+PWM]
	 BGT		MotorOff
	 BRA		MotorOn
	  
MotorOff:
	LOAD		R2		MOTOROFF
	 BRA		Motor

MotorOn:
	LOAD		R2		[GB+MOTOR]

Motor:
	MULS		R2		%010000
	  OR		R1		R2

Step:
	 MOD		R0		4
	 ADD		R0		1
	STOR		R0		[GB+STEP]
	STOR		R1		[GB+OUTPUT]
	 RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interupt		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TimerISR:
	 BRS		AbortCheck
	 BRS		StopCheck
	 BRS		LightTimerDecrease
	 BRS		Output
	
	LOAD		R0		[GB+DELTA]
	STOR		R0		[R5+TIMER]
	SETI		8
	 RTE
	

@END

@DATA
					; colorDet 168 for black
	 CODE		DS	1	; variable where CODE location is saved
       BUTBUF		DW	0	; the previous button input
       CURBUT		DW	0	;
      STOPBUF		DW	0	; the previous stop button input
      STOPBUT		DW	0	;
	DELTA		DW	10	; value for timer delay
	 STEP		DW	0	; current step, for PWM
	  PWM		DW	40	; max value for PWM
	MOTOR		DS	1	; variable for motor state
	STATE		DS	3	; variable for state ColorLight:ProxLight1:ProxLight2
       PAUSED		DW	1	;
        ABORT		DW	0	;


@CODE

	IO_AREA		EQU	-16	; base address of the I/O-Area
	TIMER		EQU	13	; timer register
	OUTPUT		EQU	11	; the 8 outputs
	LEDS		EQU	10	; the 3 LEDs above the 3 slide switches
	DSPDIG		EQU	9	; register selecting the active display element
	DSPSEG		EQU	8	; register for the pattern on the active display element
	INPUT		EQU	7	; the 8 inputs
	ADCONVS		EQU	6	; the outputs, concatenated, of the 2 A/D-converters
	
	; Button and Detector values
	START		EQU	%00000001	; location of the Start/Stop button
	ABORT		EQU	%00000010	; location of the Abort button
	   S1		EQU	%00001000	; location of S1
	   S2		EQU	%00010000	; location of S2
	PROX1		EQU	%00100000	; location of PROX1
	PROX2		EQU	%01000000	; location of PROX2
	
      MOTORCW		EQU	%010
     MOTORCCW		EQU	%001
     MOTOROFF		EQU	%000
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interrupt Enable	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableInterrupt:
	STOR		R5		[GB+CODE]
	LOAD		R0		TimerISR		; Store the address of the ISR part in R0
	ADD		R0		R5			; Add datapath to the code
	LOAD		R1		16			; Set R1 := 16
	STOR		R0		[R1]			; Save R0 in the address of R1
	SETI		8					; Enable the interrupt service routine

	LOAD		R5		IO_AREA			; Load the base I/O address
	LOAD		R0		[GB+DELTA]		; Set R0 := DELTA
	SUB		R0		[R5+TIMER]		; R0 := -TIMER
	STOR		R0		[R5+TIMER]		; TIMER := TIMER+R0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Initialization		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Off:
	LOAD		R4		[GB+ABORT]
	 BNE		Abort
	STOR		MOTORCW		[GB+MOTOR]
	
	
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
	STOR		MOTOROFF	[GB+MOTOR]
	 BRS		StopButtonCheck
	LOAD		R1		[GB+STOPBUT]
	 AND		R0		START
	 BNE		IdleFill
	LOAD		R4		0
	STOR		R4		[GB+PAUSED]
	 BEQ		IdleCheck
	 
Idle:
	







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	ButtonChecks		;
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
	STOR		R3		[GB+CURBUF]
	STOR		R0		[GB+BUTBUF]
	 RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Abort and Pause check	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AbortCheck:
	LOAD		R1		[R5+INPUT]
	 AND		R1		ABORT
	 BNE		AbortReturn
	LOAD		R4		1
	STOR		R4		[GB+ABORT]
	  
AbortReturn:
	 RTS

StopCheck:
	 BRS		StopButtonCheck
	LOAD		R1		[GB+STOPBUT]
	 AND		R1		START
	 BNE		StopReturn
	LOAD		R4		1
	STOR		R4		[GB+PAUSED]
	  
StopReturn:
	 RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interupt		;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TimerISR:
	BRS		AbortCheck
	BRS		StopCheck

@END

@DATA

	DELTA		DW	1000	; value for timer delay
	STATE		DS	8	; variable for state

@CODE

	IO_AREA		EQU	-16	; base address of the I/O-Area
	MEMSIZ		EQU	15	; (constant) register holding the size of memory
	TIMER		EQU	13	; timer register
	OUTPUT		EQU	11	; the 8 outputs
	LEDS		EQU	10	; the 3 LEDs above the 3 slide switches
	DSPDIG		EQU	9	; register selecting the active display element
	DSPSEG		EQU	8	; register for the pattern on the active display element
	INPUT		EQU	7	; the 8 inputs
	ADCONVS		EQU	6	; the outputs, concatenated, of the 2 A/D-converters
	RXDATA		EQU	5	; (input) register holding the last character received
	RXSTAT		EQU	4	; status of the serial receiver
	TXDATA		EQU	3	; (output) register for the character to be sent
	TXSTAT		EQU	2	; status of the serial sender
	BDSEL		EQU	1	; (output) register for the baud rate
	SWITCH		EQU	0	; the 3 slide switches

;
;	Timer Interrupt
;

EnableInterrupt:
	LOAD		R0		TimerISR		; Store the address of the ISR part in R0
	ADD		R0		R5			; Add datapath to the code
	LOAD		R1		16			; Set R1 := 16
	STOR		R0		[R1]			; Save R0 in the address of R1
	SETI		8					; Enable the interrupt service routine

	LOAD		R5		IO_AREA			; Load the base I/O address
	LOAD		R0		[GB+DELTA]		; Set R0 := DELTA
	SUB		R0		[R5+TIMER]		; R0 := -TIMER
	STOR		R0		[R5+TIMER]		; TIMER := TIMER+R0

;
;	Initialization:
;

SensorTest:
	LOAD		R0		%00000000		; Give initial value for that state
	STOR		R0		[GB+STATE]		; STATE := 0

MainLoop:
	LOAD		R0		[GB+STATE]		; Set all to be off
	STOR		R0		[R5+OUTPUT]		; And set

	LOAD		R0		[R5+ADCONVS]		; R0 :=  AD1 ++ AD0
	DVMD		R0		256			; R0,R1 := AD1,AD0

	CMP		R1		100			; If R1 < 100
	BCS		SmallSet				; Go to SmallSet

	LOAD		R0		%010			; Set on
	STOR		R0		[R5+LEDS]		; And store it
	BRA		MainLoop				; Return to mainloop

SmallSet:
	LOAD		R0		%001			; Set the first one to be on
	STOR		R0		[R5+LEDS]		; And store it
	BRA		MainLoop				; Return

TimerISR:
	LOAD		R0		[GB+STATE]		; Get the current state
	XOR		R0		%11111111		; Invert the state
	STOR		R0		[GB+STATE]		; And store it again

	LOAD		R0		[GB+DELTA]		; Set the DELTA value to R0
	STOR		R0		[R5+TIMER]		; Store it in the timer
	SETI		8					; Enable the interrupt
	RTE							; Return from exception

@END

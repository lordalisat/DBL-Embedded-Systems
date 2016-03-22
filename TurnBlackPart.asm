TurnBlack:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the data from the buttons
	LOAD		R2		MOTORCW			; Load the CW value
	STOR		R2		[GB+MOTOR]		; Make the motor rotate CW

	LOAD		R1		[GB+CURBUT]		; Load buttons
	 AND		R1		S2			; If S2 is high something is wrong
	 BEQ		Abort					; Abort!
	LOAD		R1		[GB+CURBUT]		; Load buttons
	 AND		R1		S1			; See if S1 is high
	 BEQ		TurnBlack				; While it is, keep turning

; The button checking up here isn't required!

; Force abort whenever ProxB or S1 will be high when we haven't had S2 yet

; If ProxB is hit before S2 Abort

TurnBlack1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the data from the buttons
	LOAD		R1		[GB+CURBUT]		; Load buttons
	 AND		R1		S1			; If S1 is high something is wrong
	 BEQ		Abort					; Abort!
	LOAD		R1		[GB+CURBUT]		; Load buttons
	 AND		R1		S2			; Check if S2 is high
	 BNE		TurnBlack1				; If not, cntinue turning and checking

TurnBlack2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	LOAD		R1		[R5+INPUT]		; Get the input values
	 AND		R1		PROXB			; See if PROXB is high
	 BEQ		TurnBlack2				; While it is high, keep looping


TurnBlack:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	
	LOAD		R2		MOTORCW			; Load the CW value
	STOR		R2		[GB+MOTOR]		; Make the motor rotate CW
	
	LOAD		R0		ON			; Load the on variable
	STOR		R0		[GB+STATE+LPROXB]	; Set the PROXB light to be ON
	
TurnBlack1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	
	LOAD		R0		[GB+CURBUT]		; Get the input values
	 AND		R0		PROXB			; See if PROXB is high
	 BEQ		Abort					; If it is, abort
	
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BEQ		Abort					; If it is, abort
	
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		TurnBlack1				; While it isn't, keep turning
	
TurnBlack2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BEQ		Abort					; If it is, abort
	
	LOAD		R0		[GB+CURBUT]		; Get the input values
	 AND		R0		PROXB			; See if PROXB is high
	 BNE		TurnBlack2				; While it isn't high, keep checking
	 BRA		IdleCheck				; Return to the idle check where everything is disabled











TurnWhite:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	
	LOAD		R2		MOTORCCW		; Load the CCW value
	STOR		R2		[GB+MOTOR]		; Make the motor rotate CCW
	
	LOAD		R0		ON			; Load the on variable
	STOR		R0		[GB+STATE+LPROXW]	; Set the PROXW light to be ON
	
TurnWhite1:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	
	LOAD		R0		[GB+CURBUT]		; Get the input values
	 AND		R0		PROXW			; See if PROXW is high
	 BEQ		Abort					; If it is, abort
	
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BEQ		Abort					; If it is, abort
	
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S2			; Check if S2 is high
	 BNE		TurnWhite1				; While it isn't, keep turning
	
TurnWhite2:
	LOAD		R4		[GB+ABORT]		; Get the abort state
	 BNE		Abort					; Branch if we aborted
	 BRS		ButtonCheck				; Get the button state
	
	LOAD		R1		[GB+CURBUT]		; Load the values
	 AND		R1		S1			; Check if S1 is high
	 BEQ		Abort					; If it is, abort
	
	LOAD		R0		[GB+CURBUT]		; Get the input values
	 AND		R0		PROXW			; See if PROXW is high
	 BNE		TurnWhite2				; While it isn't high, keep checking
	 BRA		IdleCheck				; Return to the idle check where everything is disabled
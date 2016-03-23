@DATA
     BUT_BUF DS 1						;
       DELTA DW 1						;
	   LED_n DW 49,49,49,49,49,49,49	;
        STEP DS 1						;

@CODE 


		
    IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
      LEDS      EQU   10  ;  relative position of the leds
    OUTPUT		EQU   11  ;  relative position of the power outputs
     TIMER      EQU   13  ;  relative position of the timer
     INPUT      EQU    7  ;  position of the input buttons
   ADCONVS      EQU    6  ;  position of the AD-converter


interrupt:
	LOAD R0 TMR_ISR
	 ADD R0 R5
	LOAD R1 16
	STOR R0 [R1]
	SETI 8
	
init:
	LOAD R5 IOAREA          ; R5 := "address of IOAREA"
	LOAD R0 0				; R0 := 0 
	STOR R0 [R5+OUTPUT]		; OUTPUT := R1 = 0

	LOAD R0 [GB+DELTA]
	 SUB R0 [R5+TIMER]		; R0 := -TIMER
	STOR R0 [R5+TIMER]		; TIMER := TIMER+R0

loop: 	
	 BRA loop				; loop until timer interupt


; Checking of the buttons

button_sub:
							; Check which buttons have been newly pressed
	LOAD R3 [GB+BUT_BUF]	; load the buttons pressed last tick
	LOAD R0 [R5+INPUT]		; load the buttons pressed at this tick
	 XOR R3 %011111111		; invert the last buttons to get ones only at the buttons not pressed last tick
	 AND R3 R0				; and to get only the buttons newly pressed
	STOR R0 [GB+BUT_BUF]	; store the buttons pressed this tick for next tick
	

	LOAD R4 0			
	LOAD R2 2			
	
but_check:
	LOAD R0 R3				; load the new buttons
	 AND R0 R2				; check if the 2^R4th button is pressed
	 BEQ next_but			; if not, go to the next button	
	LOAD R1 [GB+BUT_BUF]	; load the currently pressed buttons, to see if button 0 is pressed
	 MOD R1 2
	 BNE min				; if so, then minus, else plus
	 
plus:
	LOAD R1 R4
	 ADD R1 LED_n
	LOAD R0 [GB+R1]			; load the n-value of the R4th button
	 CMP R0 99				; compare it to 99
	 BGE next_but			; if it's greater than 99, then skip to the next button
	 ADD R0 10				; else, add 10 to n
	STOR R0 [GB+R1]			; save the n-value
	 BRA next_but
	
	 
min:
	LOAD R1 R4
	 ADD R1 LED_n
	LOAD R0 [GB+R1]			; load the n-value of the R4th button
	 CMP R0 0				; compare it to 0
	 BLE next_but			; if it's smaller than 0, then skip to the next button
	 SUB R0 10				; else, substract 10 from n
	STOR R0 [GB+R1]			; save the n-value
	 BRA next_but

next_but:
	MULS R2 2				; multiply r2 with 2 to get the next bit in the button buffer
	 ADD R4 1				; go to the next led-value
	 CMP R4 7				; if not all buttons have been tested
	 BNE but_check			; check the next button

	 RTS

; Setting the LED's

light_sub:	 
	LOAD R4 0				; check from the first led
	LOAD R2 2				; set R2 to 2
	LOAD R3 0				; set the initial output to 0

led_check:
	LOAD R1 R4
	 ADD R1 LED_n
	LOAD R0 [GB+R1]			; check the n-value of he R4th led
	 CMP R0 [GB+STEP]		; compare it to step
	 BLT next_led			; if it's greater than step, then go to the next led
	 ADD R3 R2				; else, add the bit value of the R4th led to the output
	
next_led:
	MULS R2 2				; multiply r2 by 2 to get the bit-value of the next led
	 ADD R4 1				; go to the next led
	 CMP R4 7				; if not all leds have been checked
	 BNE led_check			; check the next led

	
; The first led, LED0, controlled by the AD converter.
zero:
	LOAD R1 [GB+ADCONVS]
	MULS R1 20
	 DIV R1 51				; Calculate intensity by converting from 0-255 to 0-100
	 CMP R1 [GB+STEP]		; Compare intensity to step
	 BLT led_output			; if intensity is greater, then skip to the output
	 ADD R3 1				; else, add 1 to the output

led_output:
	STOR R3 [R5+OUTPUT]		; store the output to output
	 RTS		 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Timer Interrupt Enable	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TMR_ISR:
	
	BRS button_sub
	BRS light_sub
	
	LOAD R0 [GB+STEP]
	 MOD R0 100
	 ADD R0 1
	STOR R0 [GB+STEP]
	
	LOAD R0 [GB+DELTA]
	STOR R0 [R5+TIMER]
	SETI 8
	RTE
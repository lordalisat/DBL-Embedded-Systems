@DATA
		BUF	DS  1
		ALT	DS  1

@CODE
		IOAREA     EQU  -16  ;  address of the I/O-Area, modulo 2^18
		INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
		OUTPUT	   EQU   11  ;  relative position of the power outputs
   		TIMER      EQU   13  ; RELATIVE ADRESS OF TIMER
   		LEDS	   EQU   10

begin : 		LOAD  R0  timer_ir		;STORE  TIMER_IR LOCATION IN EXEPTION DESCRIPTOR
			 ADD  R0  R5			;R5 CONTAINS STARTING VALUE RAM PROGRAM
			LOAD  R1  16
			STOR  R0  [R1]			
			
main :			LOAD  R5  IOAREA		;init
			LOAD  R0  0			;RESET TIMER TO 0
			 SUB  R0  [R5+TIMER]
			STOR  R0  [R5+TIMER]
			SETI  8				; ENABLE INTERRUPT 8, TIMER
			
loop : 			LOAD  R0  [R5+INPUT]		;COPY BUTTONS TO GLOABAL VARIABLE BUF
			STOR  R0  [GB+BUF]
			 BRA  loop			;LOOP
   	
  
timer_ir : 		LOAD  R0  1000			;ADD DELTA TO TIMER
  			STOR  R0  [R5+TIMER]
  			LOAD  R0  [GB+BUF]		;LOAD  GLOBAL VARIABLE BUF
  			STOR  R0  [R5+OUTPUT]		;COPY IT TO THE OUTPUT
  			LOAD  R0  [GB+ALT]		;FLICKER LEDS
  			MULS  R0  7
  			STOR  R0  [R5+LEDS]
  			 AND  R0  %01
  			 XOR  R0  %01
  			STOR  R0  [GB+ALT]
  			SETI  8
  			 RTE

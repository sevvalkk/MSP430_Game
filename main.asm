;;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

RESET:
	bic.b #00110000b, &P2IFG ; clear IF for next interrupt for p2.4 and p2.5
	bic.b #00001000b, &P1IFG ; clear IF for next interrupt for p1.3
	mov.w #__STACK_END,SP ; Initialize stackpointer
	mov.w #0x5A80,&WDTCTL ; Stop watchdog timer
	bic.b #10001000b, &P2OUT ; Turn all the lights off

	bic.b #10111110b, &P1SEL ; make P1.1, 2, 3, 4, 5, and 7 Digital I/O
	bic.b #10111110b, &P1SEL2 ; make P1.1, 2, 3, 4, 5, and 7 Digital I/O
	bic.b #00000101b, &P2SEL ; make P2.0 and 2 Digital I/O
	bic.b #00000101b, &P2SEL2 ; make P2.0 and 2 Digital I/O
	bis.b #10110110b, &P1DIR ; make P1.1, 2, 4, 5, and 7 output
	bis.b #00000101b, &P2DIR ; make P2.0 and 2 output

	bic.b #00001000b, &P1DIR ; make P1.3 input
	bis.b #BIT3, &P1REN ; enable pull-up resistor for P1.3
	bis.b #BIT3, &P1OUT ; enable pull-up resistor for P1.3

	bis.w #GIE, SR ; enable interrupts
	bis.b #00001000b, &P1IES ; p1.3 interrupt from H to L
	bis.b #00001000b, &P1IE ; enable p1.3 interrupt
	bis.b #00110000b, &P2IES ; p2.4 and p2.5 interrupts from H to L
	bis.b #00110000b, &P2IE ; enable p2.4 and p2.5 interrupt

;make p2.4 and p2.5 digital I/O (buttons) p2.3 and p2.7 digital I/O (lights)
	bic.b #10111000b, &P2SEL
	bic.b #10111000b, &P2SEL2
;enable pull-up resistor for the button and pull-down resistor for the light
	bic.b #10111000b, &P2DIR
	bis.b #10111000b, &P2REN
	bis.b #00110000b, &P2OUT
	bic.b #10001000b, &P2OUT

	bis.b #10110110b, &P1OUT ; All segments OFF
	bis.b #00000101b, &P2OUT ; All segments OFF
	mov.w #0,r6

Three:
	bis.b #10110110b, &P1OUT
	bis.b #00000101b, &P2OUT
	bic.b #00110110b, &P1OUT ; Turn on a,b,c,d
	bic.b #00000100b, &P2OUT ; Turn on g
	mov.w #4, r5 ; Approximately 1 second delay
	call #Delay
Two:
	bis.b #10110110b, &P1OUT
	bis.b #00000101b, &P2OUT
	bic.b #10100110b, &P1OUT ; Turn on a,b,d,e
	bic.b #00000100b, &P2OUT ; Turn on g
	mov.w #4, r5 ; Approximately 1 second delay
	call #Delay
One:
	bis.b #10110110b, &P1OUT
	bis.b #00000101b, &P2OUT
	bic.b #00010100b, &P1OUT ; Turn on b,c
	mov.w #4, r5 ; Approximately 1 second delay
	call #Delay
Zero:
	bis.b #10110110b, &P1OUT
	bis.b #00000101b, &P2OUT
	bic.b #10110110b, &P1OUT ; Turn on a,b,c,d,e
	bic.b #00000001b, &P2OUT ; Turn on f
	mov.w #1, r5
	call #Delay
Dash:
	bis.b #10110110b, &P1OUT
	bis.b #00000101b, &P2OUT
	bic.b #00000100b, &P2OUT ; Turn on g
	mov.w #5, r6 ; In order to identify dash
	call #Check
	jmp Dash

Check:
	mov.w #12, r5 ; approximately 3 seconds delay
	call #Delay

	bit.b #00001000b, &P2OUT ; check if the green led on or not
	jne RESET
	bit.b #10000000b, &P2OUT ; check if the yellow led on or not
	jne RESET
	ret

Reset_button: ; Reset Interrupt
	jmp RESET

but_ISR: ; Interrupt
	cmp.w #5, r6
	jne Fail

Success:
	bit.b #00100000b, &P2IN ;read switch at p2.5
	jeq yellow_on ;if p2.5 closed
	bit.b #00010000b, &P2IN ;read switch at p2.4
	jeq green_on ;if p2.4 closed
Fail:
	bit.b #00100000b, &P2IN ;read switch at p2.5
	jeq green_on ;if p2.5 closed
	bit.b #00010000b, &P2IN ;read switch at p2.4
	jeq yellow_on ;if p2.4 closed
green_on:
	bis.b #00001000b, &P2OUT ; Turn on the green led
	jmp Dash
yellow_on:
	bis.b #10000000b, &P2OUT ; Turn on the yellow led
	jmp Dash

Delay:
	mov.w #0xFFFF, r4
Loop:
	sub.w #1, r4
	cmp.w #0, r4
	jne Loop
Out_loop:
	sub.w #1, r5
	cmp.w #0, r5
	jne Delay
	ret

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
			.sect ".int03" ; Port 2 interrupt vector
			.short but_ISR
			.sect ".int02" ; Port 1 interrupt vector
			.short Reset_button
			.sect ".reset" ; MSP430 RESET Vector
			.short RESET ; actually int15
			.end

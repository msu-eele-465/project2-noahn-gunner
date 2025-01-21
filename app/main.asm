;-------------------------------------------------------------------------------
; Include files
            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------

            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer


init:
            ; stop watchdog timer
            mov.w   #WDTPW+WDTHOLD,&WDTCTL

            ; Disable low-power mode
            bic.w   #LOCKLPM5,&PM5CTL0

            bic.b   #BIT6,&P6OUT            ; Clear P6.6 output
            bis.b   #BIT6,&P6DIR            ; P6.6 output
            bic.w   #LOCKLPM5,&PM5CTL0      ; Unlock I/O pins

            bis.w   #TBCLR,&TB0CTL          ; Clear timer
            bis.w   #TBSSEL__SMCLK,&TB0CTL  ; Select SMCLK as timer source
            bis.w   #MC__UP,&TB0CTL         ; UP counting
            bis.w   #ID__4,&TB0CTL          ; Div-by-4
            mov.w   #111,&TB0EX0              ; Divide by 8

            mov.w   #32150,&TB0CCR0
            bis.w   #CCIE,&TB0CCTL0
            bic.w   #CCIFG,&TB0CCTL0
            bis.w   #GIE,SR

main:

            nop 
            jmp main
            nop



;------------------------------------------------------------------------------
;           ISR
;------------------------------------------------------------------------------
ISR_TB0_Overflow:
            xor.b   #BIT6,&P6OUT
            bic.w   #CCIFG,&TB0CCTL0
            reti
            
;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;

            .sect   ".int43"
            .short  ISR_TB0_Overflow
            .end
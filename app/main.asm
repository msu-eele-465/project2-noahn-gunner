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

            ; Port Setup
                ; GPIO for SDA and SCL
            bic.b   #BIT0,&P2OUT            ; Clear P2.0 output
            bis.b   #BIT0,&P2DIR            ; P2.0 output (SDA)
            bis.b   #BIT0,&P2OUT            ; Set P2.0 to HIGH

            bic.b   #BIT2,&P2OUT            ; Clear P2.2 output
            bis.b   #BIT2,&P2DIR            ; P2.2 output (SCL)
            bis.b   #BIT2,&P2OUT            ; Set P2.2 to HIGH

                ; GPIO for LED
            bic.b   #BIT0,&P1OUT            ; Clear P1.0 output
            bis.b   #BIT0,&P1DIR            ; P1.0 output

            bic.b   #BIT6,&P6OUT            ; Clear P6.6 output
            bis.b   #BIT6,&P6DIR            ; P6.6 output
            bic.w   #LOCKLPM5,&PM5CTL0      ; Unlock I/O pins 

            ; Timer Setup

            bis.w   #TBCLR,&TB0CTL          ; Clear timer
            bis.w   #TBSSEL__SMCLK,&TB0CTL  ; Select SMCLK as timer source
            bis.w   #MC__UP,&TB0CTL         ; UP counting
            bis.w   #ID__4,&TB0CTL          ; Div-by-4
            mov.w   #111,&TB0EX0            ; Divide by 8

            mov.w   #32150,&TB0CCR0
            bis.w   #CCIE,&TB0CCTL0
            bic.w   #CCIFG,&TB0CCTL0
            nop
            bis.w   #GIE,SR
            nop

   


main:

            nop 
            xor.b   #BIT0,&P1OUT
            call    #START                  ; Call START subroutine
            mov.b   #01010100b, tx_address  ; Set Address
            call    #i2c_tx_byte            ; Transmit Address
            call    #rx_ACK                 ; Send Ack
            
            mov.b   #48h, tx_address        ; Set Data
            call    #i2c_tx_byte            ; Transmit Data
            call    #rx_ACK                 ; Send Ack
            
            mov.b   #69h, tx_address        ; Set Data
            call    #i2c_tx_byte            ; Transmit Data
            call    #rx_ACK                 ; Send Ack
            
            mov.b   #3Fh, tx_address        ; Set Data
            call    #i2c_tx_byte            ; Transmit Data
            call    #rx_ACK                 ; Send Ack

            call    #STOP                   ; STOP
            jmp     main
            nop

;------------------------------------------------------------------------------
;           Memory Allocation
;------------------------------------------------------------------------------

            .data
            .retain

tx_address: .ubyte  00h                        ; Create variable tx_address
tx_byte:    .ubyte  00h                        ; Create variable tx_byte


;------------------------------------------------------------------------------
;           Subroutines
;------------------------------------------------------------------------------
Delay       mov.w   #2, R14
Inner_loop  dec.w   R14
            jnz     Inner_loop
            ret

START       bic.b   #BIT0,&P2OUT            ; Set SDA to LOW
            call    #Delay                  ; Call delay subroutine
            bic.b   #BIT2,&P2OUT            ; Set SCL to LOW
            ret

STOP        bis.b   #BIT2,&P2OUT            ; Set SCL to HIGH
            call    #Delay                  ; Call delay subroutine
            bis.b   #BIT0,&P2OUT            ; Set SDA to HIGH
            ret

i2c_tx_byte 
            mov.w  #0008h, R13
byte_loop   rlc.b   tx_address
            jlo     tx_bit_0
            jc      tx_bit_1
tx_bit_0
            bic.b   #BIT0,&P2OUT            ; Set SDA to LOW
            call    #Delay
            bis.b   #BIT2,&P2OUT            ; Set SCL to HIGH
            call    #Delay
            bic.b   #BIT2,&P2OUT            ; Set SCL to LOW
            call    #Delay
            jmp     tx_bit_end
tx_bit_1
            bis.b   #BIT0,&P2OUT            ; Set SDA to HIGH
            call    #Delay
            bis.b   #BIT2,&P2OUT            ; Set SCL to HIGH
            call    #Delay
            bic.b   #BIT2,&P2OUT            ; Set SCL to LOW
            call    #Delay
tx_bit_end
            dec.w   R13
            jnz     byte_loop
            ret

tx_ACK
            ;SDA to LOW then pulse SCL
            bic.b   #BIT0,&P2OUT            ; Set SDA to LOW
            call    #Delay
            bis.b   #BIT2,&P2OUT            ; Set SCL to HIGH
            call    #Delay
            bic.b   #BIT2,&P2OUT            ; Set SCL to LOW
            ret

rx_ACK
            ;receive ACK from AD2
            bic.b   #BIT0,&P2DIR            ; P2.0 input (SDA)
            bis.b   #BIT0,&P2REN            ; P2.0 enable resistor
            bis.b   #BIT0,&P2OUT            ; P2.0 pullup resistor
            call    #Delay

            bis.b   #BIT2,&P2OUT            ; Set SCL to HIGH
            call    #Delay
            ; bitmask to read value of 2.0
            mov.b   &P2IN, R12
            inv.b   R12
            and.b   #BIT0, R12
            jz      rx_ACK_LOW
rx_ACK_HIGH
            call    #STOP
            jmp     rx_ACK_END
rx_ACK_LOW
rx_ACK_END
            bic.b   #BIT2,&P2OUT            ; Set SCL to LOW
            call    #Delay
            bic.b   #BIT0,&P2OUT            ; Clear P2.0 output
            bis.b   #BIT0,&P2DIR            ; P2.0 output (SDA)
            bis.b   #BIT0,&P2OUT            ; Set P2.0 to HIGH
            ret




;------------------------------------------------------------------------------
;           ISR
;------------------------------------------------------------------------------
ISR_TB0_Overflow:
            xor.b   #BIT6,&P6OUT
            ;xor.b   #BIT0,&P2OUT
            ;xor.b   #BIT2,&P2OUT
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


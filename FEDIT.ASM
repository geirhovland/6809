                .ORG 9220
                LBRA START
                .equ font,20100
                .equ tekst,21130
                .equ txtend,32400
 
RAD:            .dw 0       ;1 to infinity
KOLONN:         .db 1       ;0-254
SCRPOS:         .db 1       ;On screen, 0-63
VERTIK:         .db 1       ;On screen, 1-23
INVERT:         .db 1       ;0=black on white, FF=white on black
WHERE:          .dw 0       ;Position in text
MAXWHR:         .dw 0       ;Max position
MAXRAD:         .dw 0       ;Number of lines so far
STATE:          .db 1       ;BLINKING
CHAR:           .db 1       ;Keeps key press
INSERT:         .db 1       ;0=on, 1=off
MENYPO:         .db 1       ;Position in menu
RATE:           .dw 0       ;Keyboard repeat rate
FOER:           .dw 0       ;Delay time
BEEP:           .db 1       ;KEYCLICK, 0=on, 1=off
BAUD:           .db 1       ;BAUDRATE, see page 5 in '64 Supplement
BLOKK:          .db 1       ;Marked block, 0=on, 1=off
BLBEGIN:        .dw 0       ;Block start adresse
BLEND:          .dw 0       ;Block end adresse
PRINTER:        .db 0       ;0=Parallell, 1=Serial
TOGGLINE:       .db 0       ;0=on, 1=off. Linefeed toggle
MASKIN:         .db 0       ;0=Dragon 32, 1=Dragon 64
WRAP:           .db 0       ;0=on, 1=off. Wordwrap
WRAPPOS:        .db 0       ;Position where WORDWRAP occurs. Default 70
PRMARGIN:       .db 0       ;Left print margin. Default 10
 
;       GET SETUP
;*************************************************************
;*******************************
;* SETUP ROUTINE. GRAPIHCS SCREEN
;* PLACED AT 3072. RESET
;* PLACED AT COLD-START
;*******************************
SETUP:          clr 115         ;Reset ON
                STA h'FFCB
                STA h'FFC9
                STA h'FFC0
                STA h'FFC3
                STA h'FFC5
                STA h'FF22
                ANDA #h'07
                oraa #h'F8
                STA h'FF22      ;PMODE4,1
                lda 48000
                cmpa #126
                bne D32
                lda #1
                sta MASKIN
                bra D64
D32:            clr MASKIN
D64:            clr printer     ;Parallel printer port
                clr toggline    ;Linefeed on
                LDX #1
                STX RAD
                STX ROW
                STX COL
                STX MAXRAD
                lda #8
                sta BAUD        ;Baud rate 1200
                lbsr SETTBAUD
                lda #63
                sta WRAPPOS     ;Default Wordwrap position
                lda #9
                sta PRMARGIN    ;Left printer margin
                LDA #1
                STA Blokk       ;Block off
                STA Washere     ;Block status (equal to BLOKK)
                clr WRAP        ;Wordwrap on
                ldx #tekst
                stx blbegin     ;Block begin
                stx blend       ;Block end
                STA BEEP        ;Keyclick OFF
                STA VERTIK      ;Top on screen.
                STA INSERT      ;Insert off, but remains on after VISINS
                lda h'60a
                sta h'eb        ;Set correct drive.
                CLR KOLONN
                CLR SCRPOS
                CLR STATE
                CLR INVERT
                CLR MENYPO
                clr TXTLEN      ;Length search string
                clr TXTLEN2     ;Length search string in REPLACE
                clr REPLEN      ;Length replace string
                LDX #43
                STX FOER
                LDX #1
                STX RATE
                LDX #0
                STX REPEAT
                STX COUNT
                LDX #TEKST
                STX WHERE
                STX MAXWHR
                LDA #13        ;EOLN
                STA -2,X
                LDA #10
                STA -1,X
                LDA #13        ;DELETE
                LDX #TEKST     ;BUFFER
SLETTB:         STA ,X+
                CMPX #TXTEND
                BNE SLETTB
                leax 1,x
                sta ,x
MENY:           LBSR CLRSCR
                RTS
;*****************************
;Returns b=0 if WHERE is in block,
;otherwise b=1
VERDI:          .db 1

IBLOKK:         pshs x
                ldb #1
                stb verdi
                ldb blokk
                cmpb #1
                beq IBL2
                ldx blbegin
                cmpx blend
                beq IBL2
                cmpx where
                bhi IBL2
                ldx blend
                cmpx where
                blo IBL2
                clr verdi
IBL2:           puls x
                ldb verdi
                rts
;***************************

;      GET SKRIVA
;**********************************************************************
;* WRITES CHAR IN A TO ROW AND
;* COLUMN, AND INCREASES COLUMN.
;* COLUMN=SCRPOS, ROW=VERTIK
;* INVERT=0  -> BLACK CHARS
;* INVERT=FF -> WHITE CHARS
;*******************************
BOKST:          .db 1
PASS:           .db 1
SKRIVA:         PSHS X,Y,D,U
                LDB KOLONN
                CMPB #h'FF      ;Kolonne 255 ?
                LBEQ OKPOS      ;If yes, end
                ldb invert
                pshs b
                lbsr IBLOKK     ;Check if Block
                cmpb #1
                beq SKRI2
                ldb #255
                stb invert      ;Black on white at block
SKRI2:          LDB #4
                MUL
                ADDD #FONT
                TFR D,X
                LDA SCRPOS
                ANDA #1
                CMPA #1
                BEQ EIN
                LDA #240
                STA ORVERD
                BRA OVER
EIN:            LDA #15
                STA ORVERD
OVER:           LDB VERTIK
                CLRA
                LDY #8
NYSHFT:         LSLB           ;D=D*32*8
                ROLA
                LEAY -1,Y
                CMPY #0
                BNE NYSHFT
                STD POS
                CLRA
                LDB SCRPOS
                LSRB
                ADDD #3072
                ADDD POS
                STD POS
                TFR D,Y
                LDU #4
NYBYTE:         LDA ,X+
                EORA INVERT
                STA BOKST
                CLR PASS
DEL2:           LDB ORVERD
                CMPB #15
                BNE KLAR1
                LSRA
                LSRA
                LSRA
                LSRA
                oraa #240
                BRA KLAR
KLAR1:          oraa #15
KLAR:           LDB ,Y
                orab ORVERD
                STB OGVERD
                ANDA OGVERD
                STA ,Y
                LEAY 32,Y
                LDA PASS
                CMPA #0
                BNE DEL3
                INC PASS
                LDA BOKST
                LSLA
                LSLA
                LSLA
                LSLA
                oraa #15
                BRA DEL2
DEL3:           LEAU -1,U
                CMPU #0
                BNE NYBYTE
                INC KOLONN
                INC SCRPOS
OKPOS:          puls a
                sta invert
                PULS U,D,Y,X
                RTS



;      GET BLINK
;************************************************************************
; Blink the cursor. COUNT increases to VALUE before change is made.
; Otherwise the cursor would blink too fast

                .equ value,2000
COUNT:          .dw 0
BLINK:          PSHS X,Y,D,U
                LDD COUNT
                CMPD #VALUE
                BEQ OKBLI
                LDX COUNT
                LEAX 1,X
                STX COUNT
                BRA NOBLI
 
OKBLI:          LDX #0
                STX COUNT
                LDA KOLONN
                PSHS D
                CMPA #h'FF
                BNE OKBLI2
                DEC SCRPOS
OKBLI2:         CLR KOLONN
                LDA STATE
                CMPA #1
                BEQ SKRSV
                CLRA
                LBSR SKRIVA
                LDA #1
                STA STATE
                BRA SLUT
SKRSV:          LDX WHERE
                LDA ,X
                CMPA #13
                BNE OK13
                LDA #32
OK13:           LBSR SKRIVA
                CLRA
                STA STATE
SLUT:           DEC SCRPOS
                PULS D
                STA KOLONN
                CMPA #h'FF
                BNE NOBLI
                INC SCRPOS
NOBLI:          PULS U,D,Y,X
                RTS
;********************************
;* REMOVE CURSOR FROM SCREEN    *
;********************************
CURAV:          PSHS X,Y,D,U
                LDA STATE
                CMPA #0
                BEQ CUREND
                LDX #VALUE
                STX COUNT
                LBSR BLINK
CUREND:         PULS U,D,Y,X
                RTS
 

;      GET SCRLFRT
;*********************************************************************
; Scroll the screen 32 columns after right arrow key and SCRPOS=63.

SCRRGT:         LBSR CLRSCR
                LDA SCRPOS
                SUBA #32
                STA SCRPOS
                LDA KOLONN
                SUBA SCRPOS
                TFR A,B
                ANDB #1
                CMPB #0        ;PARTAL ?
                BEQ SCRR1
                INCA
                DEC SCRPOS
SCRR1:          LDB #64
                LBSR SKJERM
                RTS
;********************************
; Scroll 32 columns to the left

SCRLFT:         LBSR CLRSCR
                LDA KOLONN
                CMPA #33
                BHI SCR1
                LDA KOLONN
                STA SCRPOS
                CLRA
                BRA SCR3
SCR1:           LDA SCRPOS
                ADDA #32
                STA SCRPOS
                LDA KOLONN
                SUBA SCRPOS
                TFR A,B
                ANDB #1
                CMPB #0        ;PARTAL ?
                BEQ SCR3
                DECA
                INC SCRPOS
SCR3:           LDB #64
                LBSR SKJERM
                RTS


;      GET CLEAR
;*******************************
;* CLEAR SCREEN
;* TO WHITE. NO PARAMETERS
;* The menu line remains
;*******************************
CLRSCR:         PSHS X,D
                LDX #3328
                LDD #h'FFFF
SLETT:          STD ,X++
                CMPX #9216
                BNE SLETT
                PULS D,X
                RTS
;*******************************
;* WINDOW: DRAW WINDOW
;* AT THE TOP OF THE SCREEN
;*******************************
WINDOW:         LDA SCRPOS
                LDB KOLONN
                PSHS D
                LDA VERTIK
                PSHS D
 
                CLR KOLONN
                LDA #15
                STA SCRPOS
                LDA #6
                STA VERTIK
                LDA #218
                LBSR SKRIVA
                LDA #196
                LDB #30
WIN4:           LBSR SKRIVA
                DECB
                BNE WIN4
                LDA #191
                LBSR SKRIVA    ;TOP
 
                LDU #10
WIN6:           LDA #179
                INC VERTIK
                CLR KOLONN
                LDB #15
                STB SCRPOS
                LBSR SKRIVA
                LDA #32
                LDB #30
WIN5:           LBSR SKRIVA
                DECB
                BNE WIN5
                LDA #179
                LBSR SKRIVA
                LEAU -1,U
                CMPU #0
                BNE WIN6       ;SIDE
 
                LDA #15
                STA SCRPOS
                INC VERTIK
                LDA #192
                LBSR SKRIVA
                LDB #30
                LDA #196
WIN7:           LBSR SKRIVA
                DECB
                BNE WIN7
                LDA #217
                LBSR SKRIVA
 
                PULS D
                STA VERTIK
                PULS D
                STA SCRPOS
                STB KOLONN
                RTS
;******************************
; Copyright notice. No parameters

VERS1:          .db "FEdit v1.01",13
VERS2:          .db "Programmed by",13
VERS3:          .db "Geir Edvin Hovland"
                .db 13
VERS4:          .db "Legdavegen",13
VERS5:          .db "6943 Naustdal",13
VERS6:          .db "Norway",13
VERS7:          .db "To enter/leave the"
                .db " menus,",13
VERS8:          .db "use the break key!"
                .db 13
 
WELCM:          LDA SCRPOS
                LDB SCRPOS
                PSHS D
                LDA VERTIK
                PSHS D
 
                CLR KOLONN
                LDU #VERS1
                LDA #7
                STA VERTIK
                LDA #25
                STA SCRPOS
                LBSR WRITE
 
                LDA #9
                STA VERTIK
                LDU #VERS2
                LDA #24
                STA SCRPOS
                LBSR WRITE
 
                INC VERTIK
                LDU #VERS3
                LDA #22
                STA SCRPOS
                LBSR WRITE
 
                CLR KOLONN
                INC VERTIK
                LDU #VERS4
                LDA #25
                STA SCRPOS
                LBSR WRITE
 
                INC VERTIK
                LDU #VERS5
                LDA #24
                STA SCRPOS
                LBSR WRITE
 
                INC VERTIK
                LDU #VERS6
                LDA #28
                STA SCRPOS
                LBSR WRITE
 
                INC VERTIK
                INC VERTIK
                LDU #VERS7
                LDA #18
                STA SCRPOS
                LBSR WRITE
 
                INC VERTIK
                LDU #VERS8
                LDA #22
                STA SCRPOS
                LBSR WRITE
 
                PULS D
                STA VERTIK
                PULS D
                STA SCRPOS
                STB KOLONN
                CLR h'FF48      ;DISK AV
                RTS
;********************************
;* LINE. DRAWS BLACK LINE FROM  *
;* X T X+32.                    *
;********************************
LINE:           PSHS X,D
                LDA #0
                LDB #32
NYDEL:          STA ,X+
                DECB
                CMPB #0
                BNE NYDEL
                PULS D,X
                RTS


;      GET FILBEH
;*****************************************************************
;* STORES NORMAL TEXT FILES
;* X -> START. Y -> END
;* Ask for filename
;*******************************
FBEGIN:         .dw 0
FSLUTT:         .dw 0
FIB:            .db 1
FLEN:           .db 1
FNAME:          .db 0,0,0,0,0,0,0,0
FEXT:           .db 0,0,0
 
SAVE:           STX FBEGIN
                STY FSLUTT
                lda ,y
                cmpa #13
                bne SAVE2
                leay -1,y
                sty FSLUTT
SAVE2:          LBSR NAMN      ;GIVE NAME
                CMPA #3        ;BREAK
                BEQ SAVEND
                LDB FLEN       ;FILE LENGTH
                LDX #FNAME
                LDY #FEXT
                JSR [h'C008]    ;PARSE
                JSR [h'C00A]    ;SEARCH
                STA FIB
                JSR [h'C00C]    ;CREATE
                LDD FSLUTT
                SUBD FBEGIN
                addd #1
                TFR D,U        ;NUMBER OF BYTES
                LDA FIB
                LDX FBEGIN
                LDY #0
                CLRB
                JSR [h'C016]    ;WRITE
                JSR [h'C010]    ;CLOSE ALL
SAVEND:         LBRA VALSLT
;********************************
;* ASK FOR NAME. RETUNER WITH   *
;* A=3 FOR BREAK, A=13 FOR NAME *
;* IN FNAME.FEXT.               *
;********************************
FMELD:          .db "Enter filename!",13
FMELD2:         .db "Press break to "
                .db "cancel.",13
NAMM:           .db "Name:",13
EXTT:           .db "Ext :",13
 
NAMN:           LBSR WINDOW
                CLR KOLONN
                LDA #23
                STA SCRPOS
                LDA #8
                STA VERTIK
                LDU #FMELD
                LBSR WRITE
                INC VERTIK
                LDU #FMELD2
                LDA #20
                STA SCRPOS
                LBSR WRITE
                LDA #12
                STA VERTIK
                LDU #NAMM
                LDA #24
                STA SCRPOS
                LBSR WRITE
                INC VERTIK
                LDU #EXTT
                LBSR WRITE
 
                LDA #29
                STA SCRPOS
                LDA #12
                STA VERTIK
 
                CLR FLEN
                LDX #FNAME
                LDA #8
                clrb            ;Only capital letters
                LBSR INPUT
                CMPA #3
                LBEQ NAMEND
                STB FLEN
                INC VERTIK
                LDX #FEXT
                LDA #3
                clrb            ;Only capital letters
                LBSR INPUT
NAMEND:         RTS
;*******************************
;* INPUT LINE.
;* CALL WITH X-> STRING. A=MAX LEN
;* B=0 -> Only capital letters
;* B=1 -> All 255 characters
;* SCRPOS,VERTIK CORRECT.
;* RETURNS WITH A=Last KEY,
;* B=NUMBER OF CHARS WHICH X POINTS AT
;********************************
LENMAX:         .db 1
LEN:            .db 1
INCHAR:         .db 1
CHAR32:         .db 1
STORESMA:       .db 0
 
INPUT:          stb STORESMA
                STA LENMAX
                CLR LEN
                LDA SCRPOS
                LDB KOLONN
                PSHS D
 
                LDA #32         ;to make the cursor blink black/white
                STA CHAR32
                LDY WHERE
                PSHS Y
                LDY #CHAR32
                STY WHERE
 
FWAIT:          JSR h'8006
                LBSR BLINK
                CMPA #0
                BEQ FWAIT
                STA INCHAR
                cmpa #12
                bne FW3
                lbsr CLRINPUT   ;Clear pressed key
                sta inchar
FW3:            CMPA #8
                LBEQ FDEL
                CMPA #3
                LBEQ INPEND
                CMPA #13
                BNE FW1
                LDB LEN
                CMPB #0
                BEQ FWAIT
                LBSR CURAV
                LBRA INPEND
FW1:            LDB LEN
                CMPB LENMAX
                LBEQ FWAIT
                ldb STORESMA
                cmpb #0
                bne FW2
                CMPA #97
                BLO FW2
                SUBA #32
FW2:            STA ,X+
                INC LEN
                PSHS X
                LBSR SKRIVA
                PULS X
                LBRA FWAIT
FDEL:           LDA LEN
                CMPA #0
                LBEQ FWAIT
                PSHS X
                LBSR CURAV
                PULS X
                LEAX -1,X
                DEC SCRPOS
                LDA #32
                LBSR SKRIVA
                CLR KOLONN
                DEC SCRPOS
                DEC LEN
                LBRA FWAIT
 
INPEND:         PULS Y
                STY WHERE
                PULS D
                STA SCRPOS
                STB KOLONN
                LDA INCHAR
                LDB LEN
                RTS
;********************************
CLRINPUT:       ldb STORESMA
                cmpb #0
                lbeq CLRINP2
CLR3:           LDB #100
                STB MULT
                CLR CODE
CNTRL1:         JSR h'8006
                BEQ CNTRL1
                SUBA #48
                LDB MULT
                MUL
                ADDB CODE
                STB CODE
                LDB MULT
                CMPB #1
                BEQ CLRINP1
                CMPB #100
                BNE MI2
                LDB #10
                STB MULT
                BRA CNTRL1
MI2:            LDB #1
                STB MULT
                BRA CNTRL1
CLRINP1:        lda code
CLRINP2:        rts
;********************************
; Load normal files. Gives the user
; a file selector.

TELLAR:         .dw 0
LENGDE:         .db 0,0,0
LOAD:           LBSR GETNAM     ;File selector
                CMPA #3
                LBEQ VALSLT
 
                LDX #TEKST      ;Clear buffer
                LDA #13
LOAD1:          STA ,X+
                CMPX #TXTEND
                BNE LOAD1
 
                LDX #TEKST
                STX WHERE
                LDX #1
                STX RAD
                STX MAXRAD
                CLR VERTIK
                CLR KOLONN
                LDA #1
                STA VERTIK
 
                LDX #FNAME
                LDB FLEN
                LDY #FEXT
                JSR [h'C008]    ;PARSE
                JSR [h'C00A]    ;SEARCH
                STA FIB
                JSR [h'C00E]
                LDX #LENGDE
                LEAX 2,X
                STA ,X
                STU LENGDE
                LDX #LENGDE
                LEAX 1,X
                LDD ,X
                TFR D,Y        ;LENGTH
                ADDD #TEKST
                SUBD #1
                STD MAXWHR
                STD TELLAR
                LDA FIB
                LDX #TEKST
                LDU #0
                CLRB
                JSR [h'C014]    ;READ
                JSR [h'C010]    ;CLOSE
                LDX #TEKST
LOAD3:          LDA ,X+
                CMPA #13
                BNE LOAD2
                LDY MAXRAD
                LEAY 1,Y
                STY MAXRAD
LOAD2:          CMPX TELLAR
                BNE LOAD3
                LDX MAXWHR
                LDA ,X
                CMPA #10
                BNE LOAD5
                LEAX 1,X
                STX MAXWHR
LOAD5:          lda #1
                sta washere     ;Block off
                ldx #tekst
                stx where
                clr BLOKKSCR
                clr BLOKKKOL
                lda #1
                sta BLOKKVER
                ldx #1
                stx rad
                stx row
                stx col
SJEKKC13:       ldx MAXWHR
                lda ,x
                cmpa #13
                lbeq VALSLT     ;If last char<>Chr(13), incr MAXWHR
                leax 1,x
                stx MAXWHR
                LBRA VALSLT
;*******************************
LOADBLOK:       lbsr getnam     ;File selector
                cmpa #3
                lbeq VALSLT
                LDX #FNAME      ;Filename
                LDB FLEN        ;Number of chars in filename
                LDY #FEXT       ;File extension
                JSR [h'C008]    ;PARSE filnavn
                JSR [h'C00A]    ;SEARCH. Lager FIB.
                STA FIB         ;Keep FIB for later use
                JSR [h'C00E]    ;Finn fil-lengde.
                LDX #LENGDE     ;Length = U+A
                LEAX 2,X        ; |
                STA ,X          ; |
                STU LENGDE      ; |
                LDX #LENGDE     ; -
                LEAX 1,X
                LDD ,X
                addd maxwhr
                cmpd #txtend    ;Check if buffer is full.
                blo LODBLOK1    ;Nei, continue
                lbsr FULLT      ;Buffer full.
                jsr [h'C010]    ;Close all files
                lbra VALSLT     ;End operation
LODBLOK1:       ldd ,x          ;Read length again
                TFR D,Y         ;Transfer to Y because of READ-function
                tfr y,u         ;U er a parameter of SKUBB. U=Number of chars
                pshs y,d
                lbsr SKUBB      ;Make space
                puls d,y
                addd WHERE      ;Store Block end for use with OPPDATER
                subd #1
                std BLOKKSL     ;Block end
                LDA FIB         ;Read FIB to READ and CLOSE.
                LDX WHERE       ;Position of new block
                stx BLOKKST     ;Block start.
                LDU #0          ;File sector # = 0
                CLRB            ;Byte # within sector = 0
                JSR [h'C014]    ;READ
                JSR [h'C010]    ;CLOSE
                LBSR Oppdater   ;Update MAXRAD and MAXWHR
                clr washere     ;Blokk on
                LBRA SJEKKC13
;*******************************
; File selector used in among others LOAD TEXT

NESTE:          .db "More Files ...",13
ENTRY:          .db 1
SIDE:           .db 1
DIREND:         .db 1
                .equ buftyp,1024
BUFF:           .dw 0
GETNAM:         CLR ENTRY
                CLR DIREND
GET4:           CLR SIDE
                LDY #BUFTYP
                STY BUFF
                LBSR WINDOW
                LDA #17
                STA SCRPOS
                LDU #NESTE
                LDA #16
                STA VERTIK
                LBSR WRITE
                LDA #7
                STA VERTIK
                CLR KOLONN
                LDA #32
                LDX #BUFTYP
GET11:          STA ,X+
                CMPX #1154
                BNE GET11
GET2:           LDB ENTRY
                JSR [h'C020]    ;GETDIR
                LDA ,X+
                CMPA #137
                BNE GET7
                LDB #1
                STB DIREND
                LBRA OKVELG
GET7:           CMPA #129
                BNE GET3
                INC ENTRY
                BRA GET2
GET3:           INC ENTRY
                INC SIDE
                LDB #8
                LDY BUFF
GET5:           LDA ,X+
                CMPA #32
                BHS GET9
                LDA #32
                BRA GET10
GET9:           CMPA #91
                BLO GET10
                LDA #32
GET10:          STA ,Y+
                DECB
                BNE GET5
                LDA #46        ;.
                STA ,Y+
                LDB #3
GET6:           LDA ,X+
                STA ,Y+
                DECB
                BNE GET6
                LDA #13
                STA ,Y+
                STY BUFF
                LEAU -13,Y
                LBSR WRITE
                INC VERTIK
                LDA SIDE
                CMPA #9
                BEQ OKVELG
                LBRA GET2
OKVELG:         LDA #10
                LDB #1
                STB MENYNR
                LDB #15
                LDX #4872
                LBSR CHOOSE
                CMPA #10
                LBEQ MOREF
                DECA
                LDB #13
                MUL
                ADDD #BUFTYP
                TFR D,Y
                LDA ,Y
                CMPA #32
                BEQ MOREF2
 
                CLR FLEN
                LDX #FNAME
GET13:          LDA ,Y+
                STA ,X+
                INC FLEN
                CMPA #32
                BEQ GET12
                LDA FLEN
                CMPA #8
                BEQ GET12
                BRA GET13
GET12:          LDA ,Y+
                CMPA #46
                BNE GET12
                LDX #FEXT
                LDB #3
GET14:          LDA ,Y+
                STA ,X+
                DECB
                BNE GET14
                CLRA
                RTS
 
MOREF:          LDA DIREND
                CMPA #1
                LBNE GET4
MOREF2:         LDA #3
                RTS


;      GET MENUBAR
;*************************************************************
; Write menu line at the top of the screen

TITTEL:         .db " Line:      Column:"
                .db "     Insert:"
                .db 13
ROW:            .db h'00,h'01
COL:            .db h'00,h'01
I:              .db h'00,h'01
DECREASE:       .db h'99,h'99
 
BAR:            PSHS X,Y,D,U
                LDA #h'FF
                STA INVERT
                LDU #TITTEL
                LDA VERTIK
                PSHS D
                LDA KOLONN
                LDB SCRPOS
                PSHS D
                CLR VERTIK
                CLR SCRPOS
                CLR KOLONN
                LBSR WRITE
                LDA #31
                STA SCRPOS
                LDB #33
                LDA #32
NOTEND:         LBSR SKRIVA
                DECB
                BNE NOTEND
                PULS D
                STA KOLONN
                STB SCRPOS
                PULS D
                STA VERTIK
                LBSR VISNY
                PULS U,D,Y,X
                CLR INVERT
                RTS
;*******************************
; CHOICE. MENU. NO PARAMETERS

LINJE:          .db " File   Edit    "
                .db "Keys    Comms   "
                .db "Print   Other    "
                .db "              "
                .db 13
MEN1:           .db "  Load Text"
                .db 13
                .db "  Save Text"
                .db 13
                .db "  Load Block"
                .db 13
                .db "  Save Block"
                .db 13
                .db "  Status Info"
                .db 13
                .db "  Quit"
                .db 13,36
MEN2:           .db "  Delete Line"
                .db 13
                .db "  Block Begin"
                .db 13
                .db "  Block End"
                .db 13
                .db "  Move Block"
                .db 13
                .db "  Copy Block"
                .db 13
                .db "  Delete Block"
                .db 13,36
MEN3:           .db "  Repeat Rate"
                .db 13
                .db "  Delay Time"
                .db 13
                .db "  Key Click"
                .db 13,36
MEN4:           .db "  Baud Rate"
                .db 13
                .db "  Download Text"
                .db 13
                .db "  Upload Text"
                .db 13,36
MEN5:           .db "  Print All"
                .db 13
                .db "  Print Block"
                .db 13
                .db "  Linefeed Toggle"
                .db 13
                .db "  Choose Printer"
                .db 13
                .db "  Printer Margin"
                .db 13,36
MEN6:           .db "  Search"
                .db 13
                .db "  Repeat Search"
                .db 13
                .db "  Replace"
                .db 13
                .db "  Repeat Replace"
                .db 13
                .db "  Wordwrap"
                .db 13
                .db "  Reformat Block"
                .db 13,36

                .equ antmen,6
                .equ max1,5     ;NUMBER-1
                .equ max2,5
                .equ max3,2
                .equ max4,2
                .equ max5,4
                .equ max6,5
MENYNR:         .db 0
BLOKKVER:       .db 0
BLOKKSCR:       .db 0
BLOKKKOL:       .db 0
BLOKKINS:       .db 0

TOPPCL:         LDA #h'FF
                LDX #3328
TOPP2:          STA ,X+
                CMPX #5120 ;3328+7*256
                BNE TOPP2
                RTS

; Menu starts here.
VALG:           BSR TOPPCL
                CLR MENYNR
                lda insert
                sta BLOKKINS
                LDA SCRPOS
                sta Blokkscr    ;to be able to modify SCRPOS
                LDB KOLONN
                stb BlokkKOL
                LDA VERTIK
                sta blokkver    ;to be ablt to modify VERTIK
                lda #1
                sta blokk       ;to avoid black menus
                CLR VERTIK
                CLR SCRPOS
                CLR KOLONN
                LDU #LINJE
                LDA #h'FF
                STA INVERT
                LBSR WRITE
                CLR INVERT
                LBSR GARDIN
                LDA #0
                LBSR TOGGLE
MENVNT:         JSR h'8006
                BEQ MENVNT
                LDB BEEP
                CMPB #1
                BEQ MENCON
                LBSR CLICK
MENCON:         CMPA #3
                BEQ VALSLT
                CMPA #9
                BEQ MENRGT
                CMPA #8
                BEQ MENLFT
                CMPA #10
                LBEQ MENNED
                CMPA #94
                LBEQ MENOPP
                CMPA #13
                LBEQ UTFOER
                BRA MENVNT
 
VALSLT:         lda washere
                sta blokk       ;block status
                lda blokkver
                STA VERTIK
                lda blokkscr
                sta scrpos
                ldb BLOKKKOL
                STB KOLONN
                lda BLOKKINS
                sta Insert
                lda #0
                lbsr scadd      ;Increase Row
                lda #1
                lbsr scadd      ;Decrease row: to show change in KOLONN.
                lbsr BAR
                lbsr VISINS
                lbsr VISINS
                LBSR CLRSCR
                LDA KOLONN
                SUBA SCRPOS
                LDB #64
                LBSR SKJERM
                LBRA WAIT
;*******************************
; Shift menu position to the right

MENRGT:         LBSR TOPPCL
                LDA MENYPO
                INCA
                CMPA #ANTMEN
                BNE RGTOK
                CLRA
RGTOK:          STA MENYPO
                LBSR GARDIN
                CLR MENYNR
                LDA MENYNR
                LBSR TOGGLE
                LBRA MENVNT
;*******************************
; Shift menu position to the left

MENLFT:         LBSR TOPPCL
                LDA MENYPO
                DECA
                CMPA #h'FF
                BNE LFTOK
                LDA #ANTMEN
                DECA
LFTOK:          STA MENYPO
                LBSR GARDIN
                CLR MENYNR
                LDA MENYNR
                LBSR TOGGLE
                LBRA MENVNT
;*******************************
; Move the cursor one row down

MENNED:         LDA MENYNR
                LBSR TOGGLE
                LBSR FMAX      ;FIND MAX
                CMPB MENYNR
                BNE MENNE2
                CLR MENYNR
                BRA MENNE3
MENNE2:         INC MENYNR
MENNE3:         LDA MENYNR
                LBSR TOGGLE
                LBRA MENVNT
;*******************************
; Move the cursor one row up

MENOPP:         LDA MENYNR
                LBSR TOGGLE
                LBSR FMAX
                LDA MENYNR
                CMPA #0
                BNE MENO1
                STB MENYNR
                BRA MENO2
MENO1:          DEC MENYNR
MENO2:          LDA MENYNR
                LBSR TOGGLE
                LBRA MENVNT
;*******************************
;* FIND MAX ELEMENT IN MENUPOS *
;* RETURNS NUMBER IN B-REG.    *
;*******************************
FMAX:           LDA MENYPO
                CMPA #0
                BNE FM1
                LDB #MAX1
FM1:            CMPA #1
                BNE FM2
                LDB #MAX2
FM2:            CMPA #2
                BNE FM3
                LDB #MAX3
FM3:            CMPA #3
                BNE FM4
                LDB #MAX4
FM4:            CMPA #4
                BNE FM5
                LDB #MAX5
FM5:            CMPA #5
                BNE FM6
                LDB #MAX6
FM6:            RTS
;*******************************
; CALL WITH CORRECT MENUPOS
; Draws the menu box.
;*******************************
VEGGPO:         .db 1    ;POS ON SCRFEEN
VEGTXT:         .dw 0    ;WHERE IS THE TEXT?
ANTVEG:         .db 1    ;NUMBER CHOICE
VEGG:           .db 186,32,32,32,32,32
                .db 32,32,32,32,32,32,32
                .db 32,32
                .db 32,32,32,32,32,186,13
BOTN:           .db 200,205,205,205
                .db 205,205,205,205,205
                .db 205,205,205,205,205
                .db 205,205,205,205,205
                .db 205,188,13

GARDIN:         LDA MENYPO
                LDB #8
                MUL
                STB VEGGPO
                LDA MENYPO
                CMPA #0
                BNE NR2
                LDX #MEN1
NR2:            CMPA #1
                BNE NR3
                LDX #MEN2
NR3:            CMPA #2
                BNE NR4
                LDX #MEN3
NR4:            CMPA #3
                BNE NR5
                LDX #MEN4
NR5:            CMPA #4
                BNE NR6
                LDX #MEN5
NR6:            CMPA #5
                BNE NR7
                LDX #MEN6
NR7:            STX VEGTXT
                CLR ANTVEG
VELOO1:         LDA ,X+
                CMPA #13
                BNE VELOO2
                INC ANTVEG
VELOO2:         CMPA #36
                BNE VELOO1
                LDA #1
                STA VERTIK
                LDA VEGGPO
                STA SCRPOS
                LDA ANTVEG
                LDU #VEGG
VELOO4:         LBSR WRITE
                DECA
                BEQ VELOO3
                INC VERTIK
                BRA VELOO4
VELOO3:         INC VERTIK
                LDU #BOTN
                LBSR WRITE
                LDU VEGTXT
                LDA #1
                STA VERTIK
                LDA VEGGPO
                INCA
                STA SCRPOS
VELOO6:         LBSR WRITE
VELOO5:         LDA ,U+
                CMPA #13
                BNE VELOO5
                LDA ,U
                CMPA #36
                BEQ VESLUT
                INC VERTIK
                BRA VELOO6
VESLUT:         RTS
;********************************
; CALL WITH CORRECT MENUPOS. MENU-
; NUMBER IN A-REG. (0->)
; Invert menu position
;********************************
TOGGLE:         LDB #128
                MUL
                LSLB
                ROLA        ;D=A*256
                TFR D,X
                LDA MENYPO
                LDB #4
                MUL
                INCB
                LEAX 3328,X
                ABX
                LDU #8
TOLOO2:         LDB #8
TOLOO1:         COM ,X+
                DECB
                BNE TOLOO1
                LEAX 24,X
                LEAU -1,U
                CMPU #0
                BNE TOLOO2
                RTS
;********************************
; Execute menu commands after ENTER.

UTFOER:         LDA MENYPO
                CMPA #0
                BEQ MENY1
                cmpa #1
                beq meny2
                CMPA #2
                LBEQ MENY3
                cmpa #3
                lbeq MENY4
                cmpa #4
                lbeq MENY5
                cmpa #5
                lbeq MENY6
;*******************************
MENY1:          LDA MENYNR
                CMPA #0
                BNE MENY11
                LBRA LOAD
MENY11:         CMPA #1
                BNE MENY12
                LDX #TEKST     ;START
                LDY MAXWHR     ;SLUTT
                LBRA SAVE
MENY12:         cmpa #2        ;Load Block
                bne MENY13
                lbra LOADBLOK
MENY13:         cmpa #3        ;Save Block
                bne MENY14
                lda washere
                cmpa #1
                lbeq VALSLT
                ldx blbegin     ;Block start
                cmpx blend
                lbeq VALSLT
                ldy blend       ;Block end
                lbra save
MENY14:         cmpa #4
                bne MENY15
                lbra STATUS     ;Status Info
MENY15:         LBRA QUIT       ;Quit
;*******************************
MENY2:          lda menynr
                cmpa #0
                bne meny21
                lbra delline
MENY21:         cmpa #1
                bne meny22
                lbra blstart    ;Block begin
MENY22:         cmpa #2
                bne meny23
                lbra blokkend
MENY23:         cmpa #3         ;Move Block
                bne meny24
                lbsr SJEKBLOK   ;Is there a block to delete ?
                cmpb #0
                lbeq VALSLT     ;No, end!
                ldx blbegin     ;Block start
                ldy blend       ;Block end
                lbsr COPYBLOK
                cmpa #0
                lbne DELOLD
                lbsr FULLT      ;Buffer is full.
                lbra VALSLT
DELOLD:         ldx BLOKKST     ;Old block start
                ldy BLOKKSL     ;Old block end
                lbsr DELBLOK    ;Delete old block
                ldd WHERE
                cmpd BLBEGIN    ;Check if the block pointer must move
                lbhs NEIOK
                ldd BLOKKSL     ;Yes, remove the number of chars in old
                subd BLOKKST    ;block.
                addd #1
                std antteikn
                ldd BLBEGIN
                subd antteikn
                std BLBEGIN
                ldd BLEND
                subd antteikn
                std BLEND
NEIOK:          ldx BLBEGIN
                lbsr GOPOS      ;Move cursor to the top of block.
                lbra VALSLT
MENY24:         cmpa #4         ;Copy block
                bne MENY25
                lbsr SJEKBLOK   ;Is there a block to copy ?
                cmpb #0
                lbeq VALSLT     ;No, end!
                ldx blbegin     ;Block start
                ldy blend       ;Block end
                lbsr COPYBLOK
                cmpa #0
                lbne VALSLT
                lbsr FULLT      ;Buffer is full.
                lbra VALSLT
MENY25:         ldx blbegin     ;Block start : Delete Blokk
                ldy blend       ;Block slutt
                lbsr DELBLOK
                lda #1
                sta Washere     ;Blokk off
                ldx #tekst
                stx BLBEGIN
                stx BLEND
                lbra VALSLT
;*******************************
MENY3:          LDA MENYNR
                CMPA #0
                BNE MENY31
                LBRA REPCHA  ;CHANGE REPEA
MENY31:         CMPA #1
                BNE MENY32
                LBRA DELAY
MENY32:         LBRA CLONOF  ;CLICK ON/OF
;*******************************
MENY4:          lda MASKIN
                cmpa #1         ;Dragon 64 ?
                lbeq MENY4x     ;Yes, continue!
                lbra KUN64
MENY4x:         lda menynr
                cmpa #0
                bne MENY41
                lbra BAUDRATE
MENY41:         cmpa #1
                bne MENY42
                lbra DOWNLOAD
MENY42:         lbra UPLOAD
;*********************************
MENY5:          lda menynr
                cmpa #0
                bne MENY51
                ldx #tekst      ;Start print position
                ldy maxwhr      ;End print position
                lbra PRINT      ;Print All
MENY51:         cmpa #1
                bne MENY52
                lda washere
                cmpa #1
                lbeq VALSLT     ;No block to write
                ldx BLBEGIN     ;Block start
                ldy BLEND       ;Block end
                lbra PRINT
MENY52:         cmpa #2
                bne MENY53
                lbra FEEDTOGG
MENY53:         cmpa #3
                bne MENY54
                lbra VELGPRT    ;Choose printer
MENY54:         lbra LEFTMARG   ;Define left margin
;********************************
MENY6:          lda menynr
                cmpa #0
                bne MENY61
                ldx #1400       ;Keyboard buffer
                stx pattern
                lbsr SEARCH
                lbra VALSLT
MENY61:         cmpa #1
                bne MENY62
                ldx #1400
                stx pattern
                lbsr GJENTA     ;Repeat search.
                lbra VALSLT
MENY62:         cmpa #2
                bne MENY63
                ldx #1200       ;Use 1200 for replace, 1400 for search.
                stx pattern     ;This is to avoid errors if the user first
                lbsr REPLACE    ;does a SEARCH and afterwards REPEAT REPLACE
                lbra VALSLT
MENY63:         cmpa #3
                bne MENY64
                ldb REPLEN
                cmpb #0
                lbeq VALSLT
                ldx #1200
                stx pattern
                clra
                ldb TXTLEN
                pshs b
                ldb TXTLEN2
                stb TXTLEN
                lbsr GJENTA     ;Repeat search
                cmpa #3
                beq REPSLT2     ;Not found
                lbsr REPGJENT   ;Repeat Replace
REPSLT2:        puls b
                stb TXTLEN
                lbra VALSLT
MENY64:         cmpa #4
                bne MENY65
                lbra WORDWRAP
MENY65:         bra REFORMAT
;********************************
KOLTELL:        .db 0
FORMATIN:       .db 0           ;Flagg which defines that ENTER should not
                                ;draw the screen again
REFORMAT:       lda washere
                cmpa #1
                lbeq VALSLT     ;No block defined
                lda #1
                sta FORMATIN    ;Set flag. The flag tells ENTER and
                clr insert      ;DELETE routines to not clear the screen
                ldx BLEND
                lda ,x
                cmpa #10
                bne REFORM5
                leax -2,x
                stx BLEND
REFORM5:        ldx BLBEGIN
                lda ,x
                cmpa #13
                bne REF1
                leax 2,x        ;Skip first char in block if it is Chr(13)

REF1:           pshs x
                lbsr GOPOS      ;Move cursor to the top of block
                puls x
                pshs x          ;for use in REFSLT

                lda HUSKKOL     ;Column where BLOKK starts
                inca
                sta KOLTELL
REFORM1:        lda ,x+
                cmpx BLEND
                lbhs REFSLT
                inc KOLTELL
                cmpa #13
                bne NO13
                leay -1,x       ;Replace Chr(13)/Chr(10) with space.
                sty where
                pshs x
                lbsr delete     ;Delete Chr(13)/Chr(10)
                ldy where
                leay -1,y
                sty where
                ldu #1
                lbsr skubb      ;Make room for space
                ldx MAXWHR      ;k max position
                leax 1,x
                stx MAXWHR
                puls x
                lda #32         ;Chr(32)=space
                leay -1,x
                sta ,y          ;Replace Chr(13)/Chr(10) with Chr(32)
                bra REFORM1
NO13:           cmpx BLEND      ;Check if end of block achieved
                bhs REFSLT
                ldb KOLTELL
                cmpb WRAPPOS
                bls REFORM1     ;Check if KOLTELL>position where WORDWRAP occurs
                tfr x,y
                lda #1
                sta KOLTELL
REFORM3:        lda ,-y
                cmpa #13
                bne REFORM2
                stx where       ;If line does not contain space, the
                pshs x          ;string will be cut.
                lbsr ENTER
                puls x
                leax 2,x
                bra REFORM1
REFORM2:        cmpa #32
                bne REFORM3
                sty where       ;Go back to space and insert ENTER
                lbsr DELETE
                lbsr ENTER
                ldx where
                bra REFORM1
REFSLT:         puls x
                lbsr GOPOS
                lda #1
                sta washere     ;Block off
                clr FORMATIN
                lbra VALSLT
;********************************
WRAPTXT:        .db "Wordwrap ?",13
WORDWRAP:       lbsr window
                clr kolonn
                clr scrpos
                LDA #27
                STA SCRPOS
                LDA #8
                STA VERTIK
                LDU #WRAPTXT
                LBSR WRITE
                LDA #14
                STA VERTIK
                LDA #29
                STA SCRPOS
                LDU #YES
                LBSR WRITE
                INC VERTIK
                LDU #NO
                LBSR WRITE
 
                ldx #6670
                LDA WRAP
                inca
                STA MENYNR
                cmpa #2
                bne WRAP2
                leax 256,x
WRAP2:          LDA #2
                LDB #3
                LBSR CHOOSE
                deca
                sta WRAP
                cmpa #0
                lbne VALSLT
                bsr WRAPWHR
                lbra VALSLT
;*********************************
WHRTXT:         .db "At column:",13
WHRBLANK:       .db 32,32,32,13
WRAPWHR:        lda #16
                sta vertik
                lda #22
                sta scrpos
                ldu #whrtxt
                lbsr write
                lda #34
                sta scrpos
                ldb WRAPPOS
                clra
                lbsr INT2STR
                ldu #STRENG
                lbsr write
                lda #40
                sta scrpos

                LDA #32         ;to make cursor blink on/off
                STA CHAR32
                LDY WHERE
                PSHS Y
                LDY #CHAR32
                STY WHERE

WRAPWAIT:       jsr h'8006
                lbsr blink
                cmpa #0
                beq WRAPWAIT

                puls y
                sty where
                cmpa #13
                beq WRAPEND
                cmpa #3
                beq WRAPEND
                lda #37
                sta scrpos
                ldu #WHRBLANK
                lbsr write
                ldx #convert
                lda #3          ;max 3 characters
                clrb            ;Only capital letters
                ldx #convert
                lbsr input
                ldx #convert    ;From here: convert char to 8-bit
                clr WRAPPOS
                cmpb #3
                bne WRAP2b
                lda ,x+
                suba #48
                ldb #100
                mul
                stb WRAPPOS
                ldb #2
WRAP2b:         cmpb #2
                bne WRAP1b
                lda ,x+
                suba #48
                ldb #10
                mul
                addb WRAPPOS
                stb WRAPPOS
                ldb #1
WRAP1b:         ldb ,x+
                subb #48
                addb WRAPPOS
                stb WRAPPOS
WRAPEND:        rts
;*********************************
; INT2STR: Procedure which converts 16-bit
; number to 6 char string, Leading zeros
; converted to CHR(32). Call with 16-bit number in D-reg
; Return in STRENG.

INT:            .dw 0
CONVERT:        .db 0,0,0
INCREASE:       .db 0,0,1

INT2STR:        std int
                ldy #convert
                clr ,y+
                clr ,y+
                clr ,y
                ldx int
INTLOOP:        cmpx #0
                beq TOSTRING
                ldx #increase
                ldu #convert
                ldb #3
                leau b,u
                leax b,x
                lbsr INK2
                ldx int
                leax -1,x
                stx int
                bra INTLOOP
STRENG:         .db 0,0,0,0,0,0,13
TOSTRING:       ldy #streng
                ldx #convert
TOSTLOOP:       lda ,x+
                tfr a,b
                lsra
                lsra
                lsra
                lsra
                adda #48
                sta ,y+
                andb #15
                addb #48
                stb ,y+
                cmpx #increase
                bne TOSTLOOP
                ldx #streng
                leay 5,x
                sty CONVERT     ;Temporary storage
INTNXT:         lda ,x
                cmpa #48
                bne INTSLT
                lda #32
                sta ,x+
                cmpx CONVERT
                beq INTSLT
                bra INTNXT
INTSLT:         rts
;*********************************
REPTXT:         .db "Replace with ?",13
                .equ repequ,1300        ;Replace-buffer
REPLEN:         .db 0                   ;Length of replace string
TXTLEN2:        .db 0                   ;Length of search string
REPLACE:        ldb TXTLEN
                pshs b
                lbsr SEARCH
                puls b
                cmpa #0
                lbeq REPSLT
                cmpa #3
                lbeq REPSLT
                pshs b
                ldb TXTLEN
                stb TXTLEN2
                puls b
                stb TXTLEN
                lbsr window
                clr kolonn
                ldu #REPTXT
                lda #21
                sta scrpos
                lda #9
                sta vertik
                lbsr write

                lda #13
                sta vertik
                lda #17
                sta scrpos
                ldx #repequ
                lda #30         ;Max number of characters
                ldb #1          ;Accept all characters
                lbsr input
                stb replen
                cmpa #3
                lbeq REPSLT

REPGJENT:       clr Washere     ;Block on
                ldx #tekst
                stx BLBEGIN
                ldy #txtend
                sty BLEND       ;To fool DELBLOK.
                ldb TXTLEN2
                clra
                addd NYPLASS
                subd #1
                tfr d,y         ;Y = end of string to shift
                ldx NYPLASS     ;X = start of string to shift
                lbsr DELBLOK    ;Delete string
                lda #1
                sta Washere     ;Block off
                ldx #tekst
                stx BLBEGIN
                stx BLEND

                ldb replen
                clra
                addd #repequ
                subd #1
                tfr d,y         ;Block end
                ldx #repequ
                lbsr COPYBLOK
                cmpa #0
                lbne REPSLT
                lbsr FULLT      ;Buffer is full.
REPSLT:         rts
;********************************
; Call with X-> input buffer
SEATXT:         .db "Input search pattern:",13
PATTERN:        .dw 0                ;Input buffer
TXTLEN:         .db 0                ;Length of string
NYPLASS:        .dw 0                ;New WHERE
SEARCH:         lbsr window
                clr kolonn
                ldu #SEATXT
                lda #21
                sta scrpos
                lda #9
                sta vertik
                lbsr write

                lda #13
                sta vertik
                lda #17
                sta scrpos
                ldx pattern
                lda #30         ;Max number of chars
                ldb #1          ;Accept all chars
                lbsr input
                stb TXTLEN
GJENTA:         ldb TXTLEN
                cmpa #3
                beq SEAR1
                ldy pattern
                lbsr LEITOPP    ;Find string
                stx NYPLASS
                cmpa #0
                bne SEAR2       ;Not found
                lda #3
                rts
SEAR2:          lbsr GOPOS      ;Place cursor at found string
SEAR1:          rts
;*********************************
; LEITOPP. Call with Y-> string to
; find. B = string length
; Returns A=1 if string
; found, A=0 if not found
; If A=1, point X at string in text
; Searches from WHERE

ORIGINAL:       .dw 0           ;String to find
STRLEN:         .db 0
LEITOPP:        sty ORIGINAL
                ldx WHERE
                cmpx #txtend
                beq LEITT4
                clr STRLEN
                lda ,y
LEITT3:         cmpa ,x+
                beq LEITT2
                clr STRLEN
                ldy ORIGINAL
                lda ,y
                cmpx #txtend
                beq LEITT4
                bra LEITT3
LEITT2:         inc STRLEN
                cmpb STRLEN     ;Length
                beq LEITT5
                leay 1,y
                lda ,y
                bra LEITT3

LEITT4:         clra            ;Not found
                rts
LEITT5:         clra
                std ORIGINAL    ;Temporary used to find X position
                tfr x,d
                subd ORIGINAL
                tfr d,x
                lda #1          ;Found
                rts
;*********************************
KUNTXT:         .db "Dragon 64 only.",13
KUN64:          clr kolonn
                lbsr window
                ldu #KUNTXT
                lda #9
                sta vertik
                lda #22
                sta scrpos
                lbsr write
KUN1:           jsr h'8006
                beq KUN1
                lbra VALSLT
;********************************
PRNTXT3:        .db "Set printer left margin",13
LEFTMARG:       clr kolonn
                lbsr window
                ldu #prntxt3
                lda #10
                sta vertik
                lda #20
                sta scrpos
                lbsr write
                lda WRAPPOS
                pshs a
                lda PRMARGIN
                inca
                sta WRAPPOS
                lbsr WRAPWHR
                lda WRAPPOS
                deca
                sta PRMARGIN
                puls a
                sta WRAPPOS
                lbra VALSLT
;***********************************
PRNTXT1:        .db "Printing ...",13
PRNTXT2:        .db "Press BREAK to stop.",13
PRNSTART:       .dw 0
PRNEND:         .dw 0
NYLINJE:        .dw 0   ;0 er <>Chr(10), 1=Chr(10)

PRINT:          stx PRNSTART
                sty PRNEND
                lbsr window
                clr kolonn
                clr scrpos
                LDA #27
                STA SCRPOS
                LDA #10
                STA VERTIK
                LDU #PRNTXT1
                LBSR WRITE
                inc VERTIK
                LDA #22
                STA SCRPOS
                LDU #PRNTXT2
                LBSR WRITE

                ldx prnstart
                cmpx prnend
                lbeq VALSLT
                ldb PRMARGIN
                bra PRNLOO6     ;Write margin
PRNLOOP:        clr NYLINJE
                lda ,x+
                cmpa #10
                bne PRNLOO3
                ldb #1
                stb NYLINJE
                ldb TOGGLINE
                cmpb #1
                beq PRNLOO4
PRNLOO3:        jsr h'800f      ;Print char in A
PRNLOO4:        jsr h'8006      ;Read keyboard
                beq PRNLOO2
                cmpa #3
                lbeq VALSLT
PRNLOO2:        ldb NYLINJE
                cmpb #1
                bne PRNLOO5
                ldb PRMARGIN
PRNLOO6:        cmpb #0
                beq PRNLOO5
                lda #32
                jsr h'800f
                decb
                bra PRNLOO6
PRNLOO5:        cmpx prnend
                bne PRNLOOP
                lda #13
                jsr h'800f
                lda #10
                jsr h'800f
                LBRA VALSLT
;*********************************
TOGGTXT:        .db "Linefeed ?",13
FEEDTOGG:       lbsr window
                clr kolonn
                clr scrpos
                LDA #27
                STA SCRPOS
                LDA #8
                STA VERTIK
                LDU #TOGGTXT
                LBSR WRITE
                LDA #14
                STA VERTIK
                LDA #29
                STA SCRPOS
                LDU #YES
                LBSR WRITE
                INC VERTIK
                LDU #NO
                LBSR WRITE
 
                ldx #6670
                LDA Toggline
                inca
                STA MENYNR
                cmpa #2
                bne FEED2
                leax 256,x
FEED2:          LDA #2
                LDB #3
                LBSR CHOOSE
                deca
                sta toggline
                LBRA VALSLT
;********************************
PRT1:           .db "Which Port ?",13
PRT2:           .db "Parallel",13
PRT3:           .db "Serial",13
VELGPRT:        lbsr window
                CLR KOLONN
                CLR SCRPOS
                LDA #26
                STA SCRPOS
                LDA #8
                STA VERTIK
                LDU #PRT1
                LBSR WRITE
                LDA #14
                STA VERTIK
                LDA #28
                STA SCRPOS
                LDU #PRT2
                LBSR WRITE
                INC VERTIK
                lda #29
                sta scrpos
                LDU #PRT3
                LBSR WRITE
 
                ldx #6669
                LDA Printer
                INCA
                STA MENYNR
                cmpa #2
                bne PRT4
                leax 256,x
PRT4:           LDA #2
                LDB #6
                LBSR CHOOSE
                suba #1
                sta printer
                sta h'3ff       ;Velg printer
                lda #50
                sta h'3fe       ;End of line delay.
                LBRA VALSLT
;*********************************
STATXT1:        .db "IN TEXT:",13
STATXT2:        .db "Lines:",13
STATXT3:        .db "Words:",13
STATXT4:        .db "Chars:",13
STATXT5:        .db "IN BLOCK:",13
STATXT6:        .db "Bytes free:",13

STATUS:         lbsr window
                clr kolonn
                lda #7
                sta vertik
                lda #18
                sta scrpos
                ldu #STATXT1
                lbsr write      ;IN TEXT
                lbsr LIWOCHAR   ;Lines, Words, Chars
                inc vertik
                inc vertik
                lda #18
                sta scrpos
                ldu #STATXT5
                lbsr write      ;IN BLOCK
                lbsr LIWOCHAR
                inc vertik
                ldu #STATXT6
                lda #18
                sta scrpos
                lbsr write      ;Bytes free

                lda #26
                sta scrpos
                lda #8
                sta vertik
                ldx #tekst
                ldy maxwhr
                lbsr INFO

                inc vertik
                inc vertik
                inc vertik
                lda Washere
                cmpa #1
                beq STAT1
                ldx BLBEGIN
                cmpx BLEND
                beq STAT1
                ldy BLEND
                lbsr INFO

STAT1:          ldd #txtend
                subd maxwhr
                lbsr INT2STR
                lda #29
                sta scrpos
                lda #16
                sta vertik
                ldu #streng
                lbsr write

STAWAIT:        jsr h'8006
                beq STAWAIT
                lbra VALSLT

INFO:           pshs x,y
                lbsr FINNLINE   ;Number of lines in D
                lbsr INT2STR
                ldu #Streng
                lbsr write
                puls y,x

                pshs x,y
                inc vertik
                lbsr FINNWORD   ;Number of words in D
                lbsr INT2STR
                ldu #Streng
                lbsr write
                puls y,x

                pshs x,y
                inc vertik
                lbsr FINNCHAR   ;Number of chars in D
                lbsr INT2STR
                ldu #Streng
                lbsr write
                puls y,x
                rts

LIWOCHAR:       inc vertik
                lda #20
                sta scrpos
                ldu #STATXT2
                lbsr write
                inc vertik
                ldu #STATXT3
                lbsr write
                inc vertik
                ldu #STATXT4
                lbsr write
                rts
;**********************************
TELLHER:        .dw 0
FINNLINE:       sty BLOKKSL     ;Used temporarily
                ldd #0
                std Tellher
                cmpx BLOKKSL
                beq FINNSLT
LINELOOP:       lda ,x+
                cmpx BLOKKSL
                beq FINNSLT
                cmpa #13
                bne LINELOOP
                ldy TELLHER
                leay 1,y
                sty TELLHER
                bra LINELOOP

FINNSLT:        ldd TELLHER
                addd #1         ;D=Number of lines
                rts
;**********************************
FINNWORD:       ldd #0
                std TELLHER
                sty BLOKKSL
                cmpx BLOKKSL
                beq WORDSLT

WORD1:          lda ,x+
                cmpx BLOKKSL
                bhs WORDSLT
                cmpa #13
                bne WORD3
                lda -3,x
                cmpa #13
                beq WORD1
                bra WORD4
WORD3:          cmpa #32
                bne WORD1

WORD4:          ldd TELLHER
                addd #1
                std TELLHER

WORD2:          lda ,x+
                cmpx BLOKKSL
                bhs WORDSLT
                cmpa #32
                beq WORD2
                bra WORD1

WORDSLT:        ldd TELLHER
                rts
;**********************************
FINNCHAR:       stx BLOKKST
                sty BLOKKSL
                ldd BLOKKSL
                subd BLOKKST
                addd #1
                rts
;**********************************
MELD1:          .db "Do you really ",13
MELD2:          .db "want to quit ?",13
YES:            .db "Yes",13
NO:             .db "No ",13
QUIT:           LBSR WINDOW
                CLR KOLONN
                CLR SCRPOS
                LDA #24
                STA SCRPOS
                LDA #8
                STA VERTIK
                LDU #MELD1
                LBSR WRITE
                LDU #MELD2
                INC VERTIK
                LBSR WRITE
                LDA #14
                STA VERTIK
                LDA #29
                STA SCRPOS
                LDU #YES
                LBSR WRITE
                INC VERTIK
                LDU #NO
                LBSR WRITE
 
                LDA #1
                STA MENYNR
                LDA #2
                LDB #3
                LDX #6670
                LBSR CHOOSE
                CMPA #2
                LBEQ VALSLT
                LBRA ENDTST
;*******************************
ANTTEIKN:       .dw 0
DELLINE:        ldd maxrad
                cmpd #1
                lbeq VALSLT
                ldd rad
                cmpd maxrad
                lbeq VALSLT

                ldx where
                lda ,x
                cmpa #13
                bne DELLIN2
                ldu #2
                bra DELLIN5
DELLIN2:        lda ,-x
                cmpa #13
                bne DELLIN2
                leax 2,x
                stx where
                clr BLOKKKOL
                clr BLOKKSCR
                ldu #0
DELLIN3:        lda ,x+
                cmpa #13
                beq DELLIN4
                leau 1,u
                bra DELLIN3
DELLIN4:        leau 2,u                ;because of chr(13)/chr(10)
DELLIN5:        stu ANTTEIKN
                ldx where
                lbsr KUTT
                lbsr MINKBLOK
                ldd maxwhr
                subd antteikn
                std maxwhr
                ldd maxrad
                subd #1
                std maxrad
                lda #1
                sta blokk
                sta washere     ;Block off
                lbra VALSLT
;*******************************
WASHERE:        .db 0           ;Block status
HUSKKOL:        .db 0           ;Column at Block start
BLSTART:        clr washere
                ldx where
                stx blbegin
                cmpx blend
                bls startok
                stx blend
STARTOK:        lda BLOKKKOL
                sta HUSKKOL
                lbra VALSLT
;********************************
BLOKKEND:       clr washere
                ldx where
                cmpx maxwhr     ;If block end is defined at MAXWHR
                bne BLO5        ;and the last char is Chr(13), decrease
                lda ,x          ;BLEND by 1.
                cmpa #13
                bne BLO3
                leax -1,x
                stx blend
BLO5:           lda ,x          ;If block end points at CHR(13), increase
                cmpa #13        ;BLEND to get a linefeed.
                bne blo3
                leax 1,x
BLO3:           stx blend
                cmpx blbegin
                bhs blo2
                stx blbegin
BLO2:           lbra VALSLT
;********************************
; Returns A=0 if buffer full.

COPYHELP:       .dw 0
COPYBLOK:       stx BLOKKST
                sty BLOKKSL
                ldd BLOKKSL
                subd BLOKKST
                addd MAXWHR
                cmpd #txtend
                blo COPY2
                clra
                lbra COPYEND
COPY2:          ldd WHERE
                cmpd BLOKKST
                bls COPY6
                cmpd BLOKKSL
                bhs COPY6
                lbra VALSLT     ;Cannot copy block to itself
COPY6:          ldd BLOKKSL
                subd BLOKKST
                addd #1
                tfr d,u
                lbsr SKUBB      ;Make room
                ldd WHERE       ;If block is copied forwards,
                cmpd BLOKKST    ;the limits must be increased
                bhi COPY5
                tfr u,d
                addd BLOKKST
                std BLOKKST     ;Add U chars both at Block start
                tfr u,d         ;and Block end. U = number of chars in block
                addd BLOKKSL
                std BLOKKSL
COPY5:          ldd BLOKKSL
                addd #1
                std COPYHELP
                ldx BLOKKST
                ldy WHERE
COPY3:          lda ,x+
                sta ,y+
                cmpx COPYHELP
                bne COPY3
OPPDATER:       ldx BLOKKST     ;X = Block start
                ldy BLOKKSL     ;Y = Block end
                lbsr FINN13     ;Count number of CR
                ldd MAXRAD      ;Oppdate MAXWHR and MAXRAD
                addd TELL13
                cmpd #0         ;Make sure MAXRAD > 0
                bne COPY4
                ldd #1
COPY4:          std MAXRAD
                ldd MAXWHR
                addd BLOKKSL
                subd BLOKKST
                addd #1
                std MAXWHR
                ldd BLOKKSL     ;New block is defined
                subd BLOKKST
                addd WHERE
                std BLEND
                ldd WHERE
                std BLBEGIN
                lda #1          ;Buffer not full.
COPYEND:        rts
;*********************************
FULL1:          .db "Text buffer is full.",13
FULL2:          .db "You must split your text in",13
FULL3:          .db "two files. Use SAVE BLOCK.",13

FULLT:          lbsr WINDOW
                clr KOLONN
                lda #8
                sta vertik
                lda #21
                sta scrpos
                ldu #FULL1
                lbsr write
                lda #11
                sta vertik
                lda #17
                sta scrpos
                ldu #FULL2
                lbsr write
                inc vertik
                ldu #FULL3
                lbsr write
FULLWAIT:       jsr h'8006
                beq FULLWAIT
                rts
;*********************************
; Delete BLOCK from X to Y.
; Update MAXWHR and MAXRAD

BLOKKST:        .dw 0           ;Start delete
BLOKKSL:        .dw 0           ;End delete
DELBLOK:        stx BLOKKST
                sty BLOKKSL
                lbsr SJEKBLOK   ;Is there a block to delete ?
                cmpb #0
                lbeq DELBL2     ;No, end!
                ldx BLOKKST     ;X = Block start
                ldy BLOKKSL     ;Y = Block end
                lbsr FINN13     ;Count number of CR
                ldx BLOKKST     ;X = Block start
                lbsr GOPOS      ;Move cursor to top of block
                ldd BLOKKSL
                subd BLOKKST
                addd #1
                tfr d,u         ;U = number of chars in block
                ldx WHERE       ;X = start position for delete
                lbsr KUTT       ;Delete block
                ldd MAXWHR      ;Update MAXWHR
                addd BLOKKST
                subd BLOKKSL
                subd #1
                std MAXWHR
                ldd MAXRAD      ;Update MAXWHR and MAXRAD
                subd TELL13
                cmpd #0         ;Make sure MAXRAD > 0
                bne DELBL3
                ldd #1
DELBL3:         cmpd RAD
                bhs DELBL4
                ldd RAD         ;If the last char is deleted,
                ldx WHERE
                stx MAXWHR      ;The cursor placed at end in text
DELBL4:         std MAXRAD      ;MAXRAD = RAD -1, and must not happen.
DELBL2:         rts
;********************************
; Move cursor to X(=new WHERE)

GOX:            .dw 0           ;To here shall WHERE
GOPOS:          stx GOX
                clr BLOKKSCR    ;lda HUSKKOL, sta BLOKKKOL
                clr BLOKKKOL
                lda #1
                sta BLOKKVER    ;Set cursor to upper left
                cmpx WHERE
                lbeq GO1
                cmpx WHERE
                blo GO2         ;WHERE larger than BLOCK start
                ldx WHERE       ;Case 1: WHERE less than X
GO4:            lda ,x+
                cmpa #13
                bne GO3
                ldy RAD
                leay 1,y
                sty RAD
                lda #0
                lbsr scadd
GO3:            cmpx GOX
                bne GO4
                stx WHERE
                bra GO1

GO2:            ldx WHERE       ;Case 2: WHERE larger than X
GO6:            lda ,-x
                cmpa #13
                bne GO5
                ldy RAD
                leay -1,y
                sty RAD
                lda #1
                lbsr scadd
GO5:            cmpx GOX
                bne GO6
                stx WHERE
GO1:            clrb
GO8:            lda ,-x
                cmpa #10
                beq GO7
                incb
                bra GO8
GO7:            stb GOX         ;Temp storage
                addb BLOKKKOL
                stb BLOKKKOL
                ldb GOX
                addb BLOKKSCR
                cmpb #63
                blo GO9
                clrb
GO9:            stb BLOKKSCR
                rts
;********************************
; Returns with number of CR
; in the variable TELL13. Start in X-reg.
; End in y-reg.

TELL13:         .dw 0
FINNEND:        .dw 0
FINN13:         ldu #0
                leay 1,y
                sty FINNEND
FINN3:          lda ,x+
                cmpa #13
                bne FINN2
                leau 1,u
FINN2:          cmpx FINNEND
                bne FINN3
                stu TELL13
                rts
;********************************
; Returns with B=0 if no block is defined.

SJEKBLOK:       clrb
                lda washere
                cmpa #1
                beq SJEKKBL1
                ldx blbegin
                cmpx blend
                beq SJEKKBL1
                ldb #1
SJEKKBL1:       rts
;*********************************
REP1:           .db "Characters per "
                .db "second ?",13
REP2:           .db "40",13
REP3:           .db "30",13
REP4:           .db "20",13
REP5:           .db "10",13
REP6:           .db " 5",13
 
                .equ repe1,1     ;NB LAST 3
                .equ repe2,298   ;BIT GOES
                .equ repe3,1299  ;FROM 1-5.
                .equ repe4,5004
                .equ repe5,13005

REPCHA:         LBSR WINDOW
                LDA #20
                CLR KOLONN
                STA SCRPOS
                LDA #8
                STA VERTIK
                LDU #REP1
                LBSR WRITE
 
                LDA #29
                STA SCRPOS
                LDA #11
                STA VERTIK
                LDU #REP2
                LBSR WRITE
                INC VERTIK
                LDU #REP3
                LBSR WRITE
                INC VERTIK
                LDU #REP4
                LBSR WRITE
                INC VERTIK
                LDU #REP5
                LBSR WRITE
                INC VERTIK
                LDU #REP6
                LBSR WRITE
 
                LDD RATE
                ANDB #7
                STB MENYNR
                LDA #128
                MUL
                LSLB
                ROLA        ;D=B*256
                ADDD #5646  ;DEFAULT X
                TFR D,X
                LDA #5
                LDB #2
                LBSR CHOOSE
 
                CMPA #1
                BNE RE1
                LDX #REPE1
RE1:            CMPA #2
                BNE RE2
                LDX #REPE2
RE2:            CMPA #3
                BNE RE3
                LDX #REPE3
RE3:            CMPA #4
                BNE RE4
                LDX #REPE4
RE4:            CMPA #5
                BNE RE5
                LDX #REPE5
RE5:            STX RATE
                LBRA VALSLT
;*******************************
DELA1:          .db "Delay time before "
                .db "repeat ?",13
DELA2:          .db "0.00 sec",13
DELA3:          .db "0.25 sec",13
DELA4:          .db "0.50 sec",13
DELA5:          .db "0.75 sec",13
DELA6:          .db "1.00 sec",13
 
                .equ delay1,1
                .equ delay2,18
                .equ delay3,43
                .equ delay4,60
                .equ delay5,85
 
DELAY:          LBSR WINDOW
                CLR KOLONN
                LDA #18
                STA SCRPOS
                LDA #8
                STA VERTIK
                LDU #DELA1
                LBSR WRITE
 
                LDA #11
                STA VERTIK
                LDA #27
                STA SCRPOS
                LDU #DELA2
                LBSR WRITE
                INC VERTIK
                LDU #DELA3
                LBSR WRITE
                INC VERTIK
                LDU #DELA4
                LBSR WRITE
                INC VERTIK
                LDU #DELA5
                LBSR WRITE
                INC VERTIK
                LDU #DELA6
                LBSR WRITE
 
                LDD FOER
                ANDB #7
                STB MENYNR
                LDA #128
                MUL
                LSLB
                ROLA        ;D=B*256
                ADDD #5645  ;DEFAULT X
                TFR D,X
                LDA #5
                LDB #5
                LBSR CHOOSE
 
                CMPA #1
                BNE DLA1
                LDX #DELAY1
DLA1:           CMPA #2
                BNE DLA2
                LDX #DELAY2
DLA2:           CMPA #3
                BNE DLA3
                LDX #DELAY3
DLA3:           CMPA #4
                BNE DLA4
                LDX #DELAY4
DLA4:           CMPA #5
                BNE DLA5
                LDX #DELAY5
DLA5:           STX FOER
                LBRA VALSLT
;********************************
CLO1:           .db "Keyboard click ?",13
CLONOF:         LBSR WINDOW
                CLR KOLONN
                LDA #8
                STA VERTIK
                LDA #23
                STA SCRPOS
                LDU #CLO1
                LBSR WRITE
                LDA #11
                STA VERTIK
                LDA #29
                STA SCRPOS
                LDU #YES
                LBSR WRITE
                INC VERTIK
                LDU #NO
                LBSR WRITE
 
                LDB BEEP
                ANDB #1
                STB MENYNR
                INC MENYNR
                LDX #5902
                CMPB #1
                BNE CLO2
                LEAX 256,X
CLO2:           LDA #2
                LDB #2
                LBSR CHOOSE
                DECA
                STA BEEP
                LBRA VALSLT
;********************************
BAUD1:          .db "Choose baud rate!",13
BAUD2:          .db " 300  baud",13
BAUD3:          .db " 600  baud",13
BAUD4:          .db "1200  baud",13
BAUD5:          .db "2400  baud",13

BAUDRATE:       lbsr window
                clr kolonn
                lda #8
                sta vertik
                lda #23
                sta scrpos
                ldu #BAUD1
                lbsr write
                lda #11
                sta vertik
                lda #27
                sta scrpos
                ldu #BAUD2
                lbsr write
                ldu #BAUD3
                inc vertik
                lbsr write
                ldu #BAUD4
                inc vertik
                lbsr write
                inc vertik
                ldu #BAUD5
                lbsr write              ;Write selection list, 300-2400 baud

                lda baud
                suba #5
                cmpa #5
                bne BAU2
                deca
BAU2:           sta menynr
                ldb #128
                mul
                lslb
                rola        ;D=B*256
                addd #5645  ;DEFAULT X
                TFR D,X
                lda #4
                ldb #6
                lbsr choose
                adda #5
                cmpa #9
                bne BAU3
                inca
BAU3:           sta BAUD
                lbsr SETTBAUD
                lbra VALSLT
;*********************************
SETTBAUD:       lda MASKIN      ;Check if Dragon 32 or 64
                cmpa #0
                beq SETTEND
                lda h'ff07
                anda #h'f0
                oraa BAUD
                sta h'ff07
                lda #11
                sta h'ff06
SETTEND:        rts
;********************************
UPLOADT1:       .db "Press BREAK to cancel upload",13
UPLOADT2:       .db "Any other key to start",13
UPLOADT3:       .db "Receiver must have:",13
UPLOADT4:       .db "1 start bit, 8 data bits,",13
UPLOADT5:       .db "1 stop bit and no parity bit",13

UPLOAD:         lbsr window
                clr kolonn
                lda #8
                sta vertik
                lda #17
                sta scrpos
                ldu #UPLOADT1
                lbsr write
                inc vertik
                ldu #UPLOADT2
                lda #20
                sta scrpos
                lbsr write
                inc vertik
                inc vertik
                lda #22
                sta scrpos
                ldu #UPLOADT3
                lbsr write
                inc vertik
                lda #19
                sta scrpos
                ldu #UPLOADT4
                lbsr write
                lda #17
                sta scrpos
                ldu #UPLOADT5
                inc vertik
                lbsr write

UPLOADWAIT:     jsr h'8006
                beq UPLOADWAIT
                cmpa #3
                LBEQ VALSLT

                ldx #TEKST
UPLOADNESTE:    lda ,x+
TXTOM:          ldb h'ff05      ;Wait until TX data register is empty
                andb #16
                beq TXTOM
                sta h'ff04
                jsr h'8006
                cmpa #3
                beq UPLOADSLUTT
                cmpx MAXWHR
                bne UPLOADNESTE
UPLOADSLUTT:    lbra VALSLT
;********************************
DOWNLO1:        .db "Press BREAK to stop",13
DOWNLO2:        .db "Press a key when ready",13
DOWNLO3:        .db "Sender must have:",13
DOWNLO4:        .db "Receiving ...",13
DUMRAD:         .dw 0

DOWNLOAD:       lbsr window
                clr kolonn
                lda #8
                sta vertik
                lda #22
                sta scrpos
                ldu #DOWNLO1
                lbsr write
                inc vertik
                lda #21
                sta scrpos
                ldu #DOWNLO2
                lbsr write
                inc vertik
                inc vertik
                lda #23
                sta scrpos
                ldu #DOWNLO3
                lbsr write
                inc vertik
                lda #19
                sta scrpos
                ldu #UPLOADT4
                lbsr write
                lda #17
                sta scrpos
                ldu #UPLOADT5
                inc vertik
                lbsr write
                inc vertik
                inc vertik

DOWNWAIT:       jsr h'8006
                beq DOWNWAIT
                cmpa #3
                lbeq VALSLT

                lda #25
                sta scrpos
                ldu #DOWNLO4
                lbsr write

                lda h'ff04              ;Remove garbage on RS-232 port.
                ldx WHERE
                ldu RAD
                stu DUMRAD
RXFULL:         jsr h'8006
                cmpa #3
                LBEQ DOWNSLUTT
                ldb h'ff05
                andb #8
                beq RXFULL              ;Wait until RX data register is full

                lda h'ff04
                sta ,x+
                cmpx MAXWHR
                bls DOWNGO1
                ldy MAXWHR
                leay 1,y
                sty MAXWHR
DOWNGO1:        cmpa #13
                bne DOWNGO2
                ldy DUMRAD
                leay 1,y
                sty DUMRAD
                cmpy MAXRAD
                bls DOWNGO2
                ldy MAXRAD
                leay 1,y
                sty MAXRAD
DOWNGO2:        cmpx #TXTEND
                blo RXFULL

DOWNSLUTT:      lbra VALSLT
;********************************
; CALL: A=NO OF CHOICES, B=MAX FIELDS
; MENYNR=DEFAULT, X=DEF. POS
; Used by nearly all menu commands
; Let you select between many alternatives,
; and returns with the selected one.
;********************************
MAXVAL:         .db 1
MAXLEN:         .db 1
XPOSI:          .dw 0
CHOOSE:         STA MAXVAL
                STB MAXLEN
                STX XPOSI
                LBSR SVKVI     ;INVERT
CHWAIT:         JSR h'8006
                BEQ CHWAIT
                CMPA #10
                BEQ CHNED
                CMPA #94
                BEQ CHOPP
                CMPA #13
                BEQ RETURN
                BRA CHWAIT
 
RETURN:         LDA MENYNR
                RTS
 
CHNED:          LDA MENYNR
                CMPA MAXVAL
                LBEQ CHWAIT
                LBSR SVKVI
                INC MENYNR
                LDX XPOSI
                LEAX 256,X
                STX XPOSI
                LBSR SVKVI
                lbsr tom
                lbsr warte
                LBRA CHWAIT
 
CHOPP:          LDA MENYNR
                CMPA #1
                LBEQ CHWAIT
                LBSR SVKVI
                DEC MENYNR
                LDX XPOSI
                LEAX -256,X
                STX XPOSI
                LBSR SVKVI
                lbsr tom
                lbsr warte
                LBRA CHWAIT

WARTE:          ldx #10000
WARTE2:         leax -1,x
                cmpx #0
                bne WARTE2
                rts
;********************************
;* CALL WITH START BYTE IN XPOSI*
;* LENGTH IN MAXLEN VARIABLE.   *
;********************************
SVKVI:          LDU #8
                LDX XPOSI
SVKV2:          LDB MAXLEN
SVKV1:          COM ,X+
                DECB
                BNE SVKV1
                LDB #32
                SUBB MAXLEN
                ABX
                LEAU -1,U
                CMPU #0
                BNE SVKV2
                RTS


;      GET WRITE
;*****************************************************************
;* SCREEN: WRITES TO SCREEN FROM
;* COLUMN IN THE A REGISTER
;* NUMBER OF COLS IN B-REG.
;*******************************
KOLL:           .db 1          ;LOCAL KO
TOTAL:          .db 1
KVAR:           .dw 0
SKJERM:         PSHS X,Y,D,U
                STA KOLL
                STB TOTAL
                LDB SCRPOS
                LDA VERTIK
                PSHS D
                LDA KOLONN
                PSHS D
                ldx WHERE
                pshs X

                LDB VERTIK
SK2:            LDA ,-X
                CMPA #13
                BNE SK1
                DECB
SK1:            CMPB #0
                BNE SK2
                LEAX 2,X
                STX KVAR
 
                LDB #23        ;LINES
                CLR SCRPOS
                CLR KOLONN
                LDA #1
                STA VERTIK
SK4:            LDA KOLL
                LDX KVAR
                CMPA #0
                BEQ SK6
                PSHS B
SK3:            LDB ,X+
                CMPB #13
                BEQ SK9
                DECA
                BNE SK3
                PULS B
                BRA SK6
SK9:            PULS B
                BRA SK7
SK6:            LDA ,X+
                CMPA #13
                BEQ SK5
                tfr x,y
                leay -1,y
                sty where
                LBSR SKRIVA
                cmpx #txtend
                bhs SK10        ;Buffer end. Stop writing
                LDA SCRPOS
                CMPA TOTAL
                BEQ SK5
                BRA SK6
SK5:            CMPA #13
                BEQ SK7
SK8:            LDA ,X+
                CMPA #13
                BNE SK8
SK7:            CLR SCRPOS
                CLR KOLONN
                INC VERTIK
                LEAX 1,X
                STX KVAR
                DECB           ;LINE NUMBER
                BNE SK4
 
SK10:           puls x
                stx WHERE
                PULS D
                STA KOLONN
                PULS D
                STB SCRPOS
                STA VERTIK
                PULS U,D,Y,X
                RTS
;********************************
;* WRITE. WRITES LINE WHICH U   *
;* POINTS AT. END WHEN CHR(13)  *
;* OR LINE FULL.                *
;* POSITION: VERTIK,SCPOS       *
;********************************
WRITE:          PSHS X,Y,D,U
                LDA KOLONN
                LDB SCRPOS
                PSHS D
                LDX WHERE
                PSHS X
NYBOK:          LDA ,U+
                CMPA #13
                BEQ WRTEND
                LBSR SKRIVA
                LDA SCRPOS
                CMPA #64
                BEQ WRTEND
                BRA NYBOK
WRTEND:         lbsr IBLOKK
                cmpb #0
                bne WRT1
                clra
                bra WRT2
WRT1:           lda scrpos
                cmpa #64
                beq WRT3      ;Do not write a LF on the next line.
                LDA #32       ;WRITES
WRT2:           LBSR SKRIVA   ;A BLANK
WRT3:           PULS X        ;AT END
                STX WHERE     ;BECAUSE OF DELETE
                PULS D
                STB SCRPOS
                STA KOLONN
                PULS U,D,Y,X
                RTS

;    GET SCADD
;***************************************************************
;* SCADD. ADDS TO ROW OR
;* COLOUMN, A=0 : INC ROW
;* A=1 : DEC ROW, A=2 : INC COL
;* A=3 : DEC COL
;*******************************
TEMP:           .db 1
SCADD:          PSHS X,Y,D,U
                PSHS A
                LDX #1
                STX COL
                CLRA
                LDB KOLONN
GOON2:          CMPB #10
                BLO REST
                SUBB #9
                LDA COL+1
                ADDA #9
                DAA
                STA COL+1
                LDA COL
                ADCA #0
                STA COL
                BRA GOON2
REST:           LDA COL+1
                STB TEMP
                ADDA TEMP
                DAA
                STA COL+1
                LDA COL
                ADCA #0
                STA COL
                PULS A
 
                CMPA #0
                BNE AD1
                LDU #ROW
                LDX #I
                BRA FIN
AD1:            CMPA #1
                BNE AD2
                LDU #ROW
                LDX #DECREASE
                BRA FIN
AD2:            BRA SHOWX
FIN:            LEAU 2,U
                LEAX 2,X
                LBSR INK
SHOWX:          LBSR VISNY
                PULS X,Y,D,U
                RTS
;*******************************
INK:            ldb #2
INK2:           ANDCC #h'FE     ;With LBSR to INK2 can B, the length,
SCAD1:          LDA ,-U         ;be selected before the call.
                ADCA ,-X
                DAA
                STA ,U
                DECB
                BNE SCAD1
                RTS
;*******************************
COLOG:          .db 1
VISNY:          LDA VERTIK
                PSHS D
                LDA KOLONN
                LDB SCRPOS
                PSHS D
                CLR COLOG
                CLR VERTIK
                LDA #6
                STA KOLONN
                STA SCRPOS
                LDA #h'FF
                STA INVERT
                LDX #ROW
OGCOL:          LDB #2
NYROW:          LDA ,X+
                PSHS D
                LSRA
                LSRA
                LSRA
                LSRA
                ADDA #48
                LBSR SKRIVA
                PULS D
                ANDA #15
                ADDA #48
                LBSR SKRIVA
                DECB
                BNE NYROW
                LDA COLOG
                CMPA #1
                BEQ SLUTA
                LDA #1
                STA COLOG
                LDA #19
                STA KOLONN
                STA SCRPOS
                LDX #COL
                BRA OGCOL
SLUTA:          CLR INVERT
                PULS D
                STA KOLONN
                STB SCRPOS
                PULS D
                STA VERTIK
                RTS


;      GET KEYS
;**********************************************************************
CODE:           .db 1
MULT:           .db 1
CLEAR:          ldx MAXWHR      ;Check if buffer full.
                cmpx #txtend
                blo CLROJOJ
YESFULL:        lda scrpos
                ldb vertik
                pshs d
                lda kolonn
                pshs d
                clra
                sta invert      ;to get vlack on white
                lbsr FULLT
                puls d
                sta kolonn
                puls d
                sta scrpos
                stb vertik
                LBSR CLRSCR
                LDA KOLONN
                SUBA SCRPOS
                LDB #64
                LBSR SKJERM
                lbra WAIT

CLROJOJ:        LDA KOLONN
                CMPA #h'FE
                LBEQ WAIT
                LDA INSERT
                CMPA #0
                BEQ CL3
                LDX WHERE
                LDA ,X
                CMPA #13
                LBEQ WAIT
CL3:            LDB #100
                STB MULT
                CLR CODE
CNTRL:          JSR h'8006
                BEQ CNTRL
                CMPA #8
                bne jabba2
                lbsr DELETE
                lbra WAIT
JABBA2:         SUBA #48
                LDB MULT
                MUL
                ADDB CODE
                STB CODE
                LDB MULT
                CMPB #1
                BEQ SJEKK
                CMPB #100
                BNE M2
                LDB #10
                STB MULT
                BRA CNTRL
M2:             LDB #1
                STB MULT
                BRA CNTRL
SJEKK:          LDA CODE
                CMPA #13
                bne JABBA3
JABBA4:         lbsr ENTER
                lbra WAIT
JABBA3:         CMPA #10
                BEQ JABBA4
                LDA INSERT
                CMPA #0
                BNE CL2
                ldu #1
                LBSR SKUBB
                lbsr AUKBLOK
                LDX MAXWHR
                LEAX 1,X
                STX MAXWHR
CL2:            LDX WHERE
                LDA CODE
                STA ,X
                STX WHERE
                TFR X,U
                LBSR WRITE
                INC SCRPOS
                INC KOLONN
                LDX WHERE
                LEAX 1,X
                STX WHERE
                LDA #2
                LBSR SCADD
                LBRA WAIT
;*******************************
ENTER:          LDA INSERT
                CMPA #0
                BEQ ENT2
 
                LDX RAD
                CMPX #MAXRAD
                BEQ ENT5
                LBSR CURAV
                LDX WHERE      ;INS OFF
ENT4:           LDA ,-X
                CMPA #13
                BNE ENT4
                LEAX 2,X
                STX WHERE
                LDA KOLONN
                CMPA #64
                BLO ENT6
                lda FORMATIN
                cmpa #1
                beq ENT6
                LBSR CLRSCR
ENT6:           SUBA SCRPOS
                CMPA #0
                BEQ ENT7
                lda FORMATIN
                cmpa #1
                beq ENT7
                LBSR CLRSCR
                CLRA
                LDB #64
                LBSR SKJERM
ENT7:           CLR SCRPOS
                CLR KOLONN
                LBSR NED
                rts
 
ENT5:           LBSR TOM
                rts
 
ENT2:           LDA #32        ;INS ON
                LBSR SKRIVA
                ldu #2          ;2 chars
                LBSR SKUBB
                lbsr AUKBLOK
                LDX MAXWHR
                LEAX 2,X
                STX MAXWHR
                LDX WHERE
                LEAX 2,X
                CMPX MAXWHR
                BEQ ENT3
                lda FORMATIN
                cmpa #1
                beq ENT3
                LBSR CLRSCR
 
ENT3:           LDX RAD
                LEAX 1,X
                STX RAD
                LDX MAXRAD
                LEAX 1,X
                STX MAXRAD
                INC VERTIK
                LDA VERTIK
                CMPA #24
                BNE VEROK
                DEC VERTIK
                lda FORMATIN
                cmpa #1
                beq VEROK
                LBSR CLRSCR
VEROK:          CLR KOLONN
                CLR SCRPOS
                LDA #0
                LBSR SCADD
                LDA #13
                LDX WHERE
                STA ,X+
                LDA #10
                STA ,X+
                STX WHERE
                lda FORMATIN
                cmpa #1
                beq NONONO
                LDA #0         ;COL START
                LDB #64        ;COL END
                LBSR SKJERM
                CLRA
                LBSR SKRIVA
                LDA #1
                STA STATE
                DEC KOLONN
                DEC SCRPOS
                LBSR TOM
NONONO:         rts
;********************************
;* NB: RETURN WITH RTS          *
;********************************
LEFT:           LDX WHERE
                LDA ,X
                CMPA #13
                BNE OKCHA3
                lbsr IBLOKK
                cmpb #0
                bne OKLFT1
                clra
                bra OKCHA3
OKLFT1:         LDA #32
OKCHA3:         LBSR SKRIVA
                DEC KOLONN
                DEC SCRPOS
                LDA KOLONN
                CMPA #0
                BEQ BSEND
                LDA SCRPOS
                CMPA #0
                BNE OKLFT
                LBSR SCRLFT
OKLFT:          DEC SCRPOS
                DEC KOLONN
                LDX WHERE
                LEAX -1,X
                STX WHERE
                LDA #0
                LBSR SKRIVA
                DEC KOLONN
                DEC SCRPOS
                LDA #3
                LBSR SCADD
BSEND:          LBSR TOM
                RTS
;*******************************
REMCOL:         .db 1
REMPOS:         .db 1
OPP:            LDD RAD
                CMPD #1
                LBEQ OPPEND
                LBSR CURAV
                LDX WHERE
                LDA ,X
                CMPA #13
                BNE OKCHAR
                lbsr IBLOKK
                cmpb #0
                bne OKCH2
                clra
                bra OKCHAR
OKCH2:          LDA #32
OKCHAR:         LBSR SKRIVA
                DEC KOLONN
                DEC SCRPOS
                LDD RAD
                SUBD #1
                STD RAD
                DEC VERTIK
                LDB #2
                LDX WHERE
LEIT2:          LDA ,-X
                CMPA #13
                BNE LEIT2
                DECB
                BNE LEIT2
                LEAX 2,X
                LDB SCRPOS
                STB REMPOS
                LDB KOLONN
                STB REMCOL
                CLR KOLONN
                CLR SCRPOS
                CMPB #0
                BEQ NULL2
ADDPOS:         LDA ,X+
                CMPA #13
                BEQ DECX
                INC SCRPOS
                INC KOLONN
                DECB
                BNE ADDPOS
                BRA NULL2
DECX:           LEAX -1,X
NULL2:          STX WHERE
                LDA VERTIK
                CMPA #0
                BNE OPP3
                INC VERTIK
                BRA OPP2
OPP3:           LDA REMCOL
                CMPA KOLONN
                BEQ OPPCON
                LBSR NYSCR
                BRA VEROK2
OPPCON:         LDA REMPOS
                STA SCRPOS
                BRA VEROK2
 
;*** THIS ROUTINE IS ALSO
;*** USED BY NED.
;*** CHECK IF NECESSARY TP
;*** CLEAR SCREEN AND WRITE
;*** AGAIN. ALSO MAKES SURE TO
;*** CALL SCREEN WITH A=
;*** EVEN NUMBER!
 
NYSCR:          LDA KOLONN
                CMPA #63
                BHI MIDT
                CLRA
                BRA MIDTOV
MIDT:           LBSR CLRSCR
                LDA #32
                STA SCRPOS
                LDA KOLONN
                SUBA SCRPOS
                TFR A,B
                ANDB #1        ;EVEN ?
                CMPB #0
                BEQ MIDTOV
                INCA
                DEC SCRPOS
MIDTOV:         LDB #64
                LBSR SKJERM
                RTS
 
OPP2:           LDX #9215
OPPLOO:         LDA -256,X
                STA ,X
                LEAX -1,X
                CMPX #3583
                BNE OPPLOO
                LDX #3328
                LDA #h'FF
DLLIN:          STA ,X+
                CMPX #3584
                BNE DLLIN
                LDX WHERE
                LDA KOLONN
                CMPA #0
                BEQ DLLAB
DLLAA:          LEAX -1,X
                DECA
                BNE DLLAA
                STX WHERE
                CLR KOLONN
DLLAB:          TFR X,U
                CLR SCRPOS
                LBSR WRITE
VEROK2:         LDA #1
                LBSR SCADD
OPPEND:         LBSR TOM
                LDA #0
                LBSR SKRIVA
                LDA #1
                STA STATE      ;CURSOR
                DEC KOLONN
                DEC SCRPOS
                RTS
;*******************************
REMNKO:         .db 1
REMNPO:         .db 1
NED:            LDX MAXRAD
                CMPX RAD
                LBEQ NEDEND
                LBSR CURAV
                LDX WHERE
                LDA ,X
                CMPA #13
                BNE OKCHA2
                lbsr IBLOKK
                cmpb #0
                bne OKCH3
                clra
                bra OKCHA2
OKCH3:          LDA #32
OKCHA2:         LBSR BLINK
                LBSR SKRIVA
                DEC KOLONN
                DEC SCRPOS
                LDD RAD
                ADDD #1
                STD RAD
                INC VERTIK
                LDX WHERE
LEIT3:          LDA ,X+
                CMPA #13
                BNE LEIT3
                LEAX 1,X
                LDB SCRPOS
                STB REMNPO
                LDB KOLONN
                STB REMNKO
                CLR SCRPOS
                CLR KOLONN
                CMPB #0
                BEQ NULL
CONTI:          LDA ,X+
                INC SCRPOS
                INC KOLONN
                CMPA #13
                BEQ DECX2
                DECB
                BNE CONTI
                BRA NULL
DECX2:          LEAX -1,X
                DEC SCRPOS
                DEC KOLONN
NULL:           STX WHERE
                LDA VERTIK
                CMPA #24
                BNE NED1
                DEC VERTIK
                BRA NED2
NED1:           LDA REMNKO
                CMPA KOLONN
                BEQ NEDCON
                LBSR NYSCR
                BRA VEROK3
NEDCON:         LDA REMNPO
                STA SCRPOS
                BRA VEROK3
NED2:           LDX #3328
NEDCLR:         LDA 256,X
                STA ,X+
                CMPX #8960
                BNE NEDCLR
                LDA #h'FF
LINCLR:         STA ,X+
                CMPX #9216
                BNE LINCLR
                LDX WHERE
                LDA KOLONN
                CMPA #0
                BEQ LINNN
LINN1:          LEAX -1,X
                DECA
                BNE LINN1
                STX WHERE
                STA KOLONN
LINNN:          TFR X,U
                CLR SCRPOS
                LBSR WRITE
VEROK3:         CLRA
                LBSR SCADD
NEDEND:         LBSR TOM
                LDA #0
                LBSR SKRIVA
                LDA #1
                STA STATE      ;CURSOR
                DEC SCRPOS
                DEC KOLONN
                RTS
;*******************************
RIGTH:          LDA KOLONN
                CMPA #255
                BEQ RIEND
                LDX WHERE
                LDA ,X
                CMPA #13
                BEQ RIEND
                LBSR BLINK
                LDA ,X
                LBSR SKRIVA
                LDA KOLONN
                CMPA #h'FF
                BEQ RIEND
                LDX WHERE
                LEAX 1,X
                STX WHERE
 
                LDA SCRPOS
                CMPA #64
                BNE RIGOON
                LBSR SCRRGT
 
RIGOON:         LDA #2
                LBSR SCADD
RIEND:          LBSR TOM
                LDA #0
                LBSR SKRIVA
                DEC SCRPOS
                DEC KOLONN
                LBRA WAIT
;*******************************
TELL:           .db 1          ;ROWS UP
PGUP:           LDY RAD
                CMPY #1
                LBEQ WAIT
                LBSR CURAV
                CLR SCRPOS
                CLR KOLONN
                LDA #1
                STA VERTIK
                CLR TELL
                LDX WHERE
                LDU #23
NYTEIK:         LDA ,-X
                CMPA #13
                BNE NYTEIK
                INC TELL
                LDY RAD
                LEAY -1,Y
                STY RAD
                CMPY #0
                BEQ STOPP
                LEAU -1,U
                CMPU #0
                BEQ STOPP
                BRA NYTEIK
STOPP:          DEC TELL
                LEAY 1,Y
                STY RAD
                LEAX 2,X
                STX WHERE
                LBSR CLRSCR
                CLRA
                LDB #64
                LBSR SKJERM
NYDEC:          LDA #1
                LBSR SCADD
                LDB TELL
                DECB
                STB TELL
                CMPB #0
                BNE NYDEC
                LBRA RIEND     ;END
;*******************************
PGDN:           LDY RAD
                CMPY MAXRAD
                LBEQ WAIT
                LBSR CURAV
                CLR SCRPOS
                CLR KOLONN
                LDA #1
                STA VERTIK
                CLR TELL
                LDX WHERE
                LDU #22
NYNED:          LDA ,X+
                CMPA #13
                BNE NYNED
                INC TELL
                LDY RAD
                LEAY 1,Y
                STY RAD
                CMPY MAXRAD
                BEQ STOPND
                LEAU -1,U
                CMPU #0
                BEQ STOPND
                BRA NYNED
STOPND:         STY RAD
STOPNF:         LDA ,-X
                CMPA #13
                BNE STOPNF
                LEAX 2,X
                STX WHERE
                LBSR CLRSCR
                CLRA
                LDB #64
                LBSR SKJERM
NYDECN:         LDA #0
                LBSR SCADD
                LDB TELL
                DECB
                STB TELL
                CMPB #0
                BNE NYDECN
                LBRA RIEND     ;END
;*******************************
LINEND:         LBSR CURAV
                LDX WHERE
LINLOO:         LDA ,X+
                CMPA #13
                BEQ LINOK
                LDA KOLONN
                CMPA #h'FE
                BEQ LINLOO
                INC KOLONN
                LDA SCRPOS
                CMPA #h'FE
                BEQ LINLOO
                INC SCRPOS
                BRA LINLOO
LINOK:          LEAX -1,X
                STX WHERE
                LDA SCRPOS
                CMPA #64
                BLO LINOK2
                LDA #63
                STA SCRPOS
                LDA KOLONN
                SUBA SCRPOS
                TFR A,B
                ANDB #1
                CMPB #0        ;EVEN NUMBER ?
                BEQ LINOK3
                INCA
                DEC SCRPOS
LINOK3:         LBSR CLRSCR
                LDB #64
                LBSR SKJERM
LINOK2:         CLRA           ;TO SHOW
                LBSR SCADD     ;NEW
                LDA #1         ;COORDINATES
                LBSR SCADD
                RTS
;*******************************
OFF:            .db "Off"
ON:             .db "On "
VISINS:         LDA #h'FF
                STA INVERT
                LDA SCRPOS
                LDB KOLONN
                PSHS D
                LDA VERTIK
                PSHS D
 
                CLR VERTIK
                LDA #31
                STA SCRPOS
                CLR KOLONN
                LDA INSERT
                CMPA #0          ;ON=0
                BNE INSON
                LDX #OFF
                LDA #1
                STA INSERT
                BRA INSON2
INSON:          LDX #ON
                CLR INSERT
INSON2:         LDB #3
INSON3:         LDA ,X+
                LBSR SKRIVA
                DECB
                BNE INSON3
                CLR INVERT
                PULS D
                STA VERTIK
                PULS D
                STA SCRPOS
                STB KOLONN
                RTS
;*******************************
BSPACE:         LDX WHERE
                CMPX #TEKST
                LBEQ WAIT
                LDA KOLONN
                CMPA #0
                BNE BSPA1
                LBSR OPP
                LBSR LINEND
                lbsr DELETE
                lbra WAIT
BSPA1:          LBSR LEFT
                LDA #21
                lbsr DELETE
                lbra WAIT
;********************************
;* DELETES A CHAR. TAKES INTO   *
;* ACCOUNT CHR(13)/CHR(10)      *
;********************************
HJELP:          .dw 0
DELETE:         STA CHAR
                LDX WHERE
                CMPX MAXWHR
                LBEQ DELBACK
                LDA ,X
                CMPA #13
                BEQ DELENT
                LDU #1         ;1 CHAR
                LBSR KUTT
                lbsr MINKBLOK  ;Check if block pos should decrease
                lda FORMATIN
                cmpa #1
                beq DELET6
                TFR X,U
                LBSR WRITE
DELET6:         LDX MAXWHR
                LEAX -1,X
                STX MAXWHR
                BRA DELEND
DELENT:         LDU #2        ;CHR 13/10
                LBSR KUTT
                lbsr MINKBLOK
                LDX MAXWHR
                LEAX -2,X
                STX MAXWHR
                LDX MAXRAD
                CMPX RAD
                BEQ DELE3
                LEAX -1,X
                STX MAXRAD
DELE3:          CLRA
                LDB KOLONN
                TFR D,Y
                LDX WHERE
DELE2:          LDA ,X+
                CMPA #13
                BEQ KONTR
                LEAY 1,Y
                BRA DELE2
KONTR:          CMPY #254
                BLO DELWRT     ;OK!
                LEAU -254,Y    ;NUMBER OF CHARS
                STU HJELP
                LDD MAXWHR
                SUBD HJELP
                STD MAXWHR
                LDX WHERE
                PSHS X
                CLRA
                LDB KOLONN
                STD HJELP
                TFR X,D
                ADDD #254
                SUBD HJELP
                STD WHERE
                LBSR KUTT      ;U CHARS
                lbsr MINKBLOK
                PULS X
                STX WHERE
DELWRT:         lda FORMATIN
                cmpa #1
                beq DELBACK
                LBSR CLRSCR
                LDA KOLONN
                SUBA SCRPOS
                LDB #64
                LBSR SKJERM
DELEND:         LBSR TOM
                LDA #0
                LBSR SKRIVA
                DEC SCRPOS
                DEC KOLONN
DELBACK:        rts
;********************************
; Decrease BLSTART and BLEND if DELETE
; or BSPACE removes characters.

MINKHELP:       .dw 0

MINKBLOK:       stu MINKHELP
                cmpx blbegin
                bhi MINK1
                ldd blbegin
                subd minkhelp
                std blbegin
MINK1:          cmpx blend
                bhi MINK2
                ldd blend
                subd minkhelp
                std blend
MINK2:          rts
;********************************
; Increase block pointers with U chars if
; WHERE allows.

AUKBLOK:        ldx blbegin
                cmpx blend
                beq AUK2
                stu minkhelp
                ldx where
                cmpx blbegin
                bhi AUK1
                ldd blbegin
                addd minkhelp
                std blbegin     ;Increase block start
AUK1:           cmpx blend
                bhi AUK2
                ldd blend
                addd minkhelp
                std blend       ;Increase block end
AUK2:           rts
;********************************
; DELETE CHARS IN BUFFER.
; Start found in X=WHERE
; U = NUMBER OF CHARS TO REMOVE
;********************************
KUEND:          .dw 0
HELP:           .dw 0
KUTT:           PSHS X,Y,D,U
                LDD MAXWHR
                CMPD WHERE
                BEQ KUSLUT
                STU HELP
                SUBD HELP
                ADDD #1
                STD KUEND      ;=MAX+1-U

                LDD WHERE      ;Y=WHERE
                ADDD HELP
                TFR D,Y

                cmpx KUEND
                beq KUL2
KULOOP:         LDA ,Y+
                STA ,X+
                CMPX KUEND
                BNE KULOOP
 
KUL2:           LDY MAXWHR
                LEAY 1,Y
                STY KUEND
                LDA #13
KUTT4:          STA ,X+
                CMPX KUEND
                BNE KUTT4
 
KUSLUT:         PULS U,D,Y,X
                RTS
;********************************
;* NO PARAMS. KEY CLICK         *
;********************************
                .equ mask,252
LYD:            .db 1
VEI:            .db 1
CLICK:          PSHS X,Y,D,U
                LDD #h'B435
                STA h'FF01
                STB h'FF03
                LDA #h'3F
                STA h'FF23
                ldb #128
                lda #10
CLI2:           andb #mask
                ldx #10
CLI1:           stb h'ff20
                leax -1,x
                cmpx #0
                bne CLI1
                eorb #128
                deca
                cmpa #0
                bne CLI2
                PULS U,D,Y,X
                RTS
;**************************************************************
; Here the main procedure starts, which takes care of all key inputs
; Gives control to the menu if needed.
;**************************************************************
 
START:          LBSR SETUP
                LBSR BAR
                LBSR WINDOW
                LBSR WELCM
COPYRT:         JSR h'8006
                BEQ COPYRT
                LBSR CLRSCR
                LBSR TAST
                RTS
;*****************************************
ORVERD:         .db 1
OGVERD:         .db 1
POS:            .dw 0
REPEAT:         .dw 0 ;TIME BEFORE REPEAT
TAST:           PSHS X,Y,D,U
                LBSR VISINS    ;INS=OFF, becomes ON
WAIT:           JSR h'8006
                LBSR BLINK
                CMPA #0
                BNE WAITOV
                CLR CHAR
                BRA WAIT
 
WAITOV:         CMPA CHAR
                BNE KEYB
                LBSR TOM       ;Waiting time
                LDX REPEAT     ;before
                LEAX 1,X       ;REPEAT
                STX REPEAT
                CMPX FOER
                BLO WAIT
                LDX RATE
KEYB3:          LEAX -1,X      ;REPEAT
                CMPX #0        ;RATE
                BNE KEYB3
                BRA KEYB2
 
KEYB:           LDX #0         ;No
                STX REPEAT     ;Waiting time
 
KEYB2:          LDB BEEP
                CMPB #1
                BEQ EYB3
                LBSR CLICK
EYB3:           STA CHAR
                CMPA #3
                LBEQ VALG

                CMPA #13
                LBNE JABBA1
                ldx MAXWHR      ;Check if buffer is full.
                cmpx #txtend
                lbhs YESFULL
                lbsr ENTER
                lbra WAIT
JABBA1:         CMPA #8
                LBNE BBBBB
                LBSR LEFT
                LBRA WAIT
BBBBB:          CMPA #10
                LBNE CCCCC
                LBSR NED
                LBRA WAIT
CCCCC:          CMPA #94
                LBNE DDDDD
                LBSR OPP
                LBRA WAIT
DDDDD:          CMPA #9
                LBEQ RIGTH
                CMPA #12
                LBEQ CLEAR
                CMPA #95
                LBEQ PGUP
                CMPA #91
                LBEQ PGDN
                CMPA #93
                LBNE EEEEE
                LBSR LINEND
                LBRA WAIT
EEEEE:          CMPA #19
                BNE AAAAA
                LBSR VISINS
                LBRA WAIT
AAAAA:          CMPA #21
                LBEQ BSPACE

                ldx MAXWHR      ;Check if buffer is full.
                cmpx #txtend
                lbhs YESFULL    ;Routine used by CLEAR
                LDA KOLONN
                CMPA #h'FE
                LBEQ WAIT
                LDA INSERT
                CMPA #0
                BEQ INSEON    ;INSERT ON
                LDX WHERE
                LDA ,X
                CMPA #13
                LBEQ WAIT
                BRA INS2
INSEON:         ldu #1         ;1 char
                LBSR SKUBB     ;Make room
                lbsr AUKBLOK
                LDX MAXWHR
                LEAX 1,X
                STX MAXWHR
INS2:           LDA CHAR
                LBSR SKRIVA
                LDX WHERE
                LDA CHAR
                STA ,X+
                STX WHERE
                LDA INSERT
                CMPA #0
                BNE INS3
                ldb WRAP
                cmpb #1
                beq INS5        ;Check if Wordwrap
                ldb kolonn      ;Check if cursor larger than right margin
                incb
                cmpb wrappos
                bls INS5
                ldx where
SOEK32:         ldb ,-x
                cmpb #13
                beq INS5
                cmpb #32
                bne SOEK32
                stx where
                lbsr DELETE     ;Delete space
                lbsr ENTER      ;Add Chr(13) and (10)
                lbsr LINEND

INS5:           LDU WHERE
                LBSR WRITE
INS3:           LDA #0
                LBSR SKRIVA     ;Cursor
                DEC SCRPOS
                DEC KOLONN
 
                LDA SCRPOS
                CMPA #64
                BNE NOSCR
                LBSR SCRRGT
NOSCR:          LDA #2
                LBSR SCADD
                LBSR TOM
                LBRA WAIT
ENDTST:         PULS U,D,Y,X
                RTS
;*****************************
TOM:            PSHS D,X
                LDX #337
                LDA #255
KLR:            STA ,X+
                CMPX #346
                BNE KLR
                PULS X,D
                RTS
;****************************
; Moves buffer forwards from WHERE
; Number of chars in U
SKHELP:         .dw 0

SKUBB:          stu skhelp
                ldd MAXWHR
                cmpd WHERE
                beq SKU2
                tfr d,y
                addd skhelp
                tfr d,x
                leay 1,y
                leax 1,x
SKULOO:         LDA ,-Y
                STA ,-X
                CMPY WHERE
                BNE SKULOO
SKU2:           RTS

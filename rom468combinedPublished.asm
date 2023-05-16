	PAGE 0
;
; Assemble this file using "Makroassembler AS v1.42" by Alfred Arnold,
;	ported to windows in a package called "aswcurr"
;	http://john.ccac.rwth-aachen.de:8000/as/
;
; ..\aswcurr\bin\asw -i . -cpu 8085 -L rom468combined.asm
; ..\aswcurr\bin\p2bin.exe rom468combined -r $0000-$3fff
; comp Rom4682roms.bin rom468combined.bin <no.txt
;
; where Rom4682roms.bin is a binary copy of the original roms
; and no.txt just contains the word "no"
;
	
          ORG 0000H

		INCLUDE "Tek468DeviceInfo.inc"
		INCLUDE "Tek468Variables.inc"

DIGITAL_OFF		equ	0
DIGITAL_NORM	equ	1
DIGITAL_ENV		equ	2
DIGITAL_AVG		equ	3
DIGITAL_SAVE	equ	4

NUMWINNONE			equ	0
NUMWINVOLTS			equ	1
NUMWINTIME			equ	2
NUMWINCPLVT			equ	3
NUMWINSWEEPS		equ	4
NUMWINCNTDOWN		equ	5

; WFTbl has 4 entries of 8 bytes each
; Layout 
; each record:	0	JITTER
;				1	GNDREF
;				2	HGAIN
;				3	VGAIN
;				4	CHANMODE
;				5	STATUS
;				6	TIMEBASE
;				7	VOLTS
;
; There is a parallel V_ValidWFs of 4 entries, 1 byte each
;
;offsets in struct. WFTbl
S_JITTER		equ	0
S_GNDREF		equ	1
S_HGAIN			equ	2
S_VGAIN			equ	3
S_CHANMODE		equ	4		;Channel mode
S_STATUS		equ	5
S_TB			equ	6
S_VOLTS			equ	7

VOLTAGE4		equ	4
WFENTRYSIZE		equ	8
TB20			equ	20
LONGWFMASK		equ	04h		;bit 2 in S_STATUS

MAIN_ACTION_1_ID equ 1		;Update Numeric Window values
MAIN_ACTION_2_ID equ 2
MAIN_ACTION_3_ID equ 3
MAIN_ACTION_4_ID equ 4
MAIN_ACTION_5_ID equ 5
MAIN_ACTION_6_ID equ 6
MAIN_ACTION_7_ID equ 7
MAIN_ACTION_8_ID equ 8
MAIN_ACTION_9_ID equ 9
MAIN_ACTION_10_ID equ 10

	if 0
;
; Necessary when assembling code for ROM1 separately
;
;
; ROM575 Entry Points
;
Display_Interrupt equ	02029H
AddDisplayAction equ	02035H
Set_IE		equ			0205FH
CursorPotInt2 equ		0206BH
ScratchRamTable	equ		02019H
L201B		equ			0201BH
L201F		equ			0201FH
DisplayRamTable	equ		02021H
Init_Display	equ		0202CH
InitDisplayRB	equ		0202FH
Init_GPIB	equ			02032H
Main_Action_6	equ		02038H
Main_Action_1	equ		0203BH
Remove_GPIB_Actions	equ	02047H
Display_Action_5	equ	02062H
Update_DEV_WIFCTL_and equ 02065H
Update_DEV_FPC_and	equ	02068H
Get_GPIB_Status		equ	0206EH
ClrCursorSnap		equ	02071H
AdjustCursorTime equ	02074H
GetWFExpandVal	equ		02077H
Test_Equal_A_L	equ		03D5DH
L3FFC		equ			03FFCH
Action_Table2	equ		02001H		
	endif
	
RST0:
	mov	a,a
	jmp	Start
	hlt	
	hlt	
	hlt	
	hlt
;
; Get *(DE + A) in A. Leave ptr in HL
;
RST1:
	mov	l,a
	mvi	h,00h
	dad	d
	mov	a,m
	ret
	hlt	
	hlt
RST2:
	nop
	hlt	
	hlt	
	hlt	
	hlt	
	hlt	
	hlt	
	hlt
;
; two's complement HL
;
RST3:
	mov	a,l
	cma
	mov	l,a
	mov	a,h
	cma
	mov	h,a
	inx	h
	ret
;
; Jump to HL
;
RST4:	
	pchl
	hlt	
	hlt	
	hlt	
TRAP:
	inx	h
	mov	a,m
	jmp	TRAP
	hlt	
	hlt	
	hlt
;
; GPIB Interrupt
;
RST5dot5:
	mov	a,a
	jmp	GPIBInterrupt
;
; Fatal error
;
RST6:
	mov	a,a
	di
	hlt	
	hlt	
;
; Display Interrupt
;
RST6dot5	
	mov	a,a
	jmp	Display_Interrupt
;
; Position Rate Pot Interrupt
;
RST7:
	mov	a,a
	jmp	CursorPotInt
;
; Firmware Timing.
; External timer running at 500Hz (triggered every 2 mSec)
;	
RST7dot5:	
	mov	a,a
	jmp	Timer_Interrupt
;
SYSRAM_Area:	
	dw	RAM_MIDDLE
	dw	08300H
	dw	RAM_MIDDLE
Display_Action_7:	
	jmp	Display_Action_7_0
AddMainAction:
	jmp	AddMainAction_0
Display_Action_6:	
	jmp	Display_Action_6_0
;
; input A, DE. Output HL
;	
Get_Word_From_Table:
	jmp	Get_Word_From_Table_0
RenderCursorLine:
	jmp	RenderCursorLine_0
StrobeDisplayRAM:
	jmp	StrobeDisplayRAM_0
SetUpLineCursor:	
	jmp	SetUpLineCursor_0
EnableLineCursor:	
	jmp	EnableLineCursor_0
;
; Reset because of a UI change
;	
Main_Action_5:	
	lda	V_DigitalMode
	cpi	DIGITAL_AVG
	jnz	L0070				;brif !DIGITAL_AVG
$$L:
	lda	V_fOK2ProcessAcq	;wait for Display Interrupt to finish
	ral						;boolean test
	jnc	$$L					;brif FALSE
	call Clear_ValidWFs		;invalidate all WFs
L0070:
	mvi	a,0FFH				;TRUE
	sta	V_fOK2UpdateDispWF
	mvi	a,0FFH				;TRUE
	sta	V_fSkipAcquiredWF
	mvi	a,MAIN_ACTION_8_ID	;set INITAVG bit
	call AddMainAction
	lda	V_ACQ_Mode
	ani	7Fh					;01111111 Clr LT2
	sta	DEV_WRSR1			;set sampling bits
	mvi	a,03FH
	sta	DEV_WRSR2
	lda	DEV_MTRIG			;stop time base trigger
	sta	VAR_8009
;
; wait for ACQUIRE bit in DEV_RDSTAT to go LOW
;
$$L:
	lda	DEV_RDSTAT
	ani	01h
	cpi	01h					;A - 1
	jnz	$$L					;loop until 0
	ret						;end Main_Action_5
;
; Update V_ValidWFs, based on V_WFTable entries
;
Clear_ValidWFs:
	lxi	d,V_ValidWFs		;p2 = &V_ValidWFs. Table of 4 booleans
	lxi	h,V_WFTable+S_CHANMODE
	mvi	b,04h				;loop counter: 4, 3, 2, 1
L00A5:
	mov	a,m					;*p
	ana	a					;test
	jm	L00AC				;jump if bit 7 set
	xra	a					;clr
	stax	d				;set V_ValidWFs table entry to FALSE
L00AC:	mov	a,b				;save
	lxi	b,WFENTRYSIZE
	dad	b					;p += 8
	mov	b,a					;restore
	inx	d					;p2++
	dcr	b					;loop 4 times
	jnz	L00A5				;brif != 0
	ret
;
; Read Front Panel Buttons
;
ReadDeviceControls:
	lda	DEV_FP2				;Front Panel push buttons XMIT, NO.AVG, TIME, VOLTS
	cma						;store as Active High
	sta	V_FP2
	lda	V_GPIB_XmittingWF
	cma
	ral						;boolean test
	jnc	L019C
	xra	a
	sta	V_Action7_Flg
	sta	V_Action5_Flg		;set FALSE
	sta	V_Action3_Flg
	sta	V_Action9_Flg
	sta	V_Action6_Flg
	sta	V_LclFlag
	lda	DEV_FP1				;other Front Panel push buttons
	cma
	sta	V_FP1				;store as Active High
	call RecordVerticalMode
	lda	V_Action7_Flg
	sta	V_Action5_Flg
	lda	V_fCH1
	ral
	jc	L00F8
	lda	V_fADD
	ral
	jnc	L00FB
L00F8:
	call RecordCh1Info
L00FB:
	lda	V_fCH2				;boolean test
	ral
	jc	L0109
	lda	V_fADD				;boolean test
	ral
	jnc	L010C
L0109:
	call RecordCh2Info
L010C:	xra	a
	call SetDigitalMode
	call ReadPOST_PRETRIGGER_Settings
	call ReadPULSE_SINE_Settings
	call ReadSAVEREFSettings
	call ReadTB
	lda	V_GPIB_Enabled		;boolean test
	ral
	jnc	L014E				;not active
;
; GPIB active
;	
	lda	V_FP2
	ani	10h					;00010000 XMIT
	mvi	l,00h
	call Test_Different
	lxi	h,V_GPIB_Bool2
	ora	m
	sta	V_GPIB_XmittingWF
	ral						;test boolean
	jnc	L0148
	lda	V_DigitalMode
	cpi	DIGITAL_AVG
	jz	L0148
	lda	V_DigitalMode
	cpi	DIGITAL_ENV
	jnz	L014B
L0148:	jmp	L014E
L014B:	call GPIB_SendWF

L014E:	lda	V_Action9_Flg
	ana	a					;test A
	jz	L015A
	mvi	a,09h
	call AddMainAction
L015A:	lda	V_Action7_Flg
	ana	a					;test A
	jz	L0166
	mvi	a,MAIN_ACTION_7_ID
	call AddMainAction
L0166:
	lda	V_Action5_Flg
	ana	a					;test A
	jz	L0172
	mvi	a,05h
	call AddMainAction
L0172:	lda	V_Action3_Flg
	ana	a					;test A
	jz	L017E
	mvi	a,03h
	call AddMainAction
L017E:	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	L0194
	lda	V_Action6_Flg		;boolean test
	ral
	jnc	L0194
	lda	V_fOK2ProcessAcq
	ral
	jc	L0197
L0194:	jmp	L019C
L0197:
	mvi	a,MAIN_ACTION_7_ID
	call AddDisplayAction
L019C:
	call Read_FP2_Buttons
	ret
;
RecordVerticalMode:
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jz	L01FF
	lda	DEV_MODE
	xri	0ECh				;XOR 11101100
	mov	b,a
	mvi	a,02h
	lxi	h,V_fTRIGVIEWENA
	lxi	d,V_Action7_Flg		;preserved across calls to L04A4
	call UpdateFlagsifChange
	mvi	a,40h
	lxi	h,V_fTRIGVIEW
	call UpdateFlagsifChange
	mvi	a,04h
	lxi	h,V_fXY
	lxi	d,V_LclFlag
	call UpdateFlagsifChange
	mvi	a,08h
	lxi	h,V_fCH2
	call UpdateFlagsifChange
	mvi	a,10h
	lxi	h,V_fALT
	call UpdateFlagsifChange
	mvi	a,20h
	lxi	h,V_fADD
	call UpdateFlagsifChange
	mvi	a,80h
	lxi	h,V_fCH1
	call UpdateFlagsifChange
	lda	V_LclFlag
	mov	b,a
	lxi	h,V_Action7_Flg
	ora	m
	mov	m,a
	mov	a,b
	ana	a
	jz	L01FF
	mvi	a,MAIN_ACTION_10_ID	;clear S_GNDREF fields
	call AddMainAction
L01FF:	ret
;
RecordCh1Info:
	lda	DEV_CH1
	mov	b,a
	cma
	ani	0Fh					;00001111 Volts/Division Mask
	mov	c,a					;range 1..13
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	L021A
	lda	V_CH1_Info			;previous CH1 info
	ani	0C0h				;isolate channel properties
	ora	c					;move previous properties to new CH1 info
	mov	c,a					;new CH1 info
	jmp	L022E
L021A:
	mvi	a,40h				;old UNCAL mask
	ana	b
	jnz	L0224
	mvi	a,80h				;new UNCAL bit
	ora	c
	mov	c,a
L0224:
	mvi	a,80h				;old PROBE mask
	ana	b
	jz	L022E
	mvi	a,40h				;new PROBE bit
	ora	c
	mov	c,a					;new CH1 info
L022E:
	lda	V_CH1_Info
	xra	c					;new CH1 info
	ani	40h
	jz	L023C
	mvi	a,0FFh				;changed
	sta	V_Action7_Flg
L023C:	mov	a,c
	lxi	h,V_CH1_Info
	xra	m
	ani	8Fh					;new UNCAL & VOLTS MASK
	jz	L0251
	mvi	a,0FFh
	sta	V_Action5_Flg
	sta	V_Action7_Flg
	sta	V_Action6_Flg
L0251:
	mov	a,c
	sta	V_CH1_Info			;update
	mov	a,b					;DEV_CH1
	lxi	h,V_CH1_Coupling
	call UpdateInputCoupling
	lxi	h,V_Action5_Flg
	ora	m
	mov	m,a
	ret
RecordCh2Info:
	lda	DEV_CH2
	mov	b,a
	cma
	ani	0Fh					;00001111 Volts/Division
	mov	c,a
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	L027C
	lda	V_CH2_Info
	ani	0C0h				;11000000
	ora	c
	mov	c,a
	jmp	L0290
L027C:	mvi	a,40h			;01000000
	ana	b
	jnz	L0286
	mvi	a,80h				;10000000
	ora	c
	mov	c,a
L0286:	mvi	a,80h			;10000000
	ana	b
	jz	L0290
	mvi	a,40h				;01000000
	ora	c
	mov	c,a
L0290:	lda	V_CH2_Info
	xra	c
	ani	40h					;01000000
	jz	L029E
	mvi	a,0FFh
	sta	V_Action7_Flg
L029E:	mov	a,c
	lxi	h,V_CH2_Info
	xra	m
	ani	8Fh					;10001111
	jz	L02B3
	mvi	a,0FFh
	sta	V_Action5_Flg
	sta	V_Action7_Flg
	sta	V_Action6_Flg
L02B3:	mov	a,c
	sta	V_CH2_Info
	mov	a,b
	lxi	h,V_CH2_Coupling
	call UpdateInputCoupling
	lxi	h,V_Action5_Flg
	ora	m
	mov	m,a
	ret
;
; test *(HL) for (A&30h). Update *(HL) if non-zero
; returns 0 or 0xff in A
;	
UpdateInputCoupling:
	mvi	b,30h				;00110000
	ana	b
	cmp	m
	jz	L02CF
	mov	m,a
	mvi	a,0FFh
	ret
L02CF:	xra	a
	ret
;	
; input A = 0 or 0xff (FALSE or TRUE)
; check bits 0..4 in V_FP1: SAVE(4)|AVG|ENV|NORM|OFF(0), stored as Active High
; only 1 bit can be set due to the push buttons design
;
SetDigitalMode:
	mov	c,a					;save input
	lda	V_FP1
	ani	1Fh					;00011111
	rz
;
; A guaranteed not 0
; determine bit number cleared. range 0..4
;	
	mvi	b,00h				
$$L: rar					;>> 1
	jc	L02E2				;if bit 0 was 1, done
	inr	b
	jmp	$$L
L02E2:
;
; B contains active high bit number 0..4
;
	mov	a,c					;restore input
	ana	a					;test boolean
	jm	L02FA				;jmp if TRUE
	mov	a,b					;bit number from V_FP1 (0-4)
	cpi	04h					;was it bit 4 (SAVE)
	jnz	L02FA				;no
;
; bit 4 was set: SAVE
;	
	lda	V_DigitalMode
	cpi	DIGITAL_ENV
	jz	L031F				;rz!
	cpi	DIGITAL_AVG
	jz	L031F				;rz!
;
; B contains bitnumber that was active low
;	
L02FA:
	lda	V_DigitalMode		;table index.
	mov	d,a
	add	a					;times 5
	add	a
	add	d
	add	b					;plus B. Offset within entry (0..4)
	lxi	d,DIGITAL_Tbl		;ROM table, 5 bytes per entry
	rst	1					;Get *(DE + A) in A
	lxi	h,V_DigitalMode		;save B: active bit number
	mov	m,b					;set V_DigitalMode here
	lxi	h,DIGITAL_Actions_Tbl-2	;ROM table
L030D:
	inx	h					;next table entry
	inx	h
	add	a					;x2 (result from table DIGITAL_Tbl lookup)
	jnc	L031C				;exit if old A < 0x80
	push	h
	push	psw				;save A
	mov	e,m					;get function address from table
	inx	h
	mov	d,m
	xchg					;swap HL and DE
	rst	4					;push return address, jump to <HL>.
	pop	psw					;restore A
	pop	h
L031C:
	jnz	L030D
L031F:	ret
;
;
Set_Action5_Flg:
	mvi	a,0FFh				;V_Action5_Flg = TRUE
	sta	V_Action5_Flg
	ret
;	
Add_Action_2:	
	mvi	a,02h
	call AddMainAction
	ret
L032C:	
	mvi	a,0FFh				;V_Action7_Flg = TRUE
	sta	V_Action7_Flg
	mvi	a,0FFh				;V_Action9_Flg = TRUE
	sta	V_Action9_Flg
	ret
L0337:
	mvi	a,0FFh				;V_fOK2ProcessAcq = TRUE
	sta	V_fOK2ProcessAcq
	ret
L033D:
	lda	V_DigitalMode
	call Set_TRACK_HOLD
	ret
L0344:	
	lhld V_ENV_Sweeps		;V_Sweep_Cnt1 = *(word *)V_ENV_Sweeps
	shld V_Sweep_Cnt1
	ret
L034B:	
	lhld V_AVG_Sweeps		;V_Sweep_Cnt1 = *(word *)V_AVG_Sweeps
	shld V_Sweep_Cnt1
	call Clear_ValidWFs
	ret
;	
ReadPOST_PRETRIGGER_Settings:
	lda	V_FP1
	mvi	b,40h				;01000000 POST/PRETRIGGER
	lxi	h,V_fPostPreTrigger
	lxi	d,V_Action5_Flg
	call UpdateFlagsifChange ;Check change status
	ret
;	
ReadPULSE_SINE_Settings:
	lda	V_FP1
	mvi	b,80h				;10000000 PULSE/SINE
	lxi	h,V_fPulseSine
	lxi	d,V_Action6_Flg
	call UpdateFlagsifChange
	ret
;
ReadSAVEREFSettings:
	lda	V_FP1
	ani	20h					;00100000 SAVEREF
	mvi	a,0FFh
	jnz	L037E				;brif SAVEREF active
	cma
L037E:
	mov	b,a					;save boolean SAVEREF_Active
	lda	V_fSAVEREFShowing	;boolean test
	ana	a
	jz	L0395				
; V_fSAVEREFShowing is TRUE	
	mov	a,b					;reload boolean SAVEREF_Active
	ana	a					;test
	jnz	L0392				;jump if A TRUE
	xra	a
	sta	V_fSAVEREFShowing	;flip V_fSAVEREFShowing to FALSE
	call RemoveREFWFfromWFTbl
L0392:
	jmp	L0399				;skip setting V_fSAVEREFPushed
; V_fSAVEREFShowing is FALSE
L0395:
	mov	a,b					;reload boolean SAVEREF_Active
	sta	V_fSAVEREFPushed
L0399:
	lda	V_fSAVEREFPushed	;boolean test
	ral
	jnc	L03A8
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jz	L03AB
L03A8:	jmp	L03B0
L03AB:	mvi	a,06h
	call AddDisplayAction
L03B0:	ret
;
; read Time Settings
;
ReadTB:
	lda	DEV_BTIME
	ani	080h				;10000000 A/B
	jz	L03BB				;jump if B active
	mvi	a,0FFh				;A active
L03BB:
	lxi	h,V_ATimebaseActive
	cmp	m
	jz	L03CB				;jmp if no change
	mov	m,a					;update	V_ATimebaseActive
	mvi	a,0FFh
	sta	V_Action5_Flg		;set TRUE
	sta	V_Action6_Flg
L03CB:
	lda	DEV_ATIME			;one and only reference to A TIME/DIV
	cma						;original active Low
	ani	1Fh					;00011111 A TIME/DIV	5 bits
	mov	b,a					;save
	lxi	h,V_ATIME
	cmp	m
	jz	L03E8				;jmp if no change
	lda	V_ATimebaseActive	;is A active
	ana	a
	jp	L03E8				;positive means B active
	mvi	a,0FFh
	sta	V_Action5_Flg		;set TRUE
	sta	V_Action6_Flg
L03E8:	mov	m,b				;update V_ATIME
	lda	DEV_BTIME
	cma
	ani	1Fh					;00011111 B TIME/DIV
	mov	b,a
	lxi	h,V_BTIME
	cmp	m
	jz	L0406
	lda	V_ATimebaseActive
	ana	a
	jm	L0406				;negative means A active
	mvi	a,0FFh
	sta	V_Action5_Flg		;set TRUE
	sta	V_Action6_Flg
L0406:	mov	m,b				;update V_BTIME
	ret
;
;
Read_FP2_Buttons:
	lda	V_DigitalMode
	cpi	DIGITAL_OFF
	jnz	L041A
	mvi	a,0FFh
	sta	V_NotCountingDown
	mvi	a,00h
	jmp	L0453
L041A:	cpi	DIGITAL_AVG	;A = V_DigitalMode
	jz	L0424
	cpi	02h
	jnz	L0449
;
; V_DigitalMode = 2 or 3
;	
L0424:
	lda	V_FP2				;active High
	ani	04h					;00000100 NO.AVG
	jz	L0435
	xra	a
	sta	V_NotCountingDown
	mvi	a,04h
	jmp	L0446
L0435:	lda	V_NotCountingDown
	ana	a
	jnz	L0441
	mvi	a,05h
	jmp	L0446
L0441:	lda	V_FP2
	ani	03h					;00000011 TIME VOLTS
L0446:
	jmp	L0453
;
; A != (2 or 3)
L0449:
	mvi	a,0FFh				;set TRUE
	sta	V_NotCountingDown
	lda	V_FP2				;push buttons
	ani	03h					;00000011 TIME VOLTS
;
; multiple jmp from points. A can be 5,4,3,2,1,0
;	
L0453:
	lxi	h,V_CursorMode 		;p
	cmp	m					;A - *p	
	jz	L0463				;jump if same
	mov	m,a					;*p = A		ONLY TIME V_CursorMode is set
	cpi	00h					;TIME or VOLTS on
	jnz	L0463				;jump if yes
	call ClrNumWin			;clear LED display
L0463:
	lda	DEV_CURSOR
	ani	20h					;00100000 SELECT
	lxi	h,V_CURSOR_Select	;test if changed
	cmp	m
	jz	Local047B
	mov	m,a					;update V_CURSOR_Select
	ana	a					;test
	jz	Local047B
	lda	V_fFirstCursorActive ;Reverse Boolean value
	cma
	sta	V_fFirstCursorActive
Local047B:
	ret
;
GPIB_SendWF:
	lda	V_GPIB_Enabled	;test boolean
	ral
	jnc	L04A9				;not active
	lda	V_GPIB_XmittingWF
	ana	a
	jnz	L0491
	lda	V_GPIB_Bool2
	ana	a					;test
	jz	L04A9
L0491:	mvi	a,0FFh
	sta	V_GPIB_XmittingWF	;V_GPIB_XmittingWF = TRUE
	xra	a
	sta	V_GPIB_Bool2		;V_GPIB_Bool2 = FALSE
	mvi	a,10h				;00010000 SAVE
	sta	V_FP1
	mvi	a,0FFh
	call SetDigitalMode
	mvi	a,7Eh
	call AddMainAction
L04A9:	ret
;
; input A, B, DE, HL.
; B is a bitmask
; if (A&B) != 0 A = TRUE else A = FALSE
; if (*HL != A) {*HL = A;	*DE = TRUE;}
; B, DE, HL unchanged
;
UpdateFlagsifChange:
	ana	b
	jz	L04B0				;A is FALSE if jmp
	mvi	a,0FFh				;TRUE
L04B0:	mov	c,a				;save
	cmp	m
	rz
	mov	m,c					;store A
	mvi	a,0FFh
	stax	d
	ret
;
; init function.
;
Init_5_Variables:
	xra	a
	sta	V_fSAVEREFShowing
	mvi	a,0FFh
	sta	V_fFirstCursorActive
	xra	a
	sta	V_GPIB_Bool2
	xra	a
	sta	V_GPIB_XmittingWF
	xra	a
	sta	V_DigitalMode		;init. Seems to be display stage/mode
	ret
;
; init function
; in A: 1 or active push button
;	
Set_TRACK_HOLD:
	cpi	04h					;00000100 SAVE
	lda	V_FPC
	jnz	L04DB
	ani	0BFh				;10111111 Clr TRACK/HOLD
	jmp	L04DD
L04DB:	ori	40h				;01000000 Set TRACK/HOLD
L04DD:	sta	V_FPC
	sta	DEV_FPC
	ret
;
; Update VSM and LIGHTS
;	
Main_Action_7:	
	lda	V_DigitalMode
	cpi	DIGITAL_OFF
	jnz	L0554
	lda	V_VSM
	ani	80h					;10000000 SWEEP DISABLE
	ori	08h					;00001000 XY (active low)
	mov	b,a					;running bits
	lda	V_fCH1
	ana	a					;boolean test
	jp	L04FF
	mov	a,b
	ori	10h					;00010000 CH1
	mov	b,a					;running bits
L04FF:	lda	V_fCH2
	ana	a					;boolean test
	jp	L050A
	mov	a,b
	ori	04h					;00000100 CH2
	mov	b,a					;running bits
L050A:	lda	V_fADD
	ana	a					;boolean test
	jp	L0515
	mov	a,b
	ori	02h					;00000010 ADD
	mov	b,a					;running bits
L0515:	lda	V_fTRIGVIEW
	ana	a					;boolean test
	jp	L052B
	mov	a,b
	ori	01h					;00000001 TRIG VIEW
	mov	b,a					;running bits
	lda	V_fTRIGVIEWENA
	ana	a					;boolean test
	jp	L052B
	mov	a,b
	ori	40h					;01000000 TRIGVIEW ENABLE
	mov	b,a					;running bits
L052B:	lda	V_fALT
	ana	a					;boolean test
	jp	L0536
	mov	a,b
	ori	20h					;00100000 ALT/CHOP
	mov	b,a					;running bits
L0536:	lda	V_fXY
	ana	a					;boolean test
	jp	L0541
	mov	a,b
	ani	0D7h				;11010111 Clr XY ALT/CHOP
	mov	b,a					;running bits
L0541:	mov	a,b
	sta	V_VSM				;save
	ani	0DFh				;11011111 Clr ALT/CHOP (select CHOP)
	sta	DEV_VSM				;update VSM
	mvi	c,2Dh
L054C:	dcr	c				;delay loop
	jnz	L054C
	mov	a,b					;temp reload
	sta	DEV_VSM				;update VSM with original ALT/CHOP
L0554:	xra	a
	sta	V_Lights		;clear
	lda	V_fCH1
	lxi	h,V_fADD
	ora	m					;boolean test
	ral
	jnc	L057B
	lda	V_DigitalMode
	mvi	l,00h
	call Test_Different
	mov	b,a					;temp store
	lda	V_CH1_Info
	ani	1Fh					;00011111 mod 32
	mvi	l,04h
	call Is_A_LE_L
	ora	b					;temp stored value
	ral						;boolean test
	jc	L057E
L057B:	jmp	L059C
L057E:	lda	V_CH1_Info
	ani	40h					;01000000
	cpi	00h
	jz	L0593
	lda	V_Lights
	ori	08h					;00001000 Set CH1X10
	sta	V_Lights
	jmp	L059C
L0593:	mvi	a,04h			;00000100 Set CH2X10
	lxi	h,V_Lights
	ora	m
	sta	V_Lights
L059C:	lda	V_DigitalMode
	mvi	l,00h
	call Test_Equal_A_L
	mov	b,a					;TRUE if equal
	lda	V_fCH2
	lxi	h,V_fADD
	ora	m
	mov	c,a
	lda	V_CH2_Info
	ani	1Fh
	mvi	l,04h
	call Is_A_LE_L
	ana	c
	ana	b
	ral						;boolean test
	jc	L05DF
	lda	V_DigitalMode
	mvi	l,00h
	call Test_Different
	mov	b,a
	lda	V_fALT
	lxi	h,V_fCH1
	ana	m
	lxi	h,V_fSAVEREFShowing			;boolean test
	ana	m
	cma
	lxi	h,V_fCH2
	ana	m
	lxi	h,V_fADD
	ora	m
	ana	b
	ral						;boolean test
	jnc	L05FD
L05DF:	mvi	a,40h			;01000000
	lxi	h,V_CH2_Info
	ana	m
	cpi	00h
	jz	L05F5
	lda	V_Lights		;update
	ori	02h					;00000010 Set CH2X10
	sta	V_Lights
	jmp	L05FD
L05F5:	lda	V_Lights	;update
	ori	01h					;00000001 Set CH2X1
	sta	V_Lights
L05FD:	lda	V_Lights
	cma						;all bits active low
	sta	DEV_LIGHTS
	ret
	
Main_Action_9:	
	lda	V_DigitalMode
	cpi	DIGITAL_OFF
	jnz	L0646
	lda	V_CONTRL
	ani	0F7H				;11110111 Set TRIGVIEW (Active Low)
	ori	04H					;00000100 Clr STORDIS (Active Low)
	sta	V_CONTRL
	sta	DEV_CONTRL
	mvi	a,7Fh				;01111111 Clr SWEEP DISABLE
	lxi	h,V_VSM
	ana	m
	sta	V_VSM
	mvi	a,0DFh				;11011111 Toggle CHOP (Active Low)
	lxi	h,V_VSM
	ana	m
	sta	DEV_VSM
	mvi	a,2Dh				;45 x 2 instructions delay
$$L:
	dcr	a
	jnz	$$L
	lda	V_VSM				;reload
	sta	DEV_VSM
	lda	V_ACQ_Mode
	ani	0BFH				;10111111 Clr STORON
	sta	V_ACQ_Mode
	sta	DEV_WRSR1			;set sampling bits
	jmp	L0673
L0646:	lda	V_CONTRL
	ani	0FBh				;11111011 STORDIS
	ori	08h					;00001000 TRIGVIEW
	sta	V_CONTRL
	sta	DEV_CONTRL
	mvi	a,0DFH				;11011111 ALT/CHOP
	ani	0C9H				;11001001 
	sta	DEV_VSM
	mvi	a,02DH				;busy wait
$$L:						;L065C:
	dcr	a
	jnz	$$L					;L065C
	mvi	a,0C9H				;11001001		SWEEP DISABLE|TRIGVIEW ENABLE|NOT XY|TRIG VIEW
	sta	DEV_VSM
	lda	V_ACQ_Mode
	ori	040H				;01000000 Set STORON
	sta	V_ACQ_Mode
	sta	DEV_WRSR1			;set sampling bits
	call Set_IE				;set IE bit
L0673:	ret
;
; RAM TEST Finished or Skipped. Start the scope.
;
Main_Init:
	lxi	sp,RAM_MIDDLE
	call Init_Action_Table
	call InitDisplayRB
	call Init_5_Variables
	call Init_WFTable
	call Init_Display		;more init
	call ClrNumWin
	call InitJitterVars
	call ClrCursorSnap
	
	lda	DEV_DIPSW			;get switch settings
	cma						;always complement
	ani	80h					;test for GPIB option
	cpi	80h
	jnz	$$L					;L06A5
	mvi	a,0FFh				;set GPIB flag
	sta	V_GPIB_Enabled
	call Init_GPIB		;init GPIB
	jmp	$$L1				;L06A9
$$L:						;L06A5:
	xra	a					;clear GPIB flag
	sta	V_GPIB_Enabled
$$L1:						;L06A9:
	
	mvi	a,01h
	call Set_TRACK_HOLD
	call ReadDeviceControls ;read Front Panel
	mvi	a,MAIN_ACTION_9_ID
	call AddMainAction
	mvi	a,MAIN_ACTION_7_ID
	call AddMainAction
	mvi	a,MAIN_ACTION_5_ID
	call AddMainAction
	mvi	a,MAIN_ACTION_2_ID
	call AddMainAction
	rim						;code similar to Set_IE but not identical
	ani	0Bh					;00001011	preserve MSE, M6.5 and M5.5 mask
	ori	08h					;00001000	set MSE
	sim
	ei
	jmp	Main
;
; in A, B, HL
; A always loaded from V_samplesCnt
;	
Do_Interpolation:
	sta	V_nSamples
	mov	a,b
	cpi	02h					;DIGITAL_ENV
	jnz	L06E2
; input B was 2	
	inx	h					;HL += 4
	inx	h
	inx	h
	inx	h
	call ENV_Interpolation	;uses V_nSamples
	jmp	L06F9
L06E2:
	call DoubleJitter
	lda	V_fPulseSine
	ana	a					;test
	jp	L06F2
	call Sine_Interpolation	;uses V_nSamples
	jmp	L06F9
L06F2:
	inx	h
	inx	h
	inx	h
	inx	h
	call Pulse_Interpolation
L06F9:	ret
;
; in A,B, HL
; A always loaded from V_samplesCnt
;
Do_Interpolation_2:
	sta	V_nSamples
	mov	a,b
	cpi	02h					;DIGITAL_ENV
	jnz	L070A
; input B was 2	
	inx	h
	call ENV_Interpolation	;uses V_nSamples
	jmp	L071E
L070A:
	call DoubleJitter
	lda	V_fPulseSine
	ana	a					;test
	jp	L071A
	call Sine_Interpolation2 ;uses V_nSamples
	jmp	L071E
L071A:	inx	h
	call Pulse_Interpolation			;uses V_nSamples
L071E:	ret
;
; in DE,HL
;
Pulse_Interpolation:
	lda	V_nSamples
	mov	b,a
L0723:
	mov	a,m
	stax d
	inx	d
	inx	h
	add	m
	rar
	stax d
	inx	d
	dcr	b
	jnz	L0723
	xchg
	call Clear_Memory_Block
	ret
;
; in DE,HL
;	
ENV_Interpolation:
	shld V_Saved_Arg_HL		;ptr p1
	xchg
	shld V_Saved_Arg_DE		;ptr p2
	xchg
	mvi	c,02h				;outer loop counter
;outer loop
; inner loopcounter B = V_nSamples ? V_nSamples/2 : 128
; meaning V_nSamples/2 where V_nSamples==0 means V_nSamples==256
L073E:
	lda	V_nSamples
	ana	a					;test
	jnz	L0746				;brif != 0
	stc						;0 becomes 128 after rar
L0746:
	rar					
	mov	b,a					;loop counter
;inner loop
L0748:	mov	a,m				;A=*p1
	stax d					;*p2++ = A
	inx	d					
	inx	d					;p2++	skip
	inx	h					;p1++
	inx	h					;p1++	skip
	add	m					;A += *p1
	rar						;A >> 1
	stax d					;*p2++ = A
	inx	d
	inx	d					;p2++
	dcr	b					;loop counter
	jnz	L0748				;loop
	dcr	c
	jz	L0767				;done
	lhld V_Saved_Arg_DE		;reload p2
	xchg
	lhld V_Saved_Arg_HL		;reload p1
	inx	h					;p1++
	inx	d					;p2++
	jmp	L073E				;loop again
L0767:
	xchg
	dcx	h
	call Clear_Memory_Block
	ret
;
; in DE  p2
; in HL  p1
;	
Sine_Interpolation:
	lda	V_nSamples
	sta	V_Loop_Cntr_1
	shld V_Saved_Arg_HL		;save p1
	xchg
	shld V_Saved_Arg_DE		;save p2
;
; loop V_Loop_Cntr_1 times
;	
L077A:
	lhld V_Saved_Arg_HL		;reload p1
	mov	e,m
	mvi	d,00h
	lxi	b,09h				;L0009
	dad	b					;HL + 9
	push	h
	mov	l,m
	mvi	h,00h
	dad	d
	dad	h
	dad	h
	mov	c,l
	mov	b,h
	lhld V_Saved_Arg_HL
	inx	h
	shld V_Saved_Arg_HL
	mov	e,m
	mvi	d,00h
	pop	h
	dcx	h
	push	h
	mov	l,m
	mvi	h,00h
	dad	d
	mov	e,l
	mov	d,h
	dad	h					;x2
	dad	h					;x4
	dad	d					;x5
	dad	h					;x10
	rst	3					;two's complement HL
	dad	b					;plus BC
	mov	c,l					;save
	mov	b,h
	lhld V_Saved_Arg_HL		;reload
	inx	h
	mov	e,m
	mvi	d,00h
	pop	h
	dcx	h
	mov	l,m
	mvi	h,00h
	dad	d
	mov	e,l
	mov	d,h
	dad	h					;x2
	dad	h					;x4
	dad	d					;x5
	dad	h					;x10
	dad	h					;x20
	dad	d					;x21
	dad	b
	mov	c,l					;save intermediate result
	mov	b,h
	lhld V_Saved_Arg_HL		;reload
	inx	h
	inx	h
	mov	e,m
	mvi	d,00h
	inx	h
	inx	h
	inx	h
	mov	l,m
	mvi	h,00h
	dad	d
	mov	e,l
	mov	d,h
	dad	h					;x2
	dad	h					;x4
	dad	d					;x5
	dad	h					;x10
	dad	d					;x11
	dad	h					;x22
	dad	d					;x23
	dad	h					;x46
	dad	d					;x47
	rst	3					;two's complement HL
	dad	b					;add intermediate result
	mov	c,l					;save
	mov	b,h
	lhld V_Saved_Arg_HL		;reload
	inx	h					;HL += 3
	inx	h
	inx	h
	push	h
	mov	e,m					;get 2 bytes from memory
	mvi	d,00h				;to E and L
	inx	h
	mov	l,m
	mvi	h,00h
	dad	d					;add them
	mov	e,l
	mov	d,h
	dad	h					;x2
	dad	h					;x4
	dad	d					;x5
	dad	h					;x10
	dad	h					;x20
	dad	h					;x40
	dad	h					;x80
	dad	h					;x160
	mvi	d,00h
	jnc	L07FD
	inr	d					;record overflow
L07FD:	mov	a,c
	add	l
	mov	c,a
	mov	a,h
	aci	00h
	jnc	L0807
	inr	d
L0807:	mov	l,a
	mov	h,d
	mov	a,b
	mov	e,b
	mvi	d,00h
	ana	a
	jp	L0813
	mvi	d,0FFh
L0813:	dad	d
	mov	a,c
	ana	a
	jp	L081A
	inx	h
L081A:	mov	a,h
	ana	a
	mov	a,l
	jz	L0826
	mvi	a,00h
	jm	L0826
	cma
L0826:	pop	h
	mov	b,m
	lhld V_Saved_Arg_DE		;reload destination ptr
	mov	m,b
	inx	h
	mov	m,a
	inx	h
	shld V_Saved_Arg_DE		;save updated dest.ptr.
	lda	V_Loop_Cntr_1
	dcr	a
	sta	V_Loop_Cntr_1
	jnz	L077A
	call Clear_Memory_Block
	ret
;
; in DE, HL
;
Sine_Interpolation2:
	lda	V_nSamples
	sta	V_Loop_Cntr_1
	shld V_Saved_Arg_HL
	xchg
	shld V_Saved_Arg_DE
L084D:
	lhld V_Saved_Arg_HL
	mov	e,m
	mvi	d,00h
	inx	h
	shld V_Saved_Arg_HL
	inx	h
	inx	h
	mov	l,m
	mvi	h,00h
	dad	d
	mov	e,l
	mov	d,h
	dad	h
	dad	h
	dad	d
	dad	h
	dad	h
	dad	d
	rst	3				; two's complement HL
	mov	c,l
	mov	b,h
	lhld V_Saved_Arg_HL
	mov	e,m
	mvi	d,00h
	inx	h
	mov	l,m
	mvi	h,00h
	dad	d
	mov	e,l
	mov	d,h
	xra	a
	dad	h
	dad	h
	dad	h
	dad	d
	dad	h
	dad	h
	dad	d
	dad	h
	dad	h
	jnc	L0883
	inr	a
L0883:	dad	d
	jnc	L0888
	inr	a
L0888:	mov	d,a
	mov	a,c
	add	l
	mov	c,a
	mov	a,h
	aci	00h
	jnc	L0893
	inr	d
L0893:
	mov	l,a
	mov	h,d
	mov	a,b
	mov	e,b
	mvi	d,00h
	ana	a					;test
	jp	L089F
	mvi	d,0FFh
L089F:	dad	d
	mov	a,c
	ana	a
	jp	L08A6
	inx	h
L08A6:	mov	a,h
	ana	a
	mov	a,l
	jz	L08B2
	mvi	a,00h
	jm	L08B2
	cma
L08B2:
	lhld V_Saved_Arg_HL
	mov	b,m
	lhld V_Saved_Arg_DE
	mov	m,b
	inx	h
	mov	m,a
	inx	h
	shld V_Saved_Arg_DE
	lda	V_Loop_Cntr_1
	dcr	a
	sta	V_Loop_Cntr_1
	jnz	L084D
	call Clear_Memory_Block
	ret
;
; in HL
;	
DoubleJitter:
	lda	V_Jitter
	add	a					;x 2
	sta	V_Jitter
	rz
	rc
	inx	h
	ret						;double
	ret
;
; in HL
; Clear memory
;	
Clear_Memory_Block:
	lda	V_nSamples
	mov	b,a
	lda	V_fChopped
	ana	a
	mvi	a,80h
	jm	L08E9
	mvi	a,00h
L08E9:	sub	b				;(0x80-B) or (0-B)
	rz						;done
$$L:						;L08EB:
	mvi	m,00h
	inx	h
	mvi	m,00h
	inx	h
	dcr	a
	jnz	$$L					;L08EB
	ret
;
; Process Acquisition Complete
;	
Main_Action_4:
	xra	a
	sta	V_fOK2ProcessAcq
	lda	V_DigitalMode
	sta	V_DigitalMode_4a
	cpi	DIGITAL_SAVE
	jz	L090D
	lda	V_DigitalMode_4a
	cpi	00h					;DIGITAL_OFF
	jnz	L0910
L090D:
	jmp	L0CA0				;done
L0910:
	lhld DEV_RDMAR			;read word! Address of Last acquired waveform data point (byte)
	inr	l					;Address of first data point acquired waveform (256 data points)
	mvi	h,00h
	shld V_ACQWF_Ptr		;store first time as an offset!
	dad	h					;HL x 2 since Waveform stored as a word
	lxi	d,RAM_ACQ			;acquisition memory address
	dad	d					
	shld V_ACQWF_Ptr		;store second time as a pointer!
	lda	V_fAlternating
	cma
	ral
	jc	L0934
	lda	V_fADD
	lxi	h,V_fSAVEREFShowing	;double boolean test
	ana	m
	ral
	jnc	L0938
L0934:
	xra	a
	sta	V_ValidWFs+1
L0938:	lda	V_fCH1
	lxi	h,V_fCH2
	ora	m
	lxi	h,V_fADD
	ana	m
	lxi	h,V_fSAVEREFShowing	;boolean
	ora	m
	mov	b,a
	lda	V_fCH1
	lxi	h,V_fCH2
	ana	m
	mov	c,a
	lda	V_fAlternating
	cma
	ana	c
	ora	b
	cma
	ral
	jnc	L095F
	xra	a
	sta	V_ValidWFs+2		;set to FALSE
L095F:
	call GetWFArea			;returns 1 or 3 in A
	sta	V_PrimaryWF
	di
	lda	DEV_CH1
	lxi	h,V_CH1_Coupling 
	call UpdateInputCoupling
	sta	VAR_80ED
	lda	DEV_CH2
	lxi	h,V_CH2_Coupling
	call UpdateInputCoupling
	lxi	h,VAR_80ED
	ora	m
	jz	L0987
	mvi	a,05h
	call AddMainAction
L0987:
	ei
	lda	V_ChannelMode
	cpi	02h
	jnz	L09B8
	mvi	a,02h
	sta	V_LclWFEntry+S_CHANMODE
	lda	V_CH2_Info
	sta	V_LclWFEntry+S_VOLTS
	lda	V_CH2_Coupling
	sta	V_LclWFEntry+S_STATUS
	lda	V_fCH1
	ral
	jnc	L09B0
	mvi	a,03h
	sta	V_WF_4
	jmp	L09B5
L09B0:	mvi	a,01h
	sta	V_WF_4
L09B5:	jmp	L0A34
L09B8:	lda	V_ChannelMode
	cpi	03h
	jnz	L0A1E
	mvi	a,03h
	sta	V_LclWFEntry+S_CHANMODE
	lda	V_CH2_Info
	ani	80h
	lxi	h,V_CH1_Info
	ora	m
	sta	V_LclWFEntry+S_VOLTS
	lda	V_CH1_Info
	lxi	h,V_CH2_Info
	cmp	m
	jz	L09F3
	lda	V_CH2_Info
	adi	3Dh
	lxi	h,V_CH1_Info
	cmp	m
	jz	L09F3
	lda	V_CH1_Info
	adi	3Dh
	lxi	h,V_CH2_Info
	cmp	m
	jnz	L09F6
L09F3:	jmp	L09FE
L09F6:	lda	V_LclWFEntry+S_VOLTS
	ori	80h
	sta	V_LclWFEntry+S_VOLTS
L09FE:	lda	V_CH2_Coupling
	lxi	h,V_CH1_Coupling
	cmp	m
	jnz	L0A11
	lda	V_CH1_Coupling
	sta	V_LclWFEntry+S_STATUS
	jmp	L0A15
L0A11:	xra	a
	sta	V_LclWFEntry+S_STATUS
L0A15:
	call GetWFArea			;returns AREA1 or AREA3 in A
	sta	V_WF_4
	jmp	L0A34
L0A1E:	mvi	a,01h
	sta	V_WF_4
	mvi	a,01h
	sta	V_LclWFEntry+S_CHANMODE
	lda	V_CH1_Info
	sta	V_LclWFEntry+S_VOLTS
	lda	V_CH1_Coupling
	sta	V_LclWFEntry+S_STATUS
L0A34:	lda	V_fSkipAcquiredWF
	ral
	jc	L0A5A
	lda	V_WF_4
	lhld V_PrimaryWF
	call Test_Different
	mov	b,a
	lda	V_ChannelMode
	mvi	l,03h
	call Test_Different
	lxi	h,V_fADD
	ana	m
	ora	b
	lxi	h,V_fSAVEREFShowing	;boolean test
	ana	m
	ral
	jnc	L0A67
L0A5A:	mvi	a,0FFh
	sta	V_fOK2ProcessAcq
	mvi	a,0FFh
	sta	V_fOK2UpdateDispWF
	jmp	L0C98
L0A67:	lda	V_WF_4
	add	a
	mov	l,a
	mvi	h,00h
	lxi	d,ScratchRamTable-2
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	xchg
	shld V_pScratchRAM
	lhld V_WF_4
	dcr	l
	mov	a,l
	mvi	l,03h
	call ShiftL_A_L_times
	inr	a
	mov	l,a
	mvi	h,00h
	lxi	d,V_WFTable-1
	dad	d
	shld V_pWF_4
	lda	V_DigitalMode_4a
	lxi	h,V_LclWFEntry+S_STATUS
	ora	m
	mov	b,a
	lhld V_pWF_4
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	80h
	ora	b
	sta	V_LclWFEntry+S_STATUS
	lda	V_fPostPreTrigger	;boolean test POST/PRETRIGGER
	ral
	jnc	L0AB4
	lda	V_LclWFEntry+S_STATUS
	ori	08h
	sta	V_LclWFEntry+S_STATUS
L0AB4:	lda	V_ATimebaseActive
	ral
	jnc	L0AC4
	lda	V_ATIME
	sta	V_LclWFEntry+S_TB
	jmp	L0ACA
L0AC4:	lda	V_BTIME
	sta	V_LclWFEntry+S_TB
L0ACA:	lda	V_DigitalMode_4a
	cpi	03h					;DIGITAL_AVG
	jnz	L0AD8
	call Update_Average
	jmp	L0B10
L0AD8:	lda	V_DigitalMode_4a
	cpi	02h					;DIGITAL_ENV
	jnz	L0AE6
	call Update_Envelope
	jmp	L0B10
L0AE6:
	call ReadJitter
	sta	V_Jitter
	lda	V_fChopped
	ral
	jnc	L0B04
	lda	V_Jitter
	mvi	l,01h
	call ShiftR_A_L_times
	sta	V_Jitter
	call UnzipAcquiredWF
	jmp	L0B07
L0B04:
	call Copy_Acquired_WF
L0B07:
	xra	a
	sta	V_fAVGENVFinished
	mvi	a,0FFh
	sta	V_fOK2UpdateDispWF
L0B10:	lda	V_fOK2UpdateDispWF
	ral
	jnc	L0C93
	lhld V_WF_4
	mvi	h,00h
	lxi	d,V_Jitter_Tbl-1
	dad	d
	lda	V_Jitter
	mov	m,a
	lda	V_fChopped
	ral
	jnc	L0B38
	lda	V_Jitter
	adi	40h
	mov	b,a
	sta	V_Jitter_Tbl
	mov	a,b
	sta	V_Jitter
L0B38:
	lda	V_WF_4
	mov	l,a
	lda	V_DigitalMode_4a
	mov	c,a
	lda	V_LclWFEntry+S_TB
	mvi	b,TB20
	call TimeExpandWF		;args A, B, C, L
	sta	V_LclWFEntry+S_HGAIN
	mvi	a,TB20
	lxi	h,V_LclWFEntry+S_TB
	cmp	m
	jnc	L0B5C
	mvi	a,05h
	sta	V_DisplayAction
	jmp	L0B61
L0B5C:	mvi	a,01h
	sta	V_DisplayAction
L0B61:
	lda	V_Jitter
	sta	V_LclWFEntry+S_JITTER
	lda	V_DigitalMode_4a
	cpi	03h
	jz	L0B7A
	lda	V_LclWFEntry+S_VOLTS 
	mvi	b,04h
	call ComputeVGAIN
	sta	V_LclWFEntry+S_VGAIN
L0B7A:
	lda	V_fChopped
	cma
	ral
	jnc	L0B96
	lda	V_LclWFEntry+S_STATUS
	ori	04h
	sta	V_LclWFEntry+S_STATUS
	lxi	h,0200h
	call ComputeGNDREF
	sta	V_LclWFEntry+S_GNDREF
	jmp	L0C16
L0B96:
	xra	a
	lxi	h,V_LclWFEntry+S_STATUS
	ora	m
	sta	V_LclWFEntry+S_STATUS
	lxi	h,0100H
	call ComputeGNDREF
	sta	V_LclWFEntry+S_GNDREF
	lxi	d,V_LclWFEntry
	lxi	h,V_LclWFEntry_2
	lxi	b,WFENTRYSIZE
	call Copy_Bytes			; 8 bytes *DE to *HL
	lhld V_pWF_4
	shld V_SavedpWF_4
	lda	V_CH2_Info
	mvi	b,04h
	call ComputeVGAIN
	sta	V_LclWFEntry+S_VGAIN
	lda	V_Jitter_Tbl+0
	sui	40h
	mov	b,a
	sta	V_Jitter_Tbl+1
	mov	a,b
	sta	V_Jitter
	lda	V_DigitalMode_4a
	mov	c,a
	lda	V_LclWFEntry+S_TB
	mvi	b,TB20
	mvi	l,02h
	call TimeExpandWF		;args A, B, C, L
	sta	V_LclWFEntry+S_HGAIN
	lda	V_Jitter
	sta	V_LclWFEntry+S_JITTER
	mvi	a,02h
	sta	V_LclWFEntry+S_CHANMODE
	mvi	a,30h
	cma
	lxi	h,V_LclWFEntry+S_STATUS
	ana	m
	lxi	h,V_CH2_Coupling
	ora	m
	sta	V_LclWFEntry+S_STATUS
	lda	V_CH2_Info
	sta	V_LclWFEntry+S_VOLTS
	lhld ScratchRamTable+2
	shld V_pScratchRAM
	lxi	h,V_WFTable+WFENTRYSIZE	;WFTable[AREA2]
	shld V_pWF_4
; Duplicate code. But A == S_VOLTS field
	lxi	h,0100H
	call ComputeGNDREF
	sta	V_LclWFEntry+S_GNDREF
L0C16:
	di
	call CopyWFTableEntry
	lda	V_fChopped
	ral
	jnc	L0C41
	lhld V_SavedpWF_4
	lxi	d,V_LclWFEntry_2
	lxi	b,WFENTRYSIZE
	call Copy_Bytes 		; 8 bytes *DE to *HL
	lda	V_fSAVEREFShowing	;boolean
	mov	h,a
	lda	V_fADD
	ora	h
	jnz	L0C3E				;non-zero if either TRUE
	lda	V_WFTable+WFENTRYSIZE+S_GNDREF
	sta	V_WFTable+2*WFENTRYSIZE+S_GNDREF
L0C3E:
	jmp	L0C52
L0C41:
	lda	V_fADD
	mov	h,a
	lda	V_fSAVEREFShowing
	ora	h
	jnz	L0C52				;non-zero if either TRUE
	lda	V_WFTable+2*WFENTRYSIZE+S_GNDREF
	sta	V_WFTable+WFENTRYSIZE+S_GNDREF
L0C52:	lda	V_WF_4
	add	a
	add	a
	add	a
	add	a
	mov	b,a
	lda	V_DisplayAction
	ora	b
	call AddDisplayAction
	lda	V_fChopped
	ral
	jnc	L0C70
	lda	V_DisplayAction
	ori	20h
	call AddDisplayAction
L0C70:	lda	V_fAVGENVFinished
	ral
	jnc	L0C8F
	xra	a
	sta	V_fAVGENVFinished
	mvi	a,0FFh
	call SetDigitalMode
	call GPIB_SendWF
	lda	V_fSAVEREFPushed
	ral
	jnc	L0C8F
	mvi	a,06h
	call AddDisplayAction
L0C8F:
	ei
	jmp	L0C98
L0C93:
	mvi	a,0FFh
	sta	V_fOK2ProcessAcq
L0C98:
	mvi	a,MAIN_ACTION_2_ID
	call AddMainAction
	jmp	L0CA5
L0CA0:	mvi	a,0FFh
	sta	V_fOK2ProcessAcq
L0CA5:	ret

Update_Average:
	di
	lhld V_pWF_4
	lxi	d,05H
	dad	d
	mov	a,m
	mov	b,a
	ani	80h
	jz	L0CC2
	mov	a,b
	ani	7Fh
	mov	m,a
	lhld V_AVG_Sweeps
	shld V_Sweep_Cnt1
	shld V_Sweep_Cnt2
L0CC2:
	ei
	lhld V_Sweep_Cnt1
	xchg
	lhld V_Sweep_Cnt2
	mov	a,e
	sub	l
	mov	l,a
	mov	a,d
	sbb	h
	ora	l
	jnz	L0CE1
	xra	a
	sta	V_fOK2UpdateDispWF
	xra	a
	sta	V_fAVGENVFinished
	call Setup_Average
	jmp	L0CE4
L0CE1:
	call Add_Average
L0CE4:
	lhld V_Sweep_Cnt1
	dcx	h
	shld V_Sweep_Cnt1
	mov	a,l
	ora	h
	jnz	L0D0C
	mvi	a,0FFh
	sta	V_NotCountingDown
	mvi	a,0FFh
	sta	V_fAVGENVFinished
	lhld V_Sweep_Cnt2
	shld V_Sweep_Cnt1
	call Finalize_Average
	xra	a
	sta	V_Jitter
	mvi	a,0FFh
	sta	V_fOK2UpdateDispWF
L0D0C:
	ret
;
Update_Envelope:
	lda	V_LclWFEntry+S_STATUS
	ani	80h
	cpi	00h
	jz	L0D2C
	mvi	a,7Fh
	lxi	h,V_LclWFEntry+S_STATUS
	ana	m				;remove bit 7
	sta	V_LclWFEntry+S_STATUS
	lda	V_ChannelMode
	sta	V_SavedChannelMode
	lhld V_ENV_Sweeps
	shld V_Sweep_Cnt1
L0D2C:	lhld V_Sweep_Cnt1
	xchg
	lhld V_ENV_Sweeps
	mov	a,e
	sub	l
	mov	l,a
	mov	a,d
	sbb	h
	ora	l
	jnz	L0D46
	xra	a
	sta	V_fAVGENVFinished
	call Setup_Envelope
	jmp	L0D49
L0D46:
	call Add_Envelope
L0D49:
	lda	V_fSAVEREFShowing	;boolean test
	ral
	jc	L0D5A
	lda	V_ChannelMode
	lxi	h,V_SavedChannelMode
	cmp	m
	jnz	L0D61
L0D5A:	lhld V_Sweep_Cnt1
	dcx	h
	shld V_Sweep_Cnt1
L0D61:	lhld V_Sweep_Cnt1
	mov	a,l
	ora	h
	jz	L0D82
	lxi	d,0E00h
	lhld V_Sweep_Cnt1
	mov	a,e
	ana	l
	mov	l,a
	mov	a,d
	ana	h
	mov	h,a
	xchg
	lxi	h,0H
	mov	a,e
	sub	l
	mov	l,a
	mov	a,d
	sbb	h
	ora	l
	jz	L0D9F
L0D82:	mvi	a,0FFh
	sta	V_NotCountingDown
	mvi	a,0FFh
	sta	V_fAVGENVFinished
	lxi	d,0FFFh
	lhld V_ENV_Sweeps
	mov	a,e
	ana	l
	mov	l,a
	mov	a,d
	ana	h
	mov	h,a
	shld V_Sweep_Cnt1
	xra	a
	sta	V_Jitter
L0D9F:	mvi	a,0FFh
	sta	V_fOK2UpdateDispWF
	ret
;
;
Copy_Acquired_WF:
	lhld V_ACQWF_Ptr
	xchg
	lhld V_pScratchRAM
	lxi	b,0200H
	call Copy_Bytes 		; 512 bytes *DE to *HL
	ret
UnzipAcquiredWF:
	lxi	b,0200H				;loop count
	lhld V_ACQWF_Ptr
	inx	h
	xchg
	lhld V_pScratchRAM
L0DBE:
	ldax d					;copy *DE to *HL
	mov	m,a
	inx	h					;+1
	inx	d					;+2
	inx	d
	dcr	c
	jnz	L0DBE
	dcx	d
	dcr	b
	jnz	L0DBE
	ret
Setup_Envelope:
	lhld V_ACQWF_Ptr
	xchg
	lhld V_pScratchRAM
	mvi	c,00h
L0DD6:
	ldax d
	mov	b,a
	inx	d
	ldax d
	cmp	b
	jc	L0DE4
	mov	m,a
	inx	h
	mov	m,b
	jmp	L0DE7
L0DE4:	mov	m,b
	inx	h
	mov	m,a
L0DE7:	inx	h
	inx	d
	dcr	c
	jnz	L0DD6
	ret
Add_Envelope:
	mvi	c,00h
	lhld V_ACQWF_Ptr
	xchg
	lhld V_pScratchRAM
L0DF7:
	ldax d
	cmp	m
	jc	L0DFD
	mov	m,a
L0DFD:	inx	d
	ldax d
	cmp	m
	jc	L0E04
	mov	m,a
L0E04:	inx	h
	dcx	d
	ldax d
	cmp	m
	jnc	L0E0C
	mov	m,a
L0E0C:	inx	d
	ldax d
	cmp	m
	jnc	L0E13
	mov	m,a
L0E13:	inx	h
	inx	d
	dcr	c
	jnz	L0DF7
	ret
Setup_Average:
	lhld V_pScratchRAM
	mov	a,h
	xri	02h
	mov	h,a
	shld V_pScratchRAM2
	xchg
	lxi	h,RAM_MIDDLE
	lxi	b,0200H
	call Copy_Bytes  		; 512 bytes *DE to *HL
	call Check_AOM_bit
	lhld V_ACQWF_Ptr
	xchg
	lxi	h,RAM_SCRATCH
	lxi	b,0200h
L0E3B:	ldax d
	mov	m,a
	inx	h
	mvi	m,00h
	inx	h
	inx	d
	dcr	c
	jnz	L0E3B
	dcr	b
	jnz	L0E3B
	ret
;
; add 512 byte WaveForm (DE) to 1024 byte WaveForm (HL)
;
Add_Average:
	call Check_AOM_bit		; returns (V_ACQWF_Ptr) in HL!
	lhld V_ACQWF_Ptr
	xchg
	lxi	h,RAM_SCRATCH		;destination WaveForm
	lxi	b,0200h				;BC loop counter
L0E58:
	ldax d
	add	m					;sets carry
	mov	m,a
	inx	h
	mov	a,m
	aci	00h					;add with carry immediate
	mov	m,a
	inx	h
	inx	d
	dcr	c
	jnz	L0E58
	dcr	b
	jnz	L0E58
	ret
;
; Check AOM bit. Copy 1 byte at end of waveform if set
; returns (V_ACQWF_Ptr) in HL
;
Check_AOM_bit:
	lda	DEV_RDSTAT
	ani	02h					;00000010 AOM
	rz
	lhld V_ACQWF_Ptr
	lxi	d,0200H
	dad	d
	mov	a,m
	dcx	h
	mov	m,a
	shld V_ACQWF_Ptr
	ret
;
;
Finalize_Average:
	lda	V_LclWFEntry+S_VOLTS
	ani	1Fh					;isolate
	cpi	VOLTAGE4
	jnc	L0E98				;brif voltage >= VOLTAGE4
;
; A is desired voltage < VOLTAGE4
;
	mov	b,a
	mvi	a,VOLTAGE4
	sub	b
	sta	V_VoltSteps
	mvi	a,0C0h				;new VGAIN
	sta	V_LclWFEntry+S_VGAIN
	jmp	L0EA1
L0E98:
	xra	a
	sta	V_VoltSteps
	mvi	a,0F0h				;standard VGAIN
	sta	V_LclWFEntry+S_VGAIN
L0EA1:
	lhld V_Sweep_Cnt2		;nr. of WFs to average
;
; nr. of WFs to average is always a power of 2.
; compute 2 ^ (8 - x) where (2 ^ x) is nr. of WFs to average
;
	mvi	b,08h
	mov	a,h
	rar
	mov	a,l
	rar
L0EAA:
	dcr	b
	rar
	ana	a
	jnz	L0EAA
	mov	a,b
	sta	V_Local810D			;store result 2^(8 - x)
	lxi	h,0200h
	shld V_LoopCntAVG
	lxi	d,RAM_SCRATCH		;compress Word buffer to byte buffer
	lxi	b,RAM_SCRATCH
L0EC0:
	ldax d
	mov	l,a
	inx	d
	ldax d
	mov	h,a
	lda	V_Local810D			;2^(8-x)
	ana	a
	jz	L0ED1
;
; compute SUM / (2^x) => SUM * (2 ^ (8 - x)) / (2^8)	
;
L0ECC:
	dad	h
	dcr	a
	jnz	L0ECC
L0ED1:
	lda	V_VoltSteps
	ana	a
	jz	L0EEB
;
; Unresolved Bug in original 468 code
;
; V_VoltSteps != 0. Related to a voltage setting < VOLTAGE4
; VGAIN is set to 0C0h (normally 0F0h). 1.25 magnification.
; see UpdateChannelVolts() for the same value.
; WF value (HL) needs to be modified to show the magnified voltage
; Code adds 0C000h to the Sum and ignores overflow
; then doubles the Sum and set the MSB of the Sum to 0FFh.
; This solution does NOT work:
; The averaged WF will show spikes when moved below the 0 line
;
	push d
	lxi	d,0C000h
L0EDC:
	dad	d					;Sum = 0C000h, ignore carry
	dad	h					;double Sum
	jnc	L0EE6
	mvi	h,0FFh
	jmp	L0EEA
L0EE6:
	dcr	a
	jnz	L0EDC
L0EEA:
	pop	d
L0EEB:
;
; end of 468 code bug
;
	mov	a,h					;divide Sum by 256 by taking MSB of Sum
	stax b
	inx	d
	inx	b
	lhld V_LoopCntAVG
	dcx	h
	shld V_LoopCntAVG
	mov	a,l
	ora	h
	jnz	L0EC0
	lhld V_pScratchRAM
	lxi	d,RAM_SCRATCH
	lxi	b,0200H
	call Copy_Bytes  		; 512 bytes *DE to *HL
	lhld V_pScratchRAM2
	lxi	d,RAM_MIDDLE
	lxi	b,0200H
	call Copy_Bytes 		; 512 bytes *DE to *HL
	ret
;
;
ComputeGNDREF:
	xchg
	lhld V_pScratchRAM
	dad	d
	shld VAR_8111
	lda	V_LclWFEntry+S_STATUS
	ani	30h
	cpi	20h
	jnz	L0F60
	lhld V_pWF_4
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	30h
	cpi	20h
	jnz	L0F55
	mvi	b,00h
	lhld VAR_8111
	lxi	d,0H
	mvi	a,10h
L0F40:	dcx	h
	mov	c,m
	xchg
	dad	b
	xchg
	dcr	a
	jnz	L0F40
	xchg
	dad	h					;times 2
	dad	h					;times 4
	dad	h					;times 8
	dad	h					;times 16
	mov	a,h
	sta	VAR_80ED
	jmp	L0F5D
L0F55:
	lhld VAR_8111
	dcx	h
	mov	a,m
	sta	VAR_80ED
L0F5D:	jmp	L0F68
L0F60:	lhld V_pWF_4
	inx	h
	mov	a,m
	sta	VAR_80ED
L0F68:	lda	VAR_80ED
	ret
;
; table init function
;	
Main_Action_10:
	mvi	b,04h
	lxi	h,V_WFTable+S_CHANMODE
L0F71:
	mov	a,m
	ani	80h					;test SAVEREF bit
	jnz	L0F7F
	push h
	lxi	d,-3
	dad	d
	mvi	m,00h				;p->S_GNDREF = 0
	pop	h
L0F7F:
	lxi	d,WFENTRYSIZE		;add to hl
	dad	d
	dcr	b
	jnz	L0F71
	ret
;
; Copy and entry from Local WFTable to master WFTable
;
CopyWFTableEntry:
	lhld V_pWF_4
	lxi	d,V_LclWFEntry
	lxi	b,WFENTRYSIZE
	call Copy_Bytes 		; 8 bytes *DE to *HL
	ret
;
; set INITAVG bit in WFTable[0..3].Status
;
Main_Action_8:	
	lxi	h,V_WFTable+S_STATUS	;p to WF Status, 4 entries, each entry 8 bytes.
	lxi	d,WFENTRYSIZE
	mvi	c,04h				;loop 4 times 4,3,2,1
	mvi	b,80h				;10000000
L0F9F:
	mov	a,b
	ora	m					;set bit 7 in p->status
	mov	m,a
	dad	d					;next WFTbl entry
	dcr	c					;loop 4 times
	jnz	L0F9F
	ret
;
; init function.
;	
Init_WFTable:
	mvi	a,0FFh
	sta	V_fOK2ProcessAcq
	xra	a
	sta	V_ValidWFs+3
	xra	a
	sta	V_ValidWFs+2 		;set to FALSE
	xra	a
	sta	V_ValidWFs+1
	xra	a
	sta	V_ValidWFs
	lxi	h,V_WFTable			;store &V_WFTable in V_pDispWF
	shld V_pDispWF
	mvi	a,01h
	sta	V_ChannelMode
;	
; clear 4th byte in each table entry	
;
	mvi	b,04h				;loop counter
	lxi	d,08h				;entry size
	lxi	h,V_WFTable+4		;4 entries table pointer, 4th byte
	xra	a
$$Loop:
	mov	m,a
	dad	d					;update table pointer
	dcr	b
	jp	$$Loop
	call Main_Action_10
	ret
;
; in
; out A 1 or 3
;	
GetWFArea:
	lda	V_fSAVEREFShowing	;Flag
	cma
	mov	c,a
	lda	V_fADD
	ana	c
	mov	c,a
	lda	V_fCH1
	mov	b,a
	lda	V_fCH2
	ora	b
	ana	c
	jp	L0FF4
	mvi	a,03h
	ret
L0FF4:	mvi	a,01h
	ret
;
GPIBInterrupt:
	push psw
	push b
	push d
	push h
	rim
	ani	07h
	ori	09h
	sim
	ei
	xra	a
	sta	V_GPIB_Bool9
	sta	V_GPIB_Bool4
	sta	V_GPIB_Bool3
	call Get_GPIB_Status
	lda	V_GPIB_Bool6
	ana	a
	mvi	a,7Bh
	jp	L102A
	xra	a
	sta	V_GPIB_Bool5
	mvi	a,2Bh
	cma
	call Update_DEV_WIFCTL_and
	mvi	a,80h
	cma
	call Update_DEV_FPC_and
	mvi	a,7Ah
L102A:
	call AddMainAction
	call Remove_GPIB_Actions ;remove certain GPIB actions
	di
	pop	h
	pop	d
	pop	b
	pop	psw
	ei
	ret
;
; V_pWFTable3 is local
;
RenderCursorLine_0:
	lda	V_FPC
	ani	0CFh				;11001111 Clr CH1POS & CH2POS
	sta	V_FPC
	lda	V_CursorMode
	cpi	03h
	jnz	L10F6
	lda	V_PrimaryWF			;base 1
	dcr	a					;base 0
	rlc						;x8
	rlc
	rlc
	lxi	h,V_WFTable			;p = V_WFTable[V_PrimaryWF]
	add	l
	mov	l,a
	xra	a
	adc	h
	mov	h,a
	shld V_pWFTable3
	lxi	d,05H
	dad	d
	mov	a,m					;A = *(p+5)
	ani	04h
	cpi	04h
	jnz	L106C
	xra	a
	sta	V_fShortWF
	jmp	L1071
L106C:	mvi	a,01h
	sta	V_fShortWF
L1071:
	lhld V_TimeCursorPos
	shld V_TmpCursorPos
	lhld V_TimeCursorPos+2
	shld V_TmpCursorPos+2
	call GetWFExpandVal
	call AdjustCursorTime
	lhld V_TmpCursorPos
	call ConvertTimePos2VoltsPos
	shld V_LineCursorPos
	lhld V_TmpCursorPos+2
	call ConvertTimePos2VoltsPos
	shld V_LineCursorPos+2
	lda	V_fSnappedCursor
	ral
	jnc	L10C8
	lhld V_pWFTable3
	lxi	d,S_GNDREF
	dad	d
	mov	a,m					;A = *(p+S_GNDREF)
	rlc
	rlc
	mov	b,a
	ani	03h
	mov	d,a
	mov	a,b
	ani	0FCh
	mov	e,a
	ana	a
	jz	L10C5
	lda	V_fCursor1Snapped
	ral
	lxi	h,V_LineCursorPos
	jc	L10BF
	lxi	h,V_LineCursorPos+2
L10BF:
	mov	m,e
	inx	h
	mov	m,d
	jmp	L10C8
L10C5:
	call ClrCursorSnap
L10C8:
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	L1102
	lhld V_pWFTable3		;p = (V_pWFTable3)
	lxi	d,S_CHANMODE		;*(p+S_CHANMODE)
	dad	d
	mov	a,m
	ani	01h					;is this Channel 1
	jz	L10E5				;no
	lda	V_FPC
	ori	20h					;00100000 Set CH1POS
	sta	V_FPC
L10E5:	mov	a,m				;*(p+4)
	ani	02h					;is this Channel 2
	jz	L1102				;no
	lda	V_FPC
	ori	10h					;00010000 set CH2POS
	sta	V_FPC
	jmp	L1102
L10F6:
	lhld V_VoltsCursorPos
	shld V_LineCursorPos
	lhld V_VoltsCursorPos+2
	shld V_LineCursorPos+2
L1102:
	call StrobeDisplayRAM_0	;result A unused
	lda	V_CursorLine
	cpi	01h
	jnz	L1125
	lhld V_LineCursorPos
	shld V_ThisLineCursorPos
	lda	V_fFirstCursorActive ;boolean test
	ral
	jnc	L1132
L111A:	lda	V_CONTRL
	ori	80h					;10000000 ACTIVEL
	sta	V_CONTRL
	jmp	L1132
L1125:	lhld V_LineCursorPos+2
	shld V_ThisLineCursorPos
	lda	V_fFirstCursorActive ;boolean test
	ral
	jnc	L111A
L1132:	lda	V_ThisLineCursorPos
	ani	03h
	mov	b,a
	lda	V_DISREG
	ani	7Ch
	ora	b
	sta	V_DISREG
	lhld V_ThisLineCursorPos
	mov	a,l
	ani	0FCh
	ora	h
	rrc
	rrc
	sta	DEV_LINER
	call SetUpLineCursor_0
	lda	V_CursorMode
	cpi	03h
	jnz	L1162
	lhld V_pWFTable3
	inx	h
	inx	h
	inx	h
	mov	a,m					;A = *(p+S_VGAIN)
	jmp	L1164
L1162:	mvi	a,0F0h			;11110000
L1164:	sta	DEV_VGAIN
	call EnableLineCursor_0
	ret
;
; in HL
;	
ConvertTimePos2VoltsPos:
	dcx	h					;bad move if HL==0 or very tricky
	lda	V_fShortWF
	cpi	00h
	jnz	L1178
	mov	a,l					;save
	jmp	L117D
L1178:	mov	a,h
	rar						;/2
	mov	h,a
	mov	a,l
	rar						;/2
L117D:
	push	psw				;save A
	ani	0FEh				;11111110
	mov	l,a
	mvi	a,03h				;00000011
	ana	h					;H &= 03
	mov	h,a
	xchg					;save HL in DE, max value is 0x3FE		
	lda	V_PrimaryWF			;WaveForm Area index 1..4
	dcr	a					;rebase
	add	a					;*2
	mov	c,a
	mvi	b,00h
	lxi	h,DisplayRamTable	;p = &DisplayRamTable[index]
	dad	b
	mov	c,m					;HL = *(word*)p
	inx	h
	mov	h,m
	mov	l,c
	dad	d					;p = HL + DE
	dcx	h
	dcx	h
	mov	c,m					;C = *(byte *)(p - 2)
	mvi	b,00h
	pop	psw					;restore A
	rar						;test bit 0
	jnc	L11A9
	inx	h
	inx	h
	mov	l,m					;L = *p
	mvi	h,00h
	jmp	L11AD
L11A9:
	lxi	h,0000h
	dad	b					;HL = BC;
L11AD:
	dad	b					;HL += BC
	dad	h					;HL += HL
	ret
;
; returns A
;
StrobeDisplayRAM_0:
	lxi	h,DisplayRamTable	;data in ROM so invariant
	mov	e,m					;p = *(DisplayRamTable) : RAM_DISPLAY (0xA000)
	inx	h
	mov	d,m
	inx	d
	ldax d					;A = *p
	ret
;	
SetUpLineCursor_0:
	lxi	h,V_DISREG
	mvi	a,40h
	ori	20h
	cma
	ana	m
	ori	10h
	sta	V_DISREG
	mvi	a,3Dh				;00111101
	sta	DEV_HGAIN
	ret
;
EnableLineCursor_0:
	xra	a
	sta	DEV_JITTER
	lda	V_FPC
	sta	DEV_FPC
	lda	V_CONTRL
	ani	0EFh				;11101111 Clr LINECUR
	sta	DEV_CONTRL
	ret
;
; Freeze WFs (SAVE)
;
; V_pWFTbl_7, V_Index_7, V_Tmp_7 are local to this large function
; V_AcquiredTB_7 local
;
Display_Action_7_0:
	mvi	a,01h
	sta	V_Index_7			;V_Index_7 = 1..3
	lxi	h,V_WFTable
	shld V_pWFTbl_7			;V_pWFTbl_7 = &V_WFTable Updated each loop
; Loop 3 times
L11EB:
	lhld V_Index_7
	mvi	h,00h
	lxi	d,V_ValidWFs-1		;table of 4 booleans
	dad	d
	mov	c,m
	mov	a,c					;boolean test
	ral
	jnc	L1209				;done if FALSE
; boolean == TRUE	
	lhld V_pWFTbl_7
	inx	h					;A = *(p + 4)
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	80h					;10000000
	cpi	00h
	jz	L120C				;done if bit 7 == 0
L1209:
	jmp	L12FA				;done
L120C:
	lhld V_pWFTbl_7
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m					;A = *(p + S_CHANMODE)
	ani	03h					;00000011
	cpi	02h
	jnz	L1224
	lda	V_CH2_Info
	sta	V_Tmp_7	
	jmp	L122A
L1224:
	lda	V_CH1_Info
	sta	V_Tmp_7
L122A:
	lhld V_pWFTbl_7
	xchg					;move to DE
	lxi	h,S_STATUS
	dad	d
	mov	a,m					;A = *(p+S_STATUS)
	ani	03h					;00000011
	cpi	03h
	jnz	L1258
; A == 3	
	lxi	h,S_VOLTS		;DE still V_pWFTbl_7
	dad	d
	mov	a,m					;A = *(p+S_VOLTS)
	ani	1Fh					;00011111	isolate Voltage
	cpi	04h
	jnc	L1258
	mov	b,a					;save
	lda	V_Tmp_7				;just set before from V_CH2_Info or V_CH1_Info
	ani	1Fh					;00011111	isolate Voltage
	mov	c,a
	mov	a,b
	sub	c					;B - C
	mov	l,a
	mvi	a,0C0h				;11000000
	call ShiftR_A_L_times	;preserves DE result in A
	jmp	L1263
L1258:
	lxi	h,S_VOLTS		;DE still V_pWFTbl_7			
	dad	d
	mov	b,m					;B = *(p+S_VOLTS)
	lda	V_Tmp_7
	call ComputeVGAIN 		;result in A
L1263:	
	lhld V_pWFTbl_7
	inx	h
	inx	h
	inx	h
	mov	m,a					;*(p+S_VGAIN) = A
	lda	V_ATimebaseActive
	ral
	jnc	L127A
	lda	V_ATIME
	sta	V_Tmp_7
	jmp	L1280
L127A:	lda	V_BTIME
	sta	V_Tmp_7				;A or B TIME/DIV
L1280:	lxi	d,06H
	lhld V_pWFTbl_7			;p
	dad	d
	mov	a,m					;A = *(p+6)
	mvi	l,TB20
	call Get_Minimum
	sta	V_AcquiredTB_7		;store result
	lhld V_pWFTbl_7			;p
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m					;A = *(p+5)
	ani	04h					;00000100
	cpi	00h
	jnz	L12A8
	mvi	a,0FFh
	sta	V_fChopped	
	jmp	L12AC
L12A8:	xra	a
	sta	V_fChopped
L12AC:
	lhld V_Index_7			;current loop index 1..3
	mvi	h,00h
	lxi	d,V_Jitter_Tbl-1
	dad	d
	mov	a,m					;A = V_Jitter_Tbl[V_index]
	sta	V_Jitter
	lda	V_AcquiredTB_7
	mov	b,a
	lhld V_pWFTbl_7			;p
	lxi	d,05H
	dad	d
	mov	a,m					;A = *(p+5)
	ani	03h					;00000011
	mov	c,a
	lda	V_Index_7
	mov	l,a
	lda	V_Tmp_7
	call TimeExpandWF		;args A, B, C, L
	lhld V_pWFTbl_7			;p
	inx	h
	inx	h
	mov	m,a					;*(p+2) = A
	lda	V_AcquiredTB_7
	lxi	h,V_Tmp_7			;A or B TIME/DIV
	cmp	m
	jnc	L12EE
	lda	V_Index_7
	sta	V_CurrWF			;current WaveForm area
	call Display_Action_5
	jmp	L12FA
L12EE:	lda	V_Index_7
	add	a					;x2
	add	a					;x4
	add	a					;x8
	add	a					;x16
	ori	01h					;00000001
	call AddDisplayAction
L12FA:
	lxi	h,V_Index_7			;(V_Index_7)++
	inr	m
	lxi	d,08h
	lhld V_pWFTbl_7			;(V_pWFTbl_7) += 8
	dad	d
	shld V_pWFTbl_7
	mvi	a,03h
	lxi	h,V_Index_7
	cmp	m					;3 - V_Index_7
	jnc	L11EB				;loop if V_Index_7 <= 3
	ret
;
; Time Expand WFs if necessary
;
; in A,B,C,L
; out A
; V_RAM_Area, V_pDest_4, V_deltaTB_4, V_TargetTB_4, V_AcquiredTB_4 are local
; V_pSrc_4 local
;
TimeExpandWF:
	sta	V_TargetTB_4		;save A
	mov	a,b
	sta	V_AcquiredTB_4		;save B
	mov	a,c
	sta	V_DigitalMode_4		;save C
	mov	a,l
	sta	V_WF_4a				;save L
	lda	V_AcquiredTB_4
	lxi	h,V_TargetTB_4
	cmp	m					;V_AcquiredTB_4 - V_TargetTB_4. B - A
	jnc	L147D				;exit if B >= A. Return 125 or 250
	lda	V_ACQ_Mode
	ani	0BFh				;10111111 Clr STORON
	sta	DEV_WRSR1			;set sampling bits
	lda	V_ACQ_Mode			;toggle STORON
	sta	DEV_WRSR1			;set sampling bits
	lda	V_WF_4a				;input arg L
	add	a					;x2
	mov	b,a					;save index*2
	mov	l,b					;compute p
	mvi	h,00h
	lxi	d,ScratchRamTable-2
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	xchg
	shld V_pSrc_4			;V_pSrc_4 = *(word *)p
	mov	l,b					;restore index*2
	mvi	h,00h
	lxi	d,SYSRAM_Area-2		;Rom based Ram Areas table
	dad	d
	mov	e,m					;get Ram area address
	inx	h
	mov	d,m
	xchg
	shld V_RAM_Area			;store Ram area address
	lda	V_TargetTB_4
	lxi	h,V_AcquiredTB_4
	sub	m					;V_TargetTB_4 - V_AcquiredTB_4
	mvi	l,06h
	call Get_Smaller
	mov	b,a					;smaller value to B
	sta	V_deltaTB_4
	mov	a,b	
	sta	V_deltaTB_4_2
	lda	V_deltaTB_4
	ani	01h					;00000001
	mvi	l,00h
	call Test_Different		;returns boolean
	sta	V_oddFlg_4			;TRUE if V_deltaTB_4, bit 0 was 1
	lda	V_AcquiredTB_4
	inr	a
; A = remainder of (V_AcquiredTB_4+1)/3 + V_deltaTB_4
$$L:
	sui	03h					;A - 3
	jp	$$L
	adi	03h
	lxi	h,V_deltaTB_4		;p
	add	m					;A += *p
	mvi	b,00h
; divide A by 3, result in B
$$L1:
	inr	b
	sui	03h					;A - 3
	jnc	$$L1
	mov	a,b					;result always >= 1
	lxi	d,HGAIN_Tbl1-1
	rst	1					;Get *(DE + A)
	sta	V_LocalHGAIN_4		;save
	mov	a,b					;result again
	lxi	d,Nr_Samples_Tbl-1
	rst	1					;Get *(DE + A)
	sta	V_samplesCnt		;save. Used by Do_Interpolation and Do_Interpolation_2
	lxi	h,020H
	shld V_Cnt2
	lda	V_fChopped			;boolean test
	ral
	jnc	L13CC
	lda	V_LocalHGAIN_4
	mvi	l,01h
	call ShiftR_A_L_times
	sta	V_LocalHGAIN_4
	lda	V_samplesCnt
	ana	a					;test
	jnz	L13C2
	stc						;Results in 0x80
L13C2:	rar					; A >> 1
	sta	V_samplesCnt
	lxi	h,010h
	shld V_Cnt2
L13CC:
	lda	V_oddFlg_4			;boolean test
	ral
	jnc	L13DC
	lhld V_RAM_Area
	shld V_pDest_4	
	jmp	L13E2
L13DC:	lxi	h,RAM_ACQ
	shld V_pDest_4
L13E2:	lhld V_pSrc_4
	xchg
	lhld V_Cnt2
	dcx	h
	dcx	h
	dcx	h
	dcx	h
	dad	d
	xchg
	lhld V_pDest_4
	xchg
	lda	V_DigitalMode_4
	mov	b,a
	lda	V_samplesCnt
	call Do_Interpolation
	lxi	h,V_deltaTB_4_2
	dcr	m
	lda	V_deltaTB_4_2
	cpi	00h
	jz	L1476
	lhld V_pDest_4
	shld V_pSrc_4
	lda	V_oddFlg_4
	ral
	jnc	L141F
	lxi	h,RAM_ACQ
	shld V_pDest_4
	jmp	L1425x
L141F:	lhld V_RAM_Area
	shld V_pDest_4
L1425x:	lhld V_pSrc_4
	xchg
	lhld V_Cnt2
	dcx	h
	dad	d
	xchg
	lhld V_pDest_4
	xchg
	lda	V_DigitalMode_4
	mov	b,a
	lda	V_samplesCnt
	call Do_Interpolation_2
	lxi	h,V_deltaTB_4_2
	dcr	m
Local1441:	lda	V_deltaTB_4_2
	cpi	00h		
	jz	L1476
	lhld V_pSrc_4
	xchg
	lhld V_pDest_4
	shld V_pSrc_4
	xchg
	shld V_pDest_4
	lhld V_pSrc_4
	xchg
	lhld V_Cnt2
	dcx	h
	dad	d
	xchg
	lhld V_pDest_4
	xchg
	lda	V_DigitalMode_4
	mov	b,a
	lda	V_samplesCnt
	call Do_Interpolation_2
	lxi	h,V_deltaTB_4_2
	dcr	m
	jmp	Local1441
L1476:	lda	V_LocalHGAIN_4
	ret
	jmp	ComputeVGAIN
L147D:	lda	V_fChopped
	ral
	jnc	L148A
	mvi	a,7Dh				;125
	ret
	jmp	ComputeVGAIN
L148A:	mvi	a,0FAh			;250
	ret
;
; in A, B
; out A
;	
ComputeVGAIN:
	ani	1Fh					;00011111 mod 32
	mov	c,a					;save
	mov	a,b
	ani	1Fh					;00011111 mod 32
	mov	d,a					;save
	cpi	04h
	jnc	L149B
	mvi	d,04h				;if A > 4
L149B:	mov	a,d				;A now <= 4
	sub	c
	jm	L14BC
	jz	L14BC
	cpi	03h
	jc	L14AA
	mvi	a,03h				;if A < 3
L14AA:	mov	b,a				;B [Delta] now 1,2 or 3
	mov	a,d
L14AC:	sui	03h				;repeatedly subtract 3
	jp	L14AC				;until A < 0
	adi	03h					;now 0..2
	mov	c,a
	add	a					;x2
	add	c					;x3
	add	b					;+B 
	lxi	d,VGAIN_Tbl-1		;9 entries
	rst	1					;Get *(DE + A)
	ret
L14BC:
	mvi	a,0F0h				;11110000
	ret
;
; in A. From AddMainAction: "add action A to action queue"
; this process cannot be interrupted while adding to the Action queue
; V_MainActionStart and V_MainActionEnd are initiallized to 1 (means nothing in table)
;
AddMainAction_0:
	mov	c,a					;move action code to C
	rim						;read interrupt mask
	di
	sta	V_Saved_Int_Mask_2
	lxi	d,V_MainActionTbl-1		;Action Table ptr. Index 1-16
	lda	V_MainActionEnd		;table end index
	mov	b,a
	lda	V_MainActionStart	;table start index.
	sta	V_ActionLoopIdx		;loop index
$$L:
	lda	V_ActionLoopIdx		;load loop index
	cmp	b					;compare to end index
	jz	L14E7				;same. end of table reached
	ani	0Fh					;Circular buffer index
	inr	a					;range 1-16
	sta	V_ActionLoopIdx		;save loop index
	rst	1					;Get *(DE + A)
	cmp	c					;Compare with input action code
	jz	L14FB				;done if match. C already in table
	jmp	$$L					;loop
L14E7:						;no match. Add action to table
	mov	a,b					;ring buffer end index.
	ani	0Fh
	inr	a
	sta	V_MainActionEnd		;update table end index
	lxi	h,V_MainActionStart	;table start index ptr
	cmp	m					;overflow if the same
	jnz	L14F6
	rst	6					;HALT
L14F6:	mov	l,a				;compute ptr to new action entry
	mvi	h,00h
	dad	d
	mov	m,c					;add action to Action table
L14FB:	lda	V_Saved_Int_Mask_2
	ani	08h					;check if interrupts were enabled before (IE = bit 3)
	jz	L1504
	ei
L1504:	ret
;
; init Action Table
;
Init_Action_Table:	mvi	a,01h
	sta	V_MainActionStart
	mvi	a,01h	
	sta	V_MainActionEnd
	ret
;
; lots of WaveForm copying if SAVEREF pushed
;	
Display_Action_6_0:
	lda	V_fSAVEREFPushed	;boolean test
	ral
	jnc	L1602	
	call GetWFArea		;returns 1 or 3 in A
	sta	V_WF_6				;V_WF_6 is local
	lda	V_WF_6
	xri	02h					;^00000010: 1->3 3->1
	sta	V_FlippedWF_6		;V_FlippedWF_6 is local
	lda	V_WF_6				;1 or 3
	lxi	d,DisplayRamTable-2	;A = base 1
	call Get_Word_From_Table
	push h
	lda	V_FlippedWF_6		;flipped result
	lxi	d,DisplayRamTable-2	;A = base 1
	call Get_Word_From_Table
	pop	d
	lxi	b,0400H				;copy 2 WaveForms
	call Copy_Bytes 		; 1024 bytes *DE to *HL
	lda	V_WF_6				;1 or 3
	lxi	d,ScratchRamTable-2
	call Get_Word_From_Table
	push h
	lda	V_FlippedWF_6		;flipped result
	lxi	d,ScratchRamTable-2
	call Get_Word_From_Table
	pop	d
	lxi	b,0200H				;copy 1 waveform
	call Copy_Bytes  		; 512 bytes *DE to *HL
	lhld V_WF_6				;LSB only 1 or 3. Ignore MSB
	dcr	l					;base 0
	mov	a,l
	mvi	l,03h
	call ShiftL_A_L_times	;times 8
	inr	a					;+1
	mov	l,a					;compute table ptr
	mvi	h,00h
	lxi	d,V_WFTable-1
	dad	d
	shld V_Ptr1_6			;V_Ptr1_6 is local: &V_WFTable[V_WF_6]
	lhld V_FlippedWF_6		;flipped result
	dcr	l
	mov	a,l
	mvi	l,03h
	call ShiftL_A_L_times	;times 8
	inr	a					;+1
	mov	l,a					;compute table ptr
	mvi	h,00h
	lxi	d,V_WFTable-1
	dad	d
	shld V_Ptr2_6			;V_Ptr2_6 is local: &V_WFTable[V_FlippedWF_6]
	lhld V_Ptr1_6			;p
	inx	h					;p += 5: S_STATUS
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m					;V_WFTable[V_WF_6].S_STATUS
	ani	04h					;00000100 LONGWFMASK
	cpi	04h					;test bit 2
	jnz	L159F
	mvi	a,8
	sta	V_CopySize_6		;V_CopySize_6 is local
	xra	a
	sta	V_Flg_6				;V_Flg_6 is local
	jmp	L15A9
L159F:	mvi	a,16
	sta	V_CopySize_6
	mvi	a,0FFh
	sta	V_Flg_6
L15A9:
	lhld V_Ptr1_6
	xchg
	lhld V_Ptr2_6
	lda	V_CopySize_6
	mov	c,a
	mvi	b,00h
	call Copy_Bytes 		;BC bytes *DE to *HL
	mvi	a,0FFh
	sta	V_ValidWFs+2		;set to TRUE
	mvi	a,0FFh	
	sta	V_ValidWFs			;set to TRUE
	lda	V_Flg_6
	sta	V_ValidWFs+3
	lda	V_Flg_6
	sta	V_ValidWFs+1
; set bit 7 in V_WFTable+1[3].field
	lxi	h,V_WFTable+2*WFENTRYSIZE
	inx	h					;p += 4
	inx	h
	inx	h
	inx	h
	xchg
	mov	h,d					;HL = DE
	mov	l,e
	mov	a,m					;*p
	ori	80h					;10000000	bit 7
	xchg
	mov	m,a					;update memory
	lda	V_Flg_6				;boolean test
	ral
	jnc	L15F4
; set bit 7 in V_WFTable+1[4].field	
	lxi	h,V_WFTable+3*WFENTRYSIZE ;ptr to first byte of fourth entry
	inx	h					;p += 4
	inx	h
	inx	h
	inx	h
	xchg
	mov	h,d					;HL = DE
	mov	l,e
	mov	a,m					;*p
	ori	80h					;10000000 bit 7
	xchg					;HL,DE identical
	mov	m,a					;update memory
L15F4:
	mvi	a,MAIN_ACTION_7_ID
	call AddMainAction
	xra	a
	sta	V_fSAVEREFPushed	;clear V_fSAVEREFPushed Flag
	mvi	a,0FFh
	sta	V_fSAVEREFShowing	;set to TRUE
L1602:
	ret
;
; V_WFTable is a table of 4 entries, each entry 8 bytes, related to Displaying the WaveForm
; P1 not aligned with start of table
; Loop through table, test bit 7 field x, clear field y and corresponding WFBooleans if set
;	
RemoveREFWFfromWFTbl:
	mvi	b,04h				;loop 4 times 4,3,2,1
	lxi	h,V_WFTable+4		;p1
	lxi	d,V_ValidWFs 		;p2
L160B:	mov	a,m				;*p1
	ana	a					;test bit 7
	jp	L1622_0				;jmp if bit 7 clr
	ani	7Fh					;01111111 Clear bit 7
	mov	m,a					;V_WFTbl[x].S_CHANMODE
	inx	h					;++p1
	mov	a,m					;update V_WFTbl[x].S_STATUS
	ori	80h					;10000000 Set bit 7
	mov	m,a					;update *p1
	dcx	h
	dcx	h
	dcx	h
	dcx	h
	xra	a
	mov	m,a					;V_WFTable[x].S_GNDREF = 0
	inx	h					;--p1 (back to S_CHANMODE)
	inx	h
	inx	h
	stax d					;V_ValidWFs[x] = FALSE
L1622_0:
	inx	d					;++p2
	mov	a,b					;save loop cntr
	lxi	b,08h
	dad	b					;p1 += 8 next entry
	mov	b,a					;restore
	dcr	b
	jnz	L160B
;	
	lda	V_fADD
	mov	h,a
	lda	V_fCH1
	mov	b,a
	lda	V_fCH2
	ora	b
	ana	h
	jz	L165C
;
; copy entry 3 to entry 1 (base 1)
;
	lxi	h,V_WFTable+2*WFENTRYSIZE
	lxi	d,V_WFTable
	lxi	b,WFENTRYSIZE
	call Copy_Bytes  		;8 bytes *DE to *HL
	xra	a
	sta	V_ValidWFs			;V_ValidWFs = V_ValidWFs+1 = FALSE;
	sta	V_ValidWFs+1
;
; Clr Table[0] S_GNDREF and Table[1] S_GNDREF
;
xxxx
	lxi	h,V_WFTable+S_GNDREF ;p = &V_WFTable+S_GNDREF
	mov	m,a					;*p = 0
	lxi	h,V_WFTable+WFENTRYSIZE+S_GNDREF ;p = &V_WFTable+WFENTRYSIZE+S_GNDREF
	mov	m,a					;*p = 0
	cma						;0->0xff
	sta	V_ValidWFs+2		;V_ValidWFs+2 = TRUE
L165C:
	mvi	a,MAIN_ACTION_7_ID
	call AddMainAction
	ret
;
; Remove certain GPIB entries from the Action Buffer
;	
Remove_GPIB_Actions_0:		;from ROM575	
	xra	a
	sta	V_Lcl_fActionRemoved ;set to FALSE
	lda	V_MainActionStart	;starts at 1
L1669:
	mov	b,a
	lxi	h,V_MainActionEnd
	cmp	m					;end index
	jz	L1697				;jump if reached
	lxi	d,V_MainActionTbl-1
	rst	1					;Get *(DE + A). HL points to entry
	cpi	80h					;A-0x80
	jc	L1690				;skip if A < 0x80 (not GPIB)
	mov	c,a					;A >= 0x80. Save
	lda	V_Lcl_fActionRemoved
	ana	a					;Boolean test
	jm	L168E
	mvi	a,0FFh				;set to TRUE
	sta	V_GPIB_ActionWasRemoved	;GPIB related
	sta	V_Lcl_fActionRemoved
	mov	a,c
	sta	VAR_800E
L168E:	mvi	m,00h			;clear table entry
L1690:	mov	a,b
	ani	0Fh					;mod 16
	inr	a
	jmp	L1669				;loop
L1697:	ret
;
; input A, DE. Output HL
;
Get_Word_From_Table_0:
	add	a					;x2
	mov	l,a
	mvi	h,00h
	dad	d					;HL = DE + 2 * A
	mov	e,m					;get word from table in DE
	inx	h
	mov	d,m
	xchg					;HL <-> DE
	ret
;
; Update Numeric Display Window. Called from Timer
;	
RefreshNumWin:
	lda	V_LED_Digit			;range 1..4
	ani	03h
	inr	a
	sta	V_LED_Digit
	mov	e,a					;save
	lxi	h,V_DecPntDigit
	cmp	m
	lda	V_Curr_LEDRO
	jnz	L16B8
	ori	10h					;00010000 set bit 4: Decimal Point
L16B8:	mov	b,a
	sta	DEV_LEDRO
	mvi	d,00h
	lxi	h,V_NumWinBuf-1
	dad	d					;E is stil V_LED_Digit
	mov	a,m					;get value
	sta	DEV_SVNSEG
	dcr	e				
	mvi	a,01h
	jz	L16D1
;loop E-1 times	
L16CC:	add	a
	dcr	e
	jnz	L16CC
L16D1:	ora	b
	sta	DEV_LEDRO
	ret
;
; init function. 
;	
ClrNumWin:
	mvi	a,0F0h				;11110000
	sta	DEV_LEDRO
;
;     List of assignments for LEDRO
;             01 IS DIGIT 1 MSD
;             02 IS 2ND MSD
;             04 IS 3RD MSD
;             08 IS LSD
;             10 IS DECIMAL POINT
;             20 IS SCALE TOP
;             40 IS SCALE MIDDLE
;             80 IS SCALE BOTTOM
;
	mvi	a,0FFh
	sta	V_NumWinBuf+3
	mvi	a,0FFh
	sta	V_NumWinBuf+2
	mvi	a,0FFh
	sta	V_NumWinBuf+1
	mvi	a,0FFh
	sta	V_NumWinBuf
	mvi	a,0E0h				;00001110
	sta	V_Curr_LEDRO
	mvi	a,05h
	sta	V_DecPntDigit
	ret
;
; Test for Acquisition Complete
;
Main_Action_3:
	di
	lda	V_fSAVEREFPushed	;boolean test
	ral
	jnc	L1712	
	lda	V_DigitalMode
	cpi	DIGITAL_ENV
	jz	L1712	
	lda	V_DigitalMode
	cpi	DIGITAL_AVG
	jnz	L1715
L1712:	jmp	L1720
;
; (V_DigitalMode != DIGITAL_ENV) && (V_DigitalMode != DIGITAL_AVG)
;
L1715:	lda	DEV_STOPDIS		;reading causes Display to stop
	mvi	a,06h
	call AddDisplayAction
	call Display_Interrupt
L1720:	ei
	lda	V_fOK2ProcessAcq	;boolean test
	ral
	jnc	L1732
	lda	DEV_RDSTAT			;Time Base Status Register
	ani	01h					;00000001 ACQUIRE (Active Low)
	cpi	01h
	jz	L1735				;jmp if not active
L1732:	jmp	L174D
L1735:	lda	V_fChopped		;boolean test
	ral
	jnc	L1745
	mvi	a,0FEh				;11111110 Clr CH2
	lxi	h,V_ACQ_Mode
	ana	m
	sta	DEV_WRSR1			;set sampling bits
L1745:
	mvi	a,MAIN_ACTION_4_ID
	call AddMainAction
	jmp	L1752
L174D:
	mvi	a,MAIN_ACTION_3_ID
	call AddMainAction
L1752:	ret
;
; Program Start. No real stack yet.
;
Start:
	nop
	nop
	nop
	lxi	h,L1FFC				;end of ROM565
	lxi	d,0FFFFh
	lxi	b,01FFFh			;C = end byte address. B = MSB of ROM checksum address
	mov	c,d
	lxi	sp,L1769			;continuation address
;
; validate check bytes. Entered twice, once for each ROM
; HL points to end of ROM to test
;	
ROM_Signature:
	mov	a,m					;get check value 0x01
	inx	h					;p++
	xra	m					;xor with 0xfe -> 0xff
	inr	a					; -> 0
	rz						;ok, continue
	hlt						;fail
L1769:	dw	L176B			;continuation address
;
; checksum
;	HL = L1FFC+1 of L3FFC+1
;	BC = 0x1fff or 0x3f1f
;
L176B:
	lxi	sp,L1793			;continuation address
;
; entered twice, once for each ROM
; check 0x100 or 0xe0 bytes
;
ROM_Checksum:
	lxi	d,0000h				;running checksum
L1771:
	stc						;clr carry
	cmc
	xchg
	dad	h
	xchg					;DE = 2 x DE
	mov	a,m
	adc	e
	mov	e,a
	jnc	L177D
	inr	d
L177D:	dcx	h				;p--
	mov	a,h
	cmp	c
	jnz	L1771				;loop until H == C
	mov	h,b					;0x1ffe or 0x3ffe
	mvi	l,0FEh
	mov	a,m					;compare DE with *(word *)HL
	cmp	e
	inx	h
	jnz	L178F
	mov	a,m
	cmp	d
	rz						;continue
;
; FAIL
;
L178F:
	mov	m,d					;store DE
	dcx	h
	mov	m,e
	hlt						;fail
L1793:	dw	L1795			;continuation address
;
L1795:
	lxi	h,L3FFC				;end of ROM575
	lxi	d,01FFFh
	lxi	b,03FFFh			;C = end byte address. B = MSB of ROM checksum address
	mov	c,d	
	lxi	sp,L17A5			;continuation address
	jmp	ROM_Signature		;check ROM575
L17A5:	dw	L17A7			;continuation address
;
L17A7:
	lxi	sp,L17AD			;continuation address
	jmp	ROM_Checksum		;check ROM575
L17AD:	dw	L17AF			;continuation address
;
L17AF:
	lda	DEV_DIPSW			;not complemented
	ani	40h					;switch 7 (1-8). Ram Test
	jnz	Main_Init			;skip Ram Test
	
	mvi	a,0C0h				;11000000
	sta	DEV_FPC
	xra	a
	sta	DEV_LIGHTS
	mvi	a,08h				;00001000
	sta	DEV_SVNSEG
	mvi	a,1Fh				;00011111
	sta	DEV_LEDRO
	mvi	a,10h				;00010000 set STOP128			
	sta	DEV_DISREG
;
; ram test. First test without using the stack.
;	
	mvi	c,00h				;test result
	mvi	b,00h				;for first time through
	mvi	d,0FFh
Ram_Test_1:					;loop twice. Use value in B
	lxi	h,RAM_SYSTEM		;fill RAM 0x8000-0x83ff with 0
	mvi	a,(RAM_SYSTEM_END+1) / 256		;MSB end of RAM_SYSTEM + 1
$$L:						;L17DA:
	mov	m,b					;set RAM
	inx	h
	cmp	h					;(RAM_SYSTEM_END+1) reached test
	jnz	$$L					;loop
	lxi	h,RAM_SYSTEM		;check for 0
$$L3:
	mov	a,m
	cmp	b
	jnz	fail_ram_test
	cma						;fill with complement of B
	mov	m,a
	inx	h
	mvi	a,(RAM_SYSTEM_END+1) / 256 ;end of RAM_SYSTEM + 1
	cmp	h
	jnz	$$L3				;loop
	lxi	h,RAM_SYSTEM_END	;083FFh			;check for 0xff
$$L2:						;L17F4:
	mov	a,m
	cmp	d
	jnz	fail_ram_test
	dcx	h
	mvi	a,7Fh				;beginning of RAM_SYSTEM - 1
	cmp	h
	jnz	$$L2				;loop
	xra	a					;clr a
	cmp	b					;was this the first time through
	jnz	Ram_Test_2			;no, out
	mov	d,a					;d<-0
	cma
	mov	b,a					;b<-0xff
	jmp	Ram_Test_1			;second time through
fail_ram_test:
	mvi	a,01h				;error code
	ora	c
	mov	c,a
	jmp	Ram_Test_2	
Ram_Test_2:	mvi	b,00h
	lxi	h,RAM_SYSTEM
	mvi	a,(RAM_SYSTEM_END+1) / 256	;end of RAM_SYSTEM + 1
;	
L1819:
	mov	m,b
	inx	h
	cmp	h
	jnz	L1819
	lxi	h,RAM_SYSTEM
	xra	a
	cmp	b
	jnz	L182E
	mvi	b,01h
	mov	d,b
	mov	e,b
	jmp	L1832
L182E:	mvi	b,0FEh
	mov	d,b
	mov	e,b
L1832:	mov	m,b
	mov	a,b
	rlc
	mov	b,a
	mvi	a,(RAM_SYSTEM_END+1) / 256
	inx	h
	cmp	h
	jnz	L1832
	lxi	h,RAM_SYSTEM
	mov	a,d
L1841:	mov	b,m
	cmp	b
	jnz	L186B				;error if !=
	rlc
	inx	h
	mov	b,a
	mvi	a,(RAM_SYSTEM_END+1) / 256
	cmp	h
	mov	a,b
	jnz	L1841
	mov	a,d
	rlc
	mov	d,a
	mov	b,a
	lxi	h,RAM_SYSTEM
	cmp	e
	jnz	L1832
	mvi	a,0FEh
	cmp	e
	jz	L1872
	mvi	b,0FFh
	lxi	h,RAM_SYSTEM
	mvi	a,(RAM_SYSTEM_END+1) / 256
	jmp	L1819				;loop
L186B:	mvi	a,02h
	ora	c
	mov	c,a
	jmp	RAMTest_Error
L1872:	xra	a				;check errors
	cmp	c
	jz	L1883
;
; show error on panel
;	
RAMTest_Error:
	mov	a,c					;manual page 5-4
	sta	DEV_SVNSEG
	mvi	a,0E8h				;11101000
	sta	DEV_LEDRO
	jmp	RAMTest_Error		;loop forever
;
; After testing System Ram, use the stack
;
L1883:
	lxi	sp,RAM_MIDDLE
	lxi	h,V_NumWinBuf
	xra	a
	mov	m,a					;clear V_NumWinBuf
	mvi	a,0Fh
	inx	h
	mov	m,a					;set V_NumWinBuf[1] to 0Fh
	inx	h
	mov	m,a					;set V_NumWinBuf[2] to 0Fh
	inx	h
	mov	m,a					;set V_NumWinBuf[3] to 0Fh
	xra	a
	sta	V_NumWinBuf+1		;set V_NumWinBuf[1] to 0 again
	sta	V_RAM_Test_Status
	lxi	h,RAM_SCRATCH
	shld V_Range_Start
	lxi	h,RAM_SCRATCH_END+1
	shld V_Range_End
	call RAM_Test1
	call RAM_Test2
	lda	V_RAM_Test_Status
	sta	V_NumWinBuf+1
	xra	a
	sta	V_NumWinBuf+2
	sta	V_RAM_Test_Status
	lxi	h,RAM_DISPLAY
	shld V_Range_Start
	lxi	h,RAM_DISPLAY_END+1
	shld V_Range_End
	call RAM_Test1
	call RAM_Test2
	lda	V_RAM_Test_Status
	sta	V_NumWinBuf+2
	xra	a
	sta	V_NumWinBuf+3
	sta	V_RAM_Test_Status
	lxi	h,RAM_ACQ
	shld V_Range_Start
	lxi	h,RAM_ACQ_END+1
	shld V_Range_End
	xra	a
	sta	DEV_WRSR1			;Clr sampling bits
	call RAM_Test1
	call RAM_Test2
	lda	V_RAM_Test_Status
	sta	V_NumWinBuf+3
	lxi	h,V_NumWinBuf		;RAM test result table
	mov	a,m
	inx	h
	mov	b,m
	ora	b
	inx	h
	mov	b,m
	ora	b
	inx	h
	mov	b,m
	ora	b
	jz	L190A				;all tests pass.
;
; Error
;
$$L:						;L1904:
	call Update_FP_Display
	jmp	$$L					;L1904
	
L190A:
	jmp	Main_Init			;RAM test done
;
; Ram TEST
; input in V_Range_Start and V_Range_End
;
RAM_Test1:
	mvi	a,13h				;00010011
	sta	DEV_CONTRL
	call Update_FP_Display	;front panel
	mvi	b,00h
	mvi	d,0FFh
L1919:
	lhld V_Range_Start
	lda	V_Range_End+1
L191F:	mov	m,b
	inx	h
	ani	0F0h
	cpi	0A0h
	jnz	L1929
	inx	h
L1929:
	lda	V_Range_End+1
	cmp	h
	jnc	L191F
	call Update_FP_Display	;front panel
	lhld V_Range_Start
;	
L1936:	mov	a,m
	cmp	b
	jnz	L197B
	cma
	mov	m,a
	inx	h
	lda	V_Range_End+1
	ani	0F0h
	cpi	0A0h
	jnz	L1949
	inx	h
L1949:	lda	V_Range_End+1
	cmp	h
	jnz	L1936
	call Update_FP_Display	;front panel
	lhld V_Range_End
	dcx	h
L1957:	mov	a,m
	cmp	d
	jnz	L197B
	dcx	h
	lda	V_Range_Start+1
	ani	0F0h				;11110000
	cpi	0A0h				;10100000
	jnz	L1968
	dcx	h
L1968:	lda	V_Range_Start+1
	cmp	h
	jc	L1957
	call Update_FP_Display	;front panel
	xra	a
	cmp	b
	rnz
	mov	d,a
	cma
	mov	b,a
	jmp	L1919
L197B:	mvi	c,01h
	lda	V_RAM_Test_Status	;set bit 0
	ora	c
	sta	V_RAM_Test_Status
	ret
	ret
;
; more RAM test
; input in V_Range_Start and V_Range_End
;	
RAM_Test2:
	call Update_FP_Display ;front panel
	mvi	b,00h
	lhld V_Range_Start
	lda	V_Range_End+1
L1991:	mov	m,b
	inx	h
	ani	0F0h
	cpi	0A0h
	jnz	L199B
	inx	h
L199B:	lda	V_Range_End+1
	cmp	h
	jnc	L1991
	lhld V_Range_Start
	xra	a
	call Update_FP_Display	;front panel
	cmp	b
	jnz	L19B4
	mvi	b,01h
	mov	d,b
	mov	e,b
	jmp	L19B8
L19B4:	mvi	b,0FEh
	mov	d,b
	mov	e,b
L19B8:	mov	m,b
	mov	a,b
	rlc
	mov	b,a
	lda	V_Range_End+1
	inx	h
	ani	0F0h
	cpi	0A0h
	jnz	L19C8
	inx	h
L19C8:	lda	V_Range_End+1
	cmp	h
	jnc	L19B8
	lhld V_Range_Start
	mov	a,d
	call Update_FP_Display	;front panel
L19D6:	mov	b,m
	cmp	b
	jnz	L1A11
	rlc
	inx	h
	mov	b,a
	lda	V_Range_End+1
	ani	0F0h
	cpi	0A0h
	jnz	L19E9
	inx	h
L19E9:	lda	V_Range_End+1
	cmp	h
	mov	a,b
	jnc	L19D6
	mov	a,d
	rlc
	mov	d,a
	mov	b,a
	lhld V_Range_Start
	call Update_FP_Display	;front panel
	cmp	e
	jnz	L19B8
	mvi	a,0FEh
	cmp	e
	rz
	mvi	b,0FFh
	lhld V_Range_Start
	lda	V_Range_End+1
	call Update_FP_Display	;front panel
	jmp	L1991
L1A11:	mvi	c,02h
	lda	V_RAM_Test_Status	;set bit 1
	ora	c
	sta	V_RAM_Test_Status
	ret
	ret
;
; Front Panel display function during RAM tests
; saves A, HL
;
Update_FP_Display:
	sta	V_Saved_Param1		;store in paramater variables.
	shld V_Saved_Param2
	mvi	a,0E0h				;11100000 Scale LED
	sta	DEV_LEDRO			;stop numeric display
	lxi	h,V_NumWinBuf
	lda	V_FP_Display_Curr_Digit
	add	l
	mov	l,a
	mvi	a,00h				;preserve carry
	adc	h
	mov	h,a
	mov	a,m
	sta	DEV_SVNSEG			;set digit to display
	lxi	h,L1EFE				;compute value for DEV_LEDRO
	lda	V_FP_Display_Curr_Digit
	add	l
	mov	l,a
	mvi	a,00h
	adc	h
	mov	h,a
	mov	a,m
	sta	DEV_LEDRO
	lda	V_FP_Display_Curr_Digit	;range 0..3
	inr	a					;update
	ani	03h					;mod 4
	sta	V_FP_Display_Curr_Digit
	lda	V_Saved_Param1			;reload in paramaters
	lhld V_Saved_Param2
	ret
;
; Interrupt Handler for Position Rate Potentiometer
; Interrupts disabled at this point
;	
CursorPotInt:
	push	psw				;includes A
	push	b
	push d
	push	h
	lda	DEV_PRICLR			;read. Value ignored
	lxi	h,DEV_FPC
	lda	V_FPC
; Toggle	Latch bit
	ori	04h					;00000100 set LATCH
	mov	m,a
	xri	04h					;00000100 clear LATCH bit
	mov	m,a
	lda	DEV_CURSOR
	ani	0Fh					;00001111 Position Rate Count
	mov	b,a					;save
	lda	V_FPC
; Toggle ADVAN bit	
	ori	02h					;00000010 set ADVAN
	mov	m,a
	xri	02h					;00000010 clr ADVAN
	mov	m,a
	lda	DEV_CURSOR
	ani	0Fh					;00001111 Position Rate Count
	rlc						;x 16 Move to upper nibble
	rlc
	rlc
	rlc
	ora	b					;merge with earlier Position Rate Count
	sta	V_PositionRateCount_Values
	lda	V_FPC
; Toggle ADVAN bit	
	ori	02h					;00000010 set ADVAN
	mov	m,a
	xri	02h					;00000010 clr ADVAN
	mov	m,a
	lda	DEV_CURSOR
	ani	0Fh					;00001111
	sta	V_PositionRateCount_Values+1 ;store another sample of Position Rate Count
	lda	V_FPC
; Toggle RESET bit
	ori	08h					;00000010 set RESET
	mov	m,a
	xri	08h					;00000010 clr RESET
	mov	m,a
	lda	V_CursorPot_Delay	;was initialized to 2
	ana	a					;test
	jnz	Local1AB2
; V_CursorPot_Delay now 0 Process Position Rate Interrupt
	mvi	a,MAIN_ACTION_6_ID
	call AddMainAction
	call CursorPotInt2
	jmp	Local1AB6
Local1AB2:
	dcr	a					;V_CursorPot_Delay -= 1
	sta	V_CursorPot_Delay
Local1AB6:
	pop	h
	pop	d
	pop	b
	pop	psw
	ei
	ret
;	
ReadJitter:
	mvi	a,11h
	lxi	h,V_ActualTB_2
	cmp	m
	jc	L1AF3
	lda	DEV_RDJC4			;4 bit jitter correction signal in bits 4-7
	mvi	l,04h
	call ShiftR_A_L_times	;move to bits 0-3
	sta	V_RecorderJitter
	mvi	a,09h
	lxi	h,V_RecorderJitter
	cmp	m					;9 - V_RecorderJitter
	jnc	L1ADE				;jump if 9 <= V_RecorderJitter
	mvi	a,09h				;set maximum value
	sta	V_RecorderJitter
L1ADE:	lda	V_RecorderJitter
	mov	b,a
	rar						;/2
	ani	7Fh					;01111111
	mov	c,a
	mov	a,b
	add	a
	add	a
	mov	b,a
	add	a
	add	b
	add	c
	sta	V_RecorderJitter
	jmp	L1B52
L1AF3:	lda	V_ActualTB_2
	cpi	12h
	jnz	L1B13
	lhld V_Jitter_TB18
	call Update_Jitter_Vars
	shld V_Jitter_TB18
	rar
	ani	7Fh
	mov	b,a
	rar
	rar
	ani	1Fh
	add	b
	sta	V_RecorderJitter
	jmp	L1B52
L1B13:	lda	V_ActualTB_2
	cpi	13h
	jnz	L1B30
	lhld	V_Jitter_TB19
	call Update_Jitter_Vars
	shld	V_Jitter_TB19
	mov	b,a
	rar
	rar
	ani	3Fh
	add	b
	sta	V_RecorderJitter
	jmp	L1B52
L1B30:
	lda	V_ActualTB_2
	cpi	TB20
	jnz	L1B52
	lhld	V_Jitter_TB20
	call Update_Jitter_Vars
	shld	V_Jitter_TB20
	mov	b,a
	rar
	rar
	rar
	ani	1Fh					;00011111
	mov	c,a
	mov	a,b
	add	a
	add	b
	add	c
	sta	V_RecorderJitter
	jmp	L1B52
L1B52:	lda	DEV_RDSTAT
	ani	02h					;00000010 Tst AOM
	cpi	00h
	jz	L1B65
	mvi	a,80h				;10000000
	lxi	h,V_RecorderJitter
	ora	m
	sta	V_RecorderJitter
L1B65:
	lda	V_RecorderJitter
	ret
;
; in HL. Loaded from V_Jitter_TB18, V_Jitter_TB19, V_Jitter_TB20
;	
Update_Jitter_Vars:
	lda	DEV_RDJC8
	mov	b,a
	cmp	h
	jz	$$L
	jc	$$L
	sub	h
	add	l
	mov	l,a
	mov	h,b
	jmp	$$L2
$$L:
	cmp	l
	jz	$$L2
	jnc	$$L2
	mov	a,h
	sub	l
	add	b
	mov	h,a
	mov	l,b
$$L2:
	mov	a,h
	sub	b
	ret
;
; init function. 
;
InitJitterVars:
	xra	a
	sta	V_Jitter_TB20
	xra	a
	sta	V_Jitter_TB19
	xra	a
	sta	V_Jitter_TB18
	mvi	a,0C7h				;11000111
	sta	V_Jitter_TB18+1
	mvi	a,63h				;01100011
	sta	V_Jitter_TB19+1
	mvi	a,27h				;00100111
	sta	V_Jitter_TB20+1
	ret
;
; Start WF Acquisition
;	
Main_Action_2:	
	xra	a
	sta	V_fSkipAcquiredWF
	lda	V_DigitalMode
	cpi	DIGITAL_OFF
	jz	L1BBA				;exit
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	L1BBD				;exit
L1BBA:	jmp	L1D65
;
; V_DigitalMode != 0, != 4
;
L1BBD:	lda	V_fOK2UpdateDispWF
	ral
	jnc	L1D59
	xra	a
	sta	V_fOK2UpdateDispWF
	lda	V_ACQ_Mode
	ani	47h					;01000111 Clr
	sta	V_ACQ_Mode
	lda	V_DigitalMode
	cpi	DIGITAL_ENV
	jnz	$$L					;L1BE0
	lda	V_ActualTB_2
	cpi	12h
	jc	L1BE3
$$L:						;L1BE0:
	jmp	L1BEB
L1BE3:
	lda	V_ACQ_Mode
	ori	20h					;00100000 Set ENVL
	sta	V_ACQ_Mode
L1BEB:
	lda	V_ATimebaseActive
	ral
	jnc	L1C03
	lda	V_ACQ_Mode
	ori	08h					;00001000 Set AGTSEL
	sta	V_ACQ_Mode
	lda	V_ATIME
	sta	V_ActualTB_2
	jmp	L1C09
L1C03:	lda	V_BTIME
	sta	V_ActualTB_2
L1C09:
	lda	V_fPostPreTrigger	;boolean test POST/PRETRIGGER
	ral
	jnc	L1C21
	lda	V_ACQ_Mode
	ori	10h					;00010000 Set PRETRG
	sta	V_ACQ_Mode
	lxi	h,DEV_RSTACQ		;save ptr to DEV_RSTACQ in V_pDEVICE
	shld V_pDEVICE
	jmp	L1C27
L1C21:
	lxi	h,DEV_RSTACQ2		;Save address DEV_RSTACQ2. Tricky move. See page 3-41
	shld V_pDEVICE
L1C27:
	mvi	a,TB20				;00010100
	lxi	h,V_ActualTB_2
	cmp	m
	jnc	$$L
	mvi	a,TB20				;00010100
	sta	V_ActualTB_2
$$L:
	lda	V_ActualTB_2
	cpi	12h					;00010010
	jnc	$$L2
	lda	V_ACQ_Mode
	ori	80h					;10000000 Set LT2
	sta	V_ACQ_Mode
$$L2:
	lhld V_ActualTB_2		;load a whole word shorter than loading just a byte to L
	mvi	h,00h
	lxi	d,Sample_Rate_Table-1				;Table
	dad	d					;index
	mov	a,m
	sta	DEV_WRSR2			;sampling rate to Divide Chain
	lda	V_DigitalMode
	cpi	DIGITAL_NORM
	jnz	$$L3				;L1C74
	lda	V_fCH1
	ral
	jnc	$$L3				;L1C74
	lda	V_fCH2
	ral
	jnc	$$L3				;L1C74
	lda	V_fALT
	cma
	lxi	h,V_fADD
	ora	m
	ral
	jc	L1C77
$$L3:						;L1C74:
	jmp	L1C7F
L1C77:
	mvi	a,0FFh
	sta	V_fAlternating
	jmp	L1C83
L1C7F:
	xra	a
	sta	V_fAlternating
L1C83:
	lda	V_ACQ_Mode
	ani	0F8h				;11111000 Clr ADD|CH1|CH2
	sta	V_ACQ_Mode
	lda	V_fSAVEREFShowing	;boolean test
	ral
	jnc	L1CD6
	lda	V_fADD
	ral
	jnc	L1CA1
	mvi	a,03h
	sta	V_ChannelMode
	jmp	L1CD3
L1CA1:	lda	V_fAlternating
	ral
	jnc	L1CB0
	mvi	a,04h
	sta	V_ChannelMode
	jmp	L1CD3
L1CB0:	lda	V_fCH1
	ral
	jnc	L1CBF
	mvi	a,01h
	sta	V_ChannelMode
	jmp	L1CD3
L1CBF:	lda	V_fCH2
	ral
	jnc	L1CCE
	mvi	a,02h
	sta	V_ChannelMode
	jmp	L1CD3
L1CCE:	mvi	a,01h
	sta	V_ChannelMode
L1CD3:	jmp	L1D37
L1CD6:	lda	V_fAlternating
	ral
	jnc	L1CFE
	lda	V_fADD
	ral
	jnc	L1CEB
	lda	V_fChopped
	ral
	jc	L1CEE
L1CEB:	jmp	L1CF6
L1CEE:	mvi	a,03h
	sta	V_ChannelMode
	jmp	L1CFB
L1CF6:	mvi	a,04h
	sta	V_ChannelMode
L1CFB:	jmp	L1D37
L1CFE:	mvi	b,01h
	lda	V_fCH1
	ana	a
	jp	L1D08
	inr	b
L1D08:	lda	V_fCH2
	ana	a
	jp	L1D11
	inr	b
	inr	b
L1D11:	lda	V_fADD
	ana	a
	mov	a,b
	jp	L1D1B
	adi	04h
L1D1B:
	sta	VAR_8198
	lhld V_ChannelMode
	dcr	l
	mov	a,l
	mvi	l,03h
	call ShiftL_A_L_times
	lxi	h,VAR_8198
	add	m
	mov	l,a
	mvi	h,00h
	lxi	d,ChannelMode_Map-1
	dad	d
	mov	a,m
	sta	V_ChannelMode
L1D37:
	lda	V_ChannelMode
	cpi	04h
	mvi	a,0FFh
	jz	L1D42
	cma
L1D42:
	sta	V_fChopped
	lhld V_ChannelMode
	mvi	h,00h
	lxi	d,ChannelSwitch_Map-1
	dad	d
	mov	a,m
	lxi	h,V_ACQ_Mode
	ora	m
	sta	V_ACQ_Mode
	sta	DEV_WRSR1			;set sampling bits
L1D59:	lhld V_pDEVICE
	mov	a,m
	sta	VAR_8009
	mvi	a,MAIN_ACTION_3_ID
	call AddMainAction
L1D65:	ret
;
; Main loop: scan action table. May be interrupted so table may change.
; Next entry, if any, is actually V_MainActionStart+1
;
Main:
	lda	V_MainActionStart	;circular buffer current index 1-16 range
	mov	l,a					;compute ptr into circular buffer
	mvi	h,00h
	lxi	d,V_MainActionTbl-1
	dad	d
	mvi	m,00h				;clr state table index
	ei
	lxi	h,V_MainActionEnd 	;ptr to circular buffer end index
	cmp	m					;A still start index
	jz	L1DA0
	ani	0Fh
	inr	a
	sta	V_MainActionStart	;update start index
	lxi	d,V_MainActionTbl-1		;get action
	rst	1					;Get *(DE + A)
	ana	a					;test
	jz	L1DA0				;no action
	cpi	78h					;A - 0x78
	jnc	L1D97				;jump if A >= 0x78
	lxi	d,Action_Table1-2
	call Get_Word_From_Table
	rst	4					; Jump to HL
	jmp	L1DA0
L1D97:
	sui	78h					;rebase
	lxi	d,Action_Table2-2
	call Get_Word_From_Table
	rst	4					; Jump to HL
L1DA0:	jmp	Main
;
; Called every 2 mSec (500 Hz)
;
Timer_Interrupt:			;process RST75
	push	b
	push d
	push	h
	push	psw
	mvi	a,01h
	lxi	h,V_TimerCntr		;increment timer counter
	add	m
	sta	V_TimerCntr
	lda	V_TimerCntr2
	lxi	h,V_TimerCntr
	cmp	m
	jnz	L1DCE
	mvi	a,02h
	lxi	h,V_TimerCntr
	add	m
	sta	V_TimerCntr2
	lda	V_CursorMode
	cpi	00h
	jz	L1DCE
	call RefreshNumWin		;Front Panel
L1DCE:	lda	V_TimerCntr3
	lxi	h,V_TimerCntr
	cmp	m
	jnz	L1DE4
	mvi	a,32h
	lxi	h,V_TimerCntr
	add	m
	sta	V_TimerCntr3
	call ReadDeviceControls	;Front Panel
L1DE4:
	lda	V_TimerCntr4
	lxi	h,V_TimerCntr
	cmp	m
	jnz	L1DFC
	mvi	a,64h
	lxi	h,V_TimerCntr
	add	m
	sta	V_TimerCntr4		;V_TimerCntr = V_TimerCntr + 100
	mvi	a,MAIN_ACTION_1_ID
	call AddMainAction
L1DFC:	lda	DEV_CURSOR
	ani	40h					;01000000 Test RATE/POS
	cpi	40h					;01000000
	jnz	L1E61
;
; RATE active
;	
	lda	V_CursorMode
	cpi	04h
	jnz	L1E2A
	lda	V_TimerCntrSweepsStop
	lxi	h,V_TimerCntr
	cmp	m
	jnz	L1E27
	mvi	a,04h
	call AddDisplayAction
	lda	V_TimerCntrSweepsIncrement
	lxi	h,V_TimerCntr
	add	m
	sta	V_TimerCntrSweepsStop
L1E27:	jmp	L1E5E
L1E2A:	lda	V_TimerCntr_Rate_Stop2
	lxi	h,V_TimerCntr
	cmp	m
	jnz	L1E43
	mvi	a,03h
	call AddDisplayAction
	lda	V_TimerCntr
	lxi	h,V_TimerCntrRateInc2
	add	m
	sta	V_TimerCntr_Rate_Stop2
L1E43:
	lda	V_fCursorEdgeTracking ;boolean
	ral						;carry if TRUE
	jnc	L1E5B				;HL is &V_TimerCntrRateInc2 now
	lhld V_CursorEdgeTimeCnt
	lda	V_fAtCursorEdge	;boolean test
	ral
	jnc	L1E58				;jump if FALSE
	inx	h
	jmp	L1E5B
L1E58:	xra	a				;clear
	mov	h,a
	mov	l,a
L1E5B:
	shld V_CursorEdgeTimeCnt
L1E5E:	jmp	L1E67
;
L1E61:	xra	a
	mov	h,a
	mov	l,a
	shld V_CursorEdgeTimeCnt	;clear
L1E67:	pop	psw
	pop	h
	pop	d
	pop	b
	ei
	ret
;
; copy BC bytes from p1(DE) to p2(HL)
;	
Copy_Bytes:
	ldax d
	mov	m,a					;*p2++ = *p1++
	inx	h
	inx	d
	dcx	b					;BC--
	mov	a,c
	ora	b
	jnz	Copy_Bytes
	ret
;
; in A, L. if L > 0 shift left A L times,
; double or shift left
; only ever called with l==3
;
ShiftL_A_L_times:
	mov	c,a
	mov	a,l
	cpi	00h
	mov	a,c
	rm
	rz
$$L:
	add	a
	dcr	l
	jnz	$$L
	ret
;
; in A, L. Return T if A >= L
;
Is_A_LE_L:
	cmp	l					;A - L
	jc	$$L1_				;jmp if A < L
	mvi	a,0FFh				;return TRUE
	ret
$$L1_:
	mvi	a,00h				;return FALSE xra	a!
	ret
;
; input A, L. if L > 0, shift right A L times
;	
ShiftR_A_L_times:
	mov	c,a
	mov	a,l
	cpi	00h
	mov	a,c
	rm
	rz
$$L:
	stc						;clear carry
	cmc
	rar
	dcr	l
	jnz	$$L
	ret
;
; input A, L
; Called ONCE only with L == 6
; find smaller
;	
Get_Smaller:
	mov	b,a					;save
	xra	l					;combine unique bits
	rlc						;<< 1. Carry if (A^L) >= 0x80
	mov	a,b					;restore input
	jc	L1EAE
	cmp	l					;A - L
	jm	L1EB4				;A <= L
	jz	L1EB4
	mov	a,l					;L < A
	ret
; A restored to input value here
L1EAE:	rlc					;<< 1. Carry if (A << 1) >= 0x80
	jc	L1EB4
	mov	a,l					;return L
	ret
L1EB4:	ret
;
; Return minimum in A
; in A, L
;
Get_Minimum:
	cmp	l					;A-L
	jnc	$$L					;jump if A >= L
	ret
	jmp	Test_Different		;unreachable
$$L:
	mov	a,l
	ret
;
; Check if A & L are different
; in A, L. Out A (TRUE or FALSE), Carry
;	
Test_Different:
	sub	l					;A -= L. Carry if L > A
	mvi	a,0FFh
	rlc						;rotate does NOT affect Z. Carry set
	rnz
	mvi	a,00h
	rlc						;carry not set
	ret
;
; Front Panel Push Buttons table
; Each entry maps to Active Low bit set in FP1
; V_DigitalMode is the index into this table 1..5
; 0: OFF 1:NORM 2:ENV 3:AVG 4:SAVE
;	
DIGITAL_Tbl:
	db	00h,0e8h,0ech,0eah,038h
	db	020h,00h,084h,082h,08h
	db	020h,080h,00h,082h,08h
	db	022h,080h,084h,00h,08h
	db	020h,0d8h,0dch,0dah,00h
DIGITAL_Actions_Tbl:	
	dw	Set_Action5_Flg, Add_Action_2, L032C, L0337, L033D, L0344, L034B
HGAIN_Tbl1:
	db	0fah,0c8h,0a0h
Nr_Samples_Tbl:
	db	00h,0ceh,0a4h
VGAIN_Tbl:
	db	078h,03ch,018h,060h,030h,018h,078h,030h,018h
L1EFE:		;front panel display table
	db	0e8h,0e4h,0e2h,0e1h
ChannelMode_Map:	
	db	01h,01h,02h,02h
	db	03h,03h,03h,03h
	db	01h,01h,02h,01h
	db	03h,03h,03h,03h
	db	01h,01h,02h,01h
	db	03h,01h,02h,01h
	db	01h,01h,02h,01h
	db	03h,03h,03h,03h
ChannelSwitch_Map:
	db	02h,01h,06h,03h
;
; sampling period table.
;	
Sample_Rate_Table:
	db	0c1h,0c2h,0e0h,0e1h,0e2h,0f0h
	db	0f1h,0f2h,0f8h,0f9h,0fah,0fch,0fdh
	db	0feh,0bfh,07fh,03fh,0bfh,07Fh,03Fh
;	
Action_Table1:	
	dw	Main_Action_1, Main_Action_2, Main_Action_3, Main_Action_4, Main_Action_5
	dw	Main_Action_6, Main_Action_7, Main_Action_8, Main_Action_9, Main_Action_10

	rept 172
	hlt
	endm

	db	04H
	db	059H
L1FFC:
	db	01H
	db	0FEH
	dw	0275H				;checksum
	
	if 0
;
; Necessary when assembling code for ROM2 separately
;
	ORG	02000H
	INCLUDE Tek468DeviceInfo.inc
	INCLUDE Tek468Variables.inc
;
; Rom565 entry points
;
AddMainAction		equ	0049H
Get_Word_From_Table equ	004FH
SYSRAM_Area			equ	0040H
Display_Action_7	equ	0046H
Display_Action_6	equ	004CH
RenderCursorLine	equ	0052H
StrobeDisplayRAM	equ	0055H
SetUpLineCursor		equ	0058H
EnableLineCursor	equ	005BH

	endif

	db	076h
;
; this Action Table used for action codes >= 0x78
; for GPIB support.
;
Action_Table2:	
	dw	Action_0x79,Action_0x7A,Action_0x7B,Action_0x7C,Action_0x7D,Action_0x7E
	dw 	RST6,Action_0x80,RST6,Action_0x82,Action_0x83,Action_0x84
	
ScratchRamTable:	
	dw	RAM_SCRATCH,RAM_SCRATCH+0100h,RAM_SCRATCH+0200h,RAM_SCRATCH+0300h
DisplayRamTable:	
	dw	RAM_DISPLAY,RAM_DISPLAY+0200h,RAM_DISPLAY+0400h,RAM_DISPLAY+0600h

Display_Interrupt:
	jmp	Display_Interrupt_0
Init_Display:						;init
	jmp	Init_Display_0
InitDisplayRB:						;init
	jmp	InitDisplayRB_0
	
Init_GPIB:	
	jmp	Init_GPIB_0
	
AddDisplayAction:
	jmp	AddDisplayAction_0
Main_Action_6:
	jmp	Main_Action_6_0
Main_Action_1:	
	jmp	Main_Action_1_0
	
Action_0x7C:	
	jmp	Action_0x7C_0
Action_0x7B:	
	jmp	Action_0x7B_0
Action_0x7A:	
	jmp	Action_0x7A_0
Remove_GPIB_Actions:
	jmp	Remove_GPIB_Actions_0
Action_0x83:	
	jmp	Action_0x83_0
Action_0x7E:	
	jmp	Action_0x7E_0
Action_0x84:	
	jmp	Action_0x84_0
Action_0x7D:	
	jmp	Action_0x7D_0
Action_0x80:	
	jmp	Action_0x80_0
Action_0x79:
	jmp	Action_0x79_0
Action_0x82:	
	jmp	Action_0x82_0

Set_IE:
	jmp	EnableDisplayInterrupt
Display_Action_5:
	jmp	Display_Action_5_0
Update_DEV_WIFCTL_and:
	jmp	Update_DEV_WIFCTL_and_0
Update_DEV_FPC_and:
	jmp	Update_DEV_FPC_and_0
CursorPotInt2:
	jmp	CursorPotInt2_0
	
Get_GPIB_Status:
	jmp	Get_GPIB_Status_0
	
ClrCursorSnap:
	jmp	ClrCursorSnap_0
AdjustCursorTime:
	jmp	AdjustCursorTime_0
GetWFExpandVal:
	jmp	GetWFExpandVal_0
;
; in A
;
Update_DEV_WIFCTL_and_0:
	lxi	h,V_WIFCTL
	ana	m
	mov	m,a
	sta	DEV_WIFCTL			;GPIB
	ret
;
; in A
; DEV_FPC = V_FPC = V_FPC & A
;
Update_DEV_FPC_and_0:
	lxi	h,V_FPC
	ana	m
	mov	m,a
	sta	DEV_FPC
	ret
;
; in A
;
Update_DEV_FPC_or:
	lxi	h,V_FPC
	ora	m
	mov	m,a
	sta	DEV_FPC
	ret
	
L2095:
	lxi	h,V_WIFCTL
	ora	m
	mov	m,a
	sta	DEV_WIFCTL
	ret
;
; WF Display: submit new WFs
;
Display_Action_1:	
	lda	V_CurrWF 			;range 1..4 Current WaveForm area
	add	a					;x2
	mov	l,a
	mvi	h,00h
	lxi	d,ScratchRamTable-2	;determine Memory Area. Index base 1
	dad	d
	mov	e,m					;get Display Memory Area in DE
	inx	h
	mov	d,m
	xchg					;to HL
	shld V_pWF_Source		;store Display Memory Area
	call Copy_WF			;V_pWF_Source
	ret
	
Display_Action_5_0:
	lda	V_CurrWF 			;range 1..10 Current WF area
	add	a					;x2
	mov	l,a
	mvi	h,00h
	lxi	d,SYSRAM_Area-2		;determine Memory Area
	dad	d
	mov	e,m					;get Display Data in DE
	inx	h
	mov	d,m
	xchg
	shld V_pWF_Source		;store
	call Copy_WF			;V_pWF_Source
	ret
;
; Display related: copy a WaveForm
;	
Copy_WF:
	lda	V_CurrWF 			;current WaveForm area. Range 1..4
	lxi	h,V_WFTable			;p = &Table[1].field
	lxi	d,0008H
$$L:
	dcr	a
	jz	L20DB
	dad	d
	jmp	$$L
L20DB:
	shld V_pDispWF			;store p
	lda	V_CONTRL
	ori	03h					;00000011 BOTH|ODD
	sta	DEV_CONTRL
	lda	V_CurrWF 			;current WaveForm area. Base 1	
	add	a					;times 2
	mov	l,a					;to HL
	mvi	h,00h
	lxi	d,DisplayRamTable-2	;WaveForm area
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	xchg					;HL now new WaveForm area
	shld V_pWF_Destination	;store
	lhld V_pDispWF			;restore p
	inx	h					;p += 5
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m					;get data
	ani	04h					;LONGWFMASK
	sta	VAR_80E0			;save
	cpi	04h					;was bit 2 set
	jnz	L2113
	mvi	a,04h
	sta	VAR_80DB
	jmp	L2123
L2113:
	lda	VAR_80E0
	cpi	00h
	jnz	L2123
	mvi	a,02h
	sta	VAR_80DB
	jmp	L2123
L2123:	lda	VAR_80DB
	mov	b,a
	lhld V_pWF_Destination
	xchg
	lhld V_pWF_Source
;
; copy B times
;
$$L2:
;
; copy 128 bytes from (HL) to (DE) skipping each destination byte one
;
	mvi	c,80h
$$L:						;L2130:
	mov	a,m
	inx	h					;HL += 1
	stax	d
	inx	d					;DE += 2
	inx	d
	dcr	c
	jnz	$$L
	dcr	b
	jnz	$$L2
;	
	lhld V_CurrWF 			;current WaveForm area base 1
	mvi	h,00h
	lxi	d,V_ValidWFs-1
	dad	d
	mvi	a,0FFh
	mov	m,a
	lda	V_fSAVEREFShowing	;boolean
	cma
	mov	c,a
	lda	V_fADD
	ana	c
	mov	c,a
	lda	V_fCH1
	mov	b,a
	lda	V_fCH2
	ora	b
	ana	c
	jp	L216B
;	
L215F:
	lda	V_ValidWFs+2		;boolean test
	ral
	jnc	L2172
	mvi	a,03h
	jmp	L2174
L216B:	lda	V_ValidWFs		;boolean test
	ral
	jnc	L215F
L2172:	mvi	a,01h
L2174:	sta	V_PrimaryWF
	mvi	a,0FFh
	sta	V_fOK2ProcessAcq
	ret
;
; Display related
;
; Local V_BOTHODD
;	
RenderWF:
	lda	V_DispWF			;base 1
	dcr	a					;base 0
	rlc						;x8
	rlc
	rlc
	lxi	h,V_WFTable			;p = V_WFTable[V_DispWF-1]
	mov	e,a
	mvi	d,00h
	dad	d
	shld V_pDispWF			;ptr to WF being rendered
	lhld V_pRAM_DOT
	xchg
	lhld V_pRAM_DOT2
	mov	a,d
	ora	e
	ora	h
	ora	l
	jz	L21AF				;both V_pRAM_DOT & V_pRAM_DOT2 are NIL
	lhld V_pRAM_DOT
	mvi	m,01h
	lhld V_pRAM_DOT2
	mvi	m,01h
	lxi	h,0000H
	shld V_pRAM_DOT		;set both to 0
	shld V_pRAM_DOT2
L21AF:	lda	V_CursorMode
	cpi	02h
	jz	L21BC
	cpi	03h
	jnz	L2250
L21BC:
;
; Feature: If SAVE mode, time cursor dot shows on BOTH WFs, not just the primary
; See Operators Manual Page 71	
;
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	L21D4
	lhld V_pDispWF
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	80h					;10000000
	jnz	L2250
	jmp	L21DF
; V_DigitalMode != 4
L21D4:
	lda	V_DispWF
	mov	b,a
	lda	V_PrimaryWF
	cmp	b
	jnz	L2250
;
L21DF:
	lhld V_TimeCursorPos
	shld V_TmpCursorPos
	lhld V_TimeCursorPos+2
	shld V_TmpCursorPos+2
	call GetWFExpandVal_0
	call AdjustCursorTime_0
	lhld V_pDispWF
	lxi	d,0005H
	dad	d
	mov	a,m
	ani	04h					;LONGWFMASK
	cpi	04h
	jz	L221F
	lhld V_TmpCursorPos		;Cursor1
	call ShiftR_HL
	xchg					;DE=Cursor1
	lhld V_TmpCursorPos+2	;Cursor2
	call ShiftR_HL			;HL=Cursor2
	lda	V_DispWF
	ani	01h
	jnz	L2226
	lxi	b,0200H
	dad	b
	xchg
	dad	b
	xchg
	jmp	L2226
L221F:
	lhld V_TmpCursorPos
	xchg					;DE=Cursor1
	lhld V_TmpCursorPos+2	;HL=Cursor2
L2226:
	lda	V_fSnappedCursor		;test boolean
	ral
	jnc	L223D
	lda	V_fCursor1Snapped
	ral
	jnc	L223A
	lxi	d,0001H
	jmp	L223D
L223A:	lxi	h,0001H
L223D:	lxi	b,RAM_DOT
	dad	b
	mvi	m,00h
	shld V_pRAM_DOT2		;ptr to RAM_DOT memory
	lxi	b,RAM_DOT
	xchg
	dad	b
	mvi	m,00h
	shld V_pRAM_DOT			;ptr to RAM_DOT memory
L2250:
	lhld V_pDispWF
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	03h
	cpi	02h
	jnz	L2282
	lda	V_BOTHODD
	cpi	02h
	jnz	L2282
	lda	V_CursorMode
	cpi	02h
	jz	L2278
	lda	V_CursorMode
	cpi	03h
	jnz	L2282
L2278:	lhld V_pRAM_DOT
	mvi	m,01h
	lhld V_pRAM_DOT2
	mvi	m,01h
L2282:
	lda	V_DispWF			;base 1
	dcr	a					;base 0
	add	a					;x2
	mov	e,a
	mvi	d,00h
	lxi	h,DisplayRamTable	;p = &DisplayRamTable[V_DispWF-1]
	dad	d
	mov	e,m					;DE = *(word *)p
	inx	h
	mov	d,m
	inx	d
	ldax d					;A = *(DE+1)
	lhld V_pDispWF			;p
	lxi	d,0002H
	dad	d					;p+2
	mov	a,m					;*(p+2)
	sta	DEV_HGAIN
	inx	h					;p+3
	lda	V_DISREG
	ani	0F7h				;11110111 Clr VERT10X
	sta	V_DISREG
	mov	a,m					;*(p+3)
	sta	DEV_VGAIN
	cpi	18h					;24
	jnz	L22B8
;  DEV_VGAIN == 0x18
	lda	V_DISREG
	ori	08h					;00001000 Set VERT10X
	sta	V_DISREG
L22B8:
	lhld V_pDispWF
	mvi	c,01h
	mvi	b,00h
	dad	b
	mov	a,m
	ana	a
	jz	L22F3
	sta	DEV_LINER
	xra	a
	sta	DEV_JITTER
	call SetVertPositioning
	lda	V_CONTRL
	ani	0EFh				;11101111 set LINECUR (Active Low)
	sta	DEV_CONTRL
	call L22DD				;delay
	jmp	L22DE
L22DD:
	ret
L22DE:
	ani	0BFh				;10111111 Set ZAXON (Active Low)
	di
	sta	DEV_CONTRL
	lda	V_CONTRL
	ani	0EFh				;11101111 Toggle LINECUR (Active Low)
	sta	DEV_CONTRL
	ori	10h
	nop
	sta	DEV_CONTRL
	ei
L22F3:
	lhld V_pDispWF
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	03h
	cpi	02h
	jnz	L230B
	lda	V_BOTHODD
	cpi	02h
	jnz	L230E
L230B:	jmp	L231E
L230E:	lhld V_pDispWF
	lxi	d,0002H
	dad	d
	mov	a,m
	rar
	jnc	L231B
	inr	a
L231B:	sta	DEV_HGAIN
L231E:	lhld V_pDispWF
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	03h
	cpi	02h
	jnz	L2360
	lda	V_BOTHODD
	ani	03h
	sta	V_BOTHODD
	mvi	a,02h				;0x02 | 0x01 = 0x03 -> 0xFC
	ori	01h
	cma
	lxi	h,V_CONTRL
	ana	m					;Clr BOTH ODD
	lxi	h,V_BOTHODD
	ora	m
	sta	V_CONTRL
	lda	V_BOTHODD
	cpi	02h
	jnz	L2355
	xra	a
	sta	V_BOTHODD
	jmp	L235D
L2355:	lxi	h,V_BOTHODD
	inr	m
	lxi	h,V_DispWF
	dcr	m
L235D:	jmp	L236C
L2360:	lda	V_CONTRL
	ori	02h					;00000010 BOTH
	sta	V_CONTRL
	xra	a
	sta	V_BOTHODD
L236C:
	call SetVertPositioning
	lhld V_pDispWF
	mov	a,m
	sta	DEV_JITTER
	lxi	d,0005H
	dad	d
	mov	a,m
	ani	04h
	cpi	04h
	jnz	L2391
	lxi	h,V_DISREG
	mvi	a,20h				;0x20 | 0x10 = 0x30 ->11001111 0xCF
	ori	10h
	cma
	ana	m
	ori	40h					;01000000 STOP512
	mov	m,a					;update V_DISREG
	jmp	L239D
L2391:	lxi	h,V_DISREG
	mvi	a,40h				;0x40 | 0x10 = 0x50 ->10101111 0xAF
	ori	10h
	cma
	ana	m
	ori	20h					;00100000 STOP256
	mov	m,a					;update V_DISREG
L239D:	lda	V_CONTRL
	sta	DEV_CONTRL
	ret
;
; in V_CNT
; updates V_TmpCursorPos, V_TmpCursorPos+2
;
AdjustCursorTime_0:
	lda	V_CNT
	ana	a
	rz							;done if 0
	sta	V_Cnt_2
	lhld V_TmpCursorPos
Loop23AF:
	call Take80Percent
	lda	V_Cnt_2
	dcr	a
	sta	V_Cnt_2
	jnz	Loop23AF				;loop
	shld V_TmpCursorPos
	lda	V_CNT
	sta	V_Cnt_2
	lhld V_TmpCursorPos+2
Loop23C8:
	call Take80Percent
	lda	V_Cnt_2
	dcr	a
	sta	V_Cnt_2
	jnz	Loop23C8				;loop
	shld V_TmpCursorPos+2
	ret
;
; V_TargetTB2 is TIME value for current Time Base
; Sets V_CNT
;
; Always called from Display Interrupt with interrupts running so UIState may suddenly change.
;
; More unnecessary verbose code.
;
GetWFExpandVal_0:
	xra	a
	sta	V_CNT				;reset
	lda	V_ATimebaseActive	;determine UIState TB
	ral
	jnc	Local23ED
	lda	V_ATIME
	sta	V_TargetTB2
	jmp	Local23F3
Local23ED:
	lda	V_BTIME
	sta	V_TargetTB2
Local23F3:
;
; Note: V_TargetTB2 is not the actually acquired TB which is max TB20
;
	lda	V_DigitalMode		;UIState may change
	cpi	DIGITAL_SAVE
	jnz	Local244D
;
; V_DigitalMode == DIGITAL_SAVE
;
; Tektronix bug:
; V_pDispWF and V_PrimaryWF are not always in sync here when called from RenderCursorLine()
; GetWFExpandVal() is looking at the last Rendered WF. Investigated with SAVEREF and Chopped Ch1/Ch2
; Turns out the timebase field in the WFTbl is not updated, even when "interpolated" in SAVE mode.
; so acquiredTB below may be way off (SAVEREF TB != target TB),
; For example, select 2 WFs at say timebase 9 (ch1, ch2), then SAVEREF. Copies of these 2 WFs end up in AREA3 and AREA4.
; Then change the timebase to say 15 and select VTCoupling. Now the code below will look at the DisplayEntry AREA4 with
; timebase 9 (last rendered) while it should look at the AREA1 and AREA2 WFs (unclear which one is "primary").
; Again, if GetWFExpandVal() is called from RenderCursorLine()
; 
; The return value of GetWFExpandVal(), which now may be wrong, is used to scale (Take80Percent)
; the Cursor Time values before being converted to a Line value
;
	lhld V_pDispWF 			;ptr to WF being rendered
	lxi	d,S_TB				;offset to WF TB
	dad	d
	mov	b,m					;B = *(p+S_TB) 
	lda	V_TargetTB2			;value for current UIState TB
	cmp	b					;V_TargetTB2 - *(p+S_TB)
	jz	Local244D			;same
	jc	Local244D			;jmp if V_TargetTB2 < *(p+S_TB)
; V_TargetTB2 >= *(p+6)	
	mov	a,b
	cpi	TB20				;*(p+S_TB) - TB20 
	jc	Local2416
	mvi	b,TB20				;if (B > 0x14) B = TB20;
	mov	a,b
Local2416:					;A is new TIME value
; A, B = min(*(p+S_TB),TB20)
	call A_mod_3_plus_1		;result in A
	lxi	h,V_CNT				;p = &V_CNT
	cpi	01h
	jnz	Local242E
; A_mod_3_plus_1 == 1	
	lda	V_TargetTB2			;TIME value for current Time Base
	sub	b					;V_TargetTB2 - B
	cpi	01h
	rz
	inr	m					;(*p) += 1
	cpi	05h
	rc
	inr	m					;(*p) += 1
	ret
Local242E:
	cpi	02h					;A_mod_3_plus_1 - 2
	jnz	Local243D
; A_mod_3_plus_1 == 2	
	lda	V_TargetTB2			;TIME value for current Time Base
	sub	b					;V_TargetTB2 - B
	inr	m					;(*p) += 1
	cpi	04h
	rc
	inr	m					;(*p) += 1
	ret
Local243D:
	lda	V_TargetTB2			;TIME value for current Time Base
	sub	b					;V_TargetTB2 - B
	cpi	03h
	rc
	inr	m					;(*p) += 1
	cpi	06h
	rc
	inr	m					;(*p) += 1
	ret
	jmp	ShiftR_HL			;unreachable
; V_DigitalMode != DIGITAL_SAVE	
Local244D:
	lda	V_TargetTB2			;TIME value for current Time Base
	cpi	17h					;V_TargetTB2 - 0x17
	rc						;done if V_TargetTB2 < TIMEBASE23
	lxi	h,V_CNT				;p
	inr	m					;*p += 1
	cpi	1Ah					;V_TargetTB2 - 0x1A
	rc						;return if V_TargetTB2 < TIMEBASE26
	inr	m					;*p += 1
	ret
;
; Shift Right H & L by 1
;
ShiftR_HL:
	ana	a					;Clear Carry
	mov	a,h
	rar						;divide by 2
	mov	h,a
	mov	a,l
	rar
	mov	l,a
	ana	a					;set flags
	ret

SetVertPositioning:
	lxi	h,V_FPC
	mvi	a,20h				;0x20 | 0x10 = 0x30
	ori	10h
	cma
	ana	m
	mov	m,a
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	L24AA
	lhld V_pDispWF
	lxi	b,S_CHANMODE
	dad	b
	mov	a,m
	ani	80h
	jnz	L24AA
	mov	a,m
	ani	01h
	cpi	01h
	jnz	L2494
	lda	V_FPC
	ori	20h
	sta	V_FPC
L2494:	mov	a,m
	ani	80h
	jnz	L24AA
	mov	a,m
	ani	02h
	cpi	02h
	jnz	L24AA
	lda	V_FPC
	ori	10h
	sta	V_FPC
L24AA:	lda	V_FPC
	sta	DEV_FPC
	ret
;
; init function
;
Init_Display_0:
	lxi	h,0020H
	shld V_AVG_Sweeps
	lxi	h,0020H
	shld V_ENV_Sweeps
	xra	a
	sta	V_Curr_LEDRO
	mvi	a,05h
	sta	V_DecPntDigit
	lxi	h,0100H
	shld V_TimeCursorPos
	lxi	h,00F0H
	shld V_TimeCursorPos+2
	lxi	h,01FFh
	shld V_VoltsCursorPos
	lxi	h,01DFh
	shld V_VoltsCursorPos+2
	lxi	h,0000H
	shld V_pRAM_DOT
	shld V_pRAM_DOT2
	mvi	a,02h
	sta	V_CursorPot_Delay
	lxi	h,0FFFFH
	shld V_PreviousPRCount
	mvi	a,40h
	cma
	sta	V_PRFastMode
	xra	a
	sta	V_CursorIncrementValue
	cma
	sta	V_TimerCntrRateInc2
	lxi	h,01D0h
	shld V_CursorPos2
	lxi	h,00A0H
	shld V_CursorPos1
	mvi	a,0BFh				;10111111 & 11101111 = 10101111 0xAF
	ani	0EFh
	cma						;0x01010000 Clr LINECUR, ZAXON (Active Low)
	sta	DEV_CONTRL
	sta	V_CONTRL
	call Fill_RAM_DOT
	xra	a
	sta	DEV_FPC
	sta	V_FPC
	sta	DEV_HGAIN
	sta	DEV_VGAIN
	sta	DEV_JITTER
	sta	V_DispWF
	sta	V_CursorLine
	sta	VAR_8042
	mvi	a,40h				;01000000 STOP512
	sta	DEV_DISREG
	sta	V_DISREG			;copy of DEV_DISREG
	ret
;
; Fill RAM_DOT memory with 1
; Range RAM_DOT..RAM_DOT+179 (200 bytes)
;
Fill_RAM_DOT:
	lxi	h,RAM_DOT
	mvi	a,01h
$$L:						;L2541:
	mov	m,a
	inx	h
	mov	b,a					;save A.
	mov	a,h
	cpi	0B4h
	mov	a,b
	jnz	$$L
	ret
;
;
;
Display_Interrupt_0:	
	push	b
	push d
	push	h
	push	psw
	rim
	ani	0Fh					;00001111
	ori	0Ah					;00001010
	sim
	ei
	lxi	h,V_CONTRL
	mvi	a,7Fh				;01111111
	ana	m					;Clr ACTIVEL
	ori	12h					;00010010 LINECUR off BOTH on
	mov	m,a					;update V_CONTRL
	sta	DEV_CONTRL
	lxi	h,V_DISREG			;copy of DEV_DISREG
	mvi	a,7Fh				;01111111
	ana	m					;clr bit 7 CSEL
	ani	7Ch					;01111100 zero Line Cursor Bits
	mov	m,a					;update
	sta	DEV_DISREG
;
; Execute actions in V_DisplayRB.
; loop from (V_DisplayRB_Start + 1) to (V_DisplayRB_End) through ring buffer 1..10
;	
Process_DisplayRB:
	lxi	h,V_DisplayRB_Start
	lda	V_DisplayRB_End
	cmp	m					;V_DisplayRB_End - V_DisplayRB_Start
	jz	L25A6				;ring buffer empty
	inr	m					;increment V_DisplayRB_Start
	mvi	a,0Ah				;range 1..10
	cmp	m					;10 - (V_DisplayRB_Start + 1)
	jnc	L2583
	mvi	a,01h				;wrap around
	mov	m,a					;V_DisplayRB_Start = 1
L2583:
	mov	c,m					;index to process range 1..10
	mvi	b,00h				;MSB
	xchg					;DE now &V_DisplayRB_Start
	lxi	h,V_DisplayRB-1		;table - 1, second byte
	dad	b					
	mov	a,m					;table[C]. High nibble is current WaveForm area, low nibble is action index
	mov	b,a					;save
	ani	0F0h				;11110000 Look at upper 4 bits only
	rar						;rotate to lower 4 bits
	rar
	rar
	rar
	sta	V_CurrWF 			;save current WaveForm area
	mov	a,b					;restore
	ani	0Fh					;Lower nibble, range 1..15
	mov	c,a					;unnecessary since BC not input
	mvi	b,00h
	lxi	d,Display_Actions-2
	call Get_Word_From_Table ;action table
	rst	4					;call action
	jmp	Process_DisplayRB	;loop
L25A6:
	call ScheduleNextDisplay
	call RestartDisplaySystem
	di
	lda	V_DigitalMode
	cpi	DIGITAL_OFF
	jz	L25BB
	rim
	ani	0Dh					;00001101
	ori	08h					;00001000
	sim
L25BB:	pop	psw
	pop	h
	pop	d
	pop	b
	ei
	ret
	
SetDefaultDashedLine:
	mvi	a,80h
	sta	DEV_LINER
	lda	V_FPC
	ani	0CFh
	sta	V_FPC
	call StrobeDisplayRAM	;result A unused
	lxi	h,V_CONTRL
	mvi	a,80h				;10000000 Set ACTIVEL
	ora	m
	mov	m,a					;update V_CONTRL
	call SetUpLineCursor
	mvi	a,0F0h
	sta	DEV_VGAIN
	call EnableLineCursor
	ret

EnableDisplayInterrupt:
	di
	rim
	ani	0Dh					;00001101 	Clr Pending Status, M6.5
	ori	08h					;00001000	Set IE, Mask RST 7.5, 5.5
	sim
	ei
	ret
	
NextCursorLine:
	lda	V_CursorMode
	cpi	01h
	jz	L25FA
	cpi	03h
	jnz	L25FF
L25FA:	mvi	a,02h
	jmp	L2600
L25FF:	xra	a
L2600:	sta	VAR_8042
	mov	b,a
	lxi	h,V_CursorLine
	inr	m
	mov	a,b
	cmp	m
	rnc
	xra	a
	mov	m,a
	ret

ScheduleNextDisplay:
	call L2653
	lda	V_DispWF
	ana	a
	jz	L261C
	call RenderWF
	ret
L261C:	lda	V_CursorLine
	ana	a
	jz	L2627
	call RenderCursorLine
	ret
L2627:
	call SetDefaultDashedLine
	ret
;
; Update V_cnt1
;
FindNextWF:
	xra	a
	sta	V_cnt01
; loop
L262F:	lda	V_DispWF
	cpi	04h					;V_DispWF - 4
	jnc	L264E				;exit if >= 4
	inr	a					;V_DispWF++
	sta	V_DispWF
	mov	e,a					;base 1
	mvi	d,00h
	lxi	h,V_ValidWFs-1		;table of 4 booleans.
	dad	d
	mov	a,m					;get boolean
	ana	a
	jm	L2652
	lxi	h,V_cnt01
	inr	m
	jmp	L262F
L264E:
	xra	a					;clr V_DispWF
	sta	V_DispWF
L2652:	ret
;
L2653:
	lda	V_CursorLine
	ana	a					;test
	jnz	L2665x
; V_CursorLine == 0	
	call FindNextWF
	lda	V_cnt01
	cpi	04h
	jz	L267B
; (V_CursorLine != 0) || (V_cnt01 != 4	)
L2665x:
	lda	V_DispWF
	ana	a					;test
	jnz	L266F
; V_DispWF == 0	
	call NextCursorLine
L266F:	lda	V_DispWF
	ana	a					;test
	rnz
	lda	V_CursorLine
	ana	a
	jz	L2653				;loop.
L267B:	ret
;
; Display related
;
Display_Action_3:
	lda	V_CursorMode
	cpi	03h					;NUMWINCPLVT
	jz	L268C
	cpi	02h					;NUMWINTIME
	jnz	L26B8
	call ClrCursorSnap_0
L268C:
	lda	V_fFirstCursorActive ;boolean test
	ral
	jnc	L26991
	lxi	h,V_TimeCursorPos
	jmp	L269C
L26991:
	lxi	h,V_TimeCursorPos+2
; p (HL) can be V_VoltsCursorPos, V_VoltsCursorPos+2, V_TimeCursorPos
; Add sign-extended V_CursorIncrementValue to *(word *)p
L269C:
	lda	V_CursorIncrementValue			;V_CursorIncrementValue
	ana	a					;test
	mov	c,a					;move and sign extend A to BC
	jm	L26A9
	mvi	b,00h
	jmp	L26AB
L26A9:	mvi	b,0FFh
L26AB:	mov	e,m				;DE = *(word *)p
	inx	h
	mov	d,m
	dcx	h
	xchg					;p now in DE
	dad	b					;Old DE+BC
	xchg					;restore
	mov	m,e					;*(word *)(p) = DE+BC
	inx	h
	mov	m,d
	jmp	L26D0
;
L26B8:	cpi	01h
	jnz	L26D0
	lda	V_fFirstCursorActive ;boolean test
	ral
	jnc	L26CA
	lxi	h,V_VoltsCursorPos
	jmp	L269C
L26CA:	lxi	h,V_VoltsCursorPos+2
	jmp	L269C
L26D0:	call ConstrainVoltsTimeCursor
	lda	V_CursorMode
	cpi	03h
	jnz	L2730x
; V_CursorMode == 3
	lhld V_CursorEdgeTimeCnt
	mov	a,h
	cpi	01h
	jnc	L2702x
	lda	VAR_8016
	mov	c,a
	lda	V_fFirstCursorActive ;boolean test
	ral
	lda	V_TimeCursorPos
	jc	L26F5
	lda	V_TimeCursorPos+2
L26F5:	cmp	c
	mvi	a,0FFh
	jz	L26FC
	xra	a
L26FC:	sta	V_fAtCursorEdge ;set boolean
	jmp	L2730x	
L2702x:
	lda	V_PrimaryWF		;base 1
	dcr	a					;base 0
	rlc						;times 8
	rlc
	rlc
	lxi	h,V_WFTable+S_GNDREF ;WF table
	mov	e,a
	mvi	d,00h
	dad	d
	mov	a,m					;test memory
	ana	a
	jz	L272D
	lda	V_fCursorEdgeTracking ;test boolean
	ral						;carry if TRUE
	jnc	L272A
	lda	V_fFirstCursorActive
	sta	V_fCursor1Snapped
	xra	a
	sta	V_fCursorEdgeTracking ;V_fCursorEdgeTracking = FALSE
	cma
	sta	V_fSnappedCursor			;V_fSnappedCursor = TRUE
L272A:
	jmp	L2730x
L272D:
	call ClrCursorSnap_0
L2730x:	ret
;
ClrCursorSnap_0:
	xra	a
	sta	V_fSnappedCursor			;V_fSnappedCursor = FALSE
	sta	V_fAtCursorEdge ;V_fAtCursorEdge = FALSE
	mov	h,a
	mov	l,a
	shld V_CursorEdgeTimeCnt	;clear (word *)V_CursorEdgeTimeCnt
	cma
	sta	V_fCursorEdgeTracking ;V_fCursorEdgeTracking = TRUE
	ret
;
; Display related
;
Display_Action_4:
	lda	V_DigitalMode
	cpi	DIGITAL_AVG
	jnz	L2768x
	lxi	h,0002H
	shld V_LocalMinSweeps
	lxi	h,0100H
	shld V_LocalMaxSweeps
	lhld V_AVG_Sweeps
	shld V_CurrentSweeps
	call Update_NR_Sweeps
	lhld V_CurrentSweeps
	shld V_AVG_Sweeps
	jmp	L2783
L2768x:	lxi	h,0001H
	shld V_LocalMinSweeps
	lxi	h,9999
	shld V_LocalMaxSweeps
	lhld V_ENV_Sweeps
	shld V_CurrentSweeps
	call Update_NR_Sweeps
	lhld V_CurrentSweeps
	shld V_ENV_Sweeps
L2783:
	mvi	a,MAIN_ACTION_5_ID
	call AddMainAction
	ret
;	
;
Update_NR_Sweeps:
	lda	V_Rate_Direction
	mvi	l,00h
	call Signed_Compare_A_L ;return TRUE/CY set if A > L (signed)
	jnc	L27BF
; A > 0
	lhld V_CurrentSweeps	;jmp if [V_CurrentSweeps] >= [V_LocalMaxSweeps]
	xchg
	lhld V_LocalMaxSweeps
	mov	a,e					;E - L
	sub	l					;relevant result in CY
	mov	a,d					;D - H
	sbb	h
	jnc	L27A9				;
	lhld V_CurrentSweeps	;V_CurrentSweeps *= 2;
	dad	h
	shld V_CurrentSweeps
L27A9:
	lhld V_CurrentSweeps	;to DE
	xchg
	lxi	h,0100H				;256
	call Signed_Compare_DE_HL ;returns CY if [V_CurrentSweeps] > 256
	jnc	L27BC
	lhld V_LocalMaxSweeps	;[V_CurrentSweeps] = [V_LocalMaxSweeps]
	shld V_CurrentSweeps
L27BC:	jmp	L27EA

L27BF:
	lhld V_LocalMinSweeps	;jmp if [V_LocalMinSweeps] >= [V_CurrentSweeps]
	xchg
	lhld V_CurrentSweeps
	mov	a,e					;E - L
	sub	l					;CY result
	mov	a,d					;D - H
	sbb	h
	jnc	L27EA
;	[V_LocalMinSweeps] < [V_CurrentSweeps]
	lhld V_CurrentSweeps	;[V_CurrentSweeps] >>= 1
	xchg
	lxi	h,0001H
	call ShiftR_DE_L_times
	shld V_CurrentSweeps	
	xchg					;to DE
	lxi	h,0100H				;256
	call Signed_Compare_DE_HL ;returns CY if [V_CurrentSweeps] > 256
	jnc	L27EA
	lxi	h,0100H
	shld V_CurrentSweeps	;[V_CurrentSweeps] = 0x0100
L27EA:	ret
;
; in A
;
AddDisplayAction_0:
	push	psw
	rim
	di
	sta	V_SAVED_INT_Mask	;save interrupt mask
	pop	psw
	sta	V_Saved_Arg			;input
	lda	V_DisplayRB_Start
	sta	V_DisplayRB_Index
L27FB:	lda	V_DisplayRB_End
	lxi	h,V_DisplayRB_Index
	cmp	m
	jz	L282E
	lxi	h,V_DisplayRB_Index
	inr	m
	mvi	a,0Ah
	lxi	h,V_DisplayRB_Index
	cmp	m
	jnc	L2817A
	mvi	a,01h
	sta	V_DisplayRB_Index
L2817A:	lhld V_DisplayRB_Index
	mvi	h,00h
	lxi	d,V_DisplayRB_Start
	dad	d
	mov	a,m
	lxi	h,V_Saved_Arg		;input
	cmp	m
	jnz	L282B
	jmp	L284D				;exit
L282B:	jmp	L27FB
L282E:	lxi	h,V_DisplayRB_End ;update V_DisplayRB_End range 1..10
	inr	m
	mvi	a,0Ah
	lxi	h,V_DisplayRB_End
	cmp	m					;10 - (m). Carry if (m) > 10
	jnc	L2840
	mvi	a,01h				;reset to 1
	sta	V_DisplayRB_End
L2840:
	lhld V_DisplayRB_End	;L <- V_DisplayRB_End
	mvi	h,00h
	lxi	d,V_DisplayRB_Start	;table ptr
	dad	d
	lda	V_Saved_Arg			;input arg
	mov	m,a					;update table
L284D:	lda	V_SAVED_INT_Mask ;saved interrupt mask
	ani	08h					;00001000 test Interrupts masked
	jz	L2856				;jump if not masked
	ei
L2856:	ret
;
; init function
;
InitDisplayRB_0:
	mvi	a,01h
	sta	V_DisplayRB_Start
	mvi	a,01h
	sta	V_DisplayRB_End
	ret
;
; Called if V_GPIB_803F is TRUE
;	
Init_GPIB_0:
	xra	a
	sta	V_GPIB_MTAReceived
	sta	V_TALKREG
	sta	V_GPIB_XmitWFRQSFActive
	sta	V_GPIB_ActionWasRemoved
	sta	V_GPIB_EndOfMessage
	sta	V_GPIB_Bool4
	sta	V_GPIB_Bool3
	sta	V_GPIB_Bool5
	sta	V_WIFCTL
	sta	DEV_WIFCTL
	cma
	sta	VAR_8006
	sta	DEV_DATACC
	sta	V_GPIB_Bool9
	mvi	a,81h				;10000001 -> 01111110 TIDS LED and SRQLED
	cma
	call Update_DEV_FPC_and
	rim
	ori	08h
	ani	0Eh
	sim
	mvi	a,01h
	sta	V_GPIBOut
	mvi	a,79h
	call AddMainAction
	ret
;
; called from GPIB interrupt handler
; called from action handlers
;	
Get_GPIB_Status_0:
	di
	lda	DEV_RIFSTAT			;GPIB status bits
	sta	V_GPIB_Bool8
	ral
	sta	V_GPIB_Bool7
	ral
	sta	V_GPIB_NRFD
	ral
	sta	V_GPIB_NDAC
	ral
	sta	V_GPIB_ATNDAV
	ral
	sta	V_GPIB_60
	ral
	sta	V_GPIB_RATN
	ral
	cma
	sta	V_GPIB_Bool6
	lda	DEV_TALKREG
	sta	V_TALKREG
	ani	1Fh					;mod 32
	ori	40h					;01000000 Set bit 6
	sta	V_TALKADDR
	ei
	ret
;
; Action added by CursorPotInt
; See CursorPotInt2_0 for similarity
;	
Main_Action_6_0:
	lda	V_CursorMode
	cpi	01h					;NUMWINVOLTS
	jz	L28E7
	cpi	02h					;NUMWINTIME
	jz	L28E7
	cpi	03h					;NUMWINCPLVT
	jnz	L28EB
; (V_CursorMode == NUMWINVOLTS) || (V_CursorMode == NUMWINTIME) || (V_CursorMode == NUMWINCPLVT) 
L28E7:	call L2AA8
	ret
L28EB:
	cpi	00h					;NUMWINNONE
	rz						;done
; (V_CursorMode == NUMWINSWEEPS) || (V_CursorMode == NUMWINCNTDOWN)
	lhld V_PositionRateCount_Values
	shld V_PRCount
	call U788_BCD_2_Binary
	call Set_Rate_Direction
	ret
;
; Only called from CursorPotInt.
; Interrupts still OFF
;	
CursorPotInt2_0:
	lda	V_CursorMode
	cpi	01h
	jz	L290B
	cpi	02h
	jz	L290B
	cpi	03h
	rnz						;done
; (V_CursorMode == 1) || (V_CursorMode == 2) || (V_CursorMode == 3) 
L290B:	lhld V_PositionRateCount_Values
	shld V_PRCount
	call U788_BCD_2_Binary
	call CursorPotIntS881A
	ret
;
; only called from above
;	
CursorPotIntS881A:
	lhld V_PreviousPRCount
	xchg
	lxi	h,0FFFFH
	mov	a,e
	sub	l
	mov	l,a
	mov	a,d
	sbb	h
	ora	l
	jnz	L2931
	lhld V_PRCount
	shld V_PreviousPRCount
	jmp	Local2937
L2931:
	lhld V_LastPRCount
	shld V_PreviousPRCount	;word
Local2937:
	lhld V_PRCount
	shld V_LastPRCount
	lda	DEV_CURSOR
	ani	40h					;01000000 RATE/POS
	cpi	40h
	jnz	L2A32
; POS active	
	lda	V_PRFastMode
	cpi	40h
	jz	L29A1
	mvi	a,40h
	sta	V_PRFastMode
	lhld V_LastPRCount
	xchg					;to DE
	lxi	h,0138h				;312
	mov	a,e					;DE - 312
	sub	l
	mov	a,d
	sbb	h
	jc	Local2983
	lhld Number5			;compiler madness?
	mvi	h,00h
	xchg
	lhld V_CursorPos2
	call Multiply_HL_DE
	xchg
	lhld V_LastPRCount
	dad	d
	xchg
	lhld Number5			;more compiler madness?
	inr	l
	mvi	h,00h
	call Divide_DE_by_HL_2
	shld V_CursorPos2
	jmp	L29A1
Local2983:
	lhld Number5			;compiler madness?
	mvi	h,00h
	xchg
	lhld V_CursorPos1
	call Multiply_HL_DE
	xchg
	lhld V_LastPRCount
	dad	d
	xchg
	lhld Number5			;more compiler madness?
	inr	l
	mvi	h,00h
	call Divide_DE_by_HL_2
	shld V_CursorPos1
L29A1:
	lhld V_LastPRCount
	xchg
	lxi	h,0138h
	mov	a,e					;V_LastPRCount - 0x0138
	sub	l
	mov	a,d
	sbb	h
	jnc	$$L
; V_LastPRCount < 0x0138
	lhld V_CursorPos1		;V_TMP8142 = MAX(V_CursorPos1, V_LastPRCount)
	xchg
	lhld V_LastPRCount
	call MAX_DE_HL
	shld V_TMP8142
	jmp	$$L291
$$L:
	lhld V_CursorPos2		;V_TMP8142 = MIN(V_CursorPos2, V_LastPRCount)
	xchg
	lhld V_LastPRCount
	call MIN_DE_HL			;return smaller value in HL
	shld V_TMP8142
	lda	V_fSnappedCursor	;boolean test
	ral
	jnc	$$L291
	lda	V_fFirstCursorActive
	mov	b,a
	lda	V_fCursor1Snapped
	cmp	b
	jnz	$$L291
	call ClrCursorSnap
$$L291:
	lhld V_LastPRCount		;DE = ABS(V_LastPRCount - V_TMP8142)
	xchg
	lhld V_TMP8142
	mov	a,e
	sub	l
	mov	l,a
	mov	a,d
	sbb	h
	mov	h,a
	call AbsoluteValue_HL
	xchg					;result to DE
	lxi	h,007FH
	call MIN_DE_HL			;return smaller value in HL
	xchg					;now in DE
	lxi	h,3
	call ShiftR_DE_L_times	;>>= 3 /8
	inx	h
	shld VAR_8140
	lxi	d,V_CursorScaleTbl-1 ;multiplication factors
	lhld VAR_8140
	dad	d
	mov	a,m
	sta	V_CursorIncrementValue
	lhld V_LastPRCount		;V_LastPRCount - 0x0138
	xchg
	lxi	h,0138h
	mov	a,e
	sub	l
	mov	a,d
	sbb	h
	jnc	L2A24
	lda	V_CursorIncrementValue
	dcr	a
	cma
	sta	V_CursorIncrementValue
L2A24:
	lxi	d,V_TimerCntr_Rate_Tbl
	lhld VAR_8140
	dad	d
	mov	a,m
	sta	V_TimerCntrRateInc2
	jmp	L2A65
; RATE active	
L2A32:	lhld V_LastPRCount
	call ShiftR_HL			;divide HL by 2
	shld V_LastPRCount
	lda	V_PRFastMode
	cpi	40h
	jnz	L2A4F
	mvi	a,40h
	cma
	sta	V_PRFastMode
	lhld V_LastPRCount
	shld V_PreviousPRCount
L2A4F:
	lhld V_LastPRCount
	xchg
	lhld V_PreviousPRCount
	mov	a,e					;DE - HL
	sub	l
	mov	l,a
	mov	a,d
	sbb	h
	mov	h,a
	shld VAR_813E			;VAR_813E = V_LastPRCount - V_PreviousPRCount
	call CursorPotIntS881A_2
	call ConstrainVoltsTimeCursor
L2A65:	ret
;
; Only called from above
;
CursorPotIntS881A_2:
	lhld VAR_813E
	xchg					;DE = VAR_813E
	lda	V_CursorMode
	cpi	03h					;NUMWINCPLVT
	jz	L2A7A
	cpi	02h					;NUMWINTIME
	jnz	L2A91
;	V_CursorMode == NUMWINTIME
	call ClrCursorSnap
;	V_CursorMode == NUMWINCPLVT || V_CursorMode == NUMWINTIME
L2A7A:
	lda	V_fFirstCursorActive ;boolean test
	ral
	jnc	L2A89
	lhld V_TimeCursorPos
	dad	d
	shld V_TimeCursorPos	;V_TimeCursorPos += VAR_813E
	ret
L2A89:
	lhld V_TimeCursorPos+2
	dad	d
	shld V_TimeCursorPos+2	;V_TimeCursorPos+2 += VAR_813E
	ret
	
;	(V_CursorMode != NUMWINCPLVT) && (V_CursorMode != NUMWINTIME)
L2A91:
	lda	V_fFirstCursorActive ;boolean test
	ral
	jnc	L2AA0
	lhld V_VoltsCursorPos
	dad	d
	shld V_VoltsCursorPos	;V_VoltsCursorPos += VAR_813E
	ret
L2AA0:
	lhld V_VoltsCursorPos+2
	dad	d
	shld V_VoltsCursorPos+2	;V_VoltsCursorPos+2 += VAR_813E
	ret
	
L2AA8:
	call SetNumWinDistance
	call CvtNumWinDistance
	ret
;
; Only called from above
;
SetNumWinDistance:
	lda	V_CursorMode
	cpi	02h
	jnz	L2AC1
; (V_CursorMode == 2)
	lhld V_TimeCursorPos	;load 2 words
	xchg
	lhld V_TimeCursorPos+2
	jmp	L2AD7
; (V_CursorMode != 2)
L2AC1:	cpi	01h
	jnz	L2AD0
; (V_CursorMode == 1)
	lhld V_VoltsCursorPos	;load 2 words
	xchg
	lhld V_VoltsCursorPos+2
	jmp	L2AD7
; (V_CursorMode != 1) && (V_CursorMode != 2)
L2AD0:
	lhld V_LineCursorPos	;load 2 words
	xchg
	lhld V_LineCursorPos+2
L2AD7:	mov	a,e				;DE = DE - HL
	sub	l
	mov	e,a
	mov	a,d
	sbb	h
	mov	d,a
	xchg					;to HL
	call AbsoluteValue_HL
	shld V_NumWinValue
	ret
;
; Only called from above
;	
CvtNumWinDistance:
	lda	V_CursorMode
	cpi	02h
	jnz	L2AF3
; V_CursorMode == 2
	call TBNumWin
	jmp	L2AF6
L2AF3:
	call CvtNumWinDistanceVolts
L2AF6:
	ret
;
; Only called from above when V_CursorMode == TIME
; This is an incredible mumbo jumbo mess of spaghetti code
; TBNumWin and TBNumWin1 go on for 398 bytes of code.
; An algorithmic/formula based version is just 164 bytes
;
TBNumWin:
	lda	V_ATimebaseActive	;which time base
	ral
	jnc	L2B07
	lda	V_ATIME
	sta	V_UIVolts
	jmp	Local2B0D
L2B07:
	lda	V_BTIME
	sta	V_UIVolts
Local2B0D:
	lhld V_pDispWF			;p
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m					;A = p->S_CHANMODE)
	ani	80h					;10000000 SAVEREF
	lhld V_pDispWF			;reload.
	jz	L2B20				;brif !SAVEREF
	lxi	h,V_WFTable			;use V_WFTable[AREA1] if SAVEREF
L2B20:
	lxi	d,S_TB				;B = p->S_TB
	dad	d
	mov	b,m					;WF targetTB
	lda	V_UIVolts			;UI targetTB
	cmp	b
	jc	L2B36				;brif UI targetTB < WF targetTB
	jz	L2B4E				;brif UI targetTB == WF targetTB
; UI targetTB > WF targetTB
	call TBNumWin1
	shld V_NumWinValue
	ret
; UI targetTB (A) < WF targetTB (B)
L2B36:
	mov	c,a
	mov	a,b
	cpi	TB20
	mov	a,c
	jc	L2B4E				;brif WF targetTB < TB20
	mvi	b,TB20				;also argument to TBNumWin1
	cmp	b
	jc	L2B4E				;brif UI targetTB < TB20
	jz	L2B4E				;brif UI targetTB == TB20
; (WF targetTB >= TB20) && (UI targetTB > TB20)
	call TBNumWin1
	shld V_NumWinValue
	ret
; UI targetTB == WF targetTB
; A = UI targetTB. B = min(WF targetTB, TB20)
L2B4E:
	cpi	17h
	jc	Local2B57
	call Set_FastTimeDiv
	ret
Local2B57:
	call Set_SlowTimeDiv
	ret
;
; in B
; set VAR_8027, update V_NumWinValue
; Only called from above
;
Set_SlowTimeDiv:
; B = WF targetTB but max TB20 if (UI targetTB (A) < WF targetTB) && (WF targetTB >= TB20)
	mov	a,b
	call A_mod_3_plus_1
	sta	VAR_8027
	call SetTimeScaleCode	;sets V_SCALECode
	lhld V_NumWinValue
	lda	VAR_8027
	cpi	03h
	jnz	Local2B71
	dad	h					;x2
Local2B71:
	cpi	02h
	jnz	Local2B79
	call Multiply_HL_by_5
Local2B79:
	shld V_NumWinValue		;save HL
	ret
;
; set V_SCALECode, update V_NumWinValue
;
Set_FastTimeDiv:
	mvi	a,0F9h
	sta	V_SCALECode
	lhld V_NumWinValue
	call Take80Percent
	shld V_NumWinValue
	lda	V_UIVolts
	mov	b,a
	call Multiply_HL_by_2.5
	mov	a,b
	cpi	17h
	jz	L2BB0
	call ShiftR_HL
	mov	a,b
	cpi	18h
	jz	L2BB0
	call ShiftR_HL
	mov	a,b
	cpi	19h
	jz	L2BB0
	call Take80Percent
	call ShiftR_HL
L2BB0:
	shld V_NumWinValue
	ret
;
; in A, B
; out HL
;
TBNumWin1:
	mov	c,a
	mov	a,b
	cpi	TB20
	jc	Local2BBE
	mvi	a,TB20
	mov	b,a
Local2BBE:
	call A_mod_3_plus_1
	mov	d,b
	mov	e,a
	call SetTimeScaleCode	;sets V_SCALECode
	mov	b,d
	mov	a,e
	cpi	01h
	jnz	L2C05
	lda	V_SCALECode
	dcr	a
	sta	V_SCALECode
	mov	a,c
	sub	b
	lhld V_NumWinValue
	call Multiply_HL_by_5
	cpi	01h
	rz
	cpi	04h
	jz	DecrementScaleCode
	mov	b,a
	push b
	call Take80Percent
	pop	b
	call ShiftR_HL
	mov	a,b
	cpi	02h
	rz
	cpi	05h
	jz	DecrementScaleCode
	call ShiftR_HL
	mov	a,b
	cpi	03h
	rz
;
; Local label but also used as subroutine
;
DecrementScaleCode:
	lda	V_SCALECode
	dcr	a
	sta	V_SCALECode
	ret
;
L2C05:	cpi	02h
	jnz	L2C3A
	mov	a,c
	sub	b
	lhld V_NumWinValue
	mov	b,a
	push b
	call Take80Percent
	pop	b
	call Multiply_HL_by_5
	call ShiftR_HL
	mov	a,b
	cpi	01h
	rz
	cpi	04h
	jz	DecrementScaleCode
	call ShiftR_HL
	mov	a,b
	cpi	02h
	rz
	cpi	05h
	jz	DecrementScaleCode
	call ShiftR_HL
	mov	a,b
	cpi	03h
	rz
	jmp	DecrementScaleCode
L2C3A:
	mov	a,c
	sub	b
	lhld V_NumWinValue
	mov	b,a
	cpi	01h
	rz
	mov	a,c
	cpi	19h
	jz	L2C4E
	cpi	1Ah
	jnz	L2C5A
L2C4E:
	call ShiftR_HL
	mov	a,c
	cpi	19h
	jz	DecrementScaleCode
	jmp	L2C69
L2C5A:
	call DecrementScaleCode
	call Multiply_HL_by_5
	mov	a,b
	cpi	02h
	rz
	cpi	05h
	jz	DecrementScaleCode
L2C69:
	push b				;save
	call Take80Percent
	pop	b
	call ShiftR_HL
	mov	a,b
	cpi	03h
	rz
	cpi	04h
	jz	Local2C7D
	jmp	DecrementScaleCode
Local2C7D:
	call ShiftR_HL
	mov	a,b
	cpi	04h
	rz
	ret
;
; Multiply HL by 5. Preserves A
;
Multiply_HL_by_5:
	mov	e,l
	mov	d,h
	dad	h
	dad	h
	dad	d
	ret
;
; in B. Decrement. Divide by 3. Negate result. Increment
; set V_SCALECode
;
SetTimeScaleCode:
	mov	a,b					;save
	dcr	a
	mvi	b,0FFh
L2C8F:
	inr	b
	sui	03h
	jp	L2C8F
	mov	a,b
	cma					;two's complement
	inr	a				;negate + 1
	sta	V_SCALECode
	ret
;
; in A. (A modulo 3) plus 1. Result 1, 2 or 3
;
A_mod_3_plus_1:
	sui	03h
	jp	A_mod_3_plus_1
	adi	04h
	ret
;
; in HL. Multiply by 5, then divide by 2
;	
Multiply_HL_by_2.5:
	mov	e,l					;HL * 5
	mov	d,h
	dad	h
	dad	h
	dad	d
	call ShiftR_HL
	ret
;
; in HL, DE
;	
Take80Percent:
	dad	h					;x2
	dad	h					;x4
	xchg					;DE <- HL
	lxi	h,0005H
	call Divide_DE_by_HL
	ret
;
; in DE, HL
; Only called from above (HL == 5)
; out DE, HL
; re-entrant version which can be called from mainline code.
;	
Divide_DE_by_HL:
	mov	b,h					;BC == HL (5)
	mov	c,l
	xra	a
	mov	l,a					;loop counter
	push	h				;save
	lxi	h,0000H				;operand
	xthl					;exchange stack top with HL. HL now loop counter
	push	psw
;
; loop 16 times. L is loop counter. Operand on stack. BC, DE in
;
Local2CC1:
	pop	psw
	xthl					;exchange stack top with HL. HL now operand
	mov	a,l					;HL -= BC
	sub	c
	mov	l,a
	mov	a,h
	sbb	b
	mov	h,a
	jnc	L2CCD
	dad	b					;HL += BC
L2CCD:
; shift left DE and HL (operand)
; HL always 0 coming in
; Carry may be set
	mov	a,e					;E << 1
	ral						;rotate through carry	
	mov	e,a
	mov	a,d					;D << 1
	ral
	mov	d,a
	mov	a,l					;L << 1
	ral
	mov	l,a
	mov	a,h					;H << 1
	ral
	mov	h,a
	xthl					;exchange stack top with HL. HL now loop counter
	push	psw
	inr	l					;loop counter
	mov	a,l
	cpi	11h
	jnz	Local2CC1			;loop
;	
	pop	psw
	pop	h					;operand
	xchg					;HL <- DE
	mov	a,l					;complement HL
	cma
	mov	l,a
	mov	a,h
	cma
	mov	h,a
	ei
	ret
;
; called when V_CursorMode != TIME
;
CvtNumWinDistanceVolts:
	xra	a
	sta	V_bit_6_cleared
	sta	V_fUNCAL
	sta	V_fAVGVolts
	lda	V_CH1_Info
	sta	V_CH1_Info_Copy
	lda	V_CH2_Info
	sta	V_CH2_Info_Copy
	call LoadWFTableChanInfo ;get A from WFTable
	call Clr_bit_6_in_A
	mov	b,a					;save
	lda	V_bit_6_cleared		;boolean test
	ral
	mov	a,b					;restore
	jnc	L2D14				;jmp if bit 6 not cleared
	adi	03h					;A += 3
L2D14:	sta	V_AcqVolts		;save
	dcx	h					;HL still points to WFTable
	dcx	h
	mov	a,m					;V_WFTable[V_PrimaryWF].offset5
	ani	03h					;00000011
	cpi	03h					;A - 3
	jnz	$$L
	mvi	a,0FFh				;TRUE
	sta	V_fAVGVolts
$$L:
	lda	V_CursorMode
	cpi	03h
	jnz	$$L11
	call UpdateCplVTDispVal
	jmp	Local2D37
$$L11:
	call UpdateVoltsDispVal
Local2D37:	mvi	a,80h		;128
	lxi	h,V_UIVolts
	ana	m
	cpi	80h					;(0x80 & V_UIVolts) - 0x80
	jnz	$$L2
; V_UIVolts bit 7 was 1	
	mvi	a,0FAh				;250
	sta	V_SCALECode
	mvi	a,01h
	sta	VAR_8027
	jmp	$$L3
; V_UIVolts bit 7 was 0
$$L2:
	lda	V_UIVolts
	call MappedModulo3
	sta	VAR_8027
$$L3:
	lhld VAR_8027			;range 1..3
	mvi	h,00h
	lxi	d,V_CvtFreq2Volts-1	;get multiplication factor from table
	dad	d
	mov	a,m
	mov	e,a
	mvi	d,00h
	lhld V_NumWinValue
	call Multiply_HL_DE
	shld V_NumWinValue		;update
	ret
;
; in A
; inc A, then repeatedly subtract 3
; V_SCALECode updated
; out A is range 1..3
;
MappedModulo3:
	inr	a
	mvi	c,0FFh				;loop count
$$L:
	inr	c
	sui	03h
	jp	$$L
	mov	b,a					;save negative result
	mov	a,c					;V_SCALECode = (A + 1) / 3 - 4
	sui	04h
	sta	V_SCALECode
	mov	a,b					;restore
	adi	04h					;modulo 4
	ret
;
UpdateCplVTDispVal:
	call SetUIVolts
	lda	V_AcqVolts
	mov	b,a
	ani	80h					;10000000 UNCAL_BIT
	mov	a,b
	jz	L2D99
	mvi	a,0FFh
	sta	V_fUNCAL
	mov	a,b
	mvi	b,7Fh				;remove UNCAL_BIT
	ana	b
L2D99:
	sta	V_UIVolts
	lda	V_fAVGVolts			;boolean test
	ral
	jnc	L2DCE				;brif !V_fAVGVolts
	lda	V_UIVolts
	cpi	04h
	jnc	$$L					;brif V_UIVolts >= VOLTAGE4
	lhld V_NumWinValue		;special VGAIN correction
	call Multiply_HL_by_2.5	;times 1.25. See Finalize_Average
	call ShiftR_HL
	shld V_NumWinValue
$$L:
	lda	V_fUNCAL			;boolean test
	ral
	rnc						;done if !V_fUNCAL
; V_fUNCAL TRUE
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	SetUIVoltsUNCAL
; V_DigitalMode == DIGITAL_SAVE
	call UpdateChannelVolts
	ret
SetUIVoltsUNCAL:
	mvi	a,80h				;128
	sta	V_UIVolts
	ret
L2DCE:
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	jnz	L2DF7
; V_DigitalMode == DIGITAL_SAVE
	lda	V_fUNCAL			;boolean test
	ral
	jnc	$$L					;brif !V_fUNCAL
;
; UNCAL setting causes this UpdateChannelVolts() call because
; the 468 wants to show # divisions in UNCAL
;
	call UpdateChannelVolts
	lda	V_fUNCAL
	ana	a					;test
	rz						;done if FALSE
	mvi	a,80h				;128
	sta	V_UIVolts
	ret
$$L:
	lda	V_UIVolts		;Max(V_UIVolts, 4)
	cpi	04h
	rnc
	mvi	a,04h
	sta	V_UIVolts
	ret
; V_DigitalMode != DIGITAL_SAVE
L2DF7:
	lda	V_UIVolts
	cpi	04h
	jnc	L2E02				;brif V_UIVolts >= VOLTAGE4			
	call MultiplyNumWinValue
L2E02:
	lda	V_fUNCAL			;boolean test
	ral
	rnc						;done if !V_fUNCAL
	lda	V_UIVolts
	ori	80h					;set UNCAL_BIT
	sta	V_UIVolts
	ret
;
; update V_NumWinValue
;
; Very esoteric case:
;	CursorMode==CPLVT && DigitalMode==SAVE && Channel is uncalibrated.
;
UpdateChannelVolts:
	lda	V_UIVolts
	cpi	VOLTAGE4
	jnc	$$L 				;brif V_UIVolts >= 4
; V_UIVolts < VOLTAGE4
	lda	V_fAVGVolts			;boolean test
	ral
	lda	V_UIVolts			;preload
	jc	$$L					;brif V_fAVGVolts
; V_fAVGVolts == FALSE
	mvi	a,VOLTAGE4			;set minimum VOLTAGE4
$$L:
	mov	d,a					;save WF Volts
	lda	V_CH1_Info_Copy
	sta	V_UIVolts
	call NormalizeUIVolts2	;updates V_UIVolts
	lda	V_UIVolts
	ani	3Fh					;00111111 remove properties
	mov	e,a					;save UI Volts
	mov	a,d
	sub	e					;D - E
	rz						;return if E == D
	jc	L2E4B				;brif D < E
	cpi	4					;
	jp	L2E4F				;brif (D - E) >= 4
L2E3F:
	call VoltsMultiply		;in D, E. Returns multiplied V_NumWinValue
	shld V_NumWinValue
L2E45:
	mvi	a,80h				;10000000
	sta	V_UIVolts
	ret
L2E4B:
	mov	e,d					;E == D
	jmp	L2E45
L2E4F:
	mov	a,d					;E = D + 3
	adi	03h
	mov	e,a
	jmp	L2E3F				;jmp to VoltsMultiply
;
; in D,E
; out HL
;
VoltsMultiply:
	mov	a,e
	call MappedModulo3
	mov	e,a					;save arg2
	mov	a,d
	call MappedModulo3
	mov	b,a					;arg1
	mov	c,e					;arg2
	call ChannelMultiply2	;Multiply V_NumWinValue by 2, 4, 5, 10
	ret
;
MultiplyNumWinValue:
	lhld V_NumWinValue
	call Multiply_HL_by_2.5
	shld V_NumWinValue
	lda	V_UIVolts
	cpi	03h
	rz
	cpi	06h
	rz
	dad	h					;x2
	shld V_NumWinValue
	lda	V_UIVolts
	cpi	02h
	rz
	cpi	05h
	rz
	dad	h					;x2
	shld V_NumWinValue
	ret
;
; in A
; test bit 6. If != 0, clr bit 6
; sets boolean V_bit_6_cleared if bit 6 was cleared
;
Clr_bit_6_in_A:
	mov	b,a					;save
	ani	40h					;01000000
	mov	a,b					;restore
	rz						;done if not set
	mvi	a,0FFh				;TRUE
	sta	V_bit_6_cleared
	mvi	a,40h				;01000000
	cma						;10111111
	ana	b					;original in B: clr bit 6
	ret
;
; Only called once
;
UpdateVoltsDispVal:
	call SetUIVolts
	lda	V_DigitalMode
	cpi	DIGITAL_SAVE
	rnz
; V_DigitalMode == DIGITAL_SAVE
	lda	V_UIVolts
	mov	b,a					;save V_UIVolts
	ani	80h					;10000000
	rnz
	lda	V_AcqVolts
	ani	3Fh					;00111111 isolate Volts
	mov	c,a					;save uncorrected AcqVolts value
	cpi	04h
	jnc	L2EB5				;brif V_AcqVolts >= 4
	mvi	a,04h				;V_AcqVolts = VOLTAGE4: max hardware value
L2EB5:
	cmp	b					;V_AcqVolts - V_UIVolts
	jc	L2EDB				;brif V_UIVolts > V_AcqVolts: no amplification but set DIV LED
	sui	03h					;V_AcqVolts -= 3
	cmp	b					;V_UIVolts
	jc	L2EC3				;brif V_UIVolts >= (V_AcqVolts - 3) 
	jz	L2EC3
; V_UIVolts < (V_AcqVolts - 3) 
	mov	b,a					;update cached V_UIVolts to (V_AcqVolts - 3)
L2EC3:
	lda	V_fAVGVolts			;AVG mode?
	ral
	mov	a,b					;A = new V_UIVolts
	jnc	L2EDD				;brif !AVG mode
	cpi	04h					;new V_UIVolts - VOLTAGE4
	jnc	L2EDD				;brif new V_UIVolts >= VOLTAGE4. BUG sb > VOLTAGE4
	cmp	c					;V_AcqVolts
	jc	L2EDD				;brif V_AcqVolts >= new V_UIVolts
	jz	L2EDD
	mov	a,c					;new V_UIVolts = V_AcqVolts
	jmp	L2EDD
L2EDB:
	mvi	a,80h				;UNCAL_BIT
L2EDD:
	sta	V_UIVolts
	ret
;
; in B (arg1), C (arg2)
;	Arg1	Arg2
;	2		
; out HL Multiply V_NumWinValue by 2, 2.5, 4, 5, 10
;
ChannelMultiply2:
	lhld V_NumWinValue
	mov	a,b
	cpi	02h
	jnz	L2EF7
; arg1 == 2	
	dad	h					;x2
	mov	a,c
	cpi	01h
	rz
; arg2 != 1	
	dad	h					;x2 total x4
	cpi	03h
	rz
; arg2 != 3
	call Multiply_HL_by_2.5	;total x10
	ret
; arg1 != 2
L2EF7:	cpi	01h
	jnz	L2F0A
; arg1 == 1	
	dad	h					;x2
	mov	a,c
	cpi	03h
	rz
; arg2 != 3	
	call Multiply_HL_by_2.5 ;preserves C total x5
	mov	a,c
	cpi	02h
	rz
; arg2 != 2	
	dad	h					;x2 total x10
	ret
; arg1 != 1	
L2F0A:
	call Multiply_HL_by_2.5
	mov	a,c
	cpi	02h
	rz
; arg2 != 2	
	dad	h					;x2 total x5
	cpi	01h
	rz
; arg2 != 1	
	dad	h					;x2 total x10
	ret
;
; out HL points to V_WFTable[V_PrimaryWF].offset7
;
LoadWFTableChanInfo:
	lda	V_PrimaryWF			;base 1
	dcr	a					;base 0
	add	a					;x8
	add	a
	add	a
	inr	a					;+1
	mov	l,a
	mvi	h,00h
	lxi	d,V_WFTable-1
	dad	d
	lxi	d,0007H
	dad	d
	mov	a,m
	ret
;
;	
SetUIVolts:
	lda	V_fADD				;boolean test
	ral
	jc	L2F3E
	lda	V_fCH1
	lxi	h,V_fCH2
	ana	m
	ral
	jnc	L2FDD
L2F3E:
	lda	V_CursorMode
	cpi	03h
	jnz	L2F4E
	lda	V_fADD				;boolean test
	cma
	ral
	jc	L2F51
L2F4E:
	jmp	L2F5A
L2F51:
	lda	V_CH1_Info_Copy
	sta	V_UIVolts
	jmp	L2FDA
L2F5A:
	lda	V_CH2_Info_Copy
	lxi	h,V_CH1_Info_Copy
	cmp	m
	jnz	L2F6D
	lda	V_CH1_Info_Copy
	sta	V_UIVolts
	jmp	L2FDA
L2F6D:
	mvi	a,40h				;01000000
	lxi	h,V_CH1_Info_Copy
	ana	m
	cpi	40h					;test bit 6
	jnz	L2FA8
; V_CH1_Info_Copy bit 6 was 0
	mvi	a,40h				;10111111
	cma
	lxi	h,V_CH1_Info_Copy
	ana	m					;get all but bit 6.
	adi	03h					;A += 3
	sta	V_CH1_Info_Copy		;update.
	mvi	a,0FFh
	sta	V_bit_6_cleared		;unused
	lda	V_CH2_Info_Copy
	lxi	h,V_CH1_Info_Copy
	cmp	m
	jnz	L2F9C
	lda	V_CH1_Info_Copy
	sta	V_UIVolts
	jmp	L2FA5
L2F9C:
	mvi	a,80h				;10000000
	sta	V_UIVolts
	xra	a
	sta	V_bit_6_cleared
L2FA5:	jmp	L2FDA
; V_CH1_Info_Copy bit 6 was 1
L2FA8:
	lda	V_CH2_Info_Copy
	ani	40h					;01000000
	cpi	40h
	jnz	L2FD5
; V_CH2_Info_Copy bit 6 was 0
	mvi	a,40h				;10111111
	cma
	lxi	h,V_CH2_Info_Copy
	ana	m					;get all but bit 6.
	adi	03h					;A += 3
	lhld V_CH1_Info_Copy
	call Test_Equal_A_L
	jnc	L2FCD				;jmp if not equal
	lda	V_CH1_Info_Copy
	sta	V_UIVolts
	jmp	L2FD2
L2FCD:
	mvi	a,80h				;128
	sta	V_UIVolts
L2FD2:	jmp	L2FDA
L2FD5:
	mvi	a,80h				;128
	sta	V_UIVolts
L2FDA:	jmp	L3002
L2FDD:
	lda	V_fCH1
	ral
	jnc	L2FED
	lda	V_CH1_Info_Copy
	sta	V_UIVolts
	jmp	L3002
L2FED:
	lda	V_fCH2				;boolean test
	ral
	jnc	L2FFD
	lda	V_CH2_Info_Copy
	sta	V_UIVolts
	jmp	L3002
L2FFD:
	mvi	a,80h				;10000000
	sta	V_UIVolts
L3002:						;see NormalizeUIVolts2
	lda	V_UIVolts
	ani	40h					;01000000
	cpi	40h
	jnz	L3018
	mvi	a,40h				;10111111
	cma
	lxi	h,V_UIVolts
	ana	m					;get all but bit 6.
	adi	03h					;A += 3
	sta	V_UIVolts
L3018:	ret
;
NormalizeUIVolts2:
	lda	V_UIVolts
	ani	40h					;01000000 PROBEBIT
	cpi	40h
	jnz	L302F
; V_UIVolts PROBEBIT was 1	
	mvi	a,40h				;10111111
	cma						;~PROBEBIT
	lxi	h,V_UIVolts
	ana	m					;clr V_UIVolts PROBEBIT 
	adi	03h					;A += 3
	sta	V_UIVolts
L302F:	ret
;
; part of Action 6
;
Set_Rate_Direction:
	lda	V_CursorMode
	cpi	04h					;NUMWINSWEEPS
	jnz	L3062
	lda	DEV_CURSOR
	ani	40h					;01000000 RATE/POS
	cpi	40h
	jnz	L3062
;
; RATE Active
;	
	lhld V_PRCount
	xchg					;V_PRCount -> DE
	lxi	h,0138h				;312d
	mov	a,e					;V_PRCount - 0138h
	sub	l
	mov	a,d
	sbb	h
	jc	L3058
	mvi	a,01h
	sta	V_Rate_Direction
	jmp	L305D
L3058:	mvi	a,0FFh
	sta	V_Rate_Direction
L305D:	mvi	a,0FFh
	sta	V_TimerCntrSweepsIncrement
L3062:	ret
;
; Convert V_PRCount (word)
;
U788_BCD_2_Binary:
	lda	V_PRCount+1
	rlc						;x2
	mov	b,a					;save
	rlc						;x4
	rlc
	add	b					;V_PRCount+1 x 6
	mov	c,a					;save
	lda	V_PRCount
	rrc						;move upper 4 bits to low nibble
	rrc
	rrc
	rrc
	ani	0Fh					;00001111
	add	c					;V_PRCount+1 x 6
	rlc						;x2
	mov	e,a					;DE
	xra	a
	mov	d,a
	mov	h,a					;H = 0
	mov	a,e					;x2
	ral
	jnc	Local3083
	cmc
	inr	h					;H += 2
	inr	h
Local3083:	ral
	jnc	L3089
	cmc
	inr	h
L3089:	mov	l,a
	dad	d
	lda	V_PRCount			;reload
	ani	0Fh					;00001111 lower nibble
	mov	e,a					;to E
	dad	d
	shld V_PRCount			;update V_PRCount (word)
	ret
;
; update V_TimeCursorPos+2 .. V_VoltsCursorPos
;
ConstrainVoltsTimeCursor:
	lxi	h,V_WFTable+S_STATUS ;p
	lda	V_PrimaryWF			;base 1
	dcr	a					;base 0
	rlc						;x8
	rlc
	rlc
	mov	e,a
	mvi	d,00h
	dad	d					;p = V_WFTable[V_PrimaryWF]+S_STATUS
	mov	a,m					;get byte *p
	ani	LONGWFMASK			;01000000 test bit 6
	cpi	LONGWFMASK
	mvi	a,03h
	jz	$$L
	mvi	a,06h
$$L:
	sta	VAR_8016			;3 or 6
	mov	c,a					;save
	lxi	h,V_TimeCursorPos+2+1 ;p points to MSB
	mvi	b,04h				;loop counter
;loop	
Loop30B9:
	mov	d,m					;DE = *(word *)(p-1)
	dcx	h
	mov	e,m
	inx	h
	mov	a,d					;test D (MSB)
	ana	a
	jm	$$L 				;L30CA
	jnz	$$L1 				;L30D2
; D == 0	
	mov	a,e
	cmp	c					;3 or 6
	jnc	$$L2				;done
$$L:
	mvi	m,00h				;*(word *)(p-1) = (word)C
	dcx	h
	mov	m,c
	inx	h
	jmp	$$L2				;done
$$L1:
	mov	a,d
	cpi	04h
	jc	$$L2				;done
	mvi	m,03h				;*(word *)(p-1) = 0x03ff
	dcx	h
	mvi	m,0FFh
	inx	h
$$L2:
	dcx	h					;p -= 2
	dcx	h
	dcr	b					;loop 4 times
	jnz	Loop30B9
	ret
;
;
;
Main_Action_1_0:
	lda	V_CursorMode
	cpi	04h
	jnz	L3114
; V_CursorMode == 4	
	lda	V_DigitalMode
	cpi	DIGITAL_AVG
	jnz	L30FB
	lhld V_AVG_Sweeps
	jmp	L3101
; V_DigitalMode != 3
L30FB:	cpi	DIGITAL_ENV
	rnz						;V_DigitalMode != 2
	lhld V_ENV_Sweeps
L3101:
	shld V_BCD_Input
	call Convert_2_BCD
;
L3107:
	mvi	a,0E0h
	sta	V_LedCode			;V_LedCode = 0xe0
	mvi	a,05h
	sta	V_DecPoint			;V_DecPoint = 0x05
	jmp	L312B
; V_CursorMode != 4	
L3114:	cpi	05h				;A = V_CursorMode
	jnz	L3125
; V_CursorMode == 5
	lhld V_Sweep_Cnt1
	shld V_BCD_Input
	call Convert_2_BCD
	jmp	L3107
; V_CursorMode != 5	
L3125:
	cpi	00h					;A = V_CursorMode
	rz						;V_CursorMode == 0 done
	call PrepNumWin			;update V_SCALECode2, V_DecPoint, V_LedCode
L312B:	mvi	a,01h
	sta	V_TMP8154
	lxi	h,0F000H			;nibble bit pattern
	shld VAR_8155
; loop
L3136:	lda	V_TMP8154
	mvi	l,04h
	call Compare_A_L		;return FALSE/CY Clr if A >= L (signed)
; A <= L
	jnc	L318A
	lhld VAR_8155
	xchg
	lhld V_BCD_Input
	mov	a,e					;V_BCD_Input = VAR_8155 & V_BCD_Input
	ana	l
	mov	l,a
	mov	a,d
	ana	h
	mov	h,a
	mov	a,l					;test HL
	ora	h
	jnz	L315D
; HL == 0	
	lda	V_TMP8154
	lxi	h,V_DecPoint
	cmp	m
	jc	L3160
L315D:	jmp	L3173			;exit loop
L3160:	lhld VAR_8155
	xchg
	lhld V_BCD_Input
	mov	a,e					;V_BCD_Input = VAR_8155 | V_BCD_Input
	ora	l
	mov	l,a
	mov	a,d
	ora	h
	mov	h,a
	shld V_BCD_Input
	jmp	L3176
L3173:	jmp	L318A			;exit loop
L3176:	lhld VAR_8155		;[VAR_8155] >>= 4. Next 4 bits
	xchg
	lxi	h,0004H
	call ShiftR_DE_L_times
	shld VAR_8155
	lxi	h,V_TMP8154			;[V_TMP8154]++
	inr	m
	jmp	L3136
L318A:	mvi	a,04h			;loop count
	sta	V_TMP814D
;
; critical region
;	
	di
	lda	V_CursorMode
	cpi	00h
	jz	L31DD				;nothing to display
	lda	V_LedCode			;V_Curr_LEDRO = V_LedCode
	sta	V_Curr_LEDRO
	lda	V_DecPoint			;V_DecPntDigit = V_DecPoint
	sta	V_DecPntDigit
;loop 4 times
L31A4:	lda	V_TMP814D
	mvi	l,00h
	call Signed_Compare_A_L	;return TRUE/CY set if A > L (signed)
	jnc	L31DD				;done
; A > 0
	lxi	d,000FH				;lowest 4 bits
	lhld V_BCD_Input		;V_BCD_Input & 000FH
	mov	a,e
	ana	l
	mov	l,a					;L = L & 0xff
	mov	a,d
	ana	h
	mov	h,a					;H = H & 0
	mov	b,h					;BC = HL. H = 0
	mov	c,l					;2 BCD values
	lhld V_TMP814D			;only want L
	call SignExtend_L_in_H	;sign extend L into H.
	lxi	d,V_NumWinBuf-1
	dad	d
	mov	a,c
	mov	m,a
	lxi	h,V_TMP814D			;[V_TMP814D]--
	dcr	m
	lhld V_BCD_Input		;V_BCD_Input >>=, next 4 bits
	xchg
	lxi	h,0004H
	call ShiftR_DE_L_times
	shld V_BCD_Input
	jmp	L31A4				;loop
;
; end critical region
;	
L31DD:	ei
	ret
;
; in V_BCD_Input
; updates V_BCD_Input (word), V_SCALECode2 (byte)
;
Convert_2_BCD:
	call Convert_2_BCD_0	;sets variable V_BCD_Result (3 bytes, 2 BCD each byte)
	lhld V_BCD_Result		;first 2 results (byte 0, 1)
	lda	V_BCD_Result+2		;3rd result, byte 2
	ana	a					;test A
	jz	L3205
;
; BCD result doesn't fit in 4 BCD digits
;	
	mvi	b,04h				;loop 4 times -> divide V_BCD_Result by 16
$$L:
	call ShiftR_HL			;V_BCD_Result >> 4. Forget lowest BCD result
							;make room for new highest BCD digit
	dcr	b
	jnz	$$L
	lda	V_BCD_Result+2		;V_BCD_Result+2 << 4.
	add	a
	add	a
	add	a
	add	a
	ora	h					;Make this highest BCD digit in V_BCD_Result
	mov	h,a				
	lda	V_SCALECode2		;increment decimal point position
	inr	a
	sta	V_SCALECode2
L3205:
	shld V_BCD_Input		;store HL in V_BCD_Input, V_BCD_Input+1
	ret
;
; computes V_BCD_Result (word) and V_BCD_OVERFLOW (byte)
; Loaded from V_BCD_Input (external)
;
Convert_2_BCD_0:
	xra	a
	sta	V_BCD_Result+2		;MSB
	xra	a
	sta	V_BCD_Result+1
	xra	a
	sta	V_BCD_Result		;LSB
	lhld V_BCD_Input
	mvi	c,10h				;for every bit in V_BCD_Input
; outer loop. Shift most significant bit of HL in CY
; and shift it to the corresponding position in V_BCD_Result,
; correcting for BCD result.
$$L1:
	dad	h					;<< 1. bit 15 to CY
	lxi	d,V_BCD_Result		;reset
	mvi	b,03h				;for every digit in V_BCD_Result
; inner loop doubles 3 V_BCD_Result digits and adds CY from "dad h"
$$L: ldax d
	adc	a					;include CY from "dad h".
; if adc causes an overflow from bit 3 to bit 4 (lower BCD overflow), add 06h
; if adc sets carry	(overflow from bit 7, higher BCD overflow), add 60h
	daa						;may set CY which is then carried forward to adc in next loop
	stax d
	inx	d
	dcr	b
	jnz	$$L
	dcr	c
	jnz	$$L1
	ret
;
; update V_SCALECode2, V_DecPoint, V_LedCode
;
PrepNumWin:
	lhld V_NumWinValue
	shld V_BCD_Input
	lda	V_SCALECode
	sta	V_SCALECode2
	call Convert_2_BCD
	lda	V_SCALECode2
	mvi	l,0FCh
	call Compare_A_L		;return FALSE/CY Clr if A >= L (signed)
	jnc	L3250				;jmp if V_SCALECode2 >= 0xfc
	mvi	a,60h				;SCALE_TOP|SCALE_MID off -> SCALE_BOT
	sta	V_LedCode			;V_LedCode = 0x60
	jmp	L3268
L3250:	lda	V_SCALECode2
	mvi	l,0FFh
	call Compare_A_L		;return FALSE/CY Clr if A >= L (signed)
	jnc	L3263				;jmp if V_SCALECode2 >= 0xff
	mvi	a,0A0h				;SCALE_TOP|SCALE_BOT off -> SCALE_MID
	sta	V_LedCode			;V_LedCode = 0xa0
	jmp	L3268
L3263:	mvi	a,0C0h			;SCALE_BOT|SCALE_MID off -> SCALE_TOP
	sta	V_LedCode			;V_LedCode = 0xc0
L3268:	lda	V_SCALECode2
	mvi	l,0FFh
	call Test_Equal_A_L
	jc	L3289				;jmp if V_SCALECode2 == 0xff
	lda	V_SCALECode2
	mvi	l,0FCh
	call Test_Equal_A_L
	jc	L3289				;jmp if V_SCALECode2 == 0xfc
	lda	V_SCALECode2
	mvi	l,0F9h
	call Test_Equal_A_L
	jnc	L3291				;jmp if V_SCALECode2 != 0xf9
L3289:	mvi	a,01h			;V_DecPoint = 1
	sta	V_DecPoint
	jmp	L32E8
L3291:	lda	V_SCALECode2
	mvi	l,00h
	call Test_Equal_A_L
	jc	L32B2				;jmp if V_SCALECode2 == 0
	lda	V_SCALECode2
	mvi	l,0FDh
	call Test_Equal_A_L
	jc	L32B2				;jmp if V_SCALECode2 == 0xfd
	lda	V_SCALECode2
	mvi	l,0FAh
	call Test_Equal_A_L
	jnc	L32BA				;jmp if V_SCALECode2 != 0xfa
L32B2:	mvi	a,02h
	sta	V_DecPoint
	jmp	L32E8
L32BA:	lda	V_SCALECode2
	mvi	l,01h
	call Test_Equal_A_L
	jc	L32DB				;jmp if V_SCALECode2 == 1
	lda	V_SCALECode2
	mvi	l,0FEh
	call Test_Equal_A_L
	jc	L32DB				;jmp if V_SCALECode2 == 0xfe
	lda	V_SCALECode2
	mvi	l,0FBh
	call Test_Equal_A_L
	jnc	L32E3				;jmp if V_SCALECode2 != 0xfb
;	
L32DB:	mvi	a,03h			;V_DecPoint = 3
	sta	V_DecPoint
	jmp	L32E8
L32E3:	mvi	a,04h			;V_DecPoint = 4
	sta	V_DecPoint
L32E8:	ret
;
;
Action_0x7C_0:
	lda	DEV_ATNFLS
	call Get_GPIB_Status
	lda	V_GPIB_Bool7
	ana	a					;boolean test
	jp	L334B
	lda	V_GPIB_Bool5
	ana	a					;boolean test
	jp	L3314
	mvi	a,0FFh
	sta	V_GPIB_Bool4
	mvi	a,0FBh
	call Update_DEV_WIFCTL_and
	mvi	a,7Dh
	call AddMainAction
	mvi	a,0FEh				;11111110	
	call Update_DEV_FPC_and
	jmp	L334B
L3314:	mvi	a,0FFh
	sta	V_GPIB_Bool3
	mov	b,a
	lda	V_GPIB_ActionWasRemoved
	mov	c,a
	lda	V_GPIB_XmittingWF
	ana	c
	jp	L3336
	lxi	h,VAR_800E
	mvi	a,84h				;of action 0x84, replace with 0x80
	cmp	m
	jnz	L3330
	mvi	m,80h
L3330:
	lda	VAR_800E
	call AddMainAction
L3336:	xra	a
	sta	V_GPIB_ActionWasRemoved
	lda	V_GPIB_XmittingWF
	cma
	mov	b,a
	lda	V_GPIB_MTAReceived
	ana	b
	jp	L334B
	mvi	a,0FFh
	sta	V_GPIB_Bool2
L334B:
	mvi	a,0FFh
	sta	V_GPIB_Bool9
	di
	rim
	ori	08h
	ani	0Eh
	sim
	ei
	ret
;
;	
Action_0x7B_0:
	call Get_GPIB_Status
	mvi	a,0F5h
	call Update_DEV_WIFCTL_and
	lda	V_GPIB_RATN
	ana	a
	jm	L337E
	lda	V_TALKREG
	ana	a
	jp	L3379
	mvi	a,21h
	call L2095
	mvi	a,80h
	call Update_DEV_FPC_or
L3379:	mvi	a,7Ch
	jmp	L3439
L337E:	lda	V_GPIB_ATNDAV
	ana	a
	jp	L3437
	lda	DEV_RIFDI
	ani	7Fh
	cpi	TB20
	jnz	L33BD
	xra	a
	sta	V_GPIB_MTAReceived
	sta	V_GPIB_Bool2
	sta	V_GPIB_XmittingWF
	sta	V_GPIB_ActionWasRemoved
	sta	V_GPIB_XmitWFRQSFActive
	lda	VAR_8006
	ana	a
	jm	L33B5
	mvi	a,0FBh
	call Update_DEV_WIFCTL_and
	mvi	a,0FEh
	call Update_DEV_FPC_and
	mvi	a,00h
	jmp	L33B7
L33B5:	mvi	a,41h
L33B7:	sta	V_GPIBOut
	jmp	L341F
L33BD:	cpi	18h
	jnz	L33CF
	mvi	a,0FFh
	sta	V_GPIB_Bool5
	mvi	a,20h
	call L2095
	jmp	L341F
L33CF:	cpi	19h
	jnz	L33DB
	xra	a
	sta	V_GPIB_Bool5
	jmp	L341F
L33DB:	cpi	5Fh
	jnz	L33ED
	mvi	a,0FEh
	call Update_DEV_WIFCTL_and
	mvi	a,7Fh
	call Update_DEV_FPC_and
	jmp	L341F
L33ED:	mov	b,a
	lda	V_TALKADDR
	cmp	b
	mov	a,b
	jnz	L3408
	mvi	a,21h
	call L2095
	mvi	a,80h
	call Update_DEV_FPC_or
	mvi	a,0FFh
	sta	V_GPIB_MTAReceived
	jmp	L341F
L3408:	cpi	5Eh
	jz	L3410
	jnc	L341F
L3410:	cpi	40h
	jc	L341F
	mvi	a,0FEh
	call Update_DEV_WIFCTL_and
	mvi	a,7Fh
	call Update_DEV_FPC_and
L341F:	mvi	a,0FFh
	sta	DEV_DATACC
	call Get_GPIB_Status
	lda	V_GPIB_Bool5
	mov	b,a
	lda	V_GPIB_Bool7
	ora	b
	jm	L3437
L3432:
	mvi	a,0DFh
	call Update_DEV_WIFCTL_and
L3437:
	mvi	a,7Bh
L3439:
	call AddMainAction
	ret
;
Action_0x7A_0:
	call Get_GPIB_Status
	lda	V_GPIB_Bool6
	ral
	jnc	L344F
	mvi	a,7Ah
	call AddMainAction
	jmp	L3454
L344F:	mvi	a,7Bh
	call AddMainAction
L3454:	ret
;
Action_0x83_0:
	call Get_GPIB_Status
	di
	lda	V_GPIB_ActionWasRemoved
	ral
	rc
	lda	V_GPIB_NRFD
	mov	b,a
	lda	V_GPIB_NDAC
	ana	b
	jp	L34BD
	lda	V_WIFDO
	sta	DEV_WIFDO
	lda	V_GPIB_EndOfMessage
	ral
	lxi	h,V_WIFCTL
	jnc	L34A3
	mvi	a,08h
	ora	m
	mov	m,a
	xra	a
	sta	V_GPIB_XmittingWF
	sta	V_GPIB_XmitWFRQSFActive
	lda	V_TALKREG
	sta	V_GPIB_MTAReceived
	mvi	a,00h
	sta	V_GPIBOut
	lda	VAR_8006
	ral
	jc	L34A0
	mvi	a,0FBh
	call Update_DEV_WIFCTL_and
	mvi	a,0FEh
	call Update_DEV_FPC_and
L34A0:	jmp	L34AD
L34A3:	mvi	a,08h
	cma
	ana	m
	mov	m,a
	mvi	a,84h
	call AddMainAction
L34AD:	mvi	a,0FDh
	call Update_DEV_WIFCTL_and
	mvi	a,0FFh
	sta	DEV_SNTACK
	mvi	a,02h
	call L2095
	ret
L34BD:	mvi	a,83h
	call AddMainAction
	ret
;	
Action_0x7E_0:
	di
	lda	V_GPIB_Bool9
	ana	a					;boolean test
	jp	L34D8
	sta	V_GPIB_XmitWFRQSFActive
	mvi	a,79h
	call AddMainAction
	mvi	a,82h
	jmp	L34DA
L34D8:	mvi	a,7Eh
L34DA:
	call AddMainAction
	ret
;	
Action_0x84_0:
	call Get_GPIB_Status
	di
	lda	V_GPIB_ActionWasRemoved
	ral
	rc
	lda	V_GPIB_Bool8
	ral
	jc	L34F3
	mvi	a,84h
	jmp	L34F5
L34F3:	mvi	a,80h
L34F5:	call AddMainAction
	ret
;
;
Action_0x7D_0:
	call Get_GPIB_Status
	di
	lda	V_GPIB_Bool4
	mov	b,a
	lda	V_GPIB_Bool9
	ana	b
	rp
	lda	V_GPIB_NRFD
	mov	b,a
	lda	V_GPIB_NDAC
	ana	b
	jp	L3533
	lxi	h,V_GPIBOut
	mov	a,m
	sta	DEV_WIFDO
	ani	40h
	jz	L3528
	xra	a
	sta	V_GPIB_XmitWFRQSFActive
	sta	VAR_8006
	mov	a,m
	ani	0BFh
	mov	m,a
L3528:	mvi	a,0FFh
	sta	DEV_SNTACK
	mvi	a,02h
	call L2095
	ret
L3533:	mvi	a,7Dh
	call AddMainAction
	ret
;
; VAR_8168 is local
;
Action_0x80_0:
	di
	lda	V_GPIB_ActionWasRemoved
	ral
	rc
	lda	V_GPIBStage
	lxi	h,V_GPIB_cnt0
	cpi	01h
	jnz	L3573
	mov	a,m
	inx	h
	ora	m
	jnz	L355E
	sta	VAR_8168
	sta	V_GPIB_EndOfMessage
	dcx	h
	inr	m
	lxi	h,GPIB_txt_3
	shld V_GPIB_txt
L355E:
	call Update_V_WIFDO
	cpi	3Bh
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,06h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3573:	cpi	06h
	jnz	L35FA
	mov	a,m
	inx	h
	ora	m
	jnz	L35DA
L357E:	lxi	h,VAR_8168
	inr	m
	mvi	a,04h
	cmp	m
	jc	L3594
	mov	e,m
	mvi	d,00h
	lxi	h,V_ValidWFs-1
	dad	d
	mov	a,m
	ral
	jnc	L357E
L3594:	lda	VAR_8168
	cpi	05h
	jc	L35A9
	mvi	a,0Ah
	sta	V_WIFDO
	mvi	a,0FFh
	sta	V_GPIB_EndOfMessage
	jmp	L3C89
L35A9:	mvi	a,3Bh
	sta	V_WIFDO
	lxi	h,V_WFTable
	lda	VAR_8168			;some Display Area index base 1
	dcr	a					;base 0
	add	a					;x8
	add	a
	add	a
	mov	e,a
	mvi	d,00h
	dad	d
	shld VAR_8176
	lxi	h,GPIB_txt_4
	shld V_GPIB_txt
	lda	VAR_8168
	cpi	01h
	jnz	L35D0
	call Update_V_WIFDO
L35D0:	lhld V_GPIB_cnt0
	inx	h
	shld V_GPIB_cnt0
	jmp	L3C89
L35DA:	lhld V_GPIB_txt
	mov	a,m
	sta	V_WIFDO
	cpi	20h
	jnz	L35F3
	lxi	h,V_GPIBStage
	mvi	m,07h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L35F3:	inx	h
	shld V_GPIB_txt
	jmp	L3C89
L35FA:	cpi	07h
	jnz	L3694
	mov	a,m
	inx	h
	ora	m
	jnz	L3659
	mvi	m,00h
	dcx	h
	mvi	m,01h
	lxi	h,GPIB_txt_5
	shld V_GPIB_txt
	lhld VAR_8176
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	30h
	lxi	h,GPIB_txt_6
	cpi	10h
	jnz	L3626
	lxi	h,GPIB_txt_7
L3626:	cpi	30h
	jnz	L362E
	lxi	h,GPIB_txt_8
L362C:	equ	362CH
L362E:	cpi	20h
	jnz	L3636
	lxi	h,GPIB_txt_9
L3636:
	shld V_GPIB_Ptr2
	lhld VAR_8176
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	03h
	lxi	h,GPIB_txt_10
	cpi	02h
	jnz	L364E
	lxi	h,GPIB_txt_11
L364E:	cpi	03h
	jnz	L3656
	lxi	h,GPIB_txt_12
L3656:	shld V_GPIB_Ptr3
L3659:	call Update_V_WIFDO
	cpi	22h
	jnz	L367F
	lxi	h,V_GPIB_cnt0
	inr	m
	mov	a,m
	cpi	04h
	jc	L3676x
	dcx	h
	mvi	m,08h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3676x:
	lhld V_GPIB_Ptr3
	shld V_GPIB_txt
	jmp	L3C89
L367F:	cpi	20h
	jnz	L3C89
	lhld V_GPIB_cnt0
	inx	h
	shld V_GPIB_cnt0
	lhld V_GPIB_Ptr2
	shld V_GPIB_txt
	jmp	L3C89
L3694:	cpi	08h
	jnz	L36F8
	mov	a,m
	inx	h
	ora	m
	jnz	L36D5
	dcx	h
	inr	m
	lhld VAR_8176
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	04h
	cpi	04h
	jnz	L36BA
	lxi	d,0200H
	lxi	h,GPIB_txt_14
	jmp	L36C0
L36BA:	lxi	d,0100H
	lxi	h,GPIB_txt_15
L36C0:	shld V_GPIB_Ptr1
	xchg
	shld VAR_8174
	mvi	a,2Ch
	sta	V_WIFDO
	lxi	h,GPIB_txt_13
	shld V_GPIB_txt
	jmp	L3C89
L36D5:	call Update_V_WIFDO
	cpi	3Ah
	jnz	L36E6
	lhld V_GPIB_Ptr1
	shld V_GPIB_txt
	jmp	L36F5
L36E6:	cpi	2Ch
	jnz	L36F5
	lxi	h,V_GPIBStage
	mvi	m,09h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
L36F5:	jmp	L3C89
L36F8:	cpi	09h
	jnz	L3720x
	mov	a,m
	inx	h
	ora	m
	jnz	L370B
	dcx	h
	inr	m
	lxi	h,GPIB_txt_16
	shld V_GPIB_txt
L370B:	call Update_V_WIFDO
	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,0Ah
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3720x:	cpi	0Ah
	jnz	L37DD
	mov	a,m
	inx	h
	ora	m
	jnz	L3796
	lhld VAR_8176
	lxi	d,0006H
	dad	d
	mov	a,m
	cpi	15h
	jc	L373A
	mvi	a,TB20
L373A:	mov	b,a
L373B:	sui	03h
	jp	L373B
	adi	04h
	mov	c,a
	sta	VAR_816A
	lhld VAR_8176
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	04h
	cpi	00h
	jnz	L375C
	mov	a,c
	adi	03h
	sta	VAR_816A
L375C:	mov	a,b
	inr	a
	mvi	d,00h
L3760:	inr	d
	sui	03h
	jp	L3760
	dcr	d
	mov	a,d
L3768:	sui	03h
	jp	L3768
	inr	a
	jp	L3773
	cma
	inr	a
L3773:	sta	VAR_816B
	mov	a,b
	cpi	08h
	jnc	L3781
	mvi	a,01h
	jmp	L378D
L3781:	cpi	11h
	jnc	L378B
	mvi	a,02h
	jmp	L378D
L378B:	mvi	a,03h
L378D:	sta	VAR_816D
	lxi	h,GPIB_txt_17
	shld V_GPIB_txt
L3796:	call Update_V_WIFDO
	lxi	h,V_GPIB_cnt0
	inr	m
	mov	a,m
	cpi	06h
	jnz	L37B3
	lxi	h,Number5
	lda	VAR_816A
	mov	e,a
	mvi	d,00h
	dad	d
	shld V_GPIB_txt
	jmp	L3C89
L37B3:	cpi	08h
	jc	L3C89
	lda	VAR_816B
	ana	a
	jz	L37CB
	dcr	a
	sta	VAR_816B
	mvi	a,30h
	sta	V_WIFDO
	jmp	L3C89
L37CB:	mvi	a,2Ch
	sta	V_WIFDO
	lxi	h,V_GPIBStage
	mvi	m,0Bh
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L37DD:	cpi	0Bh
	jnz	L3807
	mov	a,m
	inx	h
	ora	m
	jnz	L37F2
	lxi	h,GPIB_txt_18
	shld V_GPIB_txt
	lxi	h,V_GPIB_cnt0
	inr	m
L37F2:	call Update_V_WIFDO
	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,0Ch
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3807:	cpi	0Ch
	jnz	L386D
	mov	a,m
	inx	h
	ora	m
	jnz	L381A
	dcx	h
	inr	m
	lxi	h,GPIB_txt_22
	shld V_GPIB_txt
L381A:	call Update_V_WIFDO
	cpi	3Ah
	jnz	L385B
	lhld VAR_8176
	inx	h
	inx	h
	inx	h
	inx	h
	inx	h
	mov	a,m
	ani	08h
	cpi	08h
	lhld VAR_8174
	mov	a,h
	jnz	L3847
	cpi	01h
	jz	L3841
	lxi	h,GPIB_txt_37
	jmp	L3855
L3841:	lxi	h,GPIB_txt_36
	jmp	L3855
L3847:	cpi	01h
	jz	L3852
	lxi	h,GPIB_txt_39
	jmp	L3855
L3852:	lxi	h,GPIB_txt_38
L3855:	shld V_GPIB_txt
	jmp	L3C89
L385B:	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,0Dh
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L386D:	cpi	0Dh
	jnz	L38C4
	mov	a,m
	inx	h
	ora	m
	jnz	L3897
	lda	VAR_816D
	lxi	h,GPIB_txt_21
	cpi	01h
	jnz	L3886
	lxi	h,GPIB_txt_19
L3886:	cpi	02h
	jnz	L388E
	lxi	h,GPIB_txt_20
L388E:	shld V_GPIB_Ptr1
	lxi	h,GPIB_txt_23
	shld V_GPIB_txt
L3897:	call Update_V_WIFDO
	lxi	h,V_GPIB_cnt0
	inr	m
	cpi	3Ah
	jnz	L38AC
	lhld V_GPIB_Ptr1
	shld V_GPIB_txt
	jmp	L3C89
L38AC:	mvi	a,08h
	cmp	m
	jnc	L3C89
	mvi	a,2Ch
	sta	V_WIFDO
	lxi	h,V_GPIBStage
	mvi	m,0Eh
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L38C4:	cpi	0Eh
	jnz	L3A2D
	mov	a,m
	inx	h
	ora	m
	jnz	L397D
	xra	a
	sta	VAR_817E			;set to False
	sta	VAR_817F
	sta	VAR_8180
	lxi	h,GPIB_txt_24
	shld V_GPIB_txt
	lhld VAR_8176
	lxi	d,0007H
	dad	d
	mov	a,m
	mov	b,a
	ani	80h
	jz	L38F2
	mvi	a,0FFh				;set to TRUE
	sta	VAR_817F
L38F2:	mov	a,b
	ani	40h
	jz	L38FD
	mvi	a,0FFh
	sta	VAR_8180			;set to TRUE
L38FD:	mov	a,b
	ani	3Fh
	cpi	04h
	jnc	L391B
	mov	b,a
	dcx	h
	dcx	h
	mov	a,m
	ani	03h
	cpi	03h
	jnz	L3919
	mvi	a,0FFh
	sta	VAR_817E			;set to TRUE
	mov	a,b
	jmp	L391B
L3919:	mvi	a,04h
L391B:	mov	b,a
	lda	VAR_817F			;boolean test
	ral
	jnc	L3928
	mvi	a,01h
	jmp	L393F
L3928:	lda	VAR_8180		;boolean test
	ral
	jnc	L3933
	mov	a,b
	adi	03h
	mov	b,a
L3933:	mov	a,b
	sta	VAR_8165
	inr	a
L3938:	sui	03h
	jp	L3938
	adi	04h
L393F:	sta	VAR_816A
	mov	a,b
	cpi	07h
	jnc	L394D
	mvi	a,01h
	jmp	L3963
L394D:	cpi	10h
	jnc	L3957
	mvi	a,02h
	jmp	L3963
L3957:	jnz	L395F
	mvi	a,03h
	jmp	L3963
L395F:	mvi	b,0Bh
	mvi	a,04h
L3963:	sta	VAR_8166
	lda	VAR_8165
	dcr	a
	mvi	c,00h
L396C:	inr	c
	sui	03h
	jp	L396C
	mov	a,c
L3973x:	sui	03h
	jp	L3973x
	adi	03h
	sta	VAR_816B
L397D:	call Update_V_WIFDO
	lxi	h,V_GPIB_cnt0
	inr	m
	cpi	3Ah
	jnz	L39ED
	lda	VAR_817E			;boolean test
	ral
	jnc	L39E0
	lda	VAR_817F			;boolean test
	ral
	jnc	L399D
	lxi	h,GPIB_txt_40
	jmp	L39DA
L399D:	lda	VAR_8165
	cpi	01h
	jnz	L39AB
	lxi	h,GPIB_txt_41
	jmp	L39DA
L39AB:	cpi	02h
	jnz	L39B6
	lxi	h,GPIB_txt_42
	jmp	L39DA
L39B6:	cpi	03h
	jnz	L39C1
	lxi	h,GPIB_txt_43
	jmp	L39DA
L39C1:	cpi	04h
	jnz	L39CC
	lxi	h,GPIB_txt_44
	jmp	L39DA
L39CC:	cpi	05h
	jnz	L39D7
	lxi	h,GPIB_txt_45
	jmp	L39DA
L39D7:
	lxi	h,GPIB_txt_46
L39DA:
	shld V_GPIB_txt
	jmp	L39ED
L39E0:	lxi	h,GPIB_txt_2
	lda	VAR_816A
	mov	e,a
	mvi	d,00h
	dad	d
	shld V_GPIB_txt
L39ED:	lxi	h,V_GPIB_cnt0
	mov	a,m
	cpi	08h
	jc	L3C89
	lda	VAR_817E			;boolean test
	ral
	jnc	L3A08
	lda	V_WIFDO
	cpi	2Ch
	jz	L3A20
	jmp	L3C89
L3A08:	lda	VAR_816B
	ana	a
	jz	L3A1B
	mvi	a,30h
	sta	V_WIFDO
	lxi	h,VAR_816B
	dcr	m
	jmp	L3C89
L3A1B:	mvi	a,2Ch
	sta	V_WIFDO
L3A20:	lxi	h,V_GPIBStage
	mvi	m,0Fh
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3A2D:	cpi	0Fh
	jnz	L3A55
	mov	a,m
	inx	h
	ora	m
	jnz	L3A40
	dcx	h
	inr	m
	lxi	h,GPIB_txt_25
	shld V_GPIB_txt
L3A40:	call Update_V_WIFDO
	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,10h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3A55:	cpi	10h
	jnz	L3ADD
	mov	a,m
	inx	h
	ora	m
	jnz	L3AB0
	lxi	h,VAR_816F
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	lhld VAR_8176
	lxi	d,0001H
	dad	d
	mov	a,m
	mvi	c,08h
	mov	h,a
	mvi	l,00h
L3A74:	dad	h
	lxi	d,VAR_816F
	mvi	b,02h
L3A7A:	ldax d
	adc	a
	daa
	stax	d
	inx	d
	dcr	b
	jnz	L3A7A
	dcr	c
	jnz	L3A74
	lxi	h,VAR_8171
	lda	VAR_8170
	adi	30h
	mov	m,a
	inx	h
	lda	VAR_816F
	ani	0F0h
	rrc
	rrc
	rrc
	rrc
	adi	30h
	mov	m,a
	inx	h
	lda	VAR_816F
	ani	0Fh
	adi	30h
	mov	m,a
	lxi	h,V_GPIB_cnt0
	inr	m
	lxi	h,GPIB_txt_26
	shld V_GPIB_txt
L3AB0:	call Update_V_WIFDO
	lxi	h,V_GPIB_cnt0
	inr	m
	cpi	3Ah
	jnz	L3AC5
	lxi	h,VAR_8171
	shld V_GPIB_txt
	jmp	L3C89
L3AC5:	mov	a,m
	cpi	0Ah
	jc	L3C89
	mvi	a,2Ch
	sta	V_WIFDO
	lxi	h,V_GPIBStage
	mvi	m,11h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3ADD:	cpi	11h
	jnz	L3B31
	mov	a,m
	inx	h
	ora	m
	jnz	L3B11
	dcx	h
	inr	m
	lxi	h,GPIB_txt_27
	shld V_GPIB_txt
	lda	VAR_8166
	lxi	h,GPIB_txt_35
	cpi	01h
	jnz	L3AFE
	lxi	h,GPIB_txt_32
L3AFE:	cpi	02h
	jnz	L3B06
	lxi	h,GPIB_txt_33
L3B06:	cpi	03h
	jnz	L3B0E
	lxi	h,GPIB_txt_34
L3B0E:	shld V_GPIB_Ptr1
L3B11:	call Update_V_WIFDO
	cpi	3Ah
	jnz	L3B1F
	lhld V_GPIB_Ptr1
	shld V_GPIB_txt
L3B1F:	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,12h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3B31:	cpi	12h
	jnz	L3B59
	mov	a,m
	inx	h
	ora	m
	jnz	L3B44
	dcx	h
	inr	m
	lxi	h,GPIB_txt_28
	shld V_GPIB_txt
L3B44:	call Update_V_WIFDO
	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,13h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3B59:	cpi	13h
	jnz	L3B81
	mov	a,m
	inx	h
	ora	m
	jnz	L3B6C
	dcx	h
	inr	m
	lxi	h,GPIB_txt_29
	shld V_GPIB_txt
L3B6C:	call Update_V_WIFDO
	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,14h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3B81:	cpi	14h
	jnz	L3BA9
	mov	a,m
	inx	h
	ora	m
	jnz	L3B94
	dcx	h
	inr	m
	lxi	h,GPIB_txt_30
	shld V_GPIB_txt
L3B94:	call Update_V_WIFDO
	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,15h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3BA9:	cpi	15h
	jnz	L3BD1
	mov	a,m
	inx	h
	ora	m
	jnz	L3BBC
	dcx	h
	inr	m
	lxi	h,GPIB_txt_31
	shld V_GPIB_txt
L3BBC:	call Update_V_WIFDO
	cpi	2Ch
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,05h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3BD1:	cpi	05h
	jnz	L3BEF
	xra	a
	sta	V_GPIB8164
	mvi	a,25h
	sta	V_WIFDO
	lxi	h,V_GPIBStage
	mvi	m,02h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	sta	V_GPIB_EndOfMessage
	jmp	L3C89
L3BEF:	cpi	02h
	jnz	L3C2A
	mov	a,m
	inx	h
	ora	m
	jnz	L3C10
	lhld VAR_8174
	mov	a,h
	cpi	01h
	jz	L3C05
	mvi	a,02h
L3C05:	sta	V_WIFDO
	mvi	a,01h
	sta	V_GPIB_cnt0
	jmp	L3C1F
L3C10:	mvi	a,01h
	sta	V_WIFDO
	lxi	h,V_GPIBStage
	mvi	m,03h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
L3C1F:	lxi	h,V_GPIB8164
	lda	V_WIFDO
	add	m
	mov	m,a
	jmp	L3C89
L3C2A:	cpi	03h
	jnz	L3C72
	mov	a,m
	inx	h
	ora	m
	jnz	L3C48
	lxi	h,ScratchRamTable
	lda	VAR_8168
	dcr	a
	add	a
	mov	e,a
	mvi	d,00h
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	xchg
	shld V_GPIB_txt
L3C48:	call Update_V_WIFDO
	lxi	h,V_GPIB8164
	add	m
	mov	m,a
	lhld V_GPIB_cnt0
	inx	h
	shld V_GPIB_cnt0
	xchg
	lhld VAR_8174
	mov	a,e
	cmp	l
	jnz	L3C89
	mov	a,d
	cmp	h
	jnz	L3C89
	lxi	h,V_GPIBStage
	mvi	m,04h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	jmp	L3C89
L3C72:	cpi	04h
	jnz	L3C89
	lda	V_GPIB8164
	dcr	a
	cma
	sta	V_WIFDO
	lxi	h,V_GPIBStage
	mvi	m,06h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
L3C89:	mvi	a,83h
	call AddMainAction
	ret
Update_V_WIFDO:	lhld V_GPIB_txt
	mov	a,m
	sta	V_WIFDO
	inx	h
	shld V_GPIB_txt
	ret
;
;
Action_0x79_0:
	call Get_GPIB_Status
	di
	lda	V_GPIB_Bool4
	ral
	jnc	L3CAE
	mvi	a,79h
	call AddMainAction
	jmp	L3D11
L3CAE:	lda	V_GPIB_XmitWFRQSFActive
	ral
	jc	L3CBC
	lda	VAR_8006
	ral
	jnc	L3D11
L3CBC:	mvi	a,01h
	sta	V_GPIBOut
	lda	V_GPIB_XmitWFRQSFActive
	ral
	jnc	L3CF1
	mvi	a,83h
	sta	V_GPIBOut
	lda	V_TALKREG
	ral
	jnc	L3CF1
	mvi	a,84h
	sta	V_GPIBOut
	lda	V_WIFCTL
	ori	01h
	ori	20h
	sta	V_WIFCTL
	mvi	a,80h
	lxi	h,V_FPC
	ora	m
	sta	V_FPC
	mvi	a,0FFh
	sta	V_GPIB_Bool3
L3CF1:	mvi	a,40h
	lxi	h,V_GPIBOut
	ora	m
	sta	V_GPIBOut
	lda	V_WIFCTL
	ori	04h
	sta	V_WIFCTL
	sta	DEV_WIFCTL
	mvi	a,01h
	lxi	h,V_FPC
	ora	m
	sta	V_FPC
	sta	DEV_FPC
L3D11:	ret
;
;
Action_0x82_0:
	di
	lda	V_GPIB_ActionWasRemoved
	ral
	rc
	lda	V_GPIB_MTAReceived
	mov	b,a
	lda	V_TALKREG
	ora	b
	jp	L3D39
	lda	V_GPIB_Bool3
	ral
	jnc	L3D39
	lxi	h,V_GPIBStage
	mvi	m,01h
	inx	h
	xra	a
	mov	m,a
	inx	h
	mov	m,a
	mvi	a,80h
	jmp	L3D3B
L3D39:	mvi	a,82h
L3D3B:	call AddMainAction
	ret
;
;
RestartDisplaySystem:
	di
	lda	V_DISREG
	ori	80h					;10000000	CSEL
	sta	DEV_DISREG
	push	psw
	mvi	a,08h
L3D4B:						;delay loop
	dcr	a
	jnz	L3D4B
	pop	psw
	ori	04h					;00000100 toggle bit 2 "START"
	sta	DEV_DISREG
	nop
	ani	0FBh				;00001011
	sta	DEV_DISREG
	ei
	ret
;
; in A,L
; out CY set, A==TRUE if equal, CY clr, A==FALSE if not equal
;	
Test_Equal_A_L:
	sub	l					;A - L
	mvi	a,0FFh
	rlc						;does NOT affect Z, sets CY
	rz
	mvi	a,00h
	rlc						;clear CY
	ret
;
; in A,L
; out A,carry. Destroys B
; Only called with L == 0
; Signed Compare A,L: return TRUE/CY set if A > L (signed)
;
Signed_Compare_A_L:
	mov	b,a
	xra	l					;test if A or L (not both) have bit 7 set (negative)
	rlc
	mov	a,b					;restore
	jc	L3D77
	cmp	l					;A - L
	mvi	a,00h				;return FALSE/CY clr if A <= L
	rlc						;does NOT affect Z flag
	rm
	rz
	mvi	a,0FFh				;return TRUE/CY set if A > L
	rlc
	ret
; A or L negative, not both	
L3D77:	rlc					;was A negative
	jc	L3D7F
; A positive so L negative	
	mvi	a,0FFh				;return TRUE/CY set if A was positive, implying A > L signed
	rlc
	ret
; A negative so L positive	
L3D7F:	xra	a				;return FALSE/CY clr if A was negative. implying A < L signed
	rlc
	ret
;
; in A,L
; out A, CY
; Signed Compare A,L: return FALSE/CY Clr if A >= L (signed)
; cf Signed_Compare_A_L
;	
Compare_A_L:
	mov	b,a					;save arg1
	xra	l					;test if A or L (not both) have bit 7 set
	rlc						;bit 7 (sign) to CY
	mov	a,b					;restore
	jc	L3D91				;brif A or L negative (not both)
;
; A and L same sign. Could be equal.
;
	cmp	l					;A - L
	mvi	a,0FFh				;return TRUE/CY set if 0
	rlc						;set carry, does not affect Z,P. A unchanged
	rm						;return TRUE/C set if A < L
; A - L >= 0
	xra	a					;return FALSE/CY clr.
	rlc
	ret
L3D91:
;
; A and L opposite signs
;
	rlc						;check sign A
	jnc	L3D99				;brif positive
;
; A negative so L zero or positive. A < L
;
	mvi	a,0FFh				;return TRUE/CY set
	rlc
	ret
L3D99:
;
; A positive so L negative. A > L
;
	xra	a					;return FALSE/CY clr
	rlc
	ret
;
;	in L
;	out H 0xff or 0
;	Sign extend L into H
;
SignExtend_L_in_H:
	mov	a,l
	ral
	mvi	a,00h
	jnc	L3DA4
	cma
L3DA4:	mov	h,a
	ret
;
; in HL. Two's complement if HL is negative. Absolute Value
;
AbsoluteValue_HL:
	mov	a,h
	ral						;test bit 7 HL
	jnc	L3DB2				;done if positive.
	dcx	h					;two's complement.
	mov	a,l
	cma
	mov	l,a
	mov	a,h
	cma
	mov	h,a
L3DB2:	ret
;
; in DE, HL
; out HL
; non-reentrant version but only called from interrupt code so safe.
;
Divide_DE_by_HL_2:
	xra	a
	sta	DivLoopCntr
	mov	b,h
	mov	c,l
	lxi	h,0000H
	push	psw
	push	h
; loop 16 times	
L3DBE:
	pop	h
	pop	psw
	mov	a,l
	sub	c
	mov	l,a
	mov	a,h
	sbb	b
	mov	h,a
	jnc	L3DCA
	dad	b
L3DCA:	mov	a,e			;shift left DE and HL
	ral
	mov	e,a
	mov	a,d
	ral
	mov	d,a
	mov	a,l
	ral
	mov	l,a
	mov	a,h
	ral
	mov	h,a
	push	psw
	push	h
	lxi	h,DivLoopCntr		;loop counter
	inr	m
	mov	a,m
	cpi	11h
	jnz	L3DBE
;	
	pop	h
	pop	psw
	rar
	mov	b,a
	xchg					;swap
	mov	a,l					;complement HL
	cma
	mov	l,a
	mov	a,h
	cma
	mov	h,a
	ret
;
; in DE, HL.
;	HL always 0x0100, DE always [V_CurrentSweeps]
; returns carry
; signed compare DE and HL
; return CY if DE > (signed) HL
; return No CY if DE <= HL;
Signed_Compare_DE_HL:
	mov	a,d
	xra	h
	rlc
	mov	a,d
	jc	L3E02
	mov	a,l
	sub	e
	mov	a,h
	sbb	d
	rlc
	mvi	a,00h
	jnc	L3E01
	mvi	a,0FFh
L3E01:	ret
L3E02:	rlc
	jc	L3E0A
	mvi	a,0FFh
	rlc
	ret
L3E0A:	xra	a
	rlc
	ret
;
; in DE, L
; L is count. Shift Right DE count times.
; result in HL
;
ShiftR_DE_L_times:
	xchg					;count to DE
	mov	a,e
	cpi	00h					;done if count <= 0
	rm
	rz
$$L1111:
	mov	a,h
	stc						;clear carry
	cmc
	rar
	mov	h,a
	mov	a,l
	rar
	mov	l,a
	dcr	e
	jnz	$$L1111
	ret
;
; in DE, HL
; out HL
; compare DE and HL unsigned.
; return larger of DE and HL in HL
; called once only
;
MAX_DE_HL:
	mov	a,e					;DE - HL
	sub	l
	mov	a,d
	sbb	h
	jnc	L3E2B
; HL > DE	
	ret
	jmp	MIN_DE_HL			;unreachable
; HL <= DE. Move DE to HL
L3E2B:	xchg
	ret
;
; in DE, HL
; out HL
; compare DE and HL unsigned.
; return smaller of DE and HL in HL
;
MIN_DE_HL:
	mov	a,e					;E - L
	sub	l
	mov	a,d					;D - H - carry
	sbb	h
	jc	L3E38
	ret
	jmp	Multiply_HL_DE		;unreachable
L3E38:	xchg
	ret
;
; in DE, HL. Multiply DE * HL
; result in HL
;	
Multiply_HL_DE:
	mov	b,h
	mov	c,l
	lxi	h,0000H
	mvi	a,10h
; loop 16 times
L3E41:
	dad	h
	xchg
	dad	h
	xchg
	jnc	L3E49
	dad	b					;add input argument
L3E49:
	dcr	a
	jnz	L3E41
	ret
;
; note: 2 copies of table
; Table used in Display_Interrupt_0. Max index 15
; 20 entries.
;	
Display_Actions:
	dw	Display_Action_1,RenderWF,Display_Action_3,Display_Action_4,Display_Action_5,Display_Action_6,Display_Action_7
	db	076h,076h,076h,076h,076h,076h
	dw	Display_Action_1,RenderWF,Display_Action_3,Display_Action_4,Display_Action_5,Display_Action_6,Display_Action_7
	db	076h,076h,076h,076h,076h,076H
;
; multiplication factor table
;
V_CvtFreq2Volts:
	db	001h,002h,005h
; unused
	db	001h,005h,002h
;
; next tables have 16 entries
;
V_CursorScaleTbl:
	db	001h,001h,001h,001h,001h,002h,002h,002h,003h
	db	003h,004h,005h,006h,007h,009h
;
V_TimerCntr_Rate_Tbl:
	db	00Ah,00Ah,008h,004h,002h,001h,001h,001h,001h,001h
	db	001h,001h,001h,001h,001h,001h,001h
Number5:
	db	005h
	
GPIB_txt_1:	
	db	"21442"
GPIB_txt_2:
	db	"8482"
GPIB_txt_3:
	db	"ID TEK/468,V79.1,FV:2.0;"
GPIB_txt_4:
	db	"WFMPRE "
GPIB_txt_5:
	db	"WFID:",022h
GPIB_txt_6:
	db	"UNK",022h
GPIB_txt_7:
	db	"DC",022h
GPIB_txt_8:
	db	"AC",022h
GPIB_txt_9:
	db	"GND",022h
GPIB_txt_10:
	db	"CH1 "
GPIB_txt_11:
	db	"CH2 "
GPIB_txt_12:
	db	"ADD "
GPIB_txt_13:
	db	"NR.PT:"
GPIB_txt_14:
	db 	"512,"
GPIB_txt_15:
	db 	"256,"
GPIB_txt_16:
	db 	"PT.FMT:Y,"
GPIB_txt_17:
	db	"XINCR:"
GPIB_txt_18:
	db 	"XZERO:0,"
GPIB_txt_19:
	db 	"MS"
GPIB_txt_20:
	db 	"US"
GPIB_txt_21:
	db 	"NS"
GPIB_txt_22:
	db 	"PT.OFF:"
GPIB_txt_23:
	db 	"XUNIT:"
GPIB_txt_24:
	db	"YMULT:"
GPIB_txt_25:
	db	"YZERO:0,"
GPIB_txt_26:
	db	"YOFF:"
GPIB_txt_27:
	db	"YUNIT:"
GPIB_txt_28:
	db	"ENCDG:BIN,"
GPIB_txt_29:
	db	"BN.FMT:RP,"
GPIB_txt_30:
	db	"BYT/NR:1,"
GPIB_txt_31:
	db	"BIT/NR:8,"
GPIB_txt_32:
	db	"UV,"
GPIB_txt_33:
	db	"MV,"
GPIB_txt_34:
	db	"V,"
GPIB_txt_35:
	db	"DIV,"
GPIB_txt_36:
	db	"224,"
GPIB_txt_37:
	db	"448,"
GPIB_txt_38:
	db	"32,"
GPIB_txt_39:
	db	"64,"
GPIB_txt_40:
	db	"50,"
GPIB_txt_41:
	db	"25,"
GPIB_txt_42:
	db	"50,"
GPIB_txt_43:
	db	"100,"
GPIB_txt_44:
	db	"250,"
GPIB_txt_45:
	db	"500,"
GPIB_txt_46:
	db	"1000,"

	rept 106
	hlt	
	endm

	db	007h,059h
L3FFC:	
	db	001h,0FEh
	dw	07746h				;rom575 checksum

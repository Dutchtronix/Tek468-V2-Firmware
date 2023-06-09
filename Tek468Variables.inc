;
; variables in System RAM.
;
DivLoopCntr	equ			08000H
V_fOK2ProcessAcq equ	08001H
V_fOK2UpdateDispWF equ	08002H
V_fSkipAcquiredWF equ	08003H
V_GPIB_txt	equ			08004H
VAR_8006	equ			08006H
V_GPIB_XmitWFRQSFActive	equ	08007H
V_ACQ_Mode	equ			08008H
VAR_8009	equ			08009H
V_pDEVICE	equ			0800AH
V_ActualTB_2	equ		0800CH
V_GPIB_ActionWasRemoved	equ 0800DH
VAR_800E	equ			0800EH
V_fSAVEREFPushed equ	0800FH
V_CursorEdgeTimeCnt equ 08010H
V_fAtCursorEdge		equ	08012H
V_fCursorEdgeTracking equ 08013H
V_fSnappedCursor	equ	08014H
V_fCursor1Snapped equ	08015H
VAR_8016	equ			08016H
V_WIFCTL	equ			08017H
V_ATIME	equ				08018H
V_BTIME	equ				08019H
V_CH1_Info	equ			0801AH
V_CH2_Info	equ			0801BH
V_CH1_Coupling	equ		0801CH
V_CH2_Coupling	equ		0801DH
V_fCH1	equ				0801EH
V_fCH2	equ				0801FH
V_fADD	equ				08020H
V_fTRIGVIEW	equ			08021H
V_fALT	equ				08022H
V_ATimebaseActive	equ	08023H
V_fTRIGVIEWENA	equ		08024H
V_fXY	equ				08025H
V_UIVolts	equ			08026H
VAR_8027	equ			08027H
V_SCALECode	equ			08028H
V_ChannelMode	equ		08029H
V_fAlternating	equ		0802AH
V_fChopped	equ			0802BH		;boolean
V_NumWinValue	equ		0802CH
V_NumWinBuf	equ			0802EH
V_DecPntDigit	equ		08032H
V_Curr_LEDRO	equ		08033H
V_CursorIncrementValue equ	08034H
V_TimerCntrRateInc2	equ	08035H
V_PRFastMode	equ		08036H
V_CursorPos2	equ		08037H
V_CursorPos1	equ		08039H
V_PreviousPRCount equ	0803BH
V_CursorPot_Delay equ	0803DH
V_CurrWF equ 			0803EH
V_GPIB_Enabled	equ		0803FH
V_DispWF	equ			08040H
V_CursorLine	equ		08041H
VAR_8042	equ			08042H		;assigned but never used
V_MainActionEnd equ		08043H
V_MainActionStart equ	08044H
V_MainActionTbl equ		08045H		;length 16.
V_GPIB_MTAReceived equ	08055H
V_Jitter	equ			08056H
V_Jitter_Tbl	equ		08057H		;table
V_GPIB_Bool9	equ		0805BH
;
; GPIB status variables
;
V_GPIB_Bool8	equ		0805CH
V_GPIB_Bool7	equ		0805DH
V_GPIB_NRFD	equ			0805EH
V_GPIB_ATNDAV	equ		0805FH
V_GPIB_60	equ			08060H
V_GPIB_RATN	equ			08061H
V_GPIB_Bool6	equ		08062H
V_GPIB_NDAC	equ			08063H
V_TALKREG	equ			08064H
V_TALKADDR	equ			08065H
;
;
V_GPIB_XmittingWF equ	08066H
V_GPIB_EndOfMessage	equ	08067H
V_GPIB_Bool2	equ		08068H
V_WIFDO	equ				08069H
V_GPIBStage	equ			0806AH
V_GPIB_cnt0	equ			0806BH
V_GPIB_Bool3 equ		0806DH
V_GPIB_Bool4 equ		0806EH
V_GPIB_Bool5	equ		0806FH
V_FPC		equ			08070H
V_DisplayRB_End	equ		08071H		;counter 1..10
V_DisplayRB_Start equ	08072H
V_DisplayRB	equ			08073H		;table of 10 entries
V_pDispWF	equ			0807DH		;pointer value
V_WFTable equ			0807FH		;table of 4 entries, 8 bytes each
V_ValidWFs	equ			0809FH		;table of 4 booleans
V_PrimaryWF	equ			080A3H
V_DISREG	equ			080A4H
V_DigitalMode equ		080A5H
V_fSAVEREFShowing equ	080A6H
V_fPostPreTrigger equ	080A7H
V_fPulseSine	equ		080A8H
V_GPIBOut	equ			080A9H
V_CursorMode	equ		080AAH
V_PositionRateCount_Values equ 080ABH
V_fFirstCursorActive equ 080ADH
V_VoltsCursorPos equ	080AFH		;table
V_TimeCursorPos	equ		080B3H
V_LineCursorPos	equ		080B7H
V_TmpCursorPos	equ		080BBH
V_CONTRL	equ			080BFH
V_TimerCntrSweepsIncrement equ	080C1H
V_AVG_Sweeps	equ		080C2H
V_ENV_Sweeps	equ		080C4H
V_Sweep_Cnt1	equ		080C6H
V_NotCountingDown equ	080C8H
V_FP2		equ			080C9H
V_FP1		equ			080CAH		;inverted copy of DEV_FP1
V_Rate_Direction equ	080C0H
V_LclFlag	equ			080CCH
V_Action5_Flg	equ		080CDH
V_Action9_Flg	equ		080CEH
V_Action7_Flg	equ		080CFH
V_Action3_Flg	equ		080D0H
V_Action6_Flg	equ		080D1H
V_CURSOR_Select	equ		080D2H
V_Lights	equ			080D3H
V_VSM	equ				080D4H
V_Saved_Arg_HL	equ		080D5H
V_Saved_Arg_DE	equ		080D7H
V_nSamples	equ			080D9H
V_Loop_Cntr_1	equ		080DAH
VAR_80DB	equ			080DBH
V_pWF_Destination equ	080DCH
V_pWF_Source equ		080DEH
VAR_80E0	equ			080E0H
V_pRAM_DOT	equ			080E1H
V_pRAM_DOT2	equ			080E3H
V_BOTHODD	equ			080E5H
V_CNT	equ				080E8H
V_Cnt_2	equ				080E9H
V_TargetTB2	equ			080EAH
V_DigitalMode_4a equ	080EBH
V_WF_4	equ				080ECH
VAR_80ED	equ			080EDH
V_DisplayAction	equ		080EEH
V_fAVGENVFinished equ	080EFH
V_Sweep_Cnt2	equ		080F0H
V_ACQWF_Ptr	equ			080F2H
V_pScratchRAM	equ		080F4H
V_pScratchRAM2	equ		080F6H
V_pWF_4	equ				080F8H
V_LclWFEntry	equ		080FAH		;8 byte WF entry
V_SavedpWF_4	equ		08102H
V_LclWFEntry_2	equ		08104H		;8 byte WF Entry
V_SavedChannelMode equ	0810CH
V_Local810D	equ			0810DH
V_VoltSteps	equ			0810EH
V_LoopCntAVG	equ		0810FH
VAR_8111	equ			08111H
V_cnt01		equ			08113H
V_LocalMinSweeps equ	08114H
V_LocalMaxSweeps equ	08116H
V_CurrentSweeps	equ		08118H
V_ThisLineCursorPos	equ	0811AH
V_fShortWF	equ			0811CH
V_pWFTable3	equ			0811DH
V_Saved_Arg equ			08120H
V_SAVED_INT_Mask equ	08121H
V_DisplayRB_Index equ	08122H
V_Index_7	equ			08123H
V_Tmp_7	equ				08124H
V_AcquiredTB_7	equ		08125H
V_pWFTbl_7	equ			08126H
V_pSrc_4	equ			08128H
V_pDest_4	equ			0812AH
V_RAM_Area	equ			0812CH
V_Cnt2	equ				0812EH
V_samplesCnt	equ		08130H
V_deltaTB_4_2	equ		08131H
V_deltaTB_4	equ			08132H
V_TargetTB_4	equ		08133H
V_AcquiredTB_4	equ		08134H
V_LocalHGAIN_4	equ		08135H
V_WF_4a	equ				08136H
V_DigitalMode_4	equ		08137H
V_oddFlg_4	equ			08138H
V_Saved_Int_Mask_2	equ 0813AH
V_ActionLoopIdx	equ		0813BH
V_LastPRCount	equ		0813CH
VAR_813E	equ			0813EH
VAR_8140	equ			08140H
V_TMP8142	equ			08142H
V_PRCount	equ			08144H
V_CH1_Info_Copy	equ		08147H
V_CH2_Info_Copy	equ		08148H
V_AcqVolts	equ			08149H
V_bit_6_cleared	equ		0814AH
V_fUNCAL	equ			0814BH
V_fAVGVolts	equ			0814CH
V_TMP814D	equ			0814DH
V_BCD_Input	equ			0814EH
V_SCALECode2 equ		08150H
V_BCD_Result equ		08151H
V_TMP8154	equ			08154H
VAR_8155	equ			08155H
V_DecPoint	equ			08157H
V_LedCode	equ			08158H
V_WF_6	equ				08159H
V_FlippedWF_6 equ		0815AH
V_CopySize_6 equ		0815BH
V_Flg_6	equ				0815CH
V_Ptr1_6 equ			0815DH
V_Ptr2_6 equ			0815FH
V_Lcl_fActionRemoved equ 08162H
V_GPIB8164	equ			08164H
VAR_8165	equ			08165H
VAR_8166	equ			08166H
VAR_8168	equ			08168H
VAR_816A	equ			0816AH
VAR_816B	equ			0816BH
VAR_816D	equ			0816DH
VAR_816F	equ			0816FH
VAR_8170	equ			08170H
VAR_8171	equ			08171H
VAR_8174	equ			08174H
VAR_8176	equ			08176H
V_GPIB_Ptr3	equ			08178H
V_GPIB_Ptr2	equ			0817AH
V_GPIB_Ptr1	equ			0817CH
VAR_817E	equ			0817EH		;boolean
VAR_817F	equ			0817FH		;boolean
VAR_8180	equ			08180H		;boolean
V_LED_Digit	equ			08181H
V_Range_Start equ		08182H
V_Range_End	equ			08184H
V_RAM_Test_Status	equ	08186H
V_FP_Display_Curr_Digit	equ	08187H
V_Saved_Param1 	equ		08188H
V_Saved_Param2	equ		08189H
V_RecorderJitter equ	08191H
V_Jitter_TB18	equ		08192H
V_Jitter_TB19	equ		08194H
V_Jitter_TB20	equ		08196H
VAR_8198	equ			08198H
V_TimerCntr	equ			0819AH
V_TimerCntr2	equ		0819BH
V_TimerCntr3	equ		0819CH 
V_TimerCntr4	equ		0819DH
V_TimerCntr_Rate_Stop2 equ 0819EH
V_TimerCntrSweepsStop equ 0819FH

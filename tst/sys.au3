; Purpose:  To run the System Control tests.

#include-once
#include <RegTstUtil.au3>

; Purpose:  Main entry point for Sys tests.
Func RunSysControlTest($hTestSummary, $hSystemControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hSystemControl_pf)
	GUICtrlSetData($hTestSummary, "==> System Control Test Started")

	; Check for Private Stream Messages coming into the box.
	$bPass = RunPrivStreamMsgTest($hTestSummary) And $bPass

	; Press the POWER button (DSR off)
	MakeRmtCmdDrip("rmt:POWER", 5000)
	$bPass = RunTestCriteria("cmd", "ALL VIDEO OUTPUTS: DISABLED", "Power Off", $hTestSummary, $hSystemControl_pf) And $bPass

	; Press the POWER button (DSR on)
	MakeRmtCmdDrip("rmt:POWER", 5000)
	$bPass = RunTestCriteria("cmd", ":ALL VIDEO OUTPUTS: ENABLED", "Power On", $hTestSummary, $hSystemControl_pf) And $bPass

	; Run the DST Tests
	$bPass = RunDstTests($hTestSummary) And $bPass

	; Send the Reboot command
	$bPass = RunRebootTest($hTestSummary) And $bPass

	GUICtrlSetData($hTestSummary, "<== System Control Test Done")
	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $hSystemControl_pf)
	Else
		PF_Box("Fail", $COLOR_Red, $hSystemControl_pf)
	EndIf
EndFunc   ;==>RunSysControlTest


; Purpose:  To run the Daylight Savings Tests
Func RunDstTests($hTestSummary)
	Local $bPass = True
	Local $aDstOrigValues[] = [0, 0, 0]     ; Save the original entry/exit timezone values.  Revert back when done with tests.
	Local $aDstDiagHex[] = [0, 0, 0, 0, 0]     ; Hexidecimal Array : UA, gps, entry, exit, tz_field
	Local $aDstDiagDec[] = [0, 0, 0, 0, 0]     ; Decimal Array : state, gps, entry, exit, timezone
	Local $aSysTime[] = ["", "", ""]        ; hours, minutes, seconds

	; Save off the original entry/exit times.
	GetDstData($hTestSummary, $aDstDiagHex, $aDstDiagDec)
	$aDstOrigValues[0] = $aDstDiagHex[2]
	$aDstOrigValues[1] = $aDstDiagHex[3]
	$aDstOrigValues[2] = $aDstDiagHex[4]

	GUICtrlSetData($hTestSummary, "Begin DST Tests")
	MakeAstTtl("ast sea none", 2)
	RunAstTtl()
	$bPass = DST_regress_001_001($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	$bPass = DST_regress_001_002($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	$bPass = DST_regress_001_003($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	$bPass = DST_regress_001_004($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	$bPass = DST_regress_001_005($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	$bPass = DST_regress_001_006($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	$bPass = DST_regress_001_007($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	$bPass = DST_regress_001_008($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	$bPass = DST_regress_001_009($hTestSummary, $aDstDiagHex, $aDstDiagDec) And $bPass
	MakeAstTtl("ast sea all", 2)
	RunAstTtl()

	; Revert UIM back to original values.
	$aDstDiagHex[2] = $aDstOrigValues[0]
	$aDstDiagHex[3] = $aDstOrigValues[1]
	$aDstDiagHex[4] = $aDstOrigValues[2]
	SendDstUim($hTestSummary, $aDstDiagHex)
	Return $bPass
EndFunc   ;==>RunDstTests

; Note:  The following conditons are tested:
;   a) Proper system time for all possible entry and exit times
;   b) Proper system time during transition across boundary.
; Condition=A-F - X=current_time : Pass_conditon
;           A - X-Exit----Entry : X=DST
;           B - Entry--X--Exit : X=DST
;           C - Exit----Entry-X : X=DST
;           D - X-Entry----Exit : X=STD
;           E - Exit--X--Entry  : X=STD
;           F - Entry----Exit-X : X=STD

; 5	DSR SI&T.System Control.DST & Related Settings:001-001	"DST Entry Past, In DST, DST Exit Future (State B -> StateA xsition)"
Func DST_regress_001_001($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	; Configure so Entry time is in the past and Exit time is in the future.
	GUICtrlSetData($hTestSummary, "Test B - Entry--X--Exit : X=DST")
	SendEntryExitUim($hTestSummary, -60 * 60 * 24 * 2, 60 * 60 * 24 * 2, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass
	; Exit time is in the near future and the Entry time is in that far future
	GUICtrlSetData($hTestSummary, "Test A - X-Exit----Entry : X=DST")
	SendEntryExitUim($hTestSummary, 60 * 60 * 24 * 20, 60 * 60 * 24 * 2, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-001', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_001

; 3	DSR SI&T.System Control.DST & Related Settings:001-002	"In STD Time, DST Entry Future,  DST Exit Future (Ahead of Entry) (State F -> State D xsition)"
Func DST_regress_001_002($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	; Configure so Entry time is in the far past and Exit time is in the near past.
	GUICtrlSetData($hTestSummary, "Test F - Entry----Exit-X : X=STD ")
	SendEntryExitUim($hTestSummary, -60 * 60 * 24 * 20, -60 * 60 * 24 * 2, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	; Entry time is in the near future and the Exit time is in that far future
	GUICtrlSetData($hTestSummary, "Test D - X-Entry----Exit : X=STD ")
	SendEntryExitUim($hTestSummary, 60 * 60 * 24 * 2, 60 * 60 * 24 * 20, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-002', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_002

; 5 DSR SI&T.System Control.DST & Related Settings:001-003	DST Entry in far future after Exit. (State A -> E xsition)
Func DST_regress_001_003($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	; Configure so Entry time is in the far future and Exit time is in the near future.
	GUICtrlSetData($hTestSummary, "Test A - X-Exit----Entry : X=DST   ")
	SendEntryExitUim($hTestSummary, 60 * 60 * 24 * 20, 20, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass
	; Allow the unit to transition to STD time (across Exit time).
	GUICtrlSetData($hTestSummary, "Wait 20 seconds, then test transition DST into STD")
	Sleep(20000)    ; Wait for 20 seconds
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-003', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_003

; 3	DSR SI&T.System Control.DST & Related Settings:001-004	DST Entry Transition (State D -> State B xsition)
Func DST_regress_001_004($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	; Configure so Entry time is in the near future and Exit time is in the far future.
	GUICtrlSetData($hTestSummary, "Test D - X-Entry----Exit : X=DST   ")
	SendEntryExitUim($hTestSummary, 20, 60 * 60 * 24 * 20, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	; Allow the unit to cross into the DST Entry time.
	GUICtrlSetData($hTestSummary, "Wait 20 seconds, then test transition STD into DST.")
	Sleep(20000)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-004', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_004

; 3	DSR SI&T.System Control.DST & Related Settings:001-005	DST Exit Transition (State B -> State F xsition)
Func DST_regress_001_005($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	; Configure so Entry time is in the near future and Exit time is in the far future.
	GUICtrlSetData($hTestSummary, "Test B - Entry--X--Exit : X=DST ")
	SendEntryExitUim($hTestSummary, -60 * 60 * 24 * 2, 20, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass
	; Entry time is in the past and the Exit time is in the future
	GUICtrlSetData($hTestSummary, "Wait 20 seconds, then test transition DST into STD ")
	Sleep(20000)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-005', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_005

; 5	DSR SI&T.System Control.DST & Related Settings:001-006	Unit in STD time. SAC DST Flag: Unchecked/Checked
Func DST_regress_001_006($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	; Configure so Entry time is in the near future and Exit time is in the far future.
	GUICtrlSetData($hTestSummary, "Test E - Exit--X--Entry  : X=STD     ")
	SendEntryExitUim($hTestSummary, 60 * 60 * 24 * 2, -60 * 60 * 24 * 20, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	;  Set the SAC condition such that the DST flag is Unchecked.
	SendModifiedTzUim($hTestSummary, $aDstDiagDec[4], 0, 1, $aDstDiagHex, $aDstDiagDec)    ; DST_enabled = 0, TZ_defined = 1
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	SendModifiedTzUim($hTestSummary, $aDstDiagDec[4], 1, 1, $aDstDiagHex, $aDstDiagDec)    ; DST_enabled = 1, TZ_defined = 1
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-006', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_006

; 5	DSR SI&T.System Control.DST & Related Settings:001-007	Unit in DST time. SAC DST Flag: Unchecked/Checked
Func DST_regress_001_007($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	; Configure so Entry time is in the near future and Exit time is in the far future.
	GUICtrlSetData($hTestSummary, "Test B - Entry--X--Exit : X=DST  ")
	SendEntryExitUim($hTestSummary, -60 * 60 * 24 * 2, 60 * 60 * 24 * 20, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass
	;  Set the SAC condition such that the DST flag is Unchecked.
	GUICtrlSetData($hTestSummary, "aDstDiagDec[4]=" & $aDstDiagDec[4] & ", number=" & Number($aDstDiagDec[4]))
	SendModifiedTzUim($hTestSummary, $aDstDiagDec[4], 0, 1, $aDstDiagHex, $aDstDiagDec)    ; DST_enabled = 0, TZ_defined = 1
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass        ; verify it is in STD
	;  Set the SAC condition such that the DST flag is Checked.
	SendModifiedTzUim($hTestSummary, $aDstDiagDec[4], 1, 1, $aDstDiagHex, $aDstDiagDec)    ; DST_enabled = 1, TZ_defined = 1
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass        ; verify it is in DST
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-007', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_007

; 5	DSR SI&T.System Control.DST & Related Settings:001-008	"In STD time. Exit time in past, Entry in future (State E -> C xsition)"
Func DST_regress_001_008($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	; Configure so Entry time is in the near future and Exit time is in the far future.
	GUICtrlSetData($hTestSummary, "Test E - Exit--X--Entry  : X=STD         ")
	SendEntryExitUim($hTestSummary, 20, -60 * 60 * 24 * 2, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 0) And $bPass
	; Entry time is in the future by 20 secs and the Exit time is in the past.
	GUICtrlSetData($hTestSummary, "Wait 20 seconds, then test transition STD into DST ")
	Sleep(20000)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-008', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_008

; 3	DSR SI&T.System Control.DST & Related Settings:001-009	DSR time tracks timezone changes
Func DST_regress_001_009($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	Local $bPass = True
	Local $iHourCrossover = 0
	Local $sPassFail = "Pass"
	Local $aEastCoast = ["", "", ""]    ; Hours Minutes Secs
	Local $aWestCoast = ["", "", ""]    ; Hours Minutes Secs
	; Configure so Entry time is in the past and Exit time is in the future.
	GUICtrlSetData($hTestSummary, "Test B - Entry--X--Exit : X=DST   ")
	SendEntryExitUim($hTestSummary, -60 * 60 * 24 * 2, 60 * 60 * 24 * 2, $aDstDiagHex, $aDstDiagDec)
	$bPass = CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, 1) And $bPass
	; At the SAC, set the postal code to east coast (19131).
	GUICtrlSetData($hTestSummary, "Set timezone to east coast.")
	Local $iTZ = $aDstDiagDec[4]    ; save off old value.
	SendModifiedTzUim($hTestSummary, -300, 1, 1, $aDstDiagHex, $aDstDiagDec)    ; timezone east coast = -300
	Sleep(5000)
	GetLocalTime($hTestSummary, $aEastCoast)
	$sTime = $aEastCoast[0] & ":" & $aEastCoast[1] & ":" & $aEastCoast[2]
	GUICtrlSetData($hTestSummary, "East coast time = " & $sTime)
	SendModifiedTzUim($hTestSummary, -480, 1, 1, $aDstDiagHex, $aDstDiagDec)    ; timezone west coast = -480
	Sleep(5000)
	GetLocalTime($hTestSummary, $aWestCoast)
	$sTime = $aWestCoast[0] & ":" & $aWestCoast[1] & ":" & $aWestCoast[2]
	GUICtrlSetData($hTestSummary, "West coast time = " & $sTime)
	If Number($aEastCoast[1]) > Number($aWestCoast[1]) Then
		$iHourCrossover = 1
	EndIf

	If Number($aEastCoast[0]) <> Number($aWestCoast[0]) + 3 + $iHourCrossover Then
		$bPass = False
		$sPassFail = "Fail"
	EndIf
	GUICtrlSetData($hTestSummary, "East coast hours: " & $aEastCoast[0] & " West coast hours: " & $aWestCoast[0])
	GUICtrlSetData($hTestSummary, "Timezone test = " & $sPassFail)
	SavePassFailTestResult('DSR SI&T.System Control.DST & Related Settings:001-009', $bPass)
	Return $bPass
EndFunc   ;==>DST_regress_001_009

; Purpose:  To send the entry/exit times in a UIM.
; $iEntryTime - DST entry time related to the current time.
; $iExitTime - DST exit time related to the current time.
; Note: Entry/Exit times in seconds, '-' before, '+' after current time.
Func SendEntryExitUim($hTestSummary, $iEntryTime, $iExitTime, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	; Get DST data from Diagnostics A screen.
	GetDstData($hTestSummary, $aDstDiagHex, $aDstDiagDec)
	$aDstDiagDec[2] = $aDstDiagDec[1] + $iEntryTime
	$aDstDiagHex[2] = CommaSeparatedBytes(Hex($aDstDiagDec[2]), 4)
	$aDstDiagDec[3] = $aDstDiagDec[1] + $iExitTime
	$aDstDiagHex[3] = CommaSeparatedBytes(Hex($aDstDiagDec[3]), 4)
	SendDstUim($hTestSummary, $aDstDiagHex)
EndFunc   ;==>SendEntryExitUim


; Purpose:  To send the TZ, DST_enable, and TZ_defined in a UIM.
; $iTZ - Timezone, in minutes (-480 for Pacific).
; $iDST_enabled - 0 for not enabled, 1 for enabled.
; $iTZ_defined - 0 for not defined, 1 for defined.
; Note: Other values in aDstDiagHex and aDstDiagDec are left unchanged.
Func SendModifiedTzUim($hTestSummary, $iTZ, $iDST_enabled, $iTZ_defined, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	; TZ_field (2 bytes) = dst Enable (E) + tz Defined (D) + reserved (xxx) + timezone minutes (T) = EDxx xTT TTTT TTTT
	$sTZ = $iTZ
	If $iDST_enabled = 0 Then    ; Turn off daylight_savings_enable, bit 15
		$iTZ = BitXOR($iTZ, 32768)
	EndIf
	If $iTZ_defined = 0 Then    ; Turn off time_zone_defined, bit 14
		$iTZ = BitXOR($iTZ, 16384)
	EndIf
	$aDstDiagHex[4] = CommaSeparatedBytes(Hex($iTZ, 4), 2)
	;GUICtrlSetData($hTestSummary, "DST_enabled=" & $iDST_enabled & ", TZ_defined=" & $iTZ_defined & ", time_zone=" & $sTZ & " => " & $aDstDiagHex[4])
	SendDstUim($hTestSummary, $aDstDiagHex)
EndFunc   ;==>SendModifiedTzUim


; Purpose:  To check if the box is in DST.
; $aDstDiagHex - Array to be filled by GetDstData.
; $aDstDiagDec - Array to be filled by GetDstData.
; $iState - Test condition : 0=noDst, 1=inDst
; Returns pass/fail based on $iState
Func CheckIfInDst($hTestSummary, $aDstDiagHex, $aDstDiagDec, $iState)
	Local $bPass = False
	Local $sPassFail = "Fail"
	Local $aSysTime = ["", "", ""]    ; Hours Minutes Secs
	Sleep(5000)                ; Wait 5 seconds and get system time
	GetLocalTime($hTestSummary, $aSysTime)
	GetDstData($hTestSummary, $aDstDiagHex, $aDstDiagDec)
	$sTime = $aSysTime[0] & ":" & $aSysTime[1] & ":" & $aSysTime[2]
	If $aDstDiagDec[0] = $iState Then
		$bPass = True                ; It should be in DST, if not then fail
		$sPassFail = "Pass"
	EndIf
	GUICtrlSetData($hTestSummary, "System time = " & $sTime & ", State = " & $aDstDiagDec[0] & ", " & $sPassFail & @CRLF)
	Return $bPass
EndFunc   ;==>CheckIfInDst

; Purpose:  Get Diagnostics A data for DST
; This fills in an a Hex array of comma-separated bytes.
Func GetDstData($hTestSummary, ByRef $aDstDiagHex, ByRef $aDstDiagDec)
	MakeRmtCmdDrip("diag:A", 1000)        ; Get Diag A data .
	RunDripTest("cmd")
	Local $sDstEntry = FindNthStringInFile("DST_Entry", "cmd", 1)
	Local $sDstExit = FindNthStringInFile("DST_Exit", "cmd", 1)
	Local $sGpsSecs = FindNthStringInFile("Secs", "cmd", 1)
	Local $sInDst = FindNthStringInFile("DST_state", "cmd", 1)
	Local $sUA = FindNthStringInFile("UA", "cmd", 2)
	Local $sTZ = FindNthStringInFile("TimeZone", "cmd", 1)
	Local $iDstEntry = Dec(StringReplace($sDstEntry, "0x", ""))
	Local $iDstExit = Dec(StringReplace($sDstExit, "0x", ""))
	Local $iGpsSecs = Dec(StringReplace($sGpsSecs, "0x", ""))
	Local $iTZ = Number($sTZ)
	$sUA = Hex($sUA, 10)       ; 10 character hex representation of decimal value
	$sTZ = Hex($iTZ, 4)

	; DST Diag Array Decimal values : state, gps, entry, exit
	$aDstDiagDec[0] = $sInDst
	$aDstDiagDec[1] = $iGpsSecs
	$aDstDiagDec[2] = $iDstEntry
	$aDstDiagDec[3] = $iDstExit
	$aDstDiagDec[4] = $iTZ

	; DST Diag Array : UA, gps, entry, exit
	$aDstDiagHex[0] = CommaSeparatedBytes($sUA, 5)         ; UA is 5 bytes
	$aDstDiagHex[1] = CommaSeparatedBytes($sGpsSecs, 4)    ; System time is 4 bytes
	$aDstDiagHex[2] = CommaSeparatedBytes($sDstEntry, 4)  ; System time is 4 bytes
	$aDstDiagHex[3] = CommaSeparatedBytes($sDstExit, 4)    ; System time is 4 bytes
	$aDstDiagHex[4] = CommaSeparatedBytes($sTZ, 2)        ; Timezone is 2 bytes
EndFunc   ;==>GetDstData


; Purpose:  Get the current local time.
; Note: Passes back array by reference of the system time.
; ast Time gives something like:
; Local Time : Mon May 10 14:33:36 2021
Func GetLocalTime($hTestSummary, ByRef $aSysTime)
	MakeAstTtl("ast Time", 5)
	RunAstTtl()
	$aSysTime[0] = FindNthStringInFile("Local", "ast", 5)
	$aSysTime[1] = FindNthStringInFile("Local", "ast", 6)
	$aSysTime[2] = FindNthStringInFile("Local", "ast", 7)
EndFunc   ;==>GetLocalTime


; Purpose:  Send a UIM with specified DST entry/exit times.
; $aDstDiagHex[]  Diagnostics Array : UA, gps, entry, exit
Func SendDstUim($hTestSummary, $aDstDiagHex)
	; Create a UIM.  Example:
	; "msp:9d,10,2a,00,1D,59,51,d2,00,69,00,13,00,00,00,40,40,00,00,1f,af,c6,20,4d,77,4f,76,4e,b2,65,f7,02,10,40,7f,fd,00,00,00,ff,fc,c0,ae,3d,1a,55,55,55"
	; Pacific timezone = 60 minutes * 8 hours = -480
	; TZ_field (2 bytes) = dst Enable (E) + tz Defined (D) + reserved (xxx) + timezone minutes (T) = EDxx xTT TTTT TTTT
	; -480 = 0xfe20 -> filter 11 bits, 110 0010 0000 -> plus dst Enable (E) and tz Defined (D), EDxx x110 0010 0000  (x should be 1, reserved)
	; fe,20, => 1111 1110 0010 0000
	; c6,20, => 1100 0110 0010 0000
	Local $sTZ_field = "c6,20,"
	Local $sUimMsg = "msp:9d,10,2a," & _
			$aDstDiagHex[0] & _
			"00,69,00,13,00,00,00,40,40,00,00,1f,af," & _
			$aDstDiagHex[4] & _
			$aDstDiagHex[2] & $aDstDiagHex[3] & _
			"02,10,40,7f,fd,00,00,00,ff,fc"
	Local $aUimCmd[] = ["wait:1000; " & $sUimMsg]
	MakeCmdDrip($aUimCmd)
	RunDripTest("cmd")
EndFunc   ;==>SendDstUim


; Purpose: Reboot the box.  The VCT_ID and Number of Channels should not change.
; This tests the following
; 5	"DSR SI&T.System Control.Power Up, Down, Reset:005-004"	EMM provider ID
; 5	"DSR SI&T.System Control.Power Up, Down, Reset:005-006"	CDT
; 5	"DSR SI&T.System Control.Power Up, Down, Reset:005-007"	MMT
; 5	"DSR SI&T.System Control.Power Up, Down, Reset:005-008"	SIT
; 5	"DSR SI&T.System Control.Power Up, Down, Reset:005-009"	TDTs
; 5	"DSR SI&T.System Control.Power Up, Down, Reset:005-010"	Virtual Channel Records
; 5	"DSR SI&T.System Control.Power Up, Down, Reset:005-016"	Firmware Code Version
; 2	"DSR SI&T.System Control.Power Up, Down, Reset:006-001"	Boot code execution from flash within 15 seconds of application of power.
; 1	"DSR SI&T.System Control.Power Up, Down, Reset:006-002"	DSR should power on from internal flash memory.
Func RunRebootTest($hTestSummary)
	Local $bPass = True
	Global $hBoxIPAddress

	; Get Diagnostics
	Local $sNumChans1 = GetDiagData("A,5,2", "NumChannels")
	Local $sVct1 = GetDiagData("A,5,3", "VCT_ID")
	GUICtrlSetData($hTestSummary, "Before Reboot: Num Channels = " & $sNumChans1 & ", VCT_ID = " & $sVct1 & @CRLF)

	; Reboot the box.
	RebootBox()

	; Get Diagnostics
	Local $sNumChans2 = GetDiagData("A,5,2", "NumChannels")
	Local $sVct2 = GetDiagData("A,5,3", "VCT_ID")
	GUICtrlSetData($hTestSummary, "After Reboot: Num Channels = " & $sNumChans2 & ", VCT_ID = " & $sVct2 & @CRLF)

	If $sNumChans1 == $sNumChans2 And $sVct1 == $sVct2 Then
		GUICtrlSetData($hTestSummary, "Reboot Test - Pass")
	Else
		GUICtrlSetData($hTestSummary, "Reboot Test - Fail")
		$bPass = False
	EndIf
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:005-004"', $bPass)
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:005-006"', $bPass)
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:005-007"', $bPass)
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:005-008"', $bPass)
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:005-009"', $bPass)
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:005-010"', $bPass)
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:005-016"', $bPass)
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:006-001"', $bPass)
	SavePassFailTestResult('"DSR SI&T.System Control.Power Up, Down, Reset:006-002"', $bPass)

	Return $bPass
EndFunc   ;==>RunRebootTest


; Purpose: Collect SF counter metrics for various Table ID values.
; Note: We are only interested in TableID's 0, 1, and 2 for this test.
;       Other TableID's are shown for further verification of messages being received.
; This tests the following:
; 3	DSR SI&T.System Control.PrivMessg:001-001	Verify that private messages are processed
Func RunPrivStreamMsgTest($hTestSummary)
	Local $bPass = True
	Local $aSfStats[12][5] = [ _
			["0", "", "", "Service Assoc (PAT)", True], _
			["1", "", "", "Conditional Access", True], _
			["2", "", "", "Service Map (PMT)", True], _
			["92", "", "", "Channel Override", False], _
			["94", "", "", "Download Preamble", False], _
			["c0", "", "", "PIM", False], _
			["c1", "", "", "PNM", False], _
			["c2", "", "", "Network Information", False], _
			["c3", "", "", "Network Text", False], _
			["c4", "", "", "Virtual Channel", False], _
			["c5", "", "", "System Time", False], _
			["e6", "", "", "Guide", False]]

	Local $iSize = UBound($aSfStats, $UBOUND_ROWS) - 1 ; Compute size of array

	MakeAstTtl("ast sf", 5)
	RunAstTtl()
	For $ii = 0 To $iSize Step 1
		$aSfStats[$ii][1] = FindNextStringInFile("tableID " & $aSfStats[$ii][0], "ast")
	Next

	Sleep(5000)
	RunAstTtl()

	For $ii = 0 To $iSize Step 1
		$aSfStats[$ii][2] = FindNextStringInFile("tableID " & $aSfStats[$ii][0], "ast")
	Next

	For $ii = 0 To $iSize Step 1
		Local $sPassFail = " - Pass"
		Local $sHeading = ""
		$aSfStats[$ii][2] = FindNextStringInFile("tableID " & $aSfStats[$ii][0], "ast")
		If $aSfStats[$ii][4] Then
			If $aSfStats[$ii][1] == $aSfStats[$ii][2] Then
				$sPassFail = " - Fail"
				$bPass = False
			EndIf
			$sHeading = "Analyze - "
		Else
			$sPassFail = ""
			$sHeading = "Info Only - "
		EndIf
		GUICtrlSetData($hTestSummary, $sHeading & $aSfStats[$ii][0] & " " & $aSfStats[$ii][3] & ": " & $aSfStats[$ii][1] & " / " & $aSfStats[$ii][2] & $sPassFail & @CRLF)
	Next
	SavePassFailTestResult('DSR SI&T.System Control.PrivMessg:001-001', $bPass)

	Return $bPass
EndFunc   ;==>RunPrivStreamMsgTest

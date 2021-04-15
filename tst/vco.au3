; Purpose:  To run the VCO tests.


#include-once
#include <RegTstUtil.au3>

$sXYZ = ""
$sRegion = ""
$sVctIdHex = ""
$sVCN = ""
$sFrom = ""
$sTo = ""
$sXpndr = ""
$sSvcNum = ""
$sSrcId = ""
;$sGpsSecs = ""

; Purpose:  Entry point to VCO tests.
Func RunVCOTest($TestSummary, $VCO_pf)
	Local $bPass = True

	;CollectSerialLogs("VcoSerial", False)    ; Start collection of serial log file (just in case it reboots)
	GUICtrlSetData($TestSummary, "==> VCO Test Started")
	PF_Box("Running", $COLOR_BLUE, $VCO_pf)
	GUICtrlSetColor($VCO_pf, $COLOR_GREEN)

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")

	If $sVctId = "4380" Then
		$sFrom = 125
		$sTo = 252
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT5")
	ElseIf $sVctId = "4188" Then
		$sFrom = 66
		$sTo = 166
		ChanChangeDrip("rmt:DIGIT0", "rmt:DIGIT6", "rmt:DIGIT6")
	Else
		GUICtrlSetData($TestSummary, "VCT_ID is " & $sVctId & ", Need either 4188 or 4380 to run test." & @CRLF)
		GUICtrlSetData($TestSummary, "<== VCO Test Done")
		PF_Box("Skipped", $COLOR_GREEN, $VCO_pf)
		Return
	EndIf

	InitVcoInfo()

	;$bPass = VCO_regress_001_001($TestSummary, $VCO_pf) And $bPass
	;$bPass = VCO_regress_001_002($TestSummary, $VCO_pf) And $bPass
	;$bPass = VCO_regress_001_003($TestSummary, $VCO_pf) And $bPass
	;$bPass = VCO_regress_001_004($TestSummary, $VCO_pf) And $bPass
	;$bPass = VCO_regress_001_005($TestSummary, $VCO_pf) And $bPass
	;$bPass = VCO_regress_001_007($TestSummary, $VCO_pf) And $bPass
	;$bPass = VCO_regress_001_008($TestSummary, $VCO_pf) And $bPass
	;$bPass = VCO_regress_001_009($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_010($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_012($TestSummary, $VCO_pf) And $bPass



	#comments-start
		If $sBoxType = "DSR800" Then
			MakeRmtCmdDrip("sea:all", 30000)    ; Collect data for 30 seconds for VCO to end.
		Else
			; Box is an 830.  Now do some trick plays.
			MakeRmtCmdDrip("rmt:REWIND", 3000)
			$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "2. RW", $TestSummary, $VCO_pf) And $bPass
			MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
			$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "3. FF", $TestSummary, $VCO_pf) And $bPass
			MakeRmtCmdDrip("rmt:PLAY", 2000)
			$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "4. Play (video)", $TestSummary, $VCO_pf) And $bPass
			$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "4. Play (audio)", $TestSummary, $VCO_pf) And $bPass
			MakeRmtCmdDrip("rmt:STOP", 2000)
			$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "5. Stop (video)", $TestSummary, $VCO_pf) And $bPass
			$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "5. Stop (audio)", $TestSummary, $VCO_pf) And $bPass
			GUICtrlSetData($TestSummary, "Wait 10 seconds for VCO to end." & @CRLF)
			MakeRmtCmdDrip("sea:all", 10000) ; Wait 10 seconds for VCO to end
		EndIf

		; The RunTestCriteria will run the 'cmd' file which collects log data for 30 seconds and then checks for the video start string for pass/fail criteria.
		$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS, CH: " & $sFrom, "VCO Return (video CH " & $sFrom & ")", $TestSummary, $VCO_pf) And $bPass
		$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS, CH: " & $sFrom, "VCO Return (audio CH " & $sFrom & ")", $TestSummary, $VCO_pf) And $bPass

		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-001", $bPass)
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-002", $bPass)
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-003", $bPass)
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-010", $bPass)
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-014", $bPass)
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-015", $bPass)

		GUICtrlSetData($TestSummary, "<== VCO Test Done")
		Sleep(6000)  ; Sleep 6 seconds just in case it crashes.
		;WinKill("COM" & $sComPort)                            ; End collection of serial log file
	#comments-end

	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $VCO_pf)
	Else
		PF_Box("Fail", $COLOR_Red, $VCO_pf)
	EndIf
EndFunc   ;==>RunVCOTest

; Purpose - Initialize VCO Information
; This gets the xyz coordinates of the box, the region, the gps seconds,
; and gets the sourceID, SvcNum, and XpndID of the destination channel.
; It converts the values to comma separated hex values that can be used
; in making a VCO Drip command.
Func InitVcoInfo()
	$sVCN = Hex($sFrom, 2)
	$sVCN = CommaSeparatedBytes($sVCN, 2)
	$sVctIdHex = Hex($sVctId)
	$sVctIdHex = CommaSeparatedBytes($sVctIdHex, 2)

	MakeRmtCmdDrip("diag:A", 1000)    ; Get Diag A data which has VCT_ID, XYZ, Region, and GPS Seconds.
	RunDripTest("cmd")
	$sVctId = FindNthStringInFile("VCT_ID", "cmd", 1)
	$sX = FindNthStringInFile("XYZ", "cmd", 1)
	$sY = FindNthStringInFile("XYZ", "cmd", 2)
	$sZ = FindNthStringInFile("XYZ", "cmd", 3)
	$sX = CommaSeparatedBytes($sX, 2)
	$sY = CommaSeparatedBytes($sY, 2)
	$sZ = CommaSeparatedBytes($sZ, 2)

	$sXYZ = $sX & $sY & $sZ
	$sRegion = FindNthStringInFile("Region", "cmd", 1)
	$sRegion = CommaSeparatedBytes($sRegion, 1)        ; Region data is 1 byte
	;$sGpsSecs = FindNthStringInFile("Secs", "cmd", 1)
	;$sGpsSecs = CommaSeparatedBytes($sGpsSecs, 4)    ; System time is 4 bytes

	MakeAstTtl("ast chan " & $sTo, 5)     ; Get the chan stats for the destination vco channel
	RunAstTtl()
	; Get something like
	; # Rec Chan  XPndr  Sat  Pol    Frequency     Symbol   Code  Modul  Tone  Svc  SourceID
	; Num  Num    ID   ---  ---       Hz          Rate    Rate   ---   ----  Num    (hex)
	; 1    252     2    97   VR   995250000*    20500000  1.92  PSK_8   1    863    fd34
	$sXpndr = FindNthStringInFile("XPndr", "ast", 24)    ; Skips 24 strings and returns the next one.
	$sXpndr = Hex($sXpndr, 2) & ","   ; Convert to hex, 1 byte, add a comma at the end
	$sSvcNum = FindNthStringInFile("Svc", "ast", 24)    ; Skips 24 strings and returns the next one.
	$sSvcNum = Hex($sSvcNum, 4)   ; Convert to hex, 2 bytes
	$sSvcNum = CommaSeparatedBytes($sSvcNum, 2)     ; SvcNum is 2 bytes
	$sSrcId = FindNthStringInFile("SourceID", "ast", 24)    ; Skips 24 strings and returns the next one.
	$sSrcId = CommaSeparatedBytes($sSrcId, 2)    ; SourceID is 2 bytes
	;ConsoleWrite("Xpndr, SvcNum = " & $sXpndr & ", " & $sSvcNum & @CRLF)
EndFunc   ;==>InitVcoInfo

; Purpose - Takes a hex value, strips off the 0x if necessary, and separates into bytes.
; Note: Useful for creating a msp message.
Func CommaSeparatedBytes($sHexValue, $numBytes)
	Local $sCommaSepVal = ""
	; First, strip off any 0x from string
	$sHexValue = StringRegExpReplace($sHexValue, "0x", "")
	; Next, separate into comma separated bytes.
	$sHexValue = Dec($sHexValue, $NUMBER_AUTO)
	$sHexValue = Hex($sHexValue, $numBytes * 2)
	For $i = 1 To $numBytes
		$sCommaSepVal = $sCommaSepVal & StringMid($sHexValue, $i * 2 - 1, 2) & ","
	Next
	Return $sCommaSepVal
EndFunc   ;==>CommaSeparatedBytes


; Purpose - Make the VCO.
; $iStartTime - 0 for immediate, -/+ secs for past/future start time, e.g., 10 means it will start 10 seconds from now.
; $sDurHex - VCO duration, e.g., use "20," for 32 seconds.
; $sLogDuration - Log collection duration, e.g., "35000" for 35 seconds.
; $sCondition (hex) - 40,R,X,X,Y,Y,Z,Z (circle_test + 7 bytes), 12,00 (region_blacked_out + 0), 3e,T,T,T (tier + 3 bytes), etc.
; $bInclusive - True for normal, False for exclusive case (e.g., not in the circle)
; Notes:  Preamble conditions are as follows:
; 	Circular_blacked_out 0x11 – Requires auth state of “circular blacked out”. Sent with one byte = 00
; 	Regional_blacked_out 0x12 – Requires auth state of “regional blacked out”. Sent with one byte = 00
; 	Region 0x1B – Sent with one byte of Region in preamble.
; 	Tier_match 0x3e– Sent with three bytes of tier in preamble.
; 	Circle_test 0x40 – Sent with seven bytes of circle data in preamble
; Notes: Duration is hardcoded to 0x20 (32 seconds)
Func MakeCmdVCO($iStartTime, $sDurHex, $sLogDuration, $sCondition, $bInclusive)

	Local $Duration = 32        ; Make VCO duration 32 seconds.
	Local $sLen1, $sLen2
	Local $sStartTime = ComputeStartTime($iStartTime)

	$iCondLen = Int(StringLen($sCondition)) / 3
	$sMsgLen = Hex(Int($iCondLen + 44), 2) & ","
	$sLen1 = Hex(Int($iCondLen + 14), 2) & ","
	$sLen2 = Hex(Int($iCondLen + 11), 2) & ","
	ConsoleWrite("CondLen=" & $iCondLen & " MsgLen=" & $sMsgLen & " sLen1=" & $sLen1 & " sLen2=" & $sLen2 & " DurHex=" & $sDurHex & @CRLF)

	If $bInclusive = True Then
		$sInclusive = "0e,"    ; first term, eol (inclusive)
	Else
		$sInclusive = "0d,"    ; not, first term (exclusive)
	EndIf

	Local $aVcoCmd[2] = ["wait:1000; msp:92,00," & _
			$sMsgLen & _
			"20," & _
			$sLen1 & _
			"00,00," & _
			$sLen2 & _
			$sInclusive & _
			"ee,ee,ee,ee,ee,ee,ee,ee,ee,01," & _
			$sCondition & _
			"00,00,00,45,0e,00," & _
			$sStartTime & _
			"00,00," & $sDurHex & _
			$sVctIdHex & _
			$sVCN & "40," & $sSrcId & "61," & $sXpndr & StringTrimRight($sSvcNum, 1), _
			"wait:" & $sLogDuration & "; sea:all"]
	MakeCmdDrip($aVcoCmd)
EndFunc   ;==>MakeCmdVCO

; Purpose - To compute the GPS Start Time
Func ComputeStartTime($iStartTime)
	Local $sStartTime = ""
	If $iStartTime = 0 Then
		$sStartTime = "00,00,00,00,"
	Else
		$sStartTime = GetDiagData("A,6,1", "Secs")
		$sStartTime = StringTrimLeft($sStartTime, 2)
		$sStartTime = Dec($sStartTime, $NUMBER_AUTO)
		$sStartTime = $sStartTime + $iStartTime
		$sStartTime = CommaSeparatedBytes(Hex($sStartTime), 4)
	EndIf
	Return $sStartTime
EndFunc   ;==>ComputeStartTime



; Requirement:  DSR SI&T.System Control.VCO regress & DVR:001-001
; 1) Verify that the VCO commences at the correct time and the correct audio and video is received.
; 2) Verify that the VCO ends at the conclusion of the show and audio/video is returned to the default channel. Verify that the transition is seamless with no artifacts.
; Verify that the map (VCT_ID) matches that for the established VCO. Verfiy that units with a different map are not affected by the VCO.
Func VCO_regress_001_001($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(10, "20,", "38000", "40,19," & $sXYZ, True)
	GUICtrlSetData($hTestSummary, "Future Circle started in 10 seconds. ")
	$bPass = RunAndTestForVco($hTestSummary, "Future Circle", True) And $bPass

	; Change the VCT_ID
	$sVctIdHexTemp = $sVctIdHex
	$sVctIdHex = "12,34,"
	MakeCmdVCO(0, "20,", "10000", "40,19," & $sXYZ, True)
	GUICtrlSetData($hTestSummary, "Immediate Circle started with different VCT_ID, should not VCO. ")
	$bPass = RunAndTestForVco($hTestSummary, "Immed Circle", False) And $bPass
	$sVctIdHex = $sVctIdHexTemp
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-001", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_001

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-002
; Note the tuner that is in use for section 3.1.1 via Diag A. Tune to a different VCO test channel and verify that the opposite tuner is now in use.
Func VCO_regress_001_002($hTestSummary, $VCO_pf)
	Local $bPass = True
	If $sBoxType = "DSR800" Then
		GUICtrlSetData($hTestSummary, "This is a single tuner box, DSR800, skip test 001-002" & @CRLF)
	Else
		GUICtrlSetData($hTestSummary, "Channel up twice." & @CRLF)
		MakeRmtCmdDrip("rmt:CHAN_UP", 4000)
		RunDripTest("cmd")
		RunDripTest("cmd")
		GUICtrlSetData($hTestSummary, "Go back to original channel, different tuner." & @CRLF)
		If $sVctId = "4380" Then
			ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")
		Else
			ChanChangeDrip("rmt:DIGIT0", "rmt:DIGIT6", "rmt:DIGIT6")
		EndIf
		MakeCmdVCO(0, "20,", "38000", "40,19," & $sXYZ, True)
		GUICtrlSetData($hTestSummary, "Immediate Circle started on different tuner, should VCO" & @CRLF)
		$bPass = RunAndTestForVco($hTestSummary, "Alternate tuner", True) And $bPass
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-002", $bPass)
	EndIf
	Return $bPass
EndFunc   ;==>VCO_regress_001_002

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-003
; 1) Verify circle inclusion and exclusion
; Note: Circle inclusion was already tested.  Perform circle exclusion test.
Func VCO_regress_001_003($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(0, "20,", "10000", "40,19," & $sXYZ, False)    ; False means exclusion
	GUICtrlSetData($hTestSummary, "Immediate Circle Exclusion don't VCO")
	$bPass = RunAndTestForVco($hTestSummary, "Circle Inclusion", False) And $bPass
	MakeCmdVCO(0, "20,", "10000", "40,02,11,22,33,44,55,66,", True)
	GUICtrlSetData($hTestSummary, "Immediate Circle different than box, don't VCO")
	$bPass = RunAndTestForVco($hTestSummary, "Different Circle than Box", False) And $bPass    ; Should not VCO
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-003", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_003


; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-004
; 2) Verify regional inclusion and exclusion
Func VCO_regress_001_004($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(0, "20,", "38000", "1b," & $sRegion, True)
	GUICtrlSetData($hTestSummary, "Regional VCO started, should VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Regional", True) And $bPass
	MakeCmdVCO(0, "20,", "10000", "1b,55,", True)  ; Different Region test, should not VCO
	GUICtrlSetData($hTestSummary, "Different Regional VCO started, should not VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Different Region than box", False) And $bPass
	MakeCmdVCO(0, "20,", "38000", "1b,55,", False)  ; Different Region test, should  VCO
	GUICtrlSetData($hTestSummary, "Different Regional VCO started, exclusion, should VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Different Region than box, exclusion", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-004", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_004

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-005
; 3) Verify tier inclusion and exclusion
Func VCO_regress_001_005($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(0, "20,", "10000", "3e,00,00,00,", True)    ; Hard-coded to tier 1
	GUICtrlSetData($hTestSummary, "Tier Inclusion started, will VCO if has tier 1, should not VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Tier different than box", False) And $bPass
	MakeCmdVCO(0, "20,", "35000", "3e,00,00,00,", False)  ; Region exclusion test
	GUICtrlSetData($hTestSummary, "Tier Exclusion started, will VCO if doesn't have tier 1, should VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Tier different than box exclusion test", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-005", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_005

; DSR SI&T.System Control.VCO regress & DVR:001-006
; 4) Unconditional based on VCT ID
; Not implemented by DSR8XX.  Do not test.

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-007
; 5) Blacked out
; 	Circular_blacked_out 0x11 – Requires auth state of “circular blacked out”. Sent with one byte = 00
; 	Regional_blacked_out 0x12 – Requires auth state of “regional blacked out”. Sent with one byte = 00
Func VCO_regress_001_007($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(0, "20,", "35000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "Auth State Circular Blackout started, exclusion test, should VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Circular_Blackout, exclusion", True) And $bPass
	MakeCmdVCO(0, "20,", "35000", "12,00,", False)  ; Region_blackout exclusion test
	GUICtrlSetData($hTestSummary, "Auth State Regional Blackout, Exclusion started, should VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Regional_Blackout, exclusion test", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-007", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_007

; Requirement:  DSR SI&T.System Control.VCO regress & DVR:001-008
; Preamble verification and back to back VCO use case
Func VCO_regress_001_008($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(0, "20,", "20000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "First back-to-back started, 32 seconds duration, should VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "First back-to-back", True) And $bPass
	MakeCmdVCO(13, "20,", "35000", "12,00,", False)  ; Region_blackout exclusion test
	GUICtrlSetData($hTestSummary, "Second back-to-back starts in 14 seconds, should VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Second back-to-back", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-008", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_008


; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-009
; Activation in the past
Func VCO_regress_001_009($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(-10, "30,", "37000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "VCO with start time in the past, should VCO" & @CRLF)
	$bPass = RunAndTestForVco($hTestSummary, "Past start time", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-009", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_009

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-010
; Immediate activation and conflicting overrides
Func VCO_regress_001_010($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(15, "30,", "1000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "VCO with start time in the future by 15 seconds, for 48 seconds" & @CRLF)
	RunDripTest("cmd")
	GUICtrlSetData($hTestSummary, "Override VCO with start time in the future by 5 seconds for 32 seconds" & @CRLF)
	MakeCmdVCO(5, "20,", "35000", "11,00,", False)    ; Circular Blacked Out, exclusion
	$bPass = RunAndTestForVco($hTestSummary, "Override start time and duration", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-010", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_010

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-012
; VCOs not saved on AC cycle
Func VCO_regress_001_012($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(60, "ff,", "1000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "VCO with start time in the future by 60 seconds, for 4 minutes 15 seconds" & @CRLF)
	RunDripTest("cmd")
	MakeAstTtl("ast vco", 5)
	RunAstTtl()
	; Get something like
	; # ---- Pending VCOs ---------------
	; currentTime = 0x4da0db42 (16:18:32)
	; ACTIV.TIME              chan  dur. Seq.#  VCTID svc Xpdr pending_time
	; --- Active VCOs ---------------
	; ACTIV.TIME              chan  dur. Seq.#  VCTID svc Xpdr remaining_time
	; 0x4da0d6ed (16:0:3)   240   3600    71     4380  712  1  2491
	Local $iStringInFileBefore = FindStringInFile($sFrom, "ast")        ; Look for the VCO channel

	RebootBox()
	MakeAstTtl("ast vco", 5)     ; Get the vco stats for the destination vco channel
	RunAstTtl()

	$iStringInFileAfter = FindStringInFile($sFrom, "ast")        ; Look for the VCO channel after rebooting.  Should not be there.
	If $iStringInFileAfter = 0 And $iStringInFileBefore <> 0 Then
		GUICtrlSetData($hTestSummary, " - Passed VCO not kept after power cycle")
	Else
		$bPass = False
		GUICtrlSetData($hTestSummary, " - Failed VCO still present after power cycle.")
	EndIf

	Return $bPass
EndFunc   ;==>VCO_regress_001_012

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-013
; VCO Channel change use cases
; DSR SI&T.System Control.VCO regress & DVR:001-014
; Trick play within VCO LOD use case
; DSR SI&T.System Control.VCO regress & DVR:001-015
; Trick play across VCO show end boundary use case
; DSR SI&T.System Control.VCO regress & DVR:001-016
; Delayed video on VCO start and saved LOD recordings use case
; DSR SI&T.System Control.VCO regress & DVR:001-017
; Delayed video on VCO end use case
; DSR SI&T.System Control.VCO regress & DVR:001-018
; Immediate VCO and LOD use case
; DSR SI&T.System Control.VCO regress & DVR:001-019
; Delayed video and immediate VCO use case
; DSR SI&T.System Control.VCO regress & DVR:001-022
; Simple background record use case
; DSR SI&T.System Control.VCO regress & DVR:001-023
; Back to back recording with a normal program use case
; DSR SI&T.System Control.VCO regress & DVR:001-024
; Back to back VCO recordings use case
; DSR SI&T.System Control.VCO regress & DVR:001-025
; Immediate VCO on background recording use case
; DSR SI&T.System Control.VCO regress & DVR:001-026
; Watch and record: single VCO use case
; DSR SI&T.System Control.VCO regress & DVR:001-027
; Watch and record: dual VCOs use case
; DSR SI&T.System Control.VCO regress & DVR:001-028
; Dual VCO recordings use case



Func VCO_regress_001_013($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO(15, "30,", "1000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "VCO with start time in the future by 15 seconds, for 48 seconds" & @CRLF)
	RunDripTest("cmd")
	GUICtrlSetData($hTestSummary, "Override VCO with start time in the future by 5 seconds for 32 seconds" & @CRLF)
	MakeCmdVCO(5, "20,", "35000", "11,00,", False)    ; Circular Blacked Out, exclusion
	$bPass = RunAndTestForVco($hTestSummary, "Override start time and duration", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-010", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_010


; Purpose:  This runs the VCO test condition.
; $sTestType - The test description, for printing out.
; bShouldVco: True if it should VCO, False if it should not.
; Return: True if it passed the test.
Func RunAndTestForVco($hTestSummary, $sTestType, $bShouldVco)
	Local $bPass = True
	RunDripTest("cmd")
	Local $iStringInFile = FindStringInFile("SEND VIDEO_COMPONENT_START_SUCCESS, CH", "cmd")
	ConsoleWrite("bShouldVco =" & $bShouldVco & ", FindString VIDEO COMPONENT =" & $iStringInFile & @CRLF)
	If ($bShouldVco And Not $iStringInFile) Or _
			($iStringInFile And Not $bShouldVco) Then
		$bPass = False
		GUICtrlSetData($hTestSummary, " - Failed " & $sTestType & @CRLF)
	Else
		GUICtrlSetData($hTestSummary, " - Passed " & $sTestType & @CRLF)
	EndIf
	Return $bPass
EndFunc   ;==>RunAndTestForVco


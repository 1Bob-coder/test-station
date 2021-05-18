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

	MakeRmtCmdDrip("ses:3", 1000)
	RunDripTest("cmd")
	MakeRmtCmdDrip("sea:all", 1000)
	RunDripTest("cmd")

	If $sVctId = "4380" Then
		$sFrom = 125
		$sTo = 252
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT5")
	ElseIf $sVctId = "4188" Then
		$sFrom = 66
		$sTo = 166
		ChanChangeDrip("rmt:DIGIT0", "rmt:DIGIT6", "rmt:DIGIT6")
	ElseIf $sVctId = "8111" Then
		$sFrom = 132
		$sTo = 135
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT3", "rmt:DIGIT2")
	Else
		GUICtrlSetData($TestSummary, "VCT_ID is " & $sVctId & ", Need either 4188, 8111, or 4380 to run test." & @CRLF)
		GUICtrlSetData($TestSummary, "<== VCO Test Done")
		PF_Box("Skipped", $COLOR_GREEN, $VCO_pf)
		Return
	EndIf

	InitVcoInfo()
	$bPass = VCO_regress_001_001($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_002($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_003($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_004($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_005($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_007($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_008($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_009($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_010($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_012($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_001_013($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_TrickPlays($TestSummary, $VCO_pf) And $bPass
	$bPass = VCO_regress_Record($TestSummary, $VCO_pf) And $bPass

	GUICtrlSetData($TestSummary, "<== VCO Test Done")

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


; Purpose - Make the VCO.
; $sChanNum - Channel number to redefine.
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
Func MakeCmdVCO($sChanNum, $iStartTime, $sDurHex, $sLogDuration, $sCondition, $bInclusive)
	Local $sVCN = Hex($sChanNum, 2)
	Local $sLen1, $sLen2
	Local $sStartTime = ComputeStartTime($iStartTime)
	Local $sSeqNum = StringFormat("%.2d", Random(1, 99, 1))      ; Need to randomize a sequence number
	$sVCN = CommaSeparatedBytes($sVCN, 2)
	$iCondLen = Int(StringLen($sCondition)) / 3
	$sMsgLen = Hex(Int($iCondLen + 44), 2) & ","
	$sLen1 = Hex(Int($iCondLen + 14), 2) & ","
	$sLen2 = Hex(Int($iCondLen + 11), 2) & ","

	If $bInclusive = True Then
		$sInclusive = "0e,"    ; first term, eol (inclusive)
	Else
		$sInclusive = "0d,"    ; not, first term (exclusive)
	EndIf

	Local $sVcoMsg = "msp:92,00," & _
			$sMsgLen & _
			"20," & _
			$sLen1 & _
			"00,00," & _
			$sLen2 & _
			$sInclusive & _
			"ee,ee,ee,ee,ee,ee,ee,ee,ee,01," & _
			$sCondition & _
			"00,00,00," & $sSeqNum & ",0e,00," & _
			$sStartTime & _
			"00,00," & $sDurHex & _
			$sVctIdHex & _
			$sVCN & "40," & $sSrcId & "61," & $sXpndr & StringTrimRight($sSvcNum, 1)

	ConsoleWrite("VCO_msg = " & $sVcoMsg & @CRLF)

	Local $aVcoCmd[] = ["wait:1000; " & $sVcoMsg & ",", _
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
	MakeCmdVCO($sFrom, 10, "20,", "38000", "40,19," & $sXYZ, True)
	GUICtrlSetData($hTestSummary, "Future Circle started in 10 seconds. ")
	$bPass = RunAndTestForVideoStart($hTestSummary, "Future Circle", True) And $bPass

	; Change the VCT_ID
	$sVctIdHexTemp = $sVctIdHex
	$sVctIdHex = "12,34,"
	MakeCmdVCO($sFrom, 0, "20,", "10000", "40,19," & $sXYZ, True)
	GUICtrlSetData($hTestSummary, "Immediate Circle started with different VCT_ID, should not VCO. ")
	$bPass = RunAndTestForVideoStart($hTestSummary, "Immed Circle", False) And $bPass
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
			ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT5")
		ElseIf $sVctId = "8111" Then
			ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")
		Else
			ChanChangeDrip("rmt:DIGIT0", "rmt:DIGIT6", "rmt:DIGIT6")
		EndIf
		Sleep(10000)    ; Sleep for 10 seconds.
		MakeCmdVCO($sFrom, 0, "20,", "38000", "40,19," & $sXYZ, True)
		GUICtrlSetData($hTestSummary, "Immediate Circle started on different tuner, should VCO" & @CRLF)
		$bPass = RunAndTestForVideoStart($hTestSummary, "Alternate tuner", True) And $bPass
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-002", $bPass)
	EndIf
	Return $bPass
EndFunc   ;==>VCO_regress_001_002

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-003
; 1) Verify circle inclusion and exclusion
; Note: Circle inclusion was already tested.  Perform circle exclusion test.
Func VCO_regress_001_003($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO($sFrom, 0, "20,", "10000", "40,19," & $sXYZ, False)    ; False means exclusion
	GUICtrlSetData($hTestSummary, "Immediate Circle Exclusion don't VCO")
	$bPass = RunAndTestForVideoStart($hTestSummary, "Circle Inclusion", False) And $bPass
	MakeCmdVCO($sFrom, 0, "20,", "10000", "40,02,11,22,33,44,55,66,", True)
	GUICtrlSetData($hTestSummary, "Immediate Circle different than box, don't VCO")
	$bPass = RunAndTestForVideoStart($hTestSummary, "Different Circle than Box", False) And $bPass    ; Should not VCO
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-003", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_003


; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-004
; 2) Verify regional inclusion and exclusion
Func VCO_regress_001_004($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO($sFrom, 0, "20,", "38000", "1b," & $sRegion, True)
	GUICtrlSetData($hTestSummary, "Regional VCO started, " & $sRegion & ", should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Regional", True) And $bPass
	MakeCmdVCO($sFrom, 0, "20,", "10000", "1b,55,", True)  ; Different Region test, should not VCO
	GUICtrlSetData($hTestSummary, "Different Regional VCO started, should not VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Different Region than box", False) And $bPass
	MakeCmdVCO($sFrom, 0, "20,", "38000", "1b,55,", False)  ; Different Region test, should  VCO
	GUICtrlSetData($hTestSummary, "Different Regional VCO started, exclusion, should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Different Region than box, exclusion", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-004", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_004

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-005
; 3) Verify tier inclusion and exclusion
Func VCO_regress_001_005($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO($sFrom, 0, "20,", "10000", "3e,00,00,00,", True)    ; Hard-coded to tier 1
	GUICtrlSetData($hTestSummary, "Tier Inclusion started, will VCO if has tier 1, should not VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Tier different than box", False) And $bPass
	MakeCmdVCO($sFrom, 0, "20,", "35000", "3e,00,00,00,", False)  ; Region exclusion test
	GUICtrlSetData($hTestSummary, "Tier Exclusion started, will VCO if doesn't have tier 1, should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Tier different than box exclusion test", True) And $bPass
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
	MakeCmdVCO($sFrom, 0, "20,", "35000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "Auth State Circular Blackout started, exclusion test, should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Circular_Blackout, exclusion", True) And $bPass
	MakeCmdVCO($sFrom, 0, "20,", "35000", "12,00,", False)  ; Region_blackout exclusion test
	GUICtrlSetData($hTestSummary, "Auth State Regional Blackout, Exclusion started, should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Regional_Blackout, exclusion test", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-007", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_007

; Requirement:  DSR SI&T.System Control.VCO regress & DVR:001-008
; Preamble verification and back to back VCO use case
Func VCO_regress_001_008($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO($sFrom, 0, "20,", "20000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "First back-to-back started, 32 seconds duration, should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "First back-to-back", True) And $bPass
	MakeCmdVCO($sFrom, 13, "20,", "35000", "12,00,", False)  ; Region_blackout exclusion test
	GUICtrlSetData($hTestSummary, "Second back-to-back starts in 14 seconds, should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Second back-to-back", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-008", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_008


; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-009
; Activation in the past
Func VCO_regress_001_009($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO($sFrom, -10, "30,", "37000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "VCO with start time in the past, should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "Past start time", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-009", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_009

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-010
; Immediate activation and conflicting overrides
Func VCO_regress_001_010($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO($sFrom, 15, "30,", "1000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "VCO with start time in the future by 15 seconds, for 48 seconds" & @CRLF)
	RunDripTest("cmd")
	GUICtrlSetData($hTestSummary, "Override VCO with start time in the future by 5 seconds for 32 seconds" & @CRLF)
	MakeCmdVCO($sFrom, 5, "20,", "35000", "11,00,", False)    ; Circular Blacked Out, exclusion
	$bPass = RunAndTestForVideoStart($hTestSummary, "Override start time and duration", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-010", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_010

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-012
; VCOs not saved on AC cycle
Func VCO_regress_001_012($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO($sFrom, 60, "ff,", "1000", "11,00,", False)    ; Circular Blacked Out, exclusion
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
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-012", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_012

; Requirement: DSR SI&T.System Control.VCO regress & DVR:001-013
; VCO Channel change use cases
Func VCO_regress_001_013($hTestSummary, $VCO_pf)
	Local $bPass = True
	MakeCmdVCO($sFrom, 0, "20,", "5000", "11,00,", False)    ; Circular Blacked Out, exclusion
	GUICtrlSetData($hTestSummary, "VCO started, collect for 5 sec, should VCO" & @CRLF)
	$bPass = RunAndTestForVideoStart($hTestSummary, "VCO started", True) And $bPass
	; Channel change up, then channel change down.
	MakeRmtCmdDrip("rmt:CHAN_UP", 8000)        ; Chan Up, collect logs for 8 seconds
	$bPass = RunAndTestForVideoStart($hTestSummary, "Channel up, collect for 8 sec", True) And $bPass
	MakeRmtCmdDrip("rmt:CHAN_DOWN", 8000)        ; Chan Down, collect logs for 8 seconds
	$bPass = RunAndTestForVideoStart($hTestSummary, "Channel down, collect for 8 sec", True) And $bPass
	MakeRmtCmdDrip("rmt:EXIT", 10000)        ; Wait for VCO to end
	$bPass = RunAndTestForVideoStart($hTestSummary, "VCO ended, collect for 10 sec.", True) And $bPass
	SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-013", $bPass)
	Return $bPass
EndFunc   ;==>VCO_regress_001_013


; Purpose:  To test LOD, Trick Plays, and other recording functions.
Func VCO_regress_TrickPlays($hTestSummary, $VCO_pf)
	Local $bPass = True
	Local $bPassTemp = True
	If $sBoxType = "DSR800" Then
		GUICtrlSetData($hTestSummary, "Box is DSR800.  LOD tests not run.")
	Else
		MakeRmtCmdDrip("rmt:CHAN_UP", 3000)
		RunDripTest("cmd")
		MakeRmtCmdDrip("rmt:CHAN_UP", 3000)
		RunDripTest("cmd")
		MakeRmtCmdDrip("rmt:CHAN_DOWN", 3000)
		RunDripTest("cmd")
		MakeRmtCmdDrip("rmt:CHAN_DOWN", 3000)
		RunDripTest("cmd")

		; Pause LOD.
		Sleep(10000)
		GUICtrlSetData($hTestSummary, "PAUSE during Live" & @CRLF)
		MakeRmtCmdDrip("rmt:PAUSE", 3000)
		RunDripTest("cmd")
		; Send VCO.
		MakeCmdVCO($sFrom, 0, "30,", "5000", "40,19," & $sXYZ, True)    ; 0x30 = 48 seconds.  Make VCO to start immediately.
		GUICtrlSetData($hTestSummary, "Start VCO, then do trick plays." & @CRLF)
		RunDripTest("cmd")
		GUICtrlSetData($hTestSummary, "PLAY and resume Live" & @CRLF)
		MakeRmtCmdDrip("rmt:PLAY", 3000)
		RunDripTest("cmd")
		GUICtrlSetData($hTestSummary, "Wait 20 seconds for transition" & @CRLF)
		MakeRmtCmdDrip("rmt:PLAY", 20000)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "Delayed LOD entry to VCO ", True)

		; DSR SI&T.System Control.VCO regress & DVR:001-014
		; Trick play within VCO LOD use case
		MakeRmtCmdDrip("rmt:FAST_FWD", 3000)
		GUICtrlSetData($hTestSummary, "VCO FAST_FWD" & @CRLF)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "Fast Forward test", True) And $bPassTemp
		MakeRmtCmdDrip("rmt:PLAY", 3000)
		GUICtrlSetData($hTestSummary, "VCO PLAY" & @CRLF)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "Play test", True) And $bPassTemp
		MakeRmtCmdDrip("rmt:REWIND", 3000)
		GUICtrlSetData($hTestSummary, "VCO REWIND" & @CRLF)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "Rewind test", True) And $bPassTemp
		MakeRmtCmdDrip("rmt:PLAY", 3000)
		RunDripTest("cmd")
		GUICtrlSetData($hTestSummary, "VCO PLAY " & @CRLF)
		MakeRmtCmdDrip("rmt:FAST_FWD", 3000)
		GUICtrlSetData($hTestSummary, "VCO FAST_FWD " & @CRLF)
		RunDripTest("cmd")

		; Play again, and check for end of VCO transition while delayed LOD.
		MakeRmtCmdDrip("rmt:PLAY", 25000)
		GUICtrlSetData($hTestSummary, "VCO PLAY  " & @CRLF)
		GUICtrlSetData($hTestSummary, "Look for end of VCO transition while LOD delayed" & @CRLF)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "VCO transition when delayed", True) And $bPassTemp
		MakeRmtCmdDrip("rmt:STOP", 3000)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "Stop test", True) And $bPassTemp
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-014", $bPassTemp)
		; Note:  This also satisfies the following tests:
		; Trick play across VCO show end boundary use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-015", $bPassTemp)
		; Delayed video on VCO start and saved LOD recordings use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-016", $bPassTemp)
		; Delayed video on VCO end use case.  This fails always.  Hardcoded for now.
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-017", False)
		; Immediate VCO and LOD use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-018", $bPassTemp)
		; Delayed video and immediate VCO use case	EndIf
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-019", $bPassTemp)

	EndIf

	Return $bPass And $bPassTemp
EndFunc   ;==>VCO_regress_TrickPlays


; Purpose:  To perform the VCO tests involving recording the show.
; To test all situations,
; 1)  Start a recording
; 2) Send back-to-back VCO's on that channel.
; 3) Channel change
; 4) Start a recording.
; 5) Send a VCO
; 6) Wait until all VCOs are done, and then stop the recordings.
; 7) Play back both recordings.  Should see
;	a) transition from non VCO to VCO and see back-to-back VCO, then back to non VCO
;	b) transition from non VCO to VCO back to non VCO.
Func VCO_regress_Record($hTestSummary, $VCO_pf)
	Local $bPass = True
	Local $bPassTemp = True
	If $sBoxType = "DSR800" Then
		GUICtrlSetData($hTestSummary, "Box is DSR800.  LOD tests not run.")
	Else
		MakeRmtCmdDrip("rmt:CHAN_UP", 3000)
		RunDripTest("cmd")
		MakeRmtCmdDrip("rmt:CHAN_UP", 3000)
		RunDripTest("cmd")
		MakeRmtCmdDrip("rmt:CHAN_DOWN", 3000)
		RunDripTest("cmd")
		MakeRmtCmdDrip("rmt:CHAN_DOWN", 10000)
		RunDripTest("cmd")

		; Start a back-to-back VCO
		MakeCmdVCO($sFrom, 10, "20,", "2000", "11,00,", False)         ; VCO begins in 10 seconds, lasts for 0x20=32 seconds.
		GUICtrlSetData($hTestSummary, "First back-to-back starts in 10 seconds, 32 seconds duration" & @CRLF)
		RunDripTest("cmd")
		MakeCmdVCO($sFrom, 38, "20,", "2000", "11,00,", False) ; Second VCO begins in 38 secs, lasts for 0x20=32 seconds.
		GUICtrlSetData($hTestSummary, "Second back-to-back starts in 38 seconds, lasts 32 seconds" & @CRLF)
		RunDripTest("cmd")

		; Start a recording
		GUICtrlSetData($hTestSummary, "Record current channel." & @CRLF)
		Local $aStartRecording[] = [ _
				"wait:2000; rmt:RECORD", _
				"wait:3000; rmt:ARROW_RIGHT", _
				"wait:2000; rmt:ENTER", _
				"wait:2000; rmt:EXIT"]
		MakeCmdDrip($aStartRecording)
		RunDripTest("cmd")

		; Channel change
		GUICtrlSetData($hTestSummary, "Channel change up" & @CRLF)
		MakeRmtCmdDrip("rmt:CHAN_UP", 3000)
		RunDripTest("cmd")

		; Send VCO for this channel. Look for debug line with "TUNE TO CHANNEL: 125" to get channel number.
		$sChanNum = FindNthStringInFile("TUNE TO CHANNEL", "cmd", 1)
		GUICtrlSetData($hTestSummary, "Send VCO to channel " & $sChanNum & " to begin in 20 seconds, 2-byte hex : " & $sVCN)
		MakeCmdVCO($sChanNum, 20, "20,", "2000", "11,00,", False)         ; VCO begins in 20 seconds, lasts for 0x20=32 seconds.
		RunDripTest("cmd")

		; Start a recording
		GUICtrlSetData($hTestSummary, "Record current channel. " & @CRLF)
		Local $aStartRecording[] = [ _
				"wait:2000; rmt:RECORD", _
				"wait:3000; rmt:ARROW_RIGHT", _
				"wait:2000; rmt:ENTER", _
				"wait:2000; rmt:EXIT"]
		MakeCmdDrip($aStartRecording)
		RunDripTest("cmd")

		; Wait until all VCOs are done, and then stop the recordings.
		GUICtrlSetData($hTestSummary, "Wait one minute and stop recordings." & @CRLF)
		Sleep(60000)
		Local $aStopRecordings[] = [ _
				"wait:3000; rmt:INTERACTIVE", _
				"wait:3000; rmt:ARROW_RIGHT", _
				"wait:2000; rmt:ENTER", _
				"wait:2000; rmt:ARROW_RIGHT", _
				"wait:2000; rmt:ENTER", _
				"wait:2000; rmt:YELLOW", _
				"wait:2000; rmt:ARROW_LEFT", _
				"wait:2000; rmt:ENTER", _
				"wait:2000; rmt:EXIT", _
				"wait:2000; rmt:EXIT"]
		MakeCmdDrip($aStopRecordings)
		GUICtrlSetData($hTestSummary, "Stop first recording." & @CRLF)
		RunDripTest("cmd")
		GUICtrlSetData($hTestSummary, "Stop second recording." & @CRLF)
		RunDripTest("cmd")

		; Play back both recordings.
		GUICtrlSetData($hTestSummary, "Play back last recording. Wait for VCO transition." & @CRLF)
		Local $aPlayBackFirst[] = [ _
				"wait:3000; rmt:LIST", _
				"wait:2000; rmt:ENTER", _
				"wait:2000; rmt:ENTER", _
				"wait:26000; ses:3"]
		MakeCmdDrip($aPlayBackFirst)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "VCO transition PVR Playback", True)

		GUICtrlSetData($hTestSummary, "Wait 25 secs for VCO to end" & @CRLF)
		MakeRmtCmdDrip("rmt:EXIT", 25000)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "VCO end PVR Playback", True) And $bPassTemp

		GUICtrlSetData($hTestSummary, "Wait 45 secs for end of playback" & @CRLF)
		Sleep(45000)

		GUICtrlSetData($hTestSummary, "Play back earlier recording. Wait 10 sec for VCO transition." & @CRLF)
		Local $aPlayBackSecond[] = [ _
				"wait:3000; rmt:ARROW_DOWN", _
				"wait:2000; rmt:ENTER", _
				"wait:2000; rmt:ENTER", _
				"wait:10000; ses:3"]
		MakeCmdDrip($aPlayBackSecond)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "VCO transition PVR Playback ", True) And $bPassTemp

		GUICtrlSetData($hTestSummary, "Wait 35 secs for VCO to VCO transition" & @CRLF)
		MakeRmtCmdDrip("rmt:EXIT", 35000)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "VCO to VCO PVR Playback", True) And $bPassTemp

		GUICtrlSetData($hTestSummary, "Wait 35 secs for VCO to end. " & @CRLF)
		MakeRmtCmdDrip("rmt:EXIT", 35000)
		$bPassTemp = RunAndTestForVideoStart($hTestSummary, "VCO Playback end", True) And $bPassTemp
		GUICtrlSetData($hTestSummary, "Wait 60 secs for second recording to end. " & @CRLF)
		Sleep(60000)

		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-022", $bPassTemp)
		; Simple background record use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-023", $bPassTemp)
		; Back to back recording with a normal program use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-024", $bPassTemp)
		; Back to back VCO recordings use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-025", $bPassTemp)
		; Immediate VCO on background recording use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-026", $bPassTemp)
		; Watch and record: single VCO use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-027", $bPassTemp)
		; Watch and record: dual VCOs use case
		SavePassFailTestResult("DSR SI&T.System Control.VCO regress & DVR:001-028", $bPassTemp)
		; Dual VCO recordings use case
		SavePassFailTestResult("DSR SI&T.System Control.VCOs w Freq Descr:001-003", $bPassTemp)
		; Source channel uses FD, Destination channel uses FD
	EndIf

	Return $bPass And $bPassTemp
EndFunc   ;==>VCO_regress_Record

; Purpose:  This runs the VCO test condition and checks if it got a VideoStart event.
; $sTestType - The test description, for printing out.
; bShouldVco: True if it should VCO, False if it should not.
; Return: True if it passed the test.
Func RunAndTestForVideoStart($hTestSummary, $sTestType, $bShouldVco)
	Local $bPass = True
	RunDripTest("cmd")
	Local $iStringInFile = FindStringInFile("SEND VIDEO_COMPONENT_START_SUCCESS, CH", "cmd")
	;ConsoleWrite("bShouldVco = " & $bShouldVco & ", FindString VIDEO COMPONENT = " & $iStringInFile & @CRLF)
	If ($bShouldVco And Not $iStringInFile) Or _
			($iStringInFile And Not $bShouldVco) Then
		$bPass = False
		GUICtrlSetData($hTestSummary, " - Failed " & $sTestType & @CRLF)
	Else
		GUICtrlSetData($hTestSummary, " - Passed " & $sTestType & @CRLF)
	EndIf
	Return $bPass
EndFunc   ;==>RunAndTestForVideoStart


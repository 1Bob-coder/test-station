; Purpose:  To run the VCO tests.

#include-once
#include <RegTstUtil.au3>

; Purpose:  Entry point to VCO tests.
; This tests the following
; 3	DSR SI&T.System Control.VCO regress & DVR:001-001	Start and stop verification
; 3	DSR SI&T.System Control.VCO regress & DVR:001-002	Alternate tuner verification
; 3	DSR SI&T.System Control.VCO regress & DVR:001-003	Verification of preamble conditionals: circle
; 3	DSR SI&T.System Control.VCO regress & DVR:001-010	Immediate activation and conflicting overrides
; 3	DSR SI&T.System Control.VCO regress & DVR:001-014	Trick play within VCO LOD use case
; 3	DSR SI&T.System Control.VCO regress & DVR:001-015	Trick play across VCO show end boundary use case

Func RunVCOTest($TestSummary, $VCO_pf)
	Local $bPass = True
	Local $sVctId = GetDiagData("A,5,3", "VCT_ID")

	CollectSerialLogs("VcoSerial", False)    ; Start collection of serial log file (just in case it reboots)
	GUICtrlSetData($TestSummary, "==> VCO Test Started")
	PF_Box("Running", $COLOR_BLUE, $VCO_pf)

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")

	Local $sFrom, $sTo        ; From channel and to channel
	Local $aVcoCmd[1] = ["wait:1000; diag:A"]

	If $sVctId = "4380" Then
		; VCO 55 seconds from 121 to 224 --> SourceID=fd6a (64,874), Transponder=2, ServiceNum=555 (VCT_ID 4380)
		; Channel change to channel 121
		$sFrom = 121
		;$sTo = 224
		$sTo = 252
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")
		;_ArrayAdd($aVcoCmd, "wait:6000; vco:35,121,64874,2,555")
		_ArrayAdd($aVcoCmd, "wait:6000; vco:35,121,64820,2,863")  	; Override 121 with channel 252
		_ArrayAdd($aVcoCmd, "wait:10000; sea:all")					; Add a 10 second wait to collect log data.
	ElseIf $sVctId = "4188" Then
		; VCO for 35 seconds on channel 66, override with chan 166.
		; For channel 166 --> Source_ID=64869 (fd65), Transponder=2, ServiceNum=788 (VCT_ID 4188)
		$sFrom = 66
		$sTo = 166
		ChanChangeDrip("rmt:DIGIT0", "rmt:DIGIT6", "rmt:DIGIT6")
		_ArrayAdd($aVcoCmd, "wait:6000; vco:35,66,64869,2,788")		; VCO command, 35 seconds, override channel 66 with 166.
		_ArrayAdd($aVcoCmd, "wait:10000; sea:all")					; Add a 10 second wait to collect log data.
	Else
		GUICtrlSetData($TestSummary, "VCT_ID is " & $sVctId & ", Need either 4188 or 4380 to run test." & @CRLF)
		GUICtrlSetData($TestSummary, "<== VCO Test Done")
		PF_Box("Skipped", $COLOR_GREEN, $VCO_pf)
		Return
	EndIf

	; Send the VCO command and examine the log file for audio/video start indicating success.
	MakeCmdDrip($aVcoCmd)                    ; Make cmd.drip file to be run with Drip.
	GUICtrlSetColor($VCO_pf, $COLOR_GREEN)
	; Now run cmd.drip and search for the indicated debug string.  This will tell if it VCO'd.
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS, CH: " & $sTo, "VCO Start(video CH " & $sTo & ")", $TestSummary, $VCO_pf) And $bPass
	; And search for the "audio" string as well.
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS, CH: " & $sTo, "VCO Start (audio CH " & $sTo & ")", $TestSummary, $VCO_pf) And $bPass

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
	WinKill("COM")    ; End collection of serial log file

	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $VCO_pf)
	Else
		PF_Box("Fail", $COLOR_Red, $VCO_pf)
	EndIf
EndFunc   ;==>RunVCOTest




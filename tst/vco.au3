; Purpose:  To run the VCO tests.

#include-once
#include <RegTstUtil.au3>


Func RunVCOTest($TestSummary, $VCO_pf)
	Local $bPass = True
	CollectSerialLogs("VcoSerial")    ; Start collection of serial log file (just in case it reboots)
	GUICtrlSetData($TestSummary, "VCO Test Started")
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
		$sTo = 224
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")
		_ArrayAdd($aVcoCmd, "wait:6000; vco:55,121,64874,2,555")
		_ArrayAdd($aVcoCmd, "wait:6000; sea:all")
	Else
		; VCO for 55 seconds on channel 66, override with chan 166.
		; For channel 166 --> Source_ID=64869 (fd65), Transponder=2, ServiceNum=788 (VCT_ID 4188)
		$sFrom = 66
		$sTo = 166
		ChanChangeDrip("rmt:DIGIT0", "rmt:DIGIT6", "rmt:DIGIT6")
		_ArrayAdd($aVcoCmd, "wait:6000; vco:55,66,64869,2,788")
		_ArrayAdd($aVcoCmd, "wait:6000; sea:all")
	EndIf

	MakeCmdDrip($aVcoCmd)                    ; Make cmd.drip file to be run with Drip.
	GUICtrlSetColor($VCO_pf, $COLOR_GREEN)
	; Now run cmd.drip and search for the indicated debug string.  This will tell if it VCO'd.
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS, CH: " & $sTo, "VCO Start(video CH " & $sTo & ")", $TestSummary, $VCO_pf) And $bPass
	; And search for the "audio" string as well.
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS, CH: " & $sTo, "VCO Start (audio CH " & $sTo & ")", $TestSummary, $VCO_pf) And $bPass
	MakeRmtCmdDrip("rmt:EXIT", 10000)
	GUICtrlSetData($TestSummary, "Send EXIT" & @CRLF)
	RunDripTest("cmd")
	; Now do some trick plays.
	MakeRmtCmdDrip("rmt:REWIND", 4000)
	GUICtrlSetData($TestSummary, "Send REWIND" & @CRLF)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO RW", $TestSummary, $VCO_pf) And $bPass
	MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
	GUICtrlSetData($TestSummary, "Send FAST_FWD" & @CRLF)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO FF", $TestSummary, $VCO_pf) And $bPass
	MakeRmtCmdDrip("rmt:PLAY", 2000)
	GUICtrlSetData($TestSummary, "Send PLAY" & @CRLF)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Play (video)", $TestSummary, $VCO_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "VCO Play (audio)", $TestSummary, $VCO_pf) And $bPass
	MakeRmtCmdDrip("rmt:STOP", 2000)
	GUICtrlSetData($TestSummary, "Send STOP" & @CRLF)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Stop (video)", $TestSummary, $VCO_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "VCO Stop (audio)", $TestSummary, $VCO_pf) And $bPass
	GUICtrlSetData($TestSummary, "Wait 20 seconds for VCO to end." & @CRLF)
	MakeRmtCmdDrip("rmt:PLAY", 20000)  ; Wait 20 seconds for VCO to end
	GUICtrlSetData($TestSummary, "Send PLAY." & @CRLF)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS, CH: " & $sFrom, "VCO Return (video CH " & $sFrom & ")", $TestSummary, $VCO_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS, CH: " & $sFrom, "VCO Return (audio CH " & $sFrom & ")", $TestSummary, $VCO_pf) And $bPass

	GUICtrlSetData($TestSummary, "VCO Test Done")
	Sleep(10000)  ; Sleep 10 seconds just in case it crashes.
	WinKill("COM")    ; End collection of serial log file

	If $bPass Then
		PF_Box("Passed", $COLOR_GREEN, $VCO_pf)
	Else
		PF_Box("Failed", $COLOR_Red, $VCO_pf)
	EndIf
EndFunc   ;==>RunVCOTest




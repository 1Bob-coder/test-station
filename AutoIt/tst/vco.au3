; Purpose:  To run the VCO tests.

#include-once
#include <RegTstUtil.au3>


Func RunVCOTest($TestSummary, $VCO_pf)
	Local $bPassFail = True
	CollectSerialLogs("VcoSerial")    ; Start collection of serial log file

	PF_Box("Running", $COLOR_BLUE, $VCO_pf)
	GUICtrlSetColor($VCO_pf, $COLOR_GREEN)
	GUICtrlSetData($TestSummary, "VCO Test Started")
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")        ; EXIT key twice to get out of any GUI screens

	; Perform VCO for 55 seconds on channel 66, override with chan 166.
	; For channel 166 --> Source_ID=64869 (fd65), Transponder=2, ServiceNum=788
	Local $aVcoCmd[6] = ["wait:1000; diag:A", _                     ; VCO command needs Diag A to be run first
			"wait:1000; rmt:DIGIT0", _                                ; Channel change to channel 66
			"wait:500; rmt:DIGIT6", _
			"wait:500; rmt:DIGIT6", _
			"wait:6000; vco:55,66,64869,2,788", _                     ; Send vco command
			"wait:6000; sea:all"]                                    ; wait 6 seconds
	MakeCmdDrip($aVcoCmd)                    ; Make cmd.drip file to be run with Drip.
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS, CH: 166", "VCO Start(video CH 166)", $TestSummary, $VCO_pf) And $bPassFail
	$bPassFail = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS, CH: 166", "VCO Start (audio CH 166)", $TestSummary, $VCO_pf) And $bPassFail
	MakeRmtCmdDrip("rmt:EXIT", 10000)
	GUICtrlSetData($TestSummary, "Send EXIT" & @CRLF)
	RunDripTest("cmd")
	MakeRmtCmdDrip("rmt:REWIND", 4000)
	GUICtrlSetData($TestSummary, "Send REWIND" & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO RW", $TestSummary, $VCO_pf) And $bPassFail
	MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
	GUICtrlSetData($TestSummary, "Send FAST_FWD" & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO FF", $TestSummary, $VCO_pf) And $bPassFail
	MakeRmtCmdDrip("rmt:PLAY", 2000)
	GUICtrlSetData($TestSummary, "Send PLAY" & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Play (video)", $TestSummary, $VCO_pf) And $bPassFail
	$bPassFail = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "VCO Play (audio)", $TestSummary, $VCO_pf) And $bPassFail
	MakeRmtCmdDrip("rmt:STOP", 2000)
	GUICtrlSetData($TestSummary, "Send STOP" & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Stop (video)", $TestSummary, $VCO_pf) And $bPassFail
	$bPassFail = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "VCO Stop (audio)", $TestSummary, $VCO_pf) And $bPassFail
	GUICtrlSetData($TestSummary, "Wait 20 seconds for VCO to end." & @CRLF)
	MakeRmtCmdDrip("rmt:PLAY", 20000)  ; Wait 20 seconds for VCO to end
	GUICtrlSetData($TestSummary, "Send PLAY." & @CRLF)
	$bPassFail = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS, CH: 66", "VCO Return (video CH 66)", $TestSummary, $VCO_pf) And $bPassFail
	$bPassFail = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS, CH: 66", "VCO Return (audio CH 66)", $TestSummary, $VCO_pf) And $bPassFail

	GUICtrlSetData($TestSummary, "VCO Test Done")
	WinKill("COM")    ; End collection of serial log file

	If $bPassFail Then
		PF_Box("Passed", $COLOR_GREEN, $VCO_pf)
	Else
		PF_Box("Failed", $COLOR_Red, $VCO_pf)
	EndIf
EndFunc   ;==>RunVCOTest



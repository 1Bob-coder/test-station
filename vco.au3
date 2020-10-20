; Purpose:  To run the VCO tests.

#include-once
#include <RegTstUtil.au3>


Func RunVCOTest($TestSummary, $VCO_pf)
	PF_Box("Running", $COLOR_BLUE, $VCO_pf)
	GUICtrlSetColor($VCO_pf, $COLOR_GREEN)
	; Perform VCO for 30 seconds on channel 66, override with chan 166.
	; For channel 166 --> Source_ID=64869 (fd65), Transponder=2, ServiceNum=788
	Local $aVcoCmd[6] = ["wait:1000; diag:A", _                     ; VCO command needs Diag A to be run first
			"wait:1000; rmt:DIGIT0", _                                ; Channel change to channel 66
			"wait:500; rmt:DIGIT6", _
			"wait:500; rmt:DIGIT6", _
			"wait:6000; vco:30,66,64869,2,788", _                     ; Send vco command
			"wait:10000; sea:all"]                                    ; wait 10 seconds
	MakeCmdDrip($aVcoCmd)                    ; Make cmd.drip file to be run with Drip.
	RunTestCriteria("cmd", "SEND LIVE PMT_CHANGED_EVENT (SVC NUM  = 788, CHANNEL = 166)", "VCO (start)", $TestSummary, $VCO_pf)
	MakeRmtCmdDrip("rmt:REWIND", 3000)
	RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO (RW)", $TestSummary, $VCO_pf)
	MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
	RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO (FF)", $TestSummary, $VCO_pf)
	MakeRmtCmdDrip("rmt:PLAY", 2000)
	If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Play (video)", $TestSummary, $VCO_pf) Then
		TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "VCO Play (audio)", $TestSummary, $VCO_pf)
	EndIf
	MakeRmtCmdDrip("rmt:STOP", 2000)
	If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "VCO Stop (video)", $TestSummary, $VCO_pf) Then
		TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "VCO Stop (audio)", $TestSummary, $VCO_pf)
	EndIf
	GUICtrlSetData($TestSummary, "VCO Test Done")
	PF_Box("Done", $COLOR_BLUE, $VCO_pf)
EndFunc   ;==>RunVCOTest



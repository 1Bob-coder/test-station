; Purpose:  To run the DVR and Trick Play tests.

#include-once
#include <RegTstUtil.au3>


Func RunDVRTest($TestSummary, $DVR_pf)
	PF_Box("Running", $COLOR_BLUE, $DVR_pf)
	MakeRmtCmdDrip("rmt:REWIND", 3000)
	RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", @CRLF & "Trick RW", $TestSummary, $DVR_pf)
	MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
	RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick FF", $TestSummary, $DVR_pf)
	MakeRmtCmdDrip("rmt:PLAY", 2000)
	If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick Play (video)", $TestSummary, $DVR_pf) Then
		TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "Trick Play (audio)", $TestSummary, $DVR_pf)
	EndIf
	MakeRmtCmdDrip("rmt:STOP", 2000)
	If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick Stop (video)", $TestSummary, $DVR_pf) Then
		TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", "Trick Stop (audio)", $TestSummary, $DVR_pf)
	EndIf
	MakeRmtCmdDrip("rmt:REWIND", 5000)
	RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick RW", $TestSummary, $DVR_pf)
	MakeRmtCmdDrip("rmt:PLAY", 2000)
	If RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", " Trick Play (video)", $TestSummary, $DVR_pf) Then
		TestForString("SEND AUDIO_COMPONENT_START_SUCCESS", "cmd", " Trick Play (audio)", $TestSummary, $DVR_pf)
	EndIf
	GUICtrlSetData($TestSummary, "DVR Test Done")
	PF_Box("Done", $COLOR_BLUE, $DVR_pf)

EndFunc   ;==>RunDVRTest



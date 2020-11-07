; Purpose:  To run the DVR and Trick Play tests.

#include-once
#include <RegTstUtil.au3>


Func RunDVRTest($TestSummary, $DVR_pf)
	Local $bPass = True
	CollectSerialLogs("DvrSerial")    ; Start collection of serial log file (just in case it reboots)
	GUICtrlSetData($TestSummary, "DVR Test Started")
	PF_Box("Running", $COLOR_BLUE, $DVR_pf)

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")

	If $sVctId = "4380" Then        ; Use channel 121 - This channel is 1080i.
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")
	EndIf

	Sleep(10000)          ; Wait 10 seconds before starting the Rewind test
	MakeRmtCmdDrip("rmt:REWIND", 3000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", @CRLF & "Trick RW", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick FF", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:PLAY", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick Play (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "Trick Play (audio)", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:STOP", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick Stop (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "Trick Stop (audio)", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:REWIND", 5000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "Trick RW", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:PLAY", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", " Trick Play (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", " Trick Play (audio)", $TestSummary, $DVR_pf) And $bPass

	GUICtrlSetData($TestSummary, "DVR Test Done")
	Sleep(10000)  ; Sleep for 10 seconds before ending collection of the serial logs.
	WinKill("COM")        ; End collection of serial log file

	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $DVR_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $DVR_pf)
	EndIf

EndFunc   ;==>RunDVRTest



; Purpose:  To run the DVR and Trick Play tests.

#include-once
#include <RegTstUtil.au3>


Func RunDVRTest($TestSummary, $DVR_pf)
	Local $bPass = True
	CollectSerialLogs("DvrSerial")    ; Start collection of serial log file (just in case it reboots)
	GUICtrlSetData($TestSummary, "==> DVR Test Started")
	PF_Box("Running", $COLOR_BLUE, $DVR_pf)

	; Turn on Video/Info debugs, "sea all", "ses 3"
	Local $aDebugs[] = [ _
			"wait:1000; sea:all", _
			"wait:1000; ses:3"]
	MakeCmdDrip($aDebugs)
	RunDripTest("cmd")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")

	If $sVctId = "4380" Then        ; Use channel 121
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")
	EndIf

	;Sleep(10000)          ; Wait 10 seconds before starting the Rewind test
	MakeRmtCmdDrip("rmt:REWIND", 3000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", @CRLF & "1. RW", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "2. FF", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:PLAY", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "3. Play (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "3. Play (audio)", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:STOP", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "4. Stop (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "4. Stop (audio)", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:REWIND", 5000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "5. RW", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:PLAY", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "6. Play (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "6. Play (audio)", $TestSummary, $DVR_pf) And $bPass

	GUICtrlSetData($TestSummary, "<== DVR Test Done")
	WinKill("COM")        ; End collection of serial log file

	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $DVR_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $DVR_pf)
	EndIf

EndFunc   ;==>RunDVRTest



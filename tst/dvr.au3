; Purpose:  To run the DVR and Trick Play tests.

#include-once
#include <RegTstUtil.au3>


Func RunDVRTest($TestSummary, $DVR_pf)
	Local $bPass = True
	CollectSerialLogs("DvrSerial", False)    ; Start collection of serial log file (just in case it reboots)
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

	Sleep(20000)          ; Wait 20 seconds before starting the LOD test
	$bPass = RunTrickPlays($TestSummary, $DVR_pf, "LOD: ") And $bPass

	; The Dual DVR Test records two shows at the same time and test for:
	; - LOD trick play during dual record
	; - Trick Play on playback of recording.
	$bPass = RunDualDvrTest($TestSummary, $DVR_pf) And $bPass

	GUICtrlSetData($TestSummary, "<== DVR Test Done")

	WinKill("COM")        ; End collection of serial log file

	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $DVR_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $DVR_pf)
	EndIf

EndFunc   ;==>RunDVRTest



;Purpose: Test RW, FF, PLAY, and STOP
Func RunTrickPlays($TestSummary, $DVR_pf, $sTest)
	MakeRmtCmdDrip("rmt:REWIND", 3000)
	Local $bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", @CRLF & "1. " & $sTest & "RW", $TestSummary, $DVR_pf)

	MakeRmtCmdDrip("rmt:FAST_FWD", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "2. " & $sTest & "FF", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:PLAY", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "3. " & $sTest & "Play (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "3. " & $sTest & "Play (audio)", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:STOP", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "4. " & $sTest & "Stop (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "4. " & $sTest & "Stop (audio)", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:EXIT", 2000)
	RunDripTest("cmd")

	MakeRmtCmdDrip("rmt:REWIND", 5000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "5. " & $sTest & "RW", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:PLAY", 2000)
	$bPass = RunTestCriteria("cmd", "SEND VIDEO_COMPONENT_START_SUCCESS", "6. " & $sTest & "Play (video)", $TestSummary, $DVR_pf) And $bPass
	$bPass = TestForString("cmd", "SEND AUDIO_COMPONENT_START_SUCCESS", "6. " & $sTest & "Play (audio)", $TestSummary, $DVR_pf) And $bPass

	MakeRmtCmdDrip("rmt:STOP", 2000)
	RunDripTest("cmd")

	MakeRmtCmdDrip("rmt:EXIT", 2000)
	RunDripTest("cmd")

	Return $bPass
EndFunc   ;==>RunTrickPlays


; Purpose:  Record two shows at the same time and make sure both play back.
Func RunDualDvrTest($TestSummary, $DVR_pf)
	GUICtrlSetData($TestSummary, "Run Dual Record Test")

	If $sVctId = "4380" Then            ; Use channel 121
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")
	EndIf

	GUICtrlSetData($TestSummary, "Record the current program, RECORD, RIGHT, ENTER" & @CRLF)
	Local $aStartRecord[] = [ _
			"wait:1000; rmt:STOP", _
			"wait:5000; rmt:RECORD", _
			"wait:3000; rmt:ARROW_RIGHT", _
			"wait:1000; rmt:ENTER"]
	MakeCmdDrip($aStartRecord)
	RunDripTest("cmd")

	If $sVctId = "4380" Then            ; Use channel 131
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT3", "rmt:DIGIT1")
	Else
		MakeRmtCmdDrip("rmt:CHAN_UP", 1000)
		RunDripTest("cmd")
	EndIf

	GUICtrlSetData($TestSummary, "Record another program, RECORD, RIGHT, ENTER" & @CRLF)
	Local $aStartRecord[] = [ _
			"wait:1000; rmt:STOP", _
			"wait:5000; rmt:RECORD", _
			"wait:3000; rmt:ARROW_RIGHT", _
			"wait:1000; rmt:ENTER"]
	MakeCmdDrip($aStartRecord)
	RunDripTest("cmd")

	Sleep(30000)        ; Wait 30 seconds.

	; Run trick plays - Tests LOD with dual recordings
	Local $bPass = RunTrickPlays($TestSummary, $DVR_pf, "LOD w/ dual rec: ")

	; Stop both recordings.
	GUICtrlSetData($TestSummary, "Stop both recordings" & @CRLF)
	Local $aStopRecord[] = [ _
			"wait:4000; rmt:INTERACTIVE", _
			"wait:2000; rmt:ARROW_RIGHT", _
			"wait:2000; rmt;ENTER", _
			"wait:2000; rmt:ARROW_RIGHT", _
			"wait:2000; rmt;ENTER", _
			"wait:2000; rmt;ENTER", _
			"wait:2000; rmt;ARROW_DOWN", _
			"wait:2000; rmt;ENTER", _
			"wait:1000; rmt;EXIT"]
	MakeCmdDrip($aStopRecord)
	RunDripTest("cmd")
	RunDripTest("cmd")

	; Play back last recording.
	Local $aPlayback[] = [ _
			"wait:4000; rmt:LIST", _
			"wait:4000; rmt;ENTER", _
			"wait:2000; rmt;ENTER", _
			"wait:3000; rmt;EXIT"]
	MakeCmdDrip($aPlayback)
	RunDripTest("cmd")

	; Run trick plays on it.
	Sleep(20000)    ; Wait 20 seconds
	$bPass = RunTrickPlays($TestSummary, $DVR_pf, "DVR Playback: ") And $bPass
	Return $bPass
EndFunc   ;==>RunDualDvrTest


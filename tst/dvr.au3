; Purpose:  To run the DVR and Trick Play tests.

#include-once
#include <RegTstUtil.au3>

$bHasExternalHD = True


Func RunDVRTest($TestSummary, $DVR_pf)
	Local $bPass = True
	GUICtrlSetData($TestSummary, "==> DVR Test Started")
	PF_Box("Running", $COLOR_BLUE, $DVR_pf)

	If $sBoxType = "DSR800" Then
		GUICtrlSetData($TestSummary, "BoxType is DSR800.  No tests run." & @CRLF)
		GUICtrlSetData($TestSummary, "<== DVR Test Done")
		PF_Box("NA", $COLOR_BLUE, $DVR_pf)
		Return
	EndIf

	Local $aHDs = GetHDs()
	$iArraySize = UBound($aHDs)
	GUICtrlSetData($TestSummary, "Number of HDs = " & $iArraySize - 1 & @CRLF)
	If $iArraySize > 2 Then
		$bHasExternalHD = True
	Else
		$bHasExternalHD = False
	EndIf

	For $i = 1 To $iArraySize - 1
		GUICtrlSetData($TestSummary, "HD = " & $aHDs[$i] & @CRLF)
	Next

	CollectSerialLogs("DvrSerial", False)    ; Start collection of serial log file (just in case it reboots)

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

	WinKill("COM" & $sComPort)                            ; End collection of serial log file

	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $DVR_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $DVR_pf)
	EndIf

EndFunc   ;==>RunDVRTest



;Purpose: Test RW, FF, PLAY, and STOP
; This tests the following:
; 3	DSR SI&T.DVR.DVR Response Time:001-001	DVR Playback Response Time
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
	SavePassFailTestResult("DSR SI&T.DVR.DVR Response Time:001-001", $bPass)

	Return $bPass
EndFunc   ;==>RunTrickPlays


; Purpose:  Record two shows at the same time and make sure both play back.
; This tests the following cases:
; 3	DSR SI&T.DVR.Dual Record Feature:001-001	Independent AV Stream
; 3	DSR SI&T.DVR.Dual Record Feature:001-002	Associated AV stream
; 3	DSR SI&T.DVR.Dual Record Feature:001-003	Watch video from tuner
; 1	DSR SI&T.DVR.Legacy DVR:001-001	Simple background record
; 3	DSR SI&T.DVR.Legacy DVR:001-002	Watch while recording a different service
; 2	DSR SI&T.DVR.Legacy DVR:001-003	Watch while recording the same service
; 3	DSR SI&T.DVR.Legacy DVR:001-004	Dual record
; 3	DSR SI&T.DVR.Legacy DVR:001-006	Record Service while playing back a different recording
; 3	DSR SI&T.DVR.Legacy DVR:001-007	Record Service while playing back the same service
; 3	DSR SI&T.DVR.Legacy DVR:001-008	"Watch Service 1 With Trick Play, Record Service 2"
; 3	DSR SI&T.DVR.Legacy DVR:003-004	MPEG4 LOD check
; 1	DSR SI&T.DVR.MPEG4:001-001	Simple background record & playback
; 3	DSR SI&T.DVR.MPEG4:001-002	Watch while recording a different service
; 3	DSR SI&T.DVR.MPEG4:001-004	Dual record
; 3	DSR SI&T.DVR.MPEG4:001-006	Record Service while playing back a different recording
; 3	DSR SI&T.DVR.MPEG4:001-007	Record Service while playing back the same service
; 3	DSR SI&T.DVR.MPEG4:001-008	"Watch Service 1 With Trick Play, Record Service 2"
; 3	DSR SI&T.DVR.MPEG4:001-009	LOD operation
; For External Hard Drive, the following are tested:
; 3 DSR SI&T.DVR.eMSD:001-001 eMSD formatted on a different Integrated Receiver/Decoder (IRD);
; 3 DSR SI&T.DVR.eMSD:001-002 use case 1: Drive pre-formatted on different IRD does not impair iMSD recording;
; 3 DSR SI&T.DVR.eMSD:001-003 use case 2: interchanging a pre-formatted drive;
; 3 DSR SI&T.DVR.eMSD:002-001 New HDD discovery and format;
; 3 DSR SI&T.DVR.eMSD:002-003 Factory reset reformat;
; 3 DSR SI&T.DVR.eMSD:002-004 eMSD serial number display;
; 3 DSR SI&T.DVR.eMSD:005-001 Dual recording;
; 3 DSR SI&T.DVR.eMSD:005-002 eMSD Playback and record;
; 3 DSR SI&T.DVR.eMSD:005-003 iMSD Playback and record;
; 2 DSR SI&T.DVR.eMSD:005-004 Dual record with eMSD playback;
; 3 DSR SI&T.DVR.eMSD:005-005 Dual record with iMSD playback;
; 2 DSR SI&T.DVR.eMSD:007-005 LOD trickplay;
; 3 DSR SI&T.DVR.eMSD:007-006 LOD record;
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
	Sleep(20000)     ; Wait 20 seconds
	$bPass = RunTrickPlays($TestSummary, $DVR_pf, "DVR Playback: ") And $bPass

	SavePassFailTestResult("DSR SI&T.DVR.Dual Record Feature:001-001", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Dual Record Feature:001-002", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Dual Record Feature:001-003", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Legacy DVR:001-001", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Legacy DVR:001-002", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Legacy DVR:001-003", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Legacy DVR:001-004", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Legacy DVR:001-006", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Legacy DVR:001-007", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Legacy DVR:001-008", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.Legacy DVR:003-004", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.MPEG4:001-001", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.MPEG4:001-002", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.MPEG4:001-004", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.MPEG4:001-006", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.MPEG4:001-007", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.MPEG4:001-008", $bPass)
	SavePassFailTestResult("DSR SI&T.DVR.MPEG4:001-009", $bPass)

	If $bHasExternalHD Then
		SavePassFailTestResult("DSR SI&T.DVR.eMSD:005-001", $bPass)
		SavePassFailTestResult("DSR SI&T.DVR.eMSD:005-002", $bPass)
		SavePassFailTestResult("DSR SI&T.DVR.eMSD:005-004", $bPass)
		SavePassFailTestResult("DSR SI&T.DVR.eMSD:007-005", $bPass)
		SavePassFailTestResult("DSR SI&T.DVR.eMSD:007-006", $bPass)
	Else
		SavePassFailTestResult("DSR SI&T.DVR.eMSD:005-003", $bPass)
		SavePassFailTestResult("DSR SI&T.DVR.eMSD:005-005", $bPass)
	EndIf

	Return $bPass
EndFunc   ;==>RunDualDvrTest



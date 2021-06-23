; Purpose:  To run the Closed Captions tests.

#include-once
#include <RegTstUtil.au3>


; Purpose:  To test closed captioning processing.
; Note:  This only tests if closed captions are being processed.
;        It does not test on-screen visual rendering or characters that are incorrect.
; First, test if cc is enabled.  Then turn on if needed.
; Finally, get counter data from two different timeperiods and compare them.
; $hTestSummary - place to print the test summary
; $hClosedCaptions_pf - place to print pass/fail
; Test Matrix Requirement:
; 3	DSR SI&T.Closed Caption.DVR:001-001	"Reconstruct L21, F1 & F2 of the VBI during playback of Retained content (LOD) at Normal Speed."
; 3	DSR SI&T.Closed Caption.DVR:002-001	Render closed captions during playback of Retained content at Normal Speed.
; 3	DSR SI&T.Closed Caption.DVR:004-001	"Render closed captions during playback of Recorded content, at Normal Speed."
Func RunClosedCaptionTest($TestSummary, $ClosedCaptions_pf)
	PF_Box("Running...", $COLOR_BLUE, $ClosedCaptions_pf)
	DisplayLineOfText($TestSummary, "Closed Captions Test Started")
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")        ; EXIT key twice to get out of any GUI screens
	ChanChange($sHdChan)

	TurnCaptionsOn()

	; Do the Live test
	Local $bPass = CcCounterTest("Live test", $TestSummary)
	; Do the LOD test
	MakeRmtCmdDrip("rmt:SKIP_BACK", 1000)
	RunDripTest("cmd")
	Local $bPassFail = CcCounterTest("LOD test", $TestSummary)
	$bPass = $bPass And $bPassFail

	; Do the Playback test.  Record the current program.
	; Press RECORD, RIGHT_ARROW, ENTER, wait 10 seconds, then stop the recording.
	DisplayLineOfText($TestSummary, "cc - Record the current program, RECORD, RIGHT, ENTER")
	Local $aStartRecord[] = [ _
			"wait:1000; rmt:STOP", _
			"wait:5000; rmt:RECORD", _
			"wait:3000; rmt:ARROW_RIGHT", _
			"wait:1000; rmt:ENTER"]
	MakeCmdDrip($aStartRecord)
	RunDripTest("cmd")
	Sleep(10000)

	; Stop the recording.
	DisplayLineOfText($TestSummary, "cc - Stop recording. INTERACTIVE, R E R E E DOWN E EXIT")

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

	; Play back the recording from the PVR list
	Local $aPlayback[] = [ _
			"wait:4000; rmt:LIST", _
			"wait:4000; rmt;ENTER", _
			"wait:2000; rmt;ENTER"]
	MakeCmdDrip($aPlayback)
	RunDripTest("cmd")
	$bPassFail = CcCounterTest("Playback test", $TestSummary)
	SavePassFailTestResult("DSR SI&T.Closed Caption.DVR:002-001", $bPass)
	$bPass = $bPass And $bPassFail

	; Stop the playback
	Local $aStopPlayback[] = [ _
			"wait:2000; rmt:STOP", _
			"wait:2000; rmt;EXIT"]
	MakeCmdDrip($aStopPlayback)
	RunDripTest("cmd")

	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $ClosedCaptions_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $ClosedCaptions_pf)
	EndIf

	DisplayLineOfText($TestSummary, "Closed Captions Test Done")
EndFunc   ;==>RunClosedCaptionTest

; Purpose:  Turns on Closed Captions.
Func TurnCaptionsOn()
	; Run the cc stats command to check if captions are on or off.
	MakeAstTtl("ast cc", 10)      ; make the 'ast cc' command, 10 second timeout
	RunAstTtl()                   ; run the 'ast cc' command and collect the log
	If FindStringInFile("Captions are off", "ast") Then
		ConsoleWrite("Captions are off, need to turn on" & @CRLF)
		Local $aHelpC[2] = ["wait:1000; rmt:HELP", _     ; HELP C to toggle captions on
				"wait:1000; rmt:YELLOW"]
		MakeCmdDrip($aHelpC)    ; Make cmd.drip file to be run with Drip.
		RunDripTest("cmd")
	Else
		ConsoleWrite("Captions are on" & @CRLF)
	EndIf
EndFunc   ;==>TurnCaptionsOn


; Purpose:  Tests to see if the closed captions counter is incrementing.
; This is the indicator that closed captions are being processed by Nexus.
Func CcCounterTest($sTestName, $TestSummary)
	Local $bPass = False

	MakeAstTtl("ast cc", 10)    ; make the 'ast cc' command, 10 second timeout
	RunAstTtl()                 ; Run TeraTerm with the 'ast cc' command and collect the log data

	Local $sCcCounter1 = FindNextStringInFile("CC counter =", "ast")    ; Get the 'CC counter' value
	ConsoleWrite("Counter1 = " & $sCcCounter1 & @CRLF)

	Sleep(5000)              ; sleep for 5 seconds
	RunAstTtl()              ; Run TeraTerm with the 'ast cc' command and collect the log data

	Local $sCcCounter2 = FindNextStringInFile("CC counter =", "ast")    ; Get the 'CC counter' value
	ConsoleWrite("Counter2 = " & $sCcCounter2 & @CRLF)
	If $sCcCounter1 <> $sCcCounter2 Then
		; Counter changed. Test passed.
		$bPass = True
		DisplayLineOfText($TestSummary, $sTestName & ": Passed")
		;_ArrayAdd($aTestResults, "Closed Caption.608_708:001-001|Passed|Render CEA708 CC on its NTSC output, SCTE21 Syntax, 608 CC_type 00 and 708 CC_type 11")
	Else
		DisplayLineOfText($TestSummary, $sTestName & ": Failed.  Check if captions are on this channel")
		;_ArrayAdd($aTestResults, "001-001|Closed Caption.608_708:001-001|Failed|Render CEA708 CC on its NTSC output, SCTE21 Syntax, 608 CC_type 00 and 708 CC_type 11")
	EndIf
	Return $bPass
EndFunc   ;==>CcCounterTest

; Purpose:  To run the Closed Captions tests.

#include-once
#include <RegTstUtil.au3>


; Purpose:  To test closed captioning processing.
; Note:  This only tests if closed captions are being processed.
;        It does not test on-screen visual rendering or characters that are incorrect.
; First, test if cc is enabled.  Then turn on if needed.
; Finally, get counter data from two different timeperiods and compare them.
Func RunClosedCaptionTest($TestSummary, $ClosedCaptions_pf)
	PF_Box("Running...", $COLOR_BLUE, $ClosedCaptions_pf)
	GUICtrlSetData($TestSummary, "Closed Captions Test Started")

	Local $sCcCounter1 = ""
	Local $sCcCounter2 = ""
	; Run the cc stats command to check if captions are on or off.
	MakeAstTtl("ast cc", 10)                            ; make the 'ast cc' command
	RunAstTtl()                                         ; run the 'ast cc' command and collect the log
	If FindStringInFile("Captions are off", "ast") Then
		ConsoleWrite("Captions are off, need to turn on" & @CRLF)
		Local $aHelpC[2] = ["wait:1000; rmt:HELP", _     ; HELP C to toggle captions on
				"wait:1000; rmt:YELLOW"]
		MakeCmdDrip($aHelpC)    ; Make cmd.drip file to be run with Drip.
		RunDripTest("cmd")
		RunAstTtl()             ; Run TeraTerm with the 'ast cc' command and collect the log data
	Else
		ConsoleWrite("Captions are on" & @CRLF)
	EndIf

	$sCcCounter1 = FindNextStringInFile("CC counter =", "ast")    ; Get the 'CC counter' value
	ConsoleWrite("Counter1 = " & $sCcCounter1 & @CRLF)

	Sleep(5000)                     ; sleep for 5 seconds

	; Run the same 'cc stats' command again to see if the value incremented.
	RunAstTtl()

	$sCcCounter2 = FindNextStringInFile("CC counter =", "ast")
	ConsoleWrite("Counter2 = " & $sCcCounter2 & @CRLF)
	If $sCcCounter1 <> $sCcCounter2 Then
		; Counter changed. Test passed.
		GUICtrlSetData($TestSummary, "cc: Passed")
		PF_Box("Pass", $COLOR_GREEN, $ClosedCaptions_pf)
		;_ArrayAdd($aTestResults, "Closed Caption.608_708:001-001|Passed|Render CEA708 CC on its NTSC output, SCTE21 Syntax, 608 CC_type 00 and 708 CC_type 11")
	Else
		GUICtrlSetData($TestSummary, "cc: Failed.  Check if captions are on this channel")
		PF_Box("Fail", $COLOR_RED, $ClosedCaptions_pf)
		;_ArrayAdd($aTestResults, "001-001|Closed Caption.608_708:001-001|Failed|Render CEA708 CC on its NTSC output, SCTE21 Syntax, 608 CC_type 00 and 708 CC_type 11")
	EndIf
	GUICtrlSetData($TestSummary, "Closed Captions Test Done")

EndFunc   ;==>RunClosedCaptionTest

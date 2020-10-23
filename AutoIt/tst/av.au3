; Purpose:  To run the Audio/Video tests.

#include-once
#include <RegTstUtil.au3>


Func RunAVPresentationTest($hTestSummary, $AV_Presentation_pf)
	Local $bPassFail = True
	PF_Box("Running", $COLOR_BLUE, $AV_Presentation_pf)
	GUICtrlSetData($hTestSummary, "AV Test Started")
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")        ; EXIT key twice to get out of any GUI screens

	MakeAstTtl("ast vi", 5)           ; make the 'ast vi' command with 5 second timeout

	; Video Aspect override test, for Normal, Stretch, and Zoom modes
	$bPassFail = RunVideoAspectOverride($hTestSummary) And $bPassFail

	; Test the A/V Settings Screen with all the various settings.
	; Test video output modes
	$bPassFail = RunVideoOutputMode($hTestSummary) And $bPassFail

	If $bPassFail Then
		PF_Box("Pass", $COLOR_GREEN, $AV_Presentation_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $AV_Presentation_pf)
	EndIf
	GUICtrlSetData($hTestSummary, "AV Test Done")
EndFunc   ;==>RunAVPresentationTest


; Purpose:  To cycle through the aspect ratios Zoom/Stretch/Normal
Func RunVideoAspectOverride($hTestSummary)
	Local $aAspect[] = ["wait:1000; rmt:ASPECT", _            ; ASPECT key to toggle Aspect ratio
			"wait:1000; rmt:ASPECT"]                    ; press it twice to toggle it
	MakeCmdDrip($aAspect)        ; Make cmd.drip file to be run with Drip.
	For $count = 1 To 3 Step 1
		RunDripTest("cmd")
		RunAstTtl()          ; run the 'ast vi' command and collect the log
		$sValue = FindNextStringInFile("User Conversion Preference    :", "ast")
		ConsoleWrite("User Conversion Preference " & $sValue & @CRLF)
		GUICtrlSetData($hTestSummary, "User Conversion Preference: " & $sValue & @CRLF)
	Next
	Return (True)
EndFunc   ;==>RunVideoAspectOverride


Func RunVideoOutputMode($hTestSummary)
	$bPassFail = True  ; True for Pass
	; OPTIONS-4-2-DOWN-ENTER
	Local $aAVSettings[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:2000; rmt:OPTIONS", _
			"wait:1000; rmt:DIGIT4", _
			"wait:1000; rmt:DIGIT2", _
			"wait:1000; rmt:ARROW_DOWN"]
	Local $aVid_1080p[] = [ _
			"wait:3000; rmt:SELECT", _
			"wait:3000; rmt:SELECT", _
			"wait:5000; rmt:ARROW_LEFT", _
			"wait:1000; rmt:SELECT"]
	Local $aVid_1080i[] = [ _
			"wait:3000; rmt:SELECT", _
			"wait:2000; rmt:ARROW_DOWN", _
			"wait:3000; rmt:SELECT", _
			"wait:6000; rmt:ARROW_LEFT", _
			"wait:2000; rmt:SELECT"]
	Local $aVid_720p[] = [ _
			"wait:3000; rmt:SELECT", _
			"wait:2000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:2000; rmt:SELECT", _
			"wait:6000; rmt:ARROW_LEFT", _
			"wait:2000; rmt:SELECT"]
	Local $aVid_480p[] = [ _
			"wait:3000; rmt:SELECT", _
			"wait:2000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:2000; rmt:SELECT", _
			"wait:6000; rmt:ARROW_LEFT", _
			"wait:2000; rmt:SELECT"]
	Local $aVid_480i[] = [ _
			"wait:3000; rmt:SELECT", _
			"wait:2000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:2000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:SELECT", _
			"wait:6000; rmt:ARROW_LEFT", _
			"wait:2000; rmt:SELECT"]
	MakeCmdDrip($aAVSettings)
	RunDripTest("cmd")
	RunAstTtl()
	$sValue = FindNextStringInFile("Nexus Display Format          :", "ast")
	If $sValue = "1080P" Then
		$bPassFail = RunVideoOutput($aVid_1080i, "1080I", $hTestSummary) And $bPassFail
	EndIf
	ConsoleWrite("Keep running test" & @CRLF)
	$bPassFail = RunVideoOutput($aVid_1080p, "1080P", $hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutput($aVid_1080i, "1080I", $hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutput($aVid_720p, "720P", $hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutput($aVid_480p, "480P", $hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutput($aVid_480i, "480I", $hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutput($aVid_1080p, "1080P", $hTestSummary) And $bPassFail
	Return ($bPassFail)
EndFunc   ;==>RunVideoOutputMode

; Purpose:  Runs a VideoOutput Test for 1080p, 1080i, etc. and returns a pass/fail result.
Func RunVideoOutput($aDripCmd, $sTestString, $hTestSummary)
	Local $bPassFail = True     ; True for pass
	MakeCmdDrip($aDripCmd)
	RunDripTest("cmd")
	RunAstTtl()
	$sValue = FindNextStringInFile("Nexus Display Format          :", "ast")
	ConsoleWrite("Video Output Display Format: " & $sValue & @CRLF)
	Local $iResult = StringCompare($sValue, $sTestString)
	If $iResult <> 0 Then
		GUICtrlSetData($hTestSummary, "Nexus Display Format: " & $sValue & " - Fail" & @CRLF)
		$bPassFail = False
	Else
		GUICtrlSetData($hTestSummary, "Nexus Display Format: " & $sValue & " - Pass" & @CRLF)
	EndIf
	Return ($bPassFail)
EndFunc   ;==>RunVideoOutput

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

	$bPassFail = RunVideoAspectOverride($hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutputMode($hTestSummary) And $bPassFail

	MakeAstTtl("ast au", 5)           ; make the 'ast au' command with 5 second timeout

	$bPassFail = RunAudioCompression($hTestSummary) And $bPassFail
	$bPassFail = RunHdmiAudio($hTestSummary) And $bPassFail
	$bPassFail = RunAnalogAudio($hTestSummary) And $bPassFail
	$bPassFail = RunOpticalDigitalAudio($hTestSummary) And $bPassFail

	If $bPassFail Then
		PF_Box("Pass", $COLOR_GREEN, $AV_Presentation_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $AV_Presentation_pf)
	EndIf
	GUICtrlSetData($hTestSummary, "AV Test Done" & @CRLF)
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


; Purpose:  Cycle through 1080p, 1080i, 720p, 480p, and 480i output modes.
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
	If $sValue = "1080I" Then
		$bPassFail = RunVideoOutput($aVid_1080p, "1080P", $hTestSummary) And $bPassFail
	EndIf
	$bPassFail = RunVideoOutput($aVid_720p, "720P", $hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutput($aVid_480p, "480P", $hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutput($aVid_480i, "480I", $hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutput($aVid_1080i, "1080I", $hTestSummary) And $bPassFail
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


; Purpose: Cycle through the various Audio Compression settings of
; No Compression, HiFi (Light), and TV (Heavy).
Func RunAudioCompression($hTestSummary)
	Local $bPass = True
	; OPTIONS-4-2-DOWN-DOWN-DOWN-DOWN
	Local $aAVSettings[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:2000; rmt:OPTIONS", _
			"wait:1000; rmt:DIGIT4", _
			"wait:1000; rmt:DIGIT2", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN"]
	MakeCmdDrip($aAVSettings)
	RunDripTest("cmd")

	;  User Value,  Actual value
	Local $aAVResults[3][2] = [ _
			["AUDIO_COMPRESSION_LIGHT", "Off"], _
			["AUDIO_COMPRESSION_HEAVY", "On"], _
			["AUDIO_COMPRESSION_NONE", "Off"]]
	$bPass = RunRightArrowTest($aAVResults, "Audio Compression", "Changing Audio Compression mode to", "Audio compression:", $hTestSummary)
	Return ($bPass)
EndFunc   ;==>RunAudioCompression


; Purpose: Cycle through the HDMI Audio settings of
; Pass Through, PCM and Auto.
Func RunHdmiAudio($hTestSummary)
	Local $bPass = True
	; OPTIONS-4-2-DOWN-DOWN-DOWN-DOWN-DOWN
	Local $aAVSettings[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:2000; rmt:OPTIONS", _
			"wait:1000; rmt:DIGIT4", _
			"wait:1000; rmt:DIGIT2", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN" _
			]
	MakeCmdDrip($aAVSettings)
	RunDripTest("cmd")        ; Run Options 4 2 dn dn dn dn dn

	;  User Value,  Actual value
	Local $aAVResults[3][2] = [ _
			["Auto", "eAuto"], _
			["PCM", "ePcm"], _
			["PassThrough", "eAuto"]]
	$bPass = RunRightArrowTest($aAVResults, "HDMI Audio", "Set HDMI Audio", "hdmi.outputMode       =", $hTestSummary)
	Return ($bPass)
EndFunc   ;==>RunHdmiAudio


; Cycle throught the Analog Audio settings: Surround and Stereo.
Func RunAnalogAudio($hTestSummary)
	Local $bPass = True
	; OPTIONS-4-2-DOWN-DOWN-DOWN-DOWN-DOWN
	Local $aAVSettings[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:2000; rmt:OPTIONS", _
			"wait:1000; rmt:DIGIT4", _
			"wait:1000; rmt:DIGIT2", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN" _
			]
	MakeCmdDrip($aAVSettings)
	RunDripTest("cmd")

	;  User Value,  Actual value
	Local $aAVResults[2][2] = [ _
			["Stereo", "eStandard"], _
			["Surround", "eDolbySurroundCompatible"]]
	$bPass = RunRightArrowTest($aAVResults, "Analog Audio", "Changing Audio analog mode to", "Analog audio :", $hTestSummary)
	Return ($bPass)
EndFunc   ;==>RunAnalogAudio


; Cycle through the Optical Digital Audio settings: PCM and Dolby Digital.
Func RunOpticalDigitalAudio($hTestSummary)
	Local $bPass = True
	; OPTIONS-4-2-DOWN-DOWN-DOWN-DOWN-DOWN
	Local $aAVSettings[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:2000; rmt:OPTIONS", _
			"wait:1000; rmt:DIGIT4", _
			"wait:1000; rmt:DIGIT2", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN" _
			]
	MakeCmdDrip($aAVSettings)
	RunDripTest("cmd")

	;  User Value,  Actual value
	Local $aAVResults[2][2] = [ _
			["Ac3", "eAuto"], _
			["PCM", "ePcm"]]
	$bPass = RunRightArrowTest($aAVResults, "Optical Digital Audio", "Spidif mode:", "spdif.outputMode      =", $hTestSummary)

	Return ($bPass)
EndFunc   ;==>RunOpticalDigitalAudio


; Purpose:  Run the RIGHT_ARROW test on a GUI box, and compare debug settings to stats results.
Func RunRightArrowTest($aUserActualValues, $sTestTitle, $sDebugSearch, $sStatsSearch, $hTestSummary)
	Local $bPass = True
	MakeRmtCmdDrip("rmt:ARROW_RIGHT", 2000)
	Local $iSize = UBound($aUserActualValues, $UBOUND_ROWS)
	For $iCount = 1 To $iSize
		Local $sSubtestTitle = $iCount & ") " & $sTestTitle
		RunDripTest("cmd")                ; Run RIGHT_ARROW
		$sValueUser = FindNextStringInFile($sDebugSearch, "cmd")
		GUICtrlSetData($hTestSummary, $sSubtestTitle & " (user): " & $sValueUser & @CRLF)
		RunAstTtl()            ; Run the ast stats command
		$sValueActual = FindNextStringInFile($sStatsSearch, "ast")
		GUICtrlSetData($hTestSummary, $sSubtestTitle & " (actual): " & $sValueActual & @CRLF)

		$iIndex = _ArraySearch($aUserActualValues, $sValueUser)
		If @error Or $sValueActual <> $aUserActualValues[$iIndex][1] Then
			GUICtrlSetData($hTestSummary, $sSubtestTitle & " Fail" & @CRLF)
			ConsoleWrite("error = " & @error & ", iIndex = " & $iIndex & @CRLF)
			$bPass = False
		Else
			GUICtrlSetData($hTestSummary, $sSubtestTitle & " Pass" & @CRLF)
		EndIf
	Next

	Return ($bPass)
EndFunc   ;==>RunRightArrowTest

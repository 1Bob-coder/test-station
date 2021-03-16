; Purpose:  To run the Audio/Video tests.

#include-once
#include <RegTstUtil.au3>

; Purpose:  Entry point into the AV tests.
; Test Matrix Requirement:
; 1	DSR SI&T.A/V Presentation.Audio:001-001	Audio setting menu and sanity test
; 3	DSR SI&T.A/V Presentation.Video:007-001	16:9 Zoom Modes
; 3	DSR SI&T.A/V Presentation.Video:001-012	4:3 Stretch mode order
; 3	DSR SI&T.A/V Presentation.Video:001-002	4:3 Stretch & Normal settings
; 4	DSR SI&T.A/V Presentation.Video:001-004	4:3 Zoom setting
; 3	DSR SI&T.A/V Presentation.Audio:003-004	Independently configure output of digital audio outputs
; 3	DSR SI&T.A/V Presentation.Audio:007-001	Transcode stereo digital audio format to AC-3 Stereo
; 3	DSR SI&T.A/V Presentation.Audio:007-002	Transcode multichannel digital audio format to AC-3_5.1
Func RunAVPresentationTest($hTestSummary, $AV_Presentation_pf)
	Local $bPassFail = True
	PF_Box("Running", $COLOR_BLUE, $AV_Presentation_pf)
	GUICtrlSetData($hTestSummary, "==> AV Test Started")
	GUICtrlSetData($hTestSummary, "Test Type : User Setting / Actual Setting => Result")

	$bPassFail = RunVideoAspectOverride($hTestSummary) And $bPassFail
	$bPassFail = RunVideoOutputMode($hTestSummary) And $bPassFail
	$bPassFail = RunSdAspectRatio($hTestSummary) And $bPassFail
	$bPassFail = RunAudioCompression($hTestSummary) And $bPassFail
	$bPassFail = RunHdmiAudio($hTestSummary) And $bPassFail
	$bPassFail = RunAnalogAudio($hTestSummary) And $bPassFail

	If $sBoxType = "DSR830" Or $sBoxType = "DSR830_p2" Then
		$bPassFail = RunOpticalDigitalAudio($hTestSummary) And $bPassFail
	EndIf

	Local $aDebugs[] = [ _
			"wait:1000; ses:3", _
			"wait:1000; sea:all"]
	MakeCmdDrip($aDebugs)
	RunDripTest("cmd")
	SavePassFailTestResult("DSR SI&T.A/V Presentation.Audio:001-001", $bPassFail)
	If $bPassFail Then
		PF_Box("Pass", $COLOR_GREEN, $AV_Presentation_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $AV_Presentation_pf)
	EndIf
	GUICtrlSetData($hTestSummary, "<== AV Test Done" & @CRLF)
EndFunc   ;==>RunAVPresentationTest


; Purpose:  To cycle through the aspect ratios Zoom/Stretch/Normal
; Test Matrix Requirement:
; 3	DSR SI&T.A/V Presentation.Video:007-001	16:9 Zoom Modes
; 3	DSR SI&T.A/V Presentation.Video:001-012	4:3 Stretch mode order
Func RunVideoAspectOverride($hTestSummary)
	Local $bPass
	Local $sVctId = GetDiagData("A,5,3", "VCT_ID")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")

	If $sVctId = "4380" Then        ; Use channel 482 - This channel is 1080i.
		ChanChangeDrip("rmt:DIGIT4", "rmt:DIGIT8", "rmt:DIGIT2")
	EndIf
	; User value, Resultant value, Test Requirement
	Local $aUserVsActual[3][3] = [ _
			["6", "FORCE_STRETCH", ""], _
			["9", "ZOOM", ""], _
			["4", "NORMAL", ""]]

	; make the 'ast vi' command with 5 second timeout
	MakeAstTtl("ast vi", 5)

	; Turn on Video/Info debugs, "sea vi", "ses 2"
	Local $aDebugs[] = [ _
			"wait:1000; sea:vi", _
			"wait:1000; ses:2"]
	MakeCmdDrip($aDebugs)
	RunDripTest("cmd")

	; Make the cmd.drip file to press the ASPECT key twice to toggle the aspect ratio.
	Local $aAspect[] = [ _
			"wait:1000; rmt:ASPECT", _
			"wait:1000; rmt:ASPECT"]
	MakeCmdDrip($aAspect)        ; Make cmd.drip file to be run with Drip.
	$bPass = RunDripAstSerialTest($aUserVsActual, "Video Aspect Override", "conversion", "User Conversion Preference", $hTestSummary)
	SavePassFailTestResult("DSR SI&T.A/V Presentation.Video:007-001", $bPass)
	SavePassFailTestResult("DSR SI&T.A/V Presentation.Video:007-012", $bPass)

	Return ($bPass)
EndFunc   ;==>RunVideoAspectOverride


; Purpose:  Cycle through 1080p, 1080i, 720p, 480p, and 480i output modes.
; Test Matrix Requirement: (None)
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
	$sValue = FindNextStringInFile("Nexus Display Format", "ast")
	If $sValue = "1080I" Then
		$bPassFail = RunVideoOutput($aVid_1080p, "1080P", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_720p, "720P", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_480p, "480P", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_480i, "480I", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_1080i, "1080I", $hTestSummary) And $bPassFail
	Else
		$bPassFail = RunVideoOutput($aVid_1080i, "1080I", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_720p, "720P", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_480p, "480P", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_480i, "480I", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_720p, "1080P", $hTestSummary) And $bPassFail
		$bPassFail = RunVideoOutput($aVid_1080i, "1080P", $hTestSummary) And $bPassFail
	EndIf
	Return ($bPassFail)
EndFunc   ;==>RunVideoOutputMode


; Purpose:  Runs a VideoOutput Test for 1080p, 1080i, etc. and returns a pass/fail result.
Func RunVideoOutput($aDripCmd, $sTestString, $hTestSummary)
	Local $bPassFail = True     ; True for pass
	MakeCmdDrip($aDripCmd)
	RunDripTest("cmd")
	RunAstTtl()
	$sValue = FindNextStringInFile("Nexus Display Format", "ast")
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


; Purpose: Cycle through the various SD Aspect Ratio settings of Stretch, Zoom, and Normal.
; Test Matrix Requirement:
; 3	DSR SI&T.A/V Presentation.Video:001-002	4:3 Stretch & Normal settings
; 4	DSR SI&T.A/V Presentation.Video:001-004	4:3 Zoom setting
Func RunSdAspectRatio($hTestSummary)
	Local $bPass = True
	; Press Exit twice to get out of any GUI screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	Local $sVctId = GetDiagData("A,5,3", "VCT_ID")

	If $sVctId = "4380" Then        ; Use channel 130 - This channel is 480i.
		ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT3", "rmt:DIGIT0")
	EndIf

	; make the 'ast vi' command with 3 second timeout for Video Stats
	MakeAstTtl("ast vi", 5)

	; Turn on Video/Info debugs, "sea vi", "ses 2"
	Local $aDebugs[] = [ _
			"wait:1000; sea:vi", _
			"wait:1000; ses:2"]
	MakeCmdDrip($aDebugs)
	RunDripTest("cmd")

	; OPTIONS-4-2-DOWN-DOWN-DOWN-DOWN
	Local $aAVSettings[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:2000; rmt:OPTIONS", _
			"wait:1000; rmt:DIGIT4", _
			"wait:1000; rmt:DIGIT2", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN"]
	MakeCmdDrip($aAVSettings)
	RunDripTest("cmd")

	;  User Value,  Actual value
	Local $aAVResults[3][2] = [ _
			["ZOOM", "ZOOM"], _
			["STRETCH", "STRETCH"], _
			["NORMAL-BARS", "NORMAL"]]
	MakeRmtCmdDrip("rmt:ARROW_RIGHT", 2000)
	$bPass = RunDripAstSerialTest($aAVResults, "SD Aspect Ratio: ", "4:3 source on 16:9 TV -", "User Conversion Preference", $hTestSummary)
	SavePassFailTestResult("DSR SI&T.A/V Presentation.Video:001-002", $bPass)
	SavePassFailTestResult("DSR SI&T.A/V Presentation.Video:001-004", $bPass)
	Return ($bPass)
EndFunc   ;==>RunSdAspectRatio


; Purpose: Cycle through the various Audio Compression settings of No Compression, HiFi (Light), and TV (Heavy).
; Test Matrix Requirement: (None)
Func RunAudioCompression($hTestSummary)
	Local $bPass = True

	; make the 'ast au' command with 5 second timeout for Audio Stats
	MakeAstTtl("ast au", 5)

	; Turn on Audio/Info debugs, "sea au", "ses 2"
	Local $aDebugs[] = [ _
			"wait:1000; sea:au", _
			"wait:1000; ses:2"]
	MakeCmdDrip($aDebugs)
	RunDripTest("cmd")

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
	MakeRmtCmdDrip("rmt:ARROW_RIGHT", 2000)
	$bPass = RunDripAstSerialTest($aAVResults, "Audio Compression", "Changing Audio Compression mode to", "Audio compression:", $hTestSummary)
	Return ($bPass)
EndFunc   ;==>RunAudioCompression


; Purpose: Cycle through the HDMI Audio settings: Pass Through, PCM and Auto.
; Test Matrix Requirement:
; 3	DSR SI&T.A/V Presentation.Audio:003-004	Independently configure output of digital audio outputs
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
	MakeAstTtl("ast au", 5)           ; make the 'ast au' command with 5 second timeout

	;  User Value,  Actual value
	Local $aAVResults[3][2] = [ _
			["Auto", "eAuto"], _
			["PCM", "ePcm"], _
			["PassThrough", "eAuto"]]
	MakeRmtCmdDrip("rmt:ARROW_RIGHT", 2000)
	$bPass = RunDripAstSerialTest($aAVResults, "HDMI Audio", "HDMI Audio", "hdmi.outputMode", $hTestSummary)
	SavePassFailTestResult("DSR SI&T.A/V Presentation.Audio:003-004", $bPass)
	Return ($bPass)
EndFunc   ;==>RunHdmiAudio


; Cycle throught the Analog Audio settings: Surround and Stereo.
; Test Matrix Requirement:
; 3	DSR SI&T.A/V Presentation.Audio:007-001	Transcode stereo digital audio format to AC-3 Stereo
Func RunAnalogAudio($hTestSummary)
	Local $bPass = True

	; Turn on Audio/Info debugs, "sea au", "ses 2"
	Local $aDebugs[] = [ _
			"wait:1000; sea:au", _
			"wait:1000; ses:2"]
	MakeCmdDrip($aDebugs)
	RunDripTest("cmd")

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
	MakeAstTtl("ast au", 5)           ; make the 'ast au' command with 5 second timeout

	;  User Value,  Actual value
	Local $aAVResults[2][2] = [ _
			["Stereo", "eStandard"], _
			["Surround", "eDolbySurroundCompatible"]]
	MakeRmtCmdDrip("rmt:ARROW_RIGHT", 2000)
	$bPass = RunDripAstSerialTest($aAVResults, "Analog Audio", "Audio analog mode :", "Analog audio", $hTestSummary)
	SavePassFailTestResult("DSR SI&T.A/V Presentation.Audio:007-001", $bPass)
	Return ($bPass)
EndFunc   ;==>RunAnalogAudio


; Cycle through the Optical Digital Audio settings: PCM and Dolby Digital.
; Test Matrix Requirement:
; 3	DSR SI&T.A/V Presentation.Audio:007-002	Transcode multichannel digital audio format to AC-3_5.1
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
	MakeAstTtl("ast au", 5)           ; make the 'ast au' command with 5 second timeout

	;  User Value,  Actual value
	Local $aAVResults[2][2] = [ _
			["Ac3", "eAuto"], _
			["PCM", "ePcm"]]
	MakeRmtCmdDrip("rmt:ARROW_RIGHT", 2000)

	$bPass = RunDripAstSerialTest($aAVResults, "Optical Digital Audio", "Spidif mode:", "spdif.outputMode      =", $hTestSummary)
	SavePassFailTestResult("DSR SI&T.A/V Presentation.Audio:007-002", $bPass)
	Return ($bPass)
EndFunc   ;==>RunOpticalDigitalAudio


; Purpose:  Run the cmd.drip test on a GUI box, and compare debug settings to stats results.
; This collects the serial.log file for Neptune Debugs, and the ast.log file for the Stats.
; Then compares strings from both those files for proper association.
; Note:  The MakeAstTtl(), MakeCmdDrip() need to be defined before running this test, and debugs need to be turned on.
Func RunDripAstSerialTest($aUserVsActual, $sTestTitle, $sDebugSearch, $sStatsSearch, $hTestSummary)
	Local $bPass = True
	Local $iSize = UBound($aUserVsActual, $UBOUND_ROWS)  ; Compute size of array
	For $iCount = 1 To $iSize
		Local $sSubtestTitle = $iCount & ") " & $sTestTitle & ": "
		CollectSerialLogs("serial", False)   ; Start collecting the serial.txt file
		RunDripTest("cmd")                ; Run the cmd.drip file
		Sleep(3000)                            ; Sleep for 3 seconds
		WinKill("COM" & $sComPort)                            ; End collection of serial log file
		RunAstTtl()            ; Run the ast stats command
		$sValueActual = FindNextStringInFile($sStatsSearch, "ast")
		$sValueUser = FindNextStringInFile($sDebugSearch, "serial")

		$iIndex = _ArraySearch($aUserVsActual, $sValueUser)
		If @error Or $sValueActual <> $aUserVsActual[$iIndex][1] Then
			GUICtrlSetData($hTestSummary, $sSubtestTitle & $sValueUser & " / " & $sValueActual & " => Fail" & @CRLF)
			ConsoleWrite("Search in serial.log : " & $sDebugSearch & @CRLF)
			ConsoleWrite("Search in ast.log : " & $sStatsSearch & @CRLF)
			ConsoleWrite("error = " & @error & ", iIndex = " & $iIndex & @CRLF)
			$bPass = False
		Else
			GUICtrlSetData($hTestSummary, $sSubtestTitle & $sValueUser & " / " & $sValueActual & " => Pass" & @CRLF)
		EndIf
	Next

	Return ($bPass)
EndFunc   ;==>RunDripAstSerialTest

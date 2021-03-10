; Purpose:  To run the tuning tests.
; All channels are MPEG4, Ac3, 8PSK, 20.5 MBPS Symbol Rate, 1.92 code rate
; Data collection parameters are:
; Nexus  Source Format          : 720P  --> or 1080I, or 480I
; Nexus Aspect Ratio            : 4x3(1.3) derived with Sar x:y:(x*w/y*h)=10:11:1.33333  --> or 16x9 (1.7)
; Freq from 995250000* to 1435250000* (all frequency descriptors)


#include-once
#include <RegTstUtil.au3>


; Purpose:  The main entry point for running all of the tuning tests.
; This satisfies the following tests
; 4	DSR SI&T.Tuning.Acquisition:001-010	Tuner offset frequency
; 1	DSR SI&T.Tuning.Acquisition:003-001	Acquired any 8PSK signal in the L-Band input frequency range of 950-2150 MHz
; 3	DSR SI&T.Tuning.Acquisition:003-005	8PSK signal acquisition
; 1	DSR SI&T.Tuning.Acquisition:003-006	8-PSK Received Eb/No (dB)
; 3	DSR SI&T.Tuning.Acquisition:003-014	Auto tune to 8PSK Rate Symbol Rate 20.50 Code Rate 1.92
Func RunTuningTest($hTestSummary, $hTuning_pf, $iTestType)
	Local $bPass = True, $bPassFail = True, $iNumChannels = 5
	PF_Box("Running", $COLOR_BLUE, $hTuning_pf)
	GUICtrlSetData($hTestSummary, "==> Tuning Test Started" & @CRLF)
	; Check if CSS configured
	$bIsCss = IsThisCssUnit($hTestSummary)
	If $bIsCss Then
		GUICtrlSetData($hTestSummary, "This is a CSS Unit" & @CRLF)
	Else
		GUICtrlSetData($hTestSummary, "This is an ODU, non-CSS, unit" & @CRLF)
	EndIf

	If $iTestType = 1 Then
		$iNumChannels = 0          ; Channel change across all channels
	EndIf

	; For VCT_ID of 4380, start at channel 964.  Use 216 for CSS channel testing.
	If $sVctId = "4380" Then
		; For VCT_ID of 4380, start at channel 964.  Use 216 for CSS channel testing.
		Local $aChanNumTune[] = ["rmt:DIGIT9", "rmt:DIGIT6", "rmt:DIGIT4"]
		Local $aChanNumCss[] = ["rmt:DIGIT2", "rmt:DIGIT1", "rmt:DIGIT6"]
	Else
		Local $aChanNumTune[] = ["rmt:DIGIT9", "rmt:DIGIT6", "rmt:DIGIT4"]
		Local $aChanNumCss[] = ["rmt:DIGIT2", "rmt:DIGIT1", "rmt:DIGIT6"]
	EndIf

	; Perform the channel change test across multiple channels with various a/v parameters.
	$bPass = PerformChannelChanges($hTestSummary, $iNumChannels, $aChanNumTune, "Tune Test", "TuneTestResults.txt")
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:001-010", $bPass)
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:003-001", $bPass)
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:003-005", $bPass)
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:003-006", $bPass)
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:003-014", $bPass)

	; If this is a CSS unit, perform CSS testing.
	; Turn off CSS, then turn on Auto and check by channel changing.
	; Refresh CSS, then check with channel changes.
	; Reboot.  Check if UB slots are the same.  Check with channel changes.
	$bIsCss = IsThisCssUnit($hTestSummary)
	If $bIsCss Then
		GUICtrlSetData($hTestSummary, "Perform CSS Tests" & @CRLF)
		$aSlotsBeforeReboot = GetCssSlots($hTestSummary, "Slots currently are: ")
		BringUpCssScreen()
		GUICtrlSetData($hTestSummary, "Turn off CSS, Standard ODU mode" & @CRLF)
		PickNoCss()                ; Turn off CSS
		GUICtrlSetData($hTestSummary, "Turn on CSS Auto mode, and do channel change test" & @CRLF)
		PickCssAuto()           ; Turn on "CSS Auto" mode.
		$aSlotsBeforeReboot = GetCssSlots($hTestSummary, "Slots Auto Mode are: ")
		$bPassFail = PerformChannelChanges($hTestSummary, 5, $aChanNumCss, "CSS Auto", "")
		SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:001-001", $bPassFail)
		SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:001-002", $bPassFail)
		SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:003-001", $bPassFail)
		SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:003-002", $bPassFail)
		SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:003-003", $bPassFail)
		$bPass = $bPass And $bPassFail

		BringUpCssScreen()
		GUICtrlSetData($hTestSummary, "Turn on CSS Refresh, and do channel change test." & @CRLF)
		PickCssRefresh()        ; Choose "CSS Refresh" mode
		$aSlotsBeforeReboot = GetCssSlots($hTestSummary, "Slots After CSS Refresh are: ")
		$bPass = PerformChannelChanges($hTestSummary, 5, $aChanNumCss, "CSS Refresh", "") And $bPass
		; Reboot the box.  Then check if CSS configuration was retained.
		If $sBoxType == "DSR800" Then
			GUICtrlSetData($hTestSummary, "Reboot box and test for same slots: " & $aSlotsBeforeReboot[0] & @CRLF)
		Else
			GUICtrlSetData($hTestSummary, "Reboot box and test for same slots: " & $aSlotsBeforeReboot[0] & ", " & $aSlotsBeforeReboot[1] & @CRLF)
		EndIf
		RebootBox()
		$bIsCss = IsThisCssUnit($hTestSummary)
		If $bIsCss Then
			GUICtrlSetData($hTestSummary, "Box rebooted.  This is a CSS Unit." & @CRLF)
			$aSlotsAfterReboot = GetCssSlots($hTestSummary, "Slots after reboot are: ")
			$bPassFail = False
			If $sBoxType == "DSR800" Then
				If $aSlotsBeforeReboot[0] == $aSlotsAfterReboot[0] Then
					$bPassFail = True
				EndIf
			Else
				If $aSlotsBeforeReboot[0] == $aSlotsAfterReboot[0] And $aSlotsBeforeReboot[1] == $aSlotsAfterReboot[1] Then
					$bPassFail = True
				EndIf
			EndIf
			If $bPassFail Then
				GUICtrlSetData($hTestSummary, "Slots remained the same after reboot.  BoxType = " & $sBoxType & @CRLF)
				$bPassFail = PerformChannelChanges($hTestSummary, 5, $aChanNumCss, "CSS Reboot", "")
			Else
				GUICtrlSetData($hTestSummary, "Failed on CSS Reboot Test - Slots are different.  BoxType = " & $sBoxType & @CRLF)
			EndIf
		Else
			$bPassFail = False
			GUICtrlSetData($hTestSummary, "Failed on CSS Reboot - No slots detected.  BoxType = " & $sBoxType & @CRLF)
		EndIf
		SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:001-017", $bPassFail)
		SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:001-018", $bPassFail)
		SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:001-021", $bPassFail)
		$bPass = $bPass And $bPassFail
	EndIf

	DisplayPassFail($bPass, $hTuning_pf)
	GUICtrlSetData($hTestSummary, "<== Tuning Test Done")
EndFunc   ;==>RunTuningTest


; Purpose:  Check if CSS Tests should be run.
; Returns: True if CSS.  False if not Css
Func IsThisCssUnit($hTestSummary)
	; Only run the CSS test if on a CSS unit.
	Local $bIsCss = True
	MakeAstTtl("ast tu", 5)
	RunAstTtl()
	; ast tu produces "System Mode: Disabled" if not connected, and "System Mode: Auto" if connected.
	$sValue = FindNextStringInFile("System Mode", "ast")
	If $sValue == "Disabled" Then
		$bIsCss = False
	EndIf
	Return $bIsCss
EndFunc   ;==>IsThisCssUnit

; Purpose:  Returns an array of UB Slots.
; Note:  IsThisCssUnit() needs to be run immediately prior to running this.
Func GetUbSlots($hTestSummary)
	$aUbSlots = FindAllStringsInFile("UB slot (hex):", "ast", 0, 1)            ; Returns an array of UbSlots
	Return $aUbSlots
EndFunc   ;==>GetUbSlots


; Purpose:  Prints CSS slots assigned.  Used to check CSS slot assignment requirements.
Func GetCssSlots($hTestSummary, $sTitle)
	Local $bIsCss = IsThisCssUnit($hTestSummary)
	If $bIsCss Then
		$aSlots = GetUbSlots($hTestSummary)
		$iNumSlots = UBound($aSlots)
		If $iNumSlots == 1 Then
			GUICtrlSetData($hTestSummary, $sTitle & $aSlots[0] & @CRLF)
		ElseIf $iNumSlots == 2 Then
			GUICtrlSetData($hTestSummary, $sTitle & $aSlots[0] & ", " & $aSlots[1] & @CRLF)
		EndIf
	Else
		GUICtrlSetData($hTestSummary, $sTitle & " No slots - Non CSS Unit" & @CRLF)
	EndIf
	Return $aSlots
EndFunc   ;==>GetCssSlots


; Purpose:  Puts up the CSS Screen.
Func BringUpCssScreen()
	; Options 4,3,4 puts up the CSS screen.
	Local $aCssScreen[] = [ _
			"wait:1000; rmt:EXIT", _
			"wait:1000; rmt:EXIT", _
			"wait:2000; rmt:OPTIONS", _
			"wait:1000; rmt:DIGIT4", _
			"wait:1000; rmt:DIGIT3", _
			"wait:1000; rmt:DIGIT4"]
	MakeCmdDrip($aCssScreen)
	RunDripTest("cmd")
	; Wait for TRANSPORT_LOCKED
	Local $aLocked[] = ["TRANSPORT_LOCKED"]
	MakeWaitTtl($aLocked)
	RunWaitTtl()
EndFunc   ;==>BringUpCssScreen

; Purpose:  The first item in the CSS screen is No CSS.  Pick that.
Func PickNoCss()
	; Go to CSS Auto (up arrow 5, down arrow 1, enter)
	Local $NoCss[] = [ _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:SELECT"]
	MakeCmdDrip($NoCss)
	RunDripTest("cmd")
	; Wait for TRANSPORT_LOCKED (1)
	Local $aLocked_1[] = [ _
			"TRANSPORT_LOCKED", _
			"(1)"]
	MakeWaitTtl($aLocked_1)
	RunWaitTtl()
EndFunc   ;==>PickNoCss

; Purpose:  The second item in the CSS screen is CSS Auto.  Pick that.
Func PickCssAuto()
	; Go to CSS Auto (up arrow 5, down arrow 1, enter)
	Local $aCssAuto[] = [ _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_UP", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:SELECT"]
	MakeCmdDrip($aCssAuto)
	RunDripTest("cmd")
	; Wait for TRANSPORT_LOCKED (1)
	Local $aLocked_1[] = [ _
			"TRANSPORT_LOCKED", _
			"(1)"]
	MakeWaitTtl($aLocked_1)
	RunWaitTtl()
EndFunc   ;==>PickCssAuto

; Purpose:  The last item in the CSS screen is CSS Refresh.  Pick that.
Func PickCssRefresh()
	; Go to CSS Refresh (down arrow 5 times, enter)
	Local $aCssRefresh[] = [ _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:ARROW_DOWN", _
			"wait:1000; rmt:SELECT"]
	MakeCmdDrip($aCssRefresh)
	RunDripTest("cmd")
	; Wait for TRANSPORT_LOCKED
	Local $aLocked[] = ["TRANSPORT_LOCKED"]
	MakeWaitTtl($aLocked)
	RunWaitTtl()
EndFunc   ;==>PickCssRefresh

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
Func RunTuningTest($hTestSummary, $hTuning_pf, $bLongTest, $bSkipCss)
	Local $bPass = True, $bPassFail = True, $iNumChannels = 25
	PF_Box("Running", $COLOR_BLUE, $hTuning_pf)
	GUICtrlSetData($hTestSummary, "==> Tuning Test Started" & @CRLF)

	; Check if CSS configured
	$bIsCss = IsThisCssUnit($hTestSummary)
	If $bIsCss Then
		GUICtrlSetData($hTestSummary, "This is a CSS Unit" & @CRLF)
	Else
		GUICtrlSetData($hTestSummary, "This is an ODU, non-CSS, unit" & @CRLF)
	EndIf

	If $bLongTest Then
		$iNumChannels = 0          ; Channel change across all channels
	EndIf

	; Find the average channel change speed.
	$bPass = PerformChannelChanges($hTestSummary, $iNumChannels, $sHdChan, "Tune", "TuneTestResults.txt")
	ComputeAvgChanSpeed($hTestSummary)

	; Perform the channel change test across multiple channels with various a/v parameters.
	;$bPass = PerformChannelChanges($hTestSummary, 5, $aChanNumTune, "Tune2", "TuneTestResults2.txt")
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:001-010", $bPass)
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:003-001", $bPass)
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:003-005", $bPass)
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:003-006", $bPass)
	SavePassFailTestResult("DSR SI&T.Tuning.Acquisition:003-014", $bPass)
	If $bPass == False Then
		PF_Box("Running", $COLOR_RED, $hTuning_pf)
	EndIf

	; If this is a CSS unit, perform CSS testing.
	; Turn off CSS, then turn on Auto and check by channel changing.
	; Refresh CSS, then check with channel changes.
	; Reboot.  Check if UB slots are the same.  Check with channel changes.
	$bIsCss = IsThisCssUnit($hTestSummary)
	If $bSkipCss Then
		GUICtrlSetData($hTestSummary, "Skip CSS Tests" & @CRLF)
	Else
		If $bIsCss Then
			GUICtrlSetData($hTestSummary, "Perform CSS Tests" & @CRLF)
			$aSlotsBeforeReboot = GetCssSlots($hTestSummary, "Slots currently are: ")
			BringUpCssScreen()
			GUICtrlSetData($hTestSummary, "Turn off CSS, Standard ODU mode" & @CRLF)
			PickNoCss()            ; Turn off CSS
			GUICtrlSetData($hTestSummary, "Turn on CSS Auto mode, and do channel change test" & @CRLF)
			PickCssAuto()       ; Turn on "CSS Auto" mode.
			$aSlotsBeforeReboot = GetCssSlots($hTestSummary, "Slots Auto Mode are: ")
			$bPassFail = PerformChannelChanges($hTestSummary, 5, $sHdChan, "CSS Auto", "")
			SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:001-001", $bPassFail)
			SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:001-002", $bPassFail)
			SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:003-001", $bPassFail)
			SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:003-002", $bPassFail)
			SavePassFailTestResult("DSR SI&T.Tuning.Channel Stacking Switch CSS:003-003", $bPassFail)
			$bPass = $bPass And $bPassFail
			If $bPass == False Then
				PF_Box("Running", $COLOR_RED, $hTuning_pf)
			EndIf

			BringUpCssScreen()
			GUICtrlSetData($hTestSummary, "Turn on CSS Refresh, and do channel change test." & @CRLF)
			PickCssRefresh()    ; Choose "CSS Refresh" mode
			$aSlotsBeforeReboot = GetCssSlots($hTestSummary, "Slots After CSS Refresh are: ")
			$bPass = PerformChannelChanges($hTestSummary, 5, $sHdChan, "CSS Refresh", "") And $bPass
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
					$bPassFail = PerformChannelChanges($hTestSummary, 5, $sHdChan, "CSS Reboot", "")
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
	EndIf

	DisplayPassFail($bPass, $hTuning_pf)
	GUICtrlSetData($hTestSummary, "<== Tuning Test Done")
EndFunc   ;==>RunTuningTest


; Purpose:  Computes the channel change speed across same transponder and different transponders.
Func ComputeAvgChanSpeed($hTestSummary)
	Local $iTRSize = UBound($aTuneResults)
	Local $iSecSame, $iSecDiff, $iSecSameNum, $iSecDiffNum
	Local $iSecDiff = 0
	ConsoleWrite("Size of array = " & $iTRSize & @CRLF)
	For $ii = 1 To $iTRSize - 2
		If $aTuneResults[$ii][3] <> "NA" And $aTuneResults[$ii + 1][3] <> "NA" Then
			If $aTuneResults[$ii][6] = "SERVICE_AUTHORIZED" Then
				ConsoleWrite($ii & " secs = " & $aTuneResults[$ii][3] & " - " & $aTuneResults[$ii + 1][3] & @CRLF)
				If $aTuneResults[$ii][2] = $aTuneResults[$ii + 1][2] Then
					$iSecSame = $iSecSame + $aTuneResults[$ii + 1][3]
					$iSecSameNum = $iSecSameNum + 1
				Else
					$iSecDiff = $iSecDiff + $aTuneResults[$ii + 1][3]
					$iSecDiffNum = $iSecDiffNum + 1
				EndIf
			Else
				GUICtrlSetData($hTestSummary, "Channel " & $aTuneResults[$ii + 1][0] & " did not get authorized.  Skipped" & @CRLF)
			EndIf
		EndIf
	Next
	If $iSecSameNum > 0 Then
		GUICtrlSetData($hTestSummary, "Channel Change Speed Test: Same Transponders " & $iSecSame & "/" & $iSecSameNum & " Avg:" & $iSecSame / $iSecSameNum & @CRLF)
		SaveTestResult("DSR SI&T.System Control.Service Selection:003-001", $iSecSame / $iSecSameNum)
	Else
		GUICtrlSetData($hTestSummary, "Channel Change Speed Test: Same Transponders - Not enough data" & @CRLF)
		SaveTestResult("DSR SI&T.System Control.Service Selection:003-001", "NA")
	EndIf
	If $iSecDiffNum > 0 Then
		GUICtrlSetData($hTestSummary, "Channel Change Speed Test: Different Transponders " & $iSecDiff & "/" & $iSecDiffNum & " Avg:" & $iSecDiff / $iSecDiffNum & @CRLF)
		SaveTestResult("DSR SI&T.System Control.Service Selection:003-002", $iSecDiff / $iSecDiffNum)
	Else
		GUICtrlSetData($hTestSummary, "Channel Change Speed Test: Different Transponders  - Not enough data" & @CRLF)
		SaveTestResult("DSR SI&T.System Control.Service Selection:003-002", "NA")
	EndIf
EndFunc   ;==>ComputeAvgChanSpeed


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
	Local $aSlots[] = [0, 0]
	If $bIsCss Then
		$aSlots = GetUbSlots($hTestSummary)
		$iNumSlots = UBound($aSlots)
		If $iNumSlots == 1 Then
			GUICtrlSetData($hTestSummary, $sTitle & $aSlots[0] & @CRLF)
		ElseIf $iNumSlots == 2 Then
			GUICtrlSetData($hTestSummary, $sTitle & $aSlots[0] & ", " & $aSlots[1] & @CRLF)
		EndIf
		Return $aSlots
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
	; Wait for TRANSPORT_LOCKED (1) and (0).
	Local $aLocked_1[] = [ _
			"TRANSPORT_LOCKED"]
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
	; Wait for TRANSPORT_LOCKED (1) and (0).
	Local $aLocked_1[] = [ _
			"TRANSPORT_LOCKED", _
			"TRANSPORT_LOCKED"]
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

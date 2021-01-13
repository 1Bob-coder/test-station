; Purpose:  To run the tuning tests.
; All channels are MPEG4, Ac3, 8PSK, 20.5 MBPS Symbol Rate, 1.92 code rate
; Data collection parameters are:
; Nexus  Source Format          : 720P  --> or 1080I, or 480I
; Nexus Aspect Ratio            : 4x3(1.3) derived with Sar x:y:(x*w/y*h)=10:11:1.33333  --> or 16x9 (1.7)
; Freq from 995250000* to 1435250000* (all frequency descriptors)


#include-once
#include <RegTstUtil.au3>

Local $aTuneResults[1][7] = [["--", "--", "--", "--", "--", "--", "--"]]

; Purpose:  The main entry point for running all of the tuning tests.
Func RunTuningTest($hTestSummary, $hTuning_pf, $iTestType)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hTuning_pf)
	GUICtrlSetData($hTestSummary, "==> Tuning Test Started")


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
	$bPass = PerformChannelChanges($hTestSummary, $iTestType, $aChanNumTune, "Tune Test")

	; Perform CSS Testing
	$bIsCss = IsThisCssUnit($hTestSummary)

	; If this is a CSS unit, perform CSS testing.
	; Turn off CSS, then turn on Auto and check by channel changing.
	; Refresh CSS, then check with channel changes.
	; Reboot.  Check if UB slots are the same.  Check with channel changes.
	If $bIsCss Then
		GUICtrlSetData($hTestSummary, "Perform CSS Tests" & @CRLF)
		$aSlotsBeforeReboot = GetUbSlots($hTestSummary)
		BringUpCssScreen()
		PickNoCss()                ; Turn off CSS
		PickCssAuto()           ; Turn on "CSS Auto" mode.
		$bPass = PerformChannelChanges($hTestSummary, 0, $aChanNumCss, "CSS Auto") And $bPass
		BringUpCssScreen()
		PickCssRefresh()        ; Choose "CSS Refresh" mode
		$bPass = PerformChannelChanges($hTestSummary, 0, $aChanNumCss, "CSS Refresh") And $bPass
		; Reboot the box.  Then check if CSS configuration was retained.
		RebootBox()
		$bIsCss = IsThisCssUnit($hTestSummary)
		If $bIsCss Then
			GUICtrlSetData($hTestSummary, "Box rebooted.  This is a CSS Unit." & @CRLF)
			$aSlotsAfterReboot = GetUbSlots($hTestSummary)
			If $aSlotsBeforeReboot[0] == $aSlotsAfterReboot[0] And $aSlotsBeforeReboot[1] == $aSlotsAfterReboot[1] Then
				GUICtrlSetData($hTestSummary, "Slots remained the same after reboot." & @CRLF)
				$bPass = PerformChannelChanges($hTestSummary, 0, $aChanNumCss, "CSS Reboot") And $bPass
			Else
				$bPass = False
				GUICtrlSetData($hTestSummary, "Failed on CSS Reboot Test - Slots are different")
			EndIf
		Else
			$bPass = False
			GUICtrlSetData($hTestSummary, "Failed on CSS Reboot - No slots detected")
		EndIf
	EndIf

	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $hTuning_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $hTuning_pf)
	EndIf
	GUICtrlSetData($hTestSummary, "<== Tuning Test Done")
EndFunc   ;==>RunTuningTest


; Purpose:  Channel change across multiple channels and gather the data.
; iTestType = 0 for short test, 1 for long test
; aChanNum - Channel Number, in array format to make Drip script.
; Note: All channels are MPEG4, Ac3, 8PSK, 20.5 MBPS Symbol Rate, 1.92 code rate
; 	Data collection parameters are:
; 	Nexus  Source Format          : 720P  --> or 1080I, or 480I
; 	Nexus Aspect Ratio            : 4x3(1.3) derived with Sar x:y:(x*w/y*h)=10:11:1.33333  --> or 16x9 (1.7)
; 	Freq from 995250000* to 1435250000* (all frequency descriptors)
Func PerformChannelChanges($hTestSummary, $iTestType, $aChanNum, $sTitle)
	Local $bPass = True
	; Is Test Type a "short" or "long" test?
	If $iTestType = 0 Then        ; "short" test, do  5 channels
		$sNumChans = 5
	Else                        ; "long" test, do all channels
		; Get the number of channels from diag A.
		$sNumChans = GetDiagData("A,5,2", "NumChannels =")
	EndIf

	GUICtrlSetData($hTestSummary, $sTitle & " - Running Tuning Test on " & $sNumChans & " channels." & @CRLF)
	$iNumMinutes = $sNumChans * 10 / 60
	GUICtrlSetData($hTestSummary, $sTitle & " - This will take approximately " & Round($iNumMinutes, 1) & " minutes" & @CRLF)

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")

	ChanChangeDrip($aChanNum[0], $aChanNum[1], $aChanNum[2])
	MakeRmtCmdDrip("rmt:CHAN_UP", 5000)        ; Chan Up, collect logs for 5 seconds

	For $ii = 1 To $sNumChans
		$sLocked = "NoLock"
		$sPassFail = ""
		RunDripTest("cmd")            ; Run chan_up
		MakeAstTtl("ast vi", 2)     ; Get the video stats
		RunAstTtl()
		$sChanNum = FindNextStringInFile("CH :", "cmd")
		If $sChanNum == "" Then
			$sChanNum = FindNextStringInFile("CHANNEL:", "cmd")
			If $sChanNum == "" Then
				$sChanNum = "?" & $ii & "?"
			EndIf
		EndIf
		If FindStringInFile("TRANSPORT_LOCKED", "cmd") Then
			$sLocked = "Lock"
		EndIf
		$sVideoSource = FindNextStringInFile("Nexus  Source Format", "ast")
		$sAspectRatio = FindNextStringInFile("Nexus Aspect Ratio", "ast")
		$sAuthState = FindNthStringInFile("notifyServiceInfo", "cmd", 2)    ; Skips one string and returns the next one.
		$sAuthWhy = FindNthStringInFile("displayAuthReason", "cmd", 1)        ; Same as FindNextStringInFile
		If $sAuthState == "" Then
			$bPass = False
			$sPassFail = " Fail, No AuthReason"
		EndIf

		MakeAstTtl("ast chan " & $sChanNum, 2)         ; Get the chan stats and the frequency.
		RunAstTtl()
		$sFreq = FindNthStringInFile("Frequency", "ast", 24) ; Skips to the 24 string and returns it.
		GUICtrlSetData($hTestSummary, $sTitle & " - Chan " & $sChanNum & " " & $sLocked & " " & $sVideoSource & " " & _
				$sAspectRatio & " " & $sAuthState & " " & $sAuthWhy & $sPassFail & @CRLF)
		Local $vRow[1][7] = [[$sChanNum, $sLocked, $sFreq, $sVideoSource, $sAspectRatio, $sAuthState, $sAuthWhy]]
		_ArrayAdd($aTuneResults, $vRow)
		Sleep(1000)  ; Sleep for 1 second
		FileDelete($sLogDir & $sChanNum & ".log")
		FileCopy($sLogDir & "cmd.log", $sLogDir & $sChanNum & ".log")
	Next
	_FileWriteFromArray("logs\TuneTestResults.txt", $aTuneResults)
	;_ArrayDisplay($aTuneResults, "Channel Change Tuning Test", "", 64, 0, "Chan|Frequency|Vid Src|Aspect|Authorization|AuthWhy")
	Return $bPass
EndFunc   ;==>PerformChannelChanges


; Purpose:  To show a pop-up array with the results of the channel change tuning test.
Func ShowTuneTestLogs()
	_ArrayDisplay($aTuneResults, "Channel Change Tuning Test", "", 64, 0, "Chan|Locked|Frequency|Vid Src|Aspect|Authorization|AuthWhy")
EndFunc   ;==>ShowTuneTestLogs


; Purpose:  Check if CSS Tests should be run.
; Returns: True if CSS.  False if not Css
Func IsThisCssUnit($hTestSummary)
	; Only run the CSS test if on a CSS unit.
	Local $bIsCss = True
	MakeAstTtl("ast tu", 10)
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

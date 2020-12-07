; Purpose:  To run the tuning tests.
; All channels are MPEG4, Ac3, 8PSK, 20.5 MBPS Symbol Rate, 1.92 code rate
; Data collection parameters are:
; Nexus  Source Format          : 720P  --> or 1080I, or 480I
; Nexus Aspect Ratio            : 4x3(1.3) derived with Sar x:y:(x*w/y*h)=10:11:1.33333  --> or 16x9 (1.7)
; Freq from 995250000* to 1435250000* (all frequency descriptors)


#include-once
#include <RegTstUtil.au3>

Local $aTuneResults[1][6] = [["--", "--", "--", "--", "--", "--"]]

Func RunTuningTest($hTestSummary, $hTuning_pf, $iTestType)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hTuning_pf)
	GUICtrlSetData($hTestSummary, "==> Tuning Test Started")

	; Is Test Type a "short" or "long" test?
	If $iTestType = 0 Then
		$sNumChans = 5
	Else
		; Get the number of channels from diag A.
		$sNumChans = GetDiagData("A,5,2", "NumChannels =")
		;MakeRmtCmdDrip("diag:A,5,2", 1000)
		;RunDripTest("cmd")
		;$sNumChans = FindNextStringInFile("NumChannels =", "cmd")
	EndIf

	GUICtrlSetData($hTestSummary, "Running Tuning Test on " & $sNumChans & " channels." & @CRLF)
	$iNumMinutes = $sNumChans * 10 / 60
	GUICtrlSetData($hTestSummary, "This will take approximately " & Round($iNumMinutes,1) & " minutes" & @CRLF)

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")

	; For VCT_ID of 4380, start at channel 964
	If $sVctId = "4380" Then
		ChanChangeDrip("rmt:DIGIT9", "rmt:DIGIT6", "rmt:DIGIT4")
	EndIf

	MakeRmtCmdDrip("rmt:CHAN_UP", 5000)        ; Chan Up, collect logs for 5 seconds
	For $ii = 1 To $sNumChans
		RunDripTest("cmd")
		MakeAstTtl("ast vi", 2)                ; Get the video stats
		RunAstTtl()
		;Local $sAuthState0 = "", $sAuthState1 = ""
		$sChanNum = FindNextStringInFile("CH :", "cmd")
		$sVideoSource = FindNextStringInFile("Nexus  Source Format", "ast")
		$sAspectRatio = FindNextStringInFile("Nexus Aspect Ratio", "ast")
		$sAuthState = FindNthStringInFile("notifyServiceInfo", "cmd", 2)    ; Skips one string and returns the next one.
		$sAuthWhy = FindNthStringInFile("displayAuthReason", "cmd", 1)        ; Same as FindNextStringInFile
		MakeAstTtl("ast chan " & $sChanNum, 2)         ; Get the chan stats and the frequency.
		RunAstTtl()
		$sFreq = FindNthStringInFile("Frequency", "ast", 24) ; Skips to the 24 string and returns it.
		GUICtrlSetData($hTestSummary, "Channel " & $sChanNum & " " & $sVideoSource & " " & _
				$sAspectRatio & " " & $sAuthState & " " & $sAuthWhy & @CRLF)
		Local $vRow[1][6] = [[$sChanNum, $sFreq, $sVideoSource, $sAspectRatio, $sAuthState, $sAuthWhy]]
		_ArrayAdd($aTuneResults, $vRow)
		Sleep(1000)  ; Sleep for 1 second
		FileDelete($sChanNum & ".log")
		FileCopy("cmd.log", $sChanNum & ".log")
	Next
	GUICtrlSetData($hTestSummary, "<== Tuning Test Done")
	PF_Box("Done", $COLOR_BLUE, $hTuning_pf)
	_FileWriteFromArray("logs\TuneTestResults.txt", $aTuneResults)
	;_ArrayDisplay($aTuneResults, "Channel Change Tuning Test", "", 64, 0, "Chan|Frequency|Vid Src|Aspect|Authorization|AuthWhy")
EndFunc   ;==>RunTuningTest

Func ShowTuneTestLogs()
	_ArrayDisplay($aTuneResults, "Channel Change Tuning Test", "", 64, 0, "Chan|Frequency|Vid Src|Aspect|Authorization|AuthWhy")
EndFunc   ;==>ShowTuneTestLogs

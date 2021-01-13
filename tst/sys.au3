; Purpose:  To run the System Control tests.

#include-once
#include <RegTstUtil.au3>


Func RunSysControlTest($hTestSummary, $hSystemControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hSystemControl_pf)
	GUICtrlSetData($hTestSummary, "==> System Control Test Started")

	; Check for Private Stream Messages coming into the box.
	$bPass = RunPrivStreamMsgTest($hTestSummary) And $bPass

	; Press the POWER button (DSR off)
	MakeRmtCmdDrip("rmt:POWER", 5000)
	$bPass = RunTestCriteria("cmd", "ALL VIDEO OUTPUTS: DISABLED", "Power Off", $hTestSummary, $hSystemControl_pf) And $bPass

	; Press the POWER button (DSR on)
	MakeRmtCmdDrip("rmt:POWER", 5000)
	$bPass = RunTestCriteria("cmd", ":ALL VIDEO OUTPUTS: ENABLED", "Power On", $hTestSummary, $hSystemControl_pf) And $bPass

	; Send the Reboot command
	$bPass = RunRebootTest($hTestSummary) And $bPass

	GUICtrlSetData($hTestSummary, "<== System Control Test Done")
	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $hSystemControl_pf)
	Else
		PF_Box("Fail", $COLOR_Red, $hSystemControl_pf)
	EndIf
EndFunc   ;==>RunSysControlTest

; Purpose: Reboot the box.  The VCT_ID and Number of Channels should not change.
Func RunRebootTest($hTestSummary)
	Local $bPass = True
	Global $hBoxIPAddress

	; Get Diagnostics
	Local $sNumChans1 = GetDiagData("A,5,2", "NumChannels")
	Local $sVct1 = GetDiagData("A,5,3", "VCT_ID")
	GUICtrlSetData($hTestSummary, "Before Reboot: Num Channels = " & $sNumChans1 & ", VCT_ID = " & $sVct1 & @CRLF)

	; Reboot the box.
	RebootBox()

	; Get Diagnostics
	Local $sNumChans2 = GetDiagData("A,5,2", "NumChannels")
	Local $sVct2 = GetDiagData("A,5,3", "VCT_ID")
	GUICtrlSetData($hTestSummary, "After Reboot: Num Channels = " & $sNumChans2 & ", VCT_ID = " & $sVct2 & @CRLF)

	If $sNumChans1 == $sNumChans2 And $sVct1 == $sVct2 Then
		GUICtrlSetData($hTestSummary, "Reboot Test - Pass")
	Else
		GUICtrlSetData($hTestSummary, "Reboot Test - Fail")
		$bPass = False
	EndIf
	Return $bPass
EndFunc   ;==>RunRebootTest


; Purpose: Collect SF counter metrics for various Table ID values.
; Note: We are only interested in TableID's 0, 1, and 2 for this test.
;       Other TableID's are shown for further verification of messages being received.
Func RunPrivStreamMsgTest($hTestSummary)
	Local $bPass = True
	Local $aSfStats[12][5] = [ _
			["0", "", "", "Service Assoc (PAT)", True], _
			["1", "", "", "Conditional Access", True], _
			["2", "", "", "Service Map (PMT)", True], _
			["92", "", "", "Channel Override", False], _
			["94", "", "", "Download Preamble", False], _
			["c0", "", "", "PIM", False], _
			["c1", "", "", "PNM", False], _
			["c2", "", "", "Network Information", False], _
			["c3", "", "", "Network Text", False], _
			["c4", "", "", "Virtual Channel", False], _
			["c5", "", "", "System Time", False], _
			["e6", "", "", "Guide", False]]

	Local $iSize = UBound($aSfStats, $UBOUND_ROWS) - 1 ; Compute size of array

	MakeAstTtl("ast sf", 3)
	RunAstTtl()
	For $ii = 0 To $iSize Step 1
		$aSfStats[$ii][1] = FindNextStringInFile("tableID " & $aSfStats[$ii][0], "ast")
	Next

	Sleep(5000)
	RunAstTtl()

	For $ii = 0 To $iSize Step 1
		$aSfStats[$ii][2] = FindNextStringInFile("tableID " & $aSfStats[$ii][0], "ast")
	Next

	For $ii = 0 To $iSize Step 1
		Local $sPassFail = " - Pass"
		Local $sHeading = ""
		$aSfStats[$ii][2] = FindNextStringInFile("tableID " & $aSfStats[$ii][0], "ast")
		If $aSfStats[$ii][4] Then
			If $aSfStats[$ii][1] == $aSfStats[$ii][2] Then
				$sPassFail = " - Fail"
				$bPass = False
			EndIf
			$sHeading = "Analyze - "
		Else
			$sPassFail = ""
			$sHeading = "Info Only - "
		EndIf
		GUICtrlSetData($hTestSummary, $sHeading & $aSfStats[$ii][0] & " " & $aSfStats[$ii][3] & ": " & $aSfStats[$ii][1] & " / " & $aSfStats[$ii][2] & $sPassFail & @CRLF)
	Next

	Return $bPass
EndFunc   ;==>RunPrivStreamMsgTest

; Purpose:  To run the System Control tests.

#include-once
#include <RegTstUtil.au3>


Func RunSysControlTest($hTestSummary, $hSystemControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hSystemControl_pf)
	GUICtrlSetData($hTestSummary, "==> System Control Test Started")

	; Press the POWER button
	MakeRmtCmdDrip("rmt:POWER", 5000)
	$bPass = RunTestCriteria("cmd", "ALL VIDEO OUTPUTS: DISABLED", "Power Off", $hTestSummary, $hSystemControl_pf) And $bPass

	; Press the POWER button
	MakeRmtCmdDrip("rmt:POWER", 5000)
	$bPass = RunTestCriteria("cmd", ":ALL VIDEO OUTPUTS: ENABLED", "Power On", $hTestSummary, $hSystemControl_pf) And $bPass

	Local $sNumChans1 = GetDiagData("A,5,2", "NumChannels")
	Local $sVct1 = GetDiagData("A,5,3", "VCT_ID")
	GUICtrlSetData($hTestSummary, "Num Channels = " & $sNumChans1 & ", VCT_ID = " & $sVct1 & @CRLF)

	; Send the Reboot command
	MakeRmtCmdDrip("send:22,2", 5000)
	RunDripTest("cmd")
	CollectSerialLogs("RebootSerial", True) ; Collect serial log and show it in real time.
	ShowProgressWindow()
	WinKill("COM")                            ; End collection of serial log file
	FindBoxIPAddress($hBoxIPAddress)        ; Get the IP address of the box in case it changed.

	; Get Diagnostics
	Local $sNumChans2 = GetDiagData("A,5,2", "NumChannels")
	Local $sVct2 = GetDiagData("A,5,3", "VCT_ID")
	GUICtrlSetData($hTestSummary, "Num Channels = " & $sNumChans2 & ", VCT_ID = " & $sVct2 & @CRLF)

	If $sNumChans1 == $sNumChans2 And $sVct1 == $sVct2 Then
		GUICtrlSetData($hTestSummary, "Reboot Test - Pass")
	Else
		GUICtrlSetData($hTestSummary, "Reboot Test - Fail")
		$bPass = False
	EndIf

	GUICtrlSetData($hTestSummary, "<== System Control Test Done")
	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $hSystemControl_pf)
	Else
		PF_Box("Fail", $COLOR_Red, $hSystemControl_pf)
	EndIf
EndFunc   ;==>RunSysControlTest


Func ShowProgressWindow()
	; Display a progress bar window.
	ProgressOn("Rebooting Now", "Wait 2 minutes for box to boot up.", "0%", -1, -1, $DLG_MOVEABLE)

	; Update the progress value of the progress bar window every second.
	For $i = 1 To 120 Step 1
		Sleep(1000)
		ProgressSet($i * 100 / 120, $i & " seconds")
	Next

	; Set the "subtext" and "maintext" of the progress bar window.
	ProgressSet(100, "Done", "Complete")
	Sleep(5000)
	ProgressOff()	; Close the progress window.
EndFunc   ;==>ShowProgressWindow

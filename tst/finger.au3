; Purpose:  To run the DVR and Trick Play tests.

#include-once
#include <RegTstUtil.au3>


Func RunFingerTest($TestSummary, $Fingerprint_pf)
	GUICtrlSetData($hTestSummary, "==> Fingerprint Test Started")

	PF_Box("Running", $COLOR_BLUE, $Fingerprint_pf)
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")        ; EXIT key twice to get out of any GUI screens

	$sSeqNum = StringFormat("%.2d", Random(1, 99, 1))                 ; Need to randomize a sequence number
	Local $aFinCmd[2] = ["wait:1000; msp:96,00,0c,00," & $sSeqNum & ",80,33,ff,ff,ff,02", _
			"wait:7000; sea:all"]
	MakeCmdDrip($aFinCmd)
	Local $bPass = RunTestCriteria("cmd", "displayUA", "Fingerprint", $TestSummary, $Fingerprint_pf)
	GUICtrlSetData($TestSummary, "<== Fingerprint Test Done")
	If $bPass Then
		PF_Box("Pass", $COLOR_GREEN, $Fingerprint_pf)
	Else
		PF_Box("Fail", $COLOR_RED, $Fingerprint_pf)
	EndIf
EndFunc   ;==>RunFingerTest

; Purpose:  To run the DVR and Trick Play tests.

#include-once
#include <RegTstUtil.au3>


Func RunFingerTest($TestSummary, $Fingerprint_pf)
	GUICtrlSetData($TestSummary, @CRLF & "Fingerprint Test Running ...")
	PF_Box("Running", $COLOR_BLUE, $Fingerprint_pf)

	$sSeqNum = StringFormat("%.2d", Random(1, 99, 1))                 ; Need to randomize a sequence number
	Local $aFinCmd[2] = ["wait:1000; msp:96,00,0c,00," & $sSeqNum & ",80,33,ff,ff,ff,02", _
			"wait:7000; sea:all"]
	MakeCmdDrip($aFinCmd)
	RunTestCriteria("cmd", "displayUA", "Fingerprint", $TestSummary, $Fingerprint_pf)
	GUICtrlSetData($TestSummary, "Fingerprint Test Done")
	PF_Box("Done", $COLOR_BLUE, $Fingerprint_pf)
EndFunc   ;==>RunFingerTest

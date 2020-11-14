; Purpose:  To run the tuning tests.

#include-once
#include <RegTstUtil.au3>


Func RunDownloadTest($hTestSummary, $hDownload_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hDownload_pf)
	GUICtrlSetData($hTestSummary, "Download Test Started")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")

	GUICtrlSetData($hTestSummary, "Download Test Done")
	PF_Box("Done", $COLOR_BLUE, $hDownload_pf)
EndFunc   ;==>RunDownloadTest


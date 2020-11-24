; Purpose:  To run the tuning tests.

#include-once
#include <RegTstUtil.au3>


Func RunDownloadTest($hTestSummary, $hDownload_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hDownload_pf)
	GUICtrlSetData($hTestSummary, "==> Download Test Started")


	GUICtrlSetData($hTestSummary, "<== Download Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hDownload_pf)
EndFunc   ;==>RunDownloadTest


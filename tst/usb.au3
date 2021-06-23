; Purpose:  To run the USB tests.

#include-once
#include <RegTstUtil.au3>


Func RunUsbTest($hTestSummary, $hUSB_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hUSB_pf)
	DisplayLineOfText($hTestSummary, "==> USB Test Started")

	DisplayLineOfText($hTestSummary, "<== USB Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hUSB_pf)
EndFunc   ;==>RunUsbTest


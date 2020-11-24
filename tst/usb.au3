; Purpose:  To run the USB tests.

#include-once
#include <RegTstUtil.au3>


Func RunUsbTest($hTestSummary, $hUSB_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hUSB_pf)
	GUICtrlSetData($hTestSummary, "==> USB Test Started")

	GUICtrlSetData($hTestSummary, "<== USB Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hUSB_pf)
EndFunc   ;==>RunUsbTest


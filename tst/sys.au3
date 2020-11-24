; Purpose:  To run the System Control tests.

#include-once
#include <RegTstUtil.au3>


Func RunSysControlTest($hTestSummary, $hSystemControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hSystemControl_pf)
	GUICtrlSetData($hTestSummary, "==> System Control Test Started")


	GUICtrlSetData($hTestSummary, "<== System Control Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hSystemControl_pf)
EndFunc   ;==>RunSysControlTest


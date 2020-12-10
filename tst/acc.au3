; Purpose:  To run the Access Control tests.

#include-once
#include <RegTstUtil.au3>


Func RunAccTest($hTestSummary, $hAccessControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hAccessControl_pf)
	GUICtrlSetData($hTestSummary, "==> Access Control Test Started")

	GUICtrlSetData($hTestSummary, "<== Access Control Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hAccessControl_pf)
EndFunc   ;==>RunAccTest


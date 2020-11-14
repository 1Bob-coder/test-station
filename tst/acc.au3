; Purpose:  To run the Access Control tests.

#include-once
#include <RegTstUtil.au3>


Func RunAccTest($hTestSummary, $hAccessControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hAccessControl_pf)
	GUICtrlSetData($hTestSummary, "Access Control Test Started")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")

	GUICtrlSetData($hTestSummary, "Access Control Test Done")
	PF_Box("Done", $COLOR_BLUE, $hAccessControl_pf)
EndFunc   ;==>RunAccTest


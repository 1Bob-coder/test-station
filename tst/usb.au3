; Purpose:  To run the USB tests.

#include-once
#include <RegTstUtil.au3>


Func RunUsbTest($hTestSummary, $hUSB_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hUSB_pf)
	GUICtrlSetData($hTestSummary, "USB Test Started")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")

	GUICtrlSetData($hTestSummary, "USB Test Done")
	PF_Box("Done", $COLOR_BLUE, $hUSB_pf)
EndFunc   ;==>RunUsbTest


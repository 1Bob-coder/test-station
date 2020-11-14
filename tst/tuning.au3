; Purpose:  To run the tuning tests.

#include-once
#include <RegTstUtil.au3>


Func RunTuningTest($hTestSummary, $hTuning_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hTuning_pf)
	GUICtrlSetData($hTestSummary, "Tuning Test Started")

	; Press EXIT twice to get out of any screens.
	MakeRmtCmdDrip("rmt:EXIT", 1000)
	RunDripTest("cmd")
	RunDripTest("cmd")
	ChanChangeDrip("rmt:DIGIT1", "rmt:DIGIT2", "rmt:DIGIT1")

	MakeRmtCmdDrip("rmt:CHAN_UP", 5000)
	For $ii = 1 To 10
		RunDripTest("cmd")
	Next
	GUICtrlSetData($hTestSummary, "Tuning Test Done")
	PF_Box("Done", $COLOR_BLUE, $hTuning_pf)
EndFunc   ;==>RunTuningTest

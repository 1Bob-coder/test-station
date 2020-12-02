; Purpose:  To run the Access Control tests.

#include-once
#include <RegTstUtil.au3>


Func RunAccTest($hTestSummary, $hAccessControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hAccessControl_pf)
	GUICtrlSetData($hTestSummary, "==> Access Control Test Started")

	GUICtrlSetData($hTestSummary, "INTERACTIVE, EXIT" & @CRLF)
	Local $aTestRemote[] = [ _
			"wait:1000; rmt:INTERACTIVE", _
			"wait:5000; rmt:EXIT"]
	MakeCmdDrip($aTestRemote)
	RunDripTest("cmd")

	GUICtrlSetData($hTestSummary, "LIST, EXIT" & @CRLF)
	Local $aTestRemote[] = [ _
			"wait:1000; rmt:LIST", _
			"wait:5000; rmt:EXIT"]
	MakeCmdDrip($aTestRemote)
	RunDripTest("cmd")

		GUICtrlSetData($hTestSummary, "BROWSE, EXIT" & @CRLF)
	Local $aTestRemote[] = [ _
			"wait:1000; rmt:BROWSE", _
			"wait:5000; rmt:EXIT"]
	MakeCmdDrip($aTestRemote)
	RunDripTest("cmd")

	GUICtrlSetData($hTestSummary, "<== Access Control Test Done")
	PF_Box("Not Implemented", $COLOR_BLUE, $hAccessControl_pf)
EndFunc   ;==>RunAccTest


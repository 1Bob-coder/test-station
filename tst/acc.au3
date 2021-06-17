; Purpose:  To run the Access Control tests.

#include-once
#include <RegTstUtil.au3>
#include <GuiComboBox.au3>

Func RunAccTest($hTestSummary, $hAccessControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hAccessControl_pf)
	GUICtrlSetData($hTestSummary, "==> Access Control Test Started")

	; Use a channel with "Subscribed" authorization.
	$bPass = PerformChannelChanges($hTestSummary, 5, $sSubscribedChan, "Subscribed Test", "")

	DisplayPassFail($bPass, $hAccessControl_pf)
	GUICtrlSetData($hTestSummary, "<== Access Control Test Done")
EndFunc   ;==>RunAccTest


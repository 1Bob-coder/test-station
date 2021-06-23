; Purpose:  To run the Access Control tests.

#include-once
#include <RegTstUtil.au3>
#include <GuiComboBox.au3>
#include <GuiListView.au3>
Func RunAccTest($hTestSummary, $hAccessControl_pf)
	Local $bPass = True
	DisplayLineOfText($hTestSummary, "==> Access Control Test Started")
	PF_Box("Running", $COLOR_BLUE, $hAccessControl_pf)

	; Use a channel with "Subscribed" authorization.
	$bPass = PerformChannelChanges($hTestSummary, 5, $sSubscribedChan, "Subscribed Test", "")

	DisplayPassFail($bPass, $hAccessControl_pf)
	DisplayLineOfText($hTestSummary, "<== Access Control Test Done")
EndFunc   ;==>RunAccTest


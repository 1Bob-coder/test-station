; Purpose:  To run the Access Control tests.

#include-once
#include <RegTstUtil.au3>


Func RunAccTest($hTestSummary, $hAccessControl_pf)
	Local $bPass = True
	PF_Box("Running", $COLOR_BLUE, $hAccessControl_pf)
	GUICtrlSetData($hTestSummary, "==> Access Control Test Started")

	; For VCT_ID of 4380, start at channel 964.  Use 216 for CSS channel testing.
	If $sVctId = "4380" Then
		; For VCT_ID of 4380, start at channel 964.  Use 216 for CSS channel testing.
		Local $aChanNumTune[] = ["rmt:DIGIT9", "rmt:DIGIT6", "rmt:DIGIT3"]
		$bPass = PerformChannelChanges($hTestSummary, 5, $aChanNumTune, "Subscribbed Test")
	Else
		GUICtrlSetData($hTestSummary, "VCT_ID is " & $sVctId & ", must be 4380 to run test." & @CRLF)
		GUICtrlSetData($hTestSummary, "<== Access Control Test Done")
		PF_Box("Not Performed", $COLOR_BLUE, $hAccessControl_pf)
		Return
	EndIf

	GUICtrlSetData($hTestSummary, "<== Access Control Test Done")
	DisplayPassFail($bPass, $hAccessControl_pf)
EndFunc   ;==>RunAccTest


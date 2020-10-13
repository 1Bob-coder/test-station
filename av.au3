; Purpose:  To run the Audio/Video tests.

#include-once
#include <RegTstUtil.au3>


Func RunAVPresentationTest($TestSummary, $AV_Presentation_pf)
	PF_Box("Running", $COLOR_BLUE, $AV_Presentation_pf)
	RunDripTest("av_menu")
	PF_Box("Pass", $COLOR_GREEN, $AV_Presentation_pf)
EndFunc   ;==>RunAVPresentationTest



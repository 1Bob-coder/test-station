#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
$TESTExit = GUICreate("EXITTest", 275, 250, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU))
$AltF4 = GUICtrlCreateLabel("Press ALT+F4 to exit", 10, 210)
$ContextMenu = GUICtrlCreateContextMenu()
$ContextMenuExit = GUICtrlCreateMenuItem("ExitMenuItem", $ContextMenu)
$FileMenu = GUICtrlCreateMenu("&File")
$FileExit = GUICtrlCreateMenuItem("ExitMenu", $FileMenu)
$Button = GUICtrlCreateButton("ExitButton", 150, 20, 100, 24)
GUISetState(@SW_SHOW, $TESTExit)
While 1
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE, $Button, $FileExit, $ContextMenuExit
			Exit
	EndSwitch
WEnd

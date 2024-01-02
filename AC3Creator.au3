; ==============================================================================
; Copyright (c) 2008 by Alcatel-Lucent Deutschland GmbH. All rights reserved.
; ==============================================================================
;
; FILE: AC3Creator.au3
; DEPARTMENT: TEC Germany
; AUTHOR: H.Friedrich
;
; ------------------------------------------------------------------------------
; DESCRIPTION: AutoIT script to ceate AC3 files from MPEG in one step
;
; ------------------------------------------------------------------------------
; HISTORY :
;   V0.8 08/05/09 - H.FRIEDRICH : new file
;   V0.9 09/06/08 - H.FRIEDRICH : recreate script for GUIOnEventMode
;
; ==============================================================================
;**** Directives created by AutoIt3Wrapper_GUI ****
#region AutoIt3Wrapper directives section
#AutoIt3Wrapper_Icon=..\graphics\AC3Creator.ico
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_OutFile=AC3Creator.exe
#AutoIt3Wrapper_Res_Comment=Thx too all that helped creating this app ...
#AutoIt3Wrapper_Res_Description=AC3 Creator
#AutoIt3Wrapper_Res_LegalCopyright=© 2010 - HFR
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Fileversion=1.0
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/sf /q /kv 1 /bdir .
#AutoIt3Wrapper_Run_After="%scitedir%\AutoIt3Wrapper\ResHacker.exe" -add %out%, %out%, %scriptdir%\..\graphics\AC3Creator.jpg, rcdata, AC3Creator, 0
#AutoIt3Wrapper_Run_After="%scitedir%\AutoIt3Wrapper\ResHacker.exe" -add %out%, %out%, %scriptdir%\..\graphics\AC3Creator_label.jpg, rcdata, AC3Creator_label, 0
#AutoIt3Wrapper_Run_After="%scitedir%\AutoIt3Wrapper\ResHacker.exe" -add %out%, %out%, %scriptdir%\..\graphics\AC3Creator_msg.jpg, rcdata, AC3Creator_msg, 0
;ResHacker has to be finished before the exe will be compressed therefore I used ping to wait a second
#AutoIt3Wrapper_Run_After=ping -n 1 -w 3000 1.1.1.1 >NUL
#AutoIt3Wrapper_Run_After=..\..\AutoIt3\upx.exe --best --compress-resources=0 "%out%"
#AutoIt3Wrapper_Run_After=copy "%out%" "..\install\."
#AutoIt3Wrapper_Run_After=copy "%out%" "C:\Program Files\HFR\AC3 Creator\."
#endregion AutoIt3Wrapper directives section
;**** Directives created by AutoIt3Wrapper_GUI ****

#NoTrayIcon
#include <Constants.au3>
#include <EditConstants.au3>
#include <GUIConstants.au3>
#include <GuiConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GDIPlus.au3>
#include <WinAPI.au3>
#include <IE.au3>
#include <INet.au3>
#include <GuiListView.au3>
#include <GuiImageList.au3>
#include <GuiMenu.au3>
#include "..\..\AutoIt3\_UDF\Resources.au3"

Opt("MustDeclareVars", 1)

#region Global Variables
; ==============================================================================
Global $CUR_VER = "0.9.1"
Global $VERSION = "AC3-Creator " & $CUR_VER

;Global $WM_DROPFILES = 0x233
Global $HDL_GUI_MAIN, $HDL_BTN_CREATE, $HDL_BTN_BATCH, $HDL_BTN_EXIT, $HDL_BTN_BROWSE
Global $HDL_BATCH_GUI = 1, $HDL_BATCH_LST = 1, $HDL_BTN_RUN = 1, $HDL_BTN_CLOSE = 1, $BAT_RUN = False, $BAT_IDX = 0
Global $HDL_EDT_20, $HDL_EDT_51, $HDL_CBX_20, $HDL_CBX_51, $HDL_INP_FN, $HDL_OUT_FN_20, $HDL_OUT_FN_51
Global $HDL_LBL_20, $HDL_LBL_51, $HDL_CBX_LOG_20, $HDL_CBX_LOG_51

Global $HDL_MSG_BOX, $HDL_MSG_BTN_OK = 100

Global $EXT_ARY[3] = [".mp3", ".mp2", ".mpa"]

Global $BESWEET_OPT_20 = "-azid( -s stereo -L -3db ) -ota( -g 2db ) -ssrc( --rate 48000 ) -ac3enc( -b 448 ) "
Global $BESWEET_OPT_51 = "-azid( -L -3db -n1 -g max -c light ) -ota( -d 0 ) -ssrc( --rate 48000 ) -ac3enc( -b 448 -6ch ) "

Global $HKEY = "HKEY_LOCAL_MACHINE\SOFTWARE\HFR\AC3Creator"
Global $BESWEET_DIR = @ScriptDir & "/BeSweet"
#endregion Global Variables

#region Main Functions
Main()

; ==============================================================================
Func ExitProg()
	RegistryWrite()
	Exit
EndFunc   ;==>ExitProg

; ==============================================================================
; Main Function
; ==============================================================================
Func Main()
	Local $msg
	CreateMainGui()
	setInpFields(RegistryRead())

	While 1
		$msg = GUIGetMsg(1)
		Select
			Case $msg[0] = $HDL_CBX_LOG_20 Or $msg[0] = $HDL_CBX_LOG_51 Or $msg[0] = $HDL_CBX_20 Or $msg[0] = $HDL_CBX_51 Or $msg[0] = $GUI_EVENT_DROPPED
				setInpFields(GUICtrlRead($HDL_INP_FN))
			Case $msg[0] = $HDL_BTN_BROWSE
				browseFolder("SingleMode")
			Case $msg[0] = $HDL_BTN_CREATE
				runBesweet()
			Case $msg[0] = $HDL_BTN_BATCH
				BatchGui()
			Case ($msg[0] = $GUI_EVENT_CLOSE And $msg[1] = $HDL_BATCH_GUI) Or $msg[0] = $HDL_BTN_CLOSE
				GUIDelete($HDL_BATCH_GUI)
			Case ($msg[0] = $HDL_BTN_RUN And $msg[1] = $HDL_BATCH_GUI And $BAT_RUN = False)
				$BAT_RUN = True
				RunBatchJob()
			Case ($msg[0] = $HDL_BTN_RUN And $msg[1] = $HDL_BATCH_GUI And $BAT_RUN = True)
				$BAT_RUN = False
			Case ($msg[0] = $GUI_EVENT_CLOSE And $msg[1] = $HDL_MSG_BOX) Or $msg[0] = $HDL_MSG_BTN_OK
				GUIDelete($HDL_MSG_BOX)
			Case ($msg[0] = $GUI_EVENT_CLOSE And $msg[1] = $HDL_GUI_MAIN) Or $msg[0] = $HDL_BTN_EXIT
				ExitProg()
		EndSelect
	WEnd
EndFunc   ;==>Main
#endregion Main Functions

#region Sub Functions
; ==============================================================================
Func browseFolder($mode)
	Local $str = GUICtrlRead($HDL_INP_FN)
	Local $old = $str
	Local $i
	Local $extStr = ""

	; only extensions like mp3, mp2 and mpa are valid
	For $i = 0 To UBound($EXT_ARY) - 1
		$extStr = $extStr & "*" & $EXT_ARY[$i] & "; "
	Next

	Local $var = FileOpenDialog("Choose a file", $str, "MPEG Files (" & $extStr & ")", 1 + 4)

	If $mode = "SingleMode" Then
		If @error Then
			GUICtrlSetData($HDL_INP_FN, $old)
		Else
			$var = StringReplace($var, "|", @CRLF)
			GUICtrlSetData($HDL_INP_FN, "")
			GUICtrlSetData($HDL_INP_FN, $var)
			setInpFields(GUICtrlRead($HDL_INP_FN))
		EndIf
	ElseIf $mode = "BatchMode" Then
		$var = StringReplace($var, "|", @CRLF)
		Local $idx = _GUICtrlListView_AddItem($HDL_BATCH_LST, "")
		_GUICtrlListView_AddSubItem($HDL_BATCH_LST, $idx, $var, 1, 1)
	EndIf
EndFunc   ;==>browseFolder

; ==============================================================================
Func GetDroppedFiles($gaDropFiles)
	Local $path, $nbrFiles, $idx

	$nbrFiles = UBound($gaDropFiles) - 1
	For $i = 0 To $nbrFiles
		If (FileExists($gaDropFiles[$i])) Then
			$path = $gaDropFiles[$i]
			$idx = _GUICtrlListView_AddItem($HDL_BATCH_LST, "tbd", -1)
			_GUICtrlListView_AddSubItem($HDL_BATCH_LST, $idx, $path, 1, 1)
		EndIf
	Next
EndFunc   ;==>GetDroppedFiles

; ==============================================================================
Func ListRightClick()
	Local Enum $idMnu01 = 900, $idMnu02
	Local $aHit = _GUICtrlListView_SubItemHitTest($HDL_BATCH_LST)
	Local $nextNe = _GUICtrlListView_GetItemTextArray($HDL_BATCH_LST, -1)

	Local $hMenu = _GUICtrlMenu_CreatePopup()
	_GUICtrlMenu_AddMenuItem($hMenu, "Add List Entry", $idMnu01)
	_GUICtrlMenu_AddMenuItem($hMenu, "Remove List Entry", $idMnu02)

	Switch _GUICtrlMenu_TrackPopupMenu($hMenu, $HDL_BATCH_LST, -1, -1, 1, 1, 2)
		Case $idMnu01
			browseFolder("BatchMode")
		Case $idMnu02
			_GUICtrlListView_DeleteItemsSelected($HDL_BATCH_LST)
	EndSwitch
	_GUICtrlMenu_DestroyMenu($hMenu)
EndFunc   ;==>ListRightClick

; ==============================================================================
Func LoopInter()
	If GUIGetMsg() = $HDL_BTN_RUN Then $BAT_RUN = False
EndFunc   ;==>LoopInter

; ==============================================================================
Func ReplaceExtension($inp, $out)
	Local $str = ""

	For $i = 0 To UBound($EXT_ARY) - 1
		If (StringInStr($inp, $EXT_ARY[$i])) Then
			$str = StringReplace($inp, $EXT_ARY[$i], $out)
			Return ($str)
		EndIf
	Next
	Return ($str)
EndFunc   ;==>ReplaceExtension

; ==============================================================================
Func RunBatchJob()
	Local $cnt = _GUICtrlListView_GetItemCount($HDL_BATCH_LST)

	GUICtrlSetData($HDL_BTN_RUN, "Stop")
	AdlibRegister("LoopInter", 50)
	For $i = $BAT_IDX To $cnt - 1
		If $BAT_RUN = False Then
			GUICtrlSetData($HDL_BTN_RUN, "Run")
			Return
		EndIf
		Local $itemTextAry = _GUICtrlListView_GetItemTextArray($HDL_BATCH_LST, $BAT_IDX)
		_GUICtrlListView_SetItemFocused($HDL_BATCH_LST, $BAT_IDX)
		_GUICtrlListView_SetItemSelected($HDL_BATCH_LST, $BAT_IDX)
		setInpFields($itemTextAry[2])
		If $BAT_IDX = $cnt - 1 Then $BAT_RUN = False
		Local $rc = runBesweet()
		If $rc = -1 Then
			_GUICtrlListView_SetItem($HDL_BATCH_LST, "nok", $BAT_IDX, 0, 1)
		Else
			_GUICtrlListView_SetItem($HDL_BATCH_LST, "ok", $BAT_IDX, 0, 2)
		EndIf
		$BAT_IDX += 1
	Next
	AdlibUnRegister("LoopInter")
	GUICtrlSetData($HDL_BTN_RUN, "Run")
EndFunc   ;==>RunBatchJob

; ==============================================================================
Func runBesweet()
	Local $cmd, $begin, $dif
	Local $inpFn, $outFn_20, $outFn_51

	$inpFn = GUICtrlRead($HDL_INP_FN)
	$outFn_51 = StringReplace($inpFn, ".mp3", "_51.ac3")
	$outFn_20 = StringReplace($inpFn, ".mp3", "_20.ac3")

	If BitAND(GUICtrlRead($HDL_CBX_20), $GUI_CHECKED) Then
		$cmd = GUICtrlRead($HDL_EDT_20)
		If (FileExists($inpFn)) Then
			$begin = TimerInit()
			GUICtrlSetData($HDL_LBL_20, "Command Line: BeSweet started, please wait ...")
			RunWait($BESWEET_DIR & "\" & $cmd)
			$dif = TimerDiff($begin)
			$dif = StringFormat("%.2f", $dif / 1000)
			GUICtrlSetData($HDL_LBL_20, "Command Line: BeSweet finished in " & $dif & " seconds.")
		Else
			MsgBox(64, "AC3Creator", "File not found: " & @CRLF & GUICtrlRead($HDL_INP_FN))
			Return (-1)
		EndIf
	EndIf

	If (BitAND(GUICtrlRead($HDL_CBX_51), $GUI_CHECKED)) Then
		$cmd = GUICtrlRead($HDL_EDT_51)
		If (FileExists($outFn_20)) Then
			$begin = TimerInit()
			GUICtrlSetData($HDL_LBL_51, "Command Line: BeSweet started, please wait ...")
			RunWait($BESWEET_DIR & "\" & $cmd)
			$dif = TimerDiff($begin)
			$dif = StringFormat("%.2f", $dif / 1000)
			GUICtrlSetData($HDL_LBL_51, "Command Line: BeSweet finished in " & $dif & " seconds.")
		Else
			MsgBox(64, "AC3Creator", "File not found: " & @CRLF & $outFn_20)
			Return (-1)
		EndIf
	EndIf
	If $BAT_RUN = False Then GUICtrlSetState($HDL_INP_FN, $GUI_FOCUS)
	If $BAT_RUN = False Then MsgBoxGui("AC3 Creator Message", "Message: BeSweet was finished successfully. Please check also the logfiles.")
EndFunc   ;==>runBesweet

; ==============================================================================
Func setInpFields($inpFn)
	Local $outFn_20, $outFn_51, $str, $logFn_20, $logFn_51

	GUICtrlSetData($HDL_INP_FN, $inpFn)
	$outFn_20 = ReplaceExtension($inpFn, "_20.ac3")
	$outFn_51 = ReplaceExtension($inpFn, "_51.ac3")

	; Handle the 2.0 section
	If BitAND(GUICtrlRead($HDL_CBX_20), $GUI_CHECKED) Then
		If BitAND(GUICtrlRead($HDL_CBX_LOG_20), $GUI_CHECKED) Then
			$logFn_20 = StringReplace($inpFn, ".mp3", ".log")
			$logFn_20 = " -logfilea " & '"' & $logFn_20 & '"'
		Else
			$logFn_20 = ""
		EndIf
		GUICtrlSetData($HDL_OUT_FN_20, $outFn_20)
		$str = "BeSweet.exe -core( -input " & '"' & $inpFn & '"' & " -output " & '"' & $outFn_20 & '"' & $logFn_20 & " ) " & $BESWEET_OPT_20
		GUICtrlSetData($HDL_EDT_20, $str)
	Else
		GUICtrlSetData($HDL_EDT_20, "")
		GUICtrlSetData($HDL_OUT_FN_20, "")
	EndIf

	; Handle the 5.1 section
	If BitAND(GUICtrlRead($HDL_CBX_51), $GUI_CHECKED) Then
		If BitAND(GUICtrlRead($HDL_CBX_LOG_51), $GUI_CHECKED) Then
			$logFn_51 = StringReplace($inpFn, ".mp3", ".log")
			$logFn_51 = " -logfilea " & '"' & $logFn_51 & '"'
		Else
			$logFn_51 = ""
		EndIf
		GUICtrlSetData($HDL_OUT_FN_51, $outFn_51)
		$str = "BeSweet.exe -core( -input " & '"' & $outFn_20 & '"' & " -output " & '"' & $outFn_51 & '"' & $logFn_51 & " ) " & $BESWEET_OPT_51
		GUICtrlSetData($HDL_EDT_51, $str)
	Else
		GUICtrlSetData($HDL_EDT_51, "")
		GUICtrlSetData($HDL_OUT_FN_51, "")
	EndIf
	If $BAT_RUN = False Then GUICtrlSetState($HDL_INP_FN, $GUI_FOCUS)
EndFunc   ;==>setInpFields
#endregion Sub Functions

#region Event Functions
; ==============================================================================
Func WM_DROPFILES_FUNC($hWnd, $MsgID, $wParam, $lParam)
	Local $nSize, $pFileName
	Local $nAmt = DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", 0xFFFFFFFF, "ptr", 0, "int", 255)
	Local $gaDropFiles[1]

	For $i = 0 To $nAmt[0] - 1
		$nSize = DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", $i, "ptr", 0, "int", 0)
		$nSize = $nSize[0] + 1
		$pFileName = DllStructCreate("char[" & $nSize & "]")
		DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", $i, "ptr", DllStructGetPtr($pFileName), "int", $nSize)
		ReDim $gaDropFiles[$i + 1]
		$gaDropFiles[$i] = DllStructGetData($pFileName, 1)
		$pFileName = 0
	Next
	GetDroppedFiles($gaDropFiles)
EndFunc   ;==>WM_DROPFILES_FUNC

; ==============================================================================
Func WM_NOTIFY($hWnd, $msg, $wParam, $lParam)
	Local $hWndFrom, $iIDFrom, $code, $tNMHDR, $hWndListView, $tInfo, $tNMLISTVIEW

	$hWndListView = $HDL_BATCH_LST
	If Not IsHWnd($HDL_BATCH_LST) Then $hWndListView = GUICtrlGetHandle($HDL_BATCH_LST)
	$tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$code = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $hWndListView
			Switch $code
				Case $NM_RCLICK ; right mouse to get the context menu
					ListRightClick()
					Return 0
				Case $LVN_COLUMNCLICK ; A column was clicked
					Local $tInfo = DllStructCreate($tagNMLISTVIEW, $lParam)
					;_GUICtrlListView_SimpleSort($HDL_BATCH_LST, $B_DESCENDING, DllStructGetData($tInfo, "SubItem"))
				Case $NM_DBLCLK
					;NlsDoubleClick()
					Return 0
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY
#endregion Event Functions

#region GUI
; ==============================================================================
Func BatchGui()
	Local $size = WinGetPos($HDL_GUI_MAIN)

	$HDL_BATCH_GUI = GUICreate("Batch Mode", 450, 350, $size[0] + 250, $size[1] + 150, $GUI_SS_DEFAULT_GUI, $WS_EX_ACCEPTFILES)
	GUISetIcon(@ScriptDir & "\..\graphics\AC3Creator.ico")
	GUISetBkColor(0x00D8D8E7)
	_GUICtrlCreatePic(@ScriptDir & "\..\graphics\AC3Creator_msg.jpg", 0, 0, 450, 60)


	$HDL_BATCH_LST = _GUICtrlListView_Create($HDL_BATCH_GUI, "Status|Files to be converted", 10, 70, 430, 230, -1, BitOR($WS_EX_CLIENTEDGE, $WS_EX_STATICEDGE))
	_GUICtrlListView_SetColumnWidth($HDL_BATCH_LST, 0, 50)
	_GUICtrlListView_SetColumnWidth($HDL_BATCH_LST, 1, 600)
	_GUICtrlListView_SetExtendedListViewStyle($HDL_BATCH_LST, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT))

	; Load images
	Local $hImage = _GUIImageList_Create(16, 16, 5, 3)
	_GUIImageList_AddIcon($hImage, @SystemDir & "\shell32.dll", 225)
	_GUIImageList_AddIcon($hImage, @SystemDir & "\shell32.dll", 131)
	_GUIImageList_AddIcon($hImage, @SystemDir & "\shell32.dll", 146)
	_GUICtrlListView_SetImageList($HDL_BATCH_LST, $hImage, 1)

	$HDL_BTN_RUN = GUICtrlCreateButton("Run", 270, 310, 80)
	$HDL_BTN_CLOSE = GUICtrlCreateButton("Close", 360, 310, 80)

	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
	GUIRegisterMsg($WM_DROPFILES, "WM_DROPFILES_FUNC") ; drag 'n drop function
	GUISetState()
EndFunc   ;==>BatchGui

; ==============================================================================
Func CreateMainGui()
	;------------
	; Main Window
	$HDL_GUI_MAIN = GUICreate($VERSION, 600, 480, -1, -1, -1, $WS_EX_ACCEPTFILES)
	GUISetIcon(@ScriptDir & "\..\graphics\AC3Creator.ico")
	GUISetBkColor(0x00D8D8E7)
	_GUICtrlCreatePic(@ScriptDir & "\..\graphics\AC3Creator.jpg", 0, 0, 600, 80)
	_GUICtrlCreatePic(@ScriptDir & "\..\graphics\AC3Creator_label.jpg", 10, 450, 231, 17)

	$HDL_INP_FN = GUICtrlCreateInput("", 10, 95, 510, 20)
	GUICtrlSetState($HDL_INP_FN, $GUI_DROPACCEPTED)
	$HDL_BTN_BROWSE = GUICtrlCreateButton("Input", 530, 93, 60)

	$HDL_CBX_20 = GUICtrlCreateCheckbox("Create Stereo 2.0 file (Dolby Digital)", 10, 130)
	GUICtrlSetState($HDL_CBX_20, $GUI_CHECKED)
	$HDL_CBX_LOG_20 = GUICtrlCreateCheckbox("Logfile", 250, 130)
	$HDL_OUT_FN_20 = GUICtrlCreateInput("", 10, 151, 580, 20)
	$HDL_LBL_20 = GUICtrlCreateLabel("Command Line:", 10, 177, 300, 20)
	GUICtrlSetColor($HDL_LBL_20, 0x99540A)
	$HDL_EDT_20 = GUICtrlCreateEdit("", 10, 195, 580, 80, $ES_AUTOVSCROLL)
	GUICtrlSetColor($HDL_EDT_20, 0x8E8E8E)

	$HDL_CBX_51 = GUICtrlCreateCheckbox("Create Surround 5.1 file (DTS)", 10, 290)
	GUICtrlSetState($HDL_CBX_51, $GUI_CHECKED)
	$HDL_CBX_LOG_51 = GUICtrlCreateCheckbox("Logfile", 250, 290)
	$HDL_OUT_FN_51 = GUICtrlCreateInput("", 10, 311, 580, 20)
	$HDL_LBL_51 = GUICtrlCreateLabel("Command Line:", 10, 337, 300, 20)
	GUICtrlSetColor($HDL_LBL_51, 0x99540A)
	$HDL_EDT_51 = GUICtrlCreateEdit("", 10, 355, 580, 80, $ES_AUTOVSCROLL)
	GUICtrlSetColor($HDL_EDT_51, 0x8E8E8E)

	$HDL_BTN_CREATE = GUICtrlCreateButton("Create AC3", 330, 445, 80)
	$HDL_BTN_BATCH = GUICtrlCreateButton("Batch", 420, 445, 80)
	$HDL_BTN_EXIT = GUICtrlCreateButton("Exit", 510, 445, 80)

	GUISetState()
EndFunc   ;==>CreateMainGui

; ==============================================================================
Func MsgBoxGui($title, $text)
	If $HDL_MSG_BOX > 0 Then GUIDelete($HDL_MSG_BOX)
	$HDL_MSG_BOX = GUICreate($title, 450, 160)
	GUISetIcon(@ScriptDir & "\..\graphics\AC3Creator.ico")
	GUISetBkColor(0x00D8D8E7)
	_GUICtrlCreatePic(@ScriptDir & "\..\graphics\AC3Creator_msg.jpg", 0, 0, 450, 60)
	GUICtrlCreateLabel($text, 10, 75, 380, 20)
	$HDL_MSG_BTN_OK = GUICtrlCreateButton("OK", 185, 125, 80, 25)
	GUISetState(@SW_SHOW)
	;TracePrint( $HDL_MSG_BOX )
EndFunc   ;==>MsgBoxGui
#endregion GUI

#region Utility Functions
; ==============================================================================
Func RegistryRead()
	Local $inpFn = RegRead($HKEY, "InputFn")
	If @error Then
		$inpFn = @ScriptDir
	EndIf
	Return ($inpFn)
EndFunc   ;==>RegistryRead

; ==============================================================================
Func RegistryWrite()
	Local $str = GUICtrlRead($HDL_INP_FN)
	RegWrite($HKEY, "InputFn", "REG_SZ", $str)
EndFunc   ;==>RegistryWrite

; ==============================================================================
Func TracePrint($s_text, $line = @ScriptLineNumber)
	ConsoleWrite( _
			"-->Line(" & StringFormat("%04d", $line) & "):" & @TAB & $s_text & @LF)
EndFunc   ;==>TracePrint
#endregion Utility Functions
; ==================================================================== EOF =====

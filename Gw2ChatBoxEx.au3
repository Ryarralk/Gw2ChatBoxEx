#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=gw2_icon.ico
#AutoIt3Wrapper_Outfile=Gw2 ChatBoxEx.exe
#AutoIt3Wrapper_Res_Description=Gw2 - ChatBoxEx is a enhanced chatbox for Guild Wars 2
#AutoIt3Wrapper_Res_Fileversion=1.0
#AutoIt3Wrapper_Res_ProductName=Gw2 - ChatBoxEx
#AutoIt3Wrapper_Res_ProductVersion=1.1
#AutoIt3Wrapper_Res_LegalCopyright=MIT
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WinAPISysWin.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#include <Array.au3>

If Not _Singleton(@ScriptName, 1) Then
	If @OSLang == "040C" Then
		MsgBox(16,"Gw2 - ChatBoxEx : Erreur", "Gw2 - ChatBoxEx est déjà lancé.")
	Else
		MsgBox(16,"Gw2 - ChatBoxEx : Error", "Gw2 - ChatBoxEx is already running")
	EndIf
	Exit
EndIf

;Change le temps entre les touches en milliseconde (0 : Aucun delais. Défaut : 5)
AutoItSetOption("SendKeyDelay", 0)
HotKeySet("+{ENTER}", "HotKeyPressed")
HotKeySet("{ESC}", "HotKeyPressed")
HotKeySet("+{ESC}", "HotKeyPressed")
HotKeySet("+{BACKSPACE}", "HotKeyPressed")

Global $hDLL = DllOpen("user32.dll")
$bWriting = False

$pList = ProcessList("Gw2-64.exe")
$GwPID = -1

If $pList[0][0] <> 0 Then
	$GwPID = $pList[1][1]
Else
	If @OSLang == "040C" Then
		MsgBox(16,"Gw2 - ChatBoxEx : Erreur", "Guild Wars 2 n'a pas été trouvé dans la liste des processus !" & @CRLF & "Vérifiez que le jeu est bien lancé.")
	Else
		MsgBox(16,"Gw2 - ChatBoxEx : Error", "Guild Wars 2 was not found in the list of processes!" & @CRLF & "Make sure the game is running.")
	EndIf
	Terminate()
EndIf

$hWnd = WinWait("Guild Wars 2", "", 10)
$cSize = WinGetClientSize($hWnd)

While 1
	Sleep (100)
	if Not ProcessExists($GwPID) Then Terminate()
WEnd

Func HotKeyPressed()

	Switch @HotKeyPressed
		Case "+{ENTER}"
			If WinActive("Guild Wars 2") And $bWriting = False Then
				NewChatbox($cSize, $hDLL)
			EndIf
		Case "{ESC}"
			If WinGetTitle("ChatBoxEx") Then
				GUIDelete()
			EndIf
		Case "+{ESC}"
			If WinGetTitle("ChatBoxEx") Then
				GUIDelete()
			EndIf
			Terminate()
		;Stop the the actual writing at the last segment
		Case "+{BACKSPACE}"
			$bWriting = False
	EndSwitch
EndFunc


Func Terminate()
	DllClose($hDLL)
	SoundPlay(@WindowsDir & "\media\windows background.wav",1)
	Exit
EndFunc

;Return len of an Array - Does the same as Ubound, but at least, I know exactly what I get
Func ArrayLength($aArray)

	$len = 0

	For $i In $aArray
		$len += 1
	Next

	Return $len
EndFunc

;Count number of a specific character in a char array
Func ArrayCountChar($aArray, $cChar)

	$iCount = 0

	For $i = 0 To (ArrayLength($aArray) - 1)
		If $aArray[$i] == $cChar Then
			$iCount += 1
		EndIf
	Next

	Return $iCount

EndFunc

;Do the final check of the string to make it readable and write it in the chat of the game
Func SendMsg($sFinal)

	If Not WinActive("Guild Wars 2") Then
		WinActivate("Guild Wars 2")
	EndIf

	$sFinal = StringReplace($sFinal, "!", "{!}")
	$sFinal = StringReplace($sFinal, "#", "{#}")
	$sFinal = StringReplace($sFinal, "+", "{+}")
	$sFinal = StringReplace($sFinal, "^", "{^}")

	Send("{ENTER}")
	Sleep(5)
	Send($sFinal)
	Send("{ENTER}")
	Sleep(5)

EndFunc

;Generate ChatBoxEx when Shift+Enter is triggered in the application
Func NewChatbox(ByRef $cSize, ByRef $hDLL)

	If WinExists("ChatBoxEx") Then
		WinActivate("ChatBoxEx")
	Else
		Local $gHeight = Round($cSize[1] * 10.4 / 100)
		Local $gWidth = Round($cSize[0] * 31.25 / 100)

		$ChatBoxEx = GUICreate("ChatBoxEx", $gWidth, $gHeight, Round($cSize[0] / 2 - $gWidth / 2), $cSize[1] - ($gHeight + 40), BitOR($WS_POPUP, $WS_EX_TOPMOST))
		$EditBox = GUICtrlCreateEdit("", 0, 0, $gWidth - 1, $gHeight - 1, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_VSCROLL))
		GUICtrlSetFont(-1, 14, 800, 0, "Consolas")
		GUICtrlSetColor(-1, 0xFFFFFF)
		GUICtrlSetBkColor(-1, 0x101A1A)
		GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

		GUISetState(@SW_SHOW)

		While 1

			If Not WinExists("ChatBoxEx") Then
				ExitLoop
			EndIf
			If _IsPressed( "0D", $hDLL) And WinActive("ChatBoxEx") And Not _IsPressed( "10", $hDLL) Then
				$lText = GUICtrlRead($EditBox)
				WriteText($lText)
				GUIDelete($ChatBoxEx)
				ExitLoop
			EndIf
		WEnd
	EndIf

EndFunc

;Main function writing the text from the Edit of the ChatBox to the application
Func WriteText(ByRef $lText)

	Local $aString = StringSplit($lText, "")
	Local $iLenght = 0
	Local $sBuffer = ""
	Local $aBuffer[0]
	Local $sEmote = ""
	Local $bFirstPass = True
	Local Const $aPonctuation = ["?", ",", ";", ".", ":", "!", "*", ">"]

	If $aString[0] = "0" Then
		Return
	EndIf

	$bWriting = True

	_ArrayDelete($aString, "0;"&String(UBound($aString) - 2)&";"&String(UBound($aString) - 1) )

	;While main array not removed completely (removes it a bit after each writing segments)
	While ArrayLength($aString) > 0 And $bWriting = True

		;If text < 199 char send without modification
		If ArrayLength($aString) < 199 Then

			$sBuffer &= _ArrayToString($aString, "")
			_ArrayDelete($aString, "0-"&(ArrayLength($aString) - 1))
			SendMsg($sBuffer)

			For $s = 1 To StringLen($sBuffer)
				If $bWriting = False Then ExitLoop
				Sleep(50)
			Next

		;Else if text have at least one space
		ElseIf ArrayCountChar($aString, " ") > 0 And _ArraySearch($aString, " ") < 185 Then

			;Keep the index of last, current and future space (if ponctuation detected after current space (and the last of the segment)
			Local $iSpaceLast = -1
			Local $iSpace = -1
			Local $iSpaceNext = -1

			;Check for emotes
			If $bFirstPass = True Then
				If $aString[0] == "/" Then
					$sEmote = _ArrayToString($aString, "", 0, _ArraySearch($aString, " "))
				EndIf
			EndIf

			;Get the last two spaces of the text segment, iSpaceLast = -1 if there's only one space
			For $i = 0 To 185
				If $aString[$i] == " " Then
					$iSpaceLast = $iSpace
					$iSpace = $i
				EndIf
			Next

			;Check for ponctuation after iSpace
			For $i = 0 To (ArrayLength($aPonctuation) - 1)

				If $aString[$iSpace + 1] = $aPonctuation[$i] Then

					For $j = $iSpace + 1 To 190
						If $aString[$j] = " " Then
							$iSpaceNext = $j
						EndIf
					Next
					ExitLoop
				EndIf
			Next

			;If iSpaceNext != 1 then go for iSpaceNext, Elif no other space but iSpaceLast != -1 then back to iSpaceLast, Else go full monke !
			If $iSpaceNext <> -1 Then
				$iSpace = $iSpaceNext
			ElseIf $iSpaceNext = -1 And $iSpaceLast <> -1 Then
				$iSpace = $iSpaceLast
			Else
				$iSpace = 190
			EndIf

			$sBuffer &= _ArrayToString($aString, "", 0, $iSpace)
			$sBuffer &= "--"
			_ArrayDelete($aString, "0-"&$iSpace)
			SendMsg($sBuffer)

			;I've made this to kill the sleep faster in case of pressing shift + bacckspace
			For $s = 1 To StringLen($sBuffer)
				If $bWriting = False Then ExitLoop
				Sleep(50)
			Next

			$sBuffer = $sEmote & "-- "

		;Else the text has no space
		Else

			If $bFirstPass = True Then
				If $aString[0] == "/" Then
					$sEmote = _ArrayToString($aString, "", 0, _ArraySearch($aString, " "))
				EndIf
			EndIf

			$sBuffer &= _ArrayToString($aString, "", 0, 191)
			$sBuffer &= "--"
			_ArrayDelete($aString, "0-191")
			SendMsg($sBuffer)

			;I've made this to kill the sleep faster in case of pressing shift + bacckspace
			For $s = 1 To StringLen($sBuffer)
				If $bWriting = False Then ExitLoop
				Sleep(50)
			Next

			$sBuffer = $sEmote & "--"

		EndIf

		$bFirstPass = False

	Wend

	If $bWriting = False Then
		SoundPlay(@WindowsDir & "\media\windows foreground.wav")
	EndIf

	$bWriting = False

EndFunc
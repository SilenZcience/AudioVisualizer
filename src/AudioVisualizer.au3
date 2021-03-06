#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Outfile=..\bin\AudioVisualizer.exe
#AutoIt3Wrapper_Res_Comment=Simple AudioVisualizer made in AutoIt
#AutoIt3Wrapper_Res_Description=AudioVisualizer
#AutoIt3Wrapper_Res_Fileversion=1.0.0.3
#AutoIt3Wrapper_Res_ProductName=AudioVisualizer
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.3
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "lib/Bass.au3"
#include "lib/BassConstants.au3"
#include <Color.au3>
#include <misc.au3>
#include <GDIPlus.au3>
#include <Array.au3>
#include <File.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>

If _Singleton("AudioVisualizerSilasKraume", 1) == 0 Then Exit MsgBox($MB_SYSTEMMODAL, "Error", "An occurrence of 'AudioVisualizer' by Silas Kraume is already running!", 2)

Opt("GUIOnEventMode", 1)
Opt("MustDeclareVars", 1)

_Init_Bass()

OnAutoItExitRegister("_close_reg")

Global $SongArray[0]
Global $SongArrayIndex = -1
Global $SongStateLast = 0
Global $SongStateNow = 0
Global $SoundSet = 2
Global Const $PI = 3.14159265358979323

Global $BASS_PAUSE_POS
Global Const $ResizeFactor = (@DesktopWidth/1920)
Global Const $MoveFactor = Int((@DesktopWidth - 1920)/2)
Global Const $width = @DesktopWidth + 2
Global Const $height = @DesktopHeight + 42
Global $hwnd = GUICreate("AudioVisualizer", $width, $height, -1, -1, $WS_POPUP, $WS_EX_ACCEPTFILES)

GUISetOnEvent(-3, "_close", $hwnd)
GUIRegisterMsg(563, "WM_DROPFILES_FUNC")
GUIRegisterMsg(0x020A, "_Mousewheel")
GUISetState(@SW_SHOW, $hwnd)

SoundSetWaveVolume($SoundSet)

_GDIPlus_Startup()
Global Const $graphics = _GDIPlus_GraphicsCreateFromHWND($hwnd)
Global Const $bitmap = _GDIPlus_BitmapCreateFromGraphics($width, $height, $graphics)
Global Const $vizbitmap = _GDIPlus_BitmapCreateFromGraphics($width, $height, $graphics)
Global Const $backbuffer = _GDIPlus_ImageGetGraphicsContext($bitmap)
Global Const $vizbuffer = _GDIPlus_ImageGetGraphicsContext($vizbitmap)

Global Const $family = _GDIPlus_FontFamilyCreate("Arial")
Global Const $font = _GDIPlus_FontCreate($family, 26 * (@DesktopWidth/1920))
Global Const $format = _GDIPlus_StringFormatCreate()
_GDIPlus_StringFormatSetAlign($format, 1)
Global Const $rect = _GDIPlus_RectFCreate(0, 150, $width, $height)
Global $WhiteTransBrushes[256]
For $i = UBound($WhiteTransBrushes) - 1 To 0 Step -1
	$WhiteTransBrushes[$i] = _GDIPlus_BrushCreateSolid("0x" & Hex($i, 2) & "FFFFFF")
Next

_GDIPlus_GraphicsSetSmoothingMode($backbuffer, 2)
_GDIPlus_GraphicsSetSmoothingMode($vizbuffer, 2)

Global $HexTimeColor[2] = [-1, -1]
$HexTimeColor[0] = Hex(Int((@HOUR * 255) / 24), 2) & Hex(Int((@MIN * 255) / 60), 2) & Hex(Int((@SEC * 255) / 60), 2)
Global $aColor = _ColorGetRGB("0x" & $HexTimeColor[0])
$HexTimeColor[1] = Hex(255 - $aColor[0], 2) & Hex(255 - $aColor[1], 2) & Hex(255 - $aColor[2], 2)

Global $Delete = False
Global $Fade = True ;0/1 of 2
Global $FadeAmount = 16
Global $blacktrans = _GDIPlus_BrushCreateSolid("0x" & Hex($FadeAmount, 2) & "000000")
Global $OverallX = 0
Global $OverallY = 0

Global $SinPen1, $SinPen2
Global $Sin = False
Global $Sin1 = True
Global $Sin2 = True
Global $SinFrom1 = 0
Global $SinTo1 = $width / 2 + 5
Global $SinFrom2 = $width
Global $SinTo2 = $width / 2
Global $Sin1Amp = 6
Global $Sin2Amp = 6
Global $Sin1Colortime = 2 ;0=static, 1=colortime, 2=colortimeinverted
Global $Sin2Colortime = 1 ;0=static, 1=colortime, 2=colortimeinverted
Global $Sin1Color = "00FF00"
Global $Sin2Color = "00FF00"
If $Sin1Colortime == 1 Then
    $SinPen1 = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[0], 2)
ElseIf $Sin1Colortime == 2 Then
    $SinPen1 = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[1], 2)
Else
    $SinPen1 = _GDIPlus_PenCreate("0xFF" & $Sin1Color, 2)
EndIf
If $Sin2Colortime == 1 Then
    $SinPen2 = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[0], 2)
ElseIf $Sin2Colortime == 2 Then
    $SinPen2 = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[1], 2)
Else
    $SinPen2 = _GDIPlus_PenCreate("0xFF" & $Sin2Color, 2)
EndIf

Global $Circle = True
Global $CircleSeed = Random(0, 10000, 1)
Global $CircleAmountFrom = 100
Global $CircleAmounTo = 500
Global $CircleIndexTo = 50
Global $CircleSize = 30
Global $CircleColortime = 0 ;0=static, 1=colortime, 2=colortimeinverted
Global $CircleColor = "FF0000"
Global $CircleBrush
If $CircleColortime == 1 Then
    $CircleBrush = _GDIPlus_BrushCreateSolid("0xFF" & $HexTimeColor[0])
ElseIf $CircleColortime == 2 Then
    $CircleBrush = _GDIPlus_BrushCreateSolid("0xFF" & $HexTimeColor[1])
Else
    $CircleBrush = _GDIPlus_BrushCreateSolid("0xFF" & $CircleColor)
EndIf

Global $TrianglePen
Global $Triangle = True
Global $TriangleGroundAnglePlus = 0 ;$PI/50
Global $TriangleGroundAngle = 0;$PI/2
Global $TriangleSize = 200
Global $TriangleColortime = 0 ;0=static, 1=colortime, 2=colortimeinverted
Global $TriangleColor = "FF0000"
If $TriangleColortime == 1 Then
    $TrianglePen = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[0], 2)
ElseIf $TriangleColortime == 2 Then
    $TrianglePen = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[1], 2)
Else
    $TrianglePen = _GDIPlus_PenCreate("0xFF" & $TriangleColor, 2)
EndIf

Global $UseDeviceSound = False
Global $SoundDeviceID = -1

Global $StreamHandle
Global $user32 = DllOpen("user32.dll")
Global $ID3 = "char id[3];char title[30];char artist[30];char album[30];char year[4];char comment[30];ubyte genre;"

Global $SongString = "Drag 'n drop audio file to start playback" ;"Audio Visualization with GDI+" & @CRLF & "Drag 'n drop audio file to start playback"
Global $SongStringOpacity = 255
Global $released = True

Global $b = DllStructCreate("float[128]")

Global $Timer1 = TimerInit()
Global $Timer2 = TimerInit()

While True
;~     Sleep(5)
	_ShowGraphics()

	If _IsPressed(02, $user32) And WinActive($hwnd) Then ;rightclick
		If _Get_playstate() == 2 and not $UseDeviceSound Then
			$BASS_PAUSE_POS = _BASS_ChannelGetPosition($StreamHandle, 0)
			If not @Compiled Then ConsoleWrite("Pause Position: " & $BASS_PAUSE_POS & @CRLF)
			_BASS_ChannelPause($StreamHandle)
		EndIf
		_GUIControl()
		If _Get_playstate() == 3 and not $UseDeviceSound Then
			_BASS_ChannelPlay($StreamHandle, 0)
		EndIf
	EndIf
	If $UseDeviceSound or Ubound($SongArray) == 0 Then ContinueLoop

	If _IsPressed(25, $user32) And WinActive($hwnd) And TimerDiff($Timer1) > 300 Then ;leftarrow
		If $SongArrayIndex > 0 Then $SongArrayIndex -= 1
        $SongArrayIndex -= 1
		_StartFile()
		$Timer1 = TimerInit()
	ElseIf _IsPressed(27, $user32) And WinActive($hwnd) And TimerDiff($Timer1) > 300 Then ;rightarrow
		If $SongArrayIndex < UBound($SongArray) - 1 Then _StartFile()
		$Timer1 = TimerInit()
	ElseIf _IsPressed(20, $user32) And WinActive($hwnd) And TimerDiff($Timer1) > 300 Then ;Space
		_Switch_AudioPlayback()
		$Timer1 = TimerInit()
	ElseIf TimerDiff($Timer2) > 750 Then
		$SongStateNow = _Get_playstate()
		If $SongStateNow == 1 And $SongArrayIndex < UBound($SongArray) - 1 Then _StartFile()
		If $SongStateNow <> $SongStateLast Then
			If not @Compiled Then ConsoleWrite("SongState: " & $SongStateNow & @CRLF)
			$SongStateLast = $SongStateNow
		EndIf
		$Timer2 = TimerInit()
	EndIf
WEnd

Func _Init_Bass()
    Local $bassPath = _PathFull("../dll/bass.dll")
    If not FileExists($bassPath) Then
        msgBox($MB_SYSTEMMODAL, "Error", "Couldn't find the bass.dll.")
        Exit
    EndIf
    _BASS_Startup($bassPath)
    _BASS_Init(0, -1, 44100, 0, "")
    _BASS_SetConfig($BASS_CONFIG_BUFFER, 1000)
    _BASS_RecordInit(-1)
EndFunc

Func _GUIControl()
	Opt("GUIOnEventMode", 0)
	Opt("GUICloseOnESC", 0)

	Local $hwidth = $width / 2
	Local $hheight = $height / 2
	Local $onethree = $hwidth * (1 / 3)
	Local $twothree = $hwidth * (2 / 3)

	;--------------------------------------------------------------------General
	Local $DeviceSoundOn = $UseDeviceSound
	Local $ModeState
	If $Delete Then
		$ModeState = "Delete"
	ElseIf $Fade Then
		$ModeState = "Fade"
	Else
		$ModeState = "Stay"
	EndIf
	Local $FadeStrength = $FadeAmount
	Local $XPos = $OverallX
	Local $YPos = $OverallY
	;---------------------------------------------------------------------------

	;--------------------------------------------------------------------Sinus
	Local $SinMode
	If $Sin Then
		$SinMode = "On"
	Else
		$SinMode = "Off"
	EndIf
	Local $Sin1Mode
	If $Sin1 Then
		$Sin1Mode = "On"
	Else
		$Sin1Mode = "Off"
	EndIf
	Local $Sin2Mode
	If $Sin2 Then
		$Sin2Mode = "On"
	Else
		$Sin2Mode = "Off"
	EndIf
	Local $Sin1From = $SinFrom1
	Local $Sin1To = $SinTo1
	Local $Sin2From = $SinFrom2
	Local $Sin2To = $SinTo2
	Local $SinStrength1 = $Sin1Amp
	Local $SinStrength2 = $Sin2Amp
	Local $Sin1ColorMode
	If $Sin1Colortime == 1 Then
		$Sin1ColorMode = "TimeColor"
	ElseIf $Sin1Colortime == 2 Then
		$Sin1ColorMode = "TimeColorInverted"
	Else
		$Sin1ColorMode = "StaticColor"
	EndIf
	Local $Sin2ColorMode
	If $Sin2Colortime == 1 Then
		$Sin2ColorMode = "TimeColor"
	ElseIf $Sin2Colortime == 2 Then
		$Sin2ColorMode = "TimeColorInverted"
	Else
		$Sin2ColorMode = "StaticColor"
	EndIf
	Local $Sin1StaticColor = $Sin1Color
	Local $Sin2StaticColor = $Sin2Color
	;-------------------------------------------------------------------------

	;--------------------------------------------------------------------Circle
	Local $CircleMode
	If $Circle Then
		$CircleMode = "On"
	Else
		$CircleMode = "Off"
	EndIf
	Local $CircleFromAmount = $CircleAmountFrom
	Local $CircleToAmount = $CircleAmounTo
	Local $CircleRandomness = $CircleIndexTo
	Local $CircleStrength = $CircleSize
	Local $CircleColorMode
	If $CircleColortime == 1 Then
		$CircleColorMode = "TimeColor"
	ElseIf $CircleColortime == 2 Then
		$CircleColorMode = "TimeColorInverted"
	Else
		$CircleColorMode = "StaticColor"
	EndIf
	Local $CircleStaticColor = $CircleColor
	;--------------------------------------------------------------------------

	;--------------------------------------------------------------------Triangle
	Local $TriangleMode
	If $Triangle Then
		$TriangleMode = "On"
	Else
		$TriangleMode = "Off"
	EndIf
	Local $TriangleAddAngle = Round(($TriangleGroundAnglePlus*180)/$PI)
	Local $TriangleAngle = Round(($TriangleGroundAngle*180)/$PI)
	Local $TriangleStrength = $TriangleSize
	Local $TriangleColorMode
	If $TriangleColortime == 1 Then
		$TriangleColorMode = "TimeColor"
	ElseIf $TriangleColortime == 2 Then
		$TriangleColorMode = "TimeColorInverted"
	Else
		$TriangleColorMode = "StaticColor"
	EndIf
	Local $TriangleStaticColor = $TriangleColor
	;----------------------------------------------------------------------------

	Local $hGUI = GUICreate("AudioVz-Control ~ Silas K.", $hwidth, $hheight, -1, -1, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
	GUISetBkColor(0x2B2B33, $hGUI)

	;--------------------------------------------------------------------TopLayer
	Local $idChangeMode = GUICtrlCreateButton("Change Mode", 10, 10, 125, 25)
	GUICtrlSetFont(-1, 11)
	Local $idModeLabel = GUICtrlCreateLabel($ModeState, 145, 13, 100, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $FadeLabel = GUICtrlCreateLabel("FadingStrength:", 255, 13, 100, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	If $ModeState <> "Fade" Then GUICtrlSetState(-1, $GUI_HIDE)
	Local $FadeStrengthInput = GUICtrlCreateInput($FadeStrength, 365, 10, 100, 25, $ES_NUMBER)
	GUICtrlSetFont(-1, 11)
	If $ModeState <> "Fade" Then GUICtrlSetState(-1, $GUI_HIDE)
	Local $XLabel = GUICtrlCreateLabel("X-Position: ", 510, 13, 65, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $XInput = GUICtrlCreateInput($XPos, 585, 10, 100, 25)
	GUICtrlSetFont(-1, 11)
	Local $YLabel = GUICtrlCreateLabel("Y-Position: ", 730, 13, 65, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $YInput = GUICtrlCreateInput($YPos, 805, 10, 100, 25)
	GUICtrlSetFont(-1, 11)
	;----------------------------------------------------------------------------

	;--------------------------------------------------------------------LeftLayer
	Local $SinSwitch = GUICtrlCreateButton("Waves:", 10, 55, 100, 25)
	GUICtrlSetFont(-1, 11)
	Local $SinLabel = GUICtrlCreateLabel($SinMode, 120, 58, 25, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)

	Local $Sin1Switch = GUICtrlCreateButton("Wave1:", 10, 90, 60, 25)
	GUICtrlSetFont(-1, 11)
	Local $Sin1Label = GUICtrlCreateLabel($Sin1Mode, 80, 93, 25, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $FromLabel1 = GUICtrlCreateLabel("From", 10, 128, 40, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $FromInput1 = GUICtrlCreateInput($Sin1From, 60, 125, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $ToLabel1 = GUICtrlCreateLabel("To", 120, 128, 25, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $ToInput1 = GUICtrlCreateInput($Sin1To, 155, 125, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $Sin1Position = GUICtrlCreateLabel("Position", 215, 128, 100, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $Strength1Label = GUICtrlCreateLabel("Strength", 10, 163, 55, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $Strength1Input = GUICtrlCreateInput($SinStrength1, 75, 160, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $Sin1ColorButton = GUICtrlCreateButton("Color Mode", 10, 195, 100, 25)
	GUICtrlSetFont(-1, 11)
	Local $Sin1ColorLabel = GUICtrlCreateLabel($Sin1ColorMode, 120, 198, 150, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $Sin1Static = GUICtrlCreateLabel("Color:", 10, 233, 40, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	If $Sin1ColorMode <> "StaticColor" Then GUICtrlSetState(-1, $GUI_HIDE)
	Local $Sin1ColorInput = GUICtrlCreateInput($Sin1StaticColor, 60, 230, 75, 25)
	GUICtrlSetFont(-1, 11)
	If $Sin1ColorMode <> "StaticColor" Then GUICtrlSetState(-1, $GUI_HIDE)


	Local $Sin2Switch = GUICtrlCreateButton("Wave2:", 10, $hheight / 2, 60, 25)
	GUICtrlSetFont(-1, 11)
	Local $Sin2Label = GUICtrlCreateLabel($Sin2Mode, 80, $hheight / 2 + 3, 25, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $FromLabel2 = GUICtrlCreateLabel("From", 10, $hheight / 2 + 38, 40, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $FromInput2 = GUICtrlCreateInput($Sin2From, 60, $hheight / 2 + 35, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $ToLabel2 = GUICtrlCreateLabel("To", 120, $hheight / 2 + 38, 25, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $ToInput2 = GUICtrlCreateInput($Sin2To, 155, $hheight / 2 + 35, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $Sin2Position = GUICtrlCreateLabel("Position", 215, $hheight / 2 + 38, 100, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $Strength2Label = GUICtrlCreateLabel("Strength", 10, $hheight / 2 + 73, 55, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $Strength2Input = GUICtrlCreateInput($SinStrength2, 75, $hheight / 2 + 70, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $Sin2ColorButton = GUICtrlCreateButton("Color Mode", 10, $hheight / 2 + 105, 100, 25)
	GUICtrlSetFont(-1, 11)
	Local $Sin2ColorLabel = GUICtrlCreateLabel($Sin2ColorMode, 120, $hheight / 2 + 108, 150, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $Sin2Static = GUICtrlCreateLabel("Color:", 10, $hheight / 2 + 143, 40, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	If $Sin2ColorMode <> "StaticColor" Then GUICtrlSetState(-1, $GUI_HIDE)
	Local $Sin2ColorInput = GUICtrlCreateInput($Sin2StaticColor, 60, $hheight / 2 + 140, 75, 25)
	GUICtrlSetFont(-1, 11)
	If $Sin2ColorMode <> "StaticColor" Then GUICtrlSetState(-1, $GUI_HIDE)
	;-----------------------------------------------------------------------------

	;--------------------------------------------------------------------MiddleLayer
	Local $CircleSwitch = GUICtrlCreateButton("Circles:", $onethree+10, 55, 100, 25)
	GUICtrlSetFont(-1, 11)
	Local $CircleLabel = GUICtrlCreateLabel($CircleMode, $onethree+120, 58, 25, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)

	Local $CircleAmountLabel1= GUICtrlCreateLabel("From", $onethree+10, 93, 40, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $CircleFrom = GUICtrlCreateInput($CircleFromAmount, $onethree+60, 90, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $CircleAmountLabel2 = GUICtrlCreateLabel("To", $onethree+120, 93, 25, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $CircleTo = GUICtrlCreateInput($CircleToAmount, $onethree+155, 90, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $CircleAmountLabel3 = GUICtrlCreateLabel("Amount", $onethree+215, 93, 100, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $CircleRandomLabel = GUICtrlCreateLabel("Randomness", $onethree+10, 128, 90, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $CircleRandomInput = GUICtrlCreateInput($CircleRandomness, $onethree+110, 125, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $CircleStrengthLabel = GUICtrlCreateLabel("Strength", $onethree+10, 163, 55, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $CircleStrengthInput = GUICtrlCreateInput($CircleStrength, $onethree+75, 160, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $CircleColorSwitch = GUICtrlCreateButton("Color Mode", $onethree+10, 195, 100, 25)
	GUICtrlSetFont(-1, 11)
	Local $CircleColorlabel = GUICtrlCreateLabel($CircleColorMode, $onethree+120, 198, 150, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $CircleStatic = GUICtrlCreateLabel("Color:", $onethree+10, 233, 40, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	If $CircleColorMode <> "StaticColor" Then GUICtrlSetState(-1, $GUI_HIDE)
	Local $CircleColorInput = GUICtrlCreateInput($CircleStaticColor, $onethree+60, 230, 75, 25)
	GUICtrlSetFont(-1, 11)
	If $CircleColorMode <> "StaticColor" Then GUICtrlSetState(-1, $GUI_HIDE)
	;-------------------------------------------------------------------------------

	;--------------------------------------------------------------------RightLayer
	Local $TriangleSwitch = GUICtrlCreateButton("Triangles:", $twothree+10, 55, 100, 25)
	GUICtrlSetFont(-1, 11)
	Local $TriangleLabel = GUICtrlCreateLabel($TriangleMode, $twothree+120, 58, 25, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)

	Local $TriangleStartLabel = GUICtrlCreateLabel("StartAngle", $twothree+10, 93, 70, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $TriangleStartInput = GUICtrlCreateInput($TriangleAngle, $twothree+90, 90, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $TriangleAddLabel = GUICtrlCreateLabel("Adding", $twothree+150, 93, 50, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $TriangleAddInput = GUICtrlCreateInput($TriangleAddAngle, $twothree+210, 90, 50, 25)
	GUICtrlSetFont(-1, 11)
	Local $TriangleStrengthLabel = GUICtrlCreateLabel("Strength", $twothree+10, 128, 55, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $TriangleStrengthInput = GUICtrlCreateInput($TriangleStrength, $twothree+75, 125, 50, 25)
	GUICtrlSetFont(-1, 11)

	Local $TriangleColorSwitch = GUICtrlCreateButton("Color Mode", $twothree+10, 160, 100, 25)
	GUICtrlSetFont(-1, 11)
	Local $TriangleColorLabel = GUICtrlCreateLabel($TriangleColorMode, $twothree+120, 163, 150, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	Local $TriangleStatic = GUICtrlCreateLabel("Color:", $twothree+10, 198, 40, 25)
	GUICtrlSetColor(-1, 0xE1E1E1)
	GUICtrlSetFont(-1, 11)
	If $TriangleColorMode <> "StaticColor" Then GUICtrlSetState(-1, $GUI_HIDE)
	Local $TriangleColorInput = GUICtrlCreateInput($TriangleStaticColor, $twothree+60, 195, 75, 25)
	GUICtrlSetFont(-1, 11)
	If $TriangleColorMode <> "StaticColor" Then GUICtrlSetState(-1, $GUI_HIDE)
	;------------------------------------------------------------------------------

	;--------------------------------------------------------------------BottonLayer
	Local $idSwitchToDeviceSound = GUICtrlCreateButton("", 10, $hheight - 35, 125, 25)
	GUICtrlSetData($idSwitchToDeviceSound, ($DeviceSoundOn ? "SoundDevice" : "MusicFile"))
	GUICtrlSetFont(-1, 11)
	Local $idSwitchToDeviceSoundLabel = GUICtrlCreateLabel("", 145, $hheight - 31, $hwidth - 145 - 145, 17)
	If $UseDeviceSound Then
		Local $DeviceInfo = _BASS_RecordGetDeviceInfo($SoundDeviceID)
		If not @error Then GUICtrlSetData($idSwitchToDeviceSoundLabel, $DeviceInfo[0])
	EndIf
	GUICtrlSetFont(-1, 11)
    GUICtrlSetColor(-1, 0xE1E1E1)

	Local $idApplyChanges = GUICtrlCreateButton("Apply Changes", $hwidth - 135, $hheight - 35, 125, 25)
	GUICtrlSetFont(-1, 11)
	;-------------------------------------------------------------------------------

	;--------------------------------------------------------------------SplitScreen
	GUICtrlCreateLabel("", 0, 45, $hwidth, 2)
	GUICtrlSetBkColor(-1, 0x44474C)
	GUICtrlCreateLabel("", $onethree, 45, 2, $hheight - (2 * 45))
	GUICtrlSetBkColor(-1, 0x44474C)
	GUICtrlCreateLabel("", $twothree, 45, 2, $hheight - (2 * 45))
	GUICtrlSetBkColor(-1, 0x44474C)
	GUICtrlCreateLabel("", 0, $hheight - 45, $hwidth, 2)
	GUICtrlSetBkColor(-1, 0x44474C)
	;-------------------------------------------------------------------------------
	Local $CableDevice = ""

	GUISetState(@SW_SHOW, $hGUI)
	Local $Timer3 = TimerInit()
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $idChangeMode
				Switch $ModeState
					Case "Delete"
						$ModeState = "Fade"
						GUICtrlSetData($idModeLabel, $ModeState)
						GUICtrlSetState($FadeLabel, $GUI_SHOW)
						GUICtrlSetState($FadeStrengthInput, $GUI_SHOW)
					Case "Fade"
						$ModeState = "Stay"
						GUICtrlSetData($idModeLabel, $ModeState)
						GUICtrlSetState($FadeLabel, $GUI_HIDE)
						GUICtrlSetState($FadeStrengthInput, $GUI_HIDE)
					Case "Stay"
						$ModeState = "Delete"
						GUICtrlSetData($idModeLabel, $ModeState)
						GUICtrlSetState($FadeLabel, $GUI_HIDE)
						GUICtrlSetState($FadeStrengthInput, $GUI_HIDE)
				EndSwitch
			Case $SinSwitch
				If $SinMode == "On" Then
					$SinMode = "Off"
					GUICtrlSetData($SinLabel, $SinMode)
				ElseIf $SinMode == "Off" Then
					$SinMode = "On"
					GUICtrlSetData($SinLabel, $SinMode)
				EndIf
			Case $Sin1Switch
				If $Sin1Mode == "On" Then
					$Sin1Mode = "Off"
					GUICtrlSetData($Sin1Label, $Sin1Mode)
				ElseIf $Sin1Mode == "Off" Then
					$Sin1Mode = "On"
					GUICtrlSetData($Sin1Label, $Sin1Mode)
				EndIf
			Case $Sin2Switch
				If $Sin2Mode == "On" Then
					$Sin2Mode = "Off"
					GUICtrlSetData($Sin2Label, $Sin2Mode)
				ElseIf $Sin2Mode == "Off" Then
					$Sin2Mode = "On"
					GUICtrlSetData($Sin2Label, $Sin2Mode)
				EndIf
			Case $Sin1ColorButton
				Switch $Sin1ColorMode
					Case "TimeColor"
						$Sin1ColorMode = "TimeColorInverted"
						GUICtrlSetData($Sin1ColorLabel, $Sin1ColorMode)
						GUICtrlSetState($Sin1Static, $GUI_HIDE)
						GUICtrlSetState($Sin1ColorInput, $GUI_HIDE)
					Case "TimeColorInverted"
						$Sin1ColorMode = "StaticColor"
						GUICtrlSetData($Sin1ColorLabel, $Sin1ColorMode)
						GUICtrlSetState($Sin1Static, $GUI_SHOW)
						GUICtrlSetState($Sin1ColorInput, $GUI_SHOW)
					Case "StaticColor"
						$Sin1ColorMode = "TimeColor"
						GUICtrlSetData($Sin1ColorLabel, $Sin1ColorMode)
						GUICtrlSetState($Sin1Static, $GUI_HIDE)
						GUICtrlSetState($Sin1ColorInput, $GUI_HIDE)
				EndSwitch
			Case $Sin2ColorButton
				Switch $Sin2ColorMode
					Case "TimeColor"
						$Sin2ColorMode = "TimeColorInverted"
						GUICtrlSetData($Sin2ColorLabel, $Sin2ColorMode)
						GUICtrlSetState($Sin2Static, $GUI_HIDE)
						GUICtrlSetState($Sin2ColorInput, $GUI_HIDE)
					Case "TimeColorInverted"
						$Sin2ColorMode = "StaticColor"
						GUICtrlSetData($Sin2ColorLabel, $Sin2ColorMode)
						GUICtrlSetState($Sin2Static, $GUI_SHOW)
						GUICtrlSetState($Sin2ColorInput, $GUI_SHOW)
					Case "StaticColor"
						$Sin2ColorMode = "TimeColor"
						GUICtrlSetData($Sin2ColorLabel, $Sin2ColorMode)
						GUICtrlSetState($Sin2Static, $GUI_HIDE)
						GUICtrlSetState($Sin2ColorInput, $GUI_HIDE)
				EndSwitch
			Case $CircleSwitch
				If $CircleMode == "On" Then
					$CircleMode = "Off"
					GUICtrlSetData($CircleLabel, $CircleMode)
				ElseIf $CircleMode == "Off" Then
					$CircleMode = "On"
					GUICtrlSetData($CircleLabel, $CircleMode)
				EndIf
			Case $CircleColorSwitch
				Switch $CircleColorMode
					Case "TimeColor"
						$CircleColorMode = "TimeColorInverted"
						GUICtrlSetData($CircleColorlabel, $CircleColorMode)
						GUICtrlSetState($CircleStatic, $GUI_HIDE)
						GUICtrlSetState($CircleColorInput, $GUI_HIDE)
					Case "TimeColorInverted"
						$CircleColorMode = "StaticColor"
						GUICtrlSetData($CircleColorlabel, $CircleColorMode)
						GUICtrlSetState($CircleStatic, $GUI_SHOW)
						GUICtrlSetState($CircleColorInput, $GUI_SHOW)
					Case "StaticColor"
						$CircleColorMode = "TimeColor"
						GUICtrlSetData($CircleColorlabel, $CircleColorMode)
						GUICtrlSetState($CircleStatic, $GUI_HIDE)
						GUICtrlSetState($CircleColorInput, $GUI_HIDE)
				EndSwitch
			Case $TriangleSwitch
				If $TriangleMode == "On" Then
					$TriangleMode = "Off"
					GUICtrlSetData($TriangleLabel, $TriangleMode)
				ElseIf $TriangleMode == "Off" Then
					$TriangleMode = "On"
					GUICtrlSetData($TriangleLabel, $TriangleMode)
				EndIf
			Case $TriangleColorSwitch
				Switch $TriangleColorMode
					Case "TimeColor"
						$TriangleColorMode = "TimeColorInverted"
						GUICtrlSetData($TriangleColorLabel, $TriangleColorMode)
						GUICtrlSetState($TriangleStatic, $GUI_HIDE)
						GUICtrlSetState($TriangleColorInput, $GUI_HIDE)
					Case "TimeColorInverted"
						$TriangleColorMode = "StaticColor"
						GUICtrlSetData($TriangleColorLabel, $TriangleColorMode)
						GUICtrlSetState($TriangleStatic, $GUI_SHOW)
						GUICtrlSetState($TriangleColorInput, $GUI_SHOW)
					Case "StaticColor"
						$TriangleColorMode = "TimeColor"
						GUICtrlSetData($TriangleColorLabel, $TriangleColorMode)
						GUICtrlSetState($TriangleStatic, $GUI_HIDE)
						GUICtrlSetState($TriangleColorInput, $GUI_HIDE)
				EndSwitch
			Case $idSwitchToDeviceSound
				$CableDevice = _GetNextDeviceChannel()
				If @error Then
					$DeviceSoundOn = False
					GUICtrlSetData($idSwitchToDeviceSound, "MusicFile")
					GUICtrlSetData($idSwitchToDeviceSoundLabel, "")
				Else
					$DeviceSoundOn = True
					GUICtrlSetData($idSwitchToDeviceSound, "SoundDevice")
					GUICtrlSetData($idSwitchToDeviceSoundLabel, $CableDevice[0])
				EndIf
			Case $idApplyChanges
				If $DeviceSoundOn Then
                    _BASS_RecordFree()
                    _BASS_RecordInit($SoundDeviceID)
					_BASS_RecordSetInput($SoundDeviceID, $BASS_INPUT_ON, 1)
					$StreamHandle = _BASS_RecordStart(44100, 2, _WinAPI_MakeLong(0, 10))
				ElseIf $DeviceSoundOn <> $UseDeviceSound Then
					If $SongArrayIndex > 0 Then
						$SongArrayIndex -= 2
					Else
						$SongArrayIndex -= 1
					EndIf
                    $StreamHandle = -1
					_StartFile()
					_BASS_ChannelPause($StreamHandle)
				EndIf
				$UseDeviceSound = $DeviceSoundOn
				Switch $ModeState
					Case "Delete"
						$Delete = True
						$Fade = False
					Case "Fade"
						$Delete = False
						$Fade = True
						$FadeAmount = GUICtrlRead($FadeStrengthInput)
						$blacktrans = _GDIPlus_BrushCreateSolid("0x" & Hex($FadeAmount, 2) & "000000")
					Case "Stay"
						$Delete = False
						$Fade = False
				EndSwitch
				$OverallX = Int(GUICtrlRead($XInput))
				$OverallY = Int(GUICtrlRead($YInput))
				If $SinMode == "On" Then
					$Sin = True
				ElseIf $SinMode == "Off" Then
					$Sin = False
				EndIf
				If $Sin1Mode == "On" Then
					$Sin1 = True
				ElseIf $Sin1Mode == "Off" Then
					$Sin1 = False
				EndIf
				If $Sin2Mode == "On" Then
					$Sin2 = True
				ElseIf $Sin2Mode == "Off" Then
					$Sin2 = False
				EndIf
				$SinFrom1 = Int(GUICtrlRead($FromInput1))
				$SinTo1 = Int(GUICtrlRead($ToInput1))
				$SinFrom2 = Int(GUICtrlRead($FromInput2))
				$SinTo2 = Int(GUICtrlRead($ToInput2))
				$Sin1Amp = Int(GUICtrlRead($Strength1Input))
				$Sin2Amp = Int(GUICtrlRead($Strength2Input))
				Switch $Sin1ColorMode
					Case "TimeColor"
						$Sin1Colortime = 1
					Case "TimeColorInverted"
						$Sin1Colortime = 2
					Case "StaticColor"
						$Sin1Colortime = 0
				EndSwitch
				Switch $Sin2ColorMode
					Case "TimeColor"
						$Sin2Colortime = 1
					Case "TimeColorInverted"
						$Sin2Colortime = 2
					Case "StaticColor"
						$Sin2Colortime = 0
				EndSwitch
				$Sin1Color = GUICtrlRead($Sin1ColorInput)
				$Sin2Color = GUICtrlRead($Sin2ColorInput)
				If $CircleMode == "On" Then
					$Circle = True
				ElseIf $CircleMode == "Off" Then
					$Circle = False
				EndIf
				$CircleAmountFrom = Int(GUICtrlRead($CircleFrom))
				$CircleAmounTo = Int(GUICtrlRead($CircleTo))
				$CircleIndexTo = Int(GUICtrlRead($CircleRandomInput))
				$CircleSize = Int(GUICtrlRead($CircleStrengthInput))
				Switch $CircleColorMode
					Case "TimeColor"
						$CircleColortime = 1
					Case "TimeColorInverted"
						$CircleColortime = 2
					Case "StaticColor"
						$CircleColortime = 0
				EndSwitch
				$CircleColor = GUICtrlRead($CircleColorInput)
				If $TriangleMode == "On" Then
					$Triangle = True
				ElseIf $TriangleMode == "Off" Then
					$Triangle = False
				EndIf
				$TriangleGroundAngle = ($PI*Int(GUICtrlRead($TriangleStartInput)))/180
				$TriangleGroundAnglePlus = ($PI*Int(GUICtrlRead($TriangleAddInput)))/180
				$TriangleSize = Int(GUICtrlRead($TriangleStrengthInput))
				Switch $TriangleColorMode
					Case "TimeColor"
						$TriangleColortime = 1
					Case "TimeColorInverted"
						$TriangleColortime = 2
					Case "StaticColor"
						$TriangleColortime = 0
				EndSwitch
				$TriangleColor = GUICtrlRead($TriangleColorInput)
				If $Sin1Colortime == 0 Then $SinPen1 = _GDIPlus_PenCreate("0xFF" & $Sin1Color, 2)
				If $Sin2Colortime == 0 Then $SinPen2 = _GDIPlus_PenCreate("0xFF" & $Sin2Color, 2)
				If $CircleColortime == 0 Then $CircleBrush = _GDIPlus_BrushCreateSolid("0xFF" & $CircleColor)
				If $TriangleColortime == 0 Then $TrianglePen = _GDIPlus_PenCreate("0xFF" & $TriangleColor, 2)
			Case 0
				If TimerDiff($Timer3) > 25 Then
					_ShowGraphics()
					$Timer3 = TimerInit()
				EndIf
                If _IsPressed(02, $user32) and WinActive($hwnd) Then
                    WinActivate($hGUI)
                EndIf
		EndSwitch
	WEnd

	GUIDelete($hGUI)
	$Timer3 = ""
	Opt("GUIOnEventMode", 1)
	Opt("GUICloseOnESC", 1)
EndFunc   ;==>_GUIControl

Func _GetNextDeviceChannel()
	$SoundDeviceID += 1
	Local $DeviceInfo = _BASS_RecordGetDeviceInfo($SoundDeviceID)
	If @error == $BASS_ERROR_DEVICE Then
		$SoundDeviceID = -1
		Return SetError($BASS_ERROR_DEVICE, 0, $DeviceInfo)
	EndIf
	Return $DeviceInfo
EndFunc

Func _ShowGraphics()
	_GDIPlus_GraphicsClear($backbuffer)
	_BASS_ChannelGetData($StreamHandle, DllStructGetPtr($b), $BASS_DATA_FFT256)

	If $Sin Then _SinViz($b)
	If $Circle Then _CircleViz($b)
	If $Triangle Then _TriangleViz($b)

	_GDIPlus_GraphicsDrawImageRect($backbuffer, $vizbitmap, 0, 0, $width, $height)

	If $SongStringOpacity > 0 Then
		_GDIPlus_GraphicsDrawStringEx($backbuffer, $SongString, $font, $rect, $format, $WhiteTransBrushes[$SongStringOpacity])
		$SongStringOpacity -= 5
	EndIf
	_GDIPlus_GraphicsDrawImageRect($graphics, $bitmap, 0, 0, $width, $height)

	$HexTimeColor[0] = Hex(Int((@HOUR * 255) / 24), 2) & Hex(Int((@MIN * 255) / 60), 2) & Hex(Int((@SEC * 255) / 60), 2)
	$aColor = _ColorGetRGB("0x" & $HexTimeColor[0])
	$HexTimeColor[1] = Hex(255 - $aColor[0], 2) & Hex(255 - $aColor[1], 2) & Hex(255 - $aColor[2], 2)

	If $Sin1Colortime == 1 Then
        $SinPen1 = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[0], 2)
	ElseIf $Sin1Colortime == 2 Then
        $SinPen1 = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[1], 2)
    EndIf
	If $Sin2Colortime == 1 Then
        $SinPen2 = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[0], 2)
	ElseIf $Sin2Colortime == 2 Then
        $SinPen2 = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[1], 2)
    EndIf

	If $CircleColortime == 1 Then
        $CircleBrush = _GDIPlus_BrushCreateSolid("0xFF" & $HexTimeColor[0])
	ElseIf $CircleColortime == 2 Then
        $CircleBrush = _GDIPlus_BrushCreateSolid("0xFF" & $HexTimeColor[1])
    EndIf

	If $TriangleColortime == 1 Then
        $TrianglePen = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[0], 2)
	ElseIf $TriangleColortime == 2 Then
        $TrianglePen = _GDIPlus_PenCreate("0xFF" & $HexTimeColor[1], 2)
    EndIf

	If $Delete Then
		_GDIPlus_GraphicsClear($vizbuffer, 0xFF000000)
	ElseIf $Fade Then
		_GDIPlus_GraphicsFillRect($vizbuffer, 0, 0, $width, $height, $blacktrans)
	EndIf
EndFunc

Func _Switch_AudioPlayback()
	If _Get_playstate() == 2 Then
		$BASS_PAUSE_POS = _BASS_ChannelGetPosition($StreamHandle, 0)
		If not @Compiled Then ConsoleWrite("Pause Position: " & $BASS_PAUSE_POS & @CRLF)
		_BASS_ChannelPause($StreamHandle)
		Local $ChannelPosition = _GetSongPositionString($BASS_PAUSE_POS)
		$SongString = "Paused (" & $ChannelPosition & ")"
		$SongStringOpacity = 255
	ElseIf _Get_playstate() == 3 Then
		_BASS_ChannelPlay($StreamHandle, 0)
		$SongString = "Resumed"
		$SongStringOpacity = 255
	EndIf
EndFunc   ;==>_Switch_AudioPlayback

Func _GetSongPositionString($Pause_Position)
	Local $CurrentPosition, $MaximalPosition
	Local $ReturnString = ""

	$CurrentPosition = _BASS_ChannelBytes2Seconds($StreamHandle, $Pause_Position)
	Local $BASS_ret_ = _BASS_ChannelGetLength($StreamHandle, 0)
	$MaximalPosition = _BASS_ChannelBytes2Seconds($StreamHandle, $BASS_ret_)

	$ReturnString = _TicksToTimeFormat($CurrentPosition*1000) & "/" & _TicksToTimeFormat($MaximalPosition*1000)

	Return $ReturnString
EndFunc

Func _TicksToTimeFormat($iTicks, $iHours = 0, $iMins = 0, $iSecs = 0)
	If Number($iTicks) > 0 Then
		$iTicks = Int($iTicks / 1000)
		$iHours = StringFormat("%02i", Int($iTicks / 3600))
		$iTicks = Mod($iTicks, 3600)
		$iMins = StringFormat("%02i", Int($iTicks / 60))
		$iSecs = StringFormat("%02i", Mod($iTicks, 60))
		; If $iHours = 0 then $iHours = 24
		If $iHours > 0 Then
			Return ($iHours & ":" & $iMins & ":" & $iSecs)
		Else
			Return ($iMins & ":" & $iSecs)
		EndIf
	ElseIf Number($iTicks) == 0 Then
		Return "00"
	Else
		Return SetError(1, 0, 0)
	EndIf
EndFunc   ;==>_TicksToTime

Func _Get_playstate()
	Local $returnstate
	Local $BASS_ret_ = _BASS_ChannelIsActive($StreamHandle)
	Switch $BASS_ret_
		Case $BASS_ACTIVE_STOPPED
			$returnstate = 1
		Case $BASS_ACTIVE_PLAYING
			$returnstate = 2
		Case $BASS_ACTIVE_PAUSED
			$returnstate = 3
		Case $BASS_ACTIVE_STALLED
			$returnstate = 4
	EndSwitch
	Return $returnstate
EndFunc   ;==>_Get_playstate

Func _TriangleViz($fftstruct)
	Local $Sum = 0
	Local $x1, $x2, $x3, $y1, $y2, $y3, $size

	For $i = 1 To 128
		$Sum += DllStructGetData($fftstruct, 1, $i)
	Next

	$TriangleGroundAngle += $TriangleGroundAnglePlus
	If $TriangleGroundAngle > 2*$PI Then $TriangleGroundAngle -= 2*$PI
	$size = 50 + $Sum * $TriangleSize

    Local $TriangleRoundAnglePlusHalfPI = $TriangleGroundAngle + $PI / 2
    Local $TwoPiThird = (2 * $PI) / 3
    Local $FourPiThird = (4 * $PI) / 3
    Local $halfWidth = $width / 2
    Local $halfheight = $height / 2
    Local $XIntend = $halfWidth + $OverallX
    Local $YIntend = $halfheight + $OverallY
	$x1 = Cos($TriangleRoundAnglePlusHalfPI) * $size + $XIntend
	$y1 = Sin($TriangleRoundAnglePlusHalfPI) * $size + $YIntend
	$x2 = Cos($TriangleRoundAnglePlusHalfPI + $TwoPiThird) * $size + $XIntend
	$y2 = Sin($TriangleRoundAnglePlusHalfPI + $TwoPiThird) * $size + $YIntend
	$x3 = Cos($TriangleRoundAnglePlusHalfPI + $FourPiThird) * $size + $XIntend
	$y3 = Sin($TriangleRoundAnglePlusHalfPI + $FourPiThird) * $size + $YIntend

	_GDIPlus_GraphicsDrawLine($vizbuffer, $x1, $y1, $x2, $y2, $TrianglePen)
	_GDIPlus_GraphicsDrawLine($vizbuffer, $x2, $y2, $x3, $y3, $TrianglePen)
	_GDIPlus_GraphicsDrawLine($vizbuffer, $x3, $y3, $x1, $y1, $TrianglePen)
EndFunc   ;==>_TriangleViz

Func _CircleViz($fftstruct)
	Local $fft, $x, $y
	Local $dots = Random($CircleAmountFrom, $CircleAmounTo, 1)
	SRandom($CircleSeed)
    Local $XIntend = $width / 2 + $OverallX
    Local $YIntend = $height / 2 + $OverallY
    Local $RootRootFft, $iterationByDots
	For $i = 1 To $dots Step 2
		$fft = DllStructGetData($fftstruct, 1, Random(1, $CircleIndexTo, 1)) ;$randvalues[$i-1])
        $RootRootFft = $CircleSize * Sqrt(Sqrt($fft * 100000))
        $iterationByDots = $i / $dots
        $x = (Cos(-1 * $PI * $iterationByDots) * $RootRootFft) + $XIntend
        $y = (Sin(-1 * $PI * $iterationByDots) * $RootRootFft) + $YIntend

		_GDIPlus_GraphicsFillEllipse($vizbuffer, $x, $y, 2, 2, $CircleBrush)
	Next
	For $i = 2 To $dots Step 2
		$fft = DllStructGetData($fftstruct, 1, Random(1, $CircleIndexTo, 1)) ;$randvalues[$i-1])
        $RootRootFft = $CircleSize * Sqrt(Sqrt($fft * 100000))
        $iterationByDots = $i / $dots
        $x = (Cos($PI * $iterationByDots) * $RootRootFft) + $XIntend
        $y = (Sin($PI * $iterationByDots) * $RootRootFft) + $YIntend

		_GDIPlus_GraphicsFillEllipse($vizbuffer, $x, $y, 2, 2, $CircleBrush)
	Next
EndFunc   ;==>_CircleViz

Func _SinViz($fftstruct)
	Local $oldx, $oldy, $fft, $y

	If $Sin1 Then
		$oldx = $SinFrom1-$MoveFactor
		$oldy = $height / 2
		For $i = $SinFrom1-$MoveFactor To $SinTo1 Step 5
			$fft = DllStructGetData($fftstruct, 1, ($i - ($SinFrom1-$MoveFactor)) / $Sin1Amp)

			$y = $height / 2 + Sin($i) * Sqrt($fft) * 500
			_GDIPlus_GraphicsDrawLine($vizbuffer, $oldx, $oldy, $i, $y, $SinPen1)
			$oldx = $i
			$oldy = $y
		Next
	EndIf
	If $Sin2 Then
		$oldx = $SinFrom2+$MoveFactor
		$oldy = $height / 2
		For $i = $SinFrom2+$MoveFactor To $SinTo2 Step -5
			$fft = DllStructGetData($fftstruct, 1, (($SinFrom2+$MoveFactor) - $i) / $Sin2Amp)

			$y = ($height / 2 - Sin($i) * Sqrt($fft) * 500)
			_GDIPlus_GraphicsDrawLine($vizbuffer, $i, $y, $oldx, $oldy, $SinPen2)
			$oldx = $i
			$oldy = $y
		Next
	EndIf
EndFunc   ;==>_SinViz

Func Map($iValue, $iFromLow, $iFromHigh, $iToLow, $iToHigh)
    Return ($iValue - $iFromLow) * ($iToHigh - $iToLow) / ($iFromHigh - $iFromLow) + $iTolow
EndFunc

Func WM_DROPFILES_FUNC($hwnd, $msgID, $wParam, $lParam)
	Local $nSize, $pFileName, $FileFolder
	Local $nAmt = DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", 0xFFFFFFFF, "ptr", 0, "int", 255)
	For $i = 0 To $nAmt[0] - 1
		$nSize = DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", $i, "ptr", 0, "int", 0)
		$nSize = $nSize[0] + 1
		$pFileName = DllStructCreate("char[" & $nSize & "]")
		DllCall("shell32.dll", "int", "DragQueryFile", "hwnd", $wParam, "int", $i, "ptr", DllStructGetPtr($pFileName), "int", $nSize)
		$FileFolder = DllStructGetData($pFileName, 1)
		If _IsFolder($FileFolder) Then
			_Folder($FileFolder)
		Else
			_File($FileFolder)
		EndIf
	Next
EndFunc   ;==>WM_DROPFILES_FUNC

Func _StartFile()
    If Ubound($SongArray) == 0 Then Return
	_BASS_StreamFree($StreamHandle)
	Local $ptr, $temp
	$SongArrayIndex += 1
    If $SongArrayIndex >= Ubound($SongArray) Then $SongArrayIndex = 0
    If $SongArrayIndex < 0 Then $SongArrayIndex = 0
	$StreamHandle = _BASS_StreamCreateFile(False, $SongArray[$SongArrayIndex], 0, 0, 0)

	If $StreamHandle == 0 Then Return
	If StringRight($SongArray[$SongArrayIndex], 4) = "flac" Or StringRight($SongArray[$SongArrayIndex], 4) = ".ogg" Then
		$ptr = _BASS_ChannelGetTags($StreamHandle, 2)
		$temp = _GetID3StructFromOGGComment($ptr)
		$SongString = DllStructGetData($temp, "Title")
		If StringLen(DllStructGetData($temp, "Artist")) > 1 Then $SongString &= " - " & DllStructGetData($temp, "Artist")
		$SongStringOpacity = 255
	Else
		$ptr = _BASS_ChannelGetTags($StreamHandle, 0)
		$temp = DllStructCreate($ID3, $ptr)
		$SongString = DllStructGetData($temp, "Title")
		If StringLen(DllStructGetData($temp, "Artist")) > 1 Then $SongString &= " - " & DllStructGetData($temp, "Artist")
		$SongStringOpacity = 255
	EndIf
	If $SongString == "0" Then $SongString = ""

	_BASS_ChannelPlay($StreamHandle, 1)
EndFunc   ;==>_StartFile

Func _Folder($Folder)
	Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
	Local $aPathSplit
	Local $SubFiles = _FileListToArrayRec($Folder, "*.mp3;*.wav;*.flac;*.ogg", $FLTAR_FILES, $FLTAR_RECUR, $FLTAR_SORT, $FLTAR_FULLPATH)
    For $i = 1 To UBound($SubFiles) - 1
		$aPathSplit = _PathSplit($SubFiles[$i], $sDrive, $sDir, $sFileName, $sExtension)
		_ArrayAdd($SongArray, $SubFiles[$i])
        If not @Compiled Then ConsoleWrite("Added " & $SubFiles[$i] & @CRLF)
	Next
EndFunc   ;==>_Folder

Func _File($File)
	Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
	Local $aPathSplit = _PathSplit($File, $sDrive, $sDir, $sFileName, $sExtension)
	If $sExtension == ".mp3" Or $sExtension == ".wav" Or $sExtension == ".flac" Or $sExtension == ".ogg" Then
		_ArrayAdd($SongArray, $File)
		If not @Compiled Then ConsoleWrite("Added " & $File & @CRLF)
	EndIf
EndFunc   ;==>_File

Func _IsFolder($path)
	Return StringInStr(FileGetAttrib($path), "D")
EndFunc   ;==>_IsFolder

Func _GetID3StructFromOGGComment($ptr)
	$tags = DllStructCreate($ID3)
	Do
		$s = DllStructCreate("char[255];", $ptr)
		$string = DllStructGetData($s, 1)
		If StringLeft($string, 1) == Chr(0) Then ExitLoop

		Switch StringLeft($string, StringInStr($string, "=") - 1)
			Case "title"
				DllStructSetData($tags, "title", StringTrimLeft($string, StringInStr($string, "=")))
			Case "artist"
				DllStructSetData($tags, "artist", StringTrimLeft($string, StringInStr($string, "=")))
			Case "album"
				DllStructSetData($tags, "album", StringTrimLeft($string, StringInStr($string, "=")))
			Case "date"
				DllStructSetData($tags, "year", StringTrimLeft($string, StringInStr($string, "=")))
			Case "genre"
				DllStructSetData($tags, "genre", StringTrimLeft($string, StringInStr($string, "=")))
			Case "comment"
				DllStructSetData($tags, "comment", StringTrimLeft($string, StringInStr($string, "=")))
		EndSwitch
		$ptr += StringLen($string) + 1
	Until False

	Return $tags
EndFunc   ;==>_GetID3StructFromOGGComment

Func _Mousewheel($hwnd, $msg, $l, $r) ;abfrage mausrad
    If $UseDeviceSound or Ubound($SongArray) == 0 Then Return
	If $l = 0xFF880000 Then ; Mouse wheel up
		If $SoundSet > 0 Then $SoundSet -= 1
	Else ; Mouse wheel down
		If $SoundSet < 100 Then $SoundSet += 1
	EndIf
	SoundSetWaveVolume($SoundSet)
	$SongString = "Volume: " & $SoundSet
	$SongStringOpacity = 255
EndFunc   ;==>_Mousewheel

Func _close()
	Exit
EndFunc   ;==>_close

Func _close_reg()
	_BASS_ChannelStop($StreamHandle)
	_BASS_Free()
	DllClose("user32.dll")
	For $i = 0 To UBound($WhiteTransBrushes) - 1
		_GDIPlus_BrushDispose($WhiteTransBrushes[$i])
	Next
	_GDIPlus_StringFormatDispose($format)
	_GDIPlus_FontDispose($font)
	_GDIPlus_FontFamilyDispose($family)
	_GDIPlus_BrushDispose($blacktrans)
	_GDIPlus_PenDispose($SinPen1)
	_GDIPlus_PenDispose($SinPen2)
	_GDIPlus_PenDispose($TrianglePen)
	_GDIPlus_GraphicsDispose($vizbuffer)
	_GDIPlus_GraphicsDispose($backbuffer)
	_GDIPlus_BitmapDispose($vizbitmap)
	_GDIPlus_BitmapDispose($bitmap)
	_GDIPlus_GraphicsDispose($graphics)
	_GDIPlus_Shutdown()
	GUIDelete($hwnd)
EndFunc   ;==>_close_reg
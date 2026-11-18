#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force
#Warn All, Off

OnError (*) => -1
SetWinDelay -1

; Hide taskbars on startup
try WinHide "ahk_class Shell_TrayWnd"
try WinHide "ahk_class Shell_SecondaryTrayWnd"

; Track lock states and overlay GUIs
global IsFrozen := false
global FreezeGui := ""

global IsBSOD := false
global BSODGui := ""
global BSODPercent := 0
global BSODTextCtrl := ""

global IsUpdating := false
global UpdateGui := ""
global UpdatePercent := 14
global UpdateTextCtrl := ""

global IsBlackout := false
global BlackoutGui := ""

global HelpGui := ""

; Ensure cursor is always restored if script exits or reloads
OnExit (*) => RestoreCursor()

; Check physical idle time every 5 seconds (180,000 ms = 3 minutes)
SetTimer CheckIdleFreeze, 5000

CheckIdleFreeze() {
    global IsFrozen, IsBSOD, IsUpdating, IsBlackout
    if (!IsFrozen && !IsBSOD && !IsUpdating && !IsBlackout && A_TimeIdlePhysical >= 180000) {
        ToggleFreeze(true)
    }
}

DismissAllOverlays() {
    global IsFrozen, IsBSOD, IsUpdating, IsBlackout
    if IsFrozen
        ToggleFreeze()
    if IsBSOD
        ToggleBSOD()
    if IsUpdating
        ToggleUpdate()
    if IsBlackout
        ToggleBlackout()
}

; ==========================================
; 1. Toggle Taskbar Visibility (Win + Alt + Z)
; ==========================================
#!z:: {
    if WinExist("ahk_class Shell_TrayWnd") {
        try WinHide "ahk_class Shell_TrayWnd"
        try WinHide "ahk_class Shell_SecondaryTrayWnd"
    } else {
        try WinShow "ahk_class Shell_TrayWnd"
        try WinShow "ahk_class Shell_SecondaryTrayWnd"
    }
}

; ==========================================
; 2. Fake Screen Freeze & Hide Cursor (Win + Alt + Q)
; ==========================================
#!q::ToggleFreeze()

ToggleFreeze(forceFreeze := false) {
    global IsFrozen, FreezeGui
    if (!IsFrozen || forceFreeze) {
        if IsFrozen
            return
        DismissAllOverlays()
        IsFrozen := true
        hBmp := CaptureVirtualScreen()
        
        vx := SysGet(76), vy := SysGet(77)
        vw := SysGet(78), vh := SysGet(79)
        
        FreezeGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
        FreezeGui.MarginX := 0
        FreezeGui.MarginY := 0
        FreezeGui.Add("Picture", "w" vw " h" vh, "HBITMAP:*" hBmp)
        FreezeGui.Show("x" vx " y" vy " w" vw " h" vh " NoActivate")
        WinActivate(FreezeGui.Hwnd)
        HideCursor()
    } else {
        IsFrozen := false
        RestoreCursor()
        if IsObject(FreezeGui) {
            FreezeGui.Destroy()
            FreezeGui := ""
        }
    }
}

; ==========================================
; 3. Screen Blackout Lock (Win + Alt + Shift + Q)
; ==========================================
#!+q::ToggleBlackout()

ToggleBlackout() {
    global IsBlackout, BlackoutGui
    if !IsBlackout {
        DismissAllOverlays()
        IsBlackout := true
        
        vx := SysGet(76), vy := SysGet(77)
        vw := SysGet(78), vh := SysGet(79)
        
        BlackoutGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
        BlackoutGui.BackColor := "000000"
        BlackoutGui.Show("x" vx " y" vy " w" vw " h" vh " NoActivate")
        WinActivate(BlackoutGui.Hwnd)
        HideCursor()
    } else {
        IsBlackout := false
        RestoreCursor()
        if IsObject(BlackoutGui) {
            BlackoutGui.Destroy()
            BlackoutGui := ""
        }
    }
}

; ==========================================
; 4. Fake Windows 10 BSOD (Win + Alt + B)
; ==========================================
#!b::ToggleBSOD()

ToggleBSOD() {
    global IsBSOD, BSODGui, BSODPercent, BSODTextCtrl
    if !IsBSOD {
        DismissAllOverlays()
        IsBSOD := true
        BSODPercent := 0
        
        vx := SysGet(76), vy := SysGet(77)
        vw := SysGet(78), vh := SysGet(79)
        
        BSODGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
        BSODGui.BackColor := "0078D7"
        BSODGui.SetFont("cWhite", "Segoe UI Light")
        
        BSODGui.SetFont("s110")
        BSODGui.Add("Text", "x140 y110 BackgroundTrans", ":(")
        
        BSODGui.SetFont("s22")
        BSODGui.Add("Text", "x140 y310 w950 BackgroundTrans", "Your PC ran into a problem and needs to restart. We're just collecting some error info, and then we'll restart for you.")
        
        BSODTextCtrl := BSODGui.Add("Text", "x140 y435 w500 BackgroundTrans", "0% complete")
        
        BSODGui.SetFont("s11", "Segoe UI")
        BSODGui.Add("Text", "x140 y520 w750 BackgroundTrans", "For more information about this issue and possible fixes, visit https://www.windows.com/stopcode`n`nIf you call a support person, give them this info:`nStop code: CRITICAL_PROCESS_DIED")
        
        BSODGui.Show("x" vx " y" vy " w" vw " h" vh " NoActivate")
        WinActivate(BSODGui.Hwnd)
        HideCursor()
        SetTimer UpdateBSODProgress, 2500
    } else {
        IsBSOD := false
        SetTimer UpdateBSODProgress, 0
        RestoreCursor()
        if IsObject(BSODGui) {
            BSODGui.Destroy()
            BSODGui := ""
        }
    }
}

UpdateBSODProgress() {
    global IsBSOD, BSODPercent, BSODTextCtrl
    if !IsBSOD
        return
    if (BSODPercent < 99) {
        BSODPercent += Random(1, 6)
        if (BSODPercent > 99)
            BSODPercent := 99
        try BSODTextCtrl.Value := BSODPercent "% complete"
    }
}

; ==========================================
; 5. Fake Windows Update Screen (Win + Alt + Shift + B)
; ==========================================
#!+b::ToggleUpdate()

ToggleUpdate() {
    global IsUpdating, UpdateGui, UpdatePercent, UpdateTextCtrl
    if !IsUpdating {
        DismissAllOverlays()
        IsUpdating := true
        UpdatePercent := Random(12, 23)
        
        vx := SysGet(76), vy := SysGet(77)
        vw := SysGet(78), vh := SysGet(79)
        
        UpdateGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
        UpdateGui.BackColor := "006DAE"
        UpdateGui.SetFont("s20 cWhite", "Segoe UI Light")
        
        UpdateTextCtrl := UpdateGui.Add("Text", "x0 y" (vh // 2 - 40) " w" vw " Center BackgroundTrans", "Working on updates " UpdatePercent "% complete.`nDon't turn off your PC. This will take a while.")
        
        UpdateGui.SetFont("s13")
        UpdateGui.Add("Text", "x0 y" (vh - 90) " w" vw " Center BackgroundTrans", "Your PC will restart several times")
        
        UpdateGui.Show("x" vx " y" vy " w" vw " h" vh " NoActivate")
        WinActivate(UpdateGui.Hwnd)
        HideCursor()
        SetTimer UpdateProgressTick, 4000
    } else {
        IsUpdating := false
        SetTimer UpdateProgressTick, 0
        RestoreCursor()
        if IsObject(UpdateGui) {
            UpdateGui.Destroy()
            UpdateGui := ""
        }
    }
}

UpdateProgressTick() {
    global IsUpdating, UpdatePercent, UpdateTextCtrl
    if !IsUpdating
        return
    if (UpdatePercent < 99) {
        UpdatePercent += Random(1, 3)
        if (UpdatePercent > 99)
            UpdatePercent := 99
        try UpdateTextCtrl.Value := "Working on updates " UpdatePercent "% complete.`nDon't turn off your PC. This will take a while."
    }
}

; ==========================================
; 6. Active Window Opacity (Win + Alt + Up / Down)
; ==========================================
#!Up::AdjustOpacity(20)
#!Down::AdjustOpacity(-20)

AdjustOpacity(delta) {
    hwnd := WinExist("A")
    if !hwnd
        return
    current := WinGetTransparent(hwnd)
    if (current = "")
        current := 255
    
    newAlpha := current + delta
    if (newAlpha >= 255) {
        WinSetTransparent "Off", hwnd
    } else {
        if (newAlpha < 40)
            newAlpha := 40
        WinSetTransparent newAlpha, hwnd
    }
}

; ==========================================
; 7. Smooth Accelerating Window Move & Resize
;    Move:   Win + Alt + H / J / K / L
;    Resize: Win + Alt + Shift + H / J / K / L
; ==========================================
#!h::AccelerateWindow("move", -1,  0, "h")
#!j::AccelerateWindow("move",  0,  1, "j")
#!k::AccelerateWindow("move",  0, -1, "k")
#!l::AccelerateWindow("move",  1,  0, "l")

#!+h::AccelerateWindow("resize", -1,  0, "h")
#!+j::AccelerateWindow("resize",  0,  1, "j")
#!+k::AccelerateWindow("resize",  0, -1, "k")
#!+l::AccelerateWindow("resize",  1,  0, "l")

AccelerateWindow(mode, dirX, dirY, triggerKey) {
    hwnd := WinExist("A")
    if !hwnd
        return
    if (WinGetMinMax(hwnd) = 1)
        WinRestore hwnd
        
    startTime := A_TickCount
    while GetKeyState(triggerKey, "P") {
        tenths := (A_TickCount - startTime) // 100
        step := Min(24, Round(2 + (tenths * 0.25) + (tenths * tenths * 0.01)))
        
        WinGetPos &wx, &wy, &ww, &wh, hwnd
        if (mode = "move") {
            WinMove wx + (dirX * step), wy + (dirY * step),,, hwnd
        } else {
            newW := Max(150, ww + (dirX * step))
            newH := Max(100, wh + (dirY * step))
            WinMove ,, newW, newH, hwnd
        }
        Sleep 16
    }
}

; ==========================================
; 8. Hotkey Cheat-Sheet Overlay (Win + Alt + /)
; ==========================================
#!/::ToggleHelpGui()

ToggleHelpGui() {
    global HelpGui
    if IsObject(HelpGui) {
        HelpGui.Destroy()
        HelpGui := ""
        return
    }
    
    HelpGui := Gui("+AlwaysOnTop -Caption +Border +ToolWindow")
    HelpGui.BackColor := "1E1E2E"
    HelpGui.MarginX := 24
    HelpGui.MarginY := 20
    
    HelpGui.SetFont("s13 Bold c89B4FA", "Segoe UI")
    HelpGui.Add("Text", "w460", "Active AutoHotkey Shortcuts")
    
    HelpGui.SetFont("s10 Norm cCDD6F4", "Consolas")
    keybinds := (
        "Win + Alt + Z           Toggle Taskbar Visibility`n"
        "Win + Alt + Q           Fake Screen Freeze (3m Idle Auto)`n"
        "Win + Alt + Shift + Q   True Blackout Lock`n"
        "Win + Alt + B           Fake Windows 10 BSOD`n"
        "Win + Alt + Shift + B   Fake Windows Update Screen`n"
        "Win + Alt + Up / Down   Adjust Window Opacity`n"
        "Win + Alt + H/J/K/L     Move Active Window (Smooth Accel)`n"
        "Win + Alt + Shift+HJKL  Resize Active Window (Smooth Accel)`n"
        "Win + Alt + /           Toggle This Cheat Sheet"
    )
    HelpGui.Add("Text", "y+14 w460", keybinds)
    
    HelpGui.SetFont("s9 Italic cA6ADC8", "Segoe UI")
    HelpGui.Add("Text", "y+14 w460", "Press Win + Alt + / again to close")
    
    HelpGui.Show("Center")
}

; ==========================================
; Input Blocker While Any Lock Overlay Is Active
; ==========================================
#HotIf (IsFrozen || IsBSOD || IsUpdating || IsBlackout)
LButton::return
RButton::return
MButton::return
WheelUp::return
WheelDown::return
!Tab::return
!F4::return
#d::return
#e::return
#r::return
#Tab::return
Esc::return
Space::return
Enter::return
*Backspace::return
*Delete::return
*a::return
*b::return
*c::return
*d::return
*e::return
*f::return
*g::return
*h::return
*i::return
*j::return
*k::return
*l::return
*m::return
*n::return
*o::return
*p::return
*q::return
*r::return
*s::return
*t::return
*u::return
*v::return
*w::return
*x::return
*y::return
*z::return
#HotIf

; ==========================================
; Helper Functions (Screen Capture & Cursor)
; ==========================================
CaptureVirtualScreen() {
    vx := SysGet(76), vy := SysGet(77)
    vw := SysGet(78), vh := SysGet(79)
    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    hbm := DllCall("CreateCompatibleBitmap", "Ptr", hdcScreen, "Int", vw, "Int", vh, "Ptr")
    obm := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hbm, "Ptr")
    DllCall("BitBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", vw, "Int", vh, "Ptr", hdcScreen, "Int", vx, "Int", vy, "UInt", 0x40CC0020)
    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", obm)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    return hbm
}

HideCursor() {
    static SystemCursors := [32512, 32513, 32514, 32515, 32516, 32640, 32641, 32642, 32643, 32644, 32645, 32646, 32648, 32649, 32650]
    andMask := Buffer(128, 0xFF)
    xorMask := Buffer(128, 0x00)
    for id in SystemCursors {
        hCursor := DllCall("CreateCursor", "Ptr", 0, "Int", 0, "Int", 0, "Int", 32, "Int", 32, "Ptr", andMask, "Ptr", xorMask, "Ptr")
        DllCall("SetSystemCursor", "Ptr", hCursor, "UInt", id)
    }
}

RestoreCursor() {
    DllCall("SystemParametersInfo", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0)
}

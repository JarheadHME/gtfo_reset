SetTitleMatchMode(3)
#Requires AutoHotkey v2.0.2

#Include <classMemory>

config_file_name := "config.ini"

BackSpace::
{
    ExitApp
}

;initialize as globals so the repeating functions can access them
mem := []
moduleBase := 0
cursor_x_ptr := []
cursor_y_ptr := []

main() {
    answer := MsgBox("Create a new config file? (will overwrite one if it already exists)", "Create?", 0x24)
    if answer = "No"
        ExitApp

    MsgBox("Script will now attempt to read GTFO`nYou can exit the config creator at any time by pressing 'Backspace'")

    ToolTip("Waiting for game to be open, press 'Backspace' to exit at any time")
    check_game_open:
    if !WinExist("GTFO ahk_class UnityWndClass ahk_exe GTFO.exe") {
        goto check_game_open
    }
    ToolTip()
    global mem := _ClassMemory("GTFO ahk_class UnityWndClass ahk_exe GTFO.exe",, &hProcessCopy)

    global moduleBase := mem.getModuleBaseAddress("GameAssembly.dll")
    global cursor_x_ptr := [moduleBase + 0x326d9b8, "Float", 0x200]
    global cursor_y_ptr := [moduleBase + 0x326d9b8, "Float", 0x204]

    ; Prompt for coordinates of the relevant buttons
    write_pairs_to_ini(get_corners("Retire to Lobby"), "retire", "coordinates")
    write_pairs_to_ini(get_corners("Retire to Lobby (confirm/hold)"), "retire_confirm", "coordinates")
    write_pairs_to_ini(get_corners("Ready"), "ready", "coordinates")
    write_pairs_to_ini(get_corners("Initialize Cage Drop"), "drop", "coordinates")


    ToolTip("Move your cursor to the left of the screen,`nand then press 'g'`n(This is to determine your sensitivity)")
    KeyWait("g", "D")
    normal := 750.0
    x1 := mem.read(cursor_x_ptr*)
    move_cursor(500, 0)
    x2 := mem.read(cursor_x_ptr*)
    diff := x2-x1
    sens := diff/normal
    ToolTip()
    IniWrite(sens, config_file_name, "input", "game_mouse_sensitivity")
    
    HotKeyGui := Gui("-SysMenu", "Input Hotkey to trigger reset")
    hotkey := HotKeyGui.Add("Hotkey", "vChosenHotkey")
    ok_button := HotKeyGui.AddButton(,"OK")
    ok_button.OnEvent("Click", ok_button_clicked)
    HotKeyGui.Show("W640 H480")
    Pause()
    
    chosen_hotkey := hotkey.Value
    HotKeyGui.Destroy()
    IniWrite(chosen_hotkey, config_file_name, "input", "hotkey")

    IniWrite(0, config_file_name, "notice", "notice")

    MsgBox("Your config file is now finished!")

    ExitApp
}

OnExit() {
    mem := []
}

move_cursor(x, y) {
    DllCall("mouse_event", "UInt", 0x01, "UInt", x, "UInt", y)
    Sleep(50)
}

; Arrow hotkeys to move the cursor by small amounts in the game to be more precise
#HotIf WinActive("GTFO ahk_class UnityWndClass ahk_exe GTFO.exe")
Up::move_cursor(0, -1)
Down::move_cursor(0, 1)
Left::move_cursor(-1, 0)
Right::move_cursor(1, 0)
Enter:: {
    Click("Down")
    KeyWait("Enter")
    Click("Up")
}

get_corners(full_text) {
    pairs := Map()

    KeyWait("g") ; make extra sure it's not being pressed to start with

    ToolTip("Put cursor over top-left of '" . full_text . "' button`nThen press 'g'`n(Can use arrow keys to move mouse in small amounts,`nand Enter to click)")
    KeyWait("g", "D")
    x := mem.read(cursor_x_ptr*)
    y := mem.read(cursor_y_ptr*)
    pair := Map("x", x, "y", y)
    pairs["top_left"] := pair
    ToolTip()

    KeyWait("g") ; wait for the key to be released before trying to proceed further

    ToolTip("Put cursor over bottom-right of '" . full_text . "' button`nThen press 'g'`n(Can use arrow keys to move mouse in small amounts,`nand Enter to click)")
    KeyWait("g", "D")
    x := mem.read(cursor_x_ptr*)
    y := mem.read(cursor_y_ptr*)
    pair := Map("x", x, "y", y)
    pairs["bottom_right"] := pair
    
    KeyWait("g") ; make sure it's not pressed before continuing

    return pairs
}

write_pairs_to_ini(map_var, name, section) {
    for k, v in map_var
        for k2, v2 in v
            IniWrite(v2, config_file_name, section, name "_" k "_" k2)
}

ok_button_clicked(x, y) {
    Pause(0)
    return
}

main()
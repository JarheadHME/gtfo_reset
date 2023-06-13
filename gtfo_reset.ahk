SetTitleMatchMode(3)
#Requires AutoHotkey v2.0.2

#Include <classMemory>
; from https://github.com/JarheadHME/classMemory-v2/
; forked and modified from https://github.com/Azerate218/classMemory-v2

config_file_name := "config.ini"

try
    load_config()
catch Error {
    MsgBox("Valid 'config.ini' not found`nPlease use the reset_config_maker")
    ExitApp
}
notice := IniRead(config_file_name, "notice", "notice")*1
if !notice {
    response := MsgBox("Config loaded.`nExit at any time with Ctrl + Backspace.`n`nOr you can find the H icon in your task tray,`nright click it, and click exit.`n`nClick Cancel to not see this next time this is started.",, "OC")
    if response = "Cancel"
        IniWrite(1, config_file_name, "notice", "notice")
}

^Backspace:: {
    ExitApp()
}

check_game_open:
if !WinExist("GTFO ahk_class UnityWndClass ahk_exe GTFO.exe")
    goto check_game_open
mem := _ClassMemory("GTFO ahk_class UnityWndClass ahk_exe GTFO.exe",, &hProcessCopy)
moduleBase := mem.getModuleBaseAddress("GameAssembly.dll")
cursor_x_ptr := [moduleBase + 0x326d9b8, "Float", 0x200]
cursor_y_ptr := [moduleBase + 0x326d9b8, "Float", 0x204]

; the value in the map is an array in the order of: Hold Length, Delay After Release, both in milliseconds
button_delays := Map("retire", [50, 100], "retire_confirm", [1200, 3000], "ready", [1000, 0], "drop", [2000, 0])

HotIfWinActive("GTFO ahk_class UnityWndClass ahk_exe GTFO.exe")
Hotkey(chosen_hotkey, reset)
reset(_) ; var is hotkey name, but we don't care about it
{
    ; pause first, then start going through the buttons to press in order
    Send("{Escape}")

    for button in buttons {
        ;ToolTip(button) ; debugging
        button_coords_map := coordinates[button]
        
        cursor_calc_and_move:
        calc_cursor_distance(button_coords_map, &dx, &dy)
        ;MsgBox(dx, dy)
        move_cursor(dx, -dy) ; invert dy because upwards movement in game is positive, but is negative from windows
        Sleep(200) ; try to wait long enough for the movement to finish going through
        if !is_inside(unpack_map(button_coords_map)*) ; if the cursor isn't inside of the button, try to move it again
            goto cursor_calc_and_move

        hold_button(button_delays[button][1]) ; refer to button_delays declaration, L33
        Sleep(button_delays[button][2])
        ToolTip() ; debugging

    }
    

}

OnExit() {
    mem := []
}

move_cursor(x, y) {
    DllCall("mouse_event", "UInt", 0x01, "UInt", x, "UInt", y)
    Sleep(100)
}
hold_button(delay:=1000) {
    Click("Down")
    Sleep(delay) ; how long to hold mouse button
    Click("Up")
}
get_cursor(&x, &y) {
    x := mem.read(cursor_x_ptr*)
    y := mem.read(cursor_y_ptr*)
}

get_midpoint(x1, y1, x2, y2) {
    mid_x := (x1 + x2) / 2.0
    mid_y := (y1 + y2) / 2.0
    return [mid_x, mid_y]
}

is_inside(x1, y1, x2, y2) {
    get_cursor(&pointx, &pointy)
    return ( ((pointx > Min(x1, x2)) && (pointx < Max(x1, x2))) && ((pointy > Min(y1, y2)) && (pointy < Max(y1, y2))) )
}

calc_cursor_distance(map_coords, &xdist, &ydist) {
    get_cursor(&x, &y)
    coords := unpack_map(map_coords)
    midpoint := get_midpoint(coords*)
    xdist := (midpoint[1] - x) / mouse_sens / 1.5
    ydist := (midpoint[2] - y) / mouse_sens / 1.5
}

unpack_map(map_coords) { ; ordered as x1, y1, x2, y2
    return [map_coords["x1"], map_coords["y1"], map_coords["x2"], map_coords["y2"]]
}

load_config() {
    global
    coordinates := Map()
    chosen_hotkey := IniRead(config_file_name, "input", "hotkey")
    mouse_sens := IniRead(config_file_name, "input", "game_mouse_sensitivity") * 1.0

    buttons := ["retire", "retire_confirm", "ready", "drop"]
    for i, name in buttons {
        local coords := Map()
        coords["x1"] := IniRead(config_file_name, "coordinates", name . "_top_left_x") * 1.0
        coords["x2"] := IniRead(config_file_name, "coordinates", name . "_bottom_right_x") * 1.0
        coords["y1"] := IniRead(config_file_name, "coordinates", name . "_top_left_y") * 1.0
        coords["y2"] := IniRead(config_file_name, "coordinates", name . "_bottom_right_y") * 1.0
        coordinates[name] := coords
    }

}
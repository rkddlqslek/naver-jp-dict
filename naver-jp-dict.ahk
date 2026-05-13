#Requires AutoHotkey v2.0
#SingleInstance Force

global SearchGui := 0

^+j::ToggleOrSearch()

ToggleOrSearch() {
    global SearchGui
    if SearchGui {
        try {
            hwnd := SearchGui.Hwnd
            if WinExist("ahk_id " hwnd) {
                if WinActive("ahk_id " hwnd) {
                    WinMinimize("ahk_id " hwnd)
                } else {
                    if WinGetMinMax("ahk_id " hwnd) = -1
                        WinRestore("ahk_id " hwnd)
                    WinActivate("ahk_id " hwnd)
                }
                return
            }
        }
    }
    ShowSearchGui()
}

ShowSearchGui() {
    global SearchGui
    SearchGui := Gui("+MinimizeBox", "네이버 일본어 사전")
    SearchGui.SetFont("s10")
    SearchGui.Add("Text", "x12 y10", "검색어를 입력하세요")
    edit := SearchGui.Add("Edit", "x12 y+6 w320 vQuery")
    SearchGui.Add("Button", "x172 y+10 w80 Default", "확인").OnEvent("Click", DoSearch)
    SearchGui.Add("Button", "x+10 w80", "취소").OnEvent("Click", (*) => CloseGui())
    SearchGui.OnEvent("Close", (*) => CloseGui())
    SearchGui.OnEvent("Escape", (*) => CloseGui())
    SearchGui.Show()
    edit.Focus()
}

DoSearch(*) {
    global SearchGui
    if !SearchGui
        return
    saved := SearchGui.Submit(false)
    if saved.Query != ""
        Run("https://ja.dict.naver.com/#/search?query=" UriEncode(saved.Query))
    CloseGui()
}

CloseGui() {
    global SearchGui
    if SearchGui {
        try SearchGui.Destroy()
        SearchGui := 0
    }
}

UriEncode(str) {
    static doc := 0
    if !doc {
        doc := ComObject("HTMLfile")
        doc.write("<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
    }
    return doc.parentWindow.encodeURIComponent(str)
}

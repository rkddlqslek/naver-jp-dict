#Requires AutoHotkey v2.0
#SingleInstance Force

global SearchGui := 0
global DictTab := 0
global SearchEdit := 0
global SuggestList := 0
global SuggestItems := []
global LastSuggestQuery := ""
global CurrentDict := "jako"
global DictConfigs := Map(
    "jako", { Label: "일본어", AcCode: "jako", HomeUrl: "https://ja.dict.naver.com/", SearchUrl: "https://ja.dict.naver.com/#/search?query=" },
    "enko", { Label: "영어", AcCode: "enko", HomeUrl: "https://en.dict.naver.com/", SearchUrl: "https://en.dict.naver.com/#/search?query=" },
    "koko", { Label: "국어", AcCode: "koko", HomeUrl: "https://ko.dict.naver.com/", SearchUrl: "https://ko.dict.naver.com/#/search?query=" }
)
global DictOrder := ["jako", "enko", "koko"]

#+j::ToggleOrSearch()

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
    ShowSearchGui(GetSelectedText())
}

ShowSearchGui(initialQuery := "") {
    global SearchGui, DictTab, SearchEdit, SuggestList, SuggestItems, LastSuggestQuery, CurrentDict
    SuggestItems := []
    LastSuggestQuery := ""
    CurrentDict := "jako"
    SearchGui := Gui("+MinimizeBox", "네이버 사전")
    SearchGui.SetFont("s10")
    DictTab := SearchGui.Add("Tab3", "x12 y10 w420 h28 Choose1", GetDictLabels())
    DictTab.OnEvent("Change", OnDictChanged)
    DictTab.UseTab()
    SearchGui.Add("Text", "x12 y+8", "검색어를 입력하세요")
    SearchEdit := SearchGui.Add("Edit", "x12 y+6 w420 vQuery")
    if initialQuery != ""
        SearchEdit.Value := initialQuery
    SearchEdit.OnEvent("Change", OnQueryChange)
    SuggestList := SearchGui.Add("ListBox", "x12 y+8 w420 r6 vSuggestionList Hidden")
    SuggestList.OnEvent("DoubleClick", UseSuggestion)
    SearchGui.Add("Button", "x272 y+10 w80 Default", "확인").OnEvent("Click", DoSearch)
    SearchGui.Add("Button", "x+10 w80", "취소").OnEvent("Click", (*) => CloseGui())
    SearchGui.OnEvent("Close", (*) => CloseGui())
    SearchGui.OnEvent("Escape", (*) => CloseGui())
    SearchGui.Show()
    SearchEdit.Focus()
    if initialQuery != ""
        SetTimer(FetchAndShowSuggestions, -50)
}

OnDictChanged(tab, *) {
    global CurrentDict, SearchEdit, DictOrder
    if tab.Value >= 1 && tab.Value <= DictOrder.Length
        CurrentDict := DictOrder[tab.Value]
    ClearSuggestions()
    if SearchEdit && Trim(SearchEdit.Value) != ""
        SetTimer(FetchAndShowSuggestions, -50)
}

OnQueryChange(*) {
    SetTimer(FetchAndShowSuggestions, 0)
    SetTimer(FetchAndShowSuggestions, -300)
}

FetchAndShowSuggestions() {
    global SearchGui, SearchEdit, SuggestList, SuggestItems, LastSuggestQuery
    if !SearchGui || !SearchEdit || !SuggestList
        return

    query := Trim(SearchEdit.Value)
    if query = "" {
        ClearSuggestions()
        return
    }
    if query = LastSuggestQuery
        return

    LastSuggestQuery := query
    suggestions := FetchSuggestions(query)
    if !SearchGui || query != Trim(SearchEdit.Value)
        return

    SuggestItems := suggestions
    SuggestList.Delete()
    if suggestions.Length = 0 {
        SuggestList.Visible := false
        return
    }

    displayItems := []
    for item in suggestions
        displayItems.Push(item.Display)

    SuggestList.Add(displayItems)
    SuggestList.Choose(1)
    SuggestList.Visible := true
}

ClearSuggestions() {
    global SuggestList, SuggestItems, LastSuggestQuery
    SuggestItems := []
    LastSuggestQuery := ""
    if SuggestList {
        try SuggestList.Delete()
        SuggestList.Visible := false
    }
}

DoSearch(*) {
    global SearchGui, SuggestList, SuggestItems
    if !SearchGui
        return
    saved := SearchGui.Submit(false)
    query := saved.Query
    if SuggestList && SuggestList.Visible && SuggestList.Value > 0 && SuggestList.Value <= SuggestItems.Length
        query := SuggestItems[SuggestList.Value].Word
    if query != ""
        Run(GetSearchUrl(query))
    CloseGui()
}

UseSuggestion(*) {
    global SearchEdit, SuggestList, SuggestItems
    if !SearchEdit || !SuggestList || SuggestList.Value <= 0 || SuggestList.Value > SuggestItems.Length
        return

    SearchEdit.Value := SuggestItems[SuggestList.Value].Word
    DoSearch()
}

CloseGui() {
    global SearchGui, DictTab, SearchEdit, SuggestList
    if SearchGui {
        try SearchGui.Destroy()
        SearchGui := 0
        DictTab := 0
        SearchEdit := 0
        SuggestList := 0
    }
}

FetchSuggestions(query) {
    global CurrentDict
    config := GetDictConfig(CurrentDict)
    url := "https://ac-dict.naver.com/" config.AcCode "/ac?st=11&r_lt=10&q=" UriEncode(query) "&r_format=json&r_enc=UTF-8"
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(1000, 1000, 1000, 2000)
        http.Open("GET", url, false)
        http.SetRequestHeader("Accept", "*/*")
        http.SetRequestHeader("Accept-Language", "ko-KR,ko;q=0.9,en-US;q=0.6,en;q=0.4,ja;q=0.3")
        http.SetRequestHeader("Referer", GetRefererUrl())
        http.SetRequestHeader("User-Agent", "Mozilla/5.0 Windows AutoHotkey NaverDict")
        http.Send()
        if http.Status != 200
            return []
        return ParseSuggestions(http.ResponseText, config.AcCode)
    } catch {
        return []
    }
}

ParseSuggestions(json, dictCode) {
    suggestions := []
    seen := Map()
    q := Chr(34)
    if dictCode = "enko" {
        pattern := "\[\[\[" q "((?:[^" q "\\]|\\.)*)" q "\],\[" q "((?:[^" q "\\]|\\.)*)" q "\],\[" q "((?:[^" q "\\]|\\.)*)" q "\]\]"
        meaningIndex := 3
    } else {
        pattern := "\[\[\[" q "((?:[^" q "\\]|\\.)*)" q "\],\[" q "((?:[^" q "\\]|\\.)*)" q "\],\[" q "((?:[^" q "\\]|\\.)*)" q "\],\[" q "((?:[^" q "\\]|\\.)*)" q "\],\[" q "([^" q "]*)" q "\],\[" q dictCode q "\]\]"
        meaningIndex := 4
    }
    pos := 1
    while pos := RegExMatch(json, pattern, &match, pos) {
        word := JsonUnescape(match[1])
        reading := JsonUnescape(match[2])
        meaning := JsonUnescape(match[meaningIndex])
        if word != "" && !seen.Has(word) {
            seen[word] := true
            display := word
            if reading != ""
                display .= " / " reading
            if meaning != ""
                display .= " - " meaning
            suggestions.Push({ Word: word, Display: display })
        }
        pos += StrLen(match[0])
    }
    return suggestions
}

GetRefererUrl() {
    global CurrentDict
    return GetDictConfig(CurrentDict).HomeUrl
}

GetSearchUrl(query) {
    global CurrentDict
    return GetDictConfig(CurrentDict).SearchUrl UriEncode(query)
}

GetDictLabels() {
    global DictConfigs, DictOrder
    labels := []
    for dictCode in DictOrder
        labels.Push(DictConfigs[dictCode].Label)
    return labels
}

GetDictConfig(dictCode) {
    global DictConfigs
    return DictConfigs.Has(dictCode) ? DictConfigs[dictCode] : DictConfigs["jako"]
}

GetSelectedText() {
    savedClipboard := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    selectedText := ""
    if ClipWait(0.2)
        selectedText := Trim(A_Clipboard)
    A_Clipboard := savedClipboard
    return selectedText
}

JsonUnescape(str) {
    str := StrReplace(str, "\" Chr(34), Chr(34))
    str := StrReplace(str, "\\", "\")
    str := StrReplace(str, "\/", "/")
    str := StrReplace(str, "\b", Chr(8))
    str := StrReplace(str, "\f", Chr(12))
    str := StrReplace(str, "\n", "`n")
    str := StrReplace(str, "\r", "`r")
    str := StrReplace(str, "\t", "`t")
    return str
}

UriEncode(str) {
    static doc := 0
    if !doc {
        doc := ComObject("HTMLfile")
        doc.write("<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
    }
    return doc.parentWindow.encodeURIComponent(str)
}

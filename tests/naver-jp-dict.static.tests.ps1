$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot 'naver-jp-dict.ahk'
$gitignorePath = Join-Path $repoRoot '.gitignore'

$source = Get-Content -LiteralPath $scriptPath -Raw
$gitignore = Get-Content -LiteralPath $gitignorePath -Raw

function Assert-Contains {
    param(
        [string] $Haystack,
        [string] $Needle,
        [string] $Message
    )

    if (-not $Haystack.Contains($Needle)) {
        throw $Message
    }
}

Assert-Contains $gitignore 'naver-jp-dict.ini' 'Runtime settings file must be ignored by git.'

Assert-Contains $source 'global SettingsPath :=' 'Script must define a runtime settings path.'
Assert-Contains $source 'LoadLastDict()' 'Script must load the last selected dictionary.'
Assert-Contains $source 'SaveLastDict(CurrentDict)' 'Script must save dictionary changes.'
Assert-Contains $source 'GetDictTabIndex(CurrentDict)' 'Script must open the tab matching the remembered dictionary.'

Assert-Contains $source 'RegisterSearchHotkeys()' 'Search window must register keyboard navigation hotkeys.'
Assert-Contains $source 'UnregisterSearchHotkeys()' 'Search window must release keyboard navigation hotkeys on close.'
Assert-Contains $source 'HotIfWinActive("ahk_id " SearchGui.Hwnd)' 'Navigation hotkeys must be scoped to the search window.'
Assert-Contains $source 'Hotkey("Down", (*) => MoveSuggestion(1), "On")' 'Down arrow must be bound while the search window is active.'
Assert-Contains $source 'Hotkey("Up", (*) => MoveSuggestion(-1), "On")' 'Up arrow must be bound while the search window is active.'
Assert-Contains $source 'Hotkey("Tab", (*) => AcceptSuggestion(false), "On")' 'Tab must accept the selected suggestion without launching search.'
Assert-Contains $source 'MoveSuggestion(1)' 'Down arrow must move to the next suggestion.'
Assert-Contains $source 'MoveSuggestion(-1)' 'Up arrow must move to the previous suggestion.'
Assert-Contains $source 'AcceptSuggestion(false)' 'Tab must accept a suggestion without launching search.'

Write-Host 'Static checks passed.'

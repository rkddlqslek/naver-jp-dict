# naver-jp-dict

윈도우 전역 단축키로 네이버 사전을 빠르게 검색하는 AutoHotkey v2 스크립트.

## 동작

`Win + Shift + J`

- 검색창이 **없을 때** → 새 입력창이 뜸 (포커스 자동)
- 검색창이 **뒤에 있거나 최소화됨** → 앞으로 가져옴
- 검색창이 **앞에 있을 때** → 최소화

상단 탭에서 `일본어`, `영어`, `국어` 사전을 선택할 수 있다.

입력창에 검색어를 입력하면 선택한 네이버 사전의 자동완성 후보가 아래에 표시된다.

- 다른 프로그램에서 단어를 선택한 상태로 `Win + Shift + J`를 누르면 선택한 단어가 검색창에 자동 입력된다.
- `Enter` 또는 `확인` → 선택된 후보가 있으면 그 후보로 검색, 없으면 입력한 검색어로 검색
- 후보 더블클릭 → 해당 후보로 바로 검색
- `Esc` → 닫기

검색 결과는 선택한 사전에 따라 기본 브라우저에서 네이버 일본어사전, 영어사전, 국어사전 검색 페이지로 열린다.

## 요구사항

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/) 설치

## 실행

`naver-jp-dict.ahk` 파일을 더블클릭하거나 다음 명령으로 실행:

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" "naver-jp-dict.ahk"
```

## 부팅 시 자동 실행

`Win + R` → `shell:startup` 으로 시작프로그램 폴더를 연 뒤, `naver-jp-dict.ahk` 의 바로가기를 그 폴더에 만들면 부팅 시 자동 실행된다.

PowerShell 한 줄로 등록:

```powershell
$startup = [Environment]::GetFolderPath('Startup')
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path $startup 'naver-jp-dict.lnk'))
$lnk.TargetPath = 'C:\Program Files\AutoHotkey\v2\AutoHotkey.exe'
$lnk.Arguments = '"' + (Resolve-Path .\naver-jp-dict.ahk).Path + '"'
$lnk.Save()
```

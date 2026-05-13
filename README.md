# naver-jp-dict

윈도우 전역 단축키로 네이버 일본어사전을 빠르게 검색하는 AutoHotkey v2 스크립트.

## 동작

`Ctrl + Shift + J`

- 검색창이 **없을 때** → 새 입력창이 뜸 (포커스 자동)
- 검색창이 **뒤에 있거나 최소화됨** → 앞으로 가져옴
- 검색창이 **앞에 있을 때** → 최소화

입력창에서 `Enter`로 검색, `Esc`로 닫기. 검색 결과는 기본 브라우저에서 `https://ja.dict.naver.com/#/search?query=...` 로 열린다.

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

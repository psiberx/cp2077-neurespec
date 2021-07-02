:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@set GameDir=E:\Games\Cyberpunk 2077
@set SevenZipExe=C:\Program Files\7-Zip\7z.exe

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@set WorkDir=%CD%
@set DistDir=D:\Projects\Cyberpunk\NeureSpec\dist

@set ModPath=bin\x64\plugins\cyber_engine_tweaks\mods\NeureSpec

@findstr /r "[0-9]\.[0-9]\.[0-9]" "%GameDir%\%ModPath%\init.lua" > "%WorkDir%\release.ver"
@set /p Version=<"%WorkDir%\release.ver"
@set Version=%Version:~12,5%
@del /f "%WorkDir%\release.ver" > nul

@set ReleaseZip=%DistDir%\NeureSpec-%Version%.zip

@echo Version: %Version%
@echo Release: %ReleaseZip%

@if not exist "%DistDir%" mkdir "%DistDir%"
@if exist "%ReleaseZip%" del /f "%ReleaseZip%"

@cd "%GameDir%"

@"%SevenZipExe%" a -tzip -mx9 ^
	-x!"%ModPath%\.dev\" ^
	-x!"%ModPath%\.git\" ^
	-x!"%ModPath%\.idea\" ^
	-x!"%ModPath%\bin\" ^
	-x!"%ModPath%\dist\" ^
	-x!"%ModPath%\.gitignore" ^
	-x!"%ModPath%\debug.lua" ^
	-x!"%ModPath%\db.sqlite3" ^
	-x!"%ModPath%\*.log" ^
	"%ReleaseZip%" ^
	"%ModPath%" ^
	> nul

@echo Done.

@cd "%WorkDir%"

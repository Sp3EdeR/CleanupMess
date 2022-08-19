@echo off
setlocal EnableDelayedExpansion

for %%A in (%*) do (
	set arg=%%~A
	set arg1=!arg:~0,1!
	set optChars=/-
	for /f %%B in ("!arg1!") do if "!optChars:%%B=!" NEQ "!optChars!" (
		:: Option, starting with / or -
		if "!arg:~1!" EQU "h" (
			echo This is the software mess cleaner script for Windows.
			echo Usage: CleanupMess [/m] [/d] [batfile]
			echo Options:
			echo     /m: Runs without deleting anything. Can still write batfile.
			echo     /d: Strong Windows Update cleanup, uninstallation won't be available.
			echo     /p: Cleans up Paint Shop Pro thumbnails. These get auto-regenerated.
			echo     cmdfile: Writes deletion commands to the batfile.
			exit /b 0
		) else if "!arg:~1!" EQU "m" (
			set mock=y
		) else if "!arg:~1!" EQU "d" (
			set "dismSwitch=!dismSwitch! /ResetBase"
		) else if "!arg:~1!" EQU "p" (
			set pspThumbs=y
		) else (
			echo Unknown switch: !arg!.
			echo To display the help, run CleanupMess /h
			exit /b 0
		)
	) else (
		set cmdfile=!arg!
		del /q "!cmdfile!" 2>NUL
	)
)

:: Helper data to enumerate drives
set allLetters=a b c d e f g h i j k l m n o p q r s t u v w x y z

echo Clearing nVidia installer stuff...
call :DelDir C:\NVIDIA
call :DelDirs C:\Program Files\NVIDIA Corporation\Installer2\*
call :DelFiles C:\ProgramData\NVIDIA Corporation\NetService\*.exe

for /d %%U in ("C:\Users\*") do (
	echo Clearing %%~nU's user directory:
	set appdata=%%U\AppData\Roaming
	set localappdata=%%U\AppData\Local
	set locallowappdata=%%U\AppData\LocalLow

	echo   Clearing Opera caches...
	for /d %%D in ("!localappdata!\Opera Software\*") do (
		call :DelDir %%~fD\Cache
	)
	for /d %%D in ("!appdata!\Opera Software\*") do (
		call :DelDir %%~fD\Code Cache
		call :DelDir %%~fD\Crash Reports\reports
		call :DelDir %%~fD\GPUCache
		call :DelDir %%~fD\GrShaderCache
		call :DelDir %%~fD\IndexedDB
		call :DelDir %%~fD\Local Storage
		call :DelDir %%~fD\Service Worker\CacheStorage
		call :DelDir %%~fD\Service Worker\ScriptCache
	)

	echo   Clearing Chrome caches...
	call :DelDir !localappdata!\Google\Chrome\User Data\Default\Cache
	call :DelDir !localappdata!\Google\Chrome\User Data\Default\Code Cache
	call :DelDir !localappdata!\Google\Chrome\User Data\Default\GPUCache
	call :DelDir !localappdata!\Google\Chrome\User Data\GrShaderCache

	echo   Clearing Internet Explorer caches...
	call :DelContents !localappdata!\Microsoft\Windows\Temporary Internet Files
	call :DelContents !localappdata!\Microsoft\Windows\INetCache

	echo   Clearing Thunderbird cache...
	for /d %%D in ("!localappdata!\Thunderbird\Profiles\*.default") do (
		call :DelDir %%~fD\Cache
	)

	echo   Clearing Discord's caches...
	call :DelDir !appdata!\discord\Cache
	call :DelDir !appdata!\discord\Code Cache
	call :DelFiles !appdata!\discord\*.tmp
	call :DelFiles !appdata!\discord\*.log

	echo   Clearing All-in-One Messenger caches...
	for /d %%D in ("!appdata!\All-in-One Messenger\Partitions\*") do (
		call :DelDir %%~fD\Cache
		call :DelDir %%~fD\Code Cache
		call :DelDir %%~fD\GPUCache
		call :DelDir %%~fD\Service Worker\CacheStorage
		call :DelDir %%~fD\Service Worker\ScriptCache
	)

	echo   Clearing Steam HTML cache...
	call :DelDir !localappdata!\Steam\htmlcache

	echo   Clearing Google Drive FS Logs...
	call :DelDir !localappdata!\Google\DriveFS\Logs

	echo   Clearing Google Earth cache...
	call :DelDir !locallowappdata!\Google\GoogleEarth\Cache\unified_cache_leveldb_leveldb2

	echo   Clearing Paint Shop Pro caches...
	call :DelDir !appdata!\Corel\Messages
	call :DelDir !appdata!\Corel\PaintShop Photo Pro\Cache
	if defined pspThumbs (
		call :DelDir !localappdata!\Corel PaintShop Pro\2021\Thumbs
	)

	echo   Clearing Visual Studio Code's caches...
	call :DelDir !appdata!\Code\Cache
	call :DelDir !appdata!\Code\CachedData
	call :DelDir !appdata!\Code\Service Worker\CacheStorage
	call :DelDir !appdata!\Code\Service Worker\ScriptCache

	echo   Clearing qBittorrent Logs...
	call :DelDir !localappdata!\qBittorrent\logs

	echo   Clearing the temp folder...
	call :DelContents %%~fU\AppData\Local\Temp
)

echo Clearing global temp folders...
call :DelContents C:\Windows\Temp

echo Clearing the Windows Update download cache...
call :DelContents C:\Windows\SoftwareDistribution\Download

echo Clearing the Windows Prefetch
call :DelFiles C:\Windows\Prefetch\*

:: Recycle bin cleanup
set/p= Emptying the recycle bin: <NUL
for %%C in (%allLetters%) do (
	set recyclebin=%%C:\$RECYCLE.BIN
	if exist !recyclebin! (
		set/p= %%C: <NUL
		call :DelDir !recyclebin!
	)
)
echo.

:: Cleanup manager autoclean
set/p= Running the cleanup manager: <NUL
for %%C in (%allLetters%) do (
	if exist %%C:\ (
		set/p= %%C: <NUL
		if not defined mock (
			cleanmgr /d %%C /autoclean
		)
		if defined cmdfile (
			echo cleanmgr /d %%C /autoclean 1>>"%cmdfile%"
		)
	)
)
echo.

echo Start running the Windows Component Cleanup task...
if not defined mock (
	Dism.exe /online /Cleanup-Image /StartComponentCleanup %dismSwitch%
)
if defined cmdfile (
	echo Dism.exe /online /Cleanup-Image /StartComponentCleanup %dismSwitch% 1>>"%cmdfile%"
)

exit /b 0

:DelFiles
if not defined mock (
	del /f /s /q "%*" 1>NUL 2>NUL
	del /f /s /q /a:h "%*" 1>NUL 2>NUL
)
if defined cmdfile (
	echo del /f /s /q "%*" 1^>NUL 2^>NUL 1>>"%cmdfile%"
	echo del /f /s /q /a:h "%*" 1^>NUL 2^>NUL 1>>"%cmdfile%"
)
exit /b 0

:DelDir
if not defined mock (
	rmdir /s /q "%*" 2>NUL
)
if defined cmdfile (
	echo rmdir /s /q "%*" 2^>NUL 1>>"%cmdfile%"
)
exit /b 0

:DelDirs
call :GetFileDir "%*"
:: Finds hidden directories as well
for /f "tokens=* delims=" %%D in ('dir /b /ad "%*" 2^>NUL') do (
	call :DelDir %dir%%%D
)
exit /b 0

:DelContents
call :DelFiles %*\*
call :DelDirs %*\*
exit /b 0

:: Trims the "file" off the path into %dir%
:GetFileDir
set dir=%~dp1
exit /b 0

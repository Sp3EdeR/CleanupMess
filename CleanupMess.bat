@echo off
setlocal EnableDelayedExpansion
if "%1" EQU "/?" call :PrintHelp & exit /b 0
call :InitGlobals
call :ParseArgs %*
if errorlevel 1 exit /b 0
call :AdminCheck

:: Cleanup operations

if not defined skipnvidia (
	echo Clearing nVidia installer stuff...
	call :DelDir C:\NVIDIA
	call :DelDirs C:\Program Files\NVIDIA Corporation\Installer2\*
	call :DelFiles C:\ProgramData\NVIDIA Corporation\NetService\*.exe
)

for /d %%U in ("C:\Users\*") do (
	echo Clearing %%~nU's user directory:
	set appdata=%%U\AppData\Roaming
	set localappdata=%%U\AppData\Local
	set locallowappdata=%%U\AppData\LocalLow

	if not defined skipopera (
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
	)

	if not defined skipchrome (
		echo   Clearing Chrome caches...
		call :DelDir !localappdata!\Google\Chrome\User Data\Default\Cache
		call :DelDir !localappdata!\Google\Chrome\User Data\Default\Code Cache
		call :DelDir !localappdata!\Google\Chrome\User Data\Default\GPUCache
		call :DelDir !localappdata!\Google\Chrome\User Data\GrShaderCache
	)

	if not defined skipinetexpl (
		echo   Clearing Internet Explorer caches...
		call :DelContents !localappdata!\Microsoft\Windows\Temporary Internet Files
		call :DelContents !localappdata!\Microsoft\Windows\INetCache
	)

	if not defined skipthunderbird (
		echo   Clearing Thunderbird cache...
		for /d %%D in ("!localappdata!\Thunderbird\Profiles\*.default") do (
			call :DelDir %%~fD\Cache
		)
	)

	if not defined skipdiscord (
		echo   Clearing Discord's caches...
		call :DelDir !appdata!\discord\Cache
		call :DelDir !appdata!\discord\Code Cache
		call :DelFiles !appdata!\discord\*.tmp
		call :DelFiles !appdata!\discord\*.log
	)

	if not defined skipaiomessenger (
		echo   Clearing All-in-One Messenger caches...
		for /d %%D in ("!appdata!\All-in-One Messenger\Partitions\*") do (
			call :DelDir %%~fD\Cache
			call :DelDir %%~fD\Code Cache
			call :DelDir %%~fD\GPUCache
			call :DelDir %%~fD\Service Worker\CacheStorage
			call :DelDir %%~fD\Service Worker\ScriptCache
		)
	)

	if not defined skipsteam (
		echo   Clearing Steam HTML cache...
		call :DelDir !localappdata!\Steam\htmlcache
	)

	if not defined skipgdrive (
		echo   Clearing Google Drive FS Logs...
		call :DelDir !localappdata!\Google\DriveFS\Logs
	)

	if not defined skipgearth (
		echo   Clearing Google Earth cache...
		call :DelDir !locallowappdata!\Google\GoogleEarth\Cache\unified_cache_leveldb_leveldb2
	)

	if not defined skippsp (
		echo   Clearing Paint Shop Pro caches...
		call :DelDir !appdata!\Corel\Messages
		call :DelDir !appdata!\Corel\PaintShop Photo Pro\Cache
		if defined pspThumbs (
			call :DelDir !localappdata!\Corel PaintShop Pro\2021\Thumbs
		)
	)

	if not defined skipvscode (
		echo   Clearing Visual Studio Code's caches...
		call :DelDir !appdata!\Code\Cache
		call :DelDir !appdata!\Code\CachedData
		call :DelDir !appdata!\Code\Service Worker\CacheStorage
		call :DelDir !appdata!\Code\Service Worker\ScriptCache
	)

	if not defined skipas (
		echo   Clearing Android Studio crash logs
		call :DelFiles %%~fU\java_error_in_studio64.hprof
		if not defined androidUser (
			echo   Clearing Android Studio Logs and Cache...
			call :DelDir %%~fU\.android\breakpad
			call :DelDir %%~fU\.android\cache
		)
		if not defined androidGradle (
			echo   Clearing Android Studio Gradle Cache and Temp...
			call :DelDir %%~fU\.gradle\.tmp
			call :DelDir %%~fU\.gradle\caches
		)
	)

	if not defined skipqbittorrent (
		echo   Clearing qBittorrent Logs...
		call :DelDir !localappdata!\qBittorrent\logs
	)

	if not defined skiptrakts if exist "!appdata!\trakt-scrobbler\trakt_scrobbler.log" (
		echo   Clearing Trakt Scrobbler Logs...
		for /f "tokens=*" %%T in ('where trakts 2^>NUL') do set "traktsdir=%%~dpT\"
		if not exist "!traktsdir!trakts.exe" if defined PIPX_BIN_DIR set "traktsdir=%PIPX_BIN_DIR%\"
		if exist "!traktsdir!trakts.exe" (
			if not defined mock ( "!traktsdir!trakts.exe" stop >NUL 2>NUL )
			if defined outfile ( echo "!traktsdir!trakts.exe" stop ^>NUL 2^>NUL )
		)
		call :DelFiles !appdata!\trakt-scrobbler\trakt_scrobbler.log
		if exist "!traktsdir!trakts.exe" (
			if not defined mock (
				pushd "!traktsdir!"
				"!traktsdir!trakts.exe" start >NUL 2>NUL
				popd
			)
			if defined outfile (
				echo pushd "!traktsdir!"
				echo "!traktsdir!trakts.exe" start ^>NUL 2^>NUL
				echo popd
			)
		)
	)

	if not defined skiptemp (
		echo   Clearing the temp folder...
		call :DelContents %%~fU\AppData\Local\Temp
	)
)

if not defined skipas (
	if defined androidUser (
		echo Clearing Android Studio Logs and Cache...
		call :DelDir !androidUser!\breakpad
		call :DelDir !androidUser!\cache
	)
	if defined androidGradle (
		echo Clearing Android Studio Gradle Cache and Temp...
		call :DelDir !androidGradle!\.tmp
		call :DelDir !androidGradle!\caches
	)
)

if not defined skiptemp (
	echo Clearing global temp folders...
	call :DelContents C:\Windows\Temp
)

if not defined skipwinupd (
	echo Clearing the Windows Update download cache...
	call :DelContents C:\Windows\SoftwareDistribution\Download
)

if not defined skipprefetch (
	echo Clearing the Windows Prefetch
	call :DelFiles C:\Windows\Prefetch\*
)

if not defined skiprecyclebin (
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
)

if not defined skipcleanmgr (
	:: Cleanup manager autoclean
	set/p= Running the cleanup manager: <NUL
	for %%C in (%allLetters%) do (
		if exist %%C:\ (
			set/p= %%C: <NUL
			if not defined mock (
				cleanmgr /d %%C /autoclean
			)
			if defined outfile (
				echo cleanmgr /d %%C /autoclean 1>>"%outfile%"
			)
		)
	)
	echo.
)

if not defined skipdism (
	echo Start running the Windows Component Cleanup task...
	if not defined mock (
		Dism.exe /online /Cleanup-Image /StartComponentCleanup %dismSwitch%
	)
	if defined outfile (
		echo Dism.exe /online /Cleanup-Image /StartComponentCleanup %dismSwitch% 1>>"%outfile%"
	)
)

exit /b 0

:: End of cleanup code; cleanup code follows

:: New cleanup addition workflow reminder:
:: - Add documentation to :PrintHelp
:: - Add new skip name to :InitGlobals
:: - Add new command line arguments to :ParseArgs if any

:PrintHelp
:: Option, starting with / or -
echo This is the software mess cleaner script for Windows.
echo Usage: CleanupMess ["options"] outfile
echo Options (separated by space):
echo     /h: Displays this message.
echo     /m: Doesn't do anything, just prints commands to stderr.
echo         "CleanupMess /m 2>commands.bat" writes the commands to commands.bat.
echo     /s stepnames: Skips cleaning the listed steps.
echo         Stepnames is a colon (:) separated list, e.g. recyclebin:dism
echo         For skippable cleanup operation names, see the below list.
echo.
echo     /ag "dir": The gradle directory (default: %userprofile%\.gradle)
echo     /au "dir": The android user directory (default: %userprofile%\.android)
echo     /d: Strong Windows component cleanup, uninstallation won't be available.
echo     /pspt: Cleans up Paint Shop Pro thumbnails. These get auto-regenerated.
echo.
echo Positional arguments:
echo     outfile: Writes all commands to the given file. See also: /m.
echo.
echo Supported cleanup operations (skip if unwanted steps with /s):
echo - All-in-one messenger chat app (/s aiomessenger)
echo - Android Studio integrated developer environment (/s as)
echo - Chrome web browser caches (/s chrome)
echo - Discord chat app (/s discord)
echo - Google Drive Desktop client (/s gdrive)
echo - Google Earth client (/s gearth)
echo - Internet Explore and Edge web browser caches (/s inetexpl)
echo - nVidia video driver installation temporaries (/s nvidia)
echo - Opera web browser caches (/s opera)
echo - Paint Shop Pro graphics editor (/s psp)
echo - QBittorrent peer-to-peer file sharing client (/s qbittorrent)
echo - Recycle bin (/s recyclebin)
echo - Steam game client (/s steam)
echo - Temporary files (/s temp)
echo - Thunderbird e-mail client (/s thunderbird)
echo - Trakt Scrobbler (/s trakts)
echo - Visual Studio Code (/s vscode)
echo - Windows cleanup manager's autoclean (/s cleanmgr)
echo - Windows component (app installation cache) (/s dism)
echo - Windows prefetch (app preloads) (/s prefetch)
echo - Windows Update download cache (/s winupd)
exit /b 0

:InitGlobals
:: Skippable cleanups
set skippables=nvidia:opera:chrome:inetexpl:thunderbird:discord:aiomessenger:steam:gdrive:gearth:as:psp:vscode:qbittorrent:trakts:temp:winupd:prefetch:recyclebin:cleanmgr:dism
:: Helper data to enumerate drives
set allLetters=a b c d e f g h i j k l m n o p q r s t u v w x y z
:: DISM switch to clean up thoroughly; prevents component uninstallation
set dismresetarg=/ResetBase
exit /b 0

:ParseArgs
:: Command line argument handling
for %%A in (%*) do (
	set arg=%%~A
	if defined switchArg (
		:: Option's arguments
		if !switchArg! EQU skips (
			for %%S in ("!arg::=" "!") do (
				set "supportedOpt="
				for %%T in ("%skippables::=" "%") do (
					if /i %%T EQU %%S ( set supportedOpt=y )
				)
				if not defined supportedOpt (
					echo Unsupported /s option: %%~S >&2
					exit /b 4
				)
				set skip%%~S=y
			)
		) else if !switchArg! EQU androidUser (
			set androidUser=!arg!
		) else if !switchArg! EQU androidGradle (
			set androidGradle=!arg!
		)
		set "switchArg="
	) else (
		set arg1=!arg:~0,1!
		set optChars=/-
		for /f %%B in ("!arg1!") do if "!optChars:%%B=!" NEQ "!optChars!" (
			:: Option switches
			if /i "!arg:~1!" EQU "h" (
				call :PrintHelp
				exit /b 1
			) else if /i "!arg:~1!" EQU "m" (
				set mock=y
			) else if /i "!arg:~1!" EQU "d" (
				set "dismSwitch=!dismSwitch! %dismresetarg%"
			) else if /i "!arg:~1!" EQU "pspt" (
				set pspThumbs=y
			) else if /i "!arg:~1!" EQU "s" (
				set switchArg=skips
			) else if /i "!arg:~1!" EQU "au" (
				set switchArg=androidUser
			) else if /i "!arg:~1!" EQU "ag" (
				set switchArg=androidGradle
			) else (
				echo Unknown switch: !arg!. >&2
				echo To display the help, run CleanupMess /h >&2
				exit /b 2
			)
		) else (
			:: Positional arguments
			if not defined outfile (
				set outfile=!arg!
				del /q "!outfile!" 2>NUL
			) else (
				echo Too many positional arguments: !arg! >&2
				exit /b 3
			)
		)
	)
)
:: Default values
if defined mock if not defined outfile (
	set "outfile=&2"
)
exit /b 0

:AdminCheck
cacls.exe "%SYSTEMROOT%\System32\config\system" 1>NUL 2>NUL
if errorlevel 1 (
	echo WARNING: Missing administrator privileges, some cleanups won't work.
	echo          Run this script as administrator to be able to do everything.
	echo.
	pause
)
exit /b 0

:DelFiles
if not defined mock (
	del /f /s /q "%*" 1>NUL 2>NUL
	del /f /s /q /a:h "%*" 1>NUL 2>NUL
)
if defined outfile (
	echo del /f /s /q "%*" 1^>NUL 2^>NUL 1>>"%outfile%"
	echo del /f /s /q /a:h "%*" 1^>NUL 2^>NUL 1>>"%outfile%"
)
exit /b 0

:DelDir
if not defined mock (
	rmdir /s /q "%*" 2>NUL
)
if defined outfile (
	echo rmdir /s /q "%*" 2^>NUL 1>>"%outfile%"
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

@echo off

set "NVM_USE_VERSION=1.0.0"

:: if NVM_HOME not defined, show message to install nvm-windows first and exit this script
if not defined NVM_HOME (
    @REM automatically detect the NVM_HOME path if not defined using where nvm.exe or equivalent
    for /f "delims=" %%i in ('where nvm 2^>nul') do (
        set "NVM_HOME=%%~dpi"
    )

    if defined NVM_HOME (
        echo [nvm-use] Detected NVM_HOME as: %NVM_HOME%
    ) else (
        echo [nvm-use] ERROR: NVM_HOME not defined. Install nvm-windows first.
        echo [nvm-use] NVM Installation Guides:
        echo [nvm-use] - https://www.nvmnode.com/guide/installation.html
        echo [nvm-use] - https://github.com/coreybutler/nvm-windows
        exit /b 1
    )
)

:: =====================================================================
:: Phase 1: The Anti-Pollution Path Guard
:: =====================================================================
:: Freeze the original, pristine system PATH on the very first run.
:: This variable persists across changes in the same terminal window.
if not defined USER_BASE_PATH (
    set "USER_BASE_PATH=%PATH%"
)

setlocal enabledelayedexpansion
set "SHOW_INFO="

:: =====================================================================
:: Phase 2: Target Version Resolution
:: =====================================================================
set "REQ_VER=%~1"
set "REQ_ACTION=%~2"

:: Smart Argument Flipper: If user types 'nvm-use default 22', swap them
:: so the rest of the script processes it as version '22' with action 'default'
if /i "!REQ_VER!"=="default" if not "!REQ_ACTION!"=="" if /i not "!REQ_ACTION!"=="default" (
    set "TEMP_VER=!REQ_VER!"
    set "REQ_VER=!REQ_ACTION!"
    set "REQ_ACTION=!TEMP_VER!"
)

:: =====================================================================
:: Smart Info, Help, Install Flag Interceptor
:: =====================================================================
if /i "!REQ_VER!"=="v"         set "SHOW_INFO=VER"
if /i "!REQ_VER!"=="ver"       set "SHOW_INFO=VER"
if /i "!REQ_VER!"=="version"   set "SHOW_INFO=VER"
if /i "!REQ_VER!"=="-v"        set "SHOW_INFO=VER"
if /i "!REQ_VER!"=="--v"       set "SHOW_INFO=VER"
if /i "!REQ_VER!"=="-ver"      set "SHOW_INFO=VER"
if /i "!REQ_VER!"=="--ver"     set "SHOW_INFO=VER"
if /i "!REQ_VER!"=="-version"  set "SHOW_INFO=VER"
if /i "!REQ_VER!"=="--version" set "SHOW_INFO=VER"

if /i "!REQ_VER!"=="-"         set "SHOW_INFO=HELP"
if /i "!REQ_VER!"=="--"        set "SHOW_INFO=HELP"
if /i "!REQ_VER!"=="h"         set "SHOW_INFO=HELP"
if /i "!REQ_VER!"=="help"      set "SHOW_INFO=HELP"
if /i "!REQ_VER!"=="-h"        set "SHOW_INFO=HELP"
if /i "!REQ_VER!"=="--h"       set "SHOW_INFO=HELP"
if /i "!REQ_VER!"=="-help"     set "SHOW_INFO=HELP"
if /i "!REQ_VER!"=="--help"    set "SHOW_INFO=HELP"
if "!REQ_VER!"=="?"            set "SHOW_INFO=HELP"
if "!REQ_VER!"=="/?"           set "SHOW_INFO=HELP"

if "!SHOW_INFO!"=="VER" (
    echo [nvm-use] version v!NVM_USE_VERSION!
    endlocal
    exit /b 0
)
if "!SHOW_INFO!"=="HELP" (
    echo Usage: nvm-use [version] [default]
    echo.
    echo Examples:
    echo   nvm-use               - Use the version specified in .node-version or .nvmrc, or stay on current/global-default if none found.
    echo   nvm-use 22            - Use the highest installed version matching 22.*
    echo   nvm-use v22.23.1      - Precise version matching
    echo   nvm-use 22 default    - Set the default version to the highest installed version matching 22.*
    echo   nvm-use default 22    - Set the default version to the highest installed version matching 22.*
    echo   nvm-use --help        - Displays command usage interface [also accepts -h, ?, /?]
    echo   nvm-use --version     - Displays the version of nvm-use [also accepts -v]
    endlocal
    exit /b 0
)

:: If no argument given, look for project configuration files
if "!REQ_VER!"=="" (
    if exist .node-version (
        set /p REQ_VER=<.node-version
    ) else if exist .nvmrc (
        set /p REQ_VER=<.nvmrc
    )
)

:: If still empty, exit gracefully and let the shell use the default fallback
if "!REQ_VER!"=="" (
    echo [nvm-use] No version specified and no .node-version/.nvmrc found.
    echo [nvm-use] Staying on current/global-default.
    REM Print confirmation using the newly mounted binary
    call node -v
    endlocal
    exit /b 0
)

:: Clean up input: remove quotes and strip a leading 'v' if present
set "REQ_VER=!REQ_VER:"=!"
if "!REQ_VER:~0,1!"=="v" set "REQ_VER=!REQ_VER:~1!"

:: Trim any trailing carriage returns or accidental spaces from file reading
for /f "tokens=1" %%a in ("!REQ_VER!") do set "REQ_VER=%%a"

:: =====================================================================
:: Phase 3: Smart Directory Matching & Highest Version Selection
:: =====================================================================
set "MATCH_COUNT=0"
set "TARGET_PATH="
set "TARGET_NAME="

if /i "!REQ_VER!" == "default" (
  set "TARGET_NAME=default"
) else (
    REM Loop through directories. The natural alphabetical sort ensures that
    REM higher dot-versions (e.g. v22.23.1 over v22.1.0) are processed last.
    for /d %%d in ("%NVM_HOME%\v!REQ_VER!*") do (
        if exist "%%d\node.exe" (
            set /a MATCH_COUNT+=1
            set "TARGET_PATH=%%d"
            set "TARGET_NAME=%%~nxd"
        )
    )
)

:: =====================================================================
:: Phase 4: Lazy-Loading / Installation Prompt
:: =====================================================================
if not defined TARGET_PATH if /i not "!REQ_VER!" == "default" (
    echo [nvm-use] Version "v!REQ_VER!" is not installed locally.
    set /p CHOICE="Would you like to download it now via nvm? [y/n]: "
    if /i "!CHOICE!"=="y" (
        endlocal
        nvm install "%~1"
        REM Re-run the script with the newly installed version
        call "%~f0" "%~1" "%~2"
        exit /b
    )
    endlocal
    exit /b 1
)

:: =====================================================================
:: Phase 5: Feedback Generation
:: =====================================================================
if !MATCH_COUNT! GTR 1 (
    echo [nvm-use] Found !MATCH_COUNT! matches. Auto-selecting highest version: !TARGET_NAME!
) else if /i not "!REQ_ACTION!" == "default" (
    echo [nvm-use] Switching to !TARGET_NAME!
)

:: =====================================================================
:: Phase 6: Export to Parent Environment & Verification
:: =====================================================================
:: The closing parenthesis trick ensures local variables are expanded
:: *before* endlocal discards the scope, safely rewriting the parent PATH.
endlocal & (
    set "PATH=%TARGET_PATH%;%USER_BASE_PATH%"
    set "X_TARGET_NAME=%TARGET_NAME%"
    set "X_REQ_ACTION=%REQ_ACTION%"
)

if /i "%X_REQ_ACTION%" == "default" (
    echo [nvm-use] Setting %X_TARGET_NAME% as default.
    nvm use "%X_TARGET_NAME%" 1>nul
)

:: Print confirmation using the newly mounted binary
call node -v
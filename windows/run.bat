@echo off
setlocal enabledelayedexpansion

set IMAGE_NAME=claude-code
set VOLUME_NAME=claude-home
set SCRIPT_DIR=%~dp0..

REM Prefer docker, fall back to podman
where docker >nul 2>nul
if %errorlevel% equ 0 (
    set RUNTIME=docker
    goto :found_runtime
)

where podman >nul 2>nul
if %errorlevel% equ 0 (
    set RUNTIME=podman
    goto :found_runtime
)

echo Error: neither docker nor podman found >&2
exit /b 1

:found_runtime
echo Using container runtime: %RUNTIME%

REM Check that the daemon is actually reachable
%RUNTIME% info >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: %RUNTIME% was found but the daemon is not running. >&2
    echo Please start Docker Desktop and try again. >&2
    exit /b 1
)

REM Build if image doesn't exist
%RUNTIME% image inspect %IMAGE_NAME% >nul 2>nul
if %errorlevel% neq 0 (
    echo Building image...
    %RUNTIME% build -t %IMAGE_NAME% -f "%SCRIPT_DIR%\Containerfile" "%SCRIPT_DIR%"
)

REM Create persistent volume if it doesn't exist
%RUNTIME% volume inspect %VOLUME_NAME% >nul 2>nul
if %errorlevel% neq 0 (
    echo Creating persistent volume '%VOLUME_NAME%'...
    echo You will need to run '/login' on first launch to authenticate.
    %RUNTIME% volume create %VOLUME_NAME%
)

REM Derive workspace path from current directory name
for %%I in ("%cd%") do set PROJECT_NAME=%%~nxI
set WORKSPACE_PATH=/workspace/%PROJECT_NAME%

REM Mount host config (read-only)
set HOST_MOUNTS=
if exist "%USERPROFILE%\.gitconfig" set "HOST_MOUNTS=-v "%USERPROFILE%\.gitconfig:/home/claude/.gitconfig:ro""
if exist "%USERPROFILE%\.ssh" set "HOST_MOUNTS=!HOST_MOUNTS! -v "%USERPROFILE%\.ssh:/home/claude/.ssh:ro""

REM Runtime-specific flags
if "%RUNTIME%"=="podman" (
    set RUNTIME_FLAGS=--userns=keep-id
) else (
    set RUNTIME_FLAGS=--cap-drop=ALL --security-opt=no-new-privileges
)

%RUNTIME% run --rm -it ^
    --network=bridge ^
    -w "%WORKSPACE_PATH%" ^
    %RUNTIME_FLAGS% ^
    %HOST_MOUNTS% ^
    -v %VOLUME_NAME%:/home/claude ^
    -v "%cd%:%WORKSPACE_PATH%" ^
    %IMAGE_NAME% ^
    %*

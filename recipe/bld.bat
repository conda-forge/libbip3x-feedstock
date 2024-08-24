:: @echo off
call powershell -File "%RECIPE_DIR%\bld.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

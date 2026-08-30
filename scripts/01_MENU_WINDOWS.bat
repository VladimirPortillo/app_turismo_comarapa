@echo off
setlocal
cd /d "%~dp0\.."

:menu
cls
echo ============================================================
echo PROYECTO FINAL 360 - SESION 2 - WINDOWS
echo ============================================================
echo 1. Ejecutar en dispositivo
echo 2. Ejecutar en Chrome
echo 3. Ver dispositivos
echo 0. Salir
echo ============================================================
set /p option=Opcion: 

if "%option%"=="1" flutter run
if "%option%"=="2" flutter run -d chrome
if "%option%"=="3" flutter devices
if "%option%"=="0" exit /b 0

echo.
pause
goto menu

@echo off 
setlocal
set API_KEY=71794C4E4E0240A7A0E84C75BD2BBDE2
set SOURCE=.pio/build/STM32F103RC_btt_512K_USB_OctoPi/firmware.bin

echo Uploading %SOURCE% to printer
ssh -q -o ConnectTimeout=1 pi@octopi.fritz.box "sudo mount /mnt/usb"
scp -q %SOURCE% pi@octopi.fritz.box:/mnt/usb
if %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%
PING -n 6 127.0.0.1>nul
ssh -q -o ConnectTimeout=1 pi@octopi.fritz.box "sudo umount /mnt/usb"
if %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%

echo Restarting printer
curl -fsS -H "X-Api-key: %API_KEY%" -H"Content-Type: application/json" http://octopi.fritz.box/api/printer/command --data "{\"command\":\"M997\"}" >nul 
if %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%

echo Waiting for serial to become available

set /a "_seconds=0"
:checkloop

    set /a "_seconds=_seconds+5">nul
    PING -n 6 127.0.0.1>nul
    if %_seconds% GEQ 120 goto nextstep
    echo |set /p="."
    if %_seconds% LEQ 2 goto checkloop
    
    ssh -q -o ConnectTimeout=1 pi@octopi.fritz.box "[ -e /dev/ttyACM0 ]"
    if %ERRORLEVEL%==0 goto nextstep

    goto checkloop

:nextstep

echo.
echo Reconnecting
curl -fsS -H "X-Api-key: %API_KEY%" -H"Content-Type: application/json" http://octopi.fritz.box/api/connection --data "{\"command\":\"connect\"}" >nul 


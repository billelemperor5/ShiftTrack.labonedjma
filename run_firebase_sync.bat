@echo off
title ShiftTrack - Firebase Sync Daemon
color 0A
echo ====================================================
echo   ShiftTrack LA BONEDJIMA - Firebase Real-time Sync
echo ====================================================
echo.
cd /d "%~dp0server"
node sync_to_firebase.js --watch
pause

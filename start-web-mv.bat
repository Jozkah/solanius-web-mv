@echo off
title Solanius web-mv relay
echo Starting Solanius web-mv on http://127.0.0.1:9000
echo Leave this window open while you use the panel.
powershell -NoExit -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-relay.ps1"

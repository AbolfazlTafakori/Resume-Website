@echo off
echo Starting Resume API Backend...
cd /d "%~dp0Backend\ResumeAPI"
dotnet run --urls http://localhost:5000
pause

@echo off
rem start_csagent.bat - mode "CSAgent lance CSFlow" (MCP).
rem  1. un CSAgent worker (--api, port 8080) dans une fenetre reduite : etapes agent des workflows ;
rem  2. le CSAgent interactif ici, avec CSFlow declare comme serveur MCP (mcp.json), SANS --yes.
rem Fermer le CSAgent interactif arrete le worker.

cd /d "%~dp0"
set CSAGENT_BIN=csagent
set PORT=8080
set API_KEY=demo-secret

if not "%ALBERT_API_KEY%"=="" goto key_ok
echo.
echo  ERREUR : ALBERT_API_KEY n'est pas definie.
pause
exit /b 1
:key_ok

where %CSAGENT_BIN% >nul 2>&1
if not errorlevel 1 goto agent_ok
echo.
echo  ERREUR : %CSAGENT_BIN% est introuvable dans le PATH.
pause
exit /b 1
:agent_ok

if exist mcp.json goto mcp_ok
if not exist mcp.json.example goto mcp_missing
copy mcp.json.example mcp.json >nul
echo   mcp.json cree depuis mcp.json.example (verifiez la commande).
goto mcp_ok
:mcp_missing
echo  ERREUR : mcp.json introuvable.
pause
exit /b 1
:mcp_ok

start "CSAgent-Worker" /min cmd /c %CSAGENT_BIN% --api --yes --port %PORT% --api-key %API_KEY% --mem csflow_worker --no-distill
timeout /t 3 /nobreak >nul

echo   CSAgent interactif avec le serveur MCP CSFlow...
%CSAGENT_BIN% --mcp-config mcp.json

echo   CSAgent ferme -- arret du worker.
taskkill /fi "WINDOWTITLE eq CSAgent-Worker*" /t /f >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":%PORT% .*LISTENING"') do taskkill /pid %%p /t /f >nul 2>&1
exit /b 0

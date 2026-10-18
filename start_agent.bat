@echo off
:: start_agent.bat — lance CSAgent en mode API headless, DEPUIS ce dossier (workflow\).
:: CSAgent n'écrit que dans son dossier courant : il doit tourner ici pour que les
:: chemins relatifs des workflows (tmp\...) pointent au même endroit que CSFlow.

cd /d "%~dp0"

:: ── à adapter ────────────────────────────────────────────────────────────────
set CSAGENT_BIN=csagent
set PORT=8080
set API_KEY=demo-secret
:: ─────────────────────────────────────────────────────────────────────────────

if "%ALBERT_API_KEY%"=="" (
    echo.
    echo  ERREUR : ALBERT_API_KEY n'est pas definie.
    echo  Lance :  set ALBERT_API_KEY=ta-cle
    exit /b 1
)

echo.
echo   CSAgent -- mode API headless
echo   Dossier : %CD%
echo   Ecoute sur http://localhost:%PORT%
echo   Arret : Ctrl-C
echo.

%CSAGENT_BIN% --api --yes --port %PORT% --api-key %API_KEY%

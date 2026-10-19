@echo off
rem ------------------------------------------------------------
rem Compilation de CSFlow avec Nuitka (un seul exe)
rem A lancer depuis le dossier workflow\ (celui qui contient app.py)
rem ------------------------------------------------------------

python -m nuitka ^
    --onefile ^
    --windows-console-mode=disable ^
    --remove-output ^
    --output-dir=build ^
    --output-filename=CSFlow.exe ^
    --include-data-dir=ui=ui ^
    --include-data-dir=workflows=workflows ^
    --include-data-files=csflow.schema.json=csflow.schema.json ^
    --include-data-files=start_agent.bat=start_agent.bat ^
    --include-package=eel ^
    --include-package-data=eel ^
    --include-package=yaml ^
    --include-package=nodes ^
    app.py

if %errorlevel% neq 0 (
    echo Erreur lors de la compilation avec Nuitka.
    exit /b %errorlevel%
)
echo Compilation reussie : build\CSFlow.exe
echo Au premier lancement, CSFlow cree a cote de l'exe les dossiers workflows et tmp.
@echo off
rem ------------------------------------------------------------
rem Build script for Nuitka – compile app.py en un seul exécutable
rem ------------------------------------------------------------

rem Assurez‑vous que le répertoire de travail est le répertoire racine du projet
rem (celui contenant app.py et les dossiers ui, tmp, workflows).

python -m nuitka ^
    --standalone ^
    --onefile ^
    --windows-disable-console ^
    --remove-output ^
    --output-dir=build ^
    --include-data-dir=ui=ui ^
    --include-data-dir=tmp=tmp ^
    --include-data-dir=workflows=workflows ^
    --include-package=eel ^
    --include-package=yaml ^
    app.py

if %errorlevel% neq 0 (
    echo Erreur lors de la compilation avec Nuitka.
    exit /b %errorlevel%
) else (
    echo Compilation reussie. L'executable se trouve dans le dossier "build".
)

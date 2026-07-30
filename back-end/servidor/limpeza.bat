@echo off
setlocal EnableDelayedExpansion

cd /d "C:\projetos\goopedir\web\allancolombo\back-end\servidor"

echo ==========================================
echo    LIMPEZA DE BACKUPS DO DELPHI
echo ==========================================
echo.

set /a TOTAL=0

for /r %%F in (*.~*~) do (
    set /a TOTAL+=1
)

if %TOTAL%==0 (
    echo Nenhum arquivo de backup encontrado.
    pause
    exit /b
)

echo Foram encontrados %TOTAL% arquivos de backup.
echo.

set /p RESP="Deseja excluir todos? (S/N): "

if /I not "%RESP%"=="S" (
    echo.
    echo Operacao cancelada.
    pause
    exit /b
)

echo.
echo Excluindo...

set /a REMOVIDOS=0

for /r %%F in (*.~*~) do (
    del /f /q "%%F"
    set /a REMOVIDOS+=1
)

echo.
echo ==========================================
echo Concluido!
echo Arquivos removidos: !REMOVIDOS!
echo ==========================================

pause
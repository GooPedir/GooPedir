@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem CONFIGURACAO
rem ============================================================

set "API_URL=https://atualizacao.goopedir.com"
set "PRODUCT=servidor"
set "CHANNEL=production"

rem Pasta onde este BAT esta localizado
set "BASE_DIR=%~dp0"

rem Pasta de versao:
rem BAT:    allancolombo\back-end\servidor
rem ARQS:   allancolombo\versao
set "VERSAO_DIR=%BASE_DIR%..\..\versao"

rem Script que gera manifest + ZIP
set "PACKAGE_SCRIPT=%BASE_DIR%create-package.ps1"

rem Token e log
set "TOKEN_FILE=%BASE_DIR%ci-api-token.txt"
set "LOG_FILE=%BASE_DIR%ci-upload.log"

rem Executavel principal usado para descobrir a versao
set "SERVER_EXE=ServidorGooPedir.exe"

rem ============================================================
rem NORMALIZA CAMINHOS
rem ============================================================

for %%I in ("%VERSAO_DIR%") do set "VERSAO_DIR=%%~fI"

set "SERVER_PATH=%VERSAO_DIR%\%SERVER_EXE%"

rem ============================================================
rem CABECALHO
rem ============================================================

echo.
echo ============================================================
echo   PUBLICACAO DO SERVIDOR
echo ============================================================
echo.
echo Pasta do BAT:
echo   %BASE_DIR%
echo.
echo Pasta dos arquivos:
echo   %VERSAO_DIR%
echo.

rem ============================================================
rem VALIDACOES BASICAS
rem ============================================================

if not exist "%VERSAO_DIR%\" (
    echo.
    echo [ERRO] Pasta de versao nao encontrada:
    echo   %VERSAO_DIR%
    echo.
    pause
    exit /b 1
)

if not exist "%PACKAGE_SCRIPT%" (
    echo.
    echo [ERRO] Script create-package.ps1 nao encontrado:
    echo   %PACKAGE_SCRIPT%
    echo.
    pause
    exit /b 1
)

if not "%CHANNEL%"=="test" if not "%CHANNEL%"=="beta" if not "%CHANNEL%"=="production" (
    echo.
    echo [ERRO] CHANNEL invalido:
    echo   %CHANNEL%
    echo.
    echo Valores permitidos:
    echo   test
    echo   beta
    echo   production
    echo.
    pause
    exit /b 1
)

rem ============================================================
rem TOKEN
rem ============================================================

if not exist "%TOKEN_FILE%" (
    echo Token de API nao encontrado.
    echo.
    echo Gere o token no portal e informe abaixo.
    echo Ele sera salvo em:
    echo   %TOKEN_FILE%
    echo.

    set /p "TOKEN=Token de API: "

    if not defined TOKEN (
        echo.
        echo [ERRO] Token nao informado.
        echo.
        pause
        exit /b 1
    )

    >"%TOKEN_FILE%" echo(!TOKEN!

    echo.
    echo Token salvo com sucesso.
) else (
    set /p "TOKEN="<"%TOKEN_FILE%"
)

if not defined TOKEN (
    echo.
    echo [ERRO] O arquivo de token esta vazio:
    echo   %TOKEN_FILE%
    echo.
    pause
    exit /b 1
)

rem ============================================================
rem OBTEM VERSAO
rem ============================================================

if not exist "%SERVER_PATH%" (
    echo.
    echo [ERRO] Executavel principal nao encontrado:
    echo   %SERVER_PATH%
    echo.
    echo Nao foi possivel descobrir a versao automaticamente.
    echo.
    echo Arquivos EXE encontrados:
    dir /b "%VERSAO_DIR%\*.exe" 2>nul
    echo.
    pause
    exit /b 1
)

for /f "usebackq delims=" %%V in (`
    powershell.exe -NoProfile -Command ^
    "$v=(Get-Item -LiteralPath '%SERVER_PATH%').VersionInfo.FileVersion; if($v){$v.Trim()}"
`) do set "VERSAO=%%V"

if not defined VERSAO (
    echo.
    echo [ERRO] Nao foi possivel obter a versao de:
    echo   %SERVER_PATH%
    echo.
    pause
    exit /b 1
)

echo.
echo Versao encontrada:
echo   %VERSAO%
echo.

rem ============================================================
rem VERIFICA SE EXISTE CONTEUDO PARA PUBLICAR
rem ============================================================

set /a FILE_COUNT=0

for /r "%VERSAO_DIR%" %%F in (*) do (
    if exist "%%~fF" (

        set "EXT=%%~xF"

        if /I not "!EXT!"==".map" if /I not "!EXT!"==".drc" (
            set /a FILE_COUNT+=1
        )
    )
)

if %FILE_COUNT% EQU 0 (
    echo.
    echo [ERRO] Nenhum arquivo valido encontrado para publicar.
    echo.
    echo Ignorados:
    echo   *.map
    echo   *.drc
    echo.
    pause
    exit /b 1
)

echo Arquivos encontrados para publicacao:
echo   %FILE_COUNT%
echo.

rem ============================================================
rem DEFINE ZIP
rem ============================================================

set "ZIP_FILE=%BASE_DIR%%PRODUCT%-%VERSAO%.zip"

if exist "%ZIP_FILE%" (
    del /q "%ZIP_FILE%"
)

rem ============================================================
rem DEBUG DAS VARIAVEIS
rem ============================================================

echo ============================================================
echo   CONFIGURACAO DO PACOTE
echo ============================================================
echo.
echo PACKAGE_SCRIPT:
echo   %PACKAGE_SCRIPT%
echo.
echo VERSAO_DIR:
echo   %VERSAO_DIR%
echo.
echo ZIP_FILE:
echo   %ZIP_FILE%
echo.
echo PRODUCT:
echo   %PRODUCT%
echo.
echo CHANNEL:
echo   %CHANNEL%
echo.
echo VERSION:
echo   %VERSAO%
echo.

rem ============================================================
rem GERA MANIFEST + ZIP
rem ============================================================

echo ============================================================
echo   GERANDO PACOTE
echo ============================================================
echo.

powershell.exe ^
    -NoProfile ^
    -ExecutionPolicy Bypass ^
    -File "%PACKAGE_SCRIPT%" ^
    -SourceDirectory "%VERSAO_DIR%" ^
    -OutputZip "%ZIP_FILE%" ^
    -Product "%PRODUCT%" ^
    -Channel "%CHANNEL%" ^
    -Version "%VERSAO%"

set "PACKAGE_EXIT=%ERRORLEVEL%"

if not "%PACKAGE_EXIT%"=="0" (
    echo.
    echo ============================================================
    echo   ERRO AO GERAR PACOTE
    echo ============================================================
    echo.
    echo Codigo:
    echo   %PACKAGE_EXIT%
    echo.
    echo Nenhum arquivo de origem foi removido.
    echo.
    pause
    exit /b %PACKAGE_EXIT%
)

if not exist "%ZIP_FILE%" (
    echo.
    echo [ERRO] O ZIP nao foi criado:
    echo   %ZIP_FILE%
    echo.
    pause
    exit /b 1
)

echo.
echo Pacote criado com sucesso:
echo   %ZIP_FILE%
echo.

rem ============================================================
rem VALIDA CURL
rem ============================================================

where curl.exe >nul 2>&1

if errorlevel 1 (
    echo.
    echo [ERRO] curl.exe nao foi encontrado no PATH.
    echo.
    echo O ZIP foi mantido:
    echo   %ZIP_FILE%
    echo.
    pause
    exit /b 1
)

rem ============================================================
rem ENVIO PARA API
rem ============================================================

echo ============================================================
echo   ENVIANDO PARA O PORTAL
echo ============================================================
echo.

if exist "%LOG_FILE%" (
    del /q "%LOG_FILE%"
)

curl.exe ^
    --fail ^
    --silent ^
    --show-error ^
    --retry 2 ^
    -X POST "%API_URL%/api/v1/ci/artifacts" ^
    -H "Authorization: Bearer %TOKEN%" ^
    -F "artifact=@%ZIP_FILE%;type=application/zip" ^
    -F "product=%PRODUCT%" ^
    -F "version=%VERSAO%" ^
    -F "channel=%CHANNEL%" ^
    > "%LOG_FILE%" 2>&1

set "CURL_EXIT=%ERRORLEVEL%"

echo.
type "%LOG_FILE%"
echo.

rem ============================================================
rem ERRO NO UPLOAD
rem ============================================================

if not "%CURL_EXIT%"=="0" (
    echo.
    echo ============================================================
    echo   ERRO NO UPLOAD
    echo ============================================================
    echo.
    echo Codigo CURL:
    echo   %CURL_EXIT%
    echo.
    echo Consulte:
    echo   %LOG_FILE%
    echo.
    echo O ZIP foi mantido para nova tentativa:
    echo   %ZIP_FILE%
    echo.
    echo Nenhum arquivo de origem foi removido.
    echo.
    pause
    exit /b %CURL_EXIT%
)

rem ============================================================
rem UPLOAD OK
rem ============================================================

echo.
echo ============================================================
echo   UPLOAD CONCLUIDO
echo ============================================================
echo.

rem ============================================================
rem LIMPEZA DOS EXECUTAVEIS
rem ============================================================

echo Limpando executaveis publicados...
echo.

for %%F in ("%VERSAO_DIR%\*.exe") do (
    if exist "%%~fF" (
        echo   Removendo %%~nxF
        del /f /q "%%~fF"
    )
)

rem ============================================================
rem LIMPEZA DO FRONTEND
rem ============================================================

set "HTML_DIR=%VERSAO_DIR%\nginx\html"

if exist "%HTML_DIR%\" (
    echo.
    echo Limpando nginx\html...
    echo.

    rem Remove arquivos
    del /f /s /q "%HTML_DIR%\*" >nul 2>&1

    rem Remove subpastas
    for /d %%D in ("%HTML_DIR%\*") do (
        rd /s /q "%%~fD"
    )

    echo   Conteudo removido.
    echo   Pasta mantida:
    echo   %HTML_DIR%
)

rem ============================================================
rem REMOVE ZIP LOCAL APOS SUCESSO
rem ============================================================

if exist "%ZIP_FILE%" (
    echo.
    echo Removendo ZIP local...
    del /f /q "%ZIP_FILE%"
)

rem ============================================================
rem FINAL
rem ============================================================

echo.
echo ============================================================
echo   PUBLICACAO CONCLUIDA
echo ============================================================
echo.
echo Produto:
echo   %PRODUCT%
echo.
echo Versao:
echo   %VERSAO%
echo.
echo Canal:
echo   %CHANNEL%
echo.
echo Arquivos publicados com sucesso.
echo.
echo Executaveis removidos da pasta versao.
echo Conteudo de nginx\html removido.
echo.

exit /b 0
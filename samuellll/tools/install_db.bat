@echo off
setlocal EnableDelayedExpansion

echo ========================================================
echo   INSTALADOR AUTOMATICO DE BASE DE DATOS - PROTEGO
echo ========================================================
echo.

:: 1. Cambiar al directorio del script para que las rutas relativas funcionen
cd /d "%~dp0"

:: 2. Cargar variables desde .env (esta en la raiz, un nivel arriba)
if exist "..\.env" (
    echo [INFO] Leyendo archivo .env...
    for /f "tokens=1,2 delims==" %%a in ('type "..\.env"') do (
        set key=%%a
        set val=%%b
        if "!key!"=="DB_HOST" set DB_HOST=!val!
        if "!key!"=="DB_PORT" set DB_PORT=!val!
        if "!key!"=="DB_NAME" set DB_NAME=!val!
        if "!key!"=="DB_USER" set DB_USER=!val!
        if "!key!"=="DB_PASSWORD" set DB_PASSWORD=!val!
    )
) else (
    echo [WARN] No se encontro archivo .env en la raiz. Usando valores por defecto.
)

:: 3. Solicitar/Confirmar credenciales
if "%DB_HOST%"=="" set DB_HOST=localhost
if "%DB_PORT%"=="" set DB_PORT=5432
if "%DB_USER%"=="" set DB_USER=postgres
if "%DB_NAME%"=="" set DB_NAME=sst_db

echo.
echo Configuracion detectada:
echo -----------------------
echo Host:      %DB_HOST%
echo Puerto:    %DB_PORT%
echo Usuario:   %DB_USER%
echo Base Datos: %DB_NAME%
echo.

set /p CONFIRM="¿Son correctos estos datos? (S/N): "
if /i "%CONFIRM%"=="N" (
    set /p DB_HOST="Host [%DB_HOST%]: "
    set /p DB_PORT="Puerto [%DB_PORT%]: "
    set /p DB_NAME="Nombre Base Datos [%DB_NAME%]: "
    set /p DB_USER="Usuario [%DB_USER%]: "
    set /p DB_PASSWORD="Password: "
)

if "%DB_PASSWORD%"=="" (
    set /p DB_PASSWORD="Ingrese Password para el usuario %DB_USER%: "
)

:: 4. Verificar y Configurar ruta de psql
set PSQL_PATH="C:\Program Files\PostgreSQL\18\bin\psql.exe"

if not exist %PSQL_PATH% (
    echo [ERROR] No se encontro psql.exe en: %PSQL_PATH%
    echo Por favor verifique la instalacion de PostgreSQL.
    pause
    exit /b 1
)

:: Establecer password para psql
set PGPASSWORD=%DB_PASSWORD%

:: Establecer codificacion para evitar errores de caracteres
set PGCLIENTENCODING=UTF8

echo.
echo ========================================================
echo   INICIANDO INSTALACION...
echo ========================================================

:: 5. Ejecutar Scripts SQL (estan en ../database/)
echo.
echo [1/4] Ejecutando: MODELO SST.sql (Estructura Base)...
%PSQL_PATH% -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "..\database\MODELO SST.sql"
if %errorlevel% neq 0 goto :error

echo.
echo [2/4] Ejecutando: setup_sequences.sql (Secuencias)...
%PSQL_PATH% -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "..\database\setup_sequences.sql"
if %errorlevel% neq 0 goto :error

echo.
echo [3/4] Ejecutando: INSERTS_SST.SQL (Datos Iniciales)...
%PSQL_PATH% -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "..\database\INSERTS_SST.SQL"
if %errorlevel% neq 0 goto :error

echo.
echo [4/4] Ejecutando: INTEGRACION_MATRIZ.sql (Modulo Riesgos)...
%PSQL_PATH% -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "..\database\INTEGRACION_MATRIZ.sql"
if %errorlevel% neq 0 goto :error

echo.
echo ========================================================
echo   INSTALACION COMPLETADA CON EXITO
echo ========================================================
echo.
pause
exit /b 0

:error
echo.
echo [ERROR] Ocurrio un error durante la ejecucion del script.
echo Revise los mensajes anteriores.
echo.
pause
exit /b 1

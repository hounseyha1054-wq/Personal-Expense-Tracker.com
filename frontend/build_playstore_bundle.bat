@echo off
echo ========================================================
echo   Building Google Play Store Android App Bundle (.aab)
echo   Project: Personal Expense Tracker (com.seyha.personal)
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/3] Running flutter clean...
call flutter clean

echo.
echo [2/3] Fetching dependencies...
call flutter pub get

echo.
echo [3/3] Compiling release Android App Bundle (.aab)...
call flutter build appbundle --release

echo.
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ========================================================
    echo   SUCCESS! App Bundle generated:
    echo   %~dp0build\app\outputs\bundle\release\app-release.aab
    echo ========================================================
    echo You can now upload this .aab file to Google Play Console!
) else (
    echo ========================================================
    echo   BUILD FAILED! Please check error output above.
    echo ========================================================
)

pause


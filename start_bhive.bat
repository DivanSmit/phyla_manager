If /I Not "%CD%/"=="%~dp0" CD /D "%~dp0"

set "targetFolder=C:\Users\LENOVO\Desktop\base-getting-started\phyla_manager_BASE\disk_bases"
del /q /s "%targetFolder%\*.*"

set SETTINGS_FILE=C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/bhive_config.json

echo %SETTINGS_FILE%
cls

CD /D C:\
cd C:/Users/LENOVO/Desktop/base-getting-started/base-core/ebin
erl -run base_hive start_bhive "%SETTINGS_FILE%"
pause
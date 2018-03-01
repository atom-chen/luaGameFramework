@echo off

call ..\application\build.bat

python remove_bom.py

xcopy /Y .\config.json .\simulator\win32\
start ./simulator/win32/MyLuaGame.exe -workdir ./ -writable-path ./simulator/win32 -resolution 1136x640 -console enable -write-debug-log debug.log
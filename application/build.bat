@echo off

if exist res (
	echo res exist
) else (
	mklink /d res ..\application\res
	mklink /d updater ..\application\updater
	cd src
	mklink /d app ..\..\application\src\app
	mklink /d battle ..\..\application\src\battle
	cd ..
	echo mklink res ok
)

cd ..\..\tools\csv2lua\
python csv2lua_dev.py

cd ..\..\client\game01_new\
xcopy ..\..\tools\csv2lua\config\*.* .\src\config\ /e /y

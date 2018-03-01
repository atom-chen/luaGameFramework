@echo off

rem DIRNAME按项目设置检出目录名
rem TAG按项目设置检出标签
set DIRNAME=game01
set TAG=test_firstrelease

@where git
if "%errorlevel%"=="0" (
	echo git exist
) else (
	echo git not install!!!
	start https://git-scm.com/download/win
	exit
)

if exist %DIRNAME% (
	echo %DIRNAME% exist
) else (
	echo %DIRNAME% need clone
	git config --global http.sslVerify false
	git clone https://robot:robot@git.tianji-game.com/tjgame/LuaGameFramework.git LuaGameFramework
	git checkout %TAG%
	mklink /d %DIRNAME% LuaGameFramework\MyLuaGame
	echo %DIRNAME% need ok
)

cd %DIRNAME%
call run_game.bat

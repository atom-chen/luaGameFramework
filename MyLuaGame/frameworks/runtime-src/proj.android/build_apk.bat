rem %ANDROID_SDK_ROOT%\tools\android update project -t android-20 -p %cd%
rem %ANT_ROOT%\ant clean release -f %cd%\build.xml -Dsdk.dir=%ANDROID_SDK_ROOT%\.
python ../../cocos2d-x/tools/cocos2d-console/bin/cocos.py compile -p android --ap android-20 -m release | tee build.log
pause
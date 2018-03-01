//Cocos平台下Lua异常收集处理
#include "LuaExceptionHandler.h"
#include "BugReport.h"

#define EXCEPTION_TAG "cocos-lua"

void LuaExceptionHandler::registerLuaExceptionHandler(const char* appid) {
    
	BugReport::initExceptinHandler(appid, COCOS_LUA_VER, EXCEPTION_TAG);
}





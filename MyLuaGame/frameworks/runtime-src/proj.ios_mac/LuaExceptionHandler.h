#ifndef __BUGRPT_LUA_EXCEPTION_HANDLER_H__
#define __BUGRPT_LUA_EXCEPTION_HANDLER_H__

#define COCOS_LUA_VER "1.1"

class LuaExceptionHandler
{
public:
    static void registerLuaExceptionHandler(const char* appid);
};

#endif  // __BUGRPT_LUA_EXCEPTION_HANDLER_H__


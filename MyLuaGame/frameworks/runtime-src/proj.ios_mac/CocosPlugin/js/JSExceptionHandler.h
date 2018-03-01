#ifndef __BUGRPT_JS_EXCEPTION_HANDLER_H__
#define __BUGRPT_JS_EXCEPTION_HANDLER_H__

#include "cocos2d.h"
#include "jsapi.h"

#define kExceptionCategoryLua       4
#define kExceptionCategoryJS        5

#define COCOS_JS_VER "1.2"

class  JSExceptionHandler
{
public:
    static void registerJSExceptionHandler(JSContext *cx, const char* appid);
    static void reportError(JSContext *cx, const char *message, JSErrorReport *report);
    
    static void sendAndroidJSReport(const char* reason, const char* traceback);
    static void sendIOSJSReport(const char* reason, const char* traceback);
};

#endif  // __BUGRPT_JS_EXCEPTION_HANDLER_H__


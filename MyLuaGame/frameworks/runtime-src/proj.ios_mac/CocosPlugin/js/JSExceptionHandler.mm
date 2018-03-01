//Cocos平台下Javascript异常收集处理
#include <stdio.h>
#include <string.h>
#include "JSExceptionHandler.h"
#include "BugReport.h"

#define EXCEPTION_TAG "cocos-js"

#define LOG_TAG "BugrptJSExceptionHandler"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    #include <android/log.h>
    #include <jni.h>
    #include "platform/android/jni/JniHelper.h"

    #define LOGI(fmt, args...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, fmt, ##args)
    #define LOGD(fmt, args...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, fmt, ##args)
    #define LOGE(fmt, args...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, fmt, ##args)

    #define AGENT_CLASS "com/netease/nis/bugrpt/CrashHandler"

#elif (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    #import <Bugrpt/NTESCrashReporter.h>
    #import <Foundation/Foundation.h>

    #define NSStringMake(const_char_pointer) (const_char_pointer == NULL ? nil : @(const_char_pointer))
    #define NSStringMakeNonnull(const_char_pointer) (const_char_pointer == NULL ? @"" : @(const_char_pointer))

    #define BUGRPT_INTERFACE_CLASS              @"NTESBugrptInternalInterface"
    #define BUGRPT_INTERFACE_SINGLEINSTANCE     @"sharedInstance"
    #define BUGRPT_INTERFACE_SENDJS             @"sendJSReportsToServer:"

    #define LOGD(fmt, args...) CCLOG("[Debug] %s: " fmt, LOG_TAG, ##args)
    #define LOGI(fmt, args...) CCLOG("[Info] %s: " fmt, LOG_TAG, ##args)
    #define LOGW(fmt, args...) CCLOGERROR("[Warn] %s: " fmt, LOG_TAG, ##args)
    #define LOGE(fmt, args...) CCLOGERROR("[Error] %s: " fmt, LOG_TAG, ##args)

#endif

//注册异常处理回调函数
void JSExceptionHandler::registerJSExceptionHandler(JSContext *cx, const char* appid) {

    LOGD("[%s] begin ctx:%p",__FUNCTION__,cx);
	
	if( cx == NULL ) {
        LOGD("[%s] JSContext is null, return",__FUNCTION__);
		return;
	}
	
	BugReport::initExceptinHandler(appid, COCOS_JS_VER, EXCEPTION_TAG);
    JS_SetErrorReporter(cx, JSExceptionHandler::reportError);
}


void JSExceptionHandler::reportError(JSContext *cx, const char *message, JSErrorReport *report)
{
    if(cx && message && report){
        const char* format = "%s(%u:%u)\n%s\n";
        const char* fileName = report->filename ? report->filename : "<no filename=\"filename\">";
        
        int bufLen = (int)(strlen(format) + strlen(fileName) + strlen(message) + 16);
        char* traceback = (char*)malloc(bufLen);
        memset(traceback, 0, bufLen);
        sprintf(traceback, format, fileName, (unsigned int) report->lineno,  (unsigned int) report->column, message);
        
        
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
        LOGD("[%s] msg:%s",__FUNCTION__,message);
        sendAndroidJSReport(message, traceback);
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
        LOGD("[%s] msg:%s",__FUNCTION__,message);
        LOGD("[%s] trace:%s",__FUNCTION__,traceback);
        sendIOSJSReport(message, traceback);
#endif
        
        free(traceback);
    }
};

//Android平台上发送report
void JSExceptionHandler::sendAndroidJSReport(const char* reason, const char* traceback) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    JavaVM* jvm = cocos2d::JniHelper::getJavaVM();
    JNIEnv* env = NULL;
    jvm->GetEnv((void**)&env, JNI_VERSION_1_4);
    
    if (NULL == jvm || NULL == env) {
        LOGE("Could not complete opertion because JavaVM or JNIEnv is null!");
        return;
    }
    jvm->AttachCurrentThread(&env, 0);
    
    jclass clsID = env->FindClass(AGENT_CLASS);
    if(clsID){
        
        jobject jCrashHandler = 0;
        jmethodID methodID = env->GetStaticMethodID(clsID, "sendReportsBridge", "(Ljava/lang/String;Ljava/lang/String;)Z");
        if(methodID){
            
            std::string strDesc = reason;
            strDesc.append("\r\n");
            strDesc.append(traceback);
            jstring jExcetpt = env->NewStringUTF(strDesc.c_str());
            
            std::string strTagStr = EXCEPTION_TAG;
            strTagStr.append("&");
            strTagStr.append(COCOS_JS_VER);
            
            jstring jTag = env->NewStringUTF(strTagStr.c_str());
            LOGD("[%s] send exception begin",__FUNCTION__);
            env->CallStaticBooleanMethod(clsID,methodID,jExcetpt,jTag);
            env->DeleteLocalRef(jTag);
            env->DeleteLocalRef(jExcetpt);
        }
        
        env->DeleteLocalRef(clsID);
    }
#endif
}

//iOS平台上发送report
void JSExceptionHandler::sendIOSJSReport(const char* reason, const char* traceback) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    
    std::string name = "";
    std::string reasonStr = "";
    
    if (reason && strlen(reason) > 0) {
        std::string tmpStr = reason;
        int index = (int)tmpStr.find(":");
        reasonStr = tmpStr;
        
        if(index != -1){
            name = tmpStr.substr( 0, index );
            tmpStr.erase( 0, index+1 );
            reasonStr = tmpStr;
        }
    }
    
    Class classzz = NSClassFromString(BUGRPT_INTERFACE_CLASS);
    if (classzz) {
        SEL selector = NSSelectorFromString(BUGRPT_INTERFACE_SINGLEINSTANCE);
        if (selector) {
            id interfaceObj = nil;
            interfaceObj = [classzz performSelector:selector withObject:nil];
            if (interfaceObj){
                selector = NSSelectorFromString(BUGRPT_INTERFACE_SENDJS);
                if (selector) {
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:3];
                    [dic setObject:NSStringMakeNonnull(name.c_str()) forKey:@"name"];
                    [dic setObject:NSStringMakeNonnull(reasonStr.c_str()) forKey:@"reason"];
                    [dic setObject:NSStringMakeNonnull(traceback) forKey:@"stack"];
                    [interfaceObj performSelector:selector withObject:dic];
                }
            }else{
                LOGE("[%s] Failed to get object by performSelector(%s)",__FUNCTION__, [BUGRPT_INTERFACE_SINGLEINSTANCE UTF8String]);
            }
        }else{
            LOGE("[%s] Failed to get object selector by NSSelectorFromString(%s)",__FUNCTION__, [BUGRPT_INTERFACE_SINGLEINSTANCE UTF8String]);
        }
    }else{
        LOGE("[%s] Failed to get class by NSClassFromString(%s)",__FUNCTION__, [BUGRPT_INTERFACE_CLASS UTF8String]);
    }
    
#endif
}





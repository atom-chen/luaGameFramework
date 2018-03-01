#include <string.h>
#include "cocos2d.h"
#include "BugReport.h"

#define LOG_TAG "CocosBugrpt"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	#include <android/log.h>
	#include <jni.h>
	#include "platform/android/jni/JniHelper.h"

	#define LOGD(fmt, args...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, fmt, ##args)
	#define LOGE(fmt, args...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, fmt, ##args)

	#define AGENT_CLASS "com/netease/nis/bugrpt/CrashHandler"

#elif (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
	#include <Bugrpt/NTESCrashReporter.h>

    #define BUGRPT_INTERFACE_CLASS              @"NTESBugrptInternalInterface"
    #define BUGRPT_INTERFACE_SINGLEINSTANCE     @"sharedInstance"
    #define BUGRPT_INTERFACE_SETJSVER           @"setJSScriptVersion:"
    #define BUGRPT_INTERFACE_SETLUAVER          @"setLuaScriptVersion:"

    #define LOGD(fmt, args...) CCLOG("[Debug] %s: " fmt, LOG_TAG, ##args)
    #define LOGI(fmt, args...) CCLOG("[Info] %s: " fmt, LOG_TAG, ##args)
    #define LOGW(fmt, args...) CCLOGERROR("[Warn] %s: " fmt, LOG_TAG, ##args)
    #define LOGE(fmt, args...) CCLOGERROR("[Error] %s: " fmt, LOG_TAG, ##args)

#endif

#define EXCEPTION_JS_TAG "cocos-js"
#define EXCEPTION_LUA_TAG "cocos-lua"

bool BugReport::mInit = false;

void BugReport::initExceptinHandler(const char* appId, const char* sdkVersion, const char* platformTag) {
	if(mInit == true) {
		return;
	}

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	initAndroidExceptinHandler(appId, sdkVersion, platformTag);
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
	initIOSExceptinHandler(appId, sdkVersion, platformTag);
#endif
}

void BugReport::initAndroidExceptinHandler(const char* appId, const char* sdkVersion, const char* platformTag){

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	if(appId == NULL) {
		LOGD("[%s] appid is null",__FUNCTION__);
		return;
	}

	LOGD("[%s] begin",__FUNCTION__);
	JavaVM* jvm = cocos2d::JniHelper::getJavaVM();
	if (jvm == NULL) {
		LOGE("[%s] JavaVM is null",__FUNCTION__);
		return;
	}

	JNIEnv* env = NULL;
	jvm->GetEnv((void**)&env, JNI_VERSION_1_4);
	if (env == NULL) {
		LOGE("[%s] JNIEnv is null", __FUNCTION__);
		return;
	}

	jvm->AttachCurrentThread(&env, 0);

	//get activity
	jclass activityClass = env->FindClass("org/cocos2dx/lib/Cocos2dxActivity");
	if (activityClass != NULL) {
		jmethodID methodActivity = env->GetStaticMethodID(activityClass, "getContext", "()Landroid/content/Context;");
		jobject activity = (jobject) env->CallStaticObjectMethod(activityClass, methodActivity);
		if (activity != NULL) {

			jclass clsID = env->FindClass(AGENT_CLASS);
			if(clsID){

				jobject jCrashHandler = 0;
				jmethodID methodID = env->GetStaticMethodID(clsID, "agentInit", "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
				if(methodID){
					jstring jAppid = env->NewStringUTF(appId);
					jstring jVersion = env->NewStringUTF(sdkVersion);
					jstring jPlatformTag = env->NewStringUTF(platformTag);
					env->CallStaticVoidMethod(clsID, methodID, activity, jAppid, jVersion, jPlatformTag);
					env->DeleteLocalRef(jPlatformTag);
					env->DeleteLocalRef(jVersion);
					env->DeleteLocalRef(jAppid);
					mInit = true;
				}

				env->DeleteLocalRef(clsID);
			}
		}else{
			LOGE("[%s] activity is Null", __FUNCTION__);
		}

		env->DeleteLocalRef(activityClass);
	}else{
		LOGE("[%s] Cocos2dxActivity is Null", __FUNCTION__);
	}
#endif
    
}

void BugReport::initIOSExceptinHandler(const char* appId, const char* sdkVersion, const char* platformTag){
 
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    if (appId && strlen(appId) > 0) {
        NTESCrashReporter *reporter = [NTESCrashReporter sharedInstance];
        if (reporter) {
            // 初始化
            [reporter initWithAppId:[NSString stringWithUTF8String:appId]];
            mInit = true;
            
            // 设置版本号
            if (sdkVersion && strlen(sdkVersion) > 0) {
                Class classzz = NSClassFromString(BUGRPT_INTERFACE_CLASS);
                if (classzz) {
                    SEL selector = NSSelectorFromString(BUGRPT_INTERFACE_SINGLEINSTANCE);
                    if (selector) {
                        id interfaceObj = nil;
                        interfaceObj = [classzz performSelector:selector withObject:nil];
                        if (interfaceObj)
                        {
                            if(strcmp(platformTag, EXCEPTION_JS_TAG) == 0){
                                selector = NSSelectorFromString(BUGRPT_INTERFACE_SETJSVER);
                                
                            }else if(strcmp(platformTag, EXCEPTION_LUA_TAG) == 0){
                                selector = NSSelectorFromString(BUGRPT_INTERFACE_SETLUAVER);
                            }
                            
                            if (selector) {
                                [interfaceObj performSelector:selector withObject:[NSString stringWithUTF8String:sdkVersion]];
                            }
                        }
                    }else{
                        LOGE("[%s] Failed to get object by sharedInstance(%s)",__FUNCTION__, [BUGRPT_INTERFACE_SINGLEINSTANCE UTF8String]);
                    }
                }else{
                    LOGE("[%s] Failed to get class by NSClassFromString(%s)",__FUNCTION__, [BUGRPT_INTERFACE_CLASS UTF8String]);
                }
            }else{
                LOGE("[%s] sdkVersion is null",__FUNCTION__);
            }
        }else{
            LOGE("[%s] class(NTESCrashReporter) is null",__FUNCTION__);
        }
    }else{
        LOGE("[%s] appid is null",__FUNCTION__);
    }
#endif
    
}

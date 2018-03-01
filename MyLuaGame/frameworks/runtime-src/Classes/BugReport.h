#ifndef BUGRPT_H_
#define BUGRPT_H_

class BugReport
{
private:
    static bool mInit;
 
public:
	static void initExceptinHandler(const char* appId, const char* sdkVersion, const char* platformTag);
	
private:
	static void initAndroidExceptinHandler(const char* appId, const char* sdkVersion, const char* platformTag);
	static void initIOSExceptinHandler(const char* appId, const char* sdkVersion, const char* platformTag);
};

#endif
//
//  Header.h
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#ifndef Header_h
#define Header_h
class SDKIOS{
private:
    static SDKIOS *instance;
public:
    static SDKIOS * getInstance();
public:
    void pay(const char * jsonParams);
    void login(const char * jsonParams);
    void loginSucess(const char * token, const char * displayName, const char * userId);
    void logout(const char * jsonParams);
    void logoutSucess(const char * jsonParams);
    void commit(const char * jsonParams);
    void initSDK();
    void adEvent(int eventIdx);
};

#endif /* Header_h */

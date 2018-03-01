//
//  SDKIOS.m
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#include "SDKIOS.h"


SDKIOS * SDKIOS::instance = nil;

SDKIOS * SDKIOS::getInstance(){
    if (SDKIOS::instance == nil ){
        SDKIOS::instance = new SDKIOS();
    }
    return instance;
}

void SDKIOS::initSDK(){

}

void SDKIOS::pay(const char * jsonParams){

}

void SDKIOS::login(const char * jsonParams){
   NSLog(@"登录--------------");
}

void SDKIOS::loginSucess(const char * token, const char * displayName, const char * userId){
    
}

void SDKIOS::logout(const char * jsonParams){
    
}

void SDKIOS::commit(const char * jsonParams){

}

void SDKIOS::adEvent(int eventIdx){
    
}
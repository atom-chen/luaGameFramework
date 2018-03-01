//
//  SDKCommon.m
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#import "SDKCommon.h"
#import "cocos2d.h"
#import "CCLuaEngine.h"
#import "CCLuaBridge.h"
using namespace cocos2d;

@implementation SDKCommon

NSDictionary *dict;

+(void) master: (NSDictionary *)dic{
    dict = dic;
    NSLog(@"调用＋＋＋＋＋＋＋＋＋＋＋＋＋");
    [self masterCallback:dic];
}

+(void) masterCallback: (NSDictionary *)dic{
    NSString *str_function_name =[dic objectForKey:@"funcName"];
    NSString *str_result =[dic objectForKey:@"result"];
    LuaStack *stack = LuaBridge::getStack();  //获取lua栈
    if ([str_function_name  isEqual: @"logout"]){
        stack->executeGlobalFunction("onSDKLogout");
        return ;
    }
    
    int handlerID = (int)[[dict objectForKey:@"callback"] integerValue];
    LuaBridge::pushLuaFunctionById(handlerID); //压入需要调用的方法id（假设方法为XG）
    stack->pushString("oc call lua method...");  //将需要通过方法XG传递给lua的参数压入lua栈
    stack->executeFunction(1);  //根据压入的方法id调用方法XG，并把XG方法参数传递给lua代码
    LuaBridge::releaseLuaFunctionById(handlerID); //最后记得释放
}

@end

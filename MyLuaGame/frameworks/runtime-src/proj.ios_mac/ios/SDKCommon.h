//
//  SDKCommon.h
//  MyLuaGame
//
//  Created by MacMini2 on 17/8/23.
//
//

#import <Foundation/Foundation.h>

@interface SDKCommon : NSObject
{
    NSDictionary *dict;
}
+(void) master: (NSDictionary *)dic;
+(void) masterCallback: (NSDictionary *)dic;
@end

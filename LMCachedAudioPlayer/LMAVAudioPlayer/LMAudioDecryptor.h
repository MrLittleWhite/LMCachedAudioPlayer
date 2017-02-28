//
//  LMAudioDecryptor.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 17/2/22.
//  Copyright © 2017年 lazy-iOS2. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LMAudioDecryptor : NSObject

- (NSData *)decryptData:(NSData *)data
                withKey:(NSString *)key
                     iv:(NSString *)iv;

@end

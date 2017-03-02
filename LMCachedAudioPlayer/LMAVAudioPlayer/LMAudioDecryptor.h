//
//  LMAudioDecryptor.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 17/2/22.
//  Copyright © 2017年 lazy-iOS2. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LMAudioDecryptor : NSObject

- (instancetype)initWithRange:(NSRange)range
                contentLength:(UInt64)length
                      withKey:(NSString *)key
                           iv:(NSString *)iv;

@property (nonatomic, assign, readonly) NSRange requireRange;

- (NSData *)decryptData:(NSData *)data;

@end

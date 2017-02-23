//
//  LMAudioDecryptor.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 17/2/22.
//  Copyright © 2017年 lazy-iOS2. All rights reserved.
//

#import "LMAudioDecryptor.h"
#include <CommonCrypto/CommonCryptor.h>

@implementation LMAudioDecryptor

+ (NSData *)decryptData:(NSData *)data
                withKey:(NSString *)key
                     iv:(NSString *)iv{
    
    UInt8 *decryptedBuff = calloc(data.length,1);
    size_t decryptedLength = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, 0, [key cStringUsingEncoding:NSUTF8StringEncoding], 16, [iv cStringUsingEncoding:NSUTF8StringEncoding], decryptedBuff, (size_t)data.length, decryptedBuff, (size_t)data.length, &decryptedLength);
    assert(cryptStatus == kCCSuccess && decryptedLength == (size_t)data.length);
    NSData *decryptedData = [NSData dataWithBytes:decryptedBuff length:data.length];
    free(decryptedBuff);
    
    return decryptedData;
}

@end

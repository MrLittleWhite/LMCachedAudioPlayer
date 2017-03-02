//
//  LMAudioDecryptor.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 17/2/22.
//  Copyright © 2017年 lazy-iOS2. All rights reserved.
//

#import "LMAudioDecryptor.h"
#include <CommonCrypto/CommonCryptor.h>

@interface LMAudioDecryptor ()

@property (nonatomic, assign) NSRange originalRange;
@property (nonatomic, assign) UInt64 contentLength;

@property (nonatomic, assign) UInt64 decryptedLength;

@property (nonatomic, assign, readwrite) NSRange requireRange;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *iv;


@property (nonatomic, strong) NSMutableData *leftData;

@property (nonatomic, assign) NSUInteger remainLength;

@end

@implementation LMAudioDecryptor

- (instancetype)initWithRange:(NSRange)range
                contentLength:(UInt64)length
                      withKey:(NSString *)key
                           iv:(NSString *)iv{
    if (self = [super init]) {
        self.originalRange = range;
        self.contentLength = length;
        self.key = key;
        self.iv = iv;
        
        self.remainLength = range.length%1024;
        NSRange tempRange = range;
        if (self.contentLength > 0) {
            if (tempRange.location + tempRange.length + self.remainLength <= self.contentLength) {
                tempRange.length += self.remainLength;
            }
        }
        self.requireRange = tempRange;
        self.leftData = [NSMutableData data];
    }
    return self;
}

- (NSData *)decryptData:(NSData *)data{
    
    if (self.key.length <= 0 || self.iv.length <= 0) {
        return data;
    }
    
    if (data.length <= 0) {
        return nil;
    }
    
    [self.leftData appendData:data] ;
    self.decryptedLength += data.length;
    
    NSMutableData *tempData = [self.leftData mutableCopy];
    
    NSInteger multipleTimes = tempData.length/1024;
    
    NSUInteger supplyBuffSize = 0;
    
    if (multipleTimes <= 0) {
        if (self.decryptedLength < self.requireRange.length) {
            return nil;
        } else {
            supplyBuffSize = 1024-tempData.length;
//            UInt8 *supplyBuff = calloc(supplyBuffSize,1);
//            memset(supplyBuff, 0, supplyBuffSize);
//            [tempData appendBytes:supplyBuff length:supplyBuffSize];
//            free(supplyBuff);
            [tempData increaseLengthBy:supplyBuffSize];
            self.leftData = [NSMutableData data];
        }
    } else {
        if (self.decryptedLength < self.requireRange.length) {
            NSUInteger decryptlength = multipleTimes*1024;
            NSData *needDecryptData = [tempData subdataWithRange:NSMakeRange(0, decryptlength)];
            tempData = [NSMutableData dataWithData:needDecryptData];
            [self.leftData replaceBytesInRange:NSMakeRange(0, decryptlength)
                                     withBytes:NULL
                                        length:0];
        } else {
            supplyBuffSize = 1024-tempData.length%1024;
            [tempData increaseLengthBy:supplyBuffSize];
        }
    }
    
    NSData *realDecryptData = [tempData copy];
    
    NSAssert((realDecryptData.length%1024) <= 0, @"解密的长度必须为1024的长度的倍数");
    
    UInt8 *decryptedBuff = calloc(realDecryptData.length,1);
    size_t decryptedLength = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, 0, [self.key cStringUsingEncoding:NSUTF8StringEncoding], 16, [self.iv cStringUsingEncoding:NSUTF8StringEncoding], decryptedBuff, (size_t)realDecryptData.length, decryptedBuff, (size_t)realDecryptData.length, &decryptedLength);
    assert(cryptStatus == kCCSuccess && decryptedLength == (size_t)realDecryptData.length);
    NSData *decryptedData = [NSData dataWithBytes:decryptedBuff
                                           length:realDecryptData.length-supplyBuffSize];
    free(decryptedBuff);
    
    return decryptedData;
}

@end

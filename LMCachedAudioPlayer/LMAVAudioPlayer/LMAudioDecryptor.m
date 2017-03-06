//
//  LMAudioDecryptor.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 17/2/22.
//  Copyright © 2017年 lazy-iOS2. All rights reserved.
//

#import "LMAudioDecryptor.h"
#include <CommonCrypto/CommonCryptor.h>

#ifdef DEBUG
#define SLog(format, ...) printf("class: <%p %s:(%d) > method: %s \n%s\n", self, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(format), ##__VA_ARGS__] UTF8String] )
#else
#define SLog(format, ...)
#endif

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
        self.key = key;
        self.iv = iv;
        if (self.key.length <= 0 || self.iv.length <= 0) {
            self.requireRange = self.originalRange;
        } else{
            self.contentLength = length;
            
            self.remainLength = (16-range.length%16)%16;
            
            NSRange tempRange = range;
            if (self.contentLength > 0) {
                if (self.remainLength > 0) {
                    if (tempRange.location + tempRange.length + self.remainLength > self.contentLength) {
                        self.remainLength = self.contentLength-(tempRange.location+tempRange.length);
                    }
                    tempRange.length += self.remainLength;
                }
            } else if (tempRange.location == 0){
                tempRange.length += self.remainLength;
            }
            self.requireRange = tempRange;
            self.leftData = [NSMutableData data];
        }
        NSLog(@"debug contentLength %@\n", @(self.contentLength));
        NSLog(@"debug originalRange %@\n", NSStringFromRange(self.originalRange));
        NSLog(@"debug requireRange %@\n", NSStringFromRange(self.requireRange));
    }
    return self;
}

- (NSData *)decryptData:(NSData *)data{
    
//    NSString *deString = [self convertDataToHexStr:data];
    
    if (self.key.length <= 0 || self.iv.length <= 0) {
        return data;
    }
    
    if (data.length <= 0) {
        return nil;
    }
    
    [self.leftData appendData:data] ;
    
    self.decryptedLength += data.length;
    
    NSMutableData *tempData = [self.leftData mutableCopy];
    
    NSInteger multipleTimes = tempData.length/16;
    
    NSUInteger supplyBuffSize = 0;
    
    BOOL isNeedMinusRemainLength = NO;
    
    if (multipleTimes <= 0) {
        if (self.decryptedLength < self.requireRange.length) {
            return nil;
        } else {
            supplyBuffSize = (16-tempData.length)%16;
            [tempData increaseLengthBy:supplyBuffSize];
            [self.leftData setData:[NSData data]];
            isNeedMinusRemainLength = YES;
        }
    } else {
        if (self.decryptedLength < self.requireRange.length) {
            NSUInteger decryptlength = multipleTimes*16;
            NSData *needDecryptData = [tempData subdataWithRange:NSMakeRange(0, decryptlength)];
            tempData = [NSMutableData dataWithData:needDecryptData];
            [self.leftData replaceBytesInRange:NSMakeRange(0, decryptlength)
                                     withBytes:NULL
                                        length:0];
        } else {
            [self.leftData setData:[NSData data]];
            
            NSData *finalDecryptData = nil;
            NSUInteger finalLeftDataLength = tempData.length%16;
            NSUInteger supplyDataLength = (16-finalLeftDataLength)%16;
            if (finalLeftDataLength > 0) {
                NSMutableData *tempDecryptedData = [NSMutableData data];
                NSUInteger leftDataTimes = tempData.length/16;
                if (leftDataTimes > 0) {
                    NSUInteger toDecryptLength = leftDataTimes*16;
                    NSRange toDecryptRange = NSMakeRange(0,toDecryptLength);
                    NSMutableData *toDecryptData = [NSMutableData dataWithData:[tempData subdataWithRange:toDecryptRange]];
                    [tempData replaceBytesInRange:toDecryptRange withBytes:NULL length:0];
                    [tempDecryptedData appendData:[self innerDecryptData:toDecryptData]];
                    NSLog(@"");
                }
                [tempData increaseLengthBy:supplyDataLength];
                [tempDecryptedData appendData:[self innerDecryptData:tempData]];
                finalDecryptData = [tempDecryptedData copy];
            } else {
                finalDecryptData = [self innerDecryptData:tempData];
            }
            NSRange supplyRange = NSMakeRange(0,finalDecryptData.length-supplyDataLength-self.remainLength);
            NSData *reDecryptedData = [finalDecryptData subdataWithRange:supplyRange];
            return reDecryptedData;
        }
    }
    
    if (self.contentLength > 0 && self.decryptedLength >= self.contentLength) {
        
    }
    
    NSAssert(self.leftData.length < 16, @"");
    
    
    NSData *realDecryptData = [tempData copy];
    NSData *decryptedData = [self innerDecryptData:realDecryptData];

    
    NSUInteger realLength = realDecryptData.length-supplyBuffSize;
    if (isNeedMinusRemainLength) {
        NSAssert(realLength > self.remainLength, @"");
        realLength -= self.remainLength;
    }
    
    return [decryptedData subdataWithRange:NSMakeRange(0, realLength)];
}

- (NSData *)innerDecryptData:(NSData *)data{
    NSAssert((data.length%16) <= 0, @"解密的长度必须为16的长度的倍数");
    
    char *decryptedBuff = calloc(data.length,sizeof(char));
    memset(decryptedBuff, 0, data.length);
    size_t decryptedLength = 0;
    
    const char *decryptedKey = self.key.UTF8String;//calloc(self.key.length,sizeof(unichar));
    size_t keyLength = self.key.length;
    
    const char *decryptedIv = self.iv.UTF8String;//calloc(self.iv.length,sizeof(unichar));
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          0,
                                          decryptedKey,
                                          keyLength,
                                          decryptedIv,
                                          data.bytes,
                                          (size_t)data.length,
                                          decryptedBuff,
                                          (size_t)data.length,
                                          &decryptedLength);
    assert(cryptStatus == kCCSuccess && decryptedLength == (size_t)data.length);
    
    NSData *decryptedData = [NSData dataWithBytesNoCopy:decryptedBuff
                                                 length:decryptedLength
                                           freeWhenDone:YES];
    return decryptedData;
}

- (NSString *)convertDataToHexStr:(NSData *)data
{
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    return string;
}

@end

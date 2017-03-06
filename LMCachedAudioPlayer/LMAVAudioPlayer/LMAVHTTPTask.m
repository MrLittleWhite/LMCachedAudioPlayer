//
//  LMAVHTTPTask.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/12/5.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "LMAVHTTPTask.h"
#import "NSURL+LMAVAudioPlayer.h"
#import "LMAudioDecryptor.h"

@interface LMAVHTTPTask ()<NSURLSessionDelegate>

@property (nonatomic, strong, readwrite) AVAssetResourceLoadingRequest *loadingRequest;

@property (nonatomic, strong) LMAudioDecryptor *decryptor;

@property (nonatomic, strong) NSURLSession *taskSesstion;

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, assign) long long feededDataOffset;

@property (nonatomic, assign) long long contentLength;

@property (nonatomic, copy) NSString *aesDecryptKey;
@property (nonatomic, copy) NSString *aesDecryptIV;

@end

@implementation LMAVHTTPTask

- (instancetype)initWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
                         aesDecryptKey:(NSString *)aesDecryptKey
                          aesDecryptIV:(NSString *)aesDecryptIV
                         contentLength:(long long)contentLength{
    if (self = [super init]) {
        self.loadingRequest = loadingRequest;
        self.aesDecryptKey = aesDecryptKey;
        self.aesDecryptIV = aesDecryptIV;
        self.contentLength = contentLength;
        NSUInteger requestedOffset = (NSUInteger)self.loadingRequest.dataRequest.requestedOffset;
        NSUInteger requestedLength = (NSUInteger)self.loadingRequest.dataRequest.requestedLength;

        self.decryptor = [[LMAudioDecryptor alloc]
                          initWithRange:NSMakeRange(requestedOffset, requestedLength)
                          contentLength:self.contentLength
                                withKey:self.aesDecryptKey
                                     iv:self.aesDecryptIV];
    }
    return self;
}

- (void)dealloc{
#if DEBUG
    NSLog(@"HttpTask dealloc");
#endif
}

#pragma mark - setter & getter
- (NSURLSessionDataTask *)dataTask {
    if (!_dataTask) {
        long long requestedOffset = self.decryptor.requireRange.location;//self.loadingRequest.dataRequest.requestedOffset;
        //    long long currentOffset = loadingRequest.dataRequest.currentOffset;
        long long requestedLength = self.decryptor.requireRange.length;//self.loadingRequest.dataRequest.requestedLength;
        long long requestEnd = requestedOffset+requestedLength-1;
        
        
        NSURL *url = [NSURL URLWithString:self.urlStr];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
        [request addValue:[NSString stringWithFormat:@"bytes=%lld-%lld", requestedOffset+self.feededDataOffset, requestEnd] forHTTPHeaderField:@"Range"];
        _dataTask = [self.taskSesstion dataTaskWithRequest:request];
    }
    return _dataTask;
}

- (NSURLSession *)taskSesstion{
    if (!_taskSesstion) {
        _taskSesstion = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _taskSesstion;
}


#pragma mark - delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    if ([self.delegate respondsToSelector:@selector(lmAVHTTPTask:didReceiveResponse:forLoadingRequest:)]) {
        [self.delegate lmAVHTTPTask:self
                 didReceiveResponse:response
                  forLoadingRequest:self.loadingRequest];
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSData *decryptedData = [self.decryptor decryptData:data];
    if (decryptedData.length) {
        
#if DEBUG
//        NSString *decryptedString = [self convertDataToHexStr:decryptedData];
//        NSLog(@"%@",decryptedString);
#endif
        
        if ([self.delegate respondsToSelector:@selector(lmAVHTTPTask:didReceiveData:forLoadingRequest:)]) {
            [self.delegate lmAVHTTPTask:self
                         didReceiveData:decryptedData
                      forLoadingRequest:self.loadingRequest];
        }
    }
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

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    if ([self.delegate respondsToSelector:@selector(lmAVHTTPTask:didFinishTaskForLoadingRequest:error:)]) {
        [self.delegate lmAVHTTPTask:self didFinishTaskForLoadingRequest:self.loadingRequest
                              error:error];
    }
}

- (void)start {
    if (self.dataTask.state == NSURLSessionTaskStateSuspended) {
        [self.dataTask resume];
    }
}

- (void)pause {
    [self.dataTask suspend];
}

- (void)stop {
    [self.dataTask cancel];
    [self.taskSesstion invalidateAndCancel];
}

@end

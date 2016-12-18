//
//  LMAVHTTPTask.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/12/5.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "LMAVHTTPTask.h"
#import "NSURL+LMAVAudioPlayer.h"

@interface LMAVHTTPTask ()<NSURLSessionDelegate>

@property (nonatomic, strong, readwrite) AVAssetResourceLoadingRequest *loadingRequest;

@property (nonatomic, strong) NSURLSession *taskSesstion;

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, assign) long long feededDataOffset;

@end

@implementation LMAVHTTPTask

- (instancetype)initWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (self = [super init]) {
        self.loadingRequest = loadingRequest;
        
    }
    return self;
}

#pragma mark - setter & getter
- (NSURLSessionDataTask *)dataTask {
    if (!_dataTask) {
        long long requestedOffset = self.loadingRequest.dataRequest.requestedOffset;
        //    long long currentOffset = loadingRequest.dataRequest.currentOffset;
        long long requestedLength = self.loadingRequest.dataRequest.requestedLength;
        long long requestEnd = requestedOffset+requestedLength-1;
        
        
        NSURL *url = [self.loadingRequest.request.URL customURLWithScheme:self.oringalScheme];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
        [request addValue:[NSString stringWithFormat:@"bytes=%lld-%lld", requestedOffset+self.feededDataOffset, requestEnd] forHTTPHeaderField:@"Range"];
        self.taskSesstion = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _dataTask = [self.taskSesstion dataTaskWithRequest:request];
    }
    return _dataTask;
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
    if ([self.delegate respondsToSelector:@selector(lmAVHTTPTask:didReceiveData:forLoadingRequest:)]) {
        [self.delegate lmAVHTTPTask:self
                     didReceiveData:data
                  forLoadingRequest:self.loadingRequest];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    if (error) {
        NSLog(@"%@",error);
    }
    if ([self.delegate respondsToSelector:@selector(lmAVHTTPTask:didFinishTaskForLoadingRequest:)]) {
        [self.delegate lmAVHTTPTask:self didFinishTaskForLoadingRequest:self.loadingRequest];
    }
}

- (void)start {
    [self.dataTask resume];
}

- (void)stop {
    [self.dataTask suspend];
}

@end

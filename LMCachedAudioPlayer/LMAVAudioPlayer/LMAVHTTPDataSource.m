//
//  LMAVHTTPDataSource.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "LMAVHTTPDataSource.h"
#import "LMAVHTTPTask.h"
#import "Reachability.h"

@interface LMAVHTTPDataSource ()<LMAVHTTPTaskDelegate>

@property (nonatomic, strong) NSMutableArray *pendingRequestQueue;
@property (nonatomic, strong) NSMutableArray *finishedRequestQueue;

@property (nonatomic, strong) NSMutableArray<LMAVHTTPTask *> *httpTaskQueue;

//@property (nonatomic, strong) AVAssetResourceLoadingRequest *currentAssetRequest;

@property (nonatomic, assign, readwrite) BOOL isFinishLoad;

//@property (nonatomic, assign) long long feedDataOffset;
@property (nonatomic, assign) long long totalDataLength;

@property (nonatomic, strong) Reachability *networkReachability;

@property (nonatomic, strong) AVAssetResourceLoadingRequest *errorAssetRequest;

@end

@implementation LMAVHTTPDataSource

- (instancetype)init {
    if (self = [super init]) {
        self.pendingRequestQueue = [NSMutableArray array];
        self.finishedRequestQueue = [NSMutableArray array];
        self.httpTaskQueue = [NSMutableArray array];
        self.networkReachability = [Reachability reachabilityForInternetConnection];
        [self.networkReachability startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusDidChanged:) name:kReachabilityChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc{
#if DEBUG
    NSLog(@"DataSource dealloc");
#endif
    [self.networkReachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopAllTask];
}

#pragma mark - public LoadingRequest

- (BOOL)isFinishLoad{
    return self.httpTaskQueue.count <= 0;
//    return self.feedDataOffset == self.totalDataLength && self.totalDataLength > 0;
}

- (void)startCache {
    [self startAllTask];
}

- (void)pauseCache {
    [self pauseAllTask];
}


- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self processLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self removeHttpTaskByRequest:loadingRequest];
    [self.pendingRequestQueue removeObject:loadingRequest];
    [self.finishedRequestQueue removeObject:loadingRequest];
}

#pragma mark - process LoadingRequest

- (void)processLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (![self.pendingRequestQueue containsObject:loadingRequest]) {
#ifdef DEBUG
        NSLog(@"requestQueue: %@",@(self.pendingRequestQueue.count));
#endif
        [self.pendingRequestQueue addObject:loadingRequest];
        self.errorAssetRequest = nil;
        [self pauseAllTask];
        LMAVHTTPTask *avHTTPTask = [[LMAVHTTPTask alloc] initWithLoadingRequest:loadingRequest];
        avHTTPTask.oringalScheme = self.originalScheme;
        avHTTPTask.delegate = self;
        [avHTTPTask start];
        [self.httpTaskQueue addObject:avHTTPTask];
    } else {
        NSLog(@"lalala");
    }
}

#pragma mark - network handler
- (void)networkStatusDidChanged:(Reachability *)reachability {
    if (self.networkReachability.isReachable
        && self.errorAssetRequest) {
        [self.errorAssetRequest finishLoading];
        [self.pendingRequestQueue removeObject:self.errorAssetRequest];
    }
}

#pragma mark - task delegate
- (void)lmAVHTTPTask:(LMAVHTTPTask *)avHTTPTask didReceiveResponse:(NSURLResponse *)response forLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSAssert(httpResponse.statusCode == 206, @"error");
        loadingRequest.contentInformationRequest.contentType = [httpResponse.allHeaderFields objectForKey:@"Content-Type"];
        NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
        NSString * totalLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
//        if (self.feedDataOffset == 0) {
//            self.feedDataOffset = loadingRequest.dataRequest.requestedOffset;
//        }
        self.totalDataLength = totalLength.longLongValue;
        loadingRequest.contentInformationRequest.contentLength = totalLength.longLongValue;
    }
    if (!loadingRequest.contentInformationRequest.contentType.length) {
        loadingRequest.contentInformationRequest.contentType = @"audio/mpeg";
    }
    if (loadingRequest.contentInformationRequest.contentLength <= 0) {
        loadingRequest.contentInformationRequest.contentLength = response.expectedContentLength;
    }
}

- (void)lmAVHTTPTask:(LMAVHTTPTask *)avHTTPTask didReceiveData:(NSData *)data forLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
//    self.feedDataOffset += data.length;
    [loadingRequest.dataRequest respondWithData:data];
}

- (void)lmAVHTTPTask:(LMAVHTTPTask *)avHTTPTask didFinishTaskForLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest error:(NSError *)error{
//    if (self.feedDataOffset == self.totalDataLength && self.totalDataLength > 0) {
//        self.isFinishLoad = YES;
//    }
//    if (self.feedDataOffset != self.totalDataLength) {
//        self.feedDataOffset = 0;
//    }
    if (error && !self.networkReachability.isReachable) {
        self.errorAssetRequest = loadingRequest;
        [avHTTPTask stop];
    } else {
        self.errorAssetRequest = nil;
        [loadingRequest finishLoading];
        [avHTTPTask stop];
        [self removeHttpTaskByRequest:loadingRequest];
        [self.finishedRequestQueue addObject:loadingRequest];
        [self.pendingRequestQueue removeObject:loadingRequest];
        [self continueNextPendingRequest];
    }
}

#pragma mark - private method

- (void)continueNextPendingRequest{
    if (self.httpTaskQueue.count) {
        [self.httpTaskQueue.lastObject start];
    }
}

- (void)removeHttpTaskByRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSInteger index = [self.pendingRequestQueue indexOfObject:loadingRequest];
    if (index != NSNotFound && index < self.httpTaskQueue.count) {
        [self.httpTaskQueue removeObjectAtIndex:index];
    }
}

- (void)stopAllTask {
    for (LMAVHTTPTask *task in self.httpTaskQueue) {
        [task stop];
    }
}

- (void)startAllTask {
    for (LMAVHTTPTask *task in self.httpTaskQueue) {
        [task start];
    }
}

- (void)pauseAllTask {
    for (LMAVHTTPTask *task in self.httpTaskQueue) {
        [task pause];
    }
}

@end

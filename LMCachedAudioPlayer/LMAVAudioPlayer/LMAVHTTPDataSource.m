//
//  LMAVHTTPDataSource.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "LMAVHTTPDataSource.h"
#import "LMAVHTTPTask.h"

@interface LMAVHTTPDataSource ()<LMAVHTTPTaskDelegate>

@property (nonatomic, strong) NSMutableArray *pendingRequestQueue;
@property (nonatomic, strong) NSMutableArray *finishedRequestQueue;

@property (nonatomic, strong) LMAVHTTPTask *httpTask;

//@property (nonatomic, strong) AVAssetResourceLoadingRequest *currentAssetRequest;

@property (nonatomic, assign) long long feedDataOffset;

@end

@implementation LMAVHTTPDataSource

- (instancetype)init {
    if (self = [super init]) {
        self.pendingRequestQueue = [NSMutableArray array];
        self.finishedRequestQueue = [NSMutableArray array];
    }
    return self;
}

#pragma mark - public LoadingRequest

- (void)startCache {
    [self.httpTask start];
}

- (void)pauseCache {
    [self.httpTask pause];
}


- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self processLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self.pendingRequestQueue removeObject:loadingRequest];
    [self.finishedRequestQueue removeObject:loadingRequest];
}

#pragma mark - process LoadingRequest

- (void)processLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (![self.pendingRequestQueue containsObject:loadingRequest]) {
        [self.pendingRequestQueue addObject:loadingRequest];
        self.httpTask = [[LMAVHTTPTask alloc] initWithLoadingRequest:loadingRequest];
        self.httpTask.oringalScheme = self.originalScheme;
        self.httpTask.delegate = self;
        [self.httpTask start];
    } else {
        NSLog(@"xxx");
    }
//    self.currentAssetRequest = loadingRequest;
}

#pragma mark - task delegate
- (void)lmAVHTTPTask:(LMAVHTTPTask *)avHTTPTask didReceiveResponse:(NSURLResponse *)response forLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        loadingRequest.contentInformationRequest.contentType = [httpResponse.allHeaderFields objectForKey:@"Content-Type"];
        NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
        NSString * totalLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
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
    [loadingRequest.dataRequest respondWithData:data];
}

- (void)lmAVHTTPTask:(LMAVHTTPTask *)avHTTPTask didFinishTaskForLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [loadingRequest finishLoading];
    [avHTTPTask stop];
    [self.pendingRequestQueue removeObject:loadingRequest];
}

@end

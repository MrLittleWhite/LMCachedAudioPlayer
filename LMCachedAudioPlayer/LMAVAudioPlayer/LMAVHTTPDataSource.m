//
//  LMAVHTTPDataSource.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "LMAVHTTPDataSource.h"

@interface LMAVHTTPDataSource ()<NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, strong) NSMutableURLRequest *request;

@property (nonatomic, strong) AVAssetResourceLoadingRequest *currentAssetRequest;

@property (nonatomic, assign) long long feedDataOffset;

@end

@implementation LMAVHTTPDataSource

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self processLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    if ([self.currentAssetRequest isEqual:loadingRequest]) {
        self.currentAssetRequest = nil;
    }
}

#pragma mark - process LoadingRequest

- (void)processLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (!loadingRequest) return;
    if (self.connection) return;
    
    self.currentAssetRequest = loadingRequest;
    self.request = [[NSMutableURLRequest alloc] initWithURL:[loadingRequest.request.URL customURLWithScheme:self.originalScheme]];

    long long requestedOffset = loadingRequest.dataRequest.requestedOffset;
//    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    long long requestedLength = loadingRequest.dataRequest.requestedLength;
    long long requestEnd = requestedOffset+requestedLength-1;
    
    if (requestedOffset > 0) {
        [self.request addValue:[NSString stringWithFormat:@"bytes=%lld-%lld",requestedOffset,requestEnd] forHTTPHeaderField:@"Range"];
    }
    
    [self.connection cancel];
    self.connection = nil;
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
    [self.connection start];

}

#pragma mark - connection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.currentAssetRequest.dataRequest respondWithData:data];
    self.feedDataOffset += data.length;
    if (self.feedDataOffset>=self.currentAssetRequest.dataRequest.requestedLength) {
        self.feedDataOffset = 0;
        [self.connection cancel];
        [self.currentAssetRequest finishLoading];
        self.currentAssetRequest = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
}

@end

@implementation NSURL (LMAVAudioPlayer)

- (NSURL *)customURLWithScheme:(NSString *)scheme {
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:self
                                                resolvingAgainstBaseURL:NO];
    components.scheme = scheme;
    return [components URL];
}

@end

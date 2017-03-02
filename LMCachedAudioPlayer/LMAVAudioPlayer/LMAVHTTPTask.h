//
//  LMAVHTTPTask.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/12/5.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@protocol LMAVHTTPTaskDelegate;

@interface LMAVHTTPTask : NSObject

- (instancetype)initWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest;

@property (nonatomic, copy)  NSString *urlStr;

@property (nonatomic, weak) id<LMAVHTTPTaskDelegate> delegate;

@property (nonatomic, strong, readonly) AVAssetResourceLoadingRequest *loadingRequest;

@property (nonatomic, copy) NSString *aesDecryptKey;
@property (nonatomic, copy) NSString *aesDecryptIV;

- (void)start;

- (void)pause;

- (void)stop;

@end

@protocol LMAVHTTPTaskDelegate <NSObject>

@optional

- (void)lmAVHTTPTask:(LMAVHTTPTask *)avHTTPTask didReceiveData:(NSData *)data forLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest;

- (void)lmAVHTTPTask:(LMAVHTTPTask *)avHTTPTask didReceiveResponse:(NSURLResponse *)response forLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest;

- (void)lmAVHTTPTask:(LMAVHTTPTask *)avHTTPTask didFinishTaskForLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest error:(NSError *)error;

@end


//
//  LMAVHTTPDataSource.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface LMAVHTTPDataSource : NSObject<AVAssetResourceLoaderDelegate>

@property (nonatomic, copy)  NSString *urlStr;

@property (nonatomic, assign, readonly) BOOL isFinishLoad;

@property (nonatomic, strong, readonly) NSError *error;

@property (nonatomic, copy) NSString *aesDecryptKey;
@property (nonatomic, copy) NSString *aesDecryptIV;

- (void)startCache;
- (void)pauseCache;

@end

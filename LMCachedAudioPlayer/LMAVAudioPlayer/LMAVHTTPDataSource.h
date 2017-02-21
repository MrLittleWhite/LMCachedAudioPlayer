//
//  LMAVHTTPDataSource.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface LMAVHTTPDataSource : NSObject<AVAssetResourceLoaderDelegate>

@property (nonatomic, copy)  NSString *originalScheme;

@property (nonatomic, assign, readonly) BOOL isFinishLoad;

@property (nonatomic, strong, readonly) NSError *error;

- (void)startCache;
- (void)pauseCache;

@end

//
//  LMAVHTTPDataSource.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LMAVHTTPDataSource : NSObject<AVAssetResourceLoaderDelegate>

@property (nonatomic, copy)  NSString *originalScheme;

//- (void)startCache;
//- (void)pauseCache;

@end


@interface NSURL (LMAVAudioPlayer)

- (NSURL *)customURLWithScheme:(NSString *)scheme;

@end

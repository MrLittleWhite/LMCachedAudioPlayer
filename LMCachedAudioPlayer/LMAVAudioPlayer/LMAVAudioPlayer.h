//
//  LMAVAudioPlayer.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LMAVAudioPlayerConfig : NSObject

@property (nonatomic, copy) NSString *urlStr;

@property (nonatomic, copy) NSString *uniqueId;

@property (nonatomic, copy) NSString *userAgent;

@property (nonatomic, copy) NSString *cacheDirectory;

@property (nonatomic, strong) NSDictionary *predefinedHttpHeaderValues;

@property (nonatomic, assign) BOOL enableCache;

@property (nonatomic, assign, readonly) BOOL isHTTPUrl;

@end

typedef NS_ENUM(NSUInteger, LMAVAudioPlayerState) {
    LMAVAudioPlayerStatePause,
    LMAVAudioPlayerStatePlay,
    LMAVAudioPlayerStateEnd,
    LMAVAudioPlayerStateError
};


@interface LMAVAudioPlayer : NSObject

- (instancetype)initWithConfig:(LMAVAudioPlayerConfig *)config;

@property (nonatomic, assign, readonly) LMAVAudioPlayerState state;

@property (nonatomic, strong, readonly) NSError *error;

@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, assign, readonly) NSTimeInterval loadedTime;

- (void)play;

- (void)playFromOffsetTime:(NSTimeInterval)offsetTime;

- (void)pause;
- (void)PauseAudioAndCache;

@end

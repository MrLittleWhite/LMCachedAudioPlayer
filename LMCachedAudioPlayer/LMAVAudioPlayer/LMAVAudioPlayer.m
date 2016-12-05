//
//  LMAVAudioPlayer.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "LMAVAudioPlayer.h"
#import "LMAVHTTPDataSource.h"

@interface LMAVAudioPlayerConfig ()

@property (nonatomic, assign, readwrite) BOOL isHTTPUrl;

@end

@implementation LMAVAudioPlayerConfig

- (void)setUrlStr:(NSString *)urlStr{
    _urlStr = urlStr;
    self.isHTTPUrl = ![urlStr rangeOfString:@"file://"].length;
}

@end

@interface LMAVAudioPlayer ()

@property (nonatomic, strong) AVPlayer *audioPlayer;
@property (nonatomic, strong) LMAVAudioPlayerConfig *config;
@property (nonatomic, strong) LMAVHTTPDataSource *dataSource;

@property (nonatomic, assign) BOOL isPaused;

@end

@implementation LMAVAudioPlayer

- (instancetype)initWithConfig:(LMAVAudioPlayerConfig *)config{
    if (self = [super init]) {
        self.config = config;
        NSAssert(self.config.urlStr.length,@"");
        [self initPlayer];
    }
    return self;
}

#pragma mark - private method
- (void)initPlayer {
    NSURL *url = [NSURL URLWithString:self.config.urlStr];
    if (self.config.isHTTPUrl) {
        self.dataSource = [[LMAVHTTPDataSource alloc] init];
        self.dataSource.originalScheme = url.scheme;
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[url customURLWithScheme:@"streaming"]
                                                options:nil];
        [asset.resourceLoader setDelegate:self.dataSource
                                    queue:dispatch_get_main_queue()];
        AVPlayerItem *playItem = [AVPlayerItem playerItemWithAsset:asset];
        self.audioPlayer = [[AVPlayer alloc] initWithPlayerItem:playItem];
    } else {
        self.audioPlayer = [[AVPlayer alloc] initWithURL:url];
    }
}

#pragma mark - public method

- (void)play {
    [self.audioPlayer play];
    self.isPaused = NO;
}

- (void)playFromOffsetTime:(NSTimeInterval)offsetTime {
    [self.audioPlayer seekToTime:CMTimeMake(offsetTime, 1)];
}

- (void)pause {
    [self.audioPlayer pause];
    self.isPaused = YES;
}
- (void)PauseAudioAndCache {
    
}

@end

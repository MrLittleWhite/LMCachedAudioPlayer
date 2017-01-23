//
//  LMAVAudioPlayer.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "LMAVAudioPlayer.h"
#import "LMAVHTTPDataSource.h"
#import "NSURL+LMAVAudioPlayer.h"

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

@property (nonatomic, assign, readwrite) LMAVAudioPlayerState state;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, assign, readwrite) NSTimeInterval duration;
@property (nonatomic, assign, readwrite) NSTimeInterval currentTime;
@property (nonatomic, assign, readwrite) NSTimeInterval loadedTime;

@end

@implementation LMAVAudioPlayer

- (void)dealloc{
    [self removeObserverForPlayItem:self.audioPlayer.currentItem];
}

- (instancetype)initWithConfig:(LMAVAudioPlayerConfig *)config{
    if (self = [super init]) {
        self.config = config;
        NSAssert(self.config.urlStr.length,@"");
//        [self initPlayer];
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
    [self addObserverForPlayItem:self.audioPlayer.currentItem];
}

#pragma mark - public method

- (void)preload{
    if (!self.audioPlayer) {
        [self initPlayer];
    }
    [self.dataSource startCache];
}

- (void)play {
    [self preload];
    [self.audioPlayer play];
    if (self.state != LMAVAudioPlayerStatePlay) {
        self.state = LMAVAudioPlayerStatePause;
    }
    self.isPaused = NO;
}

- (void)playFromOffsetTime:(NSTimeInterval)offsetTime {
    [self.audioPlayer seekToTime:CMTimeMake(offsetTime, 1)];
}

- (void)pause {
    [self.audioPlayer pause];
    self.isPaused = YES;
    self.state = LMAVAudioPlayerStatePause;
}
- (void)pauseAudioAndLoad {
    [self pause];
    [self.dataSource pauseCache];
}

- (void)addObserverForPlayItem:(AVPlayerItem *)playerItem {
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    //监控网络加载情况属性
//    [playerItem addObserver:self
//                 forKeyPath:@"loadedTimeRanges"
//                    options:NSKeyValueObservingOptionNew
//                    context:nil];
    
//    [playerItem addObserver:self
//                 forKeyPath:@"playbackBufferEmpty"
//                    options:NSKeyValueObservingOptionNew
//                    context:nil];
    
//    //缓存可以播放的时候调用
//    [playerItem addObserver:self
//                 forKeyPath:@"playbackLikelyToKeepUp"
//                    options:NSKeyValueObservingOptionNew
//                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"rate"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayItemPlayBackStalled:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayItemFailPlayToEnd:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
}

- (void)removeObserverForPlayItem:(AVPlayerItem *)playerItem {
    [self.audioPlayer removeObserver:self forKeyPath:@"rate"];
    [playerItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
//    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    
}

- (void)handlePlayItemDidPlayToEnd:(NSNotification *)noti{
    
    NSLog(@"%@",noti.userInfo);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.audioPlayer seekToTime:CMTimeMake(0, 1)];
        [self.audioPlayer play];
    });
}

- (void)handlePlayItemFailPlayToEnd:(NSNotification *)noti{
    
    NSLog(@"%@",noti.userInfo);
}

- (void)handlePlayItemPlayBackStalled:(NSNotification *)noti{
    
    NSLog(@"%@",noti.userInfo);
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.audioPlayer.status) {
            case AVPlayerStatusUnknown:
                NSLog(@"AVPlayerStatusUnknown");
                break;
            case AVPlayerStatusReadyToPlay:
                NSLog(@"AVPlayerStatusReadyToPlay");
                break;
            case AVPlayerStatusFailed:
                NSLog(@"AVPlayerStatusFailed");
                break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
//        NSLog(@"loadedTimeRanges :%@",self.audioPlayer.currentItem.loadedTimeRanges);
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSLog(@"playbackBufferEmpty :%@",@(self.audioPlayer.currentItem.playbackBufferEmpty));
    } else if ([keyPath isEqualToString:@"rate"]) {
        float rate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        if (rate == 0.0) {
            if (self.state == LMAVAudioPlayerStatePlay) {
                self.state = LMAVAudioPlayerStateLoading;
            }
        } else {
            if (self.state == LMAVAudioPlayerStateLoading) {
                self.state = LMAVAudioPlayerStatePlay;
            }
        }
    }
}

#pragma mark - setter & getter

- (BOOL)isPlaying{
    return self.audioPlayer.rate > 0;
}

- (BOOL)canPlayWithoutLoading{
    return self.audioPlayer.status == AVPlayerStatusReadyToPlay
           && self.audioPlayer.currentItem.playbackLikelyToKeepUp;
}

- (void)setState:(LMAVAudioPlayerState)state{
    if (_state != state) {
        _state = state;
    }
}

- (NSTimeInterval)duration{
    CMTime cmTime = self.audioPlayer.currentItem.duration;
    return CMTimeGetSeconds(cmTime);
}

- (NSTimeInterval)currentTime{
    CMTime cmTime = self.audioPlayer.currentItem.currentTime;
    return CMTimeGetSeconds(cmTime);
}

- (NSTimeInterval)loadedTime{
    CMTimeRange timeRange = self.audioPlayer.currentItem.loadedTimeRanges.firstObject.CMTimeRangeValue;
    Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
    Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}

@end

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
#import "NSTimer+EOCBlocksSupport.h"

@interface LMAVAudioPlayerConfig ()

@property (nonatomic, assign, readwrite) BOOL isHTTPUrl;

@end

@implementation LMAVAudioPlayerConfig

- (void)setUrlStr:(NSString *)urlStr{
    _urlStr = urlStr;
    self.isHTTPUrl = [urlStr rangeOfString:@"http://"].length > 0;
}

@end

@interface LMAVAudioPlayer ()

@property (nonatomic, strong) AVPlayer *audioPlayer;
@property (nonatomic, strong) LMAVAudioPlayerConfig *config;
@property (nonatomic, strong) LMAVHTTPDataSource *dataSource;

@property (nonatomic, strong) NSTimer *tryPlayTimer;

//@property (nonatomic, assign) BOOL isPaused;

@property (nonatomic, assign, readwrite) LMAVAudioPlayerState state;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, assign, readwrite) NSTimeInterval duration;
@property (nonatomic, assign, readwrite) NSTimeInterval currentTime;
@property (nonatomic, assign, readwrite) NSTimeInterval loadedTime;

@property (nonatomic, assign) BOOL isAddObserve;
@property (nonatomic, assign) BOOL isSeeking;

@end

@implementation LMAVAudioPlayer

- (void)dealloc{
    [self removeObserverForPlayItem:self.audioPlayer.currentItem];
    [self stopTryPlay];
    
#if DEBUG
    NSLog(@"LMAVAudioPlayer dealloc");
#endif
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
    if (self.config.isHTTPUrl) {
        NSURL *url = [NSURL URLWithString:self.config.urlStr];
        
        self.dataSource = [[LMAVHTTPDataSource alloc] init];

        self.dataSource.urlStr = self.config.urlStr;
        self.dataSource.aesDecryptKey = self.config.aesDecryptKey;
        self.dataSource.aesDecryptIV = self.config.aesDecryptIV;
        
        NSURL *asstURL = [url customURLWithScheme:@"streaming"];
        
        NSRange rangeOfHttp = [asstURL.absoluteString rangeOfString:@"http://"];
        if (rangeOfHttp.length) {
            NSString *assetURLStr = [asstURL.absoluteString substringFromIndex:rangeOfHttp.location];
            asstURL = [[NSURL URLWithString:assetURLStr] customURLWithScheme:@"streaming"];
        }
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:asstURL
                                                options:nil];
        
        [asset.resourceLoader setDelegate:self.dataSource
                                    queue:dispatch_get_main_queue()];
        
        AVPlayerItem *playItem = [AVPlayerItem playerItemWithAsset:asset];
        
        self.audioPlayer = [[AVPlayer alloc] initWithPlayerItem:playItem];
    } else {
        NSURL *url = nil;
        if ([self.config.urlStr rangeOfString:@"file://"].length) {
            url = [NSURL URLWithString:self.config.urlStr];
        } else {
            url  = [NSURL fileURLWithPath:self.config.urlStr isDirectory:NO];
        }
        self.audioPlayer = [[AVPlayer alloc] initWithURL:url];
    }
    [self addObserverForPlayItem:self.audioPlayer.currentItem];
}

#pragma mark - public method

- (void)setMuted:(BOOL)muted{
    if (_muted != muted) {
        _muted = muted;
        self.audioPlayer.muted = muted;
    }
}

- (void)preload{
    if (!self.audioPlayer) {
        [self initPlayer];
    }
    [self.dataSource startCache];
}

- (void)play {
    if (self.state != LMAVAudioPlayerStatePlay) {
        self.error = nil;
        [self preload];
        //    self.isPaused = NO;
        if ([self canPlayWithoutLoading]) {
            if (self.audioPlayer.rate == 0.0) {
                [self.audioPlayer play];
            } else {
                [self.audioPlayer pause];
                [self.audioPlayer play];
            }
            if (self.isSeeking) {
                if(self.audioPlayer.rate != 0.0
                   && YES) {
                    self.isSeeking = NO;
                    self.state = LMAVAudioPlayerStatePlay;
                }
            } else {
                self.state = LMAVAudioPlayerStatePlay;
            }
        
        } else {
            self.state = LMAVAudioPlayerStateLoading;
        }
    }
}

- (void)playFromOffsetTime:(NSTimeInterval)offsetTime {
    __weak typeof (self) weakSelf = self;
    [self.audioPlayer.currentItem cancelPendingSeeks];
    [self.audioPlayer.currentItem seekToTime:CMTimeMake(offsetTime, 1) completionHandler:^(BOOL finished) {
//        if (finished && [weakSelf canPlayWithoutLoading]) {
//            [weakSelf.audioPlayer play];
//            weakSelf.state = LMAVAudioPlayerStatePlay;
//        }
//        self.isSeeking = NO;
//        [weakSelf.audioPlayer play];
        if (finished) {
//            NSLog(@"kkk");
            [weakSelf play];
            [weakSelf startTryPlayIfBufferLongEnough];
        }
//        [weakSelf.audioPlayer play];
//        [weakSelf.audioPlayer pause];
    }];
    self.state = LMAVAudioPlayerStateLoading;
    [self.audioPlayer pause];
    self.isSeeking = YES;
}

- (void)pause {
    self.state = LMAVAudioPlayerStatePause;
    [self.audioPlayer pause];
//    self.isPaused = YES;
}
- (void)pauseAudioAndLoad {
    [self pause];
    [self.dataSource pauseCache];
}

- (void)addObserverForPlayItem:(AVPlayerItem *)playerItem {
    self.isAddObserve = YES;
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
    
    //缓存可以播放的时候调用
    [playerItem addObserver:self
                 forKeyPath:@"playbackLikelyToKeepUp"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [self.audioPlayer addObserver:self
                 forKeyPath:@"rate"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayItemPlayBackStalled:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayItemFailPlayToEnd:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
}

- (void)removeObserverForPlayItem:(AVPlayerItem *)playerItem {
    if (self.isAddObserve) {
        [playerItem removeObserver:self forKeyPath:@"status"];
        [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.audioPlayer removeObserver:self forKeyPath:@"rate"];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        //    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        //    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    }
}

- (void)handlePlayItemDidPlayToEnd:(NSNotification *)noti{
    if (self.currentTime >= MAX(self.duration-1, 0)) {
        self.state = LMAVAudioPlayerStateEnd;
    } else if (self.state == LMAVAudioPlayerStatePlay){
        self.state = LMAVAudioPlayerStateLoading;
    }
}

- (void)handlePlayItemFailPlayToEnd:(NSNotification *)noti{
    self.error = self.audioPlayer.currentItem.error;
    self.state = LMAVAudioPlayerStateError;
}

- (void)handlePlayItemPlayBackStalled:(NSNotification *)noti{
    self.state = LMAVAudioPlayerStateLoading;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
#if DEBUG
    [self debugLog];
#endif
    if (self.isSeeking) {
        return;
    }
    
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.audioPlayer.currentItem.status) {
            case AVPlayerStatusUnknown:
                break;
            case AVPlayerStatusReadyToPlay:
                if (self.state == LMAVAudioPlayerStateLoading) {
//                    self.state = LMAVAudioPlayerStatePlay;
                }
                break;
            case AVPlayerStatusFailed:
                self.error = self.audioPlayer.currentItem.error;
                self.state = LMAVAudioPlayerStateError;
                break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        BOOL isLikelyKeepUp = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isLikelyKeepUp && self.state == LMAVAudioPlayerStateLoading) {
//            [self.audioPlayer play];
//            self.state = LMAVAudioPlayerStatePlay;
        }
    } else if ([keyPath isEqualToString:@"rate"]) {
        float rate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        
//        NSLog(@"rate: %@",@(rate));
        if (rate == 0.0) {
            if (self.state == LMAVAudioPlayerStatePlay) {
                self.state = LMAVAudioPlayerStateLoading;
            }
        } else {
            if (self.state == LMAVAudioPlayerStateLoading && self.audioPlayer.currentItem.isPlaybackLikelyToKeepUp) {
                self.state = LMAVAudioPlayerStatePlay;
            }
        }
//        if (rate == 0.0) {
//            if (self.state == LMAVAudioPlayerStatePlay) {
//                self.state = LMAVAudioPlayerStateLoading;
//            }
//        }
    }
}

#pragma mark - setter & getter

- (BOOL)canPlayWithoutLoading{
    return self.audioPlayer.currentItem.status == AVPlayerStatusReadyToPlay &&
           ((self.loadedTime - self.currentTime) >= 6
           || self.dataSource.isFinishLoad);
}

- (void)setState:(LMAVAudioPlayerState)state{
    if (_state != state) {
        _state = state;
        if (state == LMAVAudioPlayerStateLoading) {
            [self startTryPlayIfBufferLongEnough];
        } else {
            [self stopTryPlay];
        }
        if (state == LMAVAudioPlayerStatePlay) {
            self.audioPlayer.muted = NO;
        } else {
            self.audioPlayer.muted = YES;
        }
    }
}

- (NSTimeInterval)duration{
    CMTime cmTime = self.audioPlayer.currentItem.duration;
    NSTimeInterval dura = CMTimeGetSeconds(cmTime);
    return isnan(dura)?0:dura;
}

- (NSTimeInterval)currentTime{
    CMTime cmTime = self.audioPlayer.currentItem.currentTime;
    NSTimeInterval curr = CMTimeGetSeconds(cmTime);
    return isnan(curr)?0:curr;
}

- (NSTimeInterval)loadedTime{
    
    NSValue *tempTimeRangeValue = nil;
    for (NSValue *timeRangeValue in self.audioPlayer.currentItem.loadedTimeRanges) {
        if (CMTimeRangeContainsTime(timeRangeValue.CMTimeRangeValue,
                                    self.audioPlayer.currentItem.currentTime)) {
            tempTimeRangeValue = timeRangeValue;
        }
    }
    
    if (!tempTimeRangeValue) {
        NSTimeInterval result = CMTimeGetSeconds(self.audioPlayer.currentItem.currentTime);
        return isnan(result)?0:result;
    }
    
    CMTimeRange timeRange = tempTimeRangeValue.CMTimeRangeValue;
    Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
    Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;
    return isnan(result)?0:result;
}

#pragma mark - private space

- (void)startTryPlayIfBufferLongEnough{
    if (self.tryPlayTimer) return;
    
    __weak typeof (self) weakSelf = self;
    self.tryPlayTimer = [NSTimer eoc_scheduledTimerWithTimeInterval:3 block:^{
        if (weakSelf.state == LMAVAudioPlayerStateLoading) {
            if ([weakSelf canPlayWithoutLoading]) {
                [weakSelf play];
            }
        } else {
            [weakSelf stopTryPlay];
        }
    } repeats:YES];
}

- (void)stopTryPlay{
    [self.tryPlayTimer invalidate];
    self.tryPlayTimer = nil;
}

#pragma mark - debug 

- (void)debugLog{
    switch (self.audioPlayer.currentItem.status) {
        case AVPlayerStatusUnknown:
            NSLog(@"avPlayer item status:AVPlayerStatusUnknown");
            break;
        case AVPlayerStatusReadyToPlay:
            NSLog(@"avPlayer item status:AVPlayerStatusReadyToPlay");
            break;
        case AVPlayerStatusFailed:
            NSLog(@"avPlayer item status:AVPlayerStatusFailed");
            break;
        default:
            break;
    }
    switch (self.audioPlayer.status) {
        case AVPlayerStatusUnknown:
            NSLog(@"avPlayer status:AVPlayerStatusUnknown");
            break;
        case AVPlayerStatusReadyToPlay:
            NSLog(@"avPlayer status:AVPlayerStatusReadyToPlay");
            break;
        case AVPlayerStatusFailed:
            NSLog(@"avPlayer status:AVPlayerStatusFailed");
            break;
        default:
            break;
    }
    NSLog(@"avPlayer playbackLikelyToKeepUp:%@",@(self.audioPlayer.currentItem.playbackLikelyToKeepUp));
    NSLog(@"avPlayer rate:%@",@(self.audioPlayer.rate));
}

@end

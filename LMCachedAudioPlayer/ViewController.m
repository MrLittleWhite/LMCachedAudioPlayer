//
//  ViewController.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/20.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "ViewController.h"
#import "LMAVAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic, strong) LMAVAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSTimer *updateTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupPlayer];
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateTimerHandler:) userInfo:nil repeats:YES];
    
    
    [self.playButton setTitle:@"Pause" forState:UIControlStateSelected];
    [self.playButton addTarget:self
                        action:@selector(playOrPause:)
              forControlEvents:UIControlEventTouchUpInside];
    
    self.seekSlider.continuous = NO;
    [self.seekSlider addTarget:self
                        action:@selector(seekForSlider:)
              forControlEvents:UIControlEventValueChanged];
    
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ab"]) {
        self.switchButton.on = YES;
    }
    [self.switchButton addTarget:self action:@selector(switchButtonDidSwitch:) forControlEvents:UIControlEventValueChanged];
}

- (void)switchButtonDidSwitch:(UISwitch *)aSwitch {
    if (aSwitch.isOn) {
        [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"ab"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"ab"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setupPlayer];
}

- (void)setupPlayer{
    if (self.audioPlayer) {
        [self.audioPlayer pause];
        [self.audioPlayer removeObserver:self forKeyPath:@"state"];
        self.audioPlayer = nil;
    }
    
    LMAVAudioPlayerConfig *config = [[LMAVAudioPlayerConfig alloc] init];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ab"]) {
        NSString *localUrl = [[NSBundle mainBundle] pathForResource:@"sourthLady" ofType:@"mp3"];
        config.urlStr = localUrl;
    } else {
//        config.urlStr = @"http://kting.info/asdb/fiction/chuanyue/yx/xhc9fsoy.mp3";
        config.urlStr = @"http://wting.info/fiction/wenxue/sanguoyy/b9ysoipi.mp3";
        //        config.aesDecryptKey = @"k90er4hli2hk2sgn";
        //        config.aesDecryptIV = @"78afc8512559b62f";
//                config.urlStr = @"http://lazyaudio.gzproxy.10155.com:8070/?xyz=3000004823:1488358650:3d996ca368acd055e12f1b214490868c&url=http://wting.info/fiction/wenxue/sanguoyy/b9ysoipi.mp3";
//        config.urlStr = @"http://xmtvip.wting.info/crypt/aes/3.5M.mp3";
    }
    LMAVAudioPlayer *avPlayer = [[LMAVAudioPlayer alloc] initWithConfig:config];
    self.audioPlayer = avPlayer;
    
    [self.audioPlayer addObserver:self
                       forKeyPath:@"state"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
}

- (void)playOrPause:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        self.playButton.backgroundColor = [UIColor yellowColor];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
        [[AVAudioSession sharedInstance] setActive:YES error:NULL];
        [self.audioPlayer play];
    } else {
        self.playButton.backgroundColor = [UIColor greenColor];
//        [self.audioPlayer pause];
        [self.audioPlayer pauseAudioAndLoad];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"state"]) {
        LMAVAudioPlayerState state = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (state) {
            case LMAVAudioPlayerStatePause:
                self.playButton.selected = NO;
                self.stateLabel.text = @"暂停";
                self.stateLabel.textColor = [UIColor blackColor];
                break;
            case LMAVAudioPlayerStatePlay:
                self.stateLabel.text = @"播放";
                self.stateLabel.textColor = [UIColor greenColor];
                break;
            case LMAVAudioPlayerStateLoading:
                self.stateLabel.text = @"加载";
                self.stateLabel.textColor = [UIColor yellowColor];
                break;
            case LMAVAudioPlayerStateEnd:
                self.stateLabel.text = @"完毕";
                self.stateLabel.textColor = [UIColor cyanColor];
                self.playButton.selected = NO;
                break;
            case LMAVAudioPlayerStateError:
                self.stateLabel.text = @"失败";
                self.stateLabel.textColor = [UIColor redColor];
                self.playButton.selected = NO;
                break;
            default:
                break;
        }
    }
}

- (void)seekForSlider:(UISlider *)slider {
    NSTimeInterval seekTime = self.audioPlayer.duration*slider.value;
    [self.audioPlayer playFromOffsetTime:seekTime];
    self.seekTimeLabel.text = [NSString stringWithFormat:@"SeekTime:%@",@(seekTime)];
}

- (void)updateTimerHandler:(NSTimer *)timer {
    if (self.audioPlayer) {
        self.durationLabel.text = [NSString stringWithFormat:@"Duration:%@",@(self.audioPlayer.duration)];
        self.currentTimeLabel.text = [NSString stringWithFormat:@"CurrentTime:%@",@(self.audioPlayer.currentTime)];
        self.loadedTimeLabel.text = [NSString stringWithFormat:@"LoadedTime:%@",@(self.audioPlayer.loadedTime)];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self.audioPlayer removeObserver:self forKeyPath:@"state"];
//    self.audioPlayer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

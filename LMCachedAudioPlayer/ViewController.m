//
//  ViewController.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/20.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "ViewController.h"
#import "LMAVAudioPlayer.h"

@interface ViewController ()

@property (nonatomic, strong) LMAVAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSTimer *updateTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    LMAVAudioPlayerConfig *config = [[LMAVAudioPlayerConfig alloc] init];
    config.urlStr = @"http://kting.info/asdb/fiction/chuanyue/yx/xhc9fsoy.mp3";
    LMAVAudioPlayer *avPlayer = [[LMAVAudioPlayer alloc] initWithConfig:config];
    self.audioPlayer = avPlayer;
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateTimerHandler:) userInfo:nil repeats:YES];
    
    
    [self.playButton setTitle:@"Pause" forState:UIControlStateSelected];
    [self.playButton addTarget:self
                        action:@selector(playOrPause:)
              forControlEvents:UIControlEventTouchUpInside];
    
    self.seekSlider.continuous = NO;
    [self.seekSlider addTarget:self
                        action:@selector(seekForSlider:)
              forControlEvents:UIControlEventValueChanged];
}

- (void)playOrPause:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        self.playButton.backgroundColor = [UIColor yellowColor];
        [self.audioPlayer play];
    } else {
        self.playButton.backgroundColor = [UIColor greenColor];
//        [self.audioPlayer pause];
        [self.audioPlayer pauseAudioAndLoad];
    }
}

- (void)seekForSlider:(UISlider *)slider {
    NSTimeInterval seekTime = self.audioPlayer.duration*slider.value;
    [self.audioPlayer playFromOffsetTime:seekTime];
    self.seekTimeLabel.text = [NSString stringWithFormat:@"SeekTime:%@",@(seekTime)];
}

- (void)updateTimerHandler:(NSTimer *)timer {
    self.durationLabel.text = [NSString stringWithFormat:@"Duration:%@",@(self.audioPlayer.duration)];
    self.currentTimeLabel.text = [NSString stringWithFormat:@"CurrentTime:%@",@(self.audioPlayer.currentTime)];
    self.loadedTimeLabel.text = [NSString stringWithFormat:@"LoadedTime:%@",@(self.audioPlayer.loadedTime)];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

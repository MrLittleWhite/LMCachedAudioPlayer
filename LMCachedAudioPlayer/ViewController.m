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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    LMAVAudioPlayerConfig *config = [[LMAVAudioPlayerConfig alloc] init];
    config.urlStr = @"http://kting.info/asdb/fiction/chuanyue/yx/xhc9fsoy.mp3";
    LMAVAudioPlayer *avPlayer = [[LMAVAudioPlayer alloc] initWithConfig:config];
    self.audioPlayer = avPlayer;
    [avPlayer play];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

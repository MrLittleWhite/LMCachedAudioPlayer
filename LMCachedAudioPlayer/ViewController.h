//
//  ViewController.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/20.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *loadedTimeLabel;

@property (weak, nonatomic) IBOutlet UILabel *seekTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *seekSlider;

@property (weak, nonatomic) IBOutlet UISwitch *switchButton;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;


@end


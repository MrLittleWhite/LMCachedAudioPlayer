//
//  NSTimer+EOCBlocksSupport.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 17/2/5.
//  Copyright © 2017年 lazy-iOS2. All rights reserved.
//

#import "NSTimer+EOCBlocksSupport.h"
#import <objc/runtime.h>

@implementation NSTimer (EOCBlocksSupport)

+ (NSTimer *)eoc_scheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                          block:(void(^)())block
                                        repeats:(BOOL)yesOrNo{
    return [self scheduledTimerWithTimeInterval:ti target:self selector:@selector(eoc_blockInvoke:) userInfo:[block copy] repeats:yesOrNo];
}

+ (void)eoc_blockInvoke:(NSTimer *)timer{
    void (^block)() = timer.userInfo;
    if (block) {
        block();
    }
}

@end

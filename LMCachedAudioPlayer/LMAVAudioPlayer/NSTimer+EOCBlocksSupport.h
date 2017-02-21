//
//  NSTimer+EOCBlocksSupport.h
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 17/2/5.
//  Copyright © 2017年 lazy-iOS2. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (EOCBlocksSupport)

+ (NSTimer *)eoc_scheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                          block:(void(^)())block
                                        repeats:(BOOL)yesOrNo;

@end

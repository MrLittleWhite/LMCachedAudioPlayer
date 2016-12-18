//
//  NSURL+LMAVAudioPlayer.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/12/6.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "NSURL+LMAVAudioPlayer.h"

@implementation NSURL (LMAVAudioPlayer)

- (NSURL *)customURLWithScheme:(NSString *)scheme {
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:self
                                                resolvingAgainstBaseURL:NO];
    components.scheme = scheme;
    return [components URL];
}

@end

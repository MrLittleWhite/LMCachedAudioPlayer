//
//  LMAVHTTPDataSource.m
//  LMCachedAudioPlayer
//
//  Created by lazy-iOS2 on 16/11/21.
//  Copyright © 2016年 lazy-iOS2. All rights reserved.
//

#import "LMAVHTTPDataSource.h"

@implementation LMAVHTTPDataSource


- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    
    return NO;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    
}

@end

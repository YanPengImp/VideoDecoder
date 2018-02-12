//
//  CDVideoDecoder.h
//  CodoonSport
//
//  Created by Imp on 2017/11/17.
//  Copyright © 2017年 Codoon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class CDVideoDecoder;

@protocol CDVideoDecoderDelegate <NSObject>

- (void)videoDecoder:(CDVideoDecoder *)videoDecoder onNewVideoFrameReady:(CGImageRef)imageRef;

- (void)videoDecoderDidFinish:(CDVideoDecoder *)videoDecoder;

@end

@interface CDVideoDecoder : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSMutableArray *imageArray;

@property (nonatomic, weak) id <CDVideoDecoderDelegate> delegate;

- (void)transformVideoPathToSampBufferRef:(NSString *)videoPath sampleInternal:(NSTimeInterval)sampleInternal;

@end

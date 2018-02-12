//
//  CDVideoDecoder.m
//  CodoonSport
//
//  Created by Imp on 2017/11/17.
//  Copyright © 2017年 Codoon. All rights reserved.
//

#import "CDVideoDecoder.h"
#import <UIKit/UIKit.h>

@interface UIImage (SampleBufferRef)

+ (CGImageRef)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef;

@end

@implementation UIImage (SampleBufferRef)

+ (CGImageRef)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef
{
    // 为媒体数据设置一个CMSampleBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    // 锁定 pixel buffer 的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到 pixel buffer 的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到 pixel buffer 的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到 pixel buffer 的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    // 创建一个依赖于设备的 RGB 颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphic context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    //根据这个位图 context 中的像素创建一个 Quartz image 对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁 pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    // 释放 context 和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // 用 Quzetz image 创建一个 UIImage 对象
    // UIImage *image = [UIImage imageWithCGImage:quartzImage];

    // 释放 Quartz image 对象
    //    CGImageRelease(quartzImage);

    return quartzImage;
}


@end


@implementation CDVideoDecoder

+ (instancetype)sharedInstance {
    static CDVideoDecoder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CDVideoDecoder alloc] init];
    });
    return instance;
}

- (id)init {
    if (self = [super init]) {
        self.imageArray = [NSMutableArray array];
    }
    return self;
}

- (void)transformVideoPathToSampBufferRef:(NSString *)videoPath sampleInternal:(NSTimeInterval)sampleInternal{
    [self.imageArray removeAllObjects];
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    NSError *error = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];

    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack =[videoTracks objectAtIndex:0];

    int m_pixelFormatType = kCVPixelFormatType_32BGRA;
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setObject:@(m_pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
    [reader addOutput:videoReaderOutput];
    [reader startReading];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        while ([reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
            CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
            [self transformSampleBufferRedToCGImageRef:videoBuffer];
            if (videoBuffer) {
                CFRelease(videoBuffer);
            }
            [NSThread sleepForTimeInterval:CMTimeGetSeconds(videoTrack.minFrameDuration) - 0.01];
        }
        [self.delegate videoDecoderDidFinish:self];
    });
}

- (void)transformSampleBufferRedToCGImageRef:(CMSampleBufferRef)videoBuffer {
    CGImageRef cgimage = [UIImage imageFromSampleBufferRef:videoBuffer];
    if (!(__bridge id)(cgimage)) { return; }
    [_imageArray addObject:((__bridge id)(cgimage))];
    [self.delegate videoDecoder:self onNewVideoFrameReady:cgimage];
    CGImageRelease(cgimage);
}

@end

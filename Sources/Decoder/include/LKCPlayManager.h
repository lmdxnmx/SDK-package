//
//  LKCPlayManager.h
//  OctobarBaby
//
//  Created by lazy-thuai on 14/6/4.
//  Copyright (c) 2014年 luckcome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//本地播放类
@protocol LKCPlayManagerUIDelegate <NSObject>
//代理方法，各个继承累需要实现这个方法，比如LKCMonitorView和LKCChooseMusicViewController
- (void)currentPlaybackTimeChanged:(NSTimeInterval)currentTime;
- (void)totalPlaybackTimeChanged:(NSTimeInterval)totalTime;
- (void)playingStateChanged:(BOOL)playing;
- (void)playerStoped:(BOOL)manual;
- (void)audioDidFinishPlaying;
@end

@interface LKCPlayManager : NSObject <AVAudioPlayerDelegate>

+ (instancetype)sharedPlayManager;
+ (void)setDelegate:(id<LKCPlayManagerUIDelegate>)delegate;
+ (void)play:(NSURL *)audioURL; //播放一首音乐
+ (void)resume;
+ (void)pause;
+ (void)next:(NSURL *)audioURL;
+ (void)prev:(NSURL *)audioURL;
+ (void)stop;
+ (void)playSeekTime:(NSTimeInterval)seekTime;
+ (BOOL)getPlayState;

- (NSTimeInterval)duration; // 音频总时长
- (NSTimeInterval)currentTime;  // 当前的播放进度

// 创建音频播放器
- (void)createPlayerWithURL:(NSURL *)url;
// 播放或者暂停
- (void)playOrPuase;
// 获取音频资源的url
- (NSURL *)audioURL;
@end

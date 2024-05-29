//
//  LKCPlayManager.m
//  OctobarBaby
//
//  Created by lazy-thuai on 14/6/4.
//  Copyright (c) 2014年 luckcome. All rights reserved.
//

#import "LKCPlayManager.h"

@interface LKCPlayManager ()
@property (nonatomic, assign) BOOL isPlaying;///是否在播放
@property (nonatomic, assign) id<LKCPlayManagerUIDelegate> delegate;//定义一个委托变量
@property (nonatomic, strong) NSTimer *callDelegateTimer;//定时器，0.5秒触发一次
@property (nonatomic, strong) AVAudioPlayer *player;//苹果自带的音频播放器

- (void)playOrPuase;
- (void)stopPlay;
- (void)createPlayerWithURL:(NSURL *)url;
- (void)seekTime:(NSTimeInterval)time;
@end

@implementation LKCPlayManager

//类方法，返回一个 LKCPlayManager
+ (instancetype)sharedPlayManager
{
    static LKCPlayManager *playManager;
    static dispatch_once_t onceToken;//dispatch_once可以保证代码只被执行一次
    dispatch_once(&onceToken, ^{
        playManager = [[LKCPlayManager alloc] init];
        playManager.callDelegateTimer = [NSTimer timerWithTimeInterval:0.5 target:playManager selector:@selector(timeTick:) userInfo:nil repeats:YES];//创建一个定时器timeTick，每隔0.5s发送一个消息给playManager
        [[NSRunLoop mainRunLoop] addTimer:playManager.callDelegateTimer forMode:NSRunLoopCommonModes];//将该定时器加入到mainRunLoop线程中，用runloop后这个线程就不会退出了,会停止在这里？调试结果是没有，直接下去了！
        playManager.isPlaying = NO;
    });
    
    return playManager;
}

//代理他的类中需要会调用这个函数，lKCMonitorView中 initWithFrame:(CGRect)frame设置
+ (void)setDelegate:(id<LKCPlayManagerUIDelegate>)delegate
{
    [LKCPlayManager sharedPlayManager].delegate = delegate;
}

//播放一首音乐
+ (void)play:(NSURL *)audioURL
{
    LKCPlayManager *manager = [LKCPlayManager sharedPlayManager];
    [manager createPlayerWithURL:audioURL];// 创建音频播放器
    [manager playOrPuase];// 播放或者暂停
}

//复位
+ (void)resume
{
    [[LKCPlayManager sharedPlayManager] playOrPuase];
}

//暂停
+ (void)pause
{
    [[LKCPlayManager sharedPlayManager] playOrPuase];
}

//播放前一首
+ (void)prev:(NSURL *)audioURL
{
    [[LKCPlayManager sharedPlayManager] createPlayerWithURL:audioURL];
    [[LKCPlayManager sharedPlayManager] playOrPuase];
}

//播放后一首
+ (void)next:(NSURL *)audioURL
{
    [[LKCPlayManager sharedPlayManager] createPlayerWithURL:audioURL];
    [[LKCPlayManager sharedPlayManager] playOrPuase];
}

//停止
+ (void)stop
{
    [[LKCPlayManager sharedPlayManager] stopPlay];
}

+ (void)playSeekTime:(NSTimeInterval)seekTime
{
    LKCPlayManager *playManager = [LKCPlayManager sharedPlayManager];
    [playManager seekTime:seekTime];
    
//    DLog(@"%@",playManager.player.url);
    
    if (playManager.player && playManager.player.url) {
        playManager.isPlaying = YES;
    }
}

+ (BOOL)getPlayState
{
    return [[[LKCPlayManager sharedPlayManager] player] isPlaying];
}

- (void)playOrPuase
{
    if (!self.player) {
        return;
    }
    
    if ([self.player isPlaying]) {
        [self.player pause];
        self.isPlaying = NO;
    }
    else
    {
        [self.player play];
        self.isPlaying = YES;
    }
}

- (void)stopPlay
{
    if (self.player) {
        [self.player stop];
        self.player.currentTime = 0;
        self.player = nil;
    }
    self.isPlaying = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerStoped:)]) {
        [self.delegate playerStoped:YES];//调用代理方法
        /**
         * 1:  代理的知识
         * 2:  [self.delegate respondsToSelector:@selector(playerStoped:)]:是否能执行playerStoped方法。比如LKCMonitorView和LKCChooseMusicViewController中实现了playerStoped方法
         */
    }
}

- (void)createPlayerWithURL:(NSURL *)url
{
    if (self.player) {
        [self.player stop];
        self.player = nil;
    }
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player setDelegate:self];
    [self.player prepareToPlay]; 
}

- (NSURL *)audioURL
{
    if (self.player) {
        return [self.player url];
    }
    return nil;
}

- (void)seekTime:(NSTimeInterval)time
{
    NSTimeInterval toTime = time > self.player.duration ? self.player.duration : time;
    [self.player pause];
    [self.player setCurrentTime:toTime];
    [self.player prepareToPlay];
    [self.player play];
}

- (NSTimeInterval)duration
{
    return self.player.duration;
}

- (NSTimeInterval)currentTime
{
    return self.player.currentTime;
}

#pragma mark -
#pragma mark Setters & Getters

- (void)setIsPlaying:(BOOL)isPlaying
{
    _isPlaying = isPlaying;
    if ([self.delegate respondsToSelector:@selector(playingStateChanged:)]) {
        [self.delegate playingStateChanged:isPlaying];
        /**
         * 1:  代理的知识
         * 2:  [self.delegate respondsToSelector:@selector(playerStoped:)]:是否能执行playerStoped方法。比如LKCMonitorView和LKCChooseMusicViewController中实现了playingStateChanged方法
         */
    }
}

#pragma mark - Timer Tick Function
//定时器，sharedPlayManager中创建
- (void)timeTick:(NSTimer *)timer
{
    if (self.delegate && [self.player isPlaying]) {
        if ([self.delegate respondsToSelector:@selector(currentPlaybackTimeChanged:)]) {
            [self.delegate currentPlaybackTimeChanged:self.player.currentTime];
        }
        if ([self.delegate respondsToSelector:@selector(totalPlaybackTimeChanged:)]) {
            [self.delegate totalPlaybackTimeChanged:self.player.duration];
        }
    }
}

#pragma mark - AVAudioPlayerDelegate

// 播放完毕相应函数
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    // 音频播放
    self.player = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerStoped:)]){
        [self.delegate playerStoped:NO];
    }
}

@end

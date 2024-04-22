//
//  LKCDecodeHeart.h
//  OctobarBaby
//
//  Created by lazy-thuai on 14-7-5.
//  Copyright (c) 2014年 luckcome. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  单个心率数据模型
 */
@interface LKCDecodeHeart : NSObject <NSCoding>

@property (assign, nonatomic) NSInteger rate;       // 胎心率 没有时为0 ， 范围 50 － 210 bmp
@property (assign, nonatomic) NSInteger rate2;      // 胎心率 没有时为0 ， 范围 50 － 210 bmp
@property (assign, nonatomic) NSInteger tocoValue;  // 宫缩压力           范围 0  — 100

@property (assign, nonatomic) NSInteger battValue;   //电池电量           范围 0  — 4
@property (assign, nonatomic) NSInteger signal;     // 胎心信号质量        范围 0 － 3
@property (assign, nonatomic) NSInteger afm;        // 自动胎动曲线        范围 0 － 40

@property (assign, nonatomic) NSInteger afmFlag; //是否监测到自动胎动 范围 0（没有）－ 1（一次自动胎动）
@property (assign, nonatomic) NSInteger fmFlag; //手动胎动标记   范围 0（没有）－ 1（记一次手动胎动）
@property (assign, nonatomic) NSInteger tocoFlag; //宫缩复位标记 范围 0（没有）－ 1（记一次宫缩复位）

@property (assign, nonatomic) NSInteger isRate;     //数据包是否包含rate参数  范围 0（不包含） － 1（包含）
@property (assign, nonatomic) NSInteger isRate2;    //数据包是否包含rate2参数 范围 0（不包含） － 1（包含）
@property (assign, nonatomic) NSInteger isToco;     //数据包是否包含TOCO参数  范围 0（不包含） － 1（包含）
@property (assign, nonatomic) NSInteger isAfm;      //数据包是否包含AFM参数   范围 0（不包含） － 1（包含）

@end

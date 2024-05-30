//
//  LMTPDecoder.h
//  OctobarGoodBaby
//
//  Created by 莱康宁 on 16/3/16.
//  Copyright © 2016年 luckcome. All rights reserved.
//
#define VERSION_NAME  @"2.3"

#import <Foundation/Foundation.h>
#import "LKCDecodeHeart.h"
@import CoreBluetooth;

@interface LMTPDecoder : NSObject


/**
 *  创建莱康宁移动终端解析器实例对象
 *  @return 返回单例对象 lmtpDecoder
 */
+ (id)shareInstance;


/**
 *  与终端设备连接成功之后，开始实时播放声音
 */
- (void)startRealTimeAudioPlyer;


/**
 *  与终端设备断开蓝牙连接之后，关闭实时播放声音
 */
- (void)stopRealTimeAudioPlyer;


/**
 *  与终端设备连接成功之后,并读取到设备特征值存在之后，开始数据解析
 *  @return 返回胎心率数据解析后的对象
 */
- (LKCDecodeHeart *)startDecoderWithCharacterData:(NSData*)characteristicData;


/**
 * 开始记录监听数据，并同时记录并保存下 声音数据 和 胎心率数据 并输入想要保存 声音数据地址文件地址 后缀为.mp3
 */
- (void)startMonitorWithAudioFilePath:(NSString *)FilePath;


/**
 * 结束记录监听数据，
 */
- (void)stopMoniter;


/**
 * 添加一次手动胎动，当进行一次手动胎动操作的时候调用此函数
 */
- (void)setFM;


/**
 * 发送宫缩复位命令 范围 0～3 档 ,
 * isToco 是否宫缩 范围 0～1 档 ，1 代表宫缩复位 ，0代表其他情况
 * tocoValue 宫缩复位值 范围 0～3 档，0:宫缩复位值为0 ，1:宫缩复位值为10 ，2:宫缩复位值为15 ， 3:宫缩复位值为20
 * peripheral 为外围的蓝牙设备  characteristic 为搜索到的蓝牙特征
 */
- (void)sendTocoReset:(int)isToco WithTocoResetValue:(int)tocoValue  forCBPeripheral:(CBPeripheral *)peripheral  WithCharacteristic:(CBCharacteristic *)characteristic;


/**
 * 发送胎心声音大小调节命令 范围 0～7档 ,peripheral 为外围的蓝牙设备  characteristic 为搜索到的蓝牙特征
 */
- (void)sendFhrValue:(int)audioValue  forCBPeripheral:(CBPeripheral *)peripheral  WithCharacteristic:(CBCharacteristic *)characteristic;


/**
 * 发送报警级别命令 范围 0～3 档，分别对应 没有报警，低级报警，中级报警，高级报警 ,peripheral 为外围的蓝牙设备  characteristic 为搜索到的蓝牙特征
 */
- (void)sendFhrAlarmLevel:(int)level  forCBPeripheral:(CBPeripheral *)peripheral  WithCharacteristic:(CBCharacteristic *)characteristic;


/**
 * 发送报警音量大小调节命令 范围 0～7 档 ,peripheral 为外围的蓝牙设备  characteristic 为搜索到的蓝牙特征
 */
- (void)sendFhrAlarmValue:(int)level  forCBPeripheral:(CBPeripheral *)peripheral  WithCharacteristic:(CBCharacteristic *)characteristic;


/**
 * 查询设备的软件版本(暂未开发)
 * @return 设备的软件版本号
 */
- (NSString *)getVersion;


@end


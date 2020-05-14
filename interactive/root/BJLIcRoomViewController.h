//
//  BJLIcRoomViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-07.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>
#import <BJLiveBase/BJLiveBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcRoomViewController : UIViewController

/** 直播教室
 参考 `BJLiveCore` */
@property (nonatomic, readonly, nullable) BJLRoom *room;

/**
 通过参加码创建教室，默认用户视频位于上侧的布局
 #param roomSecret      教室参加码
 #param userName        用户名
 #param userAvatar      用户头像 URL
 #return                教室
 */
+ (__kindof instancetype)instanceWithSecret:(NSString *)roomSecret
                                   userName:(NSString *)userName
                                 userAvatar:(nullable NSString *)userAvatar;

/**
 通过 ID 创建教室，默认用户视频位于上侧的布局
 #param roomID          教室 ID
 #param user            用户，初始化时的属性未标记可为空的都需要有值，且字符值长度不能为0
 #param apiSign         API sign
 #return                教室
 */
+ (__kindof instancetype)instanceWithID:(NSString *)roomID
                                apiSign:(NSString *)apiSign
                                   user:(BJLUser *)user;

/** 分享表情报告, 表情报告链接，首个表情截图链接，表情报告用户名 */
@property (nonatomic, nullable) void (^shareExpressExportCallback)(NSString * _Nullable contentURLString, NSString * _Nullable firstExpressURLString, NSString * _Nullable userName);

/** 跑马灯内容 */
@property (nonatomic, copy, nullable) NSString *customLampContent;

- (void)exit;

#pragma mark - observable methods

- (BJLObservable)classViewControllerEnterRoomSuccess:(BJLIcRoomViewController *)classViewController;

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController enterRoomFailureWithError:(BJLError *)error;

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController willExitWithError:(nullable BJLError *)error;

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController didExitWithError:(nullable BJLError *)error;

@end

NS_ASSUME_NONNULL_END

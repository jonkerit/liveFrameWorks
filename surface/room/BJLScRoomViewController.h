//
//  BJLScRoomViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BJLScRoomViewControllerDelegate;

@interface BJLScRoomViewController : UIViewController

/** 直播教室
 参考 `BJLiveCore` */
@property (nonatomic, readonly, nullable) BJLRoom *room;

/** 事件回调 `delegate` */
@property (nonatomic, weak) id<BJLScRoomViewControllerDelegate> delegate;

// 支持分享
@property (nonatomic, readonly) BOOL enableShare;

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

- (void)exit;

/** 跑马灯内容 */
@property (nonatomic, copy, nullable) NSString *customLampContent;


#pragma mark - observable methods

- (BJLObservable)roomViewControllerEnterRoomSuccess:(BJLScRoomViewController *)roomViewController;
- (BJLObservable)roomViewController:(BJLScRoomViewController *)roomViewController
          enterRoomFailureWithError:(BJLError *)error;

- (BJLObservable)roomViewController:(BJLScRoomViewController *)roomViewController
                  willExitWithError:(nullable BJLError *)error;
- (BJLObservable)roomViewController:(BJLScRoomViewController *)roomViewController
                   didExitWithError:(nullable BJLError *)error;

@end

@protocol BJLScRoomViewControllerDelegate <NSObject>

@optional

/** 进入教室 - 成功/失败 */
- (void)roomViewControllerEnterRoomSuccess:(BJLScRoomViewController *)roomViewController;
- (void)roomViewController:(BJLScRoomViewController *)roomViewController
 enterRoomFailureWithError:(BJLError *)error;

/**
 退出教室 - 正常/异常
 正常退出 `error` 为 `nil`，否则为异常退出
 参考 `BJLErrorCode` */
- (void)roomViewController:(BJLScRoomViewController *)roomViewController
         willExitWithError:(nullable BJLError *)error;
- (void)roomViewController:(BJLScRoomViewController *)roomViewController
          didExitWithError:(nullable BJLError *)error;

/**
 点击教室右上方分享按钮回调
 */
- (nullable UIViewController *)roomViewControllerToShare:(BJLScRoomViewController *)roomViewController;

@end

NS_ASSUME_NONNULL_END

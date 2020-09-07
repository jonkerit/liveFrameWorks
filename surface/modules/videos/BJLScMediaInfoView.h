//
//  BJLScMediaInfoView.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/19.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScMediaInfoView : UIView

@property (nonatomic, readonly) BJLUser *user;
@property (nonatomic, readonly, nullable) BJLMediaUser *mediaUser;
@property (nonatomic) BOOL isFullScreen;

/**
 根据 user 初始化
 #discussion 初始化的 user 可以是 BJLUser，用于采集的视频窗口，如果用采集以外的用户初始化的 BJLMediaUser，认为是一个音视频未打开的主摄像头用户；
 #discussion 也可以是 BJLMediaUser，用于播放的视频窗口
 #discussion 一般情况下 音视频未打开的主摄像头用户是不会显示窗口状态的
 #param room BJLRoom
 #param user user
 #return self
 */
- (instancetype)initWithRoom:(BJLRoom *)room user:(__kindof BJLUser *)user;

- (void)updateCloseVideoPlaceholderHidden:(BOOL)hidden;

- (void)updateWithLikeCount:(NSInteger)count hidden:(BOOL)hidden;

- (void)destroy;
// 显示或者隐藏省流量模式提示
- (void)hiddenWarmLabel:(BOOL)hidden;
@end

NS_ASSUME_NONNULL_END

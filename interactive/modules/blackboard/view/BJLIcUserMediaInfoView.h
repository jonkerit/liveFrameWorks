//
//  BJLIcUserMediaInfoView.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/10/8.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLUser+BJLInteractiveClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserMediaInfoView : UIView

@property (nonatomic, readonly) BJLMediaUser *user;
@property (nonatomic, readonly) NSString *mediaID;
@property (nonatomic, readonly) UIButton *likeButton;
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);
@property (nonatomic, nullable) void (^updateVideoCallback)(BJLMediaUser *user, BOOL on);
@property (nonatomic, nullable) BOOL (^blockUserCallback)(BJLUser *user);

/**
 初始化视图

 #param user 用户
 #param room 房间实例
 #return 视图实例
 */
- (instancetype)initWithUser:(BJLMediaUser *)user room:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

/**
 设置父控制器

 @param parentViewController parentViewController
 */
- (void)updateParentViewController:(UIViewController *)parentViewController;

/**
 更新视图

 @param user user
 @param combineVideoView 是否需要重置 video view
 */
- (void)updateContentWithUser:(BJLMediaUser *)user
             combineVideoView:(BOOL)combineVideoView;

/**
 单击手势处理
 当手势被拦截的时候，可以调用此方法来处理单击事件
 @param point point
 */
- (void)handleSingleTapGesture:(CGPoint)point;

/**
 更新点赞数

 @param count 点赞数
 @param hidden 是否隐藏
 */
- (void)updateWithLikeCount:(NSInteger)count hidden:(BOOL)hidden;

/**
 更新动态课件授权标志

 @param authorized 是否被授权
 */
- (void)updateWebPPTAuthorized:(BOOL)authorized;

/**
 更新画笔授权标志

 @param drawingGranted 是否被授权
 */
- (void)updateDrawingGranted:(BOOL)drawingGranted;

/**
 更新举手视图

 @param hidden 是否隐藏举手视图
 */
- (void)updateSpeakRequestViewHidden:(BOOL)hidden;

/**
 重新获取视频视图
*/
- (void)getBackVideoView;

/**
 父视图变化时，调用此方法更新布局
 */
- (void)updateVideoViewConstranints;

/**
 更新不播放视频时的占位图布局

 @param layout BJLRoomLayout
 */
- (void)updatePlaceholderImageViewConstranintsForRoomLayout:(BJLRoomLayout)layout;

/**
  网络状况变化时, 更新弱网提示
 */
- (void)updateNetWorkStatus:(BJLNetworkStatus)status;

/**
 更新音视频，名字，网络状态的

 @param referenceView 参考视图，如果这些信息不跟随 self，需要提供 referenceView，目前仅用于 1v1 的设计
 */
- (void)updateInfoGroupViewWithReferenceView:(UIView *)referenceView;

@end

NS_ASSUME_NONNULL_END

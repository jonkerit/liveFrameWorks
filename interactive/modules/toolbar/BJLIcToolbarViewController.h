//
//  BJLIcToolbarViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcUserMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolbarViewController : UIViewController

/**
 userVideoDownside 模板，弹出老师视频，当前不允许弹出时，返回 NO
 */
@property (nonatomic, nullable) BOOL (^videoWindowDisplayCallback)(BJLUser *user, BJLIcUserMediaInfoView  * _Nullable view);
/**
 userVideoDownside 模板，收回老师视频，仅老师有权限
 */
@property (nonatomic, nullable) void(^sendBackVideoViewCallback)(BJLUser *user);
/**
 老师视频视图
 */
@property (nonatomic, readonly, nullable) BJLIcUserMediaInfoView *teacherMediaInfoView;
/**
  UserVideoUpside iphone 模板，处理超出范围的按钮，userVideoDownside 模板，处理老师视频窗口位置
 */
@property (nonatomic, nullable) UIView *(^requestReferenceViewCallback)(void);

@property (nonatomic, readonly) UIButton
*exitButton,                    // 退出教室
*menuButton,                    // 菜单
*speakerButton,                 // 扬声器
*microphoneButton,              // 麦克风
*cameraButton,                  // 摄像头
*gallerylayoutButton,           // 画廊布局
*blackboardLayoutButton,        // 板书布局
*cloudRecordingButton,          // 云端录制
*pauseCloudRecordingButton,     // 暂停录制
*stopCloudRecordingButton,      // 停止录制
*unmuteAllMicrophoneButton,     // 一键开麦
*muteAllMicrophoneButton,       // 一键关麦
*speakRequestButton,            // 申请发言
*forbidSpeakRequestButton,      // 禁止发言
*userListButton,                // 用户列表
*chatListButton,                // 聊天列表
*coursewareButton,              // 课件
*teachingAidButton;             // 教具
@property (nonatomic, readonly, nullable) UILabel *chatListRedDot, *userListRedDot, *menuRedDot;

#if DEBUG
@property (nonatomic, readonly) UIButton
*widgetButton,
*settingsButton,
*fullscreenButton,
*popoversButton;
#endif

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

/**
 loading 完成，尝试弹出云端录制提示
 */
- (void)tryToShowCloudRecordingTipView;

/**
 userVideoDownside 模板重新布局toolbar，仅学生会改变

 @param drawingGranted 画笔授权状态
 */
- (void)remakeToolbarConstraintsForStudentWithDrawingGranted:(BOOL)drawingGranted;

/**
 userVideoDownside 模板，更新老师视图位置

 @param leaveSeat 是否离开位置 YES --> 显示在黑板区域 NO --> 显示在当前控制器区域
 @return BJLIcUserMediaInfoView
 */
- (nullable BJLIcUserMediaInfoView *)updateTeacherMediaInfoViewLeaveSeat:(BOOL)leaveSeat;

@end

NS_ASSUME_NONNULL_END

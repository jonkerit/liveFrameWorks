//
//  BJLIcToolbarViewController+private.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController.h"
#import "BJLIcAppearance.h"
#import "BJLAnnularProgressView.h"
#import "BJLIcUserSeatCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolbarViewController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BOOL shouldShowCloudRecordingTipView, isCloudRecordingInitialized;
@property (nonatomic) BOOL isPhoneToolboxInitialized;

@property (nonatomic) UIView *backgroundView, *mediaBackgroundView, *menuBackgroundView;
@property (nonatomic, nullable) UIView *containerView;
@property (nonatomic) UIView *teacherMediaInfoContainerView;
@property (nonatomic) UILabel *teacherNamelabel;
@property (nonatomic) UIImageView *teacherPlaceholderImageView;
@property (nonatomic) BOOL teacherLeaveSeat;
@property (nonatomic, readwrite, nullable) BJLIcUserMediaInfoView *teacherMediaInfoView;
@property (nonatomic) UIPanGestureRecognizer *touchMoveGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
//  !!!: 控制器内【不】能通过 hidden 属性控制任何按钮的显示隐藏
@property (nonatomic, readwrite) UIButton
*exitButton, // 不用于 padUserVideoUpside
*menuButton, // 仅用于 padUserVideoUpside iphone
*speakerButton,
*microphoneButton,
*cameraButton,
*layoutButton, // version 2
*gallerylayoutButton,
*blackboardLayoutButton,
*cloudRecordingButton,
*pauseCloudRecordingButton,
*stopCloudRecordingButton,
*unmuteAllMicrophoneButton,
*muteAllMicrophoneButton,
*forbidSpeakRequestButton,
*speakRequestButton,
*userListButton,
*chatListButton,
*coursewareButton, // 仅用于 1v1 iphone
*teachingAidButton; // 仅用于 1v1 iphone
@property (nonatomic) BJLAnnularProgressView *speakRequestProgressView;
@property (nonatomic, readwrite, nullable) UILabel *chatListRedDot, *userListRedDot, *menuRedDot;
@property (nonatomic, nullable) UIViewController *layoutViewController, *cloudRecordingViewController, *cloudRecordingTipViewController;

@end

NS_ASSUME_NONNULL_END

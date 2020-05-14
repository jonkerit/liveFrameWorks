//
//  BJLIcToolbarViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcToolbarViewController.h"
#import "BJLIcToolbarViewController+private.h"
#import "BJLIcToolbarViewController+padUserVideoUpside.h"
#import "BJLIcToolbarViewController+padUserVideoDownside.h"
#import "BJLIcToolbarViewController+phoneUserVideoUpside.h"
#import "BJLIcToolbarViewController+phone1to1.h"
#import "BJLIcToolbarViewController+pad1to1.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcToolbarViewController 

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    bjl_weakify(self);
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        BOOL needResponse = NO;
        if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
            needResponse = ([self.teacherMediaInfoContainerView pointInside:[[event.allTouches anyObject] locationInView:self.view] withEvent:event]
                            || [hitView isKindOfClass:[BJLIcUserMediaInfoView class]]);
        }
        if ([hitView isKindOfClass:[UIButton class]] || needResponse) {
            return hitView;
        }
        return nil;
    }];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    [self makeSubviews];
#if DEBUG
    [self makeDebugSubviewsAndConstraints];
#endif
    [self makeObserving];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    // 布局和父视图有关，因此不能在 viewdidload 中布局，需要在此方法中布局，而此方法会调用多次，需要使用 remake 来正确布局
    [super didMoveToParentViewController:parent];
    if (parent) {
        if (self.room.loginUser.isStudent) {
            [self remakeContainerViewForStudent];
        }
        else {
            [self remakeContainerViewForTeacherOrAssistant:self.room.loginUser.isAssistant];
        }
    }
}

- (void)makeSubviews {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self makePhone1to1Subviews];
        }
        else {
            [self makePad1to1Subviews];
        }
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self makePadUserVideoDownsideSubviews];
        [self makePadUserVideoDownsideObserving];
        [self makeTouchMoveGesture];
    }
    else {
        if (iPhone) {
            [self makePhoneUserVideoUpsideSubviews];
        }
        else {
            [self makePadUserVideoUpsideSubviews];
        }
    }
    
    self.exitButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_statusbar_exit"]
                              selectedImage:nil];
    self.speakerButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_speaker_normal"]
                                 selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speaker_selected"]];
    self.microphoneButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_microphone_normal"]
                                    selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_microphone_selected"]];
    self.cameraButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_camera_normal"]
                                selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_camera_selected"]];
    
    self.blackboardLayoutButton = [self makeButtonWithTitle:@"板书布局"
                                              selectedTitle:nil
                                                      image:[UIImage bjlic_imageNamed:@"bjl_toolbar_boardlayout_normal"]
                                              selectedImage:nil
                                         accessibilityLabel:BJLKeypath(self, blackboardLayoutButton)];
    self.gallerylayoutButton = [self makeButtonWithTitle:@"画廊布局"
                                           selectedTitle:nil
                                                   image:[UIImage bjlic_imageNamed:@"bjl_toolbar_gallerylayout_normal"]
                                           selectedImage:nil
                                      accessibilityLabel:BJLKeypath(self, gallerylayoutButton)];
    self.cloudRecordingButton = [self makeButtonWithTitle:@"录制课程"
                                            selectedTitle:@"录制中..."
                                                    image:[UIImage bjlic_imageNamed:@"bjl_toolbar_cloudrecording_normal"]
                                            selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_cloudrecording_selected"]
                                       accessibilityLabel:BJLKeypath(self, cloudRecordingButton)];
    [self.cloudRecordingButton addTarget:self action:@selector(showCloudRecordingView) forControlEvents:UIControlEventTouchUpInside];
    self.pauseCloudRecordingButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_cloudrecording_pause"]
                                             selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_cloudrecording_resume"]];
    self.stopCloudRecordingButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_cloudrecording_stop"]
                                            selectedImage:nil];
    self.unmuteAllMicrophoneButton = [self makeButtonWithTitle:@"全体开麦"
                                                 selectedTitle:nil
                                                         image:[UIImage bjlic_imageNamed:@"bjl_toolbar_unmuteallmicrophone"]
                                                 selectedImage:nil
                                            accessibilityLabel:BJLKeypath(self, unmuteAllMicrophoneButton)];
    self.muteAllMicrophoneButton = [self makeButtonWithTitle:@"全体关麦"
                                               selectedTitle:nil
                                                       image:[UIImage bjlic_imageNamed:@"bjl_toolbar_muteallmicrophone"]
                                               selectedImage:nil
                                          accessibilityLabel:BJLKeypath(self, muteAllMicrophoneButton)];
    self.speakRequestButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_normal"]
                                      selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_selected"]];
    self.speakRequestProgressView = ({
        BJLAnnularProgressView *progressView = [BJLAnnularProgressView new];
        progressView.size = iPhone ? [BJLIcAppearance sharedAppearance].toolbarLargeSpace - 6.0 : [BJLIcAppearance sharedAppearance].toolbarButtonWidth - 6.0; // inset = 4, width = 2
        progressView.annularWidth = 2.0;
        progressView.color = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        progressView.userInteractionEnabled = NO;
        progressView;
    });
    self.forbidSpeakRequestButton = [self makeButtonWithTitle:@"禁止举手"
                                                selectedTitle:@"允许举手"
                                                        image:[UIImage bjlic_imageNamed:@"bjl_toolbar_forbidspeakrequest_normal"]
                                                selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_forbidspeakrequest_selected"]
                                           accessibilityLabel:BJLKeypath(self, forbidSpeakRequestButton)];
    self.userListButton = [self makeButtonWithTitle:@"用户列表"
                                      selectedTitle:nil
                                              image:[UIImage bjlic_imageNamed:@"bjl_toolbar_userlist_normal"]
                                      selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_userlist_selected"]
                                 accessibilityLabel:BJLKeypath(self, userListButton)];
    self.chatListButton = [self makeButtonWithTitle:@"聊天"
                                      selectedTitle:nil
                                              image:[UIImage bjlic_imageNamed:@"bjl_toolbar_chat_normal"]
                                      selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_chat_selected"]
                                 accessibilityLabel:BJLKeypath(self, chatListButton)];
    self.coursewareButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbox_courseware_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_courseware_selected"]];
    self.teachingAidButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_toolbox_teachingaid_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_teachingaid_selected"]];
    self.userListRedDot = [self makeRedDot];
    self.chatListRedDot = [self makeRedDot];
    self.menuRedDot = [self makeRedDot];
}

#pragma mark - teacher style

- (void)remakeContainerViewForTeacherOrAssistant:(BOOL)isAssistant {
    [self clearToolbar];

    // 媒体控制按钮
    NSArray *mediaButtons =  @[/*self.speakerButton,*/
                                   self.microphoneButton,
                                   self.cameraButton];
    // 一般操作按钮
    NSMutableArray<UIButton *> *optionButtons = [@[self.blackboardLayoutButton,
                                                 self.cloudRecordingButton,
                                                 self.unmuteAllMicrophoneButton,
                                                 self.muteAllMicrophoneButton,
                                                 self.forbidSpeakRequestButton,
                                                 self.userListButton,
                                                 self.chatListButton] mutableCopy];

    // 助教不显示布局切换按钮
    if (isAssistant) {
        [optionButtons removeObject:self.blackboardLayoutButton];
    }
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        // 1v1 无布局切换，静音，禁止举手等控制
        if (iPhone) {
            NSArray *options = isAssistant ? @[self.coursewareButton, self.cloudRecordingButton, self.userListButton, self.chatListButton] : @[self.coursewareButton, self.teachingAidButton, self.cloudRecordingButton, self.userListButton, self.chatListButton];
            [self remakePhone1to1ContainerViewForTeacherOrAssistantWithMediaButtons:mediaButtons optionButtons:options];
        }
        else {
            NSArray *options = @[self.cloudRecordingButton, self.userListButton, self.chatListButton];
            [self remakePad1to1ContainerViewForTeacherOrAssistantWithMediaButtons:mediaButtons optionButtons:options];
        }
    }
    else if (BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
        else {
            [self remakePadUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
        // version 1
        if (!isAssistant) {
            // 老师显示布局切换按钮
            [self.containerView addSubview:self.gallerylayoutButton];
            self.gallerylayoutButton.hidden = YES;
            [self.gallerylayoutButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.blackboardLayoutButton);
            }];
        }
    }
    else {
        // PadUserVideoDownside 无布局切换
        [optionButtons removeObject:self.blackboardLayoutButton];
        [self remakePadUserVideoDownsideContainerViewForTeacherOrAssistantWithmediaButtons:mediaButtons optionButtons:optionButtons];
    }
    
    // 聊天消息以及用户列表的提示红点
    [self.containerView addSubview:self.userListRedDot];
    [self.userListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.userListButton).offset(10.0);
        make.left.equalTo(self.userListButton.bjl_centerX).offset(10.0);
        make.height.width.equalTo(@12.0);
    }];
    
    [self.containerView addSubview:self.chatListRedDot];
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton).offset(10.0);
        make.left.equalTo(self.chatListButton.bjl_centerX).offset(10.0);
        make.height.width.equalTo(@8.0);
    }];
}

#pragma mark - student style

- (void)remakeContainerViewForStudent {
    [self clearToolbar];
    // 学生只有摄像头按钮，举手和聊天单独布局
    NSArray *mediaButtons = @[/*self.speakerButton,,*/
                                   self.microphoneButton,
                                  self.cameraButton];
    NSArray *optionButtons =  @[self.chatListButton];
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakePhone1to1ContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
        else {
            [self remakePad1to1ContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self remakePadUserVideoDownsideContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
    }
    else {
        if (iPhone) {
            [self remakePhoneUserVideoUpsideContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
        else {
            [self remakePadUserVideoUpsideContainerViewForStudentWithMediaButtons:mediaButtons optionButtons:optionButtons];
        }
    }
    // 聊天按钮红点
    if (iPhone && BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType) {
        [self.containerView addSubview:self.chatListRedDot];
    }
    else {
        [self.view addSubview:self.chatListRedDot];
    }
    [self.chatListRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.chatListButton).offset(10.0);
        make.left.equalTo(self.chatListButton.bjl_centerX).offset(10.0);
        make.height.width.equalTo(@8.0);
    }];
}

- (void)remakeToolbarConstraintsForStudentWithDrawingGranted:(BOOL)drawingGranted {
    if (BJLIcTemplateType_userVideoDownside != self.room.roomInfo.interactiveClassTemplateType) {
        return;
    }
    [self clearToolbar];

    // 学生只有摄像头按钮，举手和聊天单独布局
    NSArray *mediaButtons = @[/*self.speakerButton,*/
                               self.microphoneButton,
                              self.cameraButton];
    NSArray *optionButtons =  @[self.chatListButton];
    [self remakePadUserVideoDownsideToolbarConstraintsWithDrawingGranted:drawingGranted mediaButtons:mediaButtons optionButtons:optionButtons];
}

- (nullable BJLIcUserMediaInfoView *)updateTeacherMediaInfoViewLeaveSeat:(BOOL)leaveSeat {
    if (BJLIcTemplateType_userVideoDownside != self.room.roomInfo.interactiveClassTemplateType) {
        return nil;
    }
    return [self updatePadUserVideoDownsideTeacherMediaInfoViewLeaveSeat:leaveSeat];
}

#pragma mark - clear

- (void)clearToolbar {
    NSArray *toolbarArray = @[
                              self.mediaBackgroundView ?: [NSNull null],
                              self.menuBackgroundView ?: [NSNull null],
                              self.containerView ?: [NSNull null],
                              self.teacherMediaInfoContainerView ?: [NSNull null],
                              self.backgroundView ?: [NSNull null],
                              self.exitButton ?: [NSNull null],
                              self.menuButton ?: [NSNull null],
                              /*self.speakerButton,*/
                              self.microphoneButton ?: [NSNull null],
                              self.cameraButton ?: [NSNull null],
                              self.blackboardLayoutButton ?: [NSNull null],
                              self.gallerylayoutButton ?: [NSNull null],
                              self.cloudRecordingButton ?: [NSNull null],
                              self.unmuteAllMicrophoneButton ?: [NSNull null],
                              self.muteAllMicrophoneButton ?: [NSNull null],
                              self.forbidSpeakRequestButton ?: [NSNull null],
                              self.speakRequestButton ?: [NSNull null],
                              self.speakRequestProgressView ?: [NSNull null],
                              self.userListButton ?: [NSNull null],
                              self.chatListButton ?: [NSNull null],
                              self.coursewareButton ?: [NSNull null],
                              self.teachingAidButton ?: [NSNull null],
                              self.userListRedDot ?: [NSNull null],
                              self.chatListRedDot ?: [NSNull null],
                              self.menuRedDot ?: [NSNull null]];
    for (UIView *view in toolbarArray) {
        if ([view respondsToSelector:@selector(removeFromSuperview)]) {
            [view removeFromSuperview];
        }
    }
}

#pragma mark - observers

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, featureConfig)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
                 self.backgroundView.hidden = self.room.featureConfig.backgroundURLString.length;
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.microphoneButton.selected = now.boolValue;
             self.speakRequestButton.enabled = !now.boolValue;
             // 关闭采集同时关闭录制
             if (self.room.loginUserIsPresenter
                 && !self.room.recordingVM.recordingAudio
                 && !self.room.recordingVM.recordingVideo
                 && self.room.serverRecordingVM.serverRecording) {
                 [self.stopCloudRecordingButton sendActionsForControlEvents:UIControlEventTouchUpInside];
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingVideo)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.cameraButton.selected = now.boolValue;
             // 关闭采集同时关闭录制
             if (self.room.loginUserIsPresenter
                 && !self.room.recordingVM.recordingAudio
                 && !self.room.recordingVM.recordingVideo
                 && self.room.serverRecordingVM.serverRecording) {
                 [self.stopCloudRecordingButton sendActionsForControlEvents:UIControlEventTouchUpInside];
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, forbidSpeakingRequest)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.forbidSpeakRequestButton.selected = now.boolValue;
             return YES;
         }];

    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestTimeRemaining)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return timeRemaining.doubleValue != old.doubleValue;
           }
         observer:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (timeRemaining.doubleValue <= 0.0) {
                 self.speakRequestProgressView.progress = 0.0;
                 self.speakRequestButton.selected = NO;
             }
             else {
                 CGFloat progress = timeRemaining.doubleValue / self.room.speakingRequestVM.speakingRequestTimeoutInterval; // 1.0 ~ 0.0
                 self.speakRequestProgressView.progress = progress;
             }
             return YES;
         }];
    
    if (self.room.serverRecordingVM && self.room.loginUser.isTeacherOrAssistant) {
        [self bjl_kvo:BJLMakeProperty(self.room.serverRecordingVM, serverRecording)
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (!self.pauseCloudRecordingButton.selected) {
                     self.cloudRecordingButton.selected = now.boolValue;
                 }
                 if (now.boolValue && !self.isCloudRecordingInitialized) {
                     self.isCloudRecordingInitialized = YES;
                     [self tryToShowCloudRecordingTipView];
                 }
                 return YES;
             }];
    }
}

#pragma mark - actions

- (void)tryToShowCloudRecordingTipView {
    if (!self.shouldShowCloudRecordingTipView || !self.isCloudRecordingInitialized) {
        self.shouldShowCloudRecordingTipView = YES;
        return;
    }
    if (!self.room.serverRecordingVM.serverRecording) {
        return;
    }
    self.shouldShowCloudRecordingTipView = NO;
    self.cloudRecordingTipViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = CGSizeMake(360.0, 117.0);
        viewController.popoverPresentationController.backgroundColor = [UIColor blackColor];
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self.cloudRecordingButton;
        viewController.popoverPresentationController.sourceRect = self.cloudRecordingButton.bounds;
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    UILabel *tipLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor clearColor];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 14.0;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                        NSForegroundColorAttributeName : [UIColor whiteColor],
                                        NSParagraphStyleAttributeName : paragraphStyle};
        label.attributedText = [[NSAttributedString alloc] initWithString:@"云端录制已开启 \n云端录制直接在云端服务器录课，本地不保存录\n课文件，课程结束后10分钟自动生成课程回放" attributes:attributedDic];
        label;
    });
    [self.cloudRecordingTipViewController.view addSubview:tipLabel];
    [tipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.cloudRecordingTipViewController.view.bjl_safeAreaLayoutGuide ?: self.cloudRecordingTipViewController.view).insets(UIEdgeInsetsMake(10.0, 20.0, 0.0, 20.0));
    }];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:self.cloudRecordingTipViewController animated:YES completion:nil];
}

- (void)showCloudRecordingView {
    if (!self.cloudRecordingButton.isSelected) {
        return;
    }
    self.cloudRecordingViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = CGSizeMake(104.0, 44.0);
        viewController.popoverPresentationController.backgroundColor = [UIColor blackColor];
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self.cloudRecordingButton;
        viewController.popoverPresentationController.sourceRect = self.cloudRecordingButton.bounds;
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    [self.cloudRecordingViewController.view addSubview:self.pauseCloudRecordingButton];
    [self.pauseCloudRecordingButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@26.0);
        make.centerY.equalTo(self.cloudRecordingViewController.view.bjl_safeAreaLayoutGuide ?: self.cloudRecordingViewController.view);
        make.right.equalTo(self.cloudRecordingViewController.view.bjl_centerX).offset(-10.0);
    }];
    [self.cloudRecordingViewController.view addSubview:self.stopCloudRecordingButton];
    [self.stopCloudRecordingButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@26.0);
        make.centerY.equalTo(self.cloudRecordingViewController.view.bjl_safeAreaLayoutGuide ?: self.cloudRecordingViewController.view);
        make.left.equalTo(self.cloudRecordingViewController.view.bjl_centerX).offset(10.0);
    }];
    [self.stopCloudRecordingButton addTarget:self action:@selector(hideCloudRecordingViewController) forControlEvents:UIControlEventTouchUpInside];
    self.pauseCloudRecordingButton.selected = !self.room.serverRecordingVM.serverRecording;
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:self.cloudRecordingViewController animated:YES completion:nil];
}

- (void)hideCloudRecordingViewController {
    [self.cloudRecordingViewController bjl_dismissAnimated:YES completion:nil];
}

#if DEBUG
- (void)makeDebugSubviewsAndConstraints {
    self->_widgetButton = [self makeButtonWithTitle:@"hide widget"
                                      selectedTitle:@"show widget"
                                              image:nil
                                      selectedImage:nil
                                 accessibilityLabel:BJLKeypath(self, widgetButton)];
    self->_settingsButton = [self makeButtonWithTitle:@"hide settings"
                                        selectedTitle:@"show settings"
                                                image:nil
                                        selectedImage:nil
                                   accessibilityLabel:BJLKeypath(self, settingsButton)];
    self->_fullscreenButton = [self makeButtonWithTitle:@"hide fullscreen"
                                          selectedTitle:@"show fullscreen"
                                                  image:nil
                                          selectedImage:nil
                                     accessibilityLabel:BJLKeypath(self, fullscreenButton)];
    self->_popoversButton = [self makeButtonWithTitle:@"hide popovers"
                                        selectedTitle:@"show popovers"
                                                image:nil
                                        selectedImage:nil
                                   accessibilityLabel:BJLKeypath(self, popoversButton)];
//    UIButton *last = nil;
//    for (UIButton *button in @[self.widgetButton,
//                               self.settingsButton,
//                               self.fullscreenButton,
//                               self.popoversButton]) {
//        [self.view addSubview:button];
//        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
//            make.top.equalTo(last.bjl_bottom ?: self.view);
//            make.right.equalTo(self.view).inset(5.0);
//            if (last) make.width.height.equalTo(last);
//        }];
//        last = button;
//    }
//    [last bjl_makeConstraints:^(BJLConstraintMaker *make) {
//        make.bottom.equalTo(self.view);
//    }];
}

#endif

#pragma mark - wheel

- (UIButton *)makeImageButton:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage {
    UIButton *button = [BJLImageButton new];
    button.layer.masksToBounds = YES;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setImage:selectedImage forState:UIControlStateHighlighted];
    [button setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    return button;
}

- (UIButton *)makeButtonWithTitle:(nullable NSString *)title selectedTitle:(nullable NSString *)selectedTitle
                            image:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage
               accessibilityLabel:(nullable NSString *)accessibilityLabel {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    UIButton *button = [BJLVerticalButton new];
    button.layer.masksToBounds = YES;
    button.accessibilityLabel = accessibilityLabel;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    // userVideoDownside 有背景
    if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        button.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].buttonSize / 2;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = [UIColor bjl_colorWithHexString:@"#999999" alpha:0.3].CGColor;
    }
    // !!!: iphone 和 userVideoDownside 所有按钮没有标题，要注意在外部修改标题的时候判断是否是 iphone
    if (title && !iPhone && BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    if (selectedTitle && !iPhone && BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType) {
        [button setTitle:selectedTitle forState:UIControlStateSelected];
        [button setTitle:selectedTitle forState:UIControlStateHighlighted];
        [button setTitle:selectedTitle forState:UIControlStateHighlighted | UIControlStateSelected];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateSelected];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateHighlighted];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:UIControlStateHighlighted];
        [button setImage:selectedImage forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    return button;
}

- (UILabel *)makeRedDot {
    UILabel *view = [UILabel new];
    view.hidden = YES;
    view.layer.masksToBounds = YES;
    view.layer.cornerRadius = 4.0;
    view.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
    view.textColor = [UIColor whiteColor];
    view.textAlignment = NSTextAlignmentCenter;
    view.adjustsFontSizeToFitWidth = YES;
    view.font = [UIFont systemFontOfSize:8.0];
    return view;
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end

NS_ASSUME_NONNULL_END

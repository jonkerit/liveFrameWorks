//
//  BJLSettingsViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-06.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLAuthorization.h>

#import "BJLSettingsViewController.h"

#import "BJLOverlayViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLSettingsViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic, readwrite) UISwitch *micSwitch, *cameraSwitch;
@property (nonatomic) UIView *micLabel, *cameraLabel, *beautifyLabel, *backgroundAudioLabel, *pptAnimationLabel, *pptRemarkLabel, *forbidChatLabel, *forbidSpeakLabel, *forbidAudioLabel;
@property (nonatomic) UISwitch *beautifySwitch, *backgroundAudioSwitch, *pptAnimationSwitch, *pptRemarkSwitch, *forbidChatSwitch, *forbidSpeakSwitch, *forbidAudioSwitch;

@property (nonatomic) UIView *separatorLine;

@property (nonatomic) UILabel *contentModeLabel, *videoDefinitionLabel, *cameraPositionLabel, *linkTypeLabel;
@property (nonatomic) UIButton *contentModeFitButton, *contentModeFillButton;
@property (nonatomic) UIButton *videoDefinitionLowButton, *videoDefinitionHighButton, *videoDefinition720pButton, *videoDefinition1080pButton;
@property (nonatomic) UIButton *cameraPositionFrontButton, *cameraPositionRearButton;
@property (nonatomic) UIButton *upLinkTypeTCPButton, *upLinkTypeUDPButton;
@property (nonatomic) UILabel *upLinkTypeLabel, *downLinkTypeLabel;
@property (nonatomic) UIButton *downLinkTypeTCPButton, *downLinkTypeUDPButton;

@end

@implementation BJLSettingsViewController

#pragma mark - lifecycle & <BJLRoomChildViewController>

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self->_room = room;
    }
    return self;
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    
    if (!parent && !self.bjl_overlayContainerController) {
        return;
    }
    
    [self.bjl_overlayContainerController updateTitle:@"设置"];
    [self.bjl_overlayContainerController updateRightButtons:nil];
    [self.bjl_overlayContainerController updateFooterView:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.scrollView.alwaysBounceVertical = YES;
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room, state)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return (BJLRoomState)[now integerValue] == BJLRoomState_connected;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self makeSubviewsAndConstraints];
             [self makeObservingAndActions];
             return NO;
         }];
}

- (void)makeSubviewsAndConstraints {
    BJLTuple *micControls = [self makeSwitchWithLabel:@"麦克风"];
    BJLTupleUnpack(micControls) = ^(UIView *label, UISwitch *swiitch) {
        self.micLabel = label;
        self.micSwitch = swiitch;
    };
    BJLTuple *cameraControls = [self makeSwitchWithLabel:@"摄像头"];
    BJLTupleUnpack(cameraControls) = ^(UIView *label, UISwitch *swiitch) {
        self.cameraLabel = label;
        self.cameraSwitch = swiitch;
    };
    BJLTuple *beautifyControls = [self makeSwitchWithLabel:@"美颜"];
    BJLTupleUnpack(beautifyControls) = ^(UIView *label, UISwitch *swiitch) {
        self.beautifyLabel = label;
        self.beautifySwitch = swiitch;
    };
    BJLTuple *backgroundAudioControls = [self makeSwitchWithLabel:@"后台音频"];
    BJLTupleUnpack(backgroundAudioControls) = ^(UIView *label, UISwitch *swiitch) {
        self.backgroundAudioLabel = label;
        self.backgroundAudioSwitch = swiitch;
    };
    BJLTuple *pptAnimationControls = [self makeSwitchWithLabel:@"课件动效"];
    BJLTupleUnpack(pptAnimationControls) = ^(UIView *label, UISwitch *swiitch) {
        self.pptAnimationLabel = label;
        self.pptAnimationSwitch = swiitch;
    };

    NSArray *tuples = nil;
    if (self.room.loginUser.isTeacherOrAssistant
        && self.room.loginUser.noGroup) {
        BJLTuple *pptRemarkControls = [self makeSwitchWithLabel:@"课件备注"];
        BJLTupleUnpack(pptRemarkControls) = ^(UIView *label, UISwitch *swiitch) {
            self.pptRemarkLabel = label;
            self.pptRemarkSwitch = swiitch;
        };
        BJLTuple *forbidChatControls = [self makeSwitchWithLabel:@"全体禁言"];
        BJLTupleUnpack(forbidChatControls) = ^(UIView *label, UISwitch *swiitch) {
            self.forbidChatLabel = label;
            self.forbidChatSwitch = swiitch;
        };
        switch (self.room.roomInfo.roomType) {
            case BJLRoomType_1vNClass: {
                BJLTuple *forbidSpeakControls = [self makeSwitchWithLabel:@"禁止举手"];
                BJLTupleUnpack(forbidSpeakControls) = ^(UIView *label, UISwitch *swiitch) {
                    self.forbidSpeakLabel = label;
                    self.forbidSpeakSwitch = swiitch;
                };
                tuples = @[micControls, cameraControls, beautifyControls, backgroundAudioControls, pptAnimationControls, pptRemarkControls, forbidChatControls, forbidSpeakControls];
                break;
            }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            case BJLRoomType_smallClass: // NO break
#pragma clang diagnostic pop
            case BJLRoomType_interactiveClass: // NO break
            case BJLRoomType_doubleTeachersClass: {
                BJLTuple *forbidAudioControls = [self makeSwitchWithLabel:@"全体静音"];
                BJLTupleUnpack(forbidAudioControls) = ^(UIView *label, UISwitch *swiitch) {
                    self.forbidAudioLabel = label;
                    self.forbidAudioSwitch = swiitch;
                };
                tuples = @[micControls, cameraControls, beautifyControls, backgroundAudioControls, pptAnimationControls, pptRemarkControls, forbidChatControls, forbidAudioControls];
                break;
            }
            default: {
                tuples = @[micControls, cameraControls, beautifyControls, backgroundAudioControls, pptAnimationControls, pptRemarkControls, forbidChatControls];
                break;
            }
        }
    }
    else if (self.room.loginUser.isTeacherOrAssistant) {
        BJLTuple *pptRemarkControls = [self makeSwitchWithLabel:@"课件备注"];
        BJLTupleUnpack(pptRemarkControls) = ^(UIView *label, UISwitch *swiitch) {
            self.pptRemarkLabel = label;
            self.pptRemarkSwitch = swiitch;
        };
        BJLTuple *forbidChatControls = [self makeSwitchWithLabel:@"全体禁言"];
        BJLTupleUnpack(forbidChatControls) = ^(UIView *label, UISwitch *swiitch) {
            self.forbidChatLabel = label;
            self.forbidChatSwitch = swiitch;
        };
        tuples = @[micControls, cameraControls, beautifyControls, backgroundAudioControls, pptAnimationControls, pptRemarkControls, forbidChatControls];
    }
    else {
        tuples = @[micControls, cameraControls, beautifyControls, backgroundAudioControls, pptAnimationControls];
    }
    
    static const NSInteger columnsPerLine = 3;
    NSMutableArray<UIView *> *spaceViews = [NSMutableArray new], *placeholders = [NSMutableArray new];
    
    UIView *lastSpaceView = nil, *lastPlaceholder = nil;
    for (NSInteger column = 0; column < columnsPerLine; column++) {
        UIView *spaceView = [self makeInvisibleView];
        // spaceView.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.3];
        [spaceViews addObject:spaceView];
        [spaceView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(lastPlaceholder.bjl_right ?: self.scrollView);
            if (lastSpaceView) {
                make.width.equalTo(lastSpaceView);
            }
            make.top.bottom.equalTo(self.scrollView);
        }];
        
        UIView *placeholder = [self makeInvisibleView];
        // placeholder.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
        [placeholders bjl_addObject:placeholder];
        [placeholder bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(spaceView.bjl_right);
            if (lastPlaceholder) {
                make.width.equalTo(lastPlaceholder);
            }
            else {
                static const CGFloat switchSize = 50.0;
                make.width.equalTo(@(switchSize));
            }
            make.top.bottom.equalTo(self.scrollView);
        }];
        
        lastSpaceView = spaceView;
        lastPlaceholder = placeholder;
    }
    
    UIView *spaceView = [self makeInvisibleView];
    // spaceView.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.3];
    [spaceViews addObject:spaceView];
    [spaceView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(lastPlaceholder.bjl_right ?: self.scrollView);
        if (lastSpaceView) {
            make.width.equalTo(lastSpaceView);
        }
        make.right.equalTo(@[self.scrollView, self.view.bjl_safeAreaLayoutGuide ?: self.view]); // right
        make.top.bottom.equalTo(self.scrollView);
    }];
    
    lastSpaceView = nil;
    lastPlaceholder = nil;
    
    __block UIView *lastLabel = nil;
    __block UISwitch *lastSwitch = nil;
    for (NSInteger index = 0; index < tuples.count; index++) {
        NSInteger column = index % columnsPerLine;
        BJLTuple *tuple = [tuples objectAtIndex:index];
        UIView *placeholder = [placeholders objectAtIndex:column];
        
        BJLTupleUnpack(tuple) = ^(UIView *label, UISwitch *swiitch) {
            [label bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.centerX.equalTo(placeholder);
                if (column == 0) {
                    make.top.equalTo(lastSwitch.bjl_bottom ?: self.scrollView).with.offset(BJLViewSpaceL);
                }
                else {
                    make.top.equalTo(lastLabel.bjl_top);
                }
            }];
            [swiitch bjl_makeConstraints:^(BJLConstraintMaker *make) {
                if (index == 0) {
                    make.width.equalTo(placeholder); // fixed width
                }
                make.centerX.equalTo(placeholder);
                make.top.equalTo(label.bjl_bottom).with.offset(BJLViewSpaceM);
            }];
            
            lastLabel = label;
            lastSwitch = swiitch;
        };
    }
    
    self.separatorLine = ({
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor bjl_grayLineColor];
        [self.scrollView addSubview:line];
        line;
    });
    [self.separatorLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.scrollView).with.offset(BJLViewSpaceL);
        make.right.equalTo(self.scrollView);
        make.top.equalTo(lastSwitch.bjl_bottom).with.offset(BJLViewSpaceL);
        make.height.equalTo(@(BJLOnePixel));
    }];
    
    self.contentModeLabel = [self makeLabelWithText:@"课件展示："];
    self.contentModeFitButton = [self makeSelectButtonWithTitle:@"全屏"];
    self.contentModeFillButton = [self makeSelectButtonWithTitle:@"铺满"];
    
    self.videoDefinitionLabel = [self makeLabelWithText:@"画质设置："];
    self.videoDefinitionLowButton = [self makeVideoDefinitionButtonWithTitle:@"标清" definition:BJLVideoDefinition_std];
    self.videoDefinitionHighButton = [self makeVideoDefinitionButtonWithTitle:@"高清" definition:BJLVideoDefinition_high];
    self.videoDefinition720pButton = [self makeVideoDefinitionButtonWithTitle:@"720p" definition:BJLVideoDefinition_720p];
    self.videoDefinition1080pButton = [self makeVideoDefinitionButtonWithTitle:@"1080p" definition:BJLVideoDefinition_1080p];
    
    self.cameraPositionLabel = [self makeLabelWithText:@"摄像头切换："];
    self.cameraPositionFrontButton = [self makeSelectButtonWithTitle:@"前"];
    self.cameraPositionRearButton = [self makeSelectButtonWithTitle:@"后"];
    
    self.linkTypeLabel = [self makeLabelWithText:@"线路选择："];
    self.upLinkTypeLabel = [self makeLabelWithText:@"上行线路："];
    self.downLinkTypeLabel = [self makeLabelWithText:@"下行线路："];
    self.upLinkTypeTCPButton = [self makeSelectButtonWithTitle:@"TCP"];
    self.upLinkTypeUDPButton = [self makeSelectButtonWithTitle:@"UDP"];
    self.downLinkTypeTCPButton = [self makeSelectButtonWithTitle:@"TCP"];
    self.downLinkTypeUDPButton = [self makeSelectButtonWithTitle:@"UDP"];
    
    [self makeConstraintsForSubviewsAfterSeparatorLine];
}

- (UIView *)makeInvisibleView {
    UIView *view = [UIView new];
    view.hidden = NO;
    [self.scrollView addSubview:view];
    [self.scrollView sendSubviewToBack:view];
    return view;
}

// - (BJLTuple<BJLTupleGeneric(UILabel *, UISwitch *)> *)makeLabelButtonAndSwitchWithTitle:(NSString *)title
- (BJLTupleType(UIView *, UISwitch *))makeSwitchWithLabel:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    label.textColor = [UIColor bjl_darkGrayTextColor];
    label.font = [UIFont systemFontOfSize:15.0];
    [self.scrollView addSubview:label];
    
    UISwitch *swiitch = [UISwitch new];
    swiitch.onTintColor = [UIColor bjl_blueBrandColor];
    swiitch.tintColor = [UIColor bjl_grayBorderColor];
    swiitch.backgroundColor = [UIColor bjl_grayBorderColor];
    swiitch.layer.cornerRadius = CGRectGetHeight(swiitch.frame) / 2;
    swiitch.layer.masksToBounds = YES;
    [self.scrollView addSubview:swiitch];
    
    return BJLTuplePack((UIView *, UISwitch *), label, swiitch);
}

- (UILabel *)makeLabelWithText:(NSString *)text {
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = [UIColor bjl_darkGrayTextColor];
    label.text = text;
    [self.scrollView addSubview:label];
    return label;
}

- (UIButton *)makeSelectButtonWithTitle:(NSString *)title {
    BJLButton *button = [BJLButton new];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor bjl_darkGrayTextColor] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13.0];
    
    UIColor *selectedColor = [UIColor whiteColor];
    [button setTitleColor:selectedColor forState:UIControlStateSelected];
    [button setTitleColor:selectedColor forState:UIControlStateSelected | UIControlStateHighlighted];
    [button setTitleColor:selectedColor forState:UIControlStateSelected | UIControlStateDisabled];
    
    UIImage *selectedImage = [UIImage bjl_imageWithColor:[UIColor bjl_blueBrandColor]];
    [button setBackgroundImage:selectedImage forState:UIControlStateSelected];
    [button setBackgroundImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    [button setBackgroundImage:selectedImage forState:UIControlStateSelected | UIControlStateDisabled];
    
    button.layer.borderColor = [UIColor bjl_grayBorderColor].CGColor;
    button.layer.cornerRadius = BJLButtonSizeS / 2;
    button.layer.masksToBounds = YES;
    bjl_weakify(button);
    [button bjl_kvo:BJLMakeProperty(button, selected)
           observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               bjl_strongify(button);
               button.layer.borderWidth = button.selected ? 0.0 : BJLOnePixel;
               return YES;
           }];
    [button bjl_kvo:BJLMakeProperty(button, enabled)
           observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               bjl_strongify(button);
               button.alpha = button.enabled ? 1.0 : 0.5;
               return YES;
           }];
    
    button.intrinsicContentSize = CGSizeMake(64.0, BJLButtonSizeS);
    
    [self.scrollView addSubview:button];
    return button;
}

- (UIButton *)makeVideoDefinitionButtonWithTitle:(NSString *)title definition:(BJLVideoDefinition)definition {
    UIButton *button = [self makeSelectButtonWithTitle:title];
    bjl_weakify(self);
    [button bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [self.videoDefinitionLowButton bjl_disableForSeconds:BJLRobotDelayM];
        [self.videoDefinitionHighButton bjl_disableForSeconds:BJLRobotDelayM];
        [self.videoDefinition720pButton bjl_disableForSeconds:BJLRobotDelayM];
        [self.videoDefinition1080pButton bjl_disableForSeconds:BJLRobotDelayM];
        if (!sender.selected) {
            BJLError *error = [self.room.recordingVM updateVideoDefinition:definition];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }
    }];
    return button;
}

- (void)makeConstraintsForSubviewsAfterSeparatorLine {
    // 课件显示
    [self.contentModeLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.micSwitch);
        make.centerY.equalTo(self.contentModeFitButton);
    }];
    [self.contentModeFitButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.cameraSwitch);
        make.top.equalTo(self.separatorLine).with.offset(BJLViewSpaceL);
    }];
    [self.contentModeFillButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.beautifySwitch);
        make.centerY.equalTo(self.contentModeFitButton);
    }];
    
    // 清晰度
    [self.videoDefinitionLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.contentModeLabel);
        make.centerY.equalTo(self.videoDefinitionLowButton);
    }];
    [self.videoDefinitionLowButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.contentModeFitButton);
        make.top.equalTo(self.contentModeFitButton.bjl_bottom).with.offset(BJLViewSpaceL);
    }];
    [self.videoDefinitionHighButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.contentModeFillButton);
        make.centerY.equalTo(self.videoDefinitionLowButton);
    }];
    
    [self.videoDefinition720pButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.videoDefinitionLowButton);
        make.top.equalTo(self.videoDefinitionLowButton.bjl_bottom).with.offset(BJLViewSpaceL);
    }];
    
    // 暂不放出 1080p
//    [self.videoDefinition1080pButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//        make.right.equalTo(self.videoDefinitionHighButton);
//        make.centerY.equalTo(self.videoDefinition720pButton);
//    }];
    
    // 摄像头
    [self.cameraPositionLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.contentModeLabel);
        make.centerY.equalTo(self.cameraPositionFrontButton);
    }];
    [self.cameraPositionFrontButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.contentModeFitButton);
        make.top.equalTo(self.videoDefinition720pButton.bjl_bottom).with.offset(BJLViewSpaceL);
    }];
    [self.cameraPositionRearButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.contentModeFillButton);
        make.centerY.equalTo(self.cameraPositionFrontButton);
    }];
    
    // 线路切换
    [self.upLinkTypeLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.contentModeLabel);
        make.centerY.equalTo(self.upLinkTypeTCPButton);
    }];
    [self.downLinkTypeLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.contentModeLabel);
        make.centerY.equalTo(self.downLinkTypeTCPButton);
    }];
    [self.upLinkTypeTCPButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.contentModeFitButton);
        make.top.equalTo(self.cameraPositionFrontButton.bjl_bottom).with.offset(BJLViewSpaceL);
    }];
    [self.upLinkTypeUDPButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.contentModeFillButton);
        make.centerY.equalTo(self.upLinkTypeTCPButton);
    }];
    [self.downLinkTypeTCPButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.contentModeFitButton);
        make.top.equalTo(self.upLinkTypeTCPButton.bjl_bottom).with.offset(BJLViewSpaceL);
    }];
    [self.downLinkTypeUDPButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.contentModeFillButton);
        make.centerY.equalTo(self.downLinkTypeTCPButton);
    }];
    
    [self.scrollView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(self.downLinkTypeTCPButton).with.offset(BJLViewSpaceL * 2);
    }];
}

- (void)makeObservingAndActions {
    bjl_weakify(self);
    
    if (!self.room.loginUser.isTeacherOrAssistant) {
        [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingEnabled)
             observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 BOOL enabled = (!self.room.loginUser.isAudition
                                 && !self.room.featureConfig.disableSpeakingRequest
                                 && (self.room.speakingRequestVM.speakingEnabled
                                     || self.room.roomInfo.roomType != BJLRoomType_1vNClass));
                 self.micSwitch.enabled = enabled;
                 self.cameraSwitch.enabled = enabled;
                 return YES;
             }];
    }
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.micSwitch.on = now.boolValue;
             return YES;
         }];
    [self.micSwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        BJLError *error = [self.room.recordingVM setRecordingAudio:sender.on
                                                    recordingVideo:self.room.recordingVM.recordingVideo];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            // 避免触发 UIControlEventValueChanged
            bjl_dispatch_async_main_queue(^{
                [self.micSwitch setOn:self.room.recordingVM.recordingAudio animated:NO];
            });
        }
        else {
            [self showProgressHUDWithText:(self.room.recordingVM.recordingAudio
                                           ? @"麦克风已打开"
                                           : @"麦克风已关闭")];
        }
    } forControlEvents:UIControlEventValueChanged];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingVideo)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL on = now.boolValue;
             self.cameraSwitch.on = on;
             return YES;
         }];
    [self.cameraSwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                    recordingVideo:sender.on];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            bjl_dispatch_async_main_queue(^{
                [self.cameraSwitch setOn:self.room.recordingVM.recordingVideo animated:NO];
            });
        }
        else {
            [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                           ? @"摄像头已打开"
                                           : @"摄像头已关闭")];
        }
    } forControlEvents:UIControlEventValueChanged];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, videoBeautifyLevel)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.beautifySwitch.on = (now.integerValue != BJLVideoBeautifyLevel_off);
             return YES;
         }];
    [self.beautifySwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        BJLError *error = [self.room.recordingVM updateVideoBeautifyLevel:(sender.on
                                                                           ? BJLVideoBeautifyLevel_on
                                                                           : BJLVideoBeautifyLevel_off)];
        if (error) {
            self.beautifySwitch.on = (self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_on);
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    } forControlEvents:UIControlEventValueChanged];
    
    [self bjl_kvo:BJLMakeProperty(self.room.mediaVM, supportBackgroundAudio)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.backgroundAudioSwitch.on  = now.boolValue;
             return YES;
         }];
    [self.backgroundAudioSwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayS];
        
        BJLError *error = [self.room.mediaVM updateSupportBackgroundAudio:sender.on];
        if (error) {
            self.backgroundAudioSwitch.on = self.room.mediaVM.supportBackgroundAudio;
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    } forControlEvents:UIControlEventValueChanged];
    
    [self bjl_kvo:BJLMakeProperty(self.room, disablePPTAnimation)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.pptAnimationSwitch.on = !now.boolValue;
             return YES;
         }];
    [self.pptAnimationSwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayS];
        self.room.disablePPTAnimation = !sender.on;
    } forControlEvents:UIControlEventValueChanged];
    
    [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, showPPTRemarkInfo)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.pptRemarkSwitch.on = self.room.slideshowViewController.showPPTRemarkInfo;
             return YES;
         }];
    [self.pptRemarkSwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayS];
        [self.room.slideshowViewController updateShowPPTRemarkInfo:sender.on];
    } forControlEvents:UIControlEventValueChanged];
    
    [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidAll)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.forbidChatSwitch.on = now.boolValue;
             return YES;
         }];
    [self.forbidChatSwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayS];
        NSError *error = [self.room.chatVM sendForbidAll:sender.on];
        [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, forbidSpeakingRequest)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.forbidSpeakSwitch.on = now.boolValue;
             return YES;
         }];
    [self.forbidSpeakSwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayS];
        [self.room.speakingRequestVM requestForbidSpeakingRequest:sender.on];
    } forControlEvents:UIControlEventValueChanged];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, forbidAllRecordingAudio)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.forbidAudioSwitch.on = now.boolValue;
             return YES;
         }];
    [self.forbidAudioSwitch bjl_addHandler:^(UISwitch * _Nullable sender, UIControlEvents event) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayS];
        [self.room.recordingVM sendForbidAllRecordingAudio:sender.on];
    } forControlEvents:UIControlEventValueChanged];
    
    [self bjl_kvo:BJLMakeProperty(self.room, slideshowViewController)
           filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return !old && now;
           }
         observer:^(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.contentModeFitButton.enabled
             = self.contentModeFillButton.enabled
             = (self.room.disablePPTAnimation
                || self.room.featureConfig.disablePPTAnimation);
             return NO;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, contentMode)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BJLContentMode contentMode = now.integerValue;
             self.contentModeFitButton.selected = (contentMode == BJLContentMode_scaleAspectFit);
             self.contentModeFillButton.selected = (contentMode == BJLContentMode_scaleAspectFill);
             return YES;
         }];
    [self.contentModeFitButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (!self.contentModeFitButton.selected) {
            self.room.slideshowViewController.contentMode = BJLContentMode_scaleAspectFit;
        }
    }];
    [self.contentModeFillButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (!self.contentModeFillButton.selected) {
            self.room.slideshowViewController.contentMode = BJLContentMode_scaleAspectFill;
        }
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, videoDefinition)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BJLVideoDefinition videoDefinition = now.integerValue;
             self.videoDefinitionLowButton.selected = (videoDefinition == BJLVideoDefinition_std);
             self.videoDefinitionHighButton.selected = (videoDefinition == BJLVideoDefinition_high);
             self.videoDefinition720pButton.selected = (videoDefinition == BJLVideoDefinition_720p);
             self.videoDefinition1080pButton.selected = (videoDefinition == BJLVideoDefinition_1080p);
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, usingRearCamera)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL usingRearCamera = now.boolValue;
             self.cameraPositionFrontButton.selected = !usingRearCamera;
             self.cameraPositionRearButton.selected = usingRearCamera;
             return YES;
         }];
    [self.cameraPositionFrontButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        [self.cameraPositionRearButton bjl_disableForSeconds:BJLRobotDelayM];
        if (!self.cameraPositionFrontButton.selected) {
            BJLError *error = [self.room.recordingVM updateUsingRearCamera:NO];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }
    }];
    [self.cameraPositionRearButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        [self.cameraPositionFrontButton bjl_disableForSeconds:BJLRobotDelayM];
        if (!self.cameraPositionRearButton.selected) {
            BJLError *error = [self.room.recordingVM updateUsingRearCamera:YES];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.mediaVM, upLinkType)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BJLLinkType upLinkType = now.integerValue;
             self.upLinkTypeTCPButton.selected = (upLinkType == BJLLinkType_TCP);
             self.upLinkTypeUDPButton.selected = (upLinkType == BJLLinkType_UDP);
             return YES;
         }];
    [self.upLinkTypeTCPButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        [self.upLinkTypeUDPButton bjl_disableForSeconds:BJLRobotDelayM];
        if (self.room.mediaVM.upLinkTypeReadOnly) {
            [self showProgressHUDWithText:@"暂时不能切换线路"];
            return;
        }
        if (self.room.featureConfig.isWebRTC) {
            [self showProgressHUDWithText:@"该房间不能切换链路类型"];
            return;
        }
        
        // 切换 TCP 上行链路的 CDN
        [self showTCPLinkTypeSwitchAlertWithIsUplink:YES
                                          completion:^(NSInteger selectIndex, BOOL canceled) {
                                              bjl_strongify(self);
                                              if (canceled) {
                                                  return;
                                              }
                                              
                                              BJLError *error = [self.room.mediaVM updateTCPUpLinkCDNWithIndex:selectIndex];
                                              if (error) {
                                                  [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                                  bjl_dispatch_async_main_queue(^{
                                                      self.upLinkTypeTCPButton.selected = (self.room.mediaVM.upLinkType == BJLLinkType_TCP);
                                                      self.upLinkTypeUDPButton.selected = (self.room.mediaVM.upLinkType == BJLLinkType_UDP);
                                                  });
                                              }
                                          }];
    }];
    
    [self.upLinkTypeUDPButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        [self.upLinkTypeTCPButton bjl_disableForSeconds:BJLRobotDelayM];
        if (!self.upLinkTypeUDPButton.selected) {
            if (self.room.mediaVM.upLinkTypeReadOnly) {
                [self showProgressHUDWithText:@"暂时不能切换线路"];
                return;
            }
            if (self.room.featureConfig.isWebRTC) {
                [self showProgressHUDWithText:@"该房间不能切换链路类型"];
                return;
            }
            BJLError *error = [self.room.mediaVM updateUpLinkType:BJLLinkType_UDP];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                bjl_dispatch_async_main_queue(^{
                    self.upLinkTypeTCPButton.selected = (self.room.mediaVM.upLinkType == BJLLinkType_TCP);
                    self.upLinkTypeUDPButton.selected = (self.room.mediaVM.upLinkType == BJLLinkType_UDP);
                });
            }
        }
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.mediaVM, downLinkType)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BJLLinkType downLinkType = now.integerValue;
             self.downLinkTypeTCPButton.selected = (downLinkType == BJLLinkType_TCP);
             self.downLinkTypeUDPButton.selected = (downLinkType == BJLLinkType_UDP);
             return YES;
         }];
    [self.downLinkTypeTCPButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        [self.downLinkTypeUDPButton bjl_disableForSeconds:BJLRobotDelayM];
        if (self.room.mediaVM.downLinkTypeReadOnly) {
            [self showProgressHUDWithText:@"暂时不能切换线路"];
            return;
        }
        if (self.room.featureConfig.isWebRTC) {
            [self showProgressHUDWithText:@"该房间不能切换链路类型"];
            return;
        }
        // 切换 TCP 下行链路的 CDN
        [self showTCPLinkTypeSwitchAlertWithIsUplink:NO
                                          completion:^(NSInteger selectIndex, BOOL canceled) {
                                              bjl_strongify(self);
                                              if (canceled) {
                                                  return;
                                              }
                                              
                                              BJLError *error = [self.room.mediaVM updateTCPDownLinkCDNWithIndex:selectIndex];
                                              if (error) {
                                                  [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                                  bjl_dispatch_async_main_queue(^{
                                                      self.downLinkTypeTCPButton.selected = (self.room.mediaVM.downLinkType == BJLLinkType_TCP);
                                                      self.downLinkTypeUDPButton.selected = (self.room.mediaVM.downLinkType == BJLLinkType_UDP);
                                                  });
                                              }
                                          }];
    }];
    
    [self.downLinkTypeUDPButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [sender bjl_disableForSeconds:BJLRobotDelayM];
        [self.downLinkTypeTCPButton bjl_disableForSeconds:BJLRobotDelayM];
        if (!self.downLinkTypeUDPButton.selected) {
            if (self.room.mediaVM.downLinkTypeReadOnly) {
                [self showProgressHUDWithText:@"暂时不能切换线路"];
                return;
            }
            if (self.room.featureConfig.isWebRTC) {
                [self showProgressHUDWithText:@"该房间不能切换链路类型"];
                return;
            }
            BJLError *error = [self.room.mediaVM updateDownLinkType:BJLLinkType_UDP] ;
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                self.downLinkTypeTCPButton.selected = (self.room.mediaVM.downLinkType == BJLLinkType_TCP);
                self.downLinkTypeUDPButton.selected = (self.room.mediaVM.downLinkType == BJLLinkType_UDP);
            }
        }
    }];
}

#pragma mark - 线路切换

- (void)showTCPLinkTypeSwitchAlertWithIsUplink:(BOOL)isUplink completion:(void (^)(NSInteger selectIndex, BOOL canceled))completion {
    NSString *title = isUplink ? @"选择上行 TCP 线路" : @"选择下行 TCP 线路";
    UIAlertController *alertController = [UIAlertController
                                          bjl_lightAlertControllerWithTitle:title
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSUInteger availableCDNCount = isUplink ? self.room.mediaVM.upLinkCDNCount : self.room.mediaVM.downLinkCDNCount;
    NSInteger currentIndex = isUplink ? self.room.mediaVM.upLinkCDNIndex : self.room.mediaVM.downLinkCDNIndex;
    BOOL isTCPNow = isUplink ? (self.room.mediaVM.upLinkType == BJLLinkType_TCP) : (self.room.mediaVM.downLinkType == BJLLinkType_TCP);
    
    // autoSwitch
    NSString *checkedString = @" ✓";
    BOOL autoSwitch = (currentIndex < 0 || currentIndex > availableCDNCount) && isTCPNow;
    UIAlertAction *autoSwitchAction = [alertController bjl_addActionWithTitle:[NSString stringWithFormat:@"自动%@", autoSwitch ? checkedString : @""]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                                          // bjl_strongify(self);
                                                                          if (completion) {
                                                                              completion(NSNotFound, NO);
                                                                          }
                                                                      }];
    autoSwitchAction.enabled = !autoSwitch;
    
    for (NSInteger index = 0; index < availableCDNCount; index ++) {
        // switchAction
        BOOL selected = (currentIndex == index && isTCPNow);
        UIAlertAction *switchAction = [alertController bjl_addActionWithTitle:[NSString stringWithFormat:@"线路 %td%@", index + 1,  selected? checkedString : @""]
                                                                        style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                                          // bjl_strongify(self);
                                                                          if (completion) {
                                                                              completion(index, NO);
                                                                          }
                                                                      }];
        switchAction.enabled = !selected;
    }
    
    // cancel
    [alertController bjl_addActionWithTitle:@"取消"
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction * _Nonnull action) {
                                        // bjl_strongify(self);
                                        if (completion) {
                                            completion(NSNotFound, YES);
                                        }
                                    }];
    
    alertController.popoverPresentationController.sourceView = isUplink ? self.upLinkTypeTCPButton : self.downLinkTypeTCPButton;
    alertController.popoverPresentationController.sourceRect = [UIApplication sharedApplication].statusBarFrame;
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

@end

NS_ASSUME_NONNULL_END

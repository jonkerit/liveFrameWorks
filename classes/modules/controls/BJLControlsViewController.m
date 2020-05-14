//
//  BJLControlsViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-02-15.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLHitTestView.h>

#import "BJLControlsViewController.h"
#import "BJLAnnularProgressView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLControlsViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic) UIView *rightToolBar, *bottomToolBar;

@property (nonatomic) UIButton *pptButton, *handButton, *penButton, *usersButton, *countDownButton;
@property (nonatomic) BJLAnnularProgressView *handProgressView;

@property (nonatomic, readwrite) UIButton *micButton, *cameraButton;
@property (nonatomic) UIButton *rotateButton, *moreButton;

@property (nonatomic) UIButton *chatButton, *questionButton;

@property (nonatomic, readwrite) UIView *questionRedDot;

@end

@implementation BJLControlsViewController

#pragma mark - lifecycle & <BJLRoomChildViewController>

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self->_room = room;
    }
    return self;
}

- (void)loadView {
    bjl_weakify(self);
    self.view = [BJLHitTestView viewWithFrame:[UIScreen mainScreen].bounds hitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        
        NSArray *containerViews = @[self.view, self.rightToolBar, self.bottomToolBar];
        
        // 非 container-view 才响应点击事件
        if (![containerViews containsObject:hitView]) {
            return hitView;
        }
        
        // 避免按钮禁用状态下点击穿透到 contentView，导致 controls 被隐藏
        // @see https://stackoverflow.com/a/40786920/456536
        for (UIView *superview in containerViews) {
            for (UIView *subview in superview.subviews) {
                UIControl *control = bjl_as(subview, UIControl);
                CGPoint pointInControl = [self.view convertPoint:point toView:control];
                if (control && !control.enabled && [control pointInside:pointInControl withEvent:event]) {
                    return self.view; // requires `self.view.userInteractionEnabled = YES;` 👇🏿
                }
            }
        }
        
        return nil;
    }];
    
    self.view.userInteractionEnabled = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviews];
    [self makeConstraints];
    [self updateButtonStates];
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room, state)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return (BJLRoomState)[now integerValue] == BJLRoomState_connected;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateRightToolBarButtons];
             [self updateButtonStates];
             return YES;
         }];
    
    [self makeObserving];
    [self makeActions];
}

// NOTE: trigger by [self.view setNeedsUpdateConstraints];
- (void)updateViewConstraints {
    [self updateButtonStates];
    [super updateViewConstraints];
}

#pragma mark - <UIContentContainer>

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    NSLog(@"%@ willTransitionToSizeClasses: %td-%td",
          NSStringFromClass([self class]), newCollection.horizontalSizeClass, newCollection.verticalSizeClass);
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        // @see - [self updateViewConstraints]
        [self.view setNeedsUpdateConstraints];
    } completion:nil];
}

#pragma mark - makeSubviews

- (void)makeSubviews {
    self.rightToolBar = ({
        UIView *view = [UIView new];
        [self.view addSubview:view];
        view;
    });
    
    self.bottomToolBar = ({
        UIView *view = [UIView new];
        [self.view addSubview:view];
        view;
    });
    
    self.pptButton = [self makeButtonWithIconName:@"bjl_ic_ppt"
                                 selectedIconName:nil
                                             size:BJLButtonSizeL
                                        superview:nil]; // add to self.rightToolBar later
    
    self.handButton = [self makeButtonWithIconName:@"bjl_ic_handup"
                                  selectedIconName:@"bjl_ic_handup_on"
                                              size:BJLButtonSizeL
                                         superview:nil]; // add to self.rightToolBar later
    
    self.handProgressView = ({
        BJLAnnularProgressView *progressView = [BJLAnnularProgressView new];
        progressView.size = BJLButtonSizeL;
        progressView.annularWidth = 2.0;
        progressView.color = [UIColor bjl_blueBrandColor];
        progressView.userInteractionEnabled = NO;
        [self.handButton addSubview:progressView];
        [progressView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.handButton);
        }];
        progressView;
    });
    
    self.penButton = [self makeButtonWithIconName:@"bjl_ic_lightpen"
                                 selectedIconName:@"bjl_ic_lightpen_on"
                                             size:BJLButtonSizeL
                                        superview:nil]; // add to self.rightToolBar later
    
    self.usersButton = [self makeButtonWithIconName:@"bjl_ic_users"
                                   selectedIconName:nil
                                               size:BJLButtonSizeL
                                          superview:nil]; // add to self.rightToolBar later
    self.countDownButton = [self makeButtonWithIconName:@"bjl_countdown"
                                       selectedIconName:nil
                                                   size:BJLButtonSizeL
                                              superview:nil]; // add to self.rightToolBar later

    self.micButton = [self makeButtonWithIconName:@"bjl_ic_stopaudio_closed"
                                 selectedIconName:nil
                                             size:BJLButtonSizeM
                                        superview:self.bottomToolBar];
    
    self.cameraButton = [self makeButtonWithIconName:@"bjl_ic_stopvideo_closed"
                                    selectedIconName:@"bjl_ic_stopvideo_open"
                                                size:BJLButtonSizeM
                                           superview:self.bottomToolBar];
    
    self.rotateButton = [self makeButtonWithIconName:@"bjl_ic_rotate_hor" // 竖屏时 normal，点击切到横屏
                                    selectedIconName:@"bjl_ic_rotate_ver" // 横屏时 selected，点击切到竖屏
                                                size:BJLButtonSizeM
                                           superview:self.bottomToolBar];
    
    self.moreButton = [self makeButtonWithIconName:@"bjl_ic_more"
                                  selectedIconName:nil
                                              size:BJLButtonSizeM
                                         superview:self.bottomToolBar];
    
    self.chatButton = [self makeButtonWithIconName:@"bjl_ic_sentmsg"
                                  selectedIconName:nil
                                              size:BJLButtonSizeM
                                         superview:self.bottomToolBar];
    
    self.questionButton = [self makeButtonWithIconName:@"bjl_ic_question"
                                      selectedIconName:nil
                                                  size:BJLButtonSizeM
                                             superview:self.bottomToolBar];
    
    self.questionRedDot = ({
        UIView *view = [UIView new];
        view.hidden = YES;
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 5.0;
        view.backgroundColor = [UIColor redColor];
        [self.bottomToolBar addSubview:view];
        [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.top.equalTo(self.questionButton);
            make.height.width.equalTo(@10.0);
        }];
        view;
    });
}

- (UIButton *)makeButtonWithIconName:(nullable NSString *)iconName
                    selectedIconName:(nullable NSString *)selectedIconName
                                size:(CGFloat)size
                           superview:(nullable UIView *)superview {
    UIButton *button = [UIButton new];
    if (iconName) {
        [button setImage:[UIImage bjl_imageNamed:iconName] forState:UIControlStateNormal];
        /*
        if (selectedImage) {
            [button setImage:selectedImage forState:UIControlStateNormal | UIControlStateHighlighted];
        } */
        if (selectedIconName) {
            UIImage *selectedImage = [UIImage bjl_imageNamed:selectedIconName];
            [button setImage:selectedImage forState:UIControlStateSelected];
            [button setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
        }
    }
    
    button.layer.cornerRadius = size / 2;
    button.layer.masksToBounds = YES;
    
    [superview addSubview:button];
    
    return button;
}

- (void)updateRightToolBarButtons {
    if (!self.room.loginUser) {
        return;
    }
    
    NSArray<UIButton *> *buttons;
    if (self.room.loginUser.isTeacher) {
        buttons = @[self.countDownButton, self.penButton, self.pptButton, self.usersButton];
    }
    else if (self.room.loginUser.isAssistant) {
        buttons = @[self.penButton, self.pptButton, self.usersButton];
    }
    else if (self.room.roomInfo.roomType != BJLRoomType_1vNClass) {
        buttons = @[self.penButton, self.usersButton];
    }
    else {
        // self.room.speakingRequestVM.speakingEnabled || NOT
        buttons = @[self.penButton, self.handButton, self.usersButton];
    }
    
    [self.rightToolBar.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIButton *last = nil;
    for (UIButton *button in buttons) {
        [self.rightToolBar addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(last.bjl_bottom ?: self.rightToolBar).with.offset(last ? BJLViewSpaceM : 0.0);
            make.left.right.equalTo(self.rightToolBar);
            make.width.height.equalTo(@(BJLButtonSizeL));
        }];
        last = button;
    }
    [last bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(self.rightToolBar);
    }];
}

- (void)updateMicButtonSelectedIconWithInputVolumeLevel:(CGFloat)inputVolumeLevel {
    if (!self.micButton.selected) {
        return;
    }
    
    bjl_returnIfRobot(0.2);
    
    NSArray<NSString *> * const imageNames = @[@"bjl_ic_stopaudio_1",
                                               @"bjl_ic_stopaudio_2",
                                               @"bjl_ic_stopaudio_3",
                                               @"bjl_ic_stopaudio_4",
                                               @"bjl_ic_stopaudio_5",
                                               @"bjl_ic_stopaudio_6"];
    NSInteger imageIndex = round(imageNames.count * inputVolumeLevel);
    NSString *imageName = [imageNames bjl_objectAtIndex:imageIndex] ?: imageNames.firstObject;
    UIImage *image = [UIImage bjl_imageNamed:imageName];
    [self.micButton setImage:image forState:UIControlStateSelected];
    [self.micButton setImage:image forState:UIControlStateSelected | UIControlStateHighlighted];
}

#pragma mark - makeConstraints

- (void)makeConstraints {
    [self.rightToolBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.view).inset(BJLViewSpaceM);
        // 纵向居中时【不能】从 bottomToolBar 顶部算起，因为竖屏时上边有发言列表、横屏时上边有退出按钮
        make.centerY.equalTo(self.view);
    }];
    [self.bottomToolBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view).inset(BJLViewSpaceM);
        make.height.equalTo(@(BJLButtonSizeM));
    }];
    
    UIButton *lastRightButton = nil;
    NSArray<UIButton *> *rightButtons = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
                                    ? @[self.moreButton/* , self.rotateButton */, self.cameraButton, self.micButton]
                                    : @[self.moreButton, self.rotateButton, self.cameraButton, self.micButton]);
    for (UIButton *button in rightButtons) {
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.right.equalTo(lastRightButton.bjl_left ?: self.bottomToolBar).with.offset(lastRightButton ? - BJLViewSpaceM : 0.0);
            make.centerY.equalTo(self.bottomToolBar);
            make.width.height.equalTo(@(BJLButtonSizeM));
        }];
        lastRightButton = button;
    }
    
    UIButton *lastLeftButton = nil;
    NSArray<UIButton *> *leftButtons = @[self.chatButton, self.questionButton];
    for (UIButton *button in leftButtons) {
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(lastLeftButton.bjl_right ?: self.bottomToolBar).offset(lastLeftButton ? BJLViewSpaceM : 0.0);
            make.centerY.equalTo(self.bottomToolBar);
            make.width.height.equalTo(@(BJLButtonSizeM));
        }];
        lastLeftButton = button;
    }
}

#pragma mark - makeObserving

- (void)makeObserving {
    bjl_weakify(self);
    
    BJLPropertyFilter ifIntegerChanged = ^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.integerValue != old.integerValue;
    };
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestTimeRemaining)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return timeRemaining.doubleValue != old.doubleValue;
           }
         observer:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (timeRemaining.doubleValue <= 0.0) {
                 self.handProgressView.progress = 0.0;
             }
             else {
                 CGFloat progress = timeRemaining.doubleValue / self.room.speakingRequestVM.speakingRequestTimeoutInterval; // 1.0 ~ 0.0
                 self.handProgressView.progress = progress;
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room, loadingVM)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateButtonStates];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingEnabled)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateButtonStates];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingGranted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateButtonStates];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, drawingEnabled)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateButtonStates];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.mainPlayingAdapterVM, playingUsers)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSArray<BJLUser *> * _Nullable now, NSArray<BJLUser *> * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old;
           }
         observer:^BOOL(NSArray<BJLUser *> * _Nullable now, NSArray<BJLUser *> * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (now.count > 0 != old.count > 0) {
                 [self updateButtonStates];
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.micButton.selected = self.room.recordingVM.recordingAudio;
             if (self.micButton.selected) {
                 [self updateMicButtonSelectedIconWithInputVolumeLevel:1.0];
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, inputVolumeLevel)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return ABS(round(old.doubleValue * 10) - round(now.doubleValue * 10)) >= 1.0;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateMicButtonSelectedIconWithInputVolumeLevel:now.doubleValue];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingVideo)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.cameraButton.selected = self.room.recordingVM.recordingVideo;
             return YES;
         }];
}

- (void)updateButtonStates {
    BOOL isHorizontal = BJLIsHorizontalUI(self);
    
    // loading == before loading + loading + after exit
    BOOL loading = self.room.loadingVM || !self.room.loginUser;
    
    BOOL is1toN = self.room.roomInfo.roomType == BJLRoomType_1vNClass;
    BOOL isTeacherOrAssistant = self.room.loginUser.isTeacherOrAssistant;
    // BOOL isTeacherOrAssistantNoGroup = isTeacherOrAssistant && self.room.loginUser.noGroup;
    
    BOOL speakingEnabled = self.room.speakingRequestVM.speakingEnabled || !is1toN;
    BOOL drawingGranted = self.room.drawingVM.drawingGranted;
    BOOL drawingEnabled = self.room.slideshowViewController.drawingEnabled;
    
    BOOL penOnly = isHorizontal && drawingEnabled;
    
    BOOL hideUserList = self.room.featureConfig.hideUserList && !isTeacherOrAssistant;
    // !!! 修改问答的隐藏显示时也要去修改问答红点的隐藏显示
    BOOL enableQuestion = self.room.featureConfig.enableQuestion && ![self.room.roomInfo.environmentName isEqualToString:@"www"];
    
    /* right */
    
    self.pptButton.hidden = loading || penOnly || !isTeacherOrAssistant;
    
    self.handButton.hidden = loading || penOnly || isTeacherOrAssistant || !is1toN || self.room.loginUser.isAudition;
    self.handButton.selected = !isTeacherOrAssistant && speakingEnabled;
    
    self.penButton.hidden = loading || !(isTeacherOrAssistant || (speakingEnabled && drawingGranted));
    self.penButton.selected = drawingEnabled;
    
    self.usersButton.hidden = loading || penOnly || hideUserList;
    
    /* right bottom */
    
    self.moreButton.hidden = loading || penOnly;
    
    self.rotateButton.hidden = loading || penOnly;
    // 解决旋转动画过程中更改 button 状态无效的问题
    bjl_dispatch_async_main_queue(^{
        self.rotateButton.selected = isHorizontal;
    });
    
    self.micButton.hidden = loading || penOnly || !(isTeacherOrAssistant || speakingEnabled) || self.room.loginUser.isAudition;
    self.micButton.selected = self.room.recordingVM.recordingAudio;
    
    self.cameraButton.hidden = loading || penOnly || !(isTeacherOrAssistant || speakingEnabled) || self.room.loginUser.isAudition;
    self.cameraButton.selected = self.room.recordingVM.recordingVideo;
    
    /* left bottom */
    
    self.chatButton.hidden = loading || penOnly || self.room.loginUser.isAudition;
    
    BOOL questionButtonHidden = loading || penOnly || !enableQuestion || self.room.loginUser.isAudition;
    [self.questionButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(@(questionButtonHidden ? 0.0 : BJLButtonSizeM));
    }];
}

#pragma mark - makeActions

- (void)makeActions {
    bjl_weakify(self);
    
    [self.pptButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.pptCallback) self.pptCallback(button);
    }];
    
    [self.countDownButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.countDownTimerCallback) self.countDownTimerCallback(button);
    }];

    [self.handButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:BJLRobotDelayS];
        if (self.handCallback) self.handCallback(button);
    }];
    
    [self.penButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.penCallback) self.penCallback(button);
    }];
    
    [self.usersButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.usersCallback) self.usersCallback(button);
    }];
    
    [self.moreButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.moreCallback) self.moreCallback(button);
    }];
    
    [self.rotateButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.rotateCallback) self.rotateCallback(button);
    }];
    
    [self.micButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:BJLRobotDelayM];
        if (self.micCallback) self.micCallback(button);
    }];
    
    [self.cameraButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:BJLRobotDelayM];
        if (self.cameraCallback) self.cameraCallback(button);
    }];
    
    [self.chatButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.chatCallback) self.chatCallback(button);
    }];
    
    [self.questionButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.questionCallback) self.questionCallback(button);
    }];
}

#pragma mark - public

- (BJLConstraintTarget *)rightLayoutGuide {
    if (!self.isViewLoaded) {
        [self view];
    }
    return self.rightToolBar.bjl_left;
}

- (BJLConstraintTarget *)bottomLayoutGuide {
    if (!self.isViewLoaded) {
        [self view];
    }
    return self.bottomToolBar.bjl_top;
}

@end

NS_ASSUME_NONNULL_END

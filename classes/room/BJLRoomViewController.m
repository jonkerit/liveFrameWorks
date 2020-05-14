//
//  BJLRoomViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-01-17.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLAFNetworking.h>

#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLUserAgent.h>

#import <BJLiveCore/BJLiveCore.h>


#import "BJLRoomViewController.h"
#import "BJLRoomViewController+protected.h"

#import "BJLiveUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLRoomViewController ()

@property (nonatomic) CGRect keyboardFrame;

@property (nonatomic, nullable) BJLAFNetworkReachabilityManager *reachability;
@property (nonatomic, nullable) BJLProgressHUD *prevHUD;
@property (nonatomic, nullable) BJLProgressHUD *networkTipHUD;

@end

@implementation BJLRoomViewController {
    BOOL _entered;
}

+ (void)load {
    [[BJLUserAgent defaultInstance] registerSDK:BJLiveUIName() version:BJLiveUIVersion()];
}

#pragma mark - lifecycle & <BJLRoomChildViewController>

- (instancetype)initWithRoom:(BJLRoom *)room {
    NSParameterAssert(room);
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self->_room = room;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor bjl_darkGrayTextColor];
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif
    
    [self makeViewControllersOnViewDidLoad];
    [self makeActionsOnViewDidLoad];
    [self makeRoomObserving];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    /* 第一次 `viewDidAppear:` 时进入教室、而不是 `viewDidLoad`，因为要避免
     在创建 `BJLRoomViewController` 实例后、如果触发 `viewDidLoad` 但没有立即展示；
     然后 `viewDidLoad` 中调用 `enter`，进教室过程中可能需要弹出提示；
     但在 `viewDidAppear:` 之前弹出的提示无法显示，并在终端打印警告。
     Warning: Attempt to present <UIAlertController> on <BJLRoomViewController> whose view
     is not in the window hierarchy!
     */
    if (!_entered) {
        _entered = YES;
        [self.room enterByValidatingConflict:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHideWithNotification:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrameWithNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
}

// NOTE: trigger by [self.view setNeedsUpdateConstraints];
- (void)updateViewConstraints {
    BOOL isHorizontal = BJLIsHorizontalUI(self);
    if (!isHorizontal) {
        // controls: 切到竖屏不再隐藏、并且再切回横屏依然显示
        [self setControlsHidden:NO animated:NO]; // TODO: 这里开动画会引起进教室时 self.backgroundView 动画异常
    }
    [self updateConstraintsForHorizontal:isHorizontal];
    [super updateViewConstraints];
}

- (void)dealloc {
    [self.reachability stopMonitoring];
    self.reachability = nil;
    
    [self clean];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

// NOTE: trigger by [self setNeedsStatusBarAppearanceUpdate];

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    BOOL isHorizontal = BJLIsHorizontalUI(self);
    return (self.imageViewController.parentViewController
            || self.room.slideshowViewController.drawingEnabled
            || (!self.overlayViewController.hidden && self.overlayViewController.prefersStatusBarHidden)
            || (isHorizontal && (self.controlsHidden)));
    // TODO: self.overlayViewController.prefersStatusBarHidden 支持由 contentViewController 设置，要区分横竖屏？
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (nullable UIViewController *)childViewControllerForStatusBarStyle {
    return self.overlayViewController.hidden ? nil : self.overlayViewController;
}

- (nullable UIViewController *)childViewControllerForStatusBarHidden {
    return self.overlayViewController.hidden ? nil : self.overlayViewController;
}

// NOTE: trigger by [self setNeedsUpdateOfHomeIndicatorAutoHidden];

- (BOOL)prefersHomeIndicatorAutoHidden {
    BOOL isHorizontal = BJLIsHorizontalUI(self);
    return isHorizontal;
}

#pragma mark - UIViewControllerRotation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone
            ? UIInterfaceOrientationMaskAllButUpsideDown
            : UIInterfaceOrientationMaskAll);
}

#pragma mark - <UIContentContainer>

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSLog(@"%@ viewWillTransitionToSize: %@",
          NSStringFromClass([self class]), NSStringFromCGSize(size));
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    NSLog(@"%@ willTransitionToSizeClasses: %td-%td",
          NSStringFromClass([self class]), newCollection.horizontalSizeClass, newCollection.verticalSizeClass);
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [self setNeedsStatusBarAppearanceUpdate];
        if (@available(iOS 11.0, *)) {
            [self setNeedsUpdateOfHomeIndicatorAutoHidden];
        }
        [self.view setNeedsUpdateConstraints];
    } completion:nil];
}

#pragma mark - events

- (void)makeRoomObserving {
    // [self bjl_stopAllMethodParametersObservingOfTarget:self.room];
    
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomSuccess)
             observer:^BOOL {
                 bjl_strongify(self);
                 
                 if (self.room.loginUser.isTeacher
                     && !self.room.roomVM.liveStarted) {
                     [self.room.roomVM sendLiveStarted:YES]; // 进入教室上课
                 }
                                  
                 [self roomViewControllerEnterRoomSuccess:self];
                 
                 self.reachability = ({
                     __block BOOL isFirstTime = YES;
                     BJLAFNetworkReachabilityManager *reachability = [BJLAFNetworkReachabilityManager manager];
                     [reachability setReachabilityStatusChangeBlock:^(BJLAFNetworkReachabilityStatus status) {
                         bjl_strongify(self);
                         if (status != BJLAFNetworkReachabilityStatusReachableViaWWAN) {
                             return;
                         }
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             if (status != BJLAFNetworkReachabilityStatusReachableViaWWAN) {
                                 return;
                             }
                             if (isFirstTime) {
                                 isFirstTime = NO;
                                 UIAlertController *alert = [UIAlertController
                                                             bjl_lightAlertControllerWithTitle:@"正在使用3G/4G网络，可手动关闭视频以减少流量消耗"
                                                             message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
                                 [alert bjl_addActionWithTitle:@"知道了"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
                                 if (self.presentedViewController) {
                                     [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                                 }
                                 [self presentViewController:alert animated:YES completion:nil];
                             }
                             else {
                                 [self showProgressHUDWithText:@"正在使用3G/4G网络"];
                             }
                         });
                     }];
                     [reachability startMonitoring];
                     reachability;
                 });
                 
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomFailureWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self roomViewController:self enterRoomFailureWithError:error];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, roomWillExitWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isTeacher
                     && error.code != BJLErrorCode_exitRoom_loginConflict) {
                     if (self.room.serverRecordingVM.serverRecording) {
                         [self.room.serverRecordingVM requestServerRecording:NO]; // 退出教室停止录课
                     }
                     if (self.room.roomVM.liveStarted) {
                         [self.room.roomVM sendLiveStarted:NO]; // 退出教室下课
                     }
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, roomDidExitWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self roomDidExitWithError:error];
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self.room, state)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
               return (BJLRoomState)[value integerValue] == BJLRoomState_connected;
           }
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self makeObservingWhenEnteredInRoom];
             return NO;
         }];
    
    /*
    [self bjl_kvo:BJLMakeProperty(self.room, vmsAvailable)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.boolValue && !old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.room.recordingVM.videoOrientation = BJLVideoOrientation_landscape;
             return YES;
         }]; */
    // 设置 page control button 的样式和位置
    [self bjl_kvo:BJLMakeProperty(self.room, slideshowViewController)
           filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return !!now;
           }
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
                self.room.slideshowViewController.shouldSwitchNativePPTBlock = ^(NSString * _Nullable documentID, void (^ _Nonnull callback)(BOOL)) {
                    callback(YES);
                };
             self.room.slideshowViewController.view.backgroundColor = [UIColor clearColor];
             // self.room.slideshowViewController.contentMode = BJLContentMode_scaleAspectFit;
             // self.room.slideshowViewController.imageSize = 720;
             self.room.slideshowViewController.placeholderImage = [UIImage bjl_imageWithColor:[UIColor bjl_grayImagePlaceholderColor]];
             self.room.slideshowViewController.prevPageIndicatorImage = [UIImage bjl_imageNamed:@"bjl_ic_ppt_prev"];
             self.room.slideshowViewController.nextPageIndicatorImage = [UIImage bjl_imageNamed:@"bjl_ic_ppt_next"];
             self.room.slideshowViewController.pageControlButton = ({
                 const CGFloat buttonWidth = 60.0, buttonHeight = BJLButtonSizeS;
                 UIButton *button = [UIButton new];
                 [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                 button.titleLabel.font = [UIFont systemFontOfSize:14.0];
                 // !!!: should be same to `BJLContentView.clearDrawingButton.backgroundColor`
                 [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor bjl_dimColor]]
                                   forState:UIControlStateNormal];
                 [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor bjl_colorWithHexString:@"#89899C" alpha:0.5]]
                                   forState:UIControlStateDisabled];
                 button.layer.cornerRadius = buttonHeight / 2;
                 button.layer.masksToBounds = YES;
                 [button addTarget:self action:@selector(showOverlayViewController) forControlEvents:UIControlEventTouchUpInside];
                 [self.room.slideshowViewController.view addSubview:button];
                 [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
                     make.centerX.equalTo(self.room.slideshowViewController.view);
                     make.bottom.equalTo(self.room.slideshowViewController.view).offset(- BJLViewSpaceM);
                     make.size.equal.sizeOffset(CGSizeMake(buttonWidth, buttonHeight));
                 }];
                 button;
             });
             return YES;
         }];
}

- (void)showOverlayViewController {
    // 设置 page control button 的点击事件
    self.overlayViewController.prefersStatusBarHidden = NO;
    self.overlayViewController.backgroundColor = [UIColor clearColor];
    bjl_weakify(self);
    [self.overlayViewController
     showWithContentViewController:self.pptQuickSlideViewController
     remakeConstraintsBlock:^(BJLConstraintMaker *make, UIView *superView, BOOL isHorizontalUI, BOOL isHorizontalSize) {
         bjl_strongify(self);
         if (isHorizontalUI) {
             make.left.right.bottom.equalTo(superView);
         }
         else {
             make.left.right.equalTo(superView);
             make.top.equalTo(self.contentView.bjl_bottom);
         }
         BOOL iphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
         make.height.equalTo(iphone ? @(76.0) : @(100.0));
     }];
}

- (void)clean {
    self->_room = nil;
    // [self.viewController bjl_removeFromParentViewControllerAndSuperiew];
    // self.viewController = nil;
}

- (void)askToExit {
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:@"确定退出教室？"
                                message:nil
                                preferredStyle:UIAlertControllerStyleAlert];
    bjl_weakify(self);
    [alert bjl_addActionWithTitle:@"确定"
                            style:UIAlertActionStyleDestructive
                          handler:^(UIAlertAction * _Nonnull action) {
                              bjl_strongify(self);
                              [self exit];
                          }];
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)roomDidExitWithError:(BJLError *)error {
    // !error: 主动退出
    // BJLErrorCode_exitRoom_disconnected: self.loadingViewController 已处理
    if (!error
        || error.code == BJLErrorCode_exitRoom_disconnected) {
        [self dismissWithError:error];
        return;
    }
    
    if (error.code == BJLErrorCode_enterRoom_auditionTimeout
        || error.code == BJLErrorCode_exitRoom_auditionTimeout) {
        
        SEL setTitle_ = @selector(setTitle:);
        BOOL enableCountdown = [UIAlertAction instancesRespondToSelector:setTitle_];
        NSString * const defaultTitle = @"确定";
        NSString * const format = @" (%td)";
        
        __block UIAlertController *alert = nil;
        __block UIAlertAction *action = nil;
        __block NSInteger countdown = 5;
        
        NSTimer *timer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            countdown--;
            if (enableCountdown) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [action performSelector:setTitle_ withObject:[defaultTitle stringByAppendingFormat:format, countdown]];
#pragma clang diagnostic pop
            }
            if (countdown <= 0) {
                [timer invalidate];
                if (self.presentedViewController == alert) {
                    [alert dismissViewControllerAnimated:NO completion:^{
                        [self dismissWithError:error];
                    }];
                }
            }
        }];
        
        alert = [UIAlertController
                 bjl_lightAlertControllerWithTitle:self.room.featureConfig.auditionEndTip ?: @"哎呀，您的试听时间已到！"
                 message:nil
                 preferredStyle:UIAlertControllerStyleAlert];
        action = [alert bjl_addActionWithTitle:(enableCountdown ? [defaultTitle stringByAppendingFormat:format, countdown] : defaultTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [timer invalidate];
            [self dismissWithError:error];
        }];
        [[UIViewController bjl_topViewController] presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"%@: %@(%td)",
                         error.localizedDescription,
                         error.localizedFailureReason ?: @"",
                         error.code];
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:message
                                message:nil
                                preferredStyle:UIAlertControllerStyleAlert];
    bjl_weakify(self);
    [alert addAction:[UIAlertAction
                      actionWithTitle:@"确定"
                      style:UIAlertActionStyleCancel
                      handler:^(UIAlertAction * _Nonnull action) {
                          bjl_strongify(self);
                          [self dismissWithError:error];
                      }]];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dismissWithError:(nullable BJLError *)error {
    [self roomViewController:self willExitWithError:nil];
    
    void (^completion)(void) = ^{
        [self roomViewController:self didExitWithError:error];
    };
    
    UINavigationController *navigation = [self.parentViewController bjl_as:[UINavigationController class]];
    BOOL isRoot = (navigation
                   && self == navigation.topViewController
                   && self == navigation.bjl_rootViewController);
    UIViewController *outermost = isRoot ? navigation : self;
    
    // pop
    if (navigation && !isRoot) {
        [navigation bjl_popViewControllerAnimated:YES completion:completion];
    }
    // dismiss
    else if (!outermost.parentViewController && outermost.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:completion];
    }
    // close in `roomViewController:didExitWithError:`
    else {
        completion();
    }
}

#pragma mark - NSNotification

- (void)keyboardDidHideWithNotification:(NSNotification *)notification {
    self.keyboardFrame = CGRectZero;
}

- (void)keyboardWillChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    self.keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
}

#pragma mark - protected

- (void)showProgressHUDWithText:(NSString *)text {
    [self showProgressHUDWithText:text superView:self.view];
}

- (void)showProgressHUDWithText:(NSString *)text superView:(UIView *)superview {
    if (!text.length
        || [text isEqualToString:self.prevHUD.detailsLabel.text]) {
        return;
    }
    
    BJLProgressHUD *hud = [BJLProgressHUD bjl_hudForTextWithSuperview:superview];
    [hud bjl_makeDetailsLabelWithLabelStyle];
    hud.detailsLabel.text = text;
    hud.minShowTime = 0.0; // !!!: MUST be 0.0
    bjl_weakify(self, hud);
    hud.completionBlock = ^{
        bjl_strongify(self, hud);
        if (hud == self.prevHUD) {
            self.prevHUD = nil;
        }
    };
    
    if (self.prevHUD) {
        [self.prevHUD hideAnimated:NO];
        /*
         BJLProgressHUD *prevHUD = self.prevHUD;
         [UIView animateWithDuration:0.5 animations:^{
         prevHUD.offset = CGPointMake(0.0, - (CGRectGetHeight(prevHUD.bezelView.frame) + BJLViewSpaceM));
         } completion:^(BOOL finished) {
         [prevHUD hideAnimated:YES];
         }]; */
    }
    CGFloat minY = CGRectGetMinY(self.keyboardFrame);
    if (minY > CGFLOAT_MIN) {
        hud.offset = CGPointMake(0, - (CGRectGetHeight(self.view.frame) - minY) / 2);
    }
    [hud showAnimated:NO]; // YES?
    [hud hideAnimated:YES afterDelay:BJLProgressHUDTimeInterval];
    self.prevHUD = hud;
}

- (void)updateNetWorkTipHUDHidden:(BOOL)hidden {
    if (hidden) {
        [self.networkTipHUD hideAnimated:YES];
    }
    else {
        BJLProgressHUD *hud = [BJLProgressHUD bjl_hudForTextWithSuperview:self.view];
        [hud bjl_makeDetailsLabelWithLabelStyle];
        hud.detailsLabel.text = @"当前网络状况差";
        hud.minShowTime = 0.0; // !!!: MUST be 0.0
        CGFloat minY = CGRectGetMinY(self.keyboardFrame);
        if (minY > CGFLOAT_MIN) {
            self.networkTipHUD.offset = CGPointMake(0, - (CGRectGetHeight(self.view.frame) - minY) / 2);
        }
        [hud showAnimated:NO];
        self.networkTipHUD = hud;
    }
}

#pragma mark - public

+ (__kindof instancetype)instanceWithID:(NSString *)roomID
                                apiSign:(NSString *)apiSign
                                   user:(BJLUser *)user {
    BJLRoom *room = [BJLRoom roomWithID:roomID apiSign:apiSign user:user];
    return [[self alloc] initWithRoom:room];
}

+ (__kindof instancetype)instanceWithSecret:(NSString *)roomSecret
                                   userName:(NSString *)userName
                                 userAvatar:(nullable NSString *)userAvatar {
    BJLRoom *room = [BJLRoom roomWithSecret:roomSecret userName:userName userAvatar:userAvatar];
    return [[self alloc] initWithRoom:room];
}

- (void)exit {
    if (self.room) {
        [self.room exit];
    }
    else {
        [self dismissWithError:nil];
    }
}

- (void)setCustomButtons:(NSArray<UIButton *> *)buttons {
    UIView *customContainerView = self.topBarView.customContainerView;
    
    [customContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIButton *last = nil;
    for (UIButton *button in buttons) {
        [customContainerView addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.horizontal.compressionResistance.required();
            make.right.equalTo(last.bjl_left ?: customContainerView).with.offset(- BJLViewSpaceM);
            make.centerY.equalTo(customContainerView);
        }];
        
        bjl_weakify(self);
        [button bjl_addHandler:^(UIButton * _Nullable sender) {
            bjl_strongify(self);
            if ([self.delegate respondsToSelector:@selector(roomViewController:viewControllerToShowForCustomButton:)]) {
                UIViewController *content = [self.delegate
                                             roomViewController:self
                                             viewControllerToShowForCustomButton:sender];
                if (content) {
                    [self.overlayViewController showWithContentViewController:content];
                }
            }
        }];
        
        last = button;
    }
    
    [last bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.greaterThanOrEqualTo(customContainerView);
    }];
}

- (void)setPreviewBackgroundImageHidden:(BOOL)hidden {
    self->_previewBackgroundImageHidden = hidden;
    self.previewsViewController.backgroundView.hidden = hidden;
}

- (BOOL)enableShare {
    return self.room.featureConfig.enableShare;
}

#pragma mark - lamp

- (void)updateLamp {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    
    NSString *lampContent = (self.customLampContent
                             ?: self.room.roomVM.lamp.content);
    if (!lampContent.length) {
        return;
    }
    
    // lampLabel
    UILabel *lampLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor bjl_colorWithHexString:@"#090300" alpha:0.3];
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 1.0;
        label.font = [UIFont systemFontOfSize:10];
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = lampContent;
        [label sizeToFit];
        label.userInteractionEnabled = NO;
        label;
    });
    
    // 文字边距
    CGSize labelSize = CGSizeMake(lampLabel.bounds.size.width + 20.0, lampLabel.bounds.size.height + 10.0);
    
    // 垂直方向位置比例，产生从 垂直方向最小比例（精确到小数点后 3 位） 到 1 之间的一个随机比例，确定跑马灯的垂直方向的位置
    CGFloat minVerticalRatio = labelSize.height / self.view.bounds.size.height;
    int temp = ceil(minVerticalRatio * 1000);
    CGFloat verticalRatio = ((arc4random() % (1000 - temp)) + temp) / 1000.0;
    
    [self.view addSubview:lampLabel];
    [lampLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.view.bjl_left).offset(labelSize.width + self.view.bounds.size.width);
        make.bottom.equalTo(self.view).multipliedBy(verticalRatio);
        make.size.equal.sizeOffset(labelSize);
    }];
    [self.view layoutIfNeeded];
    
    // animation
    CGFloat speed = 25.0; // 跑马灯速度
    NSTimeInterval duration = (labelSize.width + self.view.bounds.size.width) / speed;
    bjl_weakify(self);
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         bjl_strongify(self);
                         // 设置动画结束后的最终位置
                         [lampLabel bjl_updateConstraints:^(BJLConstraintMaker *make) {
                             make.right.equalTo(self.view.bjl_left);
                         }];
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [lampLabel removeFromSuperview];
                     }];
    // 显示间隔
    [self performSelector:_cmd withObject:nil afterDelay:60.0];
}

#pragma mark - lazy load properties

- (void)makeViewControllersOnViewDidLoad {
    { // in-order add subview/childViewControllers
        [self.view addSubview:self.contentView];
        [self.view addSubview:self.backgroundView];
        [self bjl_addChildViewController:self.controlsViewController
                               superview:self.view];
        [self bjl_addChildViewController:self.chatViewController
                               superview:self.view];
        [self bjl_addChildViewController:self.previewsViewController
                               superview:self.view];
        [self.view addSubview:self.recordingStateView];
        
        [self.view addSubview:self.topBarView];
        [self.view addSubview:self.timerView];
        [self bjl_addChildViewController:self.overlayViewController];
        
        // at last
        [self bjl_addChildViewController:self.loadingViewController];
    }
    
    [UIViewController attemptRotationToDeviceOrientation];
    // @see - [self updateViewConstraints];
    [self.view setNeedsUpdateConstraints];
}

@synthesize contentView = _contentView;
- (BJLContentView *)contentView {
    return _contentView ?: (_contentView = ({
        BJLContentView *view = [BJLContentView new];
        view;
    }));
}

@synthesize backgroundView = _backgroundView;
- (UIView *)backgroundView {
    return _backgroundView ?: (_backgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_grayLineColor];
        view;
    }));
}

@synthesize previewsViewController = _previewsViewController;
- (BJLPreviewsViewController *)previewsViewController {
    return _previewsViewController ?: (_previewsViewController = ({
        BJLPreviewsViewController *view = [[BJLPreviewsViewController alloc] initWithRoom:self.room];
        bjl_weakify(self);
        [view setFullScreenItemChangedCallback:^(BJLPreviewItem * _Nonnull fullScreenItem) {
            bjl_strongify(self);
            [self.contentView updateViewsWithItem:fullScreenItem];
        }];
        view;
    }));
}

@synthesize controlsViewController = _controlsViewController;
- (BJLControlsViewController *)controlsViewController {
    return _controlsViewController ?: (_controlsViewController = ({
        BJLControlsViewController *controller = [[BJLControlsViewController alloc] initWithRoom:self.room];
        controller;
    }));
}

@synthesize chatInputViewController = _chatInputViewController;
- (BJLChatInputViewController *)chatInputViewController {
    return _chatInputViewController ?: (_chatInputViewController = ({
        BJLChatInputViewController *controller = [[BJLChatInputViewController alloc] initWithRoom:self.room];
        bjl_weakify(self);
        [controller setSelectImageFileCallback:^(ICLImageFile *file, UIImage * _Nullable image) {
            bjl_strongify(self);
            [self.overlayViewController hide];
            [self.chatViewController refreshMessages];
            [self.chatViewController sendImageFile:file image:image];
        }];
        [controller setFinishCallback:^(NSString * _Nullable errorMessage) {
            bjl_strongify(self);
            [self.overlayViewController hide];
            if (errorMessage.length) {
                [self showProgressHUDWithText:errorMessage];
            }
            else {
                [self.chatViewController refreshMessages];
            }
        }];
        controller;
    }));
}

@synthesize recordingStateView = _recordingStateView;
- (UIButton *)recordingStateView {
    return _recordingStateView ?: (_recordingStateView = ({
        BJLButton *button = [BJLButton new];
        [button setTitle:@"录课中" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_luxianging"] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.backgroundColor = [UIColor bjl_lightDimColor];
        button.adjustsImageWhenHighlighted = NO;
        button.adjustsImageWhenDisabled = NO;
        CGSize buttonSize = CGSizeMake(85.0, BJLButtonSizeS);
        button.layer.cornerRadius = buttonSize.height / 2;
        button.intrinsicContentSize = buttonSize;
        button.midSpace = BJLViewSpaceS;
        button.layer.masksToBounds = YES;
        button.hidden = YES;
        button;
    }));
}

@synthesize topBarView = _topBarView;
- (BJLTopBarView *)topBarView {
    return _topBarView ?: (_topBarView = ({
        BJLTopBarView *view = [BJLTopBarView new];
        view;
    }));
}

@synthesize timerView = _timerView;
- (BJLHitTestView *)timerView {
    return _timerView ?: (_timerView = ({
        BJLHitTestView *view = [BJLHitTestView new];
        view;
    }));
}

@synthesize onlineGroupUsersViewController = _onlineGroupUsersViewController;
- (BJLUserListViewController *)onlineGroupUsersViewController {
    return _onlineGroupUsersViewController ?: (_onlineGroupUsersViewController = ({
        BJLUserListViewController *controller = [[BJLUserListViewController alloc] initWithRoom:self.room];
        bjl_weakify(self);
        [controller setErrorCallback:^(NSString * _Nonnull errorMessage) {
            bjl_strongify(self);
            [self showProgressHUDWithText:errorMessage];
        }];
        controller;
    }));
}

@synthesize onlineUsersViewController = _onlineUsersViewController;
- (BJLUsersViewController *)onlineUsersViewController {
    return _onlineUsersViewController ?: (_onlineUsersViewController = ({
        BJLUsersViewController *controller = [[BJLUsersViewController alloc] initWithRoom:self.room userStates:BJLUserStateMask_online];
        controller;
    }));
}

@synthesize pptManageViewController = _pptManageViewController;
- (BJLPPTManageViewController *)pptManageViewController {
    return _pptManageViewController ?: (_pptManageViewController = ({
        BJLPPTManageViewController *controller = [[BJLPPTManageViewController alloc] initWithRoom:self.room];
        bjl_weakify(self);
        [controller setErrorCallback:^(NSString * _Nonnull errorMessage) {
            bjl_strongify(self);
            [self showProgressHUDWithText:errorMessage];
        }];

        [controller setUploadingCallback:^(NSInteger failedCount, void (^ _Nullable retry)(void)) {
            bjl_strongify(self);
            if (failedCount > 0) {
                [self showProgressHUDWithText:[NSString stringWithFormat:@"有%td个课件上传失败", failedCount]];
                /*
                UIAlertController *alert = [UIAlertController
                                            bjl_lightAlertControllerWithTitle:[NSString stringWithFormat:@"有%td个课件上传失败。", failedCount]
                                            message:nil
                                            preferredStyle:UIAlertControllerStyleAlert];
                if (retry) {
                    [alert bjl_addActionWithTitle:@"重试"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull action) {
                                              retry();
                                          }];
                }
                [alert bjl_addActionWithTitle:retry ? @"取消" : @"确定"
                                        style:UIAlertActionStyleCancel
                                      handler:nil];
                if (self.presentedViewController) {
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                }
                [self presentViewController:alert animated:YES completion:nil]; */
            }
            else {
                [self showProgressHUDWithText:@"课件上传完成"];
            }
        }];
        controller;
    }));
}

@synthesize pptQuickSlideViewController = _pptQuickSlideViewController;
- (BJLPPTQuickSlideViewController *)pptQuickSlideViewController {
    return _pptQuickSlideViewController ?: (_pptQuickSlideViewController = ({
        BJLPPTQuickSlideViewController *controller = [[BJLPPTQuickSlideViewController alloc] initWithRoom:self.room];
        /*
        [controller setSelectPPTCallback:^{
            bjl_strongify(self);
            [self.overlayViewController hide];
        }];
        */
        bjl_weakify(self);
        [controller setErrorCallback:^(NSString * _Nonnull errorMessage) {
            bjl_strongify(self);
            [self showProgressHUDWithText:errorMessage];
        }];
        controller;
    }));
}

@synthesize chatViewController = _chatViewController;
- (BJLChatViewController *)chatViewController {
    return _chatViewController ?: (_chatViewController = ({
        BJLChatViewController *controller = [[BJLChatViewController alloc] initWithRoom:self.room];
        controller;
    }));
}

@synthesize questionViewController = _questionViewController;
- (BJLQuestionViewController *)questionViewController {
    return _questionViewController ?: (_questionViewController = ({
        BJLQuestionViewController *controller = [[BJLQuestionViewController alloc] initWithRoom:self.room];
        bjl_weakify(self, controller);
        [controller setShowMessageCallback:^(NSString * _Nonnull message) {
            bjl_strongify(self, controller);
            // !!! 延迟一小段时间提示错误
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showProgressHUDWithText:message superView:controller.view];
            });
        }];
        [controller setHideCallback:^{
            bjl_strongify(self, controller);
            [controller bjl_removeFromParentViewControllerAndSuperiew];
            [self.overlayViewController hide];
        }];
        controller;
    }));
    
}

@synthesize moreViewController = _moreViewController;
- (BJLMoreViewController *)moreViewController {
    return _moreViewController ?: (_moreViewController = ({
        BJLMoreViewController *controller = [[BJLMoreViewController alloc] initWithForTeacher:self.room.loginUser.isTeacher];
        bjl_weakify(self);
        [controller setNoticeCallback:^(id _Nullable sender) {
            bjl_strongify(self);
            [self.moreViewController bjl_removeFromParentViewControllerAndSuperiew];
            
            if (self.room.loginUser.isTeacherOrAssistant) {
                self.overlayViewController.prefersStatusBarHidden = NO;
                [self.overlayViewController showWithContentViewController:self.noticeEditViewController];
            }
            else {
                [self.overlayViewController showWithContentViewController:self.noticeViewController];
            }
        }];
        [controller setServerRecordingCallback:^(id _Nullable sender) {
            bjl_strongify(self);
            [self.moreViewController bjl_removeFromParentViewControllerAndSuperiew];
            
            BOOL wasRecording = self.room.serverRecordingVM.serverRecording;
            BJLError *error = [self.room.serverRecordingVM requestServerRecording:!wasRecording];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }];
        [controller setSettingsCallback:^(id _Nullable sender) {
            bjl_strongify(self);
            [self.moreViewController bjl_removeFromParentViewControllerAndSuperiew];
            [self.overlayViewController showWithContentViewController:self.settingsViewController];
        }];
        [controller setCloseCallback:^(id _Nullable sender) {
            bjl_strongify(self);
            [self.moreViewController bjl_removeFromParentViewControllerAndSuperiew];
        }];
        controller;
    }));
}

@synthesize noticeViewController = _noticeViewController;
- (BJLNoticeViewController *)noticeViewController {
    return _noticeViewController ?: (_noticeViewController = ({
        BJLNoticeViewController *controller = [[BJLNoticeViewController alloc] initWithRoom:self.room];
        controller;
    }));
}

@synthesize noticeEditViewController = _noticeEditViewController;
- (BJLNoticeEditViewController *)noticeEditViewController {
    return _noticeEditViewController ?: (_noticeEditViewController = ({
        BJLNoticeEditViewController *controller = [[BJLNoticeEditViewController alloc] initWithRoom:self.room];
        bjl_weakify(self);
        [controller setErrorCallback:^(NSString *errorMessage) {
            bjl_strongify(self);
            [self showProgressHUDWithText:errorMessage];
        }];
        controller;
    }));
}

@synthesize settingsViewController = _settingsViewController;
- (BJLSettingsViewController *)settingsViewController {
    return _settingsViewController ?: (_settingsViewController = ({
        BJLSettingsViewController *controller = [[BJLSettingsViewController alloc] initWithRoom:self.room];
        controller;
    }));
}

@synthesize imageViewController = _imageViewController;
- (BJLImageViewController *)imageViewController {
    return _imageViewController ?: (_imageViewController = ({
        BJLImageViewController *controller = [BJLImageViewController new];
        bjl_weakify(self);
        [controller setHideCallback:^(id _Nullable sender) {
            bjl_strongify(self);
            [UIView animateWithDuration:BJLAnimateDurationM
                             animations:^{
                                 self.imageViewController.view.alpha = 0.0;
                             }
                             completion:^(BOOL finished) {
                                 self.imageViewController.imageView.image = nil;
                                 [self.imageViewController bjl_removeFromParentViewControllerAndSuperiew];
                                 [self setNeedsStatusBarAppearanceUpdate];
                             }];
        }];
        controller;
    }));
}

@synthesize overlayViewController = _overlayViewController;
- (BJLOverlayViewController *)overlayViewController {
    return _overlayViewController ?: (_overlayViewController = ({
        BJLOverlayViewController *controller = [BJLOverlayViewController new];
        controller;
    }));
}

@synthesize loadingViewController = _loadingViewController;
- (BJLLoadingViewController *)loadingViewController {
    return _loadingViewController ?: (_loadingViewController = ({
        BJLLoadingViewController *controller = [[BJLLoadingViewController alloc] initWithRoom:self.room];
        controller;
    }));
}

@synthesize videoLoadingView = _videoLoadingView;
- (UIView *)videoLoadingView {
    return _videoLoadingView ?: (_videoLoadingView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"4A4A4A"];
        view.hidden = YES;
        [self.contentView insertSubview:view atIndex:0];
        view;
    }));
}

@synthesize videoLoadingImageView = _videoLoadingImageView;
- (UIImageView *)videoLoadingImageView {
    return _videoLoadingImageView ?: (_videoLoadingImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjl_imageNamed:@"bjl_ic_user_loading"]];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.videoLoadingView addSubview:imageView];
        imageView;
    }));
}

@end

#pragma mark -

@implementation BJLRoomViewController (BJLObservable)

- (BJLObservable)roomViewControllerEnterRoomSuccess:(BJLRoomViewController *)roomViewController {
    BJLMethodNotify((BJLRoomViewController *),
                    roomViewController);
    if ([self.delegate respondsToSelector:@selector(roomViewControllerEnterRoomSuccess:)]) {
        [self.delegate roomViewControllerEnterRoomSuccess:self];
    }
}

- (BJLObservable)roomViewController:(BJLRoomViewController *)roomViewController
          enterRoomFailureWithError:(BJLError *)error {
    BJLMethodNotify((BJLRoomViewController *, BJLError *),
                    roomViewController, error);
    if ([self.delegate respondsToSelector:@selector(roomViewController:enterRoomFailureWithError:)]) {
        [self.delegate roomViewController:self enterRoomFailureWithError:error];
    }
}

- (BJLObservable)roomViewController:(BJLRoomViewController *)roomViewController
                  willExitWithError:(nullable BJLError *)error {
    BJLMethodNotify((BJLRoomViewController *, BJLError *),
                    roomViewController, error);
    if ([self.delegate respondsToSelector:@selector(roomViewController:willExitWithError:)]) {
        [self.delegate roomViewController:self willExitWithError:error];
    }
}

- (BJLObservable)roomViewController:(BJLRoomViewController *)roomViewController
                   didExitWithError:(nullable BJLError *)error {
    BJLMethodNotify((BJLRoomViewController *, BJLError *),
                    roomViewController, error);
    if ([self.delegate respondsToSelector:@selector(roomViewController:didExitWithError:)]) {
        [self.delegate roomViewController:self didExitWithError:error];
    }
    [self clean];
}

@end

NS_ASSUME_NONNULL_END

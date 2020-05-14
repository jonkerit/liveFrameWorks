//
//  BJLIcLoadingViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/18.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase+Foundation.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcLoadingViewController.h"
#import "BJLIcAppearance.h"
#import "BJLIcLoadingBar.h"
#import "BJLIcLoadingIndicator.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLoadingViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BJLError *error;
@property (nonatomic, nullable) void (^reloadingCallback)(void);

@property (nonatomic, readwrite) UIButton *exitButton;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) UIImageView *logoImageView;
@property (nonatomic) BJLIcLoadingBar *loadingBar;
@property (nonatomic) BJLIcLoadingIndicator *loadingIndicator;

@property (nonatomic, nullable) UIView *loadFailedView;

@end

@implementation BJLIcLoadingViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeSubviewsAndConstraints];
    [self makeObservingForEnterRoom];
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor clearColor];
    // 毛玻璃效果
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIView *backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    [self.view addSubview:backgroundView];
    [backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    //loading背景图片
    self.backgroundImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = BJLKeypath(self, backgroundImageView);
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        imageView;
    });

    [self.view addSubview:self.backgroundImageView];
    [self.backgroundImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    UIView *blackCoverView = [UIView new];
    [blackCoverView setBackgroundColor:[UIColor bjl_colorWithHexString:@"#000000" alpha:0.5]];
    [self.backgroundImageView addSubview:blackCoverView];
    [blackCoverView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.backgroundImageView);
    }];

    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.bjl_centerY);
        make.height.equalTo(self.view).multipliedBy(1/5.0);
    }];
    
    // logo
    self.logoImageView = ({
        UIImageView *imageView = [UIImageView new];
//        imageView.image = [UIImage bjlic_imageNamed:@"bjl_loading_logo"];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        imageView;
    });
    [self.containerView addSubview:self.logoImageView];
    [self.logoImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.containerView);
        make.centerX.equalTo(self.containerView);
        make.width.equalTo(self.containerView).multipliedBy(1/5.0);
        make.height.equalTo(self.view).multipliedBy(1/11.0);
    }];
    
    // loading
    UIView *loadingView = ({
        UIView *view = [UIView new];
        view.layer.masksToBounds = NO;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.containerView addSubview:loadingView];
    [loadingView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.containerView);
        make.centerX.equalTo(self.containerView);
        make.width.equalTo(self.containerView).multipliedBy(25.0/64.0);
        make.height.equalTo(@(25.0));
    }];
    self.loadingBar = [BJLIcLoadingBar new];
    [self.containerView addSubview:self.loadingBar];
    [self.loadingBar bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(loadingView);
        make.height.equalTo(@(loadingBarHeight));
        make.left.right.equalTo(loadingView);
    }];
    self.loadingIndicator = [BJLIcLoadingIndicator new];
    [self.containerView addSubview:self.loadingIndicator];
    [self.loadingIndicator bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(loadingView);
        make.bottom.equalTo(self.loadingBar.bjl_top);
    }];
    
    // exit
    self.exitButton = ({
        UIButton *button = [BJLImageButton new];
        button.accessibilityLabel = BJLKeypath(self, exitButton);
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_statusbar_exit"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(exit) forControlEvents:UIControlEventTouchUpInside];
        bjl_return button;
    });
    [self.view addSubview:self.exitButton];
    [self.exitButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.top.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@40.0);
        make.width.equalTo(self.exitButton.bjl_height);
    }];
    
    // fire
    [self updateProgress:0.2];
}

- (void)makeLoadFailedView {
    self.loadFailedView = ({
        UIView *view = [UIView new];
        view.clipsToBounds = YES;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.loadFailedView];
    [self.loadFailedView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.containerView.bjl_bottom).offset(12.0);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@344.0);
        make.height.equalTo(self.view.bjl_height).multipliedBy(1/8.0).priorityHigh();
    }];
    
    UILabel *messageLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 2;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [self.loadFailedView addSubview:messageLabel];
    [messageLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.loadFailedView);
        make.top.equalTo(self.loadFailedView);
        make.height.equalTo(@40.0).priorityHigh();
    }];

    BOOL needRetry = !(self.error.code == BJLErrorCode_enterRoom_unsupportedClient
                       || self.error.code == BJLErrorCode_enterRoom_unsupportedDevice);
    BOOL conflict = (self.error.code == BJLErrorCode_enterRoom_loginConflict);
    UIButton *exitButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor whiteColor];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 4.0;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"我知道了" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(exit) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.loadFailedView addSubview:exitButton];
    [exitButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(messageLabel.bjl_bottom).offset(25.0);
        if (needRetry) {
            make.right.equalTo(self.loadFailedView.bjl_centerX).offset(-12.0);
        }
        else {
            make.centerX.equalTo(self.loadFailedView);
        }
        make.height.equalTo(@32.0).priorityHigh();
        make.width.equalTo(@160.0);
        make.bottom.equalTo(self.loadFailedView.bjl_bottom);
    }];
    
    if(needRetry) {
        UIButton *reloadingButton = ({
            UIButton *button = [UIButton new];
            button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 4.0;
            button.titleLabel.font = [UIFont systemFontOfSize:14.0];
            [button setTitle:(conflict ? @"进入教室" : @"刷新重试")  forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(reloading) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.loadFailedView addSubview:reloadingButton];
        [reloadingButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(messageLabel.bjl_bottom).offset(25.0);
            make.left.equalTo(self.loadFailedView.bjl_centerX).offset(12.0);
            make.height.equalTo(@32.0).priorityHigh();
            make.width.equalTo(@160.0);
            make.bottom.equalTo(self.loadFailedView.bjl_bottom);
        }];
    }
    
    NSString *message = @"哎呀出错了";
    NSString *detailMessage = [NSString stringWithFormat:@"\n%@，%@", self.error.localizedDescription, self.error.localizedFailureReason] ;
    switch (self.error.code) {
        case BJLErrorCode_enterRoom_roomIsFull:
            message = @"教室已满";
            detailMessage = @"\n该教室成员已满，无法进入教室";
            break;
            
        case BJLErrorCode_enterRoom_unsupportedClient:
            message = @"iOS端不支持";
            detailMessage = @"\niOS端不支持该班型，请使用PC客户端进入";
            break;
            
        case BJLErrorCode_enterRoom_unsupportedDevice:
            message = @"设备不支持";
            detailMessage = @"\n你的设备不支持该教室，请更换设备进入";
            break;
            
        case BJLErrorCode_enterRoom_forbidden:
            message = @"无法进入";
            detailMessage = @"\n你已被移出，无法再次进入教室";
            break;
            
        case BJLErrorCode_enterRoom_loginConflict:
            message = @"已有老师";
            detailMessage = @"\n继续进入将导致该老师强制下线";
            break;
        
        case BJLErrorCode_enterRoom_timeExpire:
            message = @"无法进入";
            detailMessage = @"\n教室已过期";
            break;
            
        default:
            break;
    }
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4.0;
    paragraphStyle.paragraphSpacing = 4.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *tipAttributedText = [[NSAttributedString alloc] initWithString:message
                                                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                                                                         NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                                         NSParagraphStyleAttributeName : paragraphStyle}];
    [attributedText appendAttributedString:tipAttributedText];
    
    NSAttributedString *detailAttributedText = [[NSAttributedString alloc] initWithString:detailMessage
                                                                               attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12.0],
                                                                                            NSForegroundColorAttributeName : [UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0]}];
    [attributedText appendAttributedString:detailAttributedText];
    
    messageLabel.attributedText = attributedText;
}

#pragma mark - observing

- (void)makeObservingForEnterRoom {
    bjl_weakify(self);
    if (!self.room) {
        return;
    }
    
    [self bjl_kvo:BJLMakeProperty(self.room, loadingVM)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.loadingVM) {
                 [self makeObservingForLoadingVM:self.room.loadingVM isReload:NO];
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room, featureConfig)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
               return !!value;
           }
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             NSURL *url = [NSURL URLWithString:self.room.featureConfig.loadingLogoURLString ?:@""];
             [self.logoImageView bjl_setImageWithURL:url placeholder:nil completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                 bjl_strongify(self);
                 if(image) {
                     [self.logoImageView setImage:image];
                 }
                 else {
                     [self.logoImageView setImage:[UIImage bjlic_imageNamed:@"bjl_loading_logo"]];
                 }
             }];

             if (self.room.featureConfig) {
                 [self.backgroundImageView bjl_setImageWithURL:[NSURL URLWithString:self.room.featureConfig.loadingBackgroundURLString ?:@""]];

                 [self.loadingIndicator updateLoadingInficatorColor:[UIColor bjl_colorWithHexString:self.room.featureConfig.loadingTextColor]];
                 [self.loadingBar updateLoadingColor:[UIColor bjl_colorWithHexString:self.room.featureConfig.loadingBarColor]];
             }
             return YES;
         }];

    [self.room setReloadingBlock:^(BJLLoadingVM *reloadingVM, void (^callback)(BOOL reload)) {
        bjl_strongify(self);
        [self makeObservingForLoadingVM:reloadingVM isReload:YES];
        callback(YES);
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomFailureWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 self.error = error;
                 [self updateProgress:-1.0];
                 return YES;
             }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.loadingBar, progressState),
                         BJLMakeProperty(self.loadingIndicator, progressState)]
              observer:^(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  if (self.loadingIndicator.progressState == BJLIcLoadingStateSuccess
                      && self.loadingBar.progressState == BJLIcLoadingStateSuccess) {
                      [self hide];
                  }
                  else if (self.loadingIndicator.progressState == BJLIcLoadingStateFailed
                           && self.loadingBar.progressState == BJLIcLoadingStateFailed) {
                      [self makeLoadFailedView];
                  }
              }];
}

- (void)makeObservingForLoadingVM:(nullable BJLLoadingVM *)loadingVM isReload:(BOOL)reload {
    bjl_weakify(self);
    loadingVM.suspendBlock = ^(BJLLoadingStep step,
                                         BJLLoadingSuspendReason reason,
                                         BJLError *error,
                                         void (^continueCallback)(BOOL isContinue)) {
        bjl_strongify(self);
        // 成功
        if (reason != BJLLoadingSuspendReason_errorOccurred) {
            continueCallback(YES);
            return;
        }
        // 失败，直接报错，没有重试步骤
        CGFloat progress = 0.2;
        switch (step) {
            case BJLLoadingStep_checkNetwork:
                progress = 0.2;
                break;
                
            case BJLLoadingStep_loadRoomInfo:
                progress = 0.25;
                break;
                
            case BJLLoadingStep_connectMasterServer:
                progress = 0.5;
                break;
                
            case BJLLoadingStep_connectRoomServer:
                progress = 0.75;
                break;
                
            default:
                break;
        }
        self.error = error;
        [self updateProgress:progress];
        [self updateProgress:-1.0];
        self.reloadingCallback = ^{
            bjl_strongify(self);
            self.reloadingCallback = nil;
            if (self.loadFailedView) {
                [self.loadFailedView removeFromSuperview];
                self.loadFailedView = nil;
                [self.loadingBar resume];
                [self.loadingIndicator resume];
                // fire
                if (step == BJLLoadingStep_checkNetwork) {
                    [self updateProgress:0.0];
                }
            }
            continueCallback(YES);
        };
    };
    
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingUpdateProgress:)
             observer:(BJLMethodObserver)^BOOL(CGFloat progress) {
                 bjl_strongify(self);
                 if (progress <= 0) {
                     return YES;
                 }
                 if (!reload && progress == 0.5) {
                     if (self.loadRoomInfoSucessCallback) {
                         self.loadRoomInfoSucessCallback();
                     }
                 }
                 [self updateProgress:progress];
                 if (progress >= 1.0) {
                     // 0.5s 后还在 loading 动画的情况下直接进入
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                         [self hide];
                     });
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingFailureWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 self.error = error;
                 [self updateProgress:-1.0];
                 return YES;
             }];
}

#pragma mark - actions

- (void)updateProgress:(CGFloat)progress {
    [self.loadingBar updateProgress:progress];
    [self.loadingIndicator updateProgress:progress];
}

// 隐藏 loading
- (void)hide {
    if (self && self.viewLoaded && self.view.window && !self.view.hidden) {
        [self bjl_removeFromParentViewControllerAndSuperiew];
        if (self.hideCallback) {
            self.hideCallback();
        }
    }
}

- (void)exit {
    if (self.exitCallback) {
        self.exitCallback();
    }
}

- (void)reloading {
    if (self.reloadingCallback) {
        self.reloadingCallback();
    }
}

@end

NS_ASSUME_NONNULL_END

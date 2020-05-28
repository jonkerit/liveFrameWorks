//
//  BJLScMediaInfoView.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/19.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScMediaInfoView.h"
#import "BJLScVideoPlaceholderView.h"
#import "BJLScAppearance.h"

@interface BJLScMediaInfoView ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BOOL recording;
@property (nonatomic, readwrite) BJLUser *user;
@property (nonatomic, readwrite, nullable) BJLMediaUser *mediaUser;
@property (nonatomic) UIView *containerView;
@property (nonatomic) BJLScVideoPlaceholderView *overlayImageContainerView, *videoPlaceholderView;
@property (nonatomic, weak) UIView *videoView;
@property (nonatomic) UIButton *likeButton;
@property (nonatomic) UIView *infoView;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic, nullable) NSString *imageURLString;// 用户未开视频时的占位图url
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSInteger times;
// 加载中的loading
@property (nonatomic) id<BJLObservation> mediaUserObservation;
@property (nonatomic) UIView *videoLoadingView;
@property (nonatomic) UIImageView *videoLoadingImageView;
@property (nonatomic) BOOL animating;



@end

@implementation BJLScMediaInfoView

- (instancetype)initWithRoom:(BJLRoom *)room user:(__kindof BJLUser *)user {
    if (self = [super init]) {
        if (!user.ID || [user.ID isEqualToString:room.loginUser.ID]) {
            self.recording = YES;
        }
        else {
            self.recording = NO;
            self.mediaUser = bjl_as(user, BJLMediaUser);
        }
        self.room = room;
        self.user = user;
        self.imageURLString = user.cameraCover;
        self.videoView = self.recording ? self.room.recordingView : [self.room.playingVM playingViewForUserWithID:self.mediaUser.ID mediaSource:self.mediaUser.mediaSource];
        self.isFullScreen = NO;
        [self makeSubviewsAndConstraints];
        [self makeObserving];
    }
    return self;
}

- (void)destroy {
    [self bjl_stopAllKeyValueObserving];
    [self bjl_stopAllMethodParametersObserving];
}

#pragma mark - subview

- (void)makeSubviewsAndConstraints {
    self.containerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    [self addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    [self.videoView removeFromSuperview];
    [self.containerView addSubview:self.videoView];
    [self.videoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    
    // 视频加载占位图
    self.videoLoadingView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, videoLoadingView);
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"4A4A4A"];
        view.hidden = YES;
        view;
    });
    [self addSubview:self.videoLoadingView];
    [self.videoLoadingView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    self.videoLoadingImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_user_loading"]];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.accessibilityLabel = BJLKeypath(self, videoLoadingImageView);
        imageView;
    });
    [self.videoLoadingView addSubview:self.videoLoadingImageView];
    [self.videoLoadingImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.videoLoadingView);
        make.width.height.equalTo(self.videoLoadingView).multipliedBy(0.4);
    }];

    // 用户未打开摄像头的占位
    self.overlayImageContainerView = ({
        BJLScVideoPlaceholderView *view = [[BJLScVideoPlaceholderView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_videoClose"] tip:@"未打开摄像头"];
        view.accessibilityLabel = BJLKeypath(self, overlayImageContainerView);
        view.hidden = YES;
        view;
    });
    [self addSubview:self.overlayImageContainerView];
    [self.overlayImageContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    // 主动关闭用户了用户摄像头的占位
    self.videoPlaceholderView = ({
        BJLScVideoPlaceholderView *view = [[BJLScVideoPlaceholderView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjlOpenTeacherVedio"] tip:@""];
        view.accessibilityLabel = BJLKeypath(self, videoPlaceholderView);
        view.hidden = YES;
        view;
    });
    [self addSubview:self.videoPlaceholderView];
    [self.videoPlaceholderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    self.infoView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        view.accessibilityLabel = BJLKeypath(self, infoView);
#pragma mark --- 修改UI
        self.infoView.hidden = YES;
        view;
    });
    [self addSubview:self.infoView];
    [self.infoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self);
        make.height.equalTo(@24.0);
    }];
    
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor whiteColor];
        label;
    });
    [self.infoView addSubview:self.nameLabel];
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.infoView).offset(4.0);
        make.right.equalTo(self.infoView).offset(-4.0);
        make.top.bottom.equalTo(self.infoView);
    }];
    
    self.likeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.accessibilityLabel = BJLKeypath(self, likeButton);
        button.titleLabel.font = [UIFont systemFontOfSize:10.0];
        button.layer.cornerRadius = 6.0;
        button.layer.masksToBounds = YES;
        button.enabled = self.room.loginUser.isTeacherOrAssistant;
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 4.0, 0.0, 4.0);
        [button setTitle:nil forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor bjl_dimColor]] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#F7E123"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_like_icon"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(sendLikeForCurrentUser) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self addSubview:self.likeButton];
    [self.likeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(4.0);
        make.bottom.equalTo(self.infoView.bjl_top).offset(-3.0);
        make.height.equalTo(@(12.0));
    }];
    
    [self updateCurrentUserAndUpdateViewIfNeed:YES];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    /* 1、老师助教隐藏点赞按钮，
       2、登录用户是学生，视频是学生视频，并且点赞数为0，隐藏点赞按钮 */
    NSInteger likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.user.number];
    BOOL hideLikeButton = !self.user || self.user.isTeacherOrAssistant || (self.room.loginUser.isStudent && !likeCount);
    [self updateWithLikeCount:likeCount hidden:hideLikeButton];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    // mediaUser 更新
    if (self.recording) {
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room.recordingVM, recordingAudio),
                             BJLMakeProperty(self.room.recordingVM, recordingVideo)]
                  observer:(BJLPropertiesObserver)^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self updateCurrentUserAndUpdateViewIfNeed:YES];
        }];
    }
    else {
        // 无 mediaUser 的情况认为是未开音视频的主摄像头用户
        if (self.mediaUser.cameraType == BJLCameraType_main || !self.mediaUser) {
            [self bjl_kvo:BJLMakeProperty(self.room.mainPlayingAdapterVM, playingUsers)
                 observer:^BOOL(NSArray<BJLMediaUser *> *  _Nullable playingUsers, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                     bjl_strongify(self);
                     [self updateCurrentUserWithPlayingUsers:playingUsers];
                     return YES;
                 }];
        }
        else {
            [self bjl_kvo:BJLMakeProperty(self.room.extraPlayingAdapterVM, playingUsers)
                 observer:^BOOL(NSArray<BJLMediaUser *> *  _Nullable playingUsers, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                     bjl_strongify(self);
                     [self updateCurrentUserWithPlayingUsers:playingUsers];
                     return YES;
                 }];
        }
        if ([self is1V1Class]) {
            // 一开始在 playingUsers 中就打开摄像头和麦克风，但是还未加入到 videoPlayingUsers 中的情况
            [self bjl_kvo:BJLMakeProperty(self.room.playingVM, videoPlayingUsers)
                 observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                bjl_strongify(self);
                if (!self.recording) {
                    [self updateCloseVideoPlaceholderHidden:[self isVideoPlayingUser]];
                }
                return YES;
            }];
        }
    }
    
    // 全屏状态
    [self bjl_kvo:BJLMakeProperty(self, isFullScreen)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        return value != oldValue;
    } observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
        [self.overlayImageContainerView updateTip:nil font:[UIFont systemFontOfSize:self.isFullScreen ? 24.0 : 12.0]];
        [self.videoPlaceholderView updateTip:nil font:[UIFont systemFontOfSize:self.isFullScreen ? 24.0 : 12.0]];
        [self.overlayImageContainerView updateImage:(self.isFullScreen ? [UIImage bjlsc_imageNamed:@"bjl_sc_videoClose_large"] : [UIImage bjlsc_imageNamed:@"bjl_sc_videoClose"]) size:(self.isFullScreen ? BJLScLargeOverlayImageSize : iPad ? BJLScSmallOverlayImageSizeIPad : BJLScSmallOverlayImageSizeIPhone)];
        if (!self.imageURLString.length) {
            [self.videoPlaceholderView updateImage:(self.isFullScreen ? [UIImage bjlsc_imageNamed:@"bjl_sc_videoClose_large"] : [UIImage bjlsc_imageNamed:@"bjl_sc_videoClose"]) size:(self.isFullScreen ? BJLScLargeOverlayImageSize : iPad ? BJLScSmallOverlayImageSizeIPad : BJLScSmallOverlayImageSizeIPhone)];
        }
        else {
            [self updateVideoPlaceholderViewImageWithimageURLString:self.imageURLString];
        }
        return YES;
    }];
    
    // 切换主讲
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, currentPresenter)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return (old // 默认主讲不提示
                       && now // 老师掉线不提示
                       && old != now
                       && ![now isSameUser:old]);
           }
         observer:^BOOL(BJLUser * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateCurrentUserAndUpdateViewIfNeed:YES];
             return YES;
         }];
    
    // loading 状态
    [self bjl_kvo:BJLMakeProperty(self, mediaUser)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
               bjl_strongify(self);
               if (self.mediaUser) {
                   [self remakeObservingForUser:self.mediaUser];
               }
               return BJLKeepObserving;
           }];
    
    // 收到点赞
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForUserNumber:records:)
             observer:^BOOL(NSString *userNumber, NSDictionary<NSString *, NSNumber *> *records) {
        bjl_strongify(self);
        if ([self.user.number isEqualToString:userNumber]) {
            NSInteger likeCount = [self.room.roomVM.likeList bjl_integerForKey:userNumber];
            BOOL hideLikeButton = self.user.isTeacherOrAssistant || (self.room.loginUser.isStudent && !likeCount);
            [self updateWithLikeCount:likeCount hidden:hideLikeButton];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, likeRecordsDidOverwrite:)
             observer:^BOOL{
        bjl_strongify(self);
        NSInteger likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.user.number];
        BOOL hideLikeButton = !self.user || self.user.isTeacherOrAssistant || (self.room.loginUser.isStudent && !likeCount);
        [self updateWithLikeCount:likeCount hidden:hideLikeButton];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didRecieveUserCameraCover:userNumber:) observer:^BOOL(NSString *imageURLString, NSString *userNumber) {
        bjl_strongify(self);
        // 目前限制只有老师背景可以修改
        if ([userNumber isEqualToString:self.user.number] && self.user.isTeacher) {
            self.imageURLString = imageURLString;
            [self updateVideoPlaceholderViewImageWithimageURLString:imageURLString];
        }
        return YES;
    }];
}

- (void)updateVideoPlaceholderViewImageWithimageURLString:(nullable NSString *)imageURLString {
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    UIImage *placeholder = (self.isFullScreen ? [UIImage bjlsc_imageNamed:@"bjl_sc_videoClose_large"] : [UIImage bjlsc_imageNamed:@"bjl_sc_videoClose"]);
    CGFloat size = (self.isFullScreen ? BJLScLargeOverlayImageSize : iPad ? BJLScSmallOverlayImageSizeIPad : BJLScSmallOverlayImageSizeIPhone);
    
    if (imageURLString.length) {
        [self.videoPlaceholderView updateImageWithURLString:imageURLString placeholder:placeholder placeholderSize:size];
    }
    else {
        [self.videoPlaceholderView updateImage:placeholder size:size];
    }
}

- (void)remakeObservingForUser:(BJLMediaUser *)mediaUser {
    [self.mediaUserObservation stopObserving];
    self.mediaUserObservation = nil;
    bjl_weakify(self);
    self.mediaUserObservation = [self bjl_kvo:BJLMakeProperty(self.mediaUser, isLoading)
                                     observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                                           bjl_strongify(self);
                                           [self updateLoadingViewHidden:!self.mediaUser.isLoading];
                                           return BJLKeepObserving;
                                       }];
}

#pragma mark - action

- (void)sendLikeForCurrentUser {
    [self.room.roomVM sendLikeForUserNumber:self.user.number];
}

#pragma mark - update

- (void)updateCurrentUserWithPlayingUsers:(NSArray<BJLMediaUser *> *)playingUsers {
    for (BJLMediaUser *user in playingUsers) {
        if ([self.mediaUser.ID isEqualToString:user.ID]
            || (!self.mediaUser && [self.user.ID isEqualToString:user.ID])) {
            if ([self needUpdateWithMediaUser:user]) {
                BOOL needUpdateView = [self needUpdateVideoViewWithMediaUser:user];
                self.mediaUser = user;
                [self updateCurrentUserAndUpdateViewIfNeed:needUpdateView];
            }
            break;
        }
    }
}

- (void)updateCurrentUserAndUpdateViewIfNeed:(BOOL)needUpdateView {
    
    if (needUpdateView) {
        [self.videoView removeFromSuperview];
        
        self.videoView = self.recording ? self.room.recordingView : [self.room.playingVM playingViewForUserWithID:self.mediaUser.ID mediaSource:self.mediaUser.mediaSource];
        
        if (self.videoView) {
            if (self.videoView.superview != self.containerView) {
                [self.videoView removeFromSuperview];
            }
            [self.containerView insertSubview:self.videoView atIndex:0];
            [self.videoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.containerView);
            }];
        }
        if (!self.recording) {
            [self updateCloseVideoPlaceholderHidden:[self isVideoPlayingUser]];
        }
    }
#pragma mark --- 修改了老师姓名展示
    if (self.recording) {
//         self.nameLabel.text = [self getShowingTitleOfUser:self.user];
//        self.overlayImageContainerView.hidden = self.room.recordingVM.recordingVideo;
        self.overlayImageContainerView.hidden = YES;
        if (self.animating && !self.room.recordingVM.recordingVideo) {
            [self updateLoadingViewHidden:YES];
        }
    }
    else {
//        self.nameLabel.text = [self getShowingTitleOfUser:self.mediaUser];
//        self.overlayImageContainerView.hidden = self.mediaUser.videoOn;
        self.overlayImageContainerView.hidden = YES;
        if (self.animating && !self.mediaUser.videoOn) {
            [self updateLoadingViewHidden:YES];
        }
    }
}

- (void)updateCloseVideoPlaceholderHidden:(BOOL)hidden {
    self.videoPlaceholderView.hidden = hidden;
    self.infoView.hidden = NO;
    self.nameLabel.hidden = NO;
    self.nameLabel.text = hidden?@"点击打开省流量模式":@"点击关闭省流量模式";
//    self.times = 3;
//    [self.timer fire];
}

- (void)updateLoadingViewHidden:(BOOL)hidden {
    if (!self.videoLoadingView) {
        return;
    }
    if (self.videoLoadingView.hidden == hidden) {
        return;
    }
    self.videoLoadingView.hidden = hidden;
    if (!self.videoLoadingView.hidden) {
        if (self.animating) {
            return;
        }
        // 显示旋转动画
        [self.videoLoadingView.layer removeAllAnimations];
        [self.videoLoadingImageView.layer removeAllAnimations];
        self.videoLoadingImageView.transform = CGAffineTransformIdentity;
        self.animating = YES;
        [self startLoadingAnimationWithAngle:0.0];
    }
    else {
        self.animating = NO;
        [self.videoLoadingView.layer removeAllAnimations];
        [self.videoLoadingImageView.layer removeAllAnimations];
    }
}

- (void)startLoadingAnimationWithAngle:(CGFloat)angle {
    CGFloat nextAngle = angle + 20.0;
    CGAffineTransform endAngle = CGAffineTransformMakeRotation(angle * (M_PI / 180.0f));
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.videoLoadingImageView.transform = endAngle;
    } completion:^(BOOL finished) {
        if (self.animating) {
            [self startLoadingAnimationWithAngle:nextAngle];
        }
    }];
}

- (void)updateWithLikeCount:(NSInteger)count hidden:(BOOL)hidden {
    [self.likeButton setTitle:count ? [NSString stringWithFormat:@"%ld", (long)count] : nil forState:UIControlStateNormal];
    self.likeButton.hidden = hidden;
}

#pragma mark - getter

/**
 老师用户永远展示备注，优先展示标签，没有标签则展示 (老师)
 助教为主讲时，展示(主讲), 否则展示标签,没有标签就不展示
 */
- (NSString *)getShowingTitleOfUser:(__kindof BJLUser *)user {
    NSString *roleName = [self roleNameOfUser:user];
    if (roleName) {
        return [NSString stringWithFormat:@"%@(%@)", user.displayName, roleName];
    }
    return user.displayName;
}

- (NSString * _Nullable)roleNameOfUser:(__kindof BJLUser *)user {
    
    BJLFeatureConfig *config = self.room.featureConfig;
    if (user.isTeacher) {
        return config.teacherLabel ?: @"老师";
    }
    else if (user.isAssistant && [user isSameCameraUser:self.room.onlineUsersVM.currentPresenter]) {
        return @"主讲";
    }
    else if (user.isAssistant && ![user isSameCameraUser:self.room.onlineUsersVM.currentPresenter]) {
        return (config.assistantLabel) ?: nil;
    }
    return nil;
}

// 是否需要更新 user 数据
- (BOOL)needUpdateWithMediaUser:(BJLMediaUser *)mediaUser {
    // 如果当前是未开音视频的主摄像头用户，更新数据
    if (!self.mediaUser) {
        return YES;
    }
    if ([self.mediaUser.mediaID isEqualToString:mediaUser.mediaID]
        && self.mediaUser.videoOn == mediaUser.videoOn
        && self.mediaUser.audioOn == mediaUser.audioOn
        && [self.mediaUser.name isEqualToString:mediaUser.name]) {
        return NO;
    }
    return YES;
}

- (BOOL)needUpdateVideoViewWithMediaUser:(BJLMediaUser *)mediaUser {
    // 如果当前是未开音视频的主摄像头用户，更新数据
    if (!self.mediaUser) {
        return YES;
    }
    if ([self.mediaUser.mediaID isEqualToString:mediaUser.mediaID]
        && self.mediaUser.mediaSource == mediaUser.mediaSource
        && self.mediaUser.videoOn == mediaUser.videoOn) {
        return NO;
    }
    return YES;
}

- (BOOL)isSameCameraTypeUser:(BJLMediaUser *)user {
    if (self.recording) {
        return [self.user.ID isEqualToString:user.ID];
    }
    else {
        return [self.user.ID isEqualToString:user.ID] && (self.mediaUser.cameraType == user.cameraType);
    }
}

- (BOOL)isVideoPlayingUser {
    // 判断是否是正在播放视频的用户必须存在 mediaUser
    for (BJLMediaUser *user in [self.room.playingVM.videoPlayingUsers copy]) {
        if ([user isSameMediaUser:self.mediaUser]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)is1V1Class {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return self.room.roomInfo.roomType == BJLRoomType_1v1Class || self.room.roomInfo.roomType == BJLRoomType_1to1;
#pragma clang diagnostic pop
}

- (void)timerRepAction{
    self.times--;
    if (self.times == 0) {
        // 隐藏
        self.infoView.hidden = YES;
        self.nameLabel.hidden = YES;
        [self.timer invalidate];
        self.timer = nil;
    }
}
- (NSTimer *)timer{
    if (!_timer) {
        if (@available(iOS 10.0, *)) {
            bjl_weakify(self);
            _timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                bjl_strongify(self);
                [self timerRepAction];
            }];
        } else {
            _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerRepAction) userInfo:nil repeats:YES ];
        }
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    return _timer;
}
@end

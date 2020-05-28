//
//  BJLIcUserMediaInfoView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/10/8.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcUserMediaInfoView.h"
#import "BJLIcUserMediaInfoView+private.h"
#import "BJLIcUserMediaInfoView+padUserVideoUpside.h"
#import "BJLIcUserMediaInfoView+padUserVideoDownside.h"
#import "BJLIcUserMediaInfoView+pad1to1.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserMediaInfoView ()

@property (nonatomic) BOOL animating;

@end

@implementation BJLIcUserMediaInfoView

- (instancetype)initWithUser:(BJLMediaUser *)user room:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
        self->_user = user;
        self->_mediaID = user.mediaID;
        self->_isRecording = [user.ID isEqualToString:self.room.loginUser.ID];
        self.videoView = self.isRecording ? self.room.recordingView : [self.room.playingVM playingViewForUserWithID:user.ID mediaSource:user.mediaSource];
        
        self.clipsToBounds = YES;
        self.isNetworkMessageShowing = NO;
        
        self.lossRateDictionary = [NSMutableDictionary new];
        self.presenterLossRateDictionary = [NSMutableDictionary new];
        [self makeSubviews];
        [self makeObserving];
        
        bjl_weakify(self);
        UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            [self showUserOperateView:[gesture locationInView:self]];
        }];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)updateParentViewController:(UIViewController *)parentViewController {
    self.parentViewController = parentViewController;
}

- (void)dealloc {
    [self stopLossRateObservingTimer];
    
    // 由于业务逻辑(1V1的班型,用户名字等信息未添加在当前界面上),销毁时,需要remove
    if (self.infoGroupView && self.infoGroupView.superview && self.infoGroupView.superview != self) {
        [self.infoGroupView removeFromSuperview];
    }
}

#pragma mark - subviews

- (void)makeSubviews {
    // 毛玻璃背景
    BJLIcTemplateType templateType = self.room.roomInfo.interactiveClassTemplateType;
    UIView *effectView = ({
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.userInteractionEnabled = NO;
        effectView.accessibilityLabel = @"effectView";
        effectView;
    });
    [self addSubview:effectView];
    [effectView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    // 视频容器
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = (BJLIcTemplateType_1v1 == templateType ? [UIColor blackColor] : [UIColor clearColor]);
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    [self addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    // 视频加载占位图
    self.videoLoadingView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"4A4A4A"];
        view.hidden = YES;
        view;
    });
    [self addSubview:self.videoLoadingView];
    [self.videoLoadingView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    self.videoLoadingImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlic_imageNamed:@"bjl_ic_user_loading"]];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.videoLoadingView addSubview:self.videoLoadingImageView];
    [self.videoLoadingImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.videoLoadingView);
        make.width.height.equalTo(self.videoLoadingView).multipliedBy(0.4);
    }];
    
    // 视频关闭占位图
    self.videoOffImageView = ({
        UIImageView *imageView = [self imageViewWithName:@"bjl_ic_user_video_off"];
        imageView.hidden = YES;
        imageView.accessibilityLabel = BJLKeypath(self, videoOffImageView);
        imageView.backgroundColor = [UIColor blackColor];
        imageView;
    });
    [self addSubview:self.videoOffImageView];
    [self.videoOffImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        (BJLIcTemplateType_1v1 == templateType ? make.center : make.edges).equalTo(self);
    }];
    
    // 纯音频占位图
    self.audioOnlyImageView = ({
        UIImageView *imageView = [self imageViewWithName:@"bjl_ic_user_placeholder"];
        imageView.hidden = YES;
        imageView.backgroundColor = [UIColor blackColor];
        imageView.accessibilityLabel = BJLKeypath(self, audioOnlyImageView);
        imageView;
    });
    [self addSubview:self.audioOnlyImageView];
    [self.audioOnlyImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        (BJLIcTemplateType_1v1 == templateType ? make.center : make.edges).equalTo(self);
    }];

    if (BJLIcTemplateType_1v1 == templateType) {
        [self makePad1to1Subviews];
    }
    else if (BJLIcTemplateType_userVideoDownside == templateType) {
        [self makePadUserVideoDownsideSubviews];
    }
    else {
        [self  makePadUserVideoUpsideSubviews];
    }
    
    // 初始化时根据 user 状态设置音频状态
    UIImage *image = self.user.audioOn ? [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_0"] : [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_off"];
    self.audioLevelView.image = image;
    // 隐藏非主摄像头的信息视图
    if (self.user.mediaSource != BJLMediaSource_mainCamera) {
        self.infoGroupView.hidden = YES;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    /* 1、老师助教隐藏点赞按钮，
       2、登录用户是学生，视频是学生视频，并且点赞数为0，隐藏点赞按钮 */
    NSInteger likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.user.number];
    BOOL hideLikeButton = !self.user || self.user.isTeacherOrAssistant || (self.room.loginUser.isStudent && !likeCount);
    [self updateWithLikeCount:likeCount hidden:hideLikeButton];
}

#pragma mark - observers

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingViewAspectRatioChanged:forUser:)
             observer:(BJLMethodObserver)^BOOL(CGFloat ratio, BJLMediaUser *user) {
                 bjl_strongify(self);
                 if ([user.mediaID isEqualToString:self.user.mediaID]
                     && self.videoView.superview != self) {
                     // !!!: TODO: 父视图非自己，不作处理，临时解决多个 mediaInfoView 抢视频视图的问题, 弱网环境存在多个 mediaInfoView 的问题待解决
                     [self updateVideoViewConstranints];
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidUpdate:old:)
             observer:(BJLMethodFilter)^(BJLMediaUser * _Nullable user, BJLMediaUser * _Nullable old) {
                 bjl_strongify(self);
                 [self updateCurrentUser];
                 // 开音频的时候默认最小音量的图标
                 if ([user.mediaID isEqualToString:self.user.mediaID]) {
                     UIImage *image = user.audioOn ? [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_0"] : [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_off"];
                     self.audioLevelView.image = image;
                 }
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if ([self.user.ID isEqualToString:self.room.loginUser.ID]) {
                 UIImage *image = self.room.recordingVM.recordingAudio ? [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_0"] : [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_off"];
                 self.audioLevelView.image = image;
             }
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, volumeDidUpdateWithUser:volume:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat volume){
                bjl_strongify(self);
                if (user.mediaSource == BJLMediaSource_mainCamera
                    && [user.mediaID isEqualToString:self.user.mediaID]
                    && self.user.audioOn) {
                    self.audioLevelView.image = [self imageWithAudioVolume:volume];
                }
                return YES;
             }];
     
    [self restartLossRateObservingTimer];
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, mediaLossRateDidUpdateWithUser:videoLossRate:audioLossRate:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat videoLossRate, CGFloat audioLossRate) {
                 bjl_strongify(self);
                 // 目前只统计所有用户主摄流的丢包
                 if(user.mediaSource != BJLMediaSource_mainCamera) {
                     return YES;
                 }
                 CGFloat packageLossRate = MIN(MAX(0.0, videoLossRate), 100.0);
                 NSString *userKey = [self userLossRateKeyWithUserID:user.ID mediaSource:user.mediaSource];
                 NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                 if (!lossRateArray) {
                     lossRateArray = [NSMutableArray new];
                 }
                 NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                 NSDictionary<NSNumber *, NSNumber *> *lossRateDic = [NSDictionary dictionaryWithObject:@(packageLossRate) forKey:@(timeInterval)];
                 [lossRateArray bjl_addObject:lossRateDic];
                 [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, didReceivePresenterLossRate:isVideo:userID:mediaSource:)
               filter:^BOOL{
                   bjl_strongify(self);
                   return !self.room.loginUserIsPresenter;
               }
             observer:(BJLMethodObserver)^BOOL(CGFloat lossRate, BOOL isVideo, NSString *userID, BJLMediaSource mediaSourcce) {
                 bjl_strongify(self);
                 if(mediaSourcce != BJLMediaSource_mainCamera) {
                     return YES;
                 }

                 NSString *userKey = [self userLossRateKeyWithUserID:userID mediaSource:mediaSourcce];
                 NSMutableArray<NSDictionary *> *lossRateArray = [[self.presenterLossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                 if (!lossRateArray) {
                     lossRateArray = [NSMutableArray new];
                 }
                 NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                 NSDictionary<NSNumber *, NSNumber *> *lossRateDic = [NSDictionary dictionaryWithObject:@(lossRate) forKey:@(timeInterval)];
                 [lossRateArray bjl_addObject:lossRateDic];
                 [self.presenterLossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                 return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidStartLoadingVideo:)
               filter:^BOOL(BJLMediaUser *playingUser) {
                   bjl_strongify(self);
                   return [self.user isSameMediaUser:playingUser];
               }
             observer:^BOOL{
                 bjl_strongify(self);
                 if (self.user.videoOn) {
                     [self updateLoadingViewHidden:NO];
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidFinishLoadingVideo:)
               filter:^BOOL(BJLMediaUser *playingUser) {
                   bjl_strongify(self);
                   return [self.user isSameMediaUser:playingUser];
               }
             observer:^BOOL{
                 bjl_strongify(self);
                 [self updateLoadingViewHidden:YES];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserGroupInfoDidChange:withGroupInfo:) filter:^BOOL(BJLUser *user, BJLUserGroup *groupInfo) {
        bjl_strongify(self);
        return [self.user isSameUserWithID:user.ID number:user.number];
    } observer:^BOOL(BJLUser *user, BJLUserGroup *groupInfo) {
        bjl_strongify(self);
        self.groupColorView.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color] ?: [UIColor clearColor];
        return BJLKeepObserving;
    }];
    
//    由于无法保证grouplist信息在拿到userlist之前获取到,所以需要监听groupList的变化
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, groupList) filter:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
//        bjl_strongify(self);
        return value != oldValue;
    } observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
            if (self.user.groupID == group.groupID) {
                self.groupColorView.backgroundColor = [UIColor bjl_colorWithHexString:group.color] ?: [UIColor clearColor];
                break;
            }
        }
        return BJLKeepObserving;
    }];
    
}

#pragma mark - weak network
- (NSString *)userLossRateKeyWithUserID:(NSString *)userID mediaSource:(BJLMediaSource)mediaSource {
    return [NSString stringWithFormat:@"%@-%td", userID, mediaSource];
}

- (BJLMediaSource)mediaSourceForUserLossRateKey:(NSString *)key {
    NSString *separator = @"-";
    BJLMediaSource mediaSource = BJLMediaSource_mainCamera;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        mediaSource = [key substringFromIndex:separatorRange.location + separatorRange.length].integerValue;
    }
    return mediaSource;
}
- (nullable NSString *)userIDForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    NSString *userID = nil;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        userID = [key substringToIndex:separatorRange.location];
    }
    return userID;
}

- (void)restartLossRateObservingTimer {
    [self stopLossRateObservingTimer];
    bjl_weakify(self);
    self.lossRateObservingTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify_ifNil(self) {
            [timer invalidate];
            return;
        }
        /* 弱网提示
         每个用户单独计算M秒内平均丢包率;
         自己上行有丢包时, 在自己的界面提示/直播间界面提示;
         自己下行有丢包时, ((有上行丢包&&下行丢包低于上行2倍) || 无上行)->提示自己网络差, (有上行&&上行无丢包 || 下行丢包高于上行两倍)-> 对方网络差
         */
        NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];

        NSString *userKey = [self userLossRateKeyWithUserID:self.room.loginUser.ID mediaSource:BJLMediaSource_mainCamera];
        NSMutableArray<NSDictionary *> *loginUserLossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
        NSInteger loginUserLossRateArrayCount = [loginUserLossRateArray count];
        CGFloat loginUserLossRate = 0.0f;
        if(loginUserLossRateArrayCount) {
            CGFloat totalLossRate = 0.0f;
            for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [loginUserLossRateArray copy]) {
                // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                    if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                        // 大于 lossRateRetainTime 的数据移除
                        [loginUserLossRateArray removeObject:lossRateDic];
                    }
                    else {
                        // 否则加入计算
                        totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                    }
                }
            }
           loginUserLossRate = (loginUserLossRateArray.count > 0) ? totalLossRate / loginUserLossRateArray.count : 0.0f;
            // 更新丢包率的字典
            [self.lossRateDictionary bjl_setObject:loginUserLossRateArray forKey:userKey];
        }
        BJLNetworkStatus loginUserLossRateStatus = [self netWorkStatusWithLossRate:loginUserLossRate];
        [self getPresenterLossRateInArrayWithUserKey:nil needUpdateAll:YES isUserPresenter:nil nowTimeInterval:nowTimeInterval];
        
        BOOL isloginUser = [self.user.ID isEqualToString:self.room.loginUser.ID];
        CGFloat currentUserLossRate = 0;
        BJLNetworkStatus currentUserLossRateStatus = BJLNetworkStatus_normal;
        if(!isloginUser) {
            // 当前窗口下行的丢包率
            userKey = [self userLossRateKeyWithUserID:self.user.ID mediaSource:self.user.mediaSource];
            NSMutableArray<NSDictionary *> *currentUserLossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
            NSInteger currentUserLossRateArrayCount = [currentUserLossRateArray count];
            if(currentUserLossRateArrayCount) {
                CGFloat totalLossRate = 0.0;
                for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [currentUserLossRateArray copy]) {
                    // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                    for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                        if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                            // 大于 lossRateRetainTime 的数据移除
                            [currentUserLossRateArray removeObject:lossRateDic];
                        }
                        else {
                            // 否则加入计算
                            totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                        }
                    }
                }
                currentUserLossRate = (currentUserLossRateArray.count > 0) ? totalLossRate / currentUserLossRateArray.count : 0.0f;
                // 更新丢包率的字典
                [self.lossRateDictionary bjl_setObject:currentUserLossRateArray forKey:userKey];
            }
            currentUserLossRateStatus = [self netWorkStatusWithLossRate:currentUserLossRate];

            // 如果往前下行窗口是主讲人窗口, 使用下行与广播取到的主讲人的上行作对比
            if(!self.room.loginUserIsPresenter && [self.user.ID isEqualToString:self.room.onlineUsersVM.currentPresenter.ID]) {
                BOOL isUserPresenter = NO;
                CGFloat presenterLossRate = [self getPresenterLossRateInArrayWithUserKey:userKey needUpdateAll:NO isUserPresenter:&isUserPresenter nowTimeInterval:nowTimeInterval];
                BJLNetworkStatus presenterLossRateStatus = [self netWorkStatusWithLossRate:presenterLossRate];
#if DEBUG
                [self showLossRateLabel:[NSString stringWithFormat:@"%.1f/%.1f", currentUserLossRate, presenterLossRate]];
#endif
                if(isUserPresenter && BJLNetworkStatus_normal != currentUserLossRateStatus && BJLNetworkStatus_normal != presenterLossRateStatus && currentUserLossRate <= presenterLossRate * 2) {
                    [self updateNetWorkStatus:presenterLossRateStatus];
                   }
                return;
            }
        }
        else {
            currentUserLossRate = loginUserLossRate;
        }
        currentUserLossRateStatus = [self netWorkStatusWithLossRate:currentUserLossRate];
        
        // 自己是否有上行
        BOOL hasUpPackage = self.room.recordingVM.recordingVideo || self.room.recordingVM.recordingAudio;
        // 自己上行是否丢包
        BOOL hasUpPackageLoss = hasUpPackage && loginUserLossRateStatus != BJLNetworkStatus_normal;
        BOOL shouldLoginUserShowWeakNetWork = hasUpPackageLoss;
        // 如果当前窗口为登录用户
        if(isloginUser) {
            for (NSString *userKey in [self.lossRateDictionary.allKeys copy]) {
                NSString *userID = [self userIDForUserLossRateKey:userKey];
//                BJLMediaSource mediaSourcce = [self mediaSourceForUserLossRateKey:userKey];
                // 读取每个用户的丢包率数据 ,除了当前登录用户和当前窗口用户
                if([userID isEqualToString:self.room.loginUser.ID]) {
                    continue;
                }

                NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                NSInteger count = lossRateArray.count;

                if (count > 0) {
                    CGFloat totalLossRate = 0.0;
                    for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [lossRateArray copy]) {
                        // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                        for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                            if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                                // 大于 lossRateObservingTimeInterval 的数据移除
                                [lossRateArray removeObject:lossRateDic];
                            }
                            else {
                                // 否则加入计算
                                totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                            }
                        }
                    }
                    // 更新丢包率的字典
                    [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                    CGFloat lossRate = (lossRateArray.count > 0) ? totalLossRate / lossRateArray.count : 0.0f;
                    BJLNetworkStatus status = [self netWorkStatusWithLossRate:lossRate];

                    BOOL isUserPresenter = NO;
                    CGFloat presenterLossRate = [self getPresenterLossRateInArrayWithUserKey:userKey needUpdateAll:NO isUserPresenter:&isUserPresenter nowTimeInterval:nowTimeInterval];
                    BJLNetworkStatus presenterLossRateStatus = [self netWorkStatusWithLossRate:presenterLossRate];
                    if(isUserPresenter) {
                        if((BJLNetworkStatus_normal != status && BJLNetworkStatus_normal != presenterLossRateStatus && lossRate > presenterLossRate * 2)
                           || (presenterLossRateStatus == BJLNetworkStatus_normal && status != BJLNetworkStatus_normal)) {
                            // 自己窗口展示弱网
                            shouldLoginUserShowWeakNetWork = YES;
                            loginUserLossRateStatus = MAX(status, loginUserLossRateStatus);
                        }
                    }
                    else {
                        // (下行丢包&&自己无上行推流) || (自己的视频窗口有丢包&&下行窗口低于上行两倍)
                        if((status != BJLNetworkStatus_normal && !hasUpPackage)
                           || (hasUpPackageLoss && lossRate <= loginUserLossRate * 2 && status != BJLNetworkStatus_normal)) {
                            // 自己窗口展示弱网
                            shouldLoginUserShowWeakNetWork = YES;
                            loginUserLossRateStatus = hasUpPackageLoss ? loginUserLossRateStatus : status;
                            break;
                        }
                    }
                }
            }
        }
#if DEBUG

        if(isloginUser) {
            [self showLossRateLabel:[NSString stringWithFormat:@"%.1f", loginUserLossRate]];
        }
        else {
            [self showLossRateLabel:[NSString stringWithFormat:@"%.1f/%.1f", currentUserLossRate, loginUserLossRate]];
        }
#endif
        if(isloginUser && shouldLoginUserShowWeakNetWork) {
            [self updateNetWorkStatus:loginUserLossRateStatus];
        }
        else if(!isloginUser) {
            // (非自己视频窗口有丢包 && 自己有上行无丢包) || (上下行均丢包&&当前窗口下行高于上行两倍)
            if(BJLNetworkStatus_normal != currentUserLossRateStatus
               && ((BJLNetworkStatus_normal == loginUserLossRateStatus && hasUpPackage)
                   || (BJLNetworkStatus_normal != loginUserLossRateStatus && currentUserLossRate > loginUserLossRate * 2))) {
                [self updateNetWorkStatus:currentUserLossRateStatus];
            }
        }
    }];
}

- (void)stopLossRateObservingTimer {
    if (self.lossRateObservingTimer || [self.lossRateObservingTimer isValid]) {
        [self.lossRateObservingTimer invalidate];
        self.lossRateObservingTimer = nil;
    }
}

- (CGFloat)getPresenterLossRateInArrayWithUserKey:(nullable NSString *)userKey needUpdateAll:(BOOL)needUpdateAll isUserPresenter:(nullable BOOL *)isUserPresenter nowTimeInterval:(NSTimeInterval)nowTimeInterval{
    CGFloat presenterLossRate = 0.0f;
    if(isUserPresenter) {
        *isUserPresenter = NO;
    }

    for (NSString *presenterUserKey in self.presenterLossRateDictionary.allKeys) {
        NSMutableArray<NSDictionary *> *presenterLossRateArray = [[self.presenterLossRateDictionary bjl_arrayForKey:presenterUserKey] mutableCopy];
        NSInteger presenterLossRateArrayCount = [presenterLossRateArray count];
        if(presenterLossRateArrayCount) {
            CGFloat totalLossRate = 0.0f;
            for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [presenterLossRateArray copy]) {
                // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                    if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                        // 大于 lossRateRetainTime 的数据移除
                        [presenterLossRateArray removeObject:lossRateDic];
                    }
                    else {
                        // 否则加入计算
                        totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                    }
                }
            }
            // 更新丢包率的字典
            [self.presenterLossRateDictionary bjl_setObject:presenterLossRateArray forKey:presenterUserKey];
            if(userKey && [presenterUserKey isEqualToString:userKey]) {
                if(isUserPresenter) {
                    *isUserPresenter = YES;
                }

                presenterLossRate = (presenterLossRateArray.count > 0) ? totalLossRate / presenterLossRateArray.count : 0.0f;
                if(!needUpdateAll) {
                    break;
                }
            }
        }
    }
    return presenterLossRate;
}

- (void)updateNetWorkStatus:(BJLNetworkStatus)status {
    if(self.isNetworkMessageShowing || self.user.mediaSource != BJLMediaSource_mainCamera)
        return;
    
    BOOL show = status != BJLNetworkStatus_normal;
    
    [self.networkMessageLabel setHidden:!show];
    if(!show) {
        [self.signalLevelView setImage:[UIImage bjlic_imageNamed:@"bjl_ic_signal_level_3"]];
        return;
    }
    
    BOOL highlighted = BJLNetworkStatus_Bad_level3 == status || BJLNetworkStatus_Bad_level4 == status || BJLNetworkStatus_Bad_level5 == status;
    NSString *message = (BJLNetworkStatus_Bad_level1 == status) ? @"网络较差" : ((BJLNetworkStatus_Bad_level2 == status) ? @"网络差" : @"网络极差");
    
    [self.networkMessageLabel setText:message];
    if(highlighted) {
        [self.networkMessageLabel setTextColor:[UIColor bjl_ic_extremelyBadNetColor]];
        [self.signalLevelView setImage:[UIImage bjlic_imageNamed:@"bjl_ic_signal_level_extremelyBad"]];
    }
    else {
        [self.networkMessageLabel setTextColor:[UIColor bjl_ic_quiteBadNetColor]];
        [self.signalLevelView setImage:[UIImage bjlic_imageNamed:@"bjl_ic_signal_level_quiteBad"]];
    }
    
    if(show) {
        self.isNetworkMessageShowing = YES;
        if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
            [self.networkMessageLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.bjl_right).offset(- 5.0);
                make.bottom.equalTo(self.bjl_bottom).offset(- 2.0);
                make.left.greaterThanOrEqualTo(self.bjl_left);
            }];
        }
        else {
            [self.networkMessageLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.bjl_right).offset(- 5.0);
                make.bottom.equalTo(self.userNameLabel.bjl_top).offset(- 5.0);
                make.left.greaterThanOrEqualTo(self.bjl_left);
            }];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.networkMessageLabel setHidden:YES];
            [self.signalLevelView setImage:[UIImage bjlic_imageNamed:@"bjl_ic_signal_level_3"]];
            self.isNetworkMessageShowing = NO;
        });
    }
}

- (BJLNetworkStatus)netWorkStatusWithLossRate:(CGFloat)lossRate {
    NSMutableArray *lossRateArray = [self.room.featureConfig.lossRateLevelArray copy];
    
    BJLNetworkStatus preLossRateLevel = BJLNetworkStatus_normal;
    BJLNetworkStatus currentLossRateLevel = BJLNetworkStatus_normal;
    for (NSInteger index = 0 ; index < [lossRateArray count]; index++) {
        NSNumber *nmber = [lossRateArray objectAtIndex:index];
        CGFloat lossRateLevel = nmber.floatValue;
        if(preLossRateLevel == BJLNetworkStatus_normal && lossRateLevel > 0 && lossRateLevel <= 100) {
            preLossRateLevel = (BJLNetworkStatus)index;
        }
        
        if(lossRateLevel <= 0 || lossRateLevel > 100) {
            continue;
        }
        
        if(lossRateLevel <= lossRate) {
            preLossRateLevel = (BJLNetworkStatus)index;
            continue;
        }
        
        if(lossRateLevel > lossRate) {
            currentLossRateLevel = (BJLNetworkStatus)index;
            break;
        }
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal && preLossRateLevel == BJLNetworkStatus_normal) {
        return BJLNetworkStatus_normal;
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal) {
        currentLossRateLevel = (preLossRateLevel + 1 <= BJLNetworkStatus_Bad_level5) ? (preLossRateLevel + 1) : BJLNetworkStatus_Bad_level5;
    }
    else {
        currentLossRateLevel = (currentLossRateLevel <= BJLNetworkStatus_Bad_level5) ? currentLossRateLevel : BJLNetworkStatus_Bad_level5;
    }
    return currentLossRateLevel;
}

#if DEBUG
- (void)showLossRateLabel:(NSString *)text {
    self.lossRateLable.text = text;
    [self.lossRateLable bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.bjl_left).offset(5.0);
        make.right.equalTo(self.bjl_right).offset(-5.0);
        make.bottom.equalTo(self.bjl_bottom).offset(- 25.0);
    }];
}
#endif

#pragma mark - public

- (void)handleSingleTapGesture:(CGPoint)point {
    if (!self.likeButton.hidden && CGRectContainsPoint(self.likeButton.frame, point)) {
        // 点击点赞按钮
        [self sendLikeForCurrentUser];
    }
    else if (!self.speakRequestControlView.hidden && CGRectContainsPoint(self.allowSpeakRequestButton.frame, point)) {
        // 点击允许举手
        [self allowSpeakRequest];
    }
    else if (!self.speakRequestControlView.hidden && CGRectContainsPoint(self.refuseSpeakRequestButton.frame, point)) {
        // 点击拒绝举手
        [self refuseSpeakRequest];
    }
    else if (!self.speakRequestButton.hidden && CGRectContainsPoint(self.speakRequestButton.frame, point)) {
        // 举手按钮
        [self showSpeakRequestControlView];
    }
    else {
        // 显示菜单
        [self showUserOperateView:point];
    }
}

- (void)updateContentWithUser:(BJLMediaUser *)user
             combineVideoView:(BOOL)combineVideoView {
    if (self.mediaID.length
        && ![self.mediaID isEqualToString:user.mediaID]) {
        return;
    }
    
    // 用户名
    self.userNameLabel.text = user.displayName;
    NSUInteger groupID = user.groupID;
    if ([user.ID isEqualToString:self.room.loginUser.ID]) {
        groupID = self.room.loginUser.groupID;
    }
    if (user.groupID != 0) {
        for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
            if (group.groupID == groupID) {
                self.groupColorView.backgroundColor = [UIColor bjl_colorWithHexString:group.color] ?: [UIColor clearColor];
                break;
            }
        }
    }
    else {
        self.groupColorView.backgroundColor = [UIColor clearColor];
    }
    
    // 视频开关
    BOOL videoOn = user.videoOn;
    // 不存在用户时不显示
    self.videoOffImageView.hidden = user ? videoOn : YES;
    // 采集不显示，无 user 显示，显示了 videoOffImageView 不显示，播放视频不显示
    self.audioOnlyImageView.hidden = self.isRecording ? YES : (user ? (self.videoOffImageView.hidden ? [self isVideoPlayingUser] : YES) : NO);
    if (videoOn && combineVideoView) {
        if (self.videoView.superview) {
            [self.videoView removeFromSuperview];
        }
        self.videoView.userInteractionEnabled = NO;
        [self insertSubview:self.videoView belowSubview:self.videoLoadingView];
        [self makeConstrantsForVideoView];
    }
    
    // !!! TODO: 在这里使用 [self.videoView removeFromSuperView] 会导致 iPad 4 (10.3.3) 崩溃，原因待查
    self.videoView.hidden = !videoOn;
    
    UIImage *image = user.audioOn ? [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_0"] : [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_off"];
    self.audioLevelView.image = image;
}

- (void)getBackVideoView {
    if (self.videoView.superview != self) {
        [self.videoView removeFromSuperview];
        [self insertSubview:self.videoView belowSubview:self.videoLoadingView];
    }
}

- (void)updateVideoViewConstranints {
    if (self.videoView.superview == self) {
        [self makeConstrantsForVideoView];
    }
}

- (void)makeConstrantsForVideoView {
    if (!self.videoView) {
        return;
    }
    // 视频视图
    CGFloat videoRatio = (self.isRecording
                          ? self.room.recordingVM.inputVideoAspectRatio
                          : [self.room.playingVM playingViewAspectRatioForUserWithID:self.user.ID mediaSource:self.user.mediaSource]);
    if (self.user.mediaSource == BJLMediaSource_mediaFile
        || self.user.mediaSource == BJLMediaSource_screenShare
        || self.user.mediaSource == BJLMediaSource_extraScreenShare) {
        // 专业小班课收到的视频是一个 fill 的内容，如果上层使用需要 fill 时，直接填充窗口，如果上层需要 fit 显示完整内容时，可以包装一个让 fill 的内容恰好完全 fill 的容器，然后放到不确定比例的窗口中
        [self.videoView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            CGFloat defaultAspectRatio = [BJLIcAppearance sharedAppearance].blackboardAspectRatio;
            if (!CGSizeEqualToSize(self.containerView.bounds.size, CGSizeZero)
                && self.containerView.bounds.size.height > 0
                && self.containerView.bounds.size.width > 0) {
                defaultAspectRatio = self.containerView.bounds.size.width / self.containerView.bounds.size.height;
            }

            if (videoRatio < defaultAspectRatio) {
                // 比黑板高的视频比例，如果显示全部内容，那么会存在左右黑边，高度固定，宽度缩放
                make.top.bottom.equalTo(self.containerView);
                make.centerX.equalTo(self.containerView);
                make.width.equalTo(self.containerView.bjl_height).multipliedBy(videoRatio);
            }
            else {
                // 比黑板宽的视频比例，如果显示全部内容，那么会存在上下黑边，宽度固定，高度缩放
                make.left.right.equalTo(self.containerView);
                make.centerY.equalTo(self.containerView);
                make.height.equalTo(self.containerView.bjl_width).multipliedBy(1.0/videoRatio);
            }
        }];
    }
    else {
        [self.videoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.containerView).priorityHigh();
            make.center.equalTo(self.containerView);
            make.top.left.lessThanOrEqualTo(self.containerView);
            make.bottom.right.greaterThanOrEqualTo(self.containerView);
            make.width.equalTo(self.videoView.bjl_height).multipliedBy(videoRatio);
        }];
    }
}

- (void)updatePlaceholderImageViewConstranintsForRoomLayout:(BJLRoomLayout)layout {
    if (layout == BJLRoomLayout_blackboard) {
        self.videoOffImageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_user_video_off"];
        self.videoOffImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.audioOnlyImageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_user_placeholder"];
        self.audioOnlyImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    else {
        self.videoOffImageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_user_video_off_gallary"];
        self.videoOffImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.audioOnlyImageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_user_placeholder_gallary"];
        self.audioOnlyImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

// 音视频用户更新点赞数, 学生点赞数为0时不显示, 能给别人点赞的人一直显示, 助教和老师自己不显示
- (void)updateWithLikeCount:(NSInteger)count hidden:(BOOL)hidden {
    [self.likeButton setTitle:count ? [NSString stringWithFormat:@"%ld", (long)count] : nil forState:UIControlStateNormal];
    self.likeButton.hidden = hidden;
    // fire
    BOOL drawingGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:self.user.number];
    BOOL webPPTAuthorized = [self.room.documentVM.authorizedPPTUserNumbers containsObject:self.user.number];
    [self updateDrawingGranted:drawingGranted webPPTAuthorized:webPPTAuthorized];
}

// 更新动态课件授权标志
- (void)updateWebPPTAuthorized:(BOOL)webPPTAuthorized {
    BOOL drawingGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:self.user.number];
    [self updateDrawingGranted:drawingGranted webPPTAuthorized:webPPTAuthorized];
}

// 更新画笔授权标志
- (void)updateDrawingGranted:(BOOL)drawingGranted {
    BOOL webPPTAuthorized = [self.room.documentVM.authorizedPPTUserNumbers containsObject:self.user.number];
    [self updateDrawingGranted:drawingGranted webPPTAuthorized:webPPTAuthorized];
}

- (void)updateDrawingGranted:(BOOL)drawingGranted webPPTAuthorized:(BOOL)webPPTAuthorized {
    self.webPPTAuthorizedView.hidden = !webPPTAuthorized;
    self.drawingGrantedView.hidden = !drawingGranted;
    
    [self.likeButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(self.likeButton.hidden ? @0.0 : @(self.likeButton.intrinsicContentSize.width));
        make.left.equalTo(self).offset(self.likeButton.hidden ? 0.0 : 4.0);
    }];
    
    [self.webPPTAuthorizedView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@(webPPTAuthorized ? 16.0 : 0.0)); // 隐藏或显示，一直偏移
        make.left.equalTo(self.likeButton.bjl_right).offset(webPPTAuthorized ? 4.0 : 0.0); // 隐藏时不偏移
    }];
    
    [self.drawingGrantedView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@(drawingGranted ? 16.0 : 0.0)); // 隐藏或显示
        make.left.equalTo(self.webPPTAuthorizedView.bjl_right).offset(drawingGranted ? 4.0 : 0.0); // 隐藏时不偏移
    }];
    
}

- (void)updateSpeakRequestViewHidden:(BOOL)hidden {
    if (hidden) {
        self.speakRequestButton.hidden = YES;
        self.speakRequestControlView.hidden = YES;
    }
    else {
        self.speakRequestButton.hidden = NO;
        self.speakRequestControlView.hidden = YES;
    }
}

#pragma mark - actions

- (void)showUserOperateView:(CGPoint)point {
    if (!self.room.roomVM.liveStarted) {
        return;
    }
    if (!self.speakRequestButton.hidden || !self.speakRequestControlView.hidden) {
        return;
    }
    if (self.user.mediaSource != BJLMediaSource_mainCamera) {
        return;
    }
    
    BJLIcUserOperateViewType operateViewType = BJLIcUserOperateViewStudent;
    if ([self.user.ID isEqualToString:self.room.loginUser.ID]) {
        operateViewType = BJLIcUserOperateViewSelf;
    }
    else {
        operateViewType = (self.room.loginUser.isTeacherOrAssistant
                           ? BJLIcUserOperateViewTeacher
                           : BJLIcUserOperateViewStudent);
    }
    
    // optionView
    BJLIcUserOperateView *optionView = [[BJLIcUserOperateView alloc] initWithType:operateViewType];
    // 更新当前user
    [self updateCurrentUser];
    // 当前的登录用户是学生，并且选择的用户没有开摄像头，不显示菜单
    if (self.room.loginUser.isStudent && !self.user.videoOn) {
        return;
    }
    BOOL enableStudentExtraCameraAndScreenShare = self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1
                                                   &&  (self.user.clientType == BJLClientType_PCWeb
                                                   || self.user.clientType == BJLClientType_PCApp
                                                   || self.user.clientType == BJLClientType_MacApp);
    // 更新状态
    optionView.videoOn = [self isVideoPlayingUser];
    optionView.cameraOn = self.user.videoOn;
    optionView.microphoneOn = self.user.audioOn;
    optionView.drawingGranted =  [self.room.drawingVM.drawingGrantedUserNumbers containsObject:self.user.number];
    optionView.webPPTAuthorized =  [self.room.documentVM.authorizedPPTUserNumbers containsObject:self.user.number];
    optionView.extraCameraAuthorized = [self.room.recordingVM.authorizedExtraCameraUserNumbers containsObject:self.user.number];
    optionView.ScreenShareAuthorized = [self.room.recordingVM.authorizedScreenShareUserNumbers containsObject:self.user.number];
    optionView.isTeacher = self.user.isTeacher;
    optionView.isAssistant = self.user.isAssistant;
    optionView.enableStudentExtraCameraAndScreenShare = enableStudentExtraCameraAndScreenShare;
    optionView.maxVideoDefinition = self.room.featureConfig.maxVideoDefinition;
    optionView.currentVideoDefinition = self.room.recordingVM.videoDefinition;
    // 更新菜单布局
    [optionView updateButtonConstraints];
    // 菜单，修改操作权限时需要同步修改视图的 UI
    NSInteger count = 0;
    if (operateViewType == BJLIcUserOperateViewSelf) {
        // 切换清晰度、切换摄像头
        count = optionView.maxVideoDefinition + 1 + 1;
    }
    else if (self.room.loginUser.isStudent) {
        // 登录的用户是学生时只有一个打开画面的菜单
        count = 1;
    }
    else {
        count = 9;
        // 没有打开摄像头的情况不显示打开画面的菜单
        count = self.user.videoOn ? count : count - 1;
        // 老师和助教不显示授权画笔，奖励，PPT授权
        count = self.user.isTeacherOrAssistant ? count - 3 : count;
        // 老师不能被踢出教室或者关闭采集
        count = self.user.isTeacher ? count - 3 : count;
    
        count = (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType && enableStudentExtraCameraAndScreenShare) ? count : count - 2;
    }
    
    // 如果操作项没有了，不显示菜单
    if (count <= 0) {
        return;
    }
    CGFloat height = [BJLIcAppearance sharedAppearance].userOptionViewHeight * count + 16.0;
    CGFloat width = 120.0;
    self.optionViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = CGSizeMake(width, height);
        viewController.popoverPresentationController.backgroundColor = [UIColor blackColor];
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self;
        viewController.popoverPresentationController.sourceRect = CGRectMake(point.x, point.y, 1.0, 1.0);
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    [self.optionViewController.view addSubview:optionView];
    [optionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.optionViewController.view.bjl_safeAreaLayoutGuide ?: self.optionViewController.view);
    }];
    bjl_weakify(self);
    [optionView setUpdateDefinitionCallback:^(BJLVideoDefinition definition) {
        bjl_strongify(self);
        [self hideOptionViewController];
        [self.room.recordingVM updateVideoDefinition:definition];
    }];
    [optionView setUpdateVideoCallback:^(BOOL on) {
        bjl_strongify(self);
        [self updateVideoForCurrentUser:on];
        [self hideOptionViewController];
    }];
    [optionView setSwitchCameraCallback:^{
        bjl_strongify(self);
        [self.room.recordingVM updateUsingRearCamera:!self.room.recordingVM.usingRearCamera];
        [self hideOptionViewController];
    }];
    [optionView setUpdateCameraCallback:^(BOOL on) {
        bjl_strongify(self);
        [self updateCameraForCurrentUser:on];
        [self hideOptionViewController];
    }];
    [optionView setUpdateMicrophoneCallback:^(BOOL on) {
        bjl_strongify(self);
        [self updateMicrophoneForCurrentUser:on];
        [self hideOptionViewController];
    }];
    [optionView setGrantDrawingCallback:^(BOOL grant) {
        bjl_strongify(self);
        [self updateDrawingGrantedForCurrentUser:grant];
        [self hideOptionViewController];
    }];
    [optionView setAuthorizeWebPPTCallback:^(BOOL authorized) {
        bjl_strongify(self);
        [self updateWebPPTAuthorizedForCurrentUser:authorized];
        [self hideOptionViewController];
    }];
    [optionView setAuthorizeExtraCameraCallback:^(BOOL authorized) {
        bjl_strongify(self);
        [self updateExtraCameraAuthorizedForCurrentUser:authorized];
        [self hideOptionViewController];
    }];
    [optionView setAuthorizeScreenShareCallback:^(BOOL authorized) {
        bjl_strongify(self);
        [self updateScreenShareAuthorizedForCurrentUser:authorized];
        [self hideOptionViewController];
    }];
    [optionView setSendLikeCallback:^{
        bjl_strongify(self);
        [self sendLikeForCurrentUser];
        [self hideOptionViewController];
    }];
    [optionView setBlockUserCallback:^{
        bjl_strongify(self);
        [self blockCurrentUser];
        [self hideOptionViewController];
    }];
    if (self.parentViewController.presentedViewController) {
        [self.parentViewController.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self.parentViewController presentViewController:self.optionViewController animated:YES completion:nil];
}

- (BOOL)updateVideoForCurrentUser:(BOOL)on {
    BJLError *error = [self.room.playingVM updatePlayingUserWithID:self.user.ID videoOn:on mediaSource:self.user.mediaSource];
    if (!error) {
        if (self.updateVideoCallback) {
            self.updateVideoCallback(self.user, on);
        }
        self.audioOnlyImageView.hidden = on;
    }
    [self throwError:error];
    return !error;
}

- (BOOL)updateCameraForCurrentUser:(BOOL)on {
    BJLError *error = [self.room.recordingVM remoteChangeRecordingWithUser:self.user audioOn:self.user.audioOn videoOn:on];
    [self throwError:error];
    return !error;
}

- (BOOL)updateMicrophoneForCurrentUser:(BOOL)on {
    BJLError *error = [self.room.recordingVM remoteChangeRecordingWithUser:self.user audioOn:on videoOn:self.user.videoOn];
    [self throwError:error];
    return !error;
}

- (NSArray *)strokeColors {
    return @[@"#F44336", @"#E91E63", @"#D500F9", @"#3D5AFE",
             @"#03A9F4", @"#00BCD4", @"#4CAF50", @"#8BC34A",
             @"#FFEB3B", @"#FFC107", @"#FF9800", @"#FF5722",
             @"#795548", @"#212121", @"#9E9E9E", @"#FFFFFF"];
}

- (BOOL)updateDrawingGrantedForCurrentUser:(BOOL)granted {
    NSString *color = nil;
    bjl_weakify(self);
    if(self.user.number) {
        __block NSString *savedColor = nil;
        [self.room.drawingVM.drawingGrantedColors enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            bjl_strongify(self);
            if(obj && [obj isEqualToString:self.user.number]) {
                savedColor = key;
                *stop = YES;
            }
        }];
        color = savedColor;
    }
    
    if(!color && granted) {
        NSArray *allUserNumbers = [self.room.drawingVM.drawingGrantedColors allKeys];

        NSMutableArray *colorsArray = [[self strokeColors] mutableCopy];
        [self.room.drawingVM.drawingGrantedColors enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            bjl_strongify(self);
            if([[self strokeColors] containsObject:key]) {
                [colorsArray removeObject:key];
            }
        }];
        
        if([colorsArray count]) {
            color = [colorsArray lastObject];
        }
        else {
            __block NSString *removedNumber = nil;
            for(int i = 0; i < [allUserNumbers count]; i++) {
                NSString *number = [allUserNumbers objectAtIndex:i];
                if(number && ![self.room.drawingVM.drawingGrantedUserNumbers containsObject:number]) {
                    removedNumber = number;
                    break;
                }
            }
            if(removedNumber) {
                [self.room.drawingVM deleteColorRecordWithUserNumber:removedNumber];
                color = [self.room.drawingVM.drawingGrantedColors bjl_stringForKey:removedNumber];
            }
        }
    }
    
    BJLError *error = [self.room.drawingVM updateDrawingGranted:granted userNumber:self.user.number color:color];
    [self throwError:error];
    return !error;
}

- (BOOL)updateWebPPTAuthorizedForCurrentUser:(BOOL)authorized {
    BJLError *error = [self.room.documentVM updateStudentPPTAuthorized:authorized userNumber:self.user.number];
    [self throwError:error];
    return !error;
}

- (BOOL)updateExtraCameraAuthorizedForCurrentUser:(BOOL)authorized {
    BJLError *error = [self.room.recordingVM updateStudentExtraCameraAuthorized:authorized userNumber:self.user.number];
    [self throwError:error];
    return !error;
}

- (BOOL)updateScreenShareAuthorizedForCurrentUser:(BOOL)authorized {
    BJLError *error = [self.room.recordingVM updateStudentScreenShareAuthorized:authorized userNumber:self.user.number];
    [self throwError:error];
    return !error;
}

- (BOOL)sendLikeForCurrentUser {
    if (!self.room.roomVM.liveStarted) {
        return NO;
    }
    BJLError *error = [self.room.roomVM sendLikeForUserNumber:self.user.number];
    [self throwError:error];
    return !error;
}

- (BOOL)blockCurrentUser {
    if (self.blockUserCallback) {
       return self.blockUserCallback(self.user);
    }
    return NO;
}

- (void)hideOptionViewController {
    [self.optionViewController bjl_dismissAnimated:YES completion:nil];
}

- (void)showSpeakRequestControlView {
    self.speakRequestButton.hidden = YES;
    self.speakRequestControlView.hidden = NO;
}

- (void)allowSpeakRequest {
    [self.room.speakingRequestVM replySpeakingRequestToUserID:self.user.ID allowed:YES];
    self.speakRequestControlView.hidden = YES;
}

- (void)refuseSpeakRequest {
    [self.room.speakingRequestVM replySpeakingRequestToUserID:self.user.ID allowed:NO];
    self.speakRequestControlView.hidden = YES;
}

- (void)updateInfoGroupViewWithReferenceView:(UIView *)referenceView {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        [self updatePad1to1InfoGroupViewWithReferenceView:referenceView];
    }
}

#pragma mark - wheel

- (BOOL)isVideoPlayingUser {
    for (BJLMediaUser *user in [self.room.playingVM.videoPlayingUsers copy]) {
        if ([user isSameMediaUser:self.user]) {
            return YES;
        }
    }
    return NO;
}

- (void)updateCurrentUser {
    BJLMediaUser *oldUser = self.user;
    BJLMediaUser *newUser = [self.room.playingVM playingUserWithID:oldUser.ID number:oldUser.number mediaSource:oldUser.mediaSource];
    if (newUser) {
        self->_user = newUser;
    }
    
    if (self.animating
        && (!newUser
            || ![self.room.playingVM.videoPlayingUsers containsObject:newUser])) {
        // 不再播放对方视频, 停止 loading 动画
        [self updateLoadingViewHidden:YES];
    }
}

// loss rate 0 - 100
- (UIImage *)imageWithLossRate:(CGFloat)rate {
    UIImage *image;
    if (rate <= 1.0) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_signal_level_3"];
    }
    else if (rate > 1.0 && rate <= 10.0) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_signal_level_2"];
    }
    else {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_signal_level_1"];
    }
    return image;
}

// volume 0 - 255
- (UIImage *)imageWithAudioVolume:(CGFloat)volume {
    UIImage *image;
    if (volume <= 5) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_0"];
    }
    else if (volume > 5 && volume <= 20) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_1"];
    }
    else if (volume > 20 && volume <= 60) {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_2"];
    }
    else {
        image = [UIImage bjlic_imageNamed:@"bjl_ic_audio_level_3"];
    }
    return image;
}

- (void)throwError:(nullable NSError *)error {
    if (error && self.showErrorMessageCallback) {
        NSString *message = error.localizedFailureReason ?: error.localizedDescription;
        self.showErrorMessageCallback(message);
    }
}

- (UIImageView *)imageViewWithName:(NSString *)imageName {
    UIImage *image = [UIImage bjlic_imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - video loading

// 用户视频加载占位图
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

@end

NS_ASSUME_NONNULL_END

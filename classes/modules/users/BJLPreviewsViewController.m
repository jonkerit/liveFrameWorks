//
//  BJLPreviewsViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-06-05.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSInvocation+BJL_M9Dev.h>
#import <BJLiveBase/NSObject+BJL_M9Dev.h>

#import "BJLPreviewsViewController.h"

#import "BJLPreviewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLPreviewItem ()

@property (nonatomic, readwrite) BJLPreviewsType type;
@property (nonatomic, readwrite, nullable) UIView *view;
@property (nonatomic, readwrite, nullable) UIViewController *viewController;
@property (nonatomic, readwrite) CGFloat aspectRatio;
@property (nonatomic, readwrite) BJLContentMode contentMode;
@property (nonatomic, readwrite) BJLUser *loginUser;
@property (nonatomic, readwrite, nullable) BJLMediaUser *playingUser;
@property (nonatomic, readwrite, copy, nullable) NSString *playingUserRoleName;
@property (nonatomic, readwrite, nullable) BJLUser *currentPresent;
@property (nonatomic, readwrite) NSInteger likeCount;

@end

@implementation BJLPreviewItem

@end

#pragma mark -

@interface _BJLPreviewsRootView : BJLHitTestView

@property (nonatomic, weak) UIButton *outsideButton;

@end

@implementation _BJLPreviewsRootView

// 解决 button 超出 bounds 之后点击失效的问题
// @see https://stackoverflow.com/questions/5432995/interaction-beyond-bounds-of-uiview
// @see https://developer.apple.com/library/content/qa/qa2013/qa1812.html
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    if (!self.outsideButton.hidden) {
        if (CGRectContainsPoint(self.outsideButton.frame, point)) {
            return YES;
        }
    }
    return [super pointInside:point withEvent:event];
}

@end

@interface _BJLPreviewsMoreButton : BJLImageRightButton

@end

@implementation _BJLPreviewsMoreButton

- (CGRect)contentRectForBounds:(CGRect)bounds {
    return UIEdgeInsetsInsetRect([super contentRectForBounds:bounds],
                                 UIEdgeInsetsMake(0.0, - BJLViewSpaceS, 0.0, BJLViewSpaceS));
}

@end

#pragma mark -

typedef NS_ENUM(NSInteger, BJLPreviewsSection) {
    BJLPreviewsSection_PPT,
    BJLPreviewsSection_presenter,
    BJLPreviewsSection_presenterExtra,
    BJLPreviewsSection_recording,
    BJLPreviewsSection_videoUsers,
    BJLPreviewsSection_audioUsers,
    BJLPreviewsSection_requestUsers,
    _BJLPreviewsSection_count
};

static const CGSize moreButtonSize = { .width = 85.0, .height = BJLButtonSizeS };

@interface BJLPreviewsViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic, readwrite) UICollectionView *collectionView;
@property (nonatomic, readwrite) UIView *backgroundView;
@property (nonatomic, readwrite) UIButton *moreButton;

@property (nonatomic, readwrite, nullable) BJLPreviewItem *fullScreenItem;
@property (nonatomic, readwrite) NSInteger numberOfItems;
@property (nonatomic) BOOL didLoadAllDocuments;

@property (nonatomic, readonly, nullable) __kindof BJLMediaUser *presenter; // NON-KVO
@property (nonatomic, readonly, nullable) __kindof BJLMediaUser *extraPresenter; // NON-KVO
@property (nonatomic, readonly) __kindof NSArray<BJLMediaUser *> *playingUsers;
@property (nonatomic) BOOL presenterVideoPlaying;
@property (nonatomic) BOOL extraPresenterVideoPlaying;
@property (nonatomic, readonly) NSMutableSet *autoPlayVideoBlacklist;
@property (nonatomic, readonly) NSMutableArray<BJLMediaUser *> *videoUsers, *audioUsers;

// < userNumber, < time, loss rate key > >
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *lossRateDictionary;
//主讲人丢包率
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *presenterLossRateDictionary;
@property (nonatomic, nullable) NSTimer *lossRateObservingTimer;

#pragma mark - loading

@property (nonatomic, readonly) NSMutableDictionary *videoLoadingInfo;
@property (nonatomic, nullable) NSTimer *videoLoadingTimer;
@property (nonatomic) CGFloat videoLoadingRotationAngle;

@end

@implementation BJLPreviewsViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self->_room = room;
        self->_autoPlayVideoBlacklist = [NSMutableSet new];
        self->_videoUsers = [NSMutableArray new];
        self->_audioUsers = [NSMutableArray new];
        self->_videoLoadingInfo = [NSMutableDictionary new];
        self.lossRateDictionary = [NSMutableDictionary new];
        self.presenterLossRateDictionary = [NSMutableDictionary new];
        self.videoLoadingRotationAngle = 0.0;
        [self startVideoLoadingTimer];
    }
    return self;
}

- (void)dealloc {
    [self stopVideoLoadingTimer];
    [self stopLossRateObservingTimer];

    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
}

- (void)loadView {
    bjl_weakify(self);
    self.view = [_BJLPreviewsRootView viewWithFrame:[UIScreen mainScreen].bounds hitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        if (hitView != self.view && hitView != self.collectionView) {
            return hitView;
        }
        return nil;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    [self makeConstraints];
    [self makeObserving];
}

#pragma mark - timer

- (void)startVideoLoadingTimer {
    [self stopVideoLoadingTimer];
    bjl_weakify(self);
    self.videoLoadingTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:BJLVideoLoadingRotationDuration repeats:YES
                                                                   block:^(NSTimer * _Nonnull timer) {
                                                                       bjl_strongify(self);
                                                                       if (!self) {
                                                                           [timer invalidate];
                                                                           return;
                                                                       }
                                                                       self.videoLoadingRotationAngle += BJLVideoLoadingRotationAngleIncrement;
                                                                       if (self.videoLoadingRotationAngle > 180.0) {
                                                                           self.videoLoadingRotationAngle = 0.0;
                                                                       }
                                                                   }];
}

- (void)stopVideoLoadingTimer {
    if (self.videoLoadingTimer) {
        [self.videoLoadingTimer invalidate];
        self.videoLoadingTimer = nil;
    }
}

#pragma mark -

- (nullable __kindof BJLMediaUser *)presenter {
    if (self.room.loginUserIsPresenter) {
        return nil;
    }
    
    for (BJLMediaUser *user in [self.room.mainPlayingAdapterVM.playingUsers copy]) {
        if ([user isSameUser:self.room.onlineUsersVM.currentPresenter]) {
            return user;
        }
    }
    
    return self.room.onlineUsersVM.currentPresenter;
}

- (nullable __kindof BJLMediaUser *)extraPresenter {
    if (self.room.loginUserIsPresenter) {
        return nil;
    }
    
    for (BJLMediaUser *user in [self.room.extraPlayingAdapterVM.playingUsers copy]) {
        if ([user isSameUser:self.room.onlineUsersVM.currentPresenter]
            && user.videoOn) {
            return user;
        }
    }
    return nil;
}

- (NSArray<BJLMediaUser *> *)playingUsers {
    return [self.room.mainPlayingAdapterVM.playingUsers
            arrayByAddingObjectsFromArray:self.room.extraPlayingAdapterVM.playingUsers];
}

#pragma mark -

- (UICollectionView *)collectionView {
    if (!self->_collectionView) {
        self.collectionView = ({
            UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                                                  collectionViewLayout:({
                UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
                layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                layout.itemSize = [BJLPreviewCell cellSize];
                layout.minimumLineSpacing = 0.0;
                layout.minimumInteritemSpacing = 0.0;
                layout.sectionInset = UIEdgeInsetsZero;
                layout;
            })];
            collectionView.backgroundColor = [UIColor clearColor];
            collectionView.bounces = YES;
            collectionView.alwaysBounceHorizontal = YES;
            collectionView.alwaysBounceVertical = NO;
            collectionView.showsHorizontalScrollIndicator = NO;
            collectionView.showsVerticalScrollIndicator = NO;
            collectionView.clipsToBounds = NO;
            collectionView.dataSource = self;
            collectionView.delegate = self;
            for (NSString *cellIdentifier in [BJLPreviewCell allCellIdentifiers]) {
                [collectionView registerClass:[BJLPreviewCell class]
                   forCellWithReuseIdentifier:cellIdentifier];
            }
            [self.view addSubview:collectionView];
            collectionView;
        });
    }
    return self->_collectionView;
}

- (UIView *)backgroundView {
    if (!self->_backgroundView) {
        self.backgroundView = ({
            UIView *backgroundView = [UIView new];
            backgroundView.backgroundColor = [UIColor bjl_lightGrayTextColor];
            [self.view insertSubview:backgroundView atIndex:0];
            backgroundView;
        });
    }
    return self->_backgroundView;
}

- (UIButton *)moreButton {
    if (!self->_moreButton) {
        self.moreButton = ({
            _BJLPreviewsMoreButton *button = [_BJLPreviewsMoreButton new];
            [button setTitle:@"新请求" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_speakreq_more"] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:14.0];
            button.backgroundColor = [UIColor bjl_blueBrandColor];
            button.layer.cornerRadius = moreButtonSize.height / 2;
            button.layer.masksToBounds = YES;
            button.midSpace = BJLViewSpaceS;
            [self.view addSubview:button];
            button;
        });
        
        self->_moreButton.hidden = YES;
        
        bjl_as(self.view, _BJLPreviewsRootView).outsideButton = self->_moreButton;
        
        bjl_weakify(self);
        [self->_moreButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
            bjl_strongify(self);
            CGRect rightEdge = CGRectMake(self.collectionView.contentSize.width - 1.0, 0.0, 1.0, 1.0);
            [self.collectionView scrollRectToVisible:rightEdge animated:YES];
        }];
    }
    
    return self->_moreButton;
}

- (void)makeConstraints {
    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.moreButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.view).with.offset(moreButtonSize.height / 2);
        make.top.equalTo(self.view.bjl_bottom).with.offset(BJLViewSpaceM);
        make.size.equal.sizeOffset(moreButtonSize);
    }];
}

- (void)makeObserving {
    bjl_weakify(self);
    
    [self enterFullScreenWithPPTView];
    
    // 【PPT 为空时（不管画笔），老师视频全屏】
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, allDocumentsDidOverwrite:)
               filter:^BOOL(NSArray<BJLDocument *> * _Nullable allDocuments) {
                   bjl_strongify(self);
                   self.didLoadAllDocuments = YES;
                   return allDocuments.count <= 1;
               }
             observer:^BOOL(NSArray<BJLDocument *> * _Nullable allDocuments) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isTeacher) {
                     [self enterFullScreenWithRecordingView];
                 }
                 else {
                     BJLUser *onlineTeacher = self.room.onlineUsersVM.onlineTeacher;
                     BJLMediaUser *videoPlayingTeacher = [self.room.mainPlayingAdapterVM videoPlayingUserWithID:onlineTeacher.ID
                                                                                                         number:onlineTeacher.number];
                     if (videoPlayingTeacher) {
                         [self enterFullScreenWithViewForVideoPlayingUser:videoPlayingTeacher];
                     }
                 }
                 return YES;
             }];
    
    // 举手用户
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestUsers)
         observer:^BOOL(NSArray<BJLUser *> * _Nullable now, NSArray<BJLUser *> * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self reloadCollectionView];
             // 举手提示
             if (self.room.loginUser.isTeacherOrAssistant
                 && self.room.loginUser.noGroup) {
                 if (now.count > old.count) {
                     [self tryToShowMoreButton];
                 }
                 else {
                     [self tryToHideMoreButton];
                 }
             }
             return YES;
         }];
    // 举手提示
    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
           filter:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return !!now;
           }
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.loginUser.isTeacherOrAssistant
                 && self.room.loginUser.noGroup) {
                 [self bjl_kvo:BJLMakeProperty(self.collectionView, contentSize)
                      observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                          bjl_strongify(self);
                          if (!self.moreButton.hidden) {
                              [self tryToHideMoreButton];
                          }
                          return YES;
                      }];
                 [self bjl_kvo:BJLMakeProperty(self.collectionView, contentOffset)
                      observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                          bjl_strongify(self);
                          if (!self.moreButton.hidden) {
                              [self tryToHideMoreButton];
                          }
                          return YES;
                      }];
             }
             return NO;
         }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.mainPlayingAdapterVM, playingUsers),
                         BJLMakeProperty(self.room.extraPlayingAdapterVM, playingUsers)]
              observer:^(NSArray<BJLMediaUser *> * _Nullable playingUsers, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  BJLMediaUser *fullScreenUser = self.fullScreenItem.playingUser;
                  for (BJLMediaUser *user in playingUsers) {
                      if (fullScreenUser && [fullScreenUser isSameCameraUser:user]) {
                          // 刷新全屏视图
                          [self enterFullScreenWithViewForVideoPlayingUser:user];
                          if (self.fullScreenItemChangedCallback) {
                              self.fullScreenItemChangedCallback(self.fullScreenItem);
                          }
                          break;
                      }
                  }
                  [self updateVideoUsers];
                  [self updateAudioUsers];
                  [self reloadCollectionView];
              }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.mainPlayingAdapterVM, videoPlayingUsers),
                         BJLMakeProperty(self.room.extraPlayingAdapterVM, videoPlayingUsers)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  [self updateVideoUsers];
                  [self updateAudioUsers];
                  [self reloadCollectionView];
              }];
    
    // 自动播放主摄像头采集视频
    self.room.mainPlayingAdapterVM.autoPlayVideoBlock = ^BJLAutoPlayVideo(BJLMediaUser *user, NSInteger cachedDefinitionIndex) {
        bjl_strongify(self);
        NSString *videoKey = [self videoKeyForUser:user];
        BOOL autoPlay = videoKey && ![self.autoPlayVideoBlacklist containsObject:videoKey];
        NSInteger definitionIndex = cachedDefinitionIndex;
        if (autoPlay) {
            NSInteger maxDefinitionIndex = MAX(0, (NSInteger)user.definitions.count - 1);
            definitionIndex = (cachedDefinitionIndex <= maxDefinitionIndex
                               ? cachedDefinitionIndex : maxDefinitionIndex);
        }
        [self tryToSendTeacherVideoFullScreen];
        return BJLAutoPlayVideoMake(autoPlay, definitionIndex);
    };
    
    // 自动播放其它视频
    self.room.extraPlayingAdapterVM.autoPlayVideoBlock = ^BJLAutoPlayVideo(BJLMediaUser *user, NSInteger cachedDefinitionIndex) {
        bjl_strongify(self);
        NSString *videoKey = [self videoKeyForUser:user];
        BOOL autoPlay = videoKey && ![self.autoPlayVideoBlacklist containsObject:videoKey];
        NSInteger definitionIndex = cachedDefinitionIndex;
        if (autoPlay) {
            NSInteger maxDefinitionIndex = MAX(0, (NSInteger)user.definitions.count - 1);
            definitionIndex = (cachedDefinitionIndex <= maxDefinitionIndex
                               ? cachedDefinitionIndex : maxDefinitionIndex);
        }
        [self tryToSendTeacherVideoFullScreen];
        return BJLAutoPlayVideoMake(autoPlay, definitionIndex);
    };
    
    // 主讲
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, currentPresenter)
           filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old;
           }
         observer:^BOOL(__kindof BJLUser * _Nullable user, __kindof BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateVideoUsers];
             [self updateAudioUsers];
             BJLUser *presenter = self.room.onlineUsersVM.currentPresenter;
             self.fullScreenItem.currentPresent = presenter;
             
             if (self.fullScreenItemChangedCallback) {
                 self.fullScreenItemChangedCallback(self.fullScreenItem);
             }
             [self reloadCollectionView];
             return YES;
         }];
    
    // 全屏
    [self bjl_kvo:BJLMakeProperty(self, fullScreenItem)
         observer:^BOOL(BJLPreviewItem * _Nullable now, BJLPreviewItem * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (old.type == BJLPreviewsType_playing
                 || now.type == BJLPreviewsType_playing) {
                 [self updateVideoUsers];
             }
             [self reloadCollectionView];
             return YES;
         }];
    
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.mainPlayingAdapterVM, playingViewAspectRatioChanged:forUser:),
                             BJLMakeMethod(self.room.extraPlayingAdapterVM, playingViewAspectRatioChanged:forUser:)]
                  observer:(BJLMethodsObserver)^(CGFloat videoAspectRatio, BJLMediaUser *user) {
                      bjl_strongify(self);
                      if (self.fullScreenItem.type == BJLPreviewsType_playing
                          && [self.fullScreenItem.playingUser.ID isEqualToString:user.ID]
                          && self.fullScreenItem.playingUser.mediaSource == user.mediaSource) {
                            self.fullScreenItem.aspectRatio = videoAspectRatio;
                      }
                      [self reloadCollectionView];
                  }];
    
    // play media
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.playingVM, teacherPlayingMedia),
                         BJLMakeProperty(self.room.playingVM, teacherSharingDesktop)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  BJLMediaUser *fullScreenUser;
                  BJLMediaUser *presenter = self.presenter;
                  BJLMediaUser *extraPresenter = self.extraPresenter;
                  if (self.room.playingVM.teacherPlayingMedia) {
                      fullScreenUser = (presenter.mediaSource == BJLMediaSource_mediaFile ? presenter : nil);
                  }
                  if (self.room.playingVM.teacherSharingDesktop) {
                      fullScreenUser = ((presenter.mediaSource == BJLMediaSource_screenShare ? presenter : nil)
                                        ?: (extraPresenter.mediaSource == BJLMediaSource_extraScreenShare ? extraPresenter : nil));
                  }
                  if (fullScreenUser) {
                      [self enterFullScreenWithViewForVideoPlayingUser:fullScreenUser];
                  }
              }];
    
    // loading 动画
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.mainPlayingAdapterVM, playingUserDidStartLoadingVideo:),
                             BJLMakeMethod(self.room.extraPlayingAdapterVM, playingUserDidStartLoadingVideo:)]
                  observer:(BJLMethodsObserver)^(BJLMediaUser *user) {
                      bjl_strongify(self);
                      [self tryToShowLoadingViewWithUser:user];
                  }];
    
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.mainPlayingAdapterVM, playingUserDidFinishLoadingVideo:),
                             BJLMakeMethod(self.room.extraPlayingAdapterVM, playingUserDidFinishLoadingVideo:)]
                  observer:(BJLMethodsObserver)^(BJLMediaUser *user) {
                      bjl_strongify(self);
                      [self tryToCloseLoadingViewWithUser:user];
                  }];
    
    // 点赞
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, likeRecordsDidOverwrite:)
             observer:^BOOL(NSDictionary<NSString *, NSNumber *> *records) {
                 bjl_strongify(self);
                 if (self.fullScreenItem.type == BJLPreviewsType_playing) {
                     self.fullScreenItem.likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.fullScreenItem.playingUser.number];
                 }
                 else if (self.fullScreenItem.type == BJLPreviewsType_recording) {
                     self.fullScreenItem.likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.fullScreenItem.loginUser.number];
                 }
                 if (self.fullScreenItemChangedCallback) {
                     self.fullScreenItemChangedCallback(self.fullScreenItem);
                 }
                 [self reloadCollectionView];
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForUserNumber:records:)
             observer:^BOOL(NSString *userNumber, NSDictionary<NSString *, NSNumber *> *records) {
                 bjl_strongify(self);
                 
                 if (self.fullScreenItem.type == BJLPreviewsType_playing) {
                     self.fullScreenItem.likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.fullScreenItem.playingUser.number];
                 }
                 else if (self.fullScreenItem.type == BJLPreviewsType_recording) {
                     self.fullScreenItem.likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.fullScreenItem.loginUser.number];
                 }
                 if (self.fullScreenItemChangedCallback) {
                     self.fullScreenItemChangedCallback(self.fullScreenItem);
                 }
                 [self reloadCollectionView];
                 return YES;
             }];
    
    // 自己
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingVideo)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.fullScreenItem.type == BJLPreviewsType_recording) {
                 if (!now.boolValue) {
                     self.fullScreenItem = nil;
                 }
             }
             else {
                 [self reloadCollectionView];
                 // 【PPT 为空时（不管画笔），老师视频全屏】
                 if (self.room.loginUser.isTeacher
                     && self.didLoadAllDocuments
                     && self.room.documentVM.allDocuments.count <= 1) {
                     [self enterFullScreenWithRecordingView];
                 }
             }
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, mediaLossRateDidUpdateWithUser:videoLossRate:audioLossRate:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat videoLossRate, CGFloat audioLossRate){
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
    [self restartLossRateObservingTimer];
}

- (void)tryToSendTeacherVideoFullScreen {
    // 等待 self.room.playingVM.videoPlayingUsers 更新
    bjl_dispatch_async_main_queue(^{
        // 【PPT 为空时（不管画笔），老师视频全屏】
        if (!self.room.loginUser.isTeacher
            && self.didLoadAllDocuments
            && self.room.documentVM.allDocuments.count <= 1) {
            BJLUser *onlineTeacher = self.room.onlineUsersVM.onlineTeacher;
            BJLMediaUser *videoPlayingTeacher = [self.room.mainPlayingAdapterVM videoPlayingUserWithID:onlineTeacher.ID
                                                                                                number:onlineTeacher.number];
            if (videoPlayingTeacher) {
                [self enterFullScreenWithViewForVideoPlayingUser:videoPlayingTeacher];
            }
        }
    });
}

- (BOOL)atTheEndOfCollectionView {
    CGFloat contentOffsetX = self.collectionView.contentOffset.x;
    CGFloat rightInset = self.collectionView.contentInset.right;
    CGFloat viewWidth = CGRectGetWidth(self.collectionView.frame);
    CGFloat contentWidth = self.collectionView.contentSize.width;
    CGFloat bottomOffset = contentOffsetX + viewWidth - rightInset - contentWidth;
    return bottomOffset >= 0.0 - [BJLPreviewCell cellSize].width / 2;
}

- (void)tryToShowMoreButton {
    if (self.moreButton.hidden && ![self atTheEndOfCollectionView]) {
        self.moreButton.hidden = NO;
    }
}

- (void)tryToHideMoreButton {
    if (!self.moreButton.hidden && [self atTheEndOfCollectionView]) {
        self.moreButton.hidden = YES;
    }
}

// videoUsers = playingVM.videoPlayingUsers - self.presenter - fullScreenItem.playingUser
- (void)updateVideoUsers {
    [self.videoUsers removeAllObjects];
    
    self.presenterVideoPlaying = NO;
    self.extraPresenterVideoPlaying = NO;
    
    BOOL fullScreenPlaying = (self.fullScreenItem.type == BJLPreviewsType_playing);
    BJLMediaUser *fullScreenUser = nil;
    
    BJLMediaUser *currentPresenter = self.presenter;
    for (BJLMediaUser *videoPlayingUser in [self.room.mainPlayingAdapterVM.videoPlayingUsers copy]) {
        BOOL isPresenter = [videoPlayingUser isSameCameraUser:currentPresenter];
        if (isPresenter
            && videoPlayingUser.mediaSource == currentPresenter.mediaSource) {
            self.presenterVideoPlaying = YES;
        }
        BOOL isFullScreenUser = (fullScreenPlaying
                                 && [videoPlayingUser isSameCameraUser:self.fullScreenItem.playingUser]);
        if (isFullScreenUser) {
            fullScreenUser = videoPlayingUser;
        }
        
        if (!isPresenter && !isFullScreenUser) {
            [self.videoUsers addObject:videoPlayingUser];
        }
    }
    
    BJLMediaUser *currentExtraPresenter = self.extraPresenter;
    for (BJLMediaUser *extraVideoPlayingUser in [self.room.extraPlayingAdapterVM.videoPlayingUsers copy]) {
        BOOL isExtraPresenter = [extraVideoPlayingUser isSameCameraUser:currentExtraPresenter];
        if (isExtraPresenter
            && extraVideoPlayingUser.mediaSource == currentExtraPresenter.mediaSource) {
            self.extraPresenterVideoPlaying = YES;
        }
        BOOL isFullScreenUser = (fullScreenPlaying
                                 && [extraVideoPlayingUser isSameCameraUser:self.fullScreenItem.playingUser]);
        if (isFullScreenUser) {
            fullScreenUser = extraVideoPlayingUser;
        }
        
        if (!isExtraPresenter && !isFullScreenUser) {
            [self.videoUsers addObject:extraVideoPlayingUser];
        }
    }
    
    if (fullScreenPlaying) {
        if (fullScreenUser) {
            self.fullScreenItem.playingUser = fullScreenUser;
        }
        else {
            self.fullScreenItem = nil;
        }
    }
}

// audioUsers = playingVM.playingUsers - self.presenter - playingVM.videoPlayingUsers
- (void)updateAudioUsers {
    [self.audioUsers removeAllObjects];
    
    for (BJLMediaUser *playingUser in [self.playingUsers copy]) {
        if (![playingUser isSameMediaUser:self.presenter]
            && ![playingUser isSameMediaUser:self.extraPresenter]
            && ![playingUser containedInMediaUsers:self.room.mainPlayingAdapterVM.videoPlayingUsers]
            && ![playingUser containedInMediaUsers:self.room.extraPlayingAdapterVM.videoPlayingUsers]) {
            [self.audioUsers addObject:playingUser];
        }
    }
}

- (void)autoEnterFullScreen {
    if (self.fullScreenItem && self.fullScreenItem.type != BJLPreviewsType_None) {
        return;
    }
    [self enterFullScreenWithPPTView];
}

- (void)enterFullScreenWithPPTView {
    self.fullScreenItem = ({
        BJLPreviewItem *item = [BJLPreviewItem new];
        item.type = BJLPreviewsType_PPT;
        item.view = nil;
        item.viewController = self.room.slideshowViewController;
        item.aspectRatio = 4.0 / 3;
        item.contentMode = BJLContentMode_scaleToFill;
        item.loginUser = self.room.loginUser;
        item.playingUser = nil;
        item.playingUserRoleName = nil;
        item.currentPresent = self.room.onlineUsersVM.currentPresenter;
        item.likeCount = 0;
        item;
    });
    [self fullScreenDidFinishLoadingVideo];
}

- (void)enterFullScreenWithRecordingView {
    if (!self.room.recordingVM.recordingVideo) {
        return;
    }
    self.fullScreenItem = ({
        BJLPreviewItem *item = [BJLPreviewItem new];
        item.type = BJLPreviewsType_recording;
        item.view = self.room.recordingView;
        item.viewController = nil;
        item.aspectRatio = self.room.recordingVM.inputVideoAspectRatio;
        item.contentMode = BJLContentMode_scaleToFill;
        item.loginUser = self.room.loginUser;
        item.playingUser = nil;
        item.playingUserRoleName = nil;
        item.currentPresent = self.room.onlineUsersVM.currentPresenter;
        item.likeCount = [self.room.roomVM.likeList bjl_integerForKey:self.room.loginUser.number];
        item;
    });
    [self fullScreenDidFinishLoadingVideo];
}

- (void)enterFullScreenWithViewForVideoPlayingUser:(BJLMediaUser *)videoPlayingUser {
    if (![videoPlayingUser containedInMediaUsers:self.room.mainPlayingAdapterVM.videoPlayingUsers]
        && ![videoPlayingUser containedInMediaUsers:self.room.extraPlayingAdapterVM.videoPlayingUsers]) {
        return;
    }
    self.fullScreenItem = ({
        BJLPreviewItem *item = [BJLPreviewItem new];
        item.type = BJLPreviewsType_playing;
        item.view = [self.room.playingVM playingViewForUserWithID:videoPlayingUser.ID mediaSource:videoPlayingUser.mediaSource];
        item.viewController = nil;
        item.aspectRatio = [self.room.playingVM playingViewAspectRatioForUserWithID:videoPlayingUser.ID mediaSource:videoPlayingUser.mediaSource];
        item.contentMode = BJLContentMode_scaleToFill;
        item.loginUser = self.room.loginUser;
        item.playingUser = videoPlayingUser;
        item.playingUserRoleName = [self roleNameOfUser:videoPlayingUser];
        item.currentPresent = self.room.onlineUsersVM.currentPresenter;
        item.likeCount = [self.room.roomVM.likeList bjl_integerForKey:videoPlayingUser.number];
        item;
    });
    BOOL isLoading = [[self.videoLoadingInfo bjl_numberForKey:videoPlayingUser.mediaID defaultValue:@(NO)] boolValue];
    if (isLoading) {
        [self fullScreenDidStartLoadingVideo:self.videoLoadingRotationAngle];
    }
    else {
        [self fullScreenDidFinishLoadingVideo];
    }
}

#pragma mark - video loading

- (void)tryToShowLoadingViewWithUser:(BJLMediaUser *)user {
    if (!user.videoOn) {
        return;
    }
    [self.videoLoadingInfo bjl_setObject:@(YES) forKey:user.mediaID];
    if (self.fullScreenItem.type == BJLPreviewsType_playing
        && [self.fullScreenItem.playingUser.mediaID isEqualToString:user.mediaID]) {
        [self fullScreenDidStartLoadingVideo:self.videoLoadingRotationAngle];
    }
    else {
        [self reloadCollectionView];
    }
}

- (void)tryToCloseLoadingViewWithUser:(BJLMediaUser *)user {
    if (!user.videoOn) {
        return;
    }
    [self.videoLoadingInfo bjl_removeObjectForKey:user.mediaID];
    if (self.fullScreenItem.type == BJLPreviewsType_playing
        && [self.fullScreenItem.playingUser.mediaID isEqualToString:user.mediaID]) {
        [self fullScreenDidFinishLoadingVideo];
    }
    else {
        [self reloadCollectionView];
    }
}

- (BJLObservable)fullScreenDidStartLoadingVideo:(CGFloat)videoLoadingRotationAngle {
    BJLMethodNotify((CGFloat), videoLoadingRotationAngle);
}

- (BJLObservable)fullScreenDidFinishLoadingVideo {
    BJLMethodNotify((void));
}

- (void)reloadCollectionView {
    [self.collectionView reloadData];
    
    NSInteger numberOfItems = 0;
    for (BJLPreviewsSection section = (BJLPreviewsSection)0; section < _BJLPreviewsSection_count; section++) {
        numberOfItems += [self.collectionView numberOfItemsInSection:section];
    }
    
    if (numberOfItems != self.numberOfItems) {
        self.numberOfItems = numberOfItems;
        [self.view bjl_updateConstraints:^(BJLConstraintMaker *make) {
            BOOL isHorizontal = BJLIsHorizontalUI(self);
            [self makeContentSize:make forHorizontal:isHorizontal];
        }];
        // !!!: `collectionView:cellForItemAtIndexPath:` bug
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        [self.collectionView reloadData];
    }
    
    [self autoEnterFullScreen];
}

// !!!: `collectionView:cellForItemAtIndexPath:` will not be called if height is 0
- (void)makeContentSize:(BJLConstraintMaker *)make forHorizontal:(BOOL)isHorizontal {
    CGSize size = [BJLPreviewCell cellSize];
    // size.width = self.numberOfItems > 0 ? size.width *= self.numberOfItems : 0.0;
    size.height = self.numberOfItems > 0 ? size.height : 0.0;
    // make.width.equalTo(@(size.width)).priorityHigh();
    make.height.equalTo(@(size.height));
    
    self.collectionView.contentInset = bjl_set(self.collectionView.contentInset, {
        // TODO: - size.width should be BJLTopBarView.customContainerView.left
        set.right = isHorizontal ? size.width : 0.0;
    });
}

- (CGFloat)viewHeightIfDisplay {
    return [BJLPreviewCell cellSize].height;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _BJLPreviewsSection_count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case BJLPreviewsSection_PPT: {
            //            return (self.room.slideshowViewController
            //                    && self.fullScreenItem.type != BJLPreviewsType_PPT
            //                    && !self.room.slideshowViewController.isBlank) ? 1 : 0;
            return (self.room.slideshowViewController
                    && self.fullScreenItem.type != BJLPreviewsType_PPT) ? 1 : 0;
        }
        case BJLPreviewsSection_presenter: {
            BOOL presenterFullScreen = (self.fullScreenItem.type == BJLPreviewsType_playing
                                        && self.fullScreenItem.playingUser
                                        && [self.fullScreenItem.playingUser isSameUser:self.presenter]
                                        && self.fullScreenItem.playingUser.cameraType == BJLCameraType_main);
            return (self.presenter
                    && !presenterFullScreen) ? 1 : 0;
        }
        case BJLPreviewsSection_presenterExtra: {
            BOOL extraPresenterFullScreen = (self.fullScreenItem.type == BJLPreviewsType_playing
                                             && self.fullScreenItem.playingUser
                                             && [self.fullScreenItem.playingUser isSameUser:self.extraPresenter]
                                             && self.fullScreenItem.playingUser.cameraType == BJLCameraType_extra);
            return (self.extraPresenter
                    && !extraPresenterFullScreen) ? 1 : 0;
        }
        case BJLPreviewsSection_recording: {
            return (self.room.recordingVM.recordingVideo
                    && self.fullScreenItem.type != BJLPreviewsType_recording) ? 1 : 0;
        }
        case BJLPreviewsSection_videoUsers: {
            return self.videoUsers.count;
        }
        case BJLPreviewsSection_audioUsers: {
            return self.audioUsers.count;
        }
        case BJLPreviewsSection_requestUsers: {
            return (self.room.loginUser.isTeacherOrAssistant && self.room.loginUser.noGroup
                    ? self.room.speakingRequestVM.speakingRequestUsers.count
                    : 0);
        }
        default: {
            return 0;
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = nil;
    switch (indexPath.section) {
        case BJLPreviewsSection_PPT:
            cellIdentifier = BJLPreviewCellID_view;
            break;
        case BJLPreviewsSection_presenter:
            cellIdentifier = (self.presenter && self.presenterVideoPlaying
                              ? BJLPreviewCellID_view_label
                              : BJLPreviewCellID_avatar_label);
            break;
        case BJLPreviewsSection_presenterExtra:
            cellIdentifier = (self.extraPresenter && self.extraPresenterVideoPlaying
                              ? BJLPreviewCellID_view_label
                              : BJLPreviewCellID_avatar_label);
            break;
        case BJLPreviewsSection_recording:
            // cellIdentifier = BJLPreviewCellID_view;
            cellIdentifier = BJLPreviewCellID_view_label;
            break;
        case BJLPreviewsSection_videoUsers:
            cellIdentifier = BJLPreviewCellID_view_label;
            break;
        case BJLPreviewsSection_audioUsers:
            cellIdentifier = BJLPreviewCellID_avatar_label;
            break;
        case BJLPreviewsSection_requestUsers:
            cellIdentifier = BJLPreviewCellID_avatar_label_buttons;
            break;
        default:
            cellIdentifier = BJLPreviewCellID_view;
            break;
    }
    
    BJLPreviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    bjl_weakify(self);
    cell.doubleTapsCallback = cell.doubleTapsCallback = ^(BJLPreviewCell *cell) {
        bjl_strongify(self);
        switch (indexPath.section) {
            case BJLPreviewsSection_PPT: {
                [self enterFullScreenWithPPTView];
                break;
            }
            case BJLPreviewsSection_presenter: {
                [self enterFullScreenWithViewForVideoPlayingUser:self.presenter];
                break;
            }
            case BJLPreviewsSection_presenterExtra: {
                [self enterFullScreenWithViewForVideoPlayingUser:self.extraPresenter];
                break;
            }
            case BJLPreviewsSection_recording: {
                [self enterFullScreenWithRecordingView];
                break;
            }
            case BJLPreviewsSection_videoUsers: {
                BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:indexPath.row];
                [self enterFullScreenWithViewForVideoPlayingUser:user];
                break;
            }
            case BJLPreviewsSection_audioUsers: {
                break;
            }
            case BJLPreviewsSection_requestUsers: {
                break;
            }
            default: {
                break;
            }
        }
    };
    
    switch (indexPath.section) {
        case BJLPreviewsSection_PPT: {
            // 更新 PPT 视图
            bjl_weakify(self);
            [self bjl_addChildViewController:self.room.slideshowViewController addSubview:^(UIView * _Nonnull parentView, UIView * _Nonnull childView) {
                bjl_strongify(self);
                [cell updateWithView:self.room.slideshowViewController.view videoRatio:0.0];
            }];
            // 隐藏 loading 状态
            [cell updateLoadingViewHidden:YES angle:self.videoLoadingRotationAngle];
            // 隐藏点赞数
            [cell updateWithLikeCount:0 hidden:YES];
            break;
        }
        case BJLPreviewsSection_presenter: {
            NSString *title = [self getShowingTitleOfUser:self.presenter];
            if (self.presenterVideoPlaying) {
                CGFloat videoRatio = [self.room.playingVM playingViewAspectRatioForUserWithID:self.presenter.ID mediaSource:self.presenter.mediaSource];
                // 更新播放视图
                [cell updateWithView:[self.room.playingVM playingViewForUserWithID:self.presenter.ID
                                                                       mediaSource:self.presenter.mediaSource]
                               title:title
                          videoRatio:videoRatio];
                
                // 更新 loading 状态
                BOOL isLoading = [[self.videoLoadingInfo bjl_numberForKey:self.presenter.mediaID defaultValue:@(NO)] boolValue];
                [cell updateLoadingViewHidden:!isLoading
                                        angle:self.videoLoadingRotationAngle];
            }
            else {
                // 更新播放视图
                [cell updateWithImageURLString:self.presenter.avatar
                                         title:title
                                      hasVideo:bjl_as(self.presenter, BJLMediaUser).videoOn];
                // 隐藏 loading 状态
                [cell updateLoadingViewHidden:YES angle:self.videoLoadingRotationAngle];
            }
            // 隐藏点赞数
            [cell updateWithLikeCount:0 hidden:YES];
            break;
        }
        case BJLPreviewsSection_presenterExtra: {
            BJLMediaUser *extraPresenter = self.extraPresenter;
            NSString *title = BJLVideoTitleWithMediaSource(extraPresenter.mediaSource);
            if (self.extraPresenterVideoPlaying) {
                // 更新播放视图
                CGFloat videoRatio = [self.room.playingVM playingViewAspectRatioForUserWithID:extraPresenter.ID mediaSource:extraPresenter.mediaSource];
                [cell updateWithView:[self.room.playingVM playingViewForUserWithID:extraPresenter.ID mediaSource:extraPresenter.mediaSource]
                               title:title
                          videoRatio:videoRatio];
                // 更新 loading 状态
                BOOL isLoadingViewHidden = YES;
                [cell updateLoadingViewHidden:isLoadingViewHidden angle:self.videoLoadingRotationAngle];
            }
            else {
                // 更新播放视图
                [cell updateWithImageURLString:self.extraPresenter.avatar
                                         title:title
                                      hasVideo:bjl_as(self.extraPresenter, BJLMediaUser).videoOn];
                // 隐藏 loading 状态
                [cell updateLoadingViewHidden:YES angle:self.videoLoadingRotationAngle];
            }
            
            // 隐藏点赞数
            [cell updateWithLikeCount:0 hidden:YES];
            break;
        }
        case BJLPreviewsSection_recording: {
            // 更新采集视图
            CGFloat videoRatio = self.room.recordingVM.inputVideoAspectRatio;
            [cell updateWithView:self.room.recordingView
                           title:[self getShowingTitleOfUser:self.room.loginUser]
                      videoRatio:videoRatio];
            // 隐藏 loading 状态
            [cell updateLoadingViewHidden:YES angle:self.videoLoadingRotationAngle];
            // 更新点赞数, 用户不是学生不显示, 登录用户是学生，用户点赞数为0不显示
            NSInteger count = [self.room.roomVM.likeList bjl_integerForKey:self.room.loginUser.number];
            BOOL hidden = NO;
            if ((!count && self.room.loginUser.isStudent)
                || self.room.loginUser.isTeacherOrAssistant) {
                hidden = YES;
            }
            [cell updateWithLikeCount:count hidden:hidden];
            break;
        }
        case BJLPreviewsSection_videoUsers: {
            // 更新播放视图
            BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:indexPath.row];
            CGFloat videoRatio = [self.room.playingVM playingViewAspectRatioForUserWithID:user.ID mediaSource:user.mediaSource];
            [cell updateWithView:[self.room.playingVM playingViewForUserWithID:user.ID mediaSource:user.mediaSource]
                           title:[self getShowingTitleOfUser:user]
                      videoRatio:videoRatio];
            
            // 更新 loading 状态
            BOOL isLoading = [[self.videoLoadingInfo bjl_numberForKey:user.mediaID defaultValue:@(NO)] boolValue];
            [cell updateLoadingViewHidden:!isLoading angle:self.videoLoadingRotationAngle];
            // 更新点赞数, 用户不是学生不显示, 登录用户是学生，用户点赞数为0不显示
            NSInteger count = [self.room.roomVM.likeList bjl_integerForKey:user.number];
            BOOL hidden = NO;
            if ((!count && self.room.loginUser.isStudent)
                || user.isTeacherOrAssistant) {
                hidden = YES;
            }
            [cell updateWithLikeCount:count hidden:hidden];
            break;
        }
        case BJLPreviewsSection_audioUsers: {
            // 更新头像视图
            BJLMediaUser *user = [self.audioUsers bjl_objectAtIndex:indexPath.row];
            [cell updateWithImageURLString:user.avatar
                                     title:[self getShowingTitleOfUser:user]
                                  hasVideo:user.videoOn];
            // 隐藏 loading 状态
            [cell updateLoadingViewHidden:YES angle:self.videoLoadingRotationAngle];
            // 更新点赞数, 用户不是学生不显示, 登录用户是学生，用户点赞数为0不显示
            NSInteger count = [self.room.roomVM.likeList bjl_integerForKey:user.number];
            BOOL hidden = NO;
            if ((!count && self.room.loginUser.isStudent)
                || user.isTeacherOrAssistant) {
                hidden = YES;
            }
            [cell updateWithLikeCount:count hidden:hidden];
            break;
        }
        case BJLPreviewsSection_requestUsers: {
            // 更新请求举手用户
            BJLUser *user = [self.room.speakingRequestVM.speakingRequestUsers bjl_objectAtIndex:indexPath.row];
            [cell updateWithImageURLString:user.avatar
                                     title:[NSString stringWithFormat:@"%@举手中", user.displayName ?: @""]
                                  hasVideo:NO];
            // 隐藏 loading 状态
            [cell updateLoadingViewHidden:YES angle:self.videoLoadingRotationAngle];
            if (self.room.loginUser.isTeacherOrAssistant
                && self.room.loginUser.noGroup) {
                bjl_weakify(self);
                cell.actionCallback = cell.actionCallback ?: ^(BJLPreviewCell *cell, BOOL allowed) {
                    bjl_strongify(self);
                    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
                    BJLUser *user = [self.room.speakingRequestVM.speakingRequestUsers bjl_objectAtIndex:indexPath.row];
                    if (user) {
                        [self.room.speakingRequestVM replySpeakingRequestToUserID:user.ID allowed:allowed];
                    }
                };
            }
            break;
        }
        default: {
            break;
        }
    }
    
    return cell;
}

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
    else if (user.isAssistant && [user isSameCameraUser:self.presenter]) {
        return @"主讲";
    }
    else if (user.isAssistant && ![user isSameCameraUser:self.presenter]) {
        return (config.assistantLabel) ?: nil;
    }
    return nil;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    switch (indexPath.section) {
        case BJLPreviewsSection_PPT: {
            [self showMenuForPPTViewSourceView:cell];
            break;
        }
        case BJLPreviewsSection_presenter: {
            [self showMenuForPlayingUser:self.presenter sourceView:cell];
            break;
        }
        case BJLPreviewsSection_presenterExtra: {
            [self showMenuForPlayingUser:self.extraPresenter sourceView:cell];
            break;
        }
        case BJLPreviewsSection_recording: {
            [self showMenuForRecordingViewSourceView:cell];
            break;
        }
        case BJLPreviewsSection_videoUsers: {
            BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:indexPath.row];
            [self showMenuForPlayingUser:user sourceView:cell];
            break;
        }
        case BJLPreviewsSection_audioUsers: {
            BJLMediaUser *user = [self.audioUsers bjl_objectAtIndex:indexPath.row];
            [self showMenuForPlayingUser:user sourceView:cell];
            break;
        }
        case BJLPreviewsSection_requestUsers: {
            break;
        }
        default: {
            break;
        }
    }
    
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - menu

- (void)showMenuForFullScreenItemSourceView:(nullable UIView *)sourceView {
    switch (self.fullScreenItem.type) {
        case BJLPreviewsType_PPT:
            [self showMenuForPPTViewSourceView:sourceView];
            break;
        case BJLPreviewsType_playing:
            [self showMenuForPlayingUser:self.fullScreenItem.playingUser sourceView:sourceView];
            break;
        case BJLPreviewsType_recording:
            [self showMenuForRecordingViewSourceView:sourceView];
            break;
        default:
            break;
    }
}

- (void)showMenuForPPTViewSourceView:(nullable UIView *)sourceView {
    if (self.fullScreenItem.type == BJLPreviewsType_PPT) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:@"PPT"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert bjl_addActionWithTitle:@"全屏"
                            style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * _Nonnull action) {
                              if (self.fullScreenItem.type == BJLPreviewsType_PPT) {
                                  return;
                              }
                              [self enterFullScreenWithPPTView];
                          }];
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    
    [self showAlert:alert sourceView:sourceView];
}

- (void)showMenuForRecordingViewSourceView:(nullable UIView *)sourceView {
    if (!self.room.recordingVM.recordingVideo) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:@"采集视频"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.fullScreenItem.type != BJLPreviewsType_recording) {
        [alert bjl_addActionWithTitle:@"全屏"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
                                  if (!self.room.recordingVM.recordingVideo) {
                                      return;
                                  }
                                  [self enterFullScreenWithRecordingView];
                              }];
    }
    
    if (self.room.loginUser.isTeacher
        && !self.room.loginUserIsPresenter
        && self.room.featureConfig.canChangePresenter) {
        [alert bjl_addActionWithTitle:@"设为主讲"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
                                  [self.room.onlineUsersVM requestChangePresenterWithUserID:self.room.loginUser.ID];
                              }];
    }
    
    [alert bjl_addActionWithTitle:@"切换摄像头"
                            style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * _Nonnull action) {
                              if (!self.room.recordingVM.recordingVideo) {
                                  return;
                              }
                              BJLError *error = [self.room.recordingVM updateUsingRearCamera:!self.room.recordingVM.usingRearCamera];
                              if (error) {
                                  [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                              }
                          }];
    
    [alert bjl_addActionWithTitle:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                   ? @"开启美颜" : @"关闭美颜")
                            style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * _Nonnull action) {
                              if (!self.room.recordingVM.recordingVideo) {
                                  return;
                              }
                              BJLError *error = [self.room.recordingVM updateVideoBeautifyLevel:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                                                                                 ? BJLVideoBeautifyLevel_on : BJLVideoBeautifyLevel_off)];
                              if (error) {
                                  [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                              }
                          }];
    
    [alert bjl_addActionWithTitle:@"关闭摄像头"
                            style:UIAlertActionStyleDestructive
                          handler:^(UIAlertAction * _Nonnull action) {
                              if (!self.room.recordingVM.recordingVideo) {
                                  return;
                              }
                              BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                                          recordingVideo:NO];
                              if (error) {
                                  [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                              }
                              else {
                                  [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                                                 ? @"摄像头已打开"
                                                                 : @"摄像头已关闭")];
                              }
                          }];
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    
    [self showAlert:alert sourceView:sourceView];
}

- (void)showMenuForPlayingUser:(BJLMediaUser *)playingUser sourceView:(nullable UIView *)sourceView {
    playingUser = [self.room.playingVM playingUserWithID:playingUser.ID number:playingUser.number mediaSource:playingUser.mediaSource];
    if (!playingUser) {
        return;
    }
    
    NSString *title = playingUser.displayName;
    if(playingUser.cameraType == BJLCameraType_extra) {
        title = BJLVideoTitleWithMediaSource(playingUser.mediaSource);
    }
    
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:title
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    BOOL playingVideo = (([playingUser isSameMediaUser:self.presenter] && self.presenterVideoPlaying)
                         || [playingUser containedInMediaUsers:self.room.playingVM.videoPlayingUsers]);
    
    if (playingVideo) {
        BOOL isFullScreen = (self.fullScreenItem.type == BJLPreviewsType_playing
                             && self.fullScreenItem.playingUser == playingUser);
        if (!isFullScreen) {
            [alert bjl_addActionWithTitle:@"全屏"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                      if (![playingUser containedInMediaUsers:self.videoUsers]
                                          && [playingUser containedInMediaUsers:self.audioUsers]) {
                                          return;
                                      }
                                      BOOL playingVideo = (([playingUser isSameUser:self.presenter] && self.presenterVideoPlaying)
                                                           || [playingUser containedInMediaUsers:self.room.playingVM.videoPlayingUsers]);
                                      BOOL isFullScreen = (self.fullScreenItem.type == BJLPreviewsType_playing
                                                           && self.fullScreenItem.playingUser == playingUser);
                                      if (playingVideo && !isFullScreen) {
                                          [self enterFullScreenWithViewForVideoPlayingUser:playingUser];
                                      }
                                  }];
        }
        
        if (playingUser.definitions.count > 1) {
            NSInteger definitionIndex = 0, currentDefinitionIndex = [self.room.playingVM definitionIndexForUserWithID:playingUser.ID mediaSource:playingUser.mediaSource];
            for (BJLLiveDefinitionKey key in [playingUser.definitions copy]) {
                NSString *definitionName = BJLLiveDefinitionNameForKey(key) ?: key;
                if (currentDefinitionIndex == definitionIndex) {
                    UIAlertAction *action =
                    [alert bjl_addActionWithTitle:[NSString stringWithFormat:@"正在播放%@视频", definitionName]
                                            style:UIAlertActionStyleDefault
                                          handler:nil];
                    action.enabled = NO;
                    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"_%@%@%@:", @"set", @"Check", @"ed"]);
                    if ([action respondsToSelector:sel]) {
                        BOOL checked = YES;
                        [action bjl_invokeWithSelector:sel argument:&checked];
                    }
                }
                else {
                    [alert bjl_addActionWithTitle:[NSString stringWithFormat:@"打开%@视频", definitionName]
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull action) {
                                              [self playVideoWithUser:playingUser definitionIndex:definitionIndex];
                                          }];
                }
                definitionIndex++;
            }
        }
        
        [alert bjl_addActionWithTitle:@"关闭视频"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
                                  if (![playingUser containedInMediaUsers:self.videoUsers]
                                      && [playingUser containedInMediaUsers:self.audioUsers]) {
                                      return;
                                  }
                                  BOOL playingVideo;
                                  if (playingUser.cameraType == BJLCameraType_main) {
                                      playingVideo = (([playingUser isSameMediaUser:self.presenter] && self.presenterVideoPlaying)
                                                      || [playingUser containedInMediaUsers:self.room.playingVM.videoPlayingUsers]);
                                  }
                                  else {
                                      playingVideo = (([playingUser isSameMediaUser:self.extraPresenter] && self.extraPresenterVideoPlaying)
                                                      || [playingUser containedInMediaUsers:self.room.playingVM.videoPlayingUsers]);
                                  }
                                  
                                  if (playingVideo) {
                                      [self.room.playingVM updatePlayingUserWithID:playingUser.ID videoOn:NO mediaSource:playingUser.mediaSource];
                                  }
                                  [self.autoPlayVideoBlacklist addObject:[self videoKeyForUser:playingUser] ?: @""];
                              }];
    }
    else if (playingUser.videoOn) {
        if (playingUser.definitions.count > 1) {
            NSInteger definitionIndex = 0;
            for (BJLLiveDefinitionKey key in [playingUser.definitions copy]) {
                NSString *definitionName = BJLLiveDefinitionNameForKey(key) ?: key;
                [alert bjl_addActionWithTitle:[NSString stringWithFormat:@"打开%@视频", definitionName]
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
                                          [self playVideoWithUser:playingUser definitionIndex:definitionIndex];
                                      }];
                definitionIndex++;
            }
        }
        else {
            [alert bjl_addActionWithTitle:@"打开视频"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                      [self playVideoWithUser:playingUser];
                                  }];
        }
    }
    else {
        alert.message = @"对方没有开启摄像头";
    }
    
    if (!self.room.featureConfig.disableGrantDrawing
        && self.room.loginUser.isTeacherOrAssistant
        && self.room.loginUser.noGroup
        && !playingUser.isTeacherOrAssistant) {
        BOOL wasGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:playingUser.number];
        [alert bjl_addActionWithTitle:wasGranted ? @"收回画笔" : @"授权画笔"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
                                  BJLError *error =
                                  [self.room.drawingVM updateDrawingGranted:!wasGranted
                                                                 userNumber:playingUser.number
                                                                      color:nil];
                                  if (error) {
                                      [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                  }
                              }];
    }
    
    if (self.room.loginUser.isTeacher
        && playingUser.isAssistant
        && self.room.featureConfig.canChangePresenter) {
        if ([self.presenter isSameUser:playingUser]) {
            [alert bjl_addActionWithTitle:@"收回主讲"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                      [self.room.onlineUsersVM requestChangePresenterWithUserID:self.room.loginUser.ID];
                                  }];
        }
        else {
            [alert bjl_addActionWithTitle:@"设为主讲"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                      [self.room.onlineUsersVM requestChangePresenterWithUserID:playingUser.ID];
                                  }];
        }
    }
    
    if (self.room.loginUser.isTeacherOrAssistant
        && self.room.loginUser.noGroup
        && playingUser.isStudent) {
        [alert bjl_addActionWithTitle:@"奖励"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
                                  BJLError *error = [self.room.roomVM sendLikeForUserNumber:playingUser.number];
                                  if (error) {
                                      [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                  }
                              }];
    }
    
    if (self.room.loginUser.isTeacherOrAssistant
        && self.room.loginUser.noGroup
        && self.room.roomInfo.roomType == BJLRoomType_1vNClass
        && !playingUser.isTeacher) {
        [alert bjl_addActionWithTitle:@"结束发言"
                                style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * _Nonnull action) {
                                  /*
                                   if (![playingUser containedInUsers:self.videoUsers]
                                   && ![playingUser containedInUsers:self.audioUsers]) {
                                   return;
                                   } */
                                  [self.room.recordingVM remoteChangeRecordingWithUser:playingUser
                                                                               audioOn:NO
                                                                               videoOn:NO];
                              }];
    }
    
    [alert bjl_addActionWithTitle:alert.actions.count ? @"取消" : @"知道了"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    
    [self showAlert:alert sourceView:sourceView];
}

#pragma mark - actions

- (void)clearAllLikeRecord {
    [self reloadCollectionView];
    self.fullScreenItem.likeCount = 0;
    if (self.fullScreenItemChangedCallback) {
        self.fullScreenItemChangedCallback(self.fullScreenItem);
    }
}

#pragma mark - play & auto-play

- (void)playVideoWithUser:(BJLMediaUser *)playingUser {
    [self playVideoWithUser:playingUser definitionIndex:0];
}

- (void)playVideoWithUser:(BJLMediaUser *)playingUser definitionIndex:(NSInteger)definitionIndex {
    playingUser = [self.room.playingVM playingUserWithID:playingUser.ID number:playingUser.number mediaSource:playingUser.mediaSource];
    if ([playingUser containedInMediaUsers:self.videoUsers]
        || (![playingUser containedInMediaUsers:self.audioUsers]
            && ![playingUser isSameUser:self.presenter])) {
            return;
        }
    
    BOOL playingVideo = [playingUser containedInMediaUsers:self.room.playingVM.videoPlayingUsers];
    NSInteger currDefinitionIndex = [self.room.playingVM definitionIndexForUserWithID:playingUser.ID mediaSource:playingUser.mediaSource];
    if ((!playingVideo || definitionIndex != currDefinitionIndex)
        && playingUser.videoOn) {
        BJLError *error = [self.room.playingVM updatePlayingUserWithID:playingUser.ID videoOn:YES mediaSource:playingUser.mediaSource definitionIndex:definitionIndex];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
    // 播放视频后恢复自动打开逻辑
    [self.autoPlayVideoBlacklist removeObject:[self videoKeyForUser:playingUser] ?: @""];
}

#pragma mark -

- (void)showAlert:(UIAlertController *)alert sourceView:(nullable UIView *)sourceView {
    if (alert.preferredStyle == UIAlertControllerStyleActionSheet) {
        sourceView = sourceView ?: self.view;
        alert.popoverPresentationController.sourceView = sourceView;
        alert.popoverPresentationController.sourceRect = ({
            CGRect rect = sourceView.bounds;
            rect.origin.y = CGRectGetMaxY(rect) - 1.0;
            rect.size.height = 1.0;
            rect;
        });
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    }
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)videoKeyForUser:(BJLMediaUser *)user {
    return [NSString stringWithFormat:@"%@-%td", user.number, user.mediaSource];
}

#pragma mark - weak network
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
         自己下行有丢包时, ((有上行丢包&&下行丢包低于上行2倍) || 无上行)->提示自己网络差, (有上行&&上行无丢包) || 下行丢包高于上行丢包2倍 -> 对方网络差
         */
        NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];

        NSString *loginUserKey = [self userLossRateKeyWithUserID:self.room.loginUser.ID mediaSource:BJLMediaSource_mainCamera];
        NSMutableArray<NSDictionary *> *loginUserLossRateArray = [[self.lossRateDictionary bjl_arrayForKey:loginUserKey] mutableCopy];
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
            [self.lossRateDictionary bjl_setObject:loginUserLossRateArray forKey:loginUserKey];
        }
        BJLNetworkStatus loginUserLossRateStatus = [self netWorkStatusWithLossRate:loginUserLossRate];
        // 自己是否有上行
        BOOL hasUpPackage = self.room.recordingVM.recordingVideo || self.room.recordingVM.recordingAudio;
        // 自己上行是否丢包
        BOOL hasUpPackageLoss = hasUpPackage && loginUserLossRateStatus != BJLNetworkStatus_normal;

        for (NSString *userKey in [self.lossRateDictionary.allKeys copy]) {
            NSString *userID = [self userIDForUserLossRateKey:userKey];
            BJLMediaSource mediaSourcce = [self mediaSourceForUserLossRateKey:userKey];
            // 读取每个用户的丢包率数据 ,除了当前登录用户
            if([userID isEqualToString:self.room.loginUser.ID]) {
                continue;
            }
            
            NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
            NSInteger count = lossRateArray.count;
            
            if (count > 0) {
                CGFloat totalLossRate = 0.0f;
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
                
                // 对于主讲人窗口单独处理, 计算广播取到的主讲人丢包率
                if([userID isEqualToString:self.room.onlineUsersVM.currentPresenter.ID]) {
                    CGFloat presenterLossRate = 0.0f;
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
                            // 更新主讲人丢包率的字典
                            [self.presenterLossRateDictionary bjl_setObject:presenterLossRateArray forKey:presenterUserKey];
                            if([presenterUserKey isEqualToString:userKey]) {
                                presenterLossRate = (presenterLossRateArray.count > 0) ? totalLossRate / presenterLossRateArray.count : 0.0f;
                            }
                        }
                    }
                    BJLNetworkStatus presenterLossRateStatus = [self netWorkStatusWithLossRate:presenterLossRate];

                    if(BJLNetworkStatus_normal != status && BJLNetworkStatus_normal != presenterLossRateStatus && lossRate <= presenterLossRate * 2 ) {
                        // 更新主讲人窗口弱网
                        [self updatePresenterNetWorkWitUserID:userID mediaSource:mediaSourcce status:presenterLossRateStatus];
                    }
                    else if((BJLNetworkStatus_normal != status && BJLNetworkStatus_normal != presenterLossRateStatus && lossRate > presenterLossRate * 2 ) || (BJLNetworkStatus_normal != status && BJLNetworkStatus_normal == presenterLossRateStatus)) {
                        // 更新自己窗口弱网
                        [self updateRecordingNetWorkWitUserID:self.room.loginUser.ID mediaSource:BJLMediaSource_mainCamera status:MAX(status, loginUserLossRateStatus)];
                    }
                    continue;
                }
                
                // (下行丢包&&自己无上行推流) || (上下行丢包&&下行窗口低于上行两倍)
                if((status != BJLNetworkStatus_normal && !hasUpPackage)
                   || (hasUpPackageLoss && lossRate <= loginUserLossRate * 2 && status != BJLNetworkStatus_normal)) {
                    // 直接自己窗口展示弱网
                    loginUserLossRateStatus = hasUpPackageLoss ? loginUserLossRateStatus : status;
                    [self updateRecordingNetWorkWitUserID:self.room.loginUser.ID mediaSource:BJLMediaSource_mainCamera status:loginUserLossRateStatus];
                }
                else {
                    // (他人非主讲窗口有丢包 && 自己有上行无丢包) || (上下行均丢包&&当前窗口下行高于上行两倍)
                    if((status != BJLNetworkStatus_normal && hasUpPackage && !hasUpPackageLoss)
                       || (status != BJLNetworkStatus_normal && loginUserLossRateStatus != BJLNetworkStatus_normal && lossRate > loginUserLossRate * 2)) {
                        // 他人窗口提示弱网
                        [self updateplayerNetWorkWitUserID:userID mediaSource:mediaSourcce status:status];
                    }
                }
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

- (void)updatePresenterNetWorkWitUserID:(NSString *)userID mediaSource:(BJLMediaSource)mediaSource status:(BJLNetworkStatus)status {
    BJLPreviewCell *cell = nil;
    if([self.presenter.ID isEqualToString:userID] && self.presenter.mediaSource == mediaSource) {
        NSInteger number = [self.collectionView numberOfItemsInSection:BJLPreviewsSection_presenter];
        if(number == 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:BJLPreviewsSection_presenter];
            cell = (BJLPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        }
    }
    else if([self.extraPresenter.ID isEqualToString:userID] && self.extraPresenter.mediaSource == mediaSource) {
        NSInteger number = [self.collectionView numberOfItemsInSection:BJLPreviewsSection_presenterExtra];
        if(number == 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:BJLPreviewsSection_presenterExtra];
            cell = (BJLPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        }
    }
    if(cell) {
        [cell updateViewWithNetWorkLossRateStatus:status];
    }
}

- (void)updateRecordingNetWorkWitUserID:(NSString *)userID mediaSource:(BJLMediaSource)mediaSource status:(BJLNetworkStatus)status {
    BJLPreviewCell *cell = nil;
    NSInteger number = [self.collectionView numberOfItemsInSection:BJLPreviewsSection_recording];
    if(number == 1) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:BJLPreviewsSection_recording];
        cell = (BJLPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    }
    if(cell) {
        [cell updateViewWithNetWorkLossRateStatus:status];
    }
}

- (void)updateplayerNetWorkWitUserID:(NSString *)userID mediaSource:(BJLMediaSource)mediaSource status:(BJLNetworkStatus)status {
    BJLPreviewCell *cell = nil;

    for (BJLMediaUser *videoUser in self.videoUsers) {
        if([userID isEqualToString:videoUser.ID] && mediaSource == videoUser.mediaSource) {
            NSInteger index = [self.videoUsers indexOfObject:videoUser];
            if(index != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:BJLPreviewsSection_videoUsers];
                cell = (BJLPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                break;
            }
        }
    }
    
    for (BJLMediaUser *audioUser in self.audioUsers) {
        if([userID isEqualToString:audioUser.ID] && mediaSource == audioUser.mediaSource) {
            NSInteger index = [self.audioUsers indexOfObject:audioUser];
            if(index != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:BJLPreviewsSection_audioUsers];
                cell = (BJLPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                break;
            }
        }
    }

    if(cell) {
        [cell updateViewWithNetWorkLossRateStatus:status];
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

@end

NS_ASSUME_NONNULL_END

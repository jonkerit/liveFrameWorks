//
//  BJLScVideosViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScVideosViewController.h"

typedef NS_ENUM(NSInteger, BJLScVideoSection) {
    BJLScVideoSection_PPT,
    BJLScVideoSection_recording,
    BJLScVideoSection_playing,
    _BJLScVideoSection_count
};

static NSString * const cellReuseIdentifier = @"userSeatCell";

@interface BJLScVideoCell : UICollectionViewCell

@end

@implementation BJLScVideoCell

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

@end

@interface BJLScVideosViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic, nullable) BJLScMediaInfoView *recordingMediaInfoView; // 采集媒体视图
@property (nonatomic, nullable, weak) BJLScMediaInfoView *teacherExtraMediaInfoView; // 老师的辅助摄像头，目前如果存在，将不显示课件视图
@property (nonatomic) NSMutableArray<BJLMediaUser *> *videoUsers; // 除老师外的媒体用户，老师的视频显示在其他位置
@property (nonatomic) NSMutableDictionary<NSString *, BJLScMediaInfoView *> *mainUserMediaInfoViews; // key -> userID
@property (nonatomic) NSMutableDictionary<NSString *, BJLScMediaInfoView *> *extraUserMediaInfoViews; // key -> userID

/** 区分大屏视图和当前视频列表的状态的数据，如果还需要添加新的可以封装成 model */
@property (nonatomic, readwrite) NSInteger majorWindowIndex; // -1 表示当前无全屏视频
@property (nonatomic, nullable) BJLMediaUser *majorMediaUser; // 全屏区域的媒体用户，majorWindowIndex 为 -1 时为空，大屏为采集时视图为空
@property (nonatomic, nullable) BJLScMediaInfoView *majorMediaInfoView; // 全屏区域的媒体视图， majorWindowIndex 为 -1 时为空，可以为采集视图

@end

@implementation BJLScVideosViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
        self.majorWindowIndex = -1;
        self.videoUsers = [NSMutableArray new];
        self.mainUserMediaInfoViews = [NSMutableDictionary new];
        self.extraUserMediaInfoViews = [NSMutableDictionary new];
        [self makeObserving];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeSubviewsAndConstraints];
}

#pragma mark - subview

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor bjl_colorWithHexString:@"#BDC6CF" alpha:1.0];
    self.collectionView = ({
        // layout: 不要设置 itemSize，触发 UICollectionViewDelegateFlowlayout
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = BJLScOnePixel;
        layout.minimumLineSpacing = BJLScOnePixel;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.accessibilityLabel = BJLKeypath(self, collectionView);
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.pagingEnabled = NO;
        collectionView.scrollEnabled = YES;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [collectionView registerClass:[BJLScVideoCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
        collectionView;
    });
    [self.view addSubview:self.collectionView];
    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    // 播放
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.mainPlayingAdapterVM, playingUsers),
                         BJLMakeProperty(self.room.extraPlayingAdapterVM, playingUsers)]
              observer:(BJLPropertiesObserver)^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateVideoUsersWithMainAndExtraPlayingUsers];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self.collectionView reloadData];
        return YES;
    }];
    
    // 采集
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.recordingVM, recordingAudio),
                         BJLMakeProperty(self.room.recordingVM, recordingVideo)]
              observer:(BJLPropertiesObserver)^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  if (self.room.loginUser.isTeacher) {
                      return;
                  }
                  if (self.room.recordingVM.recordingAudio || self.room.recordingVM.recordingVideo) {
                      if (!self.recordingMediaInfoView) {
                          self.recordingMediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:self.room.loginUser];
                      }
                  }
                  else {
                      if (self.recordingMediaInfoView && self.recordingMediaInfoView.superview) {
                          [self.recordingMediaInfoView removeFromSuperview];
                      }
                      self.recordingMediaInfoView = nil;
                  }
                  if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                      return;
                  }
                  [self.collectionView reloadData];
              }];
}

#pragma mark - update

- (void)resetVideo {
    // 清理大屏的用户视图，更新视频列表数据
    self.majorWindowIndex = -1;
    if (self.majorMediaInfoView) {
        [self.majorMediaInfoView removeFromSuperview];
        self.majorMediaInfoView = nil;
    }
    self.majorMediaUser = nil;
    self.recordingMediaInfoView.isFullScreen = NO;
    [self updateVideoUsersWithMainAndExtraPlayingUsers];
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    [self.collectionView reloadData];
}

- (void)updateVideoUsersWithMainAndExtraPlayingUsers {
    NSMutableArray<BJLMediaUser *> *videoUsers = [self.room.mainPlayingAdapterVM.playingUsers mutableCopy];
    NSMutableArray<BJLMediaUser *> *extraPlayingUser = [self.room.extraPlayingAdapterVM.playingUsers mutableCopy];
    BJLMediaUser *mediaUser = nil;
    // main playing user
    for (BJLMediaUser *user in [videoUsers copy]) {
        if (user.isTeacher) {
            // 移除老师
            [videoUsers bjl_removeObject:user];
        }
        if (self.majorMediaUser && [self isSameCameraUser:user withUser:self.majorMediaUser]) {
            // 移除在大屏视图的视频流
            [videoUsers bjl_removeObject:user];
            mediaUser = user;
        }
    }
    
    // extra playing user
    for (BJLMediaUser *user in [extraPlayingUser copy]) {
        if (self.majorMediaUser && [self isSameCameraUser:user withUser:self.majorMediaUser]) {
            mediaUser = user;
        }
        else {
            // 添加不在大屏视图的不是老师的辅助摄像头视图
            if (!user.isTeacher) {
                [videoUsers bjl_addObject:user];
            }
            // 如果大屏视频有数据，但是不是老师，并且当前存在老师的辅助摄像头的媒体信息视图，也需要添加老师的辅助摄像头
            else if (self.majorMediaInfoView && !self.majorMediaUser.isTeacher && self.teacherExtraMediaInfoView && user.isTeacher) {
                [videoUsers bjl_addObject:user];
            }
        }
    }
    // 在大屏视图的用户不属于 playingUsers 时，归还 PPT 到大屏
    if (self.majorMediaUser && !mediaUser) {
        if (self.resetPPTCallback) {
            self.resetPPTCallback();
        }
    }
    self.videoUsers = videoUsers;
    [self updateUserMediaInfoViewsWithVideoUsers];
}

- (void)updateUserMediaInfoViewsWithVideoUsers {
    NSMutableDictionary<NSString *, BJLScMediaInfoView *> *mainUserMediaInfoViews = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, BJLScMediaInfoView *> *extraUserMediaInfoViews = [NSMutableDictionary new];
    for (BJLMediaUser *user in [self.videoUsers copy]) {
        BJLScMediaInfoView *mediaInfoView = nil;
        if (user.cameraType == BJLCameraType_main) {
            mediaInfoView = [self.mainUserMediaInfoViews bjl_objectForKey:user.ID class:[BJLScMediaInfoView class]];
            if (!mediaInfoView) {
                mediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:user];
            }
            // 添加数据到新的字典中
            [mainUserMediaInfoViews bjl_setObject:mediaInfoView forKey:user.ID];
        }
        else if (user.cameraType == BJLCameraType_extra) {
            mediaInfoView = [self.extraUserMediaInfoViews bjl_objectForKey:user.ID class:[BJLScMediaInfoView class]];
            if (!mediaInfoView && !user.isTeacher) {
                mediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:user];
            }
            else {
                // 老师辅助摄像头数据一般直接获取
                mediaInfoView = self.teacherExtraMediaInfoView ?: [[BJLScMediaInfoView alloc] initWithRoom:self.room user:user];
            }
            // 添加数据到新的字典中
            [extraUserMediaInfoViews bjl_setObject:mediaInfoView forKey:user.ID];
        }
        mediaInfoView.isFullScreen = NO;
    }
    self.mainUserMediaInfoViews = mainUserMediaInfoViews;
    self.extraUserMediaInfoViews = extraUserMediaInfoViews;
}

#pragma mark - replace

- (void)replaceMajorContentViewAtIndex:(NSInteger)index recording:(BOOL)recording teacherExtraMediaInfoView:(nullable BJLScMediaInfoView *)teacherExtraMediaInfoView {
    self.majorWindowIndex = index;
    if (self.majorMediaInfoView) {
        [self.majorMediaInfoView removeFromSuperview];
    }
    self.teacherExtraMediaInfoView = teacherExtraMediaInfoView;
    // 大屏要替换成采集或 PPT
    if (index == -1) {
        // 采集
        if (recording) {
            self.majorMediaUser = nil;
            self.majorMediaInfoView =  self.recordingMediaInfoView;
            self.recordingMediaInfoView.isFullScreen = YES;
        }
        // PPT 或者老师辅助摄像头
        else {
            self.majorMediaUser = nil;
            self.majorMediaInfoView = nil;
            self.recordingMediaInfoView.isFullScreen = NO;
        }
    }
    // 大屏将要替换新的视频列表的非采集视频，index 不为-1 时，不可能为采集
    else {
        self.majorMediaInfoView = [self mediaInfoViewWithIndex:index];
        self.majorMediaUser = self.majorMediaInfoView.mediaUser;
        self.recordingMediaInfoView.isFullScreen = NO;
    }
    [self updateVideoUsersWithMainAndExtraPlayingUsers];
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    [self.collectionView reloadData];
}
#pragma mark - getter

- (CGSize)itemSize {    
    CGFloat itemWidth = 0.0;
    CGFloat itemHeight = self.collectionView.bounds.size.height;
    itemWidth = itemHeight * 16.9 / 9.0;
    
    // 根据屏幕 scale 丢弃部分 itemWidth 精度，保证计算值与屏幕实际渲染效果一致
    CGFloat screenScale = [UIScreen mainScreen].scale;
    itemWidth = floor(itemWidth * screenScale) / screenScale;
    
    return CGSizeMake(itemWidth, itemHeight);
}

- (BJLScMediaInfoView *)mediaInfoViewWithIndex:(NSInteger)index {
    BJLScMediaInfoView *mediaInfoView = nil;
    BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:index];
    if (user.cameraType == BJLCameraType_main) {
        mediaInfoView = [self.mainUserMediaInfoViews bjl_objectForKey:user.ID class:[BJLScMediaInfoView class]];
    }
    else {
        mediaInfoView = [self.extraUserMediaInfoViews bjl_objectForKey:user.ID class:[BJLScMediaInfoView class]];
    }
    return mediaInfoView;
}

// 同一个摄像头的类型的视频使用一个窗口，不展示为多个窗口
- (BOOL)isSameCameraUser:(BJLMediaUser *)frontUser withUser:(BJLMediaUser *)laterUser {
    if ([frontUser.ID isEqualToString:laterUser.ID] && frontUser.cameraType == laterUser.cameraType) {
        return YES;
    }
    return NO;
}

#pragma mark - <UICollectionViewDelegateFlowlayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self itemSize];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewFlowLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    CGSize itemSize = [self itemSize];
    NSInteger totalItems = (self.majorMediaInfoView && !self.teacherExtraMediaInfoView ? 1 : 0) + ((self.recordingMediaInfoView && self.majorMediaInfoView != self.recordingMediaInfoView) ? 1 : 0) + self.videoUsers.count;
    CGFloat combinedItemWidth = (totalItems * itemSize.width) + ((totalItems - 1) * BJLScOnePixel);
    CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
    padding = padding > 0.0 ? padding : 0.0;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    padding = floor(padding * screenScale) / screenScale;
    switch (section) {
        case BJLScVideoSection_PPT:
            return UIEdgeInsetsMake(0.0, padding, 0.0, 0.0);
            
        case BJLScVideoSection_recording:
            return UIEdgeInsetsZero;
            
        case BJLScVideoSection_playing:
            return UIEdgeInsetsMake(0.0, 0.0, 0.0, padding);

        default:
            return UIEdgeInsetsZero;
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger count = _BJLScVideoSection_count;
    return count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = 0;
    switch (section) {
        case BJLScVideoSection_PPT:
            // ppt t用户列表区域 存在老师辅助摄像头时不显示，大屏区域不存在用户视频时不显示，不应同时有 不存在老师辅助摄像头，但大屏区域有用户视频的情况
            count = (self.majorMediaInfoView && !self.teacherExtraMediaInfoView ? 1 : 0);
            break;
            
        case BJLScVideoSection_recording:
            // recording
            count = (self.recordingMediaInfoView && self.majorMediaInfoView != self.recordingMediaInfoView) ? 1 : 0;
            break;
            
        case BJLScVideoSection_playing:
            // playing
            count = self.videoUsers.count;
            break;
            
        default:
            break;
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLScVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    switch (indexPath.section) {
        case BJLScVideoSection_PPT: {
             [self.room.slideshowViewController bjl_removeFromParentViewControllerAndSuperiew];
             [self bjl_addChildViewController:self.room.slideshowViewController superview:cell];
             [self.room.slideshowViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                 make.edges.equalTo(cell);
             }];
            break;
        }
             
        case BJLScVideoSection_recording: {
            [self.recordingMediaInfoView removeFromSuperview];
            [cell addSubview:self.recordingMediaInfoView];
            [self.recordingMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(cell);
            }];
            break;
        }
            
        case BJLScVideoSection_playing: {
            BJLScMediaInfoView *mediaInfoView = [self mediaInfoViewWithIndex:indexPath.row];
            if (mediaInfoView) {
                [mediaInfoView removeFromSuperview];
                [cell addSubview:mediaInfoView];
                [mediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                    make.edges.equalTo(cell);
                }];
            }
            break;
        }
            
        default:
            break;
    }
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    bjl_weakify(self);
    UIAlertController *alert = [UIAlertController
                                 bjl_lightAlertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    [alert bjl_addActionWithTitle:@"全屏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        bjl_strongify(self);
        NSInteger index = -1;
        BJLScWindowType windowType = BJLScWindowType_ppt;
        BJLScMediaInfoView *mediaInfoView = nil;
        BOOL recording = NO;
        if (self.replaceMajorWindowCallback) {
            switch (indexPath.section) {
                case BJLScVideoSection_PPT: {
                    windowType = BJLScWindowType_ppt;
                    break;
                }
                    
                case BJLScVideoSection_recording: {
                    recording = YES;
                    windowType = BJLScWindowType_userVideo;
                    mediaInfoView = self.recordingMediaInfoView;
                    break;
                }
                    
                case BJLScVideoSection_playing: {
                    mediaInfoView = [self mediaInfoViewWithIndex:indexPath.row];
                    index = mediaInfoView.mediaUser.isTeacher ? -1 : indexPath.row; // 如果是老师的视图（只能出现辅助摄像头）
                    windowType = mediaInfoView.mediaUser.isTeacher ? BJLScWindowType_ppt : BJLScWindowType_userVideo;
                    break;
                }
                    
                default:
                    break;
            }
            mediaInfoView.isFullScreen = YES;
            self.replaceMajorWindowCallback(mediaInfoView, index, windowType, recording);
        }
    }];
    if (indexPath.section == BJLScVideoSection_recording) {
        [alert bjl_addActionWithTitle:@"切换摄像头"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
                                bjl_strongify(self);
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
                                    bjl_strongify(self);
                                  if (!self.room.recordingVM.recordingVideo) {
                                      return;
                                  }
                                  BJLError *error = [self.room.recordingVM updateVideoBeautifyLevel:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                                                                                     ? BJLVideoBeautifyLevel_on : BJLVideoBeautifyLevel_off)];
                                  if (error) {
                                      [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                  }
                              }];
        
        [alert bjl_addActionWithTitle:self.room.recordingVM.recordingVideo ? @"关闭摄像头" : @"打开摄像头"
                                style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * _Nonnull action) {
                                    bjl_strongify(self);
                                  BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                                              recordingVideo:!self.room.recordingVM.recordingVideo];
                                  if (error) {
                                      [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                  }
                                  else {
                                      [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                                                     ? @"摄像头已打开"
                                                                     : @"摄像头已关闭")];
                                  }
                              }];
    }
    else if (indexPath.section == BJLScVideoSection_playing) {
        BJLMediaUser *playingUser = [self.videoUsers bjl_objectAtIndex:indexPath.row];

        if (playingUser.videoOn) {
            BOOL playingVideo = [self isVideoPlayingUser:playingUser];
            [alert bjl_addActionWithTitle:playingVideo ? @"关闭视频" : @"开启视频"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                     bjl_strongify(self);
                                      BJLError *error = [self.room.playingVM updatePlayingUserWithID:playingUser.ID videoOn:!playingVideo mediaSource:playingUser.mediaSource];
                                      if (error) {
                                          [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                      }
                                      else {
                                          BJLScMediaInfoView *view = [self mediaInfoViewWithIndex:indexPath.row];
                                          [view updateCloseVideoPlaceholderHidden:!playingVideo];
                                          if (self.updateVideoCallback) {
                                              self.updateVideoCallback(playingUser, playingVideo);
                                          }
                                      }
                                  }];
        }
        
        if (!self.room.featureConfig.disableGrantDrawing
            && self.room.loginUser.isTeacherOrAssistant
            && self.room.loginUser.noGroup
            && !playingUser.isTeacherOrAssistant) {
            BOOL wasGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:playingUser.number];
            [alert bjl_addActionWithTitle:wasGranted ? @"收回画笔" : @"授权画笔"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                        bjl_strongify(self);
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
            && !self.room.loginUserIsPresenter
            && playingUser.isAssistant
            && self.room.featureConfig.canChangePresenter) {
            if ([playingUser isSameUser:self.room.onlineUsersVM.currentPresenter]) {
                [alert bjl_addActionWithTitle:@"收回主讲"
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
                                        bjl_strongify(self);
                                          [self.room.onlineUsersVM requestChangePresenterWithUserID:self.room.loginUser.ID];
                                      }];
            }
            else {
                [alert bjl_addActionWithTitle:@"设为主讲"
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
                                        bjl_strongify(self);
                                          BJLError *error = [self.room.onlineUsersVM requestChangePresenterWithUserID:playingUser.ID];
                                        if (error) {
                                                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                        }
                                      }];
            }
        }

        if (self.room.loginUser.isTeacherOrAssistant
            && self.room.loginUser.noGroup
            && playingUser.isStudent) {
            [alert bjl_addActionWithTitle:@"奖励"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                    bjl_strongify(self);
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
                                    bjl_strongify(self);
                                      BJLError *error = [self.room.recordingVM remoteChangeRecordingWithUser:playingUser
                                                                                   audioOn:NO
                                                                                   videoOn:NO];
                                      if (error) {
                                          [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                      }
                                  }];
        }

    }
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];

    UIView *sourceView = cell;
    alert.popoverPresentationController.sourceView = sourceView;
    alert.popoverPresentationController.sourceRect = ({
        CGRect rect = sourceView.bounds;
        rect.origin.y = CGRectGetMaxY(rect) - 1.0;
        rect.size.height = 1.0;
        rect;
    });
    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)isVideoPlayingUser:(BJLMediaUser *)mediaUser {
    for (BJLMediaUser *user in [self.room.playingVM.videoPlayingUsers copy]) {
        if ([user isSameMediaUser:mediaUser]) {
            return YES;
        }
    }
    return NO;
}

@end

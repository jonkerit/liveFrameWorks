//
//  BJLIcUserVideoListViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController.h"
#import "BJLIcUserVideoListViewController+private.h"
#import "BJLIcUserVideoListViewController+padUserVideoUpside.h"
#import "BJLIcUserVideoListViewController+padUserVideoDownside.h"
#import "BJLIcUserVideoListViewController+pad1to1.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcUserVideoListViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    [self makeSubviews];
    [self makeObserving];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.videoCollectionView reloadData];
}

- (void)dealloc {
    self.videoCollectionView.dataSource = nil;
    self.videoCollectionView.delegate = nil;
}

#pragma mark - subviews

- (void)makeSubviews {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        [self makePad1to1Subviews];
    }
    else if (BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType) {
        [self makePadUserVideoUpsideSubviews];
    }
    else {
        [self makePadUserVideoDownsideSubviews];
    }
}

#pragma mark - observers

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, featureConfig)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.effectView.hidden = self.room.featureConfig.backgroundURLString.length;
             return YES;
         }];
    
    if (self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1) {
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room.playingVM, playingUsers),
                             BJLMakeProperty(self.room.playingVM, extraPlayingUsers)]
                  observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                      bjl_strongify(self);
                      NSMutableArray *newDataSource = [NSMutableArray array];
                      for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                          for (BJLMediaUser *videoUser in [self.videoUsers copy]) {
                              if ([user isSameMediaUser:videoUser]) {
                                  user.leaveSeat = videoUser.leaveSeat;
                              }
                          }
                          [newDataSource bjl_addObject:user];
                      }
                      self.videoUsers = [NSMutableArray arrayWithArray:newDataSource];
                      [self videoUsersDidUpdate:self.videoUsers];
                      [self.videoCollectionView reloadData];
                  }];
    }
    else {
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room.playingVM, playingUsers),
                             BJLMakeProperty(self.room.playingVM, extraPlayingUsers)]
                  observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                      bjl_strongify(self);
                      NSMutableArray *newDataSource = [NSMutableArray array];
                      for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                          BJLMediaUser *extraUser = [self availableExtraPlayingUserForUser:user];
                          BJLMediaUser *targetUser = extraUser ?: user;
                          for (BJLMediaUser *videoUser in [self.videoUsers copy]) {
                              if ([targetUser isSameMediaUser:videoUser]) {
                                  targetUser.leaveSeat = videoUser.leaveSeat;
                              }
                              if (!videoUser.isTeacher
                                  && [videoUser isSameUser:targetUser]
                                  && videoUser.mediaSource != targetUser.mediaSource) {
                                  // video user 列表中原本包含与 targetUser 不同视频源的 user，且身份不是老师，需要替换窗口，这个是为了处理主摄像头和屏幕共享的用户共用同一个窗口导致显示有问题，各端修改之后可以去掉这里
                                  targetUser.leaveSeat = videoUser.leaveSeat;
                                  if (self.replaceVideoViewCallback) {
                                      self.replaceVideoViewCallback(videoUser, targetUser);
                                  }
                              }
                          }
                          [newDataSource bjl_addObject:targetUser];
                      }
                      self.videoUsers = [NSMutableArray arrayWithArray:newDataSource];
                      [self videoUsersDidUpdate:self.videoUsers];
                      [self.videoCollectionView reloadData];
                  }];
    }
    
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.playingVM, didRemoveActiveUser:),
                             BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidExit:)]
                  observer:^(BJLUser *user) {
                      bjl_strongify(self);
                      // 用户下台、退出教室，清理 mediaInfoView
                      [[self.userMediaInfoViews copy] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull mediaID, id  _Nonnull obj, BOOL * _Nonnull stop) {
                          if ([user containsMediaWithID:mediaID]) {
                              [self.userMediaInfoViews removeObjectForKey:mediaID];
                          }
                      }];
                  }];
    
    // 收到点赞
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForUserNumber:records:)
             observer:^BOOL(NSString *userNumber, NSDictionary<NSString *, NSNumber *> *records) {
                 bjl_strongify(self);
                 BJLMediaUser *user = [self userWithMediaID:nil userNumeber:userNumber];
                 BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectForKey:user.mediaID class:[BJLIcUserMediaInfoView class]];
                 NSInteger likeCount = [self.room.roomVM.likeList bjl_integerForKey:user.number];
                 BOOL hideLikeButton = user.isTeacherOrAssistant || (self.room.loginUser.isStudent && !likeCount);
                 [mediaInfoView updateWithLikeCount:likeCount hidden:hideLikeButton];
                 if (self.receiveLikeCallback) {
                     self.receiveLikeCallback(user, mediaInfoView.likeButton);
                 }
                 return YES;
             }];
   
    /*
    // 清空点赞
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return old.boolValue != now.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self.room.roomVM.liveStarted) {
                 for (NSString *mediaID in self.userMediaInfoViews.allKeys) {
                     BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectForKey:mediaID class:[BJLIcUserMediaInfoView class]];
                     BJLMediaUser *user = [self userWithMediaID:mediaID userNumeber:nil];
                     [mediaInfoView updateWithLikeCount:0 hidden:user.isStudent && !self.room.loginUser.isTeacherOrAssistant];
                 }
             }
             return YES;
         }];
    */
    // 课件授权
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, authorizedPPTUserNumbers)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             for (BJLMediaUser *user in [self.videoUsers copy]) {
                 BOOL authorizedPPT = [self.room.documentVM.authorizedPPTUserNumbers containsObject:user.number];
                 BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectForKey:user.mediaID class:[BJLIcUserMediaInfoView class]];
                 [mediaInfoView updateWebPPTAuthorized:authorizedPPT];
             }
             return YES;
         }];
    
    // 画笔授权
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingGrantedUserNumbers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             for (BJLMediaUser *user in [self.videoUsers copy]) {
                 BOOL drawingGranted = [self.room.drawingVM.drawingGrantedUserNumbers containsObject:user.number];
                 BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectForKey:user.mediaID class:[BJLIcUserMediaInfoView class]];
                 [mediaInfoView updateDrawingGranted:drawingGranted];
             }
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingRequestFromUser:)
             observer:^BOOL(BJLUser *user) {
                 bjl_strongify(self);
                 for (BJLMediaUser *videoUser in [self.videoUsers copy]) {
                     if ([videoUser isSameUser:user]) {
                         // 收到举手显示
                         BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectForKey:videoUser.ID class:[BJLIcUserMediaInfoView class]];
                         [mediaInfoView updateSpeakRequestViewHidden:NO];
                     }
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
                 bjl_strongify(self);
                 // 举手被处理
                 for (BJLMediaUser *videoUser in [self.videoUsers copy]) {
                     if ([videoUser isSameUser:user]) {
                         // 收到举手显示
                         BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectForKey:videoUser.mediaID class:[BJLIcUserMediaInfoView class]];
                         [mediaInfoView updateSpeakRequestViewHidden:YES];
                     }
                 }
                 
                 return YES;
             }];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        return [self pad1to1CollectionView:collectionView numberOfItemsInSection:section];
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        return [self padUserVideoDownsideCollectionView:collectionView numberOfItemsInSection:section];
    }
    else {
        return [self padUserVideoUpsideCollectionView:collectionView numberOfItemsInSection:section];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcUserSeatCell *cell = nil;
    BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:indexPath.row];
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifierFor1to1 forIndexPath:indexPath];
        // 1、最多二个上麦的用户，第一个用户不能为学生，只能为助教或老师，2、第二个用户为学生或助教，不能为老师
        switch (indexPath.row) {
            case 0: {
                if (!user.isTeacherOrAssistant) {
                    user = nil;
                }
            }
                break;
                
            case 1: {
                BJLMediaUser *preUser = [self.videoUsers bjl_objectAtIndex:0];
                /* 正常情况：（一个老师，一个学生）（一个助教，一个学生）（一个老师，一个助教）（二个助教）
                 异常情况：（无老师助教，一个学生）
                 如果只有一个学生开音视频的用户的情况，学生需要放在第二个位置，其他情况正常取值
                 */
                if (!user && preUser.isStudent) {
                    user = preUser;
                }
            }
                break;
                
            default:
                break;
        }
    }
    else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    }
    if (!user) {
        [cell updateContentWithUser:user leavSeat:YES];
        return cell;
    }
    [cell updateContentWithUser:user leavSeat:user.leaveSeat];
    
    // 用户音视频信息视图，不能通过 cell 重用，需要单独处理
    BJLIcUserMediaInfoView *mediaInfoView = ([self.userMediaInfoViews bjl_objectForKey:user.mediaID class:[BJLIcUserMediaInfoView class]]
                                           ?: [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room]);
    if (BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType
        && !mediaInfoView.user.leaveSeat) {
        // 仅处理未离开座位的用户的视频，防止因为在拖动过程中刷新视图而将拖动中的视图切换成了高清晰度的视频
        [self.room.playingVM switchVideoDefinitionWithUser:mediaInfoView.user useLowDefinition:YES];
    }
    [mediaInfoView updateParentViewController:self];
    [mediaInfoView updateInfoGroupViewWithReferenceView:cell];
    
    if (!user.leaveSeat) {
        [mediaInfoView removeFromSuperview];
        [cell.mediaInfoContainerView addSubview:mediaInfoView];
        [mediaInfoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(cell.mediaInfoContainerView);
        }];
    }
    
    [mediaInfoView updateContentWithUser:user combineVideoView:!user.leaveSeat];
    // 更新占位图的约束
    [mediaInfoView updatePlaceholderImageViewConstranintsForRoomLayout:BJLRoomLayout_blackboard];
    
    bjl_weakify(self);
    [mediaInfoView setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    [mediaInfoView setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
        bjl_strongify(self);
        if (self.updateVideoCallback) {
            self.updateVideoCallback(user, on);
        }
    }];
    [mediaInfoView setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        if (self.blockUserCallback) {
            return self.blockUserCallback(user);
        }
        return NO;
    }];
    if (mediaInfoView && mediaInfoView.mediaID.length) {
        [self.userMediaInfoViews setObject:mediaInfoView forKey:mediaInfoView.mediaID];
    }
    
    // 只有老师才可以收回学生视频窗口
    if (self.room.loginUser.isTeacher) {
        [cell setSingleTapCallback:^{
            bjl_strongify(self);
            if (user.leaveSeat) {
                [self setUser:user leaveSeat:NO];
                if (self.sendBackVideoViewCallback) {
                    self.sendBackVideoViewCallback(user);
                }
            }
            else {
                // 暂时禁用双击弹出
                //            if (self.sendBackAllVideoViewCallback) {
                //                self.sendBackAllVideoViewCallback();
                //            }
                //            [self setUser:user leaveSeat:YES];
                //            if (self.popOverVideoViewCallback) {
                //                self.popOverVideoViewCallback(user);
                //            }
            }
            [self.videoCollectionView reloadData];
        }];
    }
    
    return cell;
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
    NSInteger numberOfItems = self.videoUsers.count;
    if (numberOfItems <= 0) {
        return UIEdgeInsetsZero;
    }
    CGFloat combinedItemWidth = (numberOfItems * itemSize.width) + ((numberOfItems - 1) * itemSpacing);
    CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
    padding = padding > 0.0 ? padding : 0.0;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    padding = floor(padding * screenScale) / screenScale;
    return UIEdgeInsetsMake(0.0, padding, 0.0, padding);
}

#pragma mark - public

- (nullable BJLIcUserMediaInfoView *)mediaInfoViewWithPanGesture:(UIPanGestureRecognizer *)panGesture {
    for (BJLIcUserSeatCell *cell in self.videoCollectionView.visibleCells) {
        CGPoint location = [panGesture locationInView:cell];
        if ([cell pointInside:location withEvent:nil]) {
            NSInteger index = [self.videoCollectionView indexPathForCell:cell].row;
            BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:index];
            if (user && !user.leaveSeat) {
                [self setUser:user leaveSeat:YES];
                // update
                [self.videoCollectionView reloadData];
                return [self.userMediaInfoViews bjl_objectForKey:user.mediaID class:[BJLIcUserMediaInfoView class]];
            }
        }
    }
    return nil;
}

- (nullable BJLIcUserMediaInfoView *)setUserLeaveSeatWithMediaID:(NSString *)mediaID {
    for (NSInteger index = 0; index < self.videoUsers.count; index++) {
        BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:index];
        if ([mediaID isEqualToString:user.mediaID]) {
            [self setUser:user leaveSeat:YES];
            // update
            [self.videoCollectionView reloadData];
            
            BJLIcUserMediaInfoView *mediaInfoView = ([self.userMediaInfoViews bjl_objectForKey:user.mediaID class:[BJLIcUserMediaInfoView class]]
                                                     ?: [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room]);
            [mediaInfoView updateParentViewController:self];
            bjl_weakify(self);
            [mediaInfoView setShowErrorMessageCallback:^(NSString * _Nonnull message) {
                bjl_strongify(self);
                if (self.showErrorMessageCallback) {
                    self.showErrorMessageCallback(message);
                }
            }];
            [mediaInfoView setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
                bjl_strongify(self);
                if (self.updateVideoCallback) {
                    self.updateVideoCallback(user, on);
                }
            }];
            [mediaInfoView setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
                bjl_strongify(self);
                if (self.blockUserCallback) {
                    return self.blockUserCallback(user);
                }
                return NO;
            }];
            [self.userMediaInfoViews setObject:mediaInfoView forKey:mediaInfoView.mediaID];
            return mediaInfoView;
        }
    }
    return nil;
}

- (nullable BJLIcUserMediaInfoView *)mediaInfoViewWithTouch:(UITouch *)touch {
    for (BJLIcUserSeatCell *cell in self.videoCollectionView.visibleCells) {
        CGPoint location = [touch locationInView:cell];
        if ([cell pointInside:location withEvent:nil]) {
            NSInteger index = [self.videoCollectionView indexPathForCell:cell].row;
            BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:index];
            if (user && !user.leaveSeat) {
                [self setUser:user leaveSeat:YES];
                // update
                [self.videoCollectionView reloadData];
                
                return [self.userMediaInfoViews bjl_objectForKey:user.mediaID class:[BJLIcUserMediaInfoView class]];
            }
        }
    }
    
    return nil;
}

- (void)sendUserBackToSeatWithMediaID:(NSString *)mediaID {
    if (!mediaID.length) {
        return;
    }
    
    BJLMediaUser *tempUser = nil;
    NSInteger tempIndex = NSNotFound;
    for (NSInteger i = 0; i < self.videoUsers.count; i ++) {
        BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:i];
        if ([user.mediaID isEqualToString:mediaID]) {
            tempUser = user;
            tempIndex = i;
            break;
        }
    }
    
    if (!tempUser || tempIndex == NSNotFound) {
        return;
    }
    
    [self setUser:tempUser leaveSeat:NO];
    
    // update
    [self.videoCollectionView reloadData];
}

#pragma mark - getters

- (NSMutableArray<BJLMediaUser *> *)videoUsers {
    if (!_videoUsers) {
        _videoUsers = [NSMutableArray array];
    }
    return _videoUsers;
}

- (NSMutableDictionary *)userMediaInfoViews {
    if (!_userMediaInfoViews) {
        _userMediaInfoViews = [NSMutableDictionary dictionary];
    }
    return _userMediaInfoViews;
}

- (nullable BJLMediaUser *)availableExtraPlayingUserForUser:(BJLMediaUser *)user {
    if (!user || user.isTeacher) {
        return nil;
    }
    
    // 倒序遍历，找出最新的 extraPlayingUser
    for (BJLMediaUser *extraPlayingUser in [self.room.playingVM.extraPlayingUsers reverseObjectEnumerator]) {
        if ([extraPlayingUser isSameUser:user]) {
            if (extraPlayingUser.videoOn && extraPlayingUser.mediaSource == BJLMediaSource_screenShare) {
                return extraPlayingUser;
            }
            else if (extraPlayingUser.mediaSource == BJLMediaSource_mediaFile) {
                return extraPlayingUser;
            }
        }
    }
    return nil;
}

#pragma mark - private

- (nullable BJLMediaUser *)userWithMediaID:(nullable NSString *)mediaID userNumeber:(nullable NSString *)userNumber {
    for (BJLMediaUser *user in [self.videoUsers copy]) {
        if (mediaID.length && [user.mediaID isEqualToString:mediaID]) {
            return user;
        }
        else if (userNumber.length && [user.number isEqualToString:userNumber]) {
            return user;
        }
    }
    return nil;
}

- (CGSize)itemSize {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        return [self pad1to1ItemSize];
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        return [self padUserVideoDownsideItemSize];
    }
    else {
        return [self padUserVideoUpsideItemSize];
    }
}

- (void)setUser:(BJLUser *)user leaveSeat:(BOOL)leaveSeat {
    user.leaveSeat = leaveSeat;
    [self videoUsersDidUpdate:self.videoUsers];
}

#pragma mark - observable methods

- (BJLObservable)videoUsersDidUpdate:(NSArray<BJLUser *> *)users {
    BJLMethodNotify((NSArray<BJLUser *> *), users);
}

@end

NS_ASSUME_NONNULL_END

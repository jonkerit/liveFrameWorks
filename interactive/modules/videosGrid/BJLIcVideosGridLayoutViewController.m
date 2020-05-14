//
//  BJLIcVideosGridLayoutViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/14.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>

#import "BJLIcVideosGridLayoutViewController.h"
#import "BJLIcUserMediaInfoView.h"
#import "BJLIcVideosGridCell.h"

#define itemSpacing (1.0 / [UIScreen mainScreen].scale)

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcVideosGridLayoutViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) NSMutableArray *videoUsers;
@property (nonatomic, readwrite) NSMutableDictionary *userMediaInfoViews;

@end

@implementation BJLIcVideosGridLayoutViewController

static NSString * const reuseIdentifier = @"Cell";

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [self init];
    if (self) {
        self->_room = room;
        [self setupObserversForRoom];
    }
    return self;
}

- (instancetype)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = itemSpacing;
    layout.minimumLineSpacing = itemSpacing;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self = [super initWithCollectionViewLayout:layout];
    
    if (self) {
        self.collectionView.scrollEnabled = NO;
        [self.collectionView registerClass:[BJLIcVideosGridCell class] forCellWithReuseIdentifier:reuseIdentifier];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

#pragma mark - observers

- (void)setupObserversForRoom {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.playingVM, playingUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.videoUsers = [NSMutableArray arrayWithArray:self.room.playingVM.playingUsers];
             [self.collectionView reloadData];
             return YES;
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
                     BJLUser *user = [self userWithMediaID:mediaID userNumeber:nil];
                     [mediaInfoView updateWithLikeCount:0 hidden:user.isStudent];
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
                 // 收到举手显示
                 BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectForKey:user.ID class:[BJLIcUserMediaInfoView class]];
                 [mediaInfoView updateSpeakRequestViewHidden:NO];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
                 bjl_strongify(self);
                 // 举手被处理
                 BJLIcUserMediaInfoView *mediaInfoView = [self.userMediaInfoViews bjl_objectForKey:user.ID class:[BJLIcUserMediaInfoView class]];
                 [mediaInfoView updateSpeakRequestViewHidden:YES];
                 return YES;
             }];
}

#pragma mark - public

- (void)updateContentWithUsers:(NSArray<BJLUser *> *)users room:(BJLRoom *)room {
    self->_room = room;
    self.videoUsers = [NSMutableArray array];
    for (BJLUser *user in users) {
        if (user.leaveSeat) {
             [self.videoUsers bjl_addObject:user];
        }
    }
    [self.collectionView reloadData];
    if (self.videoUsers.count <= 0 && self.dataSourceEmptyCallback) {
        self.dataSourceEmptyCallback();
    }
}

#pragma mark - <UICollectionViewDelegateFlowlayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self itemSize];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewFlowLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section{
    CGSize itemSize = [self itemSize];
    NSInteger numberOfItems = [collectionView numberOfItemsInSection:section];
    if (numberOfItems <= 0) {
        return UIEdgeInsetsZero;
    }
    CGFloat combinedItemWidth = (numberOfItems * itemSize.width) + ((numberOfItems - 1) * itemSpacing);
    CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
    padding = padding > 0.0 ? padding : 0.0;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    padding = floor(padding * screenScale) / screenScale;
    return UIEdgeInsetsMake(0.0, padding, itemSpacing, padding);
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self sectionCount];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger maxItemCount = [self maxItemCountForEachSection];
    return MIN(maxItemCount, self.videoUsers.count - maxItemCount * section);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.section * [self maxItemCountForEachSection] + indexPath.row;
    BJLMediaUser *user = [self.videoUsers bjl_objectAtIndex:index];
    BJLIcVideosGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    // 用户音视频信息视图，不能通过 cell 重用，需要单独处理
    BJLIcUserMediaInfoView *mediaInfoView = ([self.userMediaInfoViews bjl_objectForKey:user.mediaID class:[BJLIcUserMediaInfoView class]]
                                           ?: [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room]);
    if (BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType) {
        [self.room.playingVM switchVideoDefinitionWithUser:mediaInfoView.user useLowDefinition:NO];
    }
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
    [mediaInfoView removeFromSuperview];
    [cell.mediaInfoContainerView addSubview:mediaInfoView];
    [mediaInfoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(cell.mediaInfoContainerView);
    }];
    [mediaInfoView updateContentWithUser:user combineVideoView:YES];
    /* 1、老师助教隐藏点赞按钮，
     2、登录用户是学生，视频是学生视频，并且点赞数为0，隐藏点赞按钮 */
    NSInteger likeCount = [self.room.roomVM.likeList bjl_integerForKey:user.number];
    BOOL hideLikeButton = user.isTeacherOrAssistant || (self.room.loginUser.isStudent && !likeCount);
    [mediaInfoView updateWithLikeCount:likeCount hidden:hideLikeButton];
    // 更新占位图的约束
    [mediaInfoView updatePlaceholderImageViewConstranintsForRoomLayout:BJLRoomLayout_gallary];
    
    if (mediaInfoView && mediaInfoView.mediaID.length) {
        [self.userMediaInfoViews setObject:mediaInfoView forKey:mediaInfoView.mediaID];
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>



#pragma mark - calculatiing methods

- (CGSize)itemSize {
    NSUInteger row = [self sectionCount];
    NSUInteger column = [self maxItemCountForEachSection];
    if (row <= 0 || column <= 0) {
        return CGSizeZero;
    }
    
    CGSize viewSize = self.view.bounds.size;
    CGFloat itemWidth = (viewSize.width - (column - 1) * itemSpacing) / column;
    CGFloat itemHeight = (viewSize.height - (row - 1) * itemSpacing) / row;
    
    // 根据屏幕 scale 丢弃部分 itemWidth 精度，保证计算值与屏幕实际渲染效果一致
    CGFloat screenScale = [UIScreen mainScreen].scale;
    return CGSizeMake(floor(itemWidth * screenScale) / screenScale, floor(itemHeight * screenScale) / screenScale);
}

- (NSUInteger)sectionCount {
    NSUInteger sourceCount = self.videoUsers.count;
    NSUInteger maxItemCount = [self maxItemCountForEachSection];
    return (sourceCount / maxItemCount + (sourceCount % maxItemCount > 0 ? 1 : 0));
}

- (NSUInteger)maxItemCountForEachSection {
    NSUInteger sourceCount = self.videoUsers.count;
    if (sourceCount <= 2) {
        return sourceCount;
    }
    else if (sourceCount <= 8) {
        // 2～3 列
        return sourceCount / 2 + (sourceCount % 2 > 0 ? 1 : 0);
    }
    else if (sourceCount <= 12) {
        // 3～4 列
        return sourceCount / 3 + (sourceCount % 3 > 0 ? 1 : 0);
    }
    else if (sourceCount <= 16) {
        return 4;
    }
    else {
        // 专业版小班课一般不超过 16 人
        return floor(sqrt(sourceCount));
    }
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

#pragma mark - getters

- (NSMutableDictionary *)userMediaInfoViews {
    if (!_userMediaInfoViews) {
        _userMediaInfoViews = [NSMutableDictionary dictionary];
    }
    return _userMediaInfoViews;
}

@end

NS_ASSUME_NONNULL_END

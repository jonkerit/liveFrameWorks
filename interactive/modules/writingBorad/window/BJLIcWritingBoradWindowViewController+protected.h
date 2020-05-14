//
//  BJLIcWritingBoradWindowViewController+protected.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWritingBoradWindowViewController.h"
#import "BJLIcWritingBoardUserListView.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcWritingBoardBottomToolBarViewController.h"
#import "BJLIcWritingBoardTopToolBarViewController.h"
#import "BJLIcPromptViewController.h"
#import "BJLIcPopoverViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcWritingboradUserlistSection) {
    BJLIcWritingboradUserlistSection_loginUser, // 当前登录用户
    BJLIcWritingboradUserlistSection_activeUser,// 台上用户
    BJLIcWritingboradUserlistSection_normal,    //台下
    BJLIcWritingboradUserlistSection_count
};

extern NSString * const cellReuseIdentifier;

@interface BJLIcWritingBoradWindowViewController ()

@property (nonatomic, readwrite) BJLWritingBoard *writingBoard;

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic, readonly) NSString *userNumber;

@property (nonatomic) BJLIcWritingBoardUserListView *boardUserListView;
@property (nonatomic) BJLIcWritingBoardTopToolBarViewController *topToolBarViewController;
@property (nonatomic) BJLIcWritingBoardBottomToolBarViewController *bottomToolBarViewController;
@property (nonatomic) BJLIcPromptViewController *promptViewController;
@property (nonatomic, nullable) BJLIcPopoverViewController *popoverViewController; // 用于关闭未点击但是需要关闭的弹窗

@property (nonatomic) UIView *popoversLayer;
@property (nonatomic, readonly) UIButton *userListButton;
@property (nonatomic) UILabel *titleNameLabel, *groupColorLabel, *groupNameLabel;

#pragma mark -
@property (nonatomic) UICollectionView *collectionView;

//如果是分享,添加一个writingBoradViewController, 否则使用collectionView
@property (nonatomic) UIViewController<BJLWritingBoardUI> *writingBoradViewController;
//变化时需要更新collectionview,bottom 和userlist
//@property (nonatomic, copy) NSArray <BJLUser *> *participatedUsers;
@property (nonatomic, copy) NSArray <BJLUser *> *activeParticipatedUsers;// 台上用户
@property (nonatomic, copy) NSArray <BJLUser *> *normalParticipatedUsers;//台下
@property (nonatomic) BOOL hasTeacher;
@property (nonatomic) BOOL shouldOpenActiveUserList;
@property (nonatomic) BOOL shouldOpenNormalUserList;

//下面的变化时, 需要更新bottom 和userlist
@property (nonatomic) NSArray <BJLUser *> *submitedUsers;
@property (nonatomic) NSArray <BJLUser *> *checkedUsers;
@property (nonatomic) NSMutableArray <BJLUser *> *mutaCheckedUsers;

@property (nonatomic, nullable) BJLUser *currentShowUser;
@property (nonatomic, nullable) NSString *currentLayer;
//@property (nonatomic) NSInteger currentIndex;
@property (nonatomic, nullable) NSIndexPath *currentIndexPath;

#pragma mark -
- (void)publishWithOperate:(BJLWritingBoardPublishOperate)operate restrictionTimeString:(nullable NSString *)restrictionTimeString;
- (BOOL)isValidStatusForUserListAndToolBar;
- (BOOL)isValidIndexPathInUserList:(NSIndexPath *)indexPath;
- (BOOL)isValidIndexPathInCollectionView:(NSIndexPath *)indexPath;
- (void)reedit;
- (void)share;

- (void)askToRevokeWritingBoard;
- (void)askToClearWritingBoard;
- (void)askToCloseWritingBoard;

- (nullable BJLUser *)getUserForIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END

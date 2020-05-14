//
//  BJLIcWritingBoradWindowViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//
#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcWritingBoradWindowViewController.h"
#import "BJLIcWritingBoradWindowViewController+protected.h"
#import "BJLIcWritingBoradWindowViewController+userList.h"
#import "BJLIcWritingBoradWindowViewController+toolbar.h"
#import "BJLIcWritingBoradWindowViewController+collectionView.h"
#import "BJLIcWritingBoardCollectionViewCell.h"
#import "BJLIcPopoverViewController.h"

#import "BJLIcAppearance.h"

NSString * const cellReuseIdentifier = @"collectionViewCell";

@interface BJLIcWritingBoradWindowViewController ()

//作答中的倒计时timer
@property (nonatomic) NSTimer *timer;

//提交后的倒计时timer
@property (nonatomic) NSTimer *leftTipTimer;

/* 当前窗口是否已发布, 用于区分老师的小黑板初始编辑状态 */
@property (nonatomic) BOOL isPublished;

@end

@implementation BJLIcWritingBoradWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                writingBoard:(BJLWritingBoard *)writingBoard
                  userNumber:(NSString *)userNumber {
    self = [super init];
    if (self) {
        self->_room = room;
        self->_writingBoard = writingBoard;
        self->_userNumber = userNumber;
        self.currentLayer = userNumber;
        self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        self.shouldOpenActiveUserList = YES;
        self.shouldOpenNormalUserList = NO;
        self.hasTeacher = YES;
        self.submitedUsers = [NSArray array];
//        self.participatedUsers = [NSArray array];
        self.checkedUsers = [NSArray array];
        self.mutaCheckedUsers = [NSMutableArray array];
        self.isPublished = !(writingBoard.status == BJLIcWriteBoardStatus_teacherEditing);
        [self prepareToOpen];        
    }
    return self;
}

- (void)dealloc {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (self.leftTipTimer) {
        [self.leftTipTimer invalidate];
        self.leftTipTimer = nil;
    }
    
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    self.boardUserListView.tableView.delegate = nil;
    self.boardUserListView.tableView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11.0, *)) {
    }
    else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    [self setupSubviews];
    [self setupObservers];
}

- (void)prepareToOpen {
    self.fixedAspectRatio = 2/1;
    self.minWindowHeight = 150;
    self.minWindowWidth = 300;

    CGFloat relativeWidth = 7.5 / 16.0;
    CGFloat relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth width:720.0 height:720.0/2];
    self.relativeRect = [self rectInBounds:CGRectMake(0.2, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
    
    self.bottomToolBarViewController = [[BJLIcWritingBoardBottomToolBarViewController alloc] initWithRoom:self.room];
    
    self.topToolBarViewController = [[BJLIcWritingBoardTopToolBarViewController alloc] initWithRoom:self.room];
    
    self.boardUserListView = [BJLIcWritingBoardUserListView new];
    self.boardUserListView.tableView.delegate = self;
    self.boardUserListView.tableView.dataSource = self;
}

- (void)setupSubviews {
    if (self.writingBoard.status == BJLIcWriteBoardStatus_teacherShare) {
        self.writingBoradViewController = [self.room.documentVM writingBoardViewControllerWithWritingBoard:self.writingBoard];
        
        [self setContentViewController:self.writingBoradViewController contentView:nil];
    }
    else {
        self.collectionView = ({
            // layout：不要设置 itemSize，触发 UICollectionViewDelegateFlowlayout
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            layout.minimumInteritemSpacing = 0.0;
            layout.minimumLineSpacing = 0.0;
            layout.sectionInset = UIEdgeInsetsZero;
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            
            UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
            collectionView.backgroundColor = [UIColor clearColor];
            collectionView.showsHorizontalScrollIndicator = NO;
            collectionView.bounces = YES;
            collectionView.pagingEnabled = YES;
            collectionView.alwaysBounceHorizontal = YES;
            collectionView.dataSource = self;
            collectionView.delegate = self;
            collectionView.scrollEnabled = NO;
            if (@available(iOS 11.0, *)) {
                collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
            [collectionView registerClass:[BJLIcWritingBoardCollectionViewCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
            bjl_return collectionView;
        });
        [self setContentViewController:nil contentView:self.collectionView];
    }
    
    self.topBar.backgroundView.backgroundColor = [UIColor bjl_colorWithHex:0x9b9b9b alpha:0.2];
    [self.topBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
    }];
    
    self.titleNameLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor bjl_colorWithHex:0xDEDEDE];
        label.text = @"小黑板";
        label.accessibilityLabel = BJLKeypath(self, titleNameLabel);
        bjl_return label;
    });
    self.groupColorLabel = ({
        UILabel *label = [UILabel new];
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        label.hidden = YES;
        label.accessibilityLabel = BJLKeypath(self, groupColorLabel);
        bjl_return label;
    });
    self.groupNameLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"--";
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor bjl_colorWithHex:0X9B9B9B];
        label.hidden = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        bjl_return label;
    });

    [self.view addSubview:self.titleNameLabel];
    [self.view addSubview:self.groupColorLabel];
    [self.view addSubview:self.groupNameLabel];
    [self.titleNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.view);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
        make.left.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
    [self.groupColorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.titleNameLabel);
        make.size.equal.sizeOffset(CGSizeMake(12.0, 12.0));
        make.left.equalTo(self.titleNameLabel.bjl_right).offset(10);
    }];
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.view);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
        make.left.equalTo(self.groupColorLabel.bjl_right).offset(5);
        make.right.lessThanOrEqualTo(self.view);
    }];

    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    if (iPad && self.state == BJLWindowState_fullscreen) {
        [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@40.0);
        }];
    }
    else {
        [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@30.0);
        }];
    }
    
    self.popoversLayer = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, popoversLayer);
        bjl_return view;
    });
    [self.view insertSubview:self.popoversLayer aboveSubview:self.forgroundView];
    [self.popoversLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.topBar.bjl_bottom);
        make.bottom.equalTo(self.bottomBar.bjl_top);
        make.left.right.equalTo(self.view);
    }];
    
    self->_promptViewController = [[BJLIcPromptViewController alloc] init];
    [self bjl_addChildViewController:self.promptViewController superview:self.popoversLayer];
    [self.promptViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.right.left.equalTo(self.popoversLayer);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].promptViewHeight));
    }];
    
    self->_userListButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_ic_writingboard_showUser"] forState:UIControlStateNormal];
        button.accessibilityLabel = BJLKeypath(self, userListButton);
        button.hidden = YES;
        button.backgroundColor = [UIColor bjl_colorWithHex:0x000000 alpha:0.3];
        bjl_return button;
    });
    [self.popoversLayer addSubview:self.userListButton];
    [self.userListButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.popoversLayer);
        make.width.equalTo(@(32));
    }];
    
    [self setupBoardToolBar];
    [self setupBoardUserList];
    [self setupBoardTopToolBar];
    
    self.forgroundView.hidden = YES;
}

- (void)setupObservers {
    bjl_weakify(self);

    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
           filter:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
               return !!now;
           }
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             // 权限
             BOOL isTeacher = self.room.loginUser.isTeacher;
             [self setWindowInterfaceEnabled:YES];
             
             // 老师或者当前用户<助教同学生权限>正在答题时, 可以使用手势
             [self setWindowGesturesEnabled:(([self.userNumber isEqualToString:self.room.loginUser.number] && self.writingBoard.isActive) || isTeacher)];
             self.closeButtonHidden = !(isTeacher && [self.userNumber isEqualToString:BJLWritingboardUserNumberForTeacher]);
             self.fullscreenButtonHidden = YES;
             
             if (self.writingBoradViewController) {
                 [self.writingBoradViewController updateShapesWithUserNumber:self.userNumber];
             }
             
             // 初始化小黑板的用户列表数据
             if (self.writingBoard.status == BJLIcWriteBoardStatus_studentEdit || self.writingBoard.status == BJLIcWriteBoardStatus_teacherEditing) {
//                 self.participatedUsers = [NSArray arrayWithObject:self.room.loginUser];
                 self.checkedUsers = [NSArray arrayWithObject:self.room.loginUser];
                 self.mutaCheckedUsers = [NSMutableArray arrayWithArray:self.checkedUsers];
             }
             else if (self.writingBoard.status == BJLIcWriteBoardStatus_teacherGathered) {
                 NSMutableArray *submitted = [self.room.documentVM.allWritingBoardSubmitedUsers mutableCopy];
                 if (!submitted) {
                     submitted = [NSMutableArray array];
                 }
                 [submitted insertObject:self.room.loginUser atIndex:0];
                 self.submitedUsers = submitted;
                 
//                 NSMutableArray *participatedUsers = [self.room.documentVM.allWritingBoardParticipatedUsers mutableCopy];
//                 if (!participatedUsers) {
//                     participatedUsers = [NSMutableArray array];
//                 }
//                 [participatedUsers insertObject:self.room.loginUser atIndex:0];
//                 self.participatedUsers = participatedUsers;
                 [self updateparticipatedUsers];
                 self.checkedUsers = [NSArray arrayWithObject:self.room.loginUser];
             }

             self.currentShowUser = self.room.loginUser;

             [self updateWritingBoardStatus];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.view, bounds)
           filter:^BOOL(NSValue * _Nullable now, NSValue * _Nullable old, BJLPropertyChange * _Nullable change) {
               return (!CGRectEqualToRect(now.CGRectValue, old.CGRectValue));
           }
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             // 触发 UICollectionViewDelegateFlowlayout，更新 cell 大小
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self updateCollectionView];
             });
             return YES;
         }];

    /* 发布之后更新界面 */
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didPublishWritingBoard:)
               filter:^BOOL(BJLWritingBoard *writingBoard) {
                   bjl_strongify(self);
                   return (!!writingBoard.boardID.length
                           && self.writingBoard.status != BJLIcWriteBoardStatus_teacherShare
                           && self.writingBoard.status != BJLIcWriteBoardStatus_None
                           && [writingBoard.boardID isEqualToString:self.writingBoard.boardID]);
               }
             observer:^BOOL(BJLWritingBoard *writingBoard) {
                 bjl_strongify(self);
                 BOOL isTeacher = self.room.loginUser.isTeacher;
                 
                 if (isTeacher && writingBoard.operate == BJLWritingBoardPublishOperate_begin) {
                     self.writingBoard.isActive = YES;
                     self.isPublished = YES;
                 }
                 else if (isTeacher && writingBoard.operate == BJLWritingBoardPublishOperate_end) {
                     self.writingBoard.isActive = NO;
                     self.isPublished = YES;
                     [self.promptViewController enqueueWithPrompt:@"小黑板已全部收回" duration:2];
                 }
                 else if (isTeacher && writingBoard.operate == BJLWritingBoardPublishOperate_revoke) {
                     self.writingBoard.isActive = NO;
                     self.isPublished = NO;
                 }
                 else if (!isTeacher
                         && writingBoard.operate == BJLWritingBoardPublishOperate_begin
                         ) {
                     self.writingBoard.isActive = YES;
                     self.isPublished = YES;
                 }
                 else if (!isTeacher
                         && writingBoard.operate == BJLWritingBoardPublishOperate_end
                         && self.writingBoard.isActive)
                    {
                     [self submitBoard];
                     self.writingBoard.isActive = NO;
                     self.isPublished = YES;
                     self.writingBoard.status = BJLIcWriteBoardStatus_None;
                     return NO;
                 }
                 else if (!isTeacher
                         && writingBoard.operate == BJLWritingBoardPublishOperate_revoke
                         && self.writingBoard.isActive)
                 {
                     self.writingBoard.isActive = NO;
                     self.isPublished = NO;
                     self.writingBoard.status = BJLIcWriteBoardStatus_None;
                     [self closeWithoutRequest];
                     return NO;
                 }
                 else {
                     return NO;
                 }
                 [self updateWritingBoardStatus];
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self, state)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
             if (iPad) {
                 if (self.state == BJLWindowState_fullscreen) {
                     [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
                         make.height.equalTo(@50.0);
                     }];
                 }
                 else {
                     [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
                         make.height.equalTo(@30.0);
                     }];
                 }
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, allWritingBoardParticipatedUsers)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
               bjl_strongify(self);
               return (self.room.loginUser.isTeacher
                       && (self.writingBoard.status == BJLIcWriteBoardStatus_teacherGathered || self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished) );
           }
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
            [self updateparticipatedUsers];
             
             if (![self.room.documentVM.allWritingBoardParticipatedUsers count]) {
                 [self.mutaCheckedUsers removeAllObjects];
                 [self.mutaCheckedUsers insertObject:self.room.loginUser atIndex:0];
                 self.checkedUsers = self.mutaCheckedUsers;
             }
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self updateCollectionView];
                 [self updateBottomAndTopText];
                 [self updateUserListView];
             });
             return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, allWritingBoardSubmitedUsers)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
               bjl_strongify(self);
               return (self.room.loginUser.isTeacher
                       && self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished);
           }
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             NSMutableArray *allWritingBoardSubmitedUsers = [self.room.documentVM.allWritingBoardSubmitedUsers mutableCopy];
             [allWritingBoardSubmitedUsers insertObject:self.room.loginUser atIndex:0];
             self.submitedUsers = [allWritingBoardSubmitedUsers copy];
             if (![self.room.documentVM.allWritingBoardSubmitedUsers count]) {
                 [self.mutaCheckedUsers removeAllObjects];
                 [self.mutaCheckedUsers insertObject:self.room.loginUser atIndex:0];
                 self.checkedUsers = self.mutaCheckedUsers;
             }
        
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self updateSubviews];
             });
             return YES;
         }];
    
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.playingVM, didAddActiveUser:), BJLMakeMethod(self.room.playingVM, didRemoveActiveUser:)]
                    filter:^BOOL{
        bjl_strongify(self);
        return [self isValidStatusForUserListAndToolBar];
    }
                  observer:^{
        bjl_strongify(self);
        [self updateparticipatedUsers];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSubviews];
        });
    }];

    [self bjl_kvo:BJLMakeProperty(self, currentLayer)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
        if (!self.room.loginUser.isTeacher) {
            return YES;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSubviews];
        });
        return YES;
    }];
}

- (void)updateSubviews {
    [self updateCollectionView];
    [self updateBottomAndTopText];
    [self updateUserListView];
}

- (void)updateparticipatedUsers {
    
    NSMutableArray *activeParticipatedUsers = [NSMutableArray array];
    NSMutableArray *normalParticipatedUsers = [NSMutableArray array];
    for (BJLUser *user in [self.room.documentVM.allWritingBoardParticipatedUsers copy]) {
        BOOL isAvtiveUser = NO;
        for (BJLUser *avtiveUser in self.room.playingVM.playingUsers) {
            if ([user isSameUserWithID:avtiveUser.ID number:avtiveUser.number]) {
                isAvtiveUser = YES;
                [activeParticipatedUsers bjl_addObject:user];
                break;
            }
        }
        if (!isAvtiveUser) {
            [normalParticipatedUsers bjl_addObject:user];
        }
    }
    
    NSMutableArray *participatedUsers = [NSMutableArray array];
    [participatedUsers bjl_insertObject:self.room.loginUser atIndex:0];
    if ([activeParticipatedUsers count]) {
        [participatedUsers addObjectsFromArray:activeParticipatedUsers];
    }
    
    if ([normalParticipatedUsers count]) {
        [participatedUsers addObjectsFromArray:normalParticipatedUsers];
    }

    self.activeParticipatedUsers = activeParticipatedUsers;
    self.normalParticipatedUsers = normalParticipatedUsers;
//    self.participatedUsers = [participatedUsers copy];

    if ([self.currentLayer isEqualToString:BJLWritingboardUserNumberForTeacher]) {
        self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
        self.currentLayer = BJLWritingboardUserNumberForTeacher;
    }
    else {
        BOOL isExist = NO;
        for (NSInteger i = 0; i < [self.activeParticipatedUsers count] ; i++) {
            BJLUser *user = [self.activeParticipatedUsers bjl_objectAtIndex:i];
            if ([user.number isEqualToString:self.currentLayer]) {
                self.currentShowUser = user;
                self.currentIndexPath = [NSIndexPath indexPathForRow:i inSection:BJLIcWritingboradUserlistSection_activeUser];
                self.currentLayer = user.number;
                isExist = YES;
                break;
            }
        }
        
        if (!isExist) {
            for (NSInteger i = 0; i < [self.normalParticipatedUsers count] ; i++) {
                BJLUser *user = [self.normalParticipatedUsers bjl_objectAtIndex:i];
                if ([user.number isEqualToString:self.currentLayer]) {
                    self.currentShowUser = user;
                    self.currentIndexPath = [NSIndexPath indexPathForRow:i inSection:BJLIcWritingboradUserlistSection_normal];
                    self.currentLayer = user.number;
                    isExist = YES;
                    break;
                }
            }
        }

        if (!isExist) {
            self.currentShowUser = self.room.loginUser;
            self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
            self.currentLayer = BJLWritingboardUserNumberForTeacher;
        }
    }
}

#pragma mark - public
- (nullable BJLUser *)getUserForIndexPath:(NSIndexPath *)indexPath {
    BJLUser *userForCell = nil;
    if (indexPath.section == BJLIcWritingboradUserlistSection_loginUser) {
        userForCell = self.hasTeacher ? self.room.loginUser : nil;
    }
    else if (indexPath.section == BJLIcWritingboradUserlistSection_activeUser) {
        userForCell = [self.activeParticipatedUsers bjl_objectAtIndex:indexPath.row];
    }
    else {
        userForCell = [self.normalParticipatedUsers bjl_objectAtIndex:indexPath.row];
    }
    return userForCell;
}

- (void)updateCaptionWithName:(nullable NSString *)name groupInfo:(nullable BJLUserGroup *)groupInfo {
    if (name.length) {
        self.titleNameLabel.text = [NSString stringWithFormat:@"%@的小黑板", [BJLUser displayNameOfName:name]];
        if (groupInfo) {
            self.groupColorLabel.hidden = NO;
            self.groupNameLabel.hidden = NO;
            self.groupColorLabel.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color];
            self.groupNameLabel.text = groupInfo.name;
        }
    }
    else {
        self.titleNameLabel.text = @"小黑板";
        self.groupColorLabel.hidden = YES;
        self.groupNameLabel.hidden = YES;
    }
    self.writingBoard.userName = name;
    self.bottomToolBarViewController.showNickNameButton.selected = !!name.length;
}

- (void)submitBoard {
    if (!self.writingBoard.isActive
       || self.writingBoard.status != BJLIcWriteBoardStatus_studentEdit
       || self.room.loginUser.isTeacher) {
        return;
    }
    
    [self.room.documentVM submitWritingBoard:self.writingBoard.boardID];
    self.windowInterfaceEnabled = NO;
    self.writingBoard.isActive = NO;
    self.status = BJLIcWriteBoardStatus_None;
    [self.timer invalidate];
    self.timer = nil;
        
    bjl_weakify(self);
    __block NSInteger leftTipTime = 3;
    self.leftTipTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self || leftTipTime <= 0) {
            [self.leftTipTimer invalidate];
            return;
        }
        
        NSString *message = [NSString stringWithFormat:@"已提交 %td秒后自动关闭", leftTipTime];
        [self.promptViewController enqueueWithSpecialPrompt:message duration:1 important:NO];
        leftTipTime--;
    }];

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self) {
            [self closeWithoutRequest];
        }
    });
}

/** 场景:作答中的小黑板,老师右上角X按钮确认关闭后 */
- (void)teacherCloseWritingBoardWithGatherRequest {
    if (self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished) {
        [self publishWithOperate:BJLWritingBoardPublishOperate_end restrictionTimeString:nil];
        [self closeWritingBoard];
    }
}

- (nullable BJLError *)clearWritingBoard {
    NSIndexPath *currentIndexPath = [self getCurrentCellIndexPath];
    BJLIcWritingBoardCollectionViewCell *pptCell = (BJLIcWritingBoardCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:currentIndexPath];
    if ([pptCell respondsToSelector:@selector(clearShapes)]) {
        [pptCell clearShapes];
    }
    return nil;
}

//关闭小黑板
- (void)closeWritingBoard {
    if (self.writingBoardWindowCloseCallback) {
        self.writingBoardWindowCloseCallback(self.writingBoard.boardID, self.writingBoard.pageIndex, self.userNumber);
    }
    [super close];
}

- (NSIndexPath *)getCurrentCellIndexPath {
    CGPoint contentOffset = self.collectionView.contentOffset;
    return [self.collectionView indexPathForItemAtPoint:contentOffset];
}

- (void)addParticipatedUserLayer:(NSString *)userLayer {
    if (!userLayer.length
       || !self.room.loginUser.isTeacher
       || self.writingBoard.isActive
       || self.writingBoard.status == BJLIcWriteBoardStatus_teacherShare) {
        return;
    }
    
    if ([userLayer isEqualToString:BJLWritingboardUserNumberForTeacher]) {
        self.hasTeacher = YES;
    }
    else {
        BJLUser *participateduser = nil;
        for(BJLUser *user in self.room.documentVM.allWritingBoardParticipatedUsers) {
            if ([user.number isEqualToString:userLayer]) {
                participateduser = user;
                break;
            }
        }

        BOOL isActiveUser = NO;
        for (BJLUser *user in self.room.playingVM.playingUsers) {
            if ([user.number isEqualToString:userLayer]) {
                isActiveUser = YES;
                break;
            }
        }
        
        if (isActiveUser) {
            BOOL hasExist = NO;
            for (BJLUser *user in self.activeParticipatedUsers) {
                if ([user.number isEqualToString:userLayer]) {
                    hasExist = YES;
                    break;
                }
            }
            if (!hasExist) {
                NSMutableArray *participatedUsers = [self.activeParticipatedUsers mutableCopy] ? : [NSMutableArray array];
                [participatedUsers bjl_addObject:participateduser];
                self.activeParticipatedUsers = participatedUsers;
            }
        }
        else {
            BOOL hasExist = NO;
            for (BJLUser *user in self.normalParticipatedUsers) {
                if ([user.number isEqualToString:userLayer]) {
                    hasExist = YES;
                    break;
                }
            }
            if (!hasExist) {
                NSMutableArray *participatedUsers = [self.normalParticipatedUsers mutableCopy] ? : [NSMutableArray array];
                [participatedUsers bjl_addObject:participateduser];
                self.normalParticipatedUsers = participatedUsers;
            }
        }
    }
    self.currentLayer = self.currentLayer;
}

/** 窗口的时间输入回调,返回的时间,更新到窗口上 */
- (void)inputTimeString:(NSString *)timeString {
    if (self.room.loginUser.isTeacher && self.writingBoard.status == BJLIcWriteBoardStatus_teacherEditing) {
        if (!!timeString.length ) {
            if ([[timeString substringFromIndex:timeString.length - 1] isEqualToString:@"\n"]) {
                timeString = [timeString substringToIndex:timeString.length - 1];
            }
        }
        
        if (![self isValidDuration:timeString]) {
            [self.promptViewController enqueueWithPrompt:@"请输入合法时间"];
            return;
        }
        
        [self.bottomToolBarViewController updateInputTimeString:timeString];
    }
}

#pragma mark - protected

/** 老师的publish信令操作 */
- (void)publishWithOperate:(BJLWritingBoardPublishOperate)operate restrictionTimeString:(nullable NSString *)restrictionTimeString {
    if (!self.room.loginUser.isTeacher) {
        return;
    }
    
    if (operate == BJLWritingBoardPublishOperate_begin) {
        if (![self isValidDuration:restrictionTimeString]) {
            [self.promptViewController enqueueWithPrompt:@"请重新输入小黑板作答时间"];
            return;
        }
        
        NSInteger duration = [restrictionTimeString integerValue];
        //转换为秒单位
        duration = (MIN(MAX(duration, 0), 150)) * 60;
        
        //publish信令发布
        [self.room.documentVM publishWritingBoardWithID:self.writingBoard.boardID
                                                operate:BJLWritingBoardPublishOperate_begin
                                                duraton:duration];
        
        //先更新本都duration和startTime
        self.writingBoard.duration = duration;
        self.writingBoard.startTime = [[NSDate date] timeIntervalSince1970];
        
    }
    else if (operate == BJLWritingBoardPublishOperate_end) {
        //收回
        [self.room.documentVM publishWritingBoardWithID:self.writingBoard.boardID
                                                operate:BJLWritingBoardPublishOperate_end
                                                duraton:0];
        
        self.writingBoard.duration = 0;
        self.writingBoard.startTime = 0;
    }
    else {//BJLWritingBoardPublishOperate_revoke
        //撤销,不保留学生画笔
        [self.room.documentVM publishWritingBoardWithID:self.writingBoard.boardID
                                                operate:BJLWritingBoardPublishOperate_revoke
                                                duraton:0];
        
        self.writingBoard.duration = 0;
        self.writingBoard.startTime = 0;
    }
}

/** 老师点击重新编辑, 清理除老师之外的所有作答用户画笔 */
- (void)reedit {
    self.writingBoard.isActive = NO;
    self.isPublished = NO;
    
    if (self.teacherwillReEditWritingBoardCallback) {
        self.teacherwillReEditWritingBoardCallback();
    }
    
    [self.room.drawingVM clearStudentShapesOnWritingBoard:self.writingBoard.boardID pageIndex:self.writingBoard.pageIndex];
    [self updateWritingBoardStatus];
}

- (void)share {
    BJLUser *currentUser = [self getUserForIndexPath:self.currentIndexPath];
    if (!currentUser
       || !self.room.loginUser.isTeacher) {
        return;
    }
    
    NSString *sharedLayer = self.currentLayer;
    //share要移除用户, 同时关闭分享时,需要把用户加回老师的管理窗口
    
    if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_loginUser) {
        self.hasTeacher = NO;
        if (self.currentLayer == BJLWritingboardUserNumberForTeacher) {
            if ([self.activeParticipatedUsers count]) {
                self.currentShowUser = [self.activeParticipatedUsers bjl_objectAtIndex:0];
                self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_activeUser];
                self.currentLayer = self.currentShowUser.number;
            }
            else if ([self.normalParticipatedUsers count]) {
                self.currentShowUser = [self.normalParticipatedUsers bjl_objectAtIndex:0];
                self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_normal];
                self.currentLayer = self.currentShowUser.number;
            }
            else {
                self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
                self.currentShowUser = self.room.loginUser;
                self.currentLayer = BJLWritingboardUserNumberForTeacher;
            }
        }
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_activeUser) {
        NSMutableArray *participatedUsers = [self.activeParticipatedUsers mutableCopy] ? : [NSMutableArray array];
        [participatedUsers removeObject:currentUser];
        self.activeParticipatedUsers = [participatedUsers copy];
        if (self.currentIndexPath.row < [self.activeParticipatedUsers count]) {
            self.currentShowUser = [self.activeParticipatedUsers bjl_objectAtIndex:self.currentIndexPath.row];
            self.currentLayer = self.currentShowUser.number;
        }
        else if ([self.normalParticipatedUsers count]) {
            self.currentShowUser = [self.normalParticipatedUsers bjl_objectAtIndex:0];
            self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_normal];
            self.currentLayer = self.currentShowUser.number;
        }
        else {
            self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
            self.currentShowUser = self.room.loginUser;
            self.currentLayer = BJLWritingboardUserNumberForTeacher;
        }
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_normal) {
        NSMutableArray *participatedUsers = [self.normalParticipatedUsers mutableCopy] ? : [NSMutableArray array];
        [participatedUsers removeObject:currentUser];
        self.normalParticipatedUsers = [participatedUsers copy];
        if (self.currentIndexPath.row < [self.normalParticipatedUsers count]) {
            self.currentShowUser = [self.normalParticipatedUsers bjl_objectAtIndex:self.currentIndexPath.row];
            self.currentLayer = self.currentShowUser.number;
        }
        else {
            self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
            self.currentShowUser = self.room.loginUser;
            self.currentLayer = BJLWritingboardUserNumberForTeacher;
        }
    }
    else {
        return;
    }
        
    if (self.writingBoardWindowShareCallback) {
        self.writingBoardWindowShareCallback(self.writingBoard, sharedLayer, self.relativeRect);
    }
}

/** 只有老师在答题中和已收回时,可以查看学员答题列表 */
- (BOOL)isValidStatusForUserListAndToolBar {
    BOOL isTeacher = self.room.loginUser.isTeacher;
    
    if (isTeacher
       && (self.writingBoard.status == BJLIcWriteBoardStatus_teacherGathered || self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished)) {
        return YES;
    }
    return NO;
}

- (BOOL)isValidIndexPathInUserList:(NSIndexPath *)indexPath {
    if (indexPath.section == BJLIcWritingboradUserlistSection_loginUser) {
        return (self.hasTeacher && indexPath.row == 0);
    }
    else if (indexPath.section == BJLIcWritingboradUserlistSection_activeUser) {
        return (indexPath.row < [self.activeParticipatedUsers count] && indexPath.row >= 0 && self.shouldOpenActiveUserList);
    }
    else if (indexPath.section == BJLIcWritingboradUserlistSection_normal)  {
        return (indexPath.row < [self.normalParticipatedUsers count] && indexPath.row >= 0 && self.shouldOpenNormalUserList);
    }
    return NO;
}

- (BOOL)isValidIndexPathInCollectionView:(NSIndexPath *)indexPath {
    if (indexPath.section == BJLIcWritingboradUserlistSection_loginUser) {
        return (indexPath.row == 0 && self.hasTeacher);
    }
    else if (indexPath.section == BJLIcWritingboradUserlistSection_activeUser) {
        return (indexPath.row < [self.activeParticipatedUsers count] && indexPath.row >= 0);
    }
    else if (indexPath.section == BJLIcWritingboradUserlistSection_normal)  {
        return (indexPath.row < [self.normalParticipatedUsers count] && indexPath.row >= 0);
    }
    return NO;
}

#pragma mark - alert
- (void)askToRevokeWritingBoard {
    if (!self.room.loginUser.isTeacher) {
        return ;
    }
    
    if (self.popoverViewController) {
        [self.popoverViewController bjl_removeFromParentViewControllerAndSuperiew];
        self.popoverViewController = nil;
    }
    
    NSString *message = @"撤销小黑板将不保留学生数据\n是否继续撤销";
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcRevokeWritingBoard message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self publishWithOperate:BJLWritingBoardPublishOperate_revoke restrictionTimeString:nil];
        self.popoverViewController = nil;
    }];
    self.popoverViewController = popoverViewController;
}

- (void)askToClearWritingBoard {
    if (self.popoverViewController) {
        [self.popoverViewController bjl_removeFromParentViewControllerAndSuperiew];
        self.popoverViewController = nil;
    }

    NSString *message = @"清空小黑板无法恢复\n是否继续清空";
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcRevokeWritingBoard message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        BJLError *error = [self clearWritingBoard];
        if (error) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
        }
        self.popoverViewController = nil;
    }];
    self.popoverViewController = popoverViewController;
}

- (void)askToCloseWritingBoard {
    if (!self.room.loginUser.isTeacher) {
        return ;
    }
    NSString *message = @"关闭窗口将收回学生页面, 是否继续?";
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWritingBoard message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self teacherCloseWritingBoardWithGatherRequest];
    }];
}

#pragma mark - private

- (void)updateBottomAndTopText {
    BOOL isTeacher = self.room.loginUser.isTeacher;
    NSInteger activeUserCount = [self.activeParticipatedUsers count];
    NSInteger normalUserCount = [self.normalParticipatedUsers count];
    
    NSInteger currentIndex = self.hasTeacher * (self.currentIndexPath.section > 0) + activeUserCount * (self.currentIndexPath.section > 1) + self.currentIndexPath.row + 1;
    NSInteger totalCount = self.hasTeacher  + activeUserCount + normalUserCount;
    if (isTeacher
       && (self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished || self.writingBoard.status == BJLIcWriteBoardStatus_teacherGathered)) {
        
        BJLUserGroup *groupInfo = nil;
        for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
            if (group.groupID == self.currentShowUser.groupID) {
                groupInfo = [group copy];
                break;
            }
        }

        if (groupInfo.color.length) {
            self.topToolBarViewController.groupColorLabel.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color];
        }
        else {
            self.topToolBarViewController.groupColorLabel.backgroundColor = [UIColor clearColor];
        }

        self.topToolBarViewController.groupNameLabel.text = groupInfo.name;
        self.topToolBarViewController.studentNameLabel.text = [NSString stringWithFormat:@"当前查看: %@", self.currentShowUser.displayName];
        self.bottomToolBarViewController.pageNumberLabel.text = [NSString stringWithFormat:@"%td/%td", currentIndex, totalCount];
        if (!totalCount) {
            self.bottomToolBarViewController.pageNumberLabel.text = @"0/0";
        }
    }
    
    self.topToolBarViewController.view.hidden = !( self.room.loginUser.isTeacher
                                                  && totalCount
                                                  && (self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished ||(self.writingBoard.status ==  BJLIcWriteBoardStatus_teacherGathered)) );
}

- (void)updateUserListView {
    [self.boardUserListView.tableView reloadData];
    if ([self isValidIndexPathInUserList:self.currentIndexPath] && !self.boardUserListView.hidden) {
        [self.boardUserListView.tableView selectRowAtIndexPath:self.currentIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void)updateCollectionView {
    [self.collectionView reloadData];
    if ([self isValidIndexPathInCollectionView:self.currentIndexPath]) {
        [self.collectionView scrollToItemAtIndexPath:self.currentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

- (void)updateWritingBoardStatus {
     BOOL isTeacher = self.room.loginUser.isTeacher;
    
    if (!isTeacher && self.writingBoard.isActive) {
        [self.room.documentVM participateWritingBoard:self.writingBoard.boardID];
        self.status = BJLIcWriteBoardStatus_studentEdit;
    }
    else if (!isTeacher && !self.writingBoard.isActive) {
        self.status = BJLIcWriteBoardStatus_None;
    }
    else if (isTeacher && !self.isPublished) {
        self.status = BJLIcWriteBoardStatus_teacherEditing;
    }
    else if (isTeacher && self.isPublished && self.writingBoard.isActive ) {
        self.status = BJLIcWriteBoardStatus_teacherPublished;
    }
    else if (isTeacher && self.isPublished && !self.writingBoard.isActive ) {
        if ([self.userNumber isEqualToString:BJLWritingboardUserNumberForTeacher] && !(self.writingBoard.status == BJLIcWriteBoardStatus_teacherShare)) {
            self.status = BJLIcWriteBoardStatus_teacherGathered;
        }
        else {
            self.status = BJLIcWriteBoardStatus_teacherShare;
        }
    }
    else {
        self.status = BJLIcWriteBoardStatus_None;
    }
}

- (void)setStatus:(BJLIcWriteBoardStatus)status {
    self.writingBoard.status = status;
    [self.timer invalidate];
    self.timer = nil;

    [self.room.drawingVM updateWritingBoardEnabled:status == BJLIcWriteBoardStatus_teacherEditing
                                                                || status ==  BJLIcWriteBoardStatus_teacherGathered
     || status ==  BJLIcWriteBoardStatus_studentEdit
     || (status == BJLIcWriteBoardStatus_teacherShare && self.room.loginUser.isTeacher) ];
    
    self.userListButton.hidden = !((status == BJLIcWriteBoardStatus_teacherPublished)
                                   ||(status ==  BJLIcWriteBoardStatus_teacherGathered));
    self.boardUserListView.hidden = YES;
    
    NSInteger totalCount = self.hasTeacher  + [self.activeParticipatedUsers count] + [self.normalParticipatedUsers count];

    [self.topToolBarViewController updateViewConstraintsWithStatus:status];
    self.topToolBarViewController.view.hidden = !( self.room.loginUser.isTeacher && totalCount && (status == BJLIcWriteBoardStatus_teacherPublished ||(status ==  BJLIcWriteBoardStatus_teacherGathered)) );
    
    [self.bottomToolBarViewController updateViewConstraintsWithStatus:status shouldshareUserName:(!!self.writingBoard.userName.length)];
    self.bottomToolBarViewController.timeForTeachLabel.hidden = !(status == BJLIcWriteBoardStatus_teacherPublished && (self.writingBoard.duration > 0));
    self.bottomToolBarViewController.timeForStuLabel.hidden = !(status == BJLIcWriteBoardStatus_studentEdit && (self.writingBoard.duration > 0));

    if ((status == BJLIcWriteBoardStatus_teacherPublished
        || status == BJLIcWriteBoardStatus_studentEdit) && (self.writingBoard.duration > 0)) {
        bjl_weakify(self);
        self.timer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            bjl_strongify(self);
            if (!self || (self.writingBoard.duration <= 0)) {
                [timer invalidate];
                return;
            }
            [self updateCountDownTip];
        }];
    }
    
    if (status == BJLIcWriteBoardStatus_teacherShare) {
        self.currentShowUser = nil;
        self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        self.currentLayer = self.userNumber;
    }
    else if (status == BJLIcWriteBoardStatus_studentEdit) {
        self.currentShowUser = self.room.loginUser;
        self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        self.currentLayer = self.userNumber;
    }
    else if (status == BJLIcWriteBoardStatus_teacherEditing) {
        self.hasTeacher = YES;
        [self.mutaCheckedUsers removeAllObjects];
        [self.mutaCheckedUsers addObject:self.room.loginUser];
        self.checkedUsers = self.mutaCheckedUsers;
//        self.participatedUsers = [NSArray arrayWithObject:self.room.loginUser];
        self.submitedUsers = [NSArray array];
        
        self.currentShowUser = self.room.loginUser;
        self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        self.currentLayer = BJLWritingboardUserNumberForTeacher;
    }
    else if (status == BJLIcWriteBoardStatus_teacherPublished) {
        self.hasTeacher = YES;
        [self.mutaCheckedUsers removeAllObjects];
        [self.mutaCheckedUsers addObject:self.room.loginUser];
        self.checkedUsers = self.mutaCheckedUsers;
        self.submitedUsers = [NSArray arrayWithObject:self.room.loginUser];
//        self.participatedUsers = [NSArray arrayWithObject:self.room.loginUser];
        self.currentShowUser = self.room.loginUser;
        self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        self.currentLayer = BJLWritingboardUserNumberForTeacher;
    }
    else if (status == BJLIcWriteBoardStatus_teacherGathered) {
        self.hasTeacher = YES;
        self.submitedUsers = [self.room.documentVM.allWritingBoardParticipatedUsers copy];
        [self updateUserListView];
    }
    else if (!self.room.loginUser.isTeacher && status == BJLIcWriteBoardStatus_None) {
        self.bottomBar.hidden = NO;
        self.resizeHandleImageViewHidden = YES;
        self.maximizeButtonHidden = YES;
        self.topBar.hidden = NO;
    }
}

- (void)updateCountDownTip {
    NSTimeInterval endTimeInterval = self.writingBoard.startTime + self.writingBoard.duration;
    NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval leftTimeInterval = endTimeInterval - nowTimeInterval;
    
    if (leftTimeInterval <= 0.0 ) {
        if (!self.room.loginUser.isTeacher
           && self.writingBoard.status == BJLIcWriteBoardStatus_studentEdit
           && self.writingBoard.isActive) {
            [self submitBoard];
        }
        else if (self.room.loginUser.isTeacher && self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished) {
            [self.room.documentVM publishWritingBoardWithID:self.writingBoard.boardID
                                                    operate:BJLWritingBoardPublishOperate_end
                                                    duraton:0];
        }
        [self.timer invalidate];
        self.timer = nil;
    }
    else {
        if (leftTimeInterval <= 10.0 ) {
            [self.bottomToolBarViewController.timeForStuLabel setFont:[UIFont systemFontOfSize:24]];
            self.bottomToolBarViewController.timeForStuLabel.textColor = [UIColor whiteColor];
            
//            if (!self.room.loginUser.isTeacher && self.writingBoard.status == BJLIcWriteBoardStatus_studentEdit) {
//                [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"倒计时 %d秒后提交", (int)leftTimeInterval] duration:0.8];
//            }
        }
        else {
            if (leftTimeInterval > 60) {
                [self.bottomToolBarViewController.timeForStuLabel setTextColor:[UIColor colorWithWhite:1 alpha:0.5]];
                self.bottomToolBarViewController.timeForStuLabel.font = [UIFont systemFontOfSize:14.0];
            }
            else {
                self.bottomToolBarViewController.timeForStuLabel.font = [UIFont systemFontOfSize:14.0];
                self.bottomToolBarViewController.timeForStuLabel.textColor = [UIColor whiteColor];
            }
        }
        
        if (self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished) {
            [self.bottomToolBarViewController.timeForTeachLabel setText:[NSString stringWithFormat:@"%@后收回", [self stringFromTimeInterval:leftTimeInterval]]];
        }
        else if (self.writingBoard.status == BJLIcWriteBoardStatus_studentEdit) {
            [self.bottomToolBarViewController.timeForStuLabel setText:[self stringFromTimeInterval:leftTimeInterval]];
        }
    }
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    int hours = interval / 3600;
    int minums = ((long long)interval % 3600) / 60;
    int seconds = (long long)interval % 60;
    if (hours > 0) {
        return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minums, seconds];
    }
    else {
        if (minums > 0 || (minums <= 0 && seconds > 10)) {
            return [NSString stringWithFormat:@"%02d:%02d", minums, seconds];
        }
        else {
            return [NSString stringWithFormat:@"%01d", seconds];
        }
    }
}

- (BOOL)isValidDuration:(NSString *)durationString {
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:durationString]) {
        return YES;
    }
    return NO;
}

#pragma mark - override
//顶部x关闭按钮,需要弹框提醒
- (void)close {
    //正在的小黑板, 老师点击X确认关闭时,需要发收回信令
    if (self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished) {
        [self askToCloseWritingBoard];
    }
    else {
        [self closeWritingBoard];
    }
}

- (void)closeWithoutRequest {
    self.writingBoard.duration = 0;
    self.writingBoard.startTime = 0;
    [self.timer invalidate];
    self.timer = nil;

    if (self.writingBoardWindowCloseCallback) {
        self.writingBoardWindowCloseCallback(self.writingBoard.boardID, self.writingBoard.pageIndex, self.userNumber);
    }
    [super closeWithoutRequest];
}

@end

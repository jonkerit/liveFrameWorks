//
//  BJLIcBlackboardLayoutViewController+WritingBoard.m
//  BJLiveCore
//
//  Created by 凡义 on 2019/3/22.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+WritingBoard.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (WritingBoard)

- (void)makeObserversForWritingBoard {
    bjl_weakify(self);
    /* 作答中的学生/助教,下课时自动提交 */
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               bjl_strongify(self);
               return (old.boolValue != now.boolValue && self.writingBoardViewController);
           }
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self.room.roomVM.liveStarted) {
                 BOOL isTeacher = self.room.loginUser.isTeacher;
                 if (!isTeacher) {
                     [self.writingBoardViewController submitBoard];
                 }
                 else {
                     [self.writingBoardViewController teacherCloseWritingBoardWithGatherRequest];
                 }
             }
             return YES;
     }];

    /* 同步分享的小黑板窗口 */
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didUpdateWritingBoradWindowWithModel:shouldReset:)
             observer:(BJLMethodObserver)^BOOL(BJLWindowUpdateModel *updateModel, BOOL shouldReset) {
                 bjl_strongify(self);
                 // 分享的小黑板窗口
                 if (shouldReset) {
                     [self resetWritingBoardWindowsWithModel:updateModel];
                 }
                 else {
                     [self updateWritingBoardWindowsWithModel:updateModel];
                 }
                 return YES;
             }];
    
    /* 助教权限同学生 */
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didPublishWritingBoard:)
               filter:^BOOL(BJLWritingBoard *writingBoard) {
                   return (writingBoard
                           && writingBoard.boardID.length);
               }
             observer:^BOOL(BJLWritingBoard *writingBoard) {
                 bjl_strongify(self);
                 BOOL isTeacher = self.room.loginUser.isTeacher;
                 // 老师收到发布小黑板信令res时, 需要关闭已分享/发布的窗口
                 if (isTeacher
                    && writingBoard.operate == BJLWritingBoardPublishOperate_begin) {
                     [self closeDisplayingWritingBoardWindowsWithRequestUpdate:YES];
                     return YES;
                 }
                 else if (isTeacher) {
                     return YES;
                 }
                 // 判断是否为学生/助教
                 if (writingBoard.operate == BJLWritingBoardPublishOperate_begin) {
                     //学生收到发布的小黑板之后 先清空之前已发布的黑板
                     writingBoard.status = BJLIcWriteBoardStatus_studentEdit;
                     [self closeDisplayingWritingBoardWindowsWithRequestUpdate:NO];
                     [self displayingMyWritingBoardWindows:writingBoard userNumber:self.room.loginUser.number];
                 }
                 else if (writingBoard.operate == BJLWritingBoardPublishOperate_revoke
                         && self.writingBoardViewController) {
                     [self.writingBoardViewController closeWithoutRequest];
                     [self.writingBoardViewController bjl_removeFromParentViewControllerAndSuperiew];
                     self.writingBoardViewController = nil;
                     // 小黑板被撤销的时候取消其小黑板画笔权限
                     [self.room.drawingVM updateWritingBoardEnabled:NO];

                     if (self.showErrorMessageCallback) {
                        self.showErrorMessageCallback(@"小黑板已被撤回");
                     }
                 }
                 else if (writingBoard.operate == BJLWritingBoardPublishOperate_end
                         && self.writingBoardViewController) {
                     if (self.writingBoardViewController.writingBoard.status == BJLIcWriteBoardStatus_studentEdit
                        && self.writingBoardViewController.writingBoard.isActive) {
                         [self.writingBoardViewController submitBoard];
                         if (self.showErrorMessageCallback) {
                             self.showErrorMessageCallback(@"小黑板已被收回");
                         }
                     }
                 }
                 return YES;
             }];
    
    /** pull操作都是用户主动触发的, 学生/助教进教室后,主动pull教室内部小黑板状态, 老师点击小黑板按钮主动pull小黑板状态
     1. 老师pull 小黑板, 如果boardID存在, 则根据状态来展示窗口, 如不存在,则创建一个发布按钮的小黑板窗口
     2. 学生/助教pull 小黑板, 如果boardID存在 && 答题中, 则进入作答状态, 否则不要展示.
     3. 分享的窗口是走广播信令的.
     */
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didPullWritingBoard:)
               filter:^BOOL(BJLWritingBoard *writingBoard){
                   return !!writingBoard;
               }
             observer:^BOOL(BJLWritingBoard *writingBoard){
                 bjl_strongify(self);

                 BOOL hasWritingBoard = !!writingBoard.boardID.length;
                 BOOL isActive = writingBoard.isActive;
                 BOOL isTeacher = self.room.loginUser.isTeacher;
                 BOOL writingBoardWindowExist = !!self.writingBoardViewController;
                 if (isTeacher && isActive && hasWritingBoard && !writingBoardWindowExist) {
                     writingBoard.status = BJLIcWriteBoardStatus_teacherPublished;
                     //老师展示作答中的窗口: published
                     [self displayingMyWritingBoardWindows:writingBoard userNumber:BJLWritingboardUserNumberForTeacher];
                 }
                 else if (isTeacher && !isActive && hasWritingBoard && !writingBoardWindowExist) {
                     //老师新添加一个答题已结束的小黑板 gather
                     writingBoard.status = BJLIcWriteBoardStatus_teacherGathered;
                     [self displayingMyWritingBoardWindows:writingBoard userNumber:BJLWritingboardUserNumberForTeacher];
                 }
                 else if (isTeacher && /*!isActive &&*/ !hasWritingBoard  && !writingBoardWindowExist) {
                     //老师添加一个编辑小黑板的窗口 teacher_editing
                     [self closeDisplayingWritingBoardWindowsWithRequestUpdate:YES];
                     BJLWritingBoard *newWritingBoard = [[BJLWritingBoard alloc] initWithBoardID:BJLWritingboardID pageIndex:BJLWritingboardPageIndex];
                     newWritingBoard.status = BJLIcWriteBoardStatus_teacherEditing;
                     newWritingBoard.isActive = NO;
                     [self displayingMyWritingBoardWindows:newWritingBoard userNumber:BJLWritingboardUserNumberForTeacher];
                 }
                 else if (!isTeacher && hasWritingBoard && isActive ) {
                     BOOL hasSubmited = NO;
                     for (BJLUser *user in writingBoard.submitedUsers) {
                         if ([user.number isEqualToString:self.room.loginUser.number]) {
                             hasSubmited = YES;
                             break;
                         }
                     }

                     //学生进入小黑板作答模式, 再次确认是否已提交
                     if (!hasSubmited) {
                         writingBoard.status = BJLIcWriteBoardStatus_studentEdit;
                         [self closeDisplayingWritingBoardWindowsWithRequestUpdate:NO];
                         [self displayingMyWritingBoardWindows:writingBoard userNumber:self.room.loginUser.number];
                     }
                 }
                 return YES;
    }];
}

#pragma mark - writingBoard

/* 展示当前用户自己作答的小黑板窗口 */
- (void)displayingMyWritingBoardWindows:(BJLWritingBoard *)writingBoard userNumber:(NSString *)userNumber {
    if (self.writingBoardViewController) {
        [self.writingBoardViewController bjl_removeFromParentViewControllerAndSuperiew];
        self.writingBoardViewController = nil;
    }
    
    self.writingBoardViewController = [[BJLIcWritingBoradWindowViewController alloc] initWithRoom:self.room
                                                                                     writingBoard:writingBoard
                                                                                       userNumber:userNumber];
    
    [self.writingBoardViewController setWindowedParentViewController:self
                                                           superview:self.writingBoardWindowsView];
    
    bjl_weakify(self);
    [self.writingBoardViewController setShowTimeInputCallBack:^() {
        bjl_strongify(self);
        if (self.showWritingBoardTimeInputViewControllerCallBack) {
            self.showWritingBoardTimeInputViewControllerCallBack();
        }
    }];
    
    [self.writingBoardViewController setWritingBoardWindowCloseCallback:^(NSString * _Nonnull boardID, NSInteger pageIndex, NSString * _Nonnull userNumber) {
        bjl_strongify(self);
        self.writingBoardViewController = nil;
    }];
    
    // 老师重新编辑需要先关闭分享窗口
    [self.writingBoardViewController setTeacherwillReEditWritingBoardCallback:^() {
        bjl_strongify(self);
        [self closeDisplayingWritingBoardWindowsWithRequestUpdate:YES];
    }];
    
    [self.writingBoardViewController setWritingBoardWindowShareCallback:^(BJLWritingBoard *writingBoard, NSString *layerID, CGRect relativeRect) {
        bjl_strongify(self);
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.writingBoardWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:layerID]) {
                oldDisplayInfo = displayInfo;
                break;
            }
        }
        if (oldDisplayInfo) {
            [self.mutableWritingBoardWindowDisplayInfos removeObject:oldDisplayInfo];
        }
        
        BJLWindowDisplayInfo *newDisplayInfo = ({
            BJLWindowDisplayInfo *info = [[BJLWindowDisplayInfo alloc] init];
            info.ID = layerID;
            info.x = CGRectGetMinX(relativeRect);
            info.y = CGRectGetMinY(relativeRect);
            info.width = CGRectGetWidth(relativeRect);
            info.height = CGRectGetHeight(relativeRect);
            info;
        });
        
        [self.mutableWritingBoardWindowDisplayInfos bjl_addObject:newDisplayInfo];
        self.writingBoardWindowDisplayInfos = self.mutableWritingBoardWindowDisplayInfos;
        
        if (self.room.loginUser.isTeacher && layerID) {
            [self.room.documentVM updateWritingBoardWindow:writingBoard
                                                userNumber:layerID
                                                    action:BJLWindowsUpdateAction_open
                                              displayInfos:self.writingBoardWindowDisplayInfos];
        }
    }];
    [self.writingBoardViewController openWithoutRequest];
}

- (void)resetWritingBoardWindowsWithModel:(BJLWindowUpdateModel *)updateModel {
    [self closeDisplayingWritingBoardWindowsWithRequestUpdate:NO];
    self.writingBoardWindowDisplayInfos = [NSArray array];
    self.mutableWritingBoardWindowDisplayInfos = [NSMutableArray array];
    
    BOOL hasFindStick = NO;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        NSString *userNumber = displayInfo.ID;
        //reset窗口的时候，不应该使用action，应该把all displayinfo都展示成窗口, 区分窗口和最大化，全屏
        NSString *action = BJLWindowsUpdateAction_open;
        if (displayInfo.isFullScreen) {
            action = BJLWindowsUpdateAction_fullScreen;
        }
        else if (displayInfo.isMaximized) {
            action = BJLWindowsUpdateAction_maximize;
        }
        if (action == BJLWindowsUpdateAction_open && hasFindStick == NO) {
            //第一个窗户是stick
            action = BJLWindowsUpdateAction_stick;
            hasFindStick = YES;
        }

        [self setupWritingBoardWindowWithUserNumber:userNumber
                                             action:action
                                        displayInfo:displayInfo];
    }
}

- (void)updateWritingBoardWindowsWithModel:(BJLWindowUpdateModel *)updateModel {
    NSString *userNumber = updateModel.ID;
    if (!userNumber.length) {
        return;
    }

    BJLWindowDisplayInfo *newDisplayInfo;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        if ([displayInfo.ID isEqualToString:userNumber]) {
            newDisplayInfo = displayInfo;
            break;
        }
    }
    
    BJLWindowDisplayInfo *oldDisplayInfo;
    for (BJLWindowDisplayInfo *displayInfo in [self.documentWindowDisplayInfos copy]) {
        if ([displayInfo.ID isEqualToString:userNumber]) {
            oldDisplayInfo = displayInfo;
            break;
        }
    }
    if (oldDisplayInfo) {
        [self.mutableDocumentWindowDisplayInfos removeObject:oldDisplayInfo];
    }
    
    [self setupWritingBoardWindowWithUserNumber:userNumber
                                         action:updateModel.action
                                    displayInfo:newDisplayInfo];
}

- (void)setupWritingBoardWindowWithUserNumber:(NSString *)userNumber
                                       action:(NSString *)action
                                  displayInfo:(BJLWindowDisplayInfo *)displayInfo {
    // 关闭
    if ([action isEqualToString:BJLWindowsUpdateAction_close]) {
        [self closeDisplayingWritingBoardWindowWithID:BJLWritingboardID
                                            pageIndex:BJLWritingboardPageIndex
                                           userNumber:userNumber
                                        requestUpdate:NO];
        return;
    }
    
    NSString *key = [self keyForWritingBoard:BJLWritingboardID pageIndex:BJLWritingboardPageIndex userNumber:userNumber];
    BJLIcWritingBoradWindowViewController *window = [self.displayingWritingBoardWindows bjl_objectForKey:key
                                                                                                   class:[BJLIcWritingBoradWindowViewController class]];
    
    // 打开
    if ([action isEqualToString:BJLWindowsUpdateAction_open]
        || !window) {
        BJLWritingBoard *board = [BJLWritingBoard new];
        board.status = BJLIcWriteBoardStatus_teacherShare;
        window = (BJLIcWritingBoradWindowViewController *)[self displayWritingBoardWindowWith:board userNumber:userNumber requestUpdate:NO];
    }
    
    BJLUserGroup *group = nil;
    NSInteger groupID = 0;
    for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
        if ([user.number isEqualToString:userNumber]) {
            groupID = user.groupID;
            break;
        }
    }
    for (BJLUserGroup *groupItem in self.room.onlineUsersVM.groupList) {
        if (groupID == groupItem.groupID) {
            group = groupItem;
            break;
        }
    }
    [window updateCaptionWithName:displayInfo.name groupInfo:group];

    // 全屏 !!!: no else if
    if ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]) {
        [window fullScreenWithoutRequest];
    }
    // 最大化
    else if ([action isEqualToString:BJLWindowsUpdateAction_maximize]) {
        [window maximizeWithoutRequest];
    }
    // 还原
    else if ([action isEqualToString:BJLWindowsUpdateAction_restore]) {
        [window restoreWithoutRequest];
    }
    else {
        [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
    }
    [window bringToFrontWithoutRequest];
    if (displayInfo) {
        [self.mutableWritingBoardWindowDisplayInfos bjl_addObject:displayInfo];
    }
    self.writingBoardWindowDisplayInfos = self.mutableWritingBoardWindowDisplayInfos;
}

- (NSString *)keyForWritingBoard:(NSString *)documentID pageIndex:(NSInteger)pageIndex userNumber:(NSString *)userNumber {
    NSString *key = [NSString stringWithFormat:@"%@-%@-%@", documentID, @(pageIndex), userNumber];
    return key;
}

@end

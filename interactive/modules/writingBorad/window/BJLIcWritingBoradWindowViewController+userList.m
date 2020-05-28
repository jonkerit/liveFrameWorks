//
//  BJLIcWritingBoradWindowViewController+userList.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWritingBoradWindowViewController+userList.h"
#import "BJLIcWritingBoradWindowViewController+protected.h"
#import "BJLIcWritingBoardUserTableViewCell.h"
#import "BJLIcWritingBoardUserListHeaderView.h"

@implementation BJLIcWritingBoradWindowViewController (userList)

#pragma mark - action
- (void)setupBoardUserList {
    
    [self.userListButton addTarget:self action:@selector(showBoardUserList:) forControlEvents:UIControlEventTouchUpInside];

    bjl_weakify(self);
    self.boardUserListView.closeListCallBack = ^() {
        bjl_strongify(self);
        if(self.boardUserListView) {
            [self.boardUserListView removeFromSuperview];
        }
        self.userListButton.hidden = NO;
    };
}

#pragma mark - action
- (void)showBoardUserList:(UIButton *)button {
    [self.boardUserListView removeFromSuperview];
    
    self.userListButton.hidden = YES;
    self.boardUserListView.hidden = NO;
    [self.popoversLayer addSubview:self.boardUserListView];
    [self.boardUserListView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.left.equalTo(self.popoversLayer);
        make.width.equalTo(@(160));
    }];
    
    if([self isValidIndexPathInUserList:self.currentIndexPath]) {
        [self.boardUserListView.tableView selectRowAtIndexPath:self.currentIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}

#pragma maek - UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(![self isValidStatusForUserListAndToolBar]) {
        return 0;
    }
    return (BJLIcWritingboradUserlistSection_count);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(![self isValidStatusForUserListAndToolBar]) {
        return 0;
    }
    switch (section) {
        case BJLIcWritingboradUserlistSection_loginUser:
            return self.hasTeacher ? 1 : 0;
            break;
        case BJLIcWritingboradUserlistSection_activeUser:
            return self.shouldOpenActiveUserList ? [self.activeParticipatedUsers count] : 0;
            break;
        case BJLIcWritingboradUserlistSection_normal:
            return self.shouldOpenNormalUserList ? [self.normalParticipatedUsers count] : 0;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcWritingBoardUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BJLIcWritingBoardUserTableViewCellIdentifier forIndexPath:indexPath];

    if(![self isValidStatusForUserListAndToolBar]) {
        return cell;
    }
    
    BJLUser *userForCell = [self getUserForIndexPath:indexPath];
    if (!userForCell) {
        return cell;
    }

    BOOL hasChecked = NO;
    BOOL hasSubmit = NO;

    if([userForCell.number isEqualToString:self.room.loginUser.number]) {
        //说明当前user是老师
        [cell updateWithUser:userForCell hasSubmit:NO hasRedDot:NO groupInfo:nil];
        return cell;
    }
    
    for(BJLUser *user in self.submitedUsers) {
        if([user.number isEqualToString:userForCell.number]) {
            hasSubmit = YES;
            break;
        }
    }
    
    for(BJLUser *user in self.checkedUsers) {
        if([user.number isEqualToString:userForCell.number]) {
            hasChecked = YES;
            break;
        }
    }

    BJLUserGroup *groupInfo = nil;
    for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
        if (group.groupID == userForCell.groupID) {
            groupInfo = [group copy];
            break;
        }
    }

    [cell updateWithUser:userForCell hasSubmit:hasSubmit hasRedDot:hasSubmit && !hasChecked groupInfo:groupInfo];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(![self isValidStatusForUserListAndToolBar] ) {
        return ;
    }
    
    BJLUser *userForCell = [self getUserForIndexPath:indexPath];
    if (!userForCell) {
        return;
    }
    
    if([userForCell.number isEqualToString:self.room.loginUser.number]) {
        //说明当前user是老师
        self.currentShowUser = self.room.loginUser;
        self.currentIndexPath = indexPath;
        self.currentLayer = BJLWritingboardUserNumberForTeacher;
        return ;
    }
    
    self.currentShowUser = userForCell;
    self.currentIndexPath = indexPath;
    self.currentLayer = userForCell.number;

    BOOL hasChecked = NO;
    for(BJLUser *user in self.mutaCheckedUsers) {
        if([user.number isEqualToString:userForCell.number]) {
            hasChecked = YES;
            break;
        }
    }
    if(!hasChecked && userForCell) {
        [self.mutaCheckedUsers addObject:userForCell];
        self.checkedUsers = self.mutaCheckedUsers;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == BJLIcWritingboradUserlistSection_loginUser) {
        return nil;
    }
    BJLIcWritingBoardUserListHeaderView *view = [BJLIcWritingBoardUserListHeaderView new];
    NSString *title = (section == BJLIcWritingboradUserlistSection_activeUser) ? [NSString stringWithFormat:@"台上成员(%td)", [self.activeParticipatedUsers count]] : [NSString stringWithFormat:@"台下成员(%td)", [self.normalParticipatedUsers count]];
    view.groupNameLabel.text = title;
    view.openButton.selected = (section == BJLIcWritingboradUserlistSection_activeUser) ? self.shouldOpenActiveUserList : self.shouldOpenNormalUserList;
    bjl_weakify(self);
    [view setTapCallback:^(BOOL show) {
        bjl_strongify(self);
        if (section == BJLIcWritingboradUserlistSection_activeUser) {
            self.shouldOpenActiveUserList = show;
        }
        else {
            self.shouldOpenNormalUserList = show;
        }
        [self.boardUserListView.tableView reloadData];
    }];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == BJLIcWritingboradUserlistSection_loginUser) {
        return 0;
    }

    return 32.0;
}

#pragma mark - load more user

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    
    if (scrollView != self.boardUserListView.tableView) {
        return;
    }
    
    if ([self atTheBottomOfTableView]
        && !self.boardUserListView.hidden && self.room.documentVM.hasMoreWritingBoardUsers) {
        
        NSMutableArray <NSString *> *activeUsersNumberArray = [NSMutableArray array];
        for (BJLUser *user in self.room.playingVM.playingUsers) {
            if (user && user.number.length && ![user.ID isEqualToString:self.room.loginUser.ID]) {
                [activeUsersNumberArray bjl_addObject:user.number];
            }
        }
        [self.room.documentVM pullWritingBoard:self.writingBoard.boardID
                               withActiveUsers:activeUsersNumberArray
                                         count:20];
    }
}

- (BOOL)atTheBottomOfTableView {
    UITableView *tableView = self.boardUserListView.tableView;

    CGFloat contentOffsetY = tableView.contentOffset.y;
    CGFloat bottom = tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(tableView.frame);
    CGFloat contentHeight = tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    return bottomOffset >= 0.0 - 30;
}

@end

//
//  BJLScGroupUserViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/11/11.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScGroupUserViewController.h"
#import "BJLUserGroupView.h"
#import "BJLScUserCell.h"
#import "BJLScAppearance.h"

typedef NS_ENUM(NSInteger, BJLUserListSection) {
    BJLUserListSection_group0,
    BJLUserListSection_groupcount,
    BJLUserListSection_defaultCount
};

static NSString * const cellReuseIdentifier = @"groupUserCellReuseIdentifier";

@interface BJLScGroupUserViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic, readonly) BOOL enableGroupUser;

// 大班未分组的用户信息
@property (nonatomic) NSMutableArray <BJLMediaUser *> *classUser;
// 小组用户信息
@property (nonatomic) NSDictionary <NSNumber *, NSArray<BJLMediaUser *> *> *groupUserDic;

//教室内小组信息
@property (nonatomic) NSArray <BJLUserGroup *> *groupList;
@property (nonatomic) NSMutableDictionary *groupCountDic;

@property (nonatomic) NSInteger currentShowGroupID;

@end

@implementation BJLScGroupUserViewController

#pragma mark - lifecycle & <BJLRoomChildViewController>

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self->_room = room;
        self.groupCountDic = [NSMutableDictionary dictionary];
        self.currentShowGroupID = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
           self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif
    [self updateGroupUserInfo];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO;
    self.tableView.rowHeight = 52.0;
    [self.tableView registerClass:[BJLScUserCell class] forCellReuseIdentifier:cellReuseIdentifier];

    [self makeObserving];
}

#pragma mark - private

- (void)makeObserving {
    bjl_weakify(self);

    // 监听在线用户变化
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsers)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
            [self updateGroupUserInfo];

            if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                return YES;
            }

             [self.tableView reloadData];
             return YES;
         }];
    
    // 监听分组更新
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, groupList)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateGroupUserInfo];
            if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                return YES;
            }

             [self.tableView reloadData];
             return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserGroupCountDidChange:)
             observer:^BOOL(NSDictionary *groupCountDic) {
        bjl_strongify(self);
        [groupCountDic enumerateKeysAndObjectsUsingBlock:^(NSString *groupID, NSNumber *count, BOOL * _Nonnull stop) {
            bjl_strongify(self);
            [self.groupCountDic bjl_setObject:count forKey:groupID];
        }];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self.tableView reloadData];
        return YES;
    }];
}

// 更新大班的数据：包括老师，助教，无分组的学生
- (void)updateGroupUserInfo {
    __block NSInteger totalCount = 0;
    NSMutableArray<BJLMediaUser *> *classUserArray = [NSMutableArray array];
    NSMutableDictionary <NSNumber *, NSArray<BJLMediaUser *> *> *groupUserDic = [NSMutableDictionary dictionary];
    for (BJLMediaUser *user in self.room.onlineUsersVM.onlineUsers) {
        if (user.noGroup) {
            [classUserArray addObject:user];
        }
        else {
            NSMutableArray *groupArray = [[groupUserDic bjl_objectForKey:@(user.groupID)] mutableCopy];
            if (!groupArray) {
                groupArray = [NSMutableArray array];
            }
            [groupArray addObject:user];
            [groupUserDic bjl_setObject:[groupArray copy] forKey:@(user.groupID)];
        }
    }
    self.groupUserDic = [groupUserDic copy];
    self.classUser = classUserArray;
    totalCount += [self.classUser count];
    
    BOOL isGroupUser = !self.room.loginUser.noGroup;
    BOOL enableGroupUser = self.enableGroupUser;
    if (isGroupUser && !enableGroupUser) {
        NSArray *groupUsers = [self.groupUserDic bjl_objectForKey:@(self.room.loginUser.groupID)];
        totalCount += [groupUsers count];
    }
    else {
        [self.groupUserDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSArray<BJLMediaUser *> * _Nonnull obj, BOOL * _Nonnull stop) {
            totalCount += [obj count];
        }];
    }
    
    if (self.userCountChangeCallback) {
        self.userCountChangeCallback(totalCount);
    }

    NSMutableArray <BJLUserGroup *> *groupList = [NSMutableArray array];
    for(BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
        if (group.groupID == 0) {
            continue;
        }
        [groupList addObject:group];
    }
    self.groupList = [groupList copy];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL isGroupUser = !self.room.loginUser.noGroup;
    BOOL enableGroupUser = self.enableGroupUser;
    
    NSInteger num = BJLUserListSection_defaultCount + (isGroupUser && !enableGroupUser)
    + [self shouldShowAllGroupList] * [self.groupList count];
    return num;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL isGroupUser = !self.room.loginUser.noGroup;
    BOOL enableGroupUser = self.enableGroupUser;

    if (section == BJLUserListSection_group0)
        return [self.classUser count];
    if (section == BJLUserListSection_groupcount)
        return 0;
    
    // 小组用户 & 不允许显示全员
    if (isGroupUser && !enableGroupUser) {
        NSArray *groupUsers = [self.groupUserDic bjl_objectForKey:@(self.room.loginUser.groupID)];
        return [groupUsers count];
    }
    else {
        BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section-2];
        NSArray *groupUsers = [self.groupUserDic bjl_objectForKey:@(group.groupID)];
        return [groupUsers count] * (self.currentShowGroupID == group.groupID);
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isGroupUser = !self.room.loginUser.noGroup;
    BOOL enableGroupUser = self.enableGroupUser;
    BOOL isSubCell = NO;
    
    __kindof BJLUser *user = nil;
    if (indexPath.section == BJLUserListSection_group0) {
        user = [self.classUser bjl_objectAtIndex:indexPath.row];
    }
    else if (indexPath.section > BJLUserListSection_groupcount ){
        if (isGroupUser && !enableGroupUser) {
            NSArray *groupUsers = [self.groupUserDic bjl_objectForKey:@(self.room.loginUser.groupID)];
            user = [groupUsers bjl_objectAtIndex:indexPath.row];
        }
        else {
            isSubCell = YES;
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:indexPath.section-2];
            NSArray *groupUsers = [self.groupUserDic bjl_objectForKey:@(group.groupID)];
            user = [groupUsers bjl_objectAtIndex:indexPath.row];
        }
    }
    
    BJLScUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell updateWithUser:user isSubCell:isSubCell];

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    BOOL isGroupUser = !self.room.loginUser.noGroup;
    BOOL enableGroupUser = self.enableGroupUser;
    BJLUserGroupView *groupView = [BJLUserGroupView new];
    BJLUserGroup *group = nil;

    if (section == BJLUserListSection_group0) {
        return [UIView new];
    }
    
    if (section == BJLUserListSection_groupcount) {
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        UILabel *label = [UILabel new];
        label.text = [NSString stringWithFormat:@"分组(%@)", @(self.groupList.count)];
        label.textColor = [UIColor bjl_colorWithHex:0X4A4A4A];
        label.font = [UIFont systemFontOfSize:18];
        label.textAlignment = NSTextAlignmentLeft;
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.top.bottom.equalTo(view);
            make.left.equalTo(view).offset(15);
        }];
        
        return ([self shouldShowAllGroupList] && !![self.groupList count]) ? view : [UIView new];
    }
    
    // 小组用户 & 不允许显示全员时，不显示当前分组名称
    if (isGroupUser && !enableGroupUser) {
        return [UIView new];
    }
    else {
        group = [self.groupList bjl_objectAtIndex:section-2];
    }
    NSArray *groupUsers = [self.groupUserDic bjl_objectForKey:@(group.groupID)];

    NSInteger count = MAX([groupUsers count], [self.groupCountDic bjl_integerForKey:@(group.groupID).stringValue]);

    [groupView updateWithGroup:group
              groupColorString:[self.room.onlineUsersVM getGroupColorWithID:group.groupID]
                      selected:(self.currentShowGroupID == group.groupID)
              isLoginUserGroup:(self.room.loginUser.groupID == group.groupID)
                         count:count];

    bjl_weakify(self);
    [groupView setTagCallback:^(BOOL show) {
        bjl_strongify(self);
        self.currentShowGroupID = show ? group.groupID : -1;
        if (show) {
            [self.room.onlineUsersVM loadMoreOnlineUsersWithCount:20 groupID:group.groupID];
        }
        [self.tableView reloadData];
    }];
    return groupView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    BOOL isGroupUser = !self.room.loginUser.noGroup;
    BOOL enableGroupUser = self.enableGroupUser;

    if (section == BJLUserListSection_group0)
        return 0;
    if (section == BJLUserListSection_groupcount) {
        return ([self shouldShowAllGroupList] && !![self.groupList count]) ? 50 : 0;
    }
    return (isGroupUser && !enableGroupUser) ? 0 : 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isGroupUser = !self.room.loginUser.noGroup;
    BOOL enableGroupUser = self.enableGroupUser;

    __kindof BJLUser *user = nil;
    if (indexPath.section == BJLUserListSection_group0) {
        user = [self.classUser bjl_objectAtIndex:indexPath.row];
    }
    else if (indexPath.section > BJLUserListSection_groupcount ){
        if (isGroupUser && !enableGroupUser) {
            NSArray *groupUsers = [self.groupUserDic bjl_objectForKey:@(self.room.loginUser.groupID)];
            user = [groupUsers bjl_objectAtIndex:indexPath.row];
        }
        else {
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:indexPath.section-2];
            NSArray *groupUsers = [self.groupUserDic bjl_objectForKey:@(group.groupID)];
            user = [groupUsers bjl_objectAtIndex:indexPath.row];
        }
    }
    
    BJLScUserCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CGPoint point = [self.view convertPoint:cell.avatarImageView.center fromView:cell.avatarImageView.superview];

    if (self.userSelectCallback) {
        self.userSelectCallback(user, point);
    }
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    NSInteger groupID = self.currentShowGroupID >= 0 ?: self.room.loginUser.groupID;
    if ([self.room.onlineUsersVM hasMoreOnlineUsersofGroup:groupID]
        && [self atTheBottomOfTableView]) {
        [self.room.onlineUsersVM loadMoreOnlineUsersWithCount:20 groupID:groupID];
    }
}

- (BOOL)atTheBottomOfTableView {
    CGFloat contentOffsetY = self.tableView.contentOffset.y;
    CGFloat bottom = self.tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(self.tableView.frame);
    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    return bottomOffset >= 0.0 - BJLViewSpaceS;
}

/**
 *  对于大班学生和小组成员，是否允许组间相互可见
 *  新版分组直播/新版线上双师 && 分组成员可互见
 */
- (BOOL)enableGroupUser {
    return self.room.roomInfo.enableGroupUser;
}

/**
    对于大班老师助教，默认是可以查看全员，
    但是enableGroupInNewSmallRoom配置为不分组时，不要展示所有分组的信息，
    因为此时理论上大班课的所有用户的group都为0
 */
- (BOOL)enableGroupUserofTeacherORAsisstant {
    if (self.room.roomInfo.newRoomGroupType == BJLRoomNewGroupType_onlinedoubleTeachers
        && !self.room.roomInfo.enableGroupInNewSmallRoom
        && self.room.loginUser.noGroup
        && self.room.loginUser.isTeacherOrAssistant) {
        return NO;
    }
    return YES;
}

/** 是否应该展示所有分组名字
 * 1， 小组成员 && 允许组间相互可见
 * 2， 大班老师助教 && enableGroupUserofTeacherORAsisstant
 * 3， 大班成员 && 允许组间相互可见
 */
- (BOOL)shouldShowAllGroupList {
    BOOL isGroupUser = !self.room.loginUser.noGroup;
    BOOL enableGroupUser = self.enableGroupUser;
    BOOL isStudent = self.room.loginUser.isStudent;

    return ((isGroupUser && enableGroupUser)
            || (!isGroupUser && !isStudent && [self enableGroupUserofTeacherORAsisstant])
            || (!isGroupUser && isStudent && enableGroupUser));
}


@end

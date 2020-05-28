//
//  BJLPrivateChatUsersView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/1/2.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLPrivateChatUsersView.h"

#import "BJLUserCell.h"
#import "BJLUserGroupView.h"

typedef NS_ENUM(NSInteger, BJLPrivateUserSection) {
    BJLPrivateUserSection_group0,
    BJLPrivateUserSection_groupcount,
    BJLPrivateUserSection_defaultCount
};

@interface BJLPrivateChatUsersView ()

@property (nonatomic, strong) NSArray<BJLUser *> *userList;
@property (nonatomic, strong) BJLRoom *room;
@property (nonatomic, readonly) BOOL enableGroupUser;

@property (nonatomic, strong) BJLUser *targetUser;
@property (nonatomic, assign) BJLChatStatus chatStatus;

@property (nonatomic, strong) UIView *chatStatusView;
@property (nonatomic, strong) UIButton *emptyListView;
@property (nonatomic, strong) UILabel *chatStatusLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refresh;

@end

@implementation BJLPrivateChatUsersView

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self) {
        self = [super initWithFrame:bjl_set((CGRect)CGRectZero, {
            set.size = [self intrinsicContentSize];
        })];
        self.room = room;
        self.frame = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, 266.0);
        self.backgroundColor = [UIColor bjl_lightGrayBackgroundColor];
        [self setUpSubView];
        [self setUpObservers];
    }
    return self;
}

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

#pragma mark - subViews

- (void)setUpSubView {
    CGFloat margin = 15.0;
    
    // chatStatusView
    [self addSubview:self.chatStatusView];
    [self.chatStatusView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.left.right.equalTo(self.bjl_safeAreaLayoutGuide ?: self);
        make.height.equalTo(@(0.0)); // will update
    }];
    
    // cancelChatButton
    UIButton *cancelChatButton = ({
        UIButton *button = [[UIButton alloc] init];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"取消私聊" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(cancelPrivateChat) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.chatStatusView addSubview:cancelChatButton];
    [cancelChatButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.chatStatusView).offset(-margin);
        make.centerY.equalTo(self.chatStatusView);
    }];
    
    // chatStatusLabel
    [self.chatStatusView addSubview:self.chatStatusLabel];
    [self.chatStatusLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.chatStatusView).offset(margin);
        make.centerY.equalTo(self.chatStatusView);
        make.right.lessThanOrEqualTo(cancelChatButton.bjl_left).offset(-margin);
    }];
    
    // tableView
    [self addSubview:self.tableView];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.chatStatusView.bjl_bottom);
        make.left.bottom.right.equalTo(self.bjl_safeAreaLayoutGuide ?: self);
    }];
    
    // 添加refreshControl
    [self.tableView insertSubview:self.refresh atIndex:0];
    
    // 列表为空时的视图
    [self addSubview:self.emptyListView];
    [self.emptyListView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self);
    }];
}

- (void)setUpObservers {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self loadUserListData];
             return YES;
         }];
}

#pragma mark - load data

- (void)refreshDataWithRefreshControl:(UIRefreshControl *)refreshControl {
    [self.refresh endRefreshing];
    [self loadUserListData];
}

- (void)loadUserListData {
    [self updateGroupUserInfo];
    [self.tableView reloadData];
}

/**
 大班课老师/助教，可以与【任何人】相互发私聊消息
 配置为仅组内可见，则组内助教可以向【组内在线用户】相互发私聊消息
 配置为仅组间可见，则组内助教可以向【任意在线用户】相互发私聊消息
 */
- (void)updateGroupUserInfo {
    NSMutableArray *mutableUserList = [NSMutableArray array];
    
    for (BJLMediaUser *user in self.room.onlineUsersVM.onlineUsers) {
        if ([user.ID isEqualToString:self.room.loginUser.ID] || !([self.room.chatVM canSendPrivateMessageFromeUser:self.room.loginUser toUser:user] || [self.room.chatVM canSendPrivateMessageFromeUser:user toUser:self.room.loginUser])) {
            continue;
        }
        [mutableUserList addObject:user];
    }
    self.userList = [NSArray arrayWithArray:mutableUserList];
    self.emptyListView.hidden = (self.userList.count > 0);
}

#pragma mark - chatStatus

- (void)startPrivateChatWithTargetUser:(BJLUser *)user {
    [self updateChatStatus:BJLChatStatus_private withTargetUser:user];
    if (self.startPrivateChatCallback) {
        self.startPrivateChatCallback(user);
    }
}

- (void)cancelPrivateChat {
    [self updateChatStatus:BJLChatStatus_default withTargetUser:nil];
    if (self.cancelPrivateChatCallback) {
        self.cancelPrivateChatCallback();
    }
}

- (void)updateChatStatus:(BJLChatStatus)chatStatus withTargetUser:(nullable BJLUser *)targetUser {
    self.chatStatus = chatStatus;
    self.targetUser = (chatStatus == BJLChatStatus_private)? targetUser : nil;
    
    // update content
    if (chatStatus == BJLChatStatus_private) {
        // show view
        [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
            make.height.equalTo(@36.0);
        }];
        
        // text
        self.chatStatusLabel.text = [NSString stringWithFormat:@"正在和 %@ 私聊中...", self.targetUser.displayName];
    }
    else {
        // reset
        [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
            make.height.equalTo(@0.0);
        }];
    }
    [self.tableView reloadData];
}

#pragma mark - <UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLFeatureConfig *config = self.room.featureConfig;
    BJLUser *user = [self.userList bjl_objectAtIndex:indexPath.row];
    NSString *cellIdentifier = [BJLUserCell cellIdentifierForUserState:BJLUserState_online
                                                  isTeacherOrAssistant:self.room.loginUser.isTeacherOrAssistant
                                                           isPresenter:NO // need not
                                                              userRole:user.role
                                                              hasVideo:NO
                                                          videoPlaying:NO];
    BJLUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = ([self.targetUser.ID isEqualToString:user.ID])? [UIColor whiteColor] : [UIColor clearColor];
    [cell updateWithUser:user
                roleName:(user.isTeacher ? config.teacherLabel
                                        : user.isAssistant ? config.assistantLabel
                                        : nil)
               isSubCell:NO];
    return cell;
}
#pragma mark - <UITableViewDelegate>
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLUser *user = [self.userList bjl_objectAtIndex:indexPath.row];
    [self startPrivateChatWithTargetUser:user];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    if ([self.room.onlineUsersVM hasMoreOnlineUsers]
        && [self atTheBottomOfTableView]) {
        [self.room.onlineUsersVM loadMoreOnlineUsersWithCount:20];
    }
}

- (BOOL)atTheBottomOfTableView {
    CGFloat contentOffsetY = self.tableView.contentOffset.y;
    CGFloat bottom = self.tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(self.tableView.frame);
    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    CGFloat margin = 5.0;
    return (bottomOffset >= 0.0 - margin);
}

#pragma mark - getters

- (UIView *)chatStatusView {
    if (!_chatStatusView) {
        _chatStatusView = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor bjl_colorWithHexString:@"#2CA1F8"];
            view.clipsToBounds = YES;
            view;
        });
    }
    return _chatStatusView;
}

- (UILabel *)chatStatusLabel {
    if (!_chatStatusLabel) {
        _chatStatusLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.font = [UIFont systemFontOfSize:14.0];
            label.textColor = [UIColor whiteColor];
            label.numberOfLines = 0;
            label;
        });
    }
    return _chatStatusLabel;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = ({
            UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
            tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            tableView.backgroundColor = [UIColor clearColor];
            tableView.rowHeight = 46.0;
            if (@available(iOS 9.0, *)) {
                tableView.cellLayoutMarginsFollowReadableWidth = NO;
            }
            tableView.dataSource = self;
            tableView.delegate = self;
            for (NSString *cellIdentifier in [BJLUserCell allCellIdentifiers]) {
                [tableView registerClass:[BJLUserCell class] forCellReuseIdentifier:cellIdentifier];
            }
            tableView;
        });
    }
    return _tableView;
}

- (UIRefreshControl *)refresh {
    if (!_refresh) {
        _refresh = [[UIRefreshControl alloc] init];
        [_refresh addTarget:self
                     action:@selector(refreshDataWithRefreshControl:)
           forControlEvents:UIControlEventValueChanged];
    }
    return _refresh;
}

- (UIButton *)emptyListView {
    if (!_emptyListView) {
        _emptyListView = ({
            UIButton *button = [[UIButton alloc] init];
            button.titleLabel.font = [UIFont systemFontOfSize:14.0];
            [button setTitleColor:[UIColor bjl_grayTextColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor bjl_lightGrayTextColor] forState:UIControlStateHighlighted];
            [button setTitle:@"暂无可私聊对象，点击刷新" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(loadUserListData) forControlEvents:UIControlEventTouchUpInside];
            button.hidden = YES;
            button;
        });
    }
    return _emptyListView;
}

@end

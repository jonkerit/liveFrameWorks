//
//  BJLScUserViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScUserViewController.h"
#import "BJLScAppearance.h"
#import "BJLScUserCell.h"
#import "BJLScUserOperateView.h"

static NSString * const cellReuseIdentifier = @"userCellReuseIdentifier";

@interface BJLScUserViewController () <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) UIViewController *optionViewController;

@end

@implementation BJLScUserViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.room = room;
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
    
    [self makeSubviewsAndConstraints];
    [self makeObserving];
}

- (void)makeSubviewsAndConstraints {
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 52.0;
    [self.tableView registerClass:[BJLScUserCell class] forCellReuseIdentifier:cellReuseIdentifier];
}

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsers)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                 return YES;
             }
            if (self.userCountChangeCallback) {
                self.userCountChangeCallback([self.room.onlineUsersVM.onlineUsers count]);
            }
             [self.tableView reloadData];        
             return YES;
         }];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = self.room.onlineUsersVM.onlineUsers.count;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLScUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    BJLUser *user = [self.room.onlineUsersVM.onlineUsers bjl_objectAtIndex:indexPath.row];
    [cell updateWithUser:user isSubCell:NO];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLScUserCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    BJLUser *user = [self.room.onlineUsersVM.onlineUsers bjl_objectAtIndex:indexPath.row];
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
    if (self.room.onlineUsersVM.hasMoreOnlineUsers
        && [self atTheBottomOfTableView]) {
        [self.room.onlineUsersVM loadMoreOnlineUsersWithCount:20
                                                      groupID:self.room.loginUser.groupID];
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

@end

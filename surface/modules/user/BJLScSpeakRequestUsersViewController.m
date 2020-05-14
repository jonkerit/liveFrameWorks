//
//  BJLScSpeakRequestUsersViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScSpeakRequestUsersViewController.h"
#import "BJLScSpeakRequestUserCell.h"
#import "BJLScAppearance.h"

static NSString * const cellReuseIdentifier = @"BJLScSpeakRequestUserCellIdentifier";

@interface BJLScSpeakRequestUsersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) NSMutableArray<BJLUser *> *speakRequestUserList;

@property (nonatomic) UIView *topContainerView;
@property (nonatomic) UILabel *titleLabel;

@end

@implementation BJLScSpeakRequestUsersViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
        [self makeObservingAndActions];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self bjl_setUpCommonTableView];
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 0, 0.0, 0.0);
    self.tableView.estimatedRowHeight = 52;
    [self.tableView registerClass:[BJLScSpeakRequestUserCell class] forCellReuseIdentifier:cellReuseIdentifier];
    
    #if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
    #endif

    [self makeSubviewsAndConstraints];
    [self reloadTableViewData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self reloadTableViewData];
}

- (void)makeSubviewsAndConstraints {
    self.topContainerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, topContainerView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    UIView *separatorLine = ({
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor bjlsc_grayLineColor];
        [self.topContainerView addSubview:line];
        bjl_return line;
    });
    
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"举手列表";
        label.textColor = [UIColor blackColor];
        label.accessibilityLabel = BJLKeypath(self, titleLabel);
        [self.topContainerView addSubview:label];
        bjl_return label;
    });
    
    [self.topContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@(BJLScControlSize));
    }];

    [self.tableView bjl_removeAllConstraints];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.left.bottom.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.top.equalTo(self.topContainerView.bjl_bottom);
    }];
    
    [separatorLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.topContainerView);
        make.height.equalTo(@(BJLScOnePixel));
    }];
    
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.topContainerView.bjl_safeAreaLayoutGuide ?: self.topContainerView).with.offset(BJLScViewSpaceL);
        make.top.bottom.equalTo(self.topContainerView.bjl_safeAreaLayoutGuide ?: self.topContainerView);
    }];
}

- (void)makeObservingAndActions {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, forbidSpeakingRequest)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.tableView.hidden = self.room.speakingRequestVM.forbidSpeakingRequest;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.speakRequestUserList = [self.room.speakingRequestVM.speakingRequestUsers mutableCopy];
             if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                 return YES;
             }
             [self reloadTableViewData];
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingRequestFromUser:)
             observer:^BOOL(BJLUser *user) {
                 bjl_strongify(self);
                 if (self.receiveSpeakingRequestCallback) {
                     self.receiveSpeakingRequestCallback(self.room.speakingRequestVM.speakingRequestUsers.count);
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
                 bjl_strongify(self);
                 if (self.receiveSpeakingRequestCallback) {
                     self.receiveSpeakingRequestCallback(self.room.speakingRequestVM.speakingRequestUsers.count);
                 }
                 return YES;
             }];
}

- (void)reloadTableViewData {
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }

    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.speakRequestUserList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLScSpeakRequestUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    BJLUser *user = [self.speakRequestUserList bjl_objectAtIndex:indexPath.row];
    [cell updateWithUser:user];
    
    bjl_weakify(self);
    cell.agreeRequestCallback = cell.agreeRequestCallback ?: ^(BJLScSpeakRequestUserCell *cell, BOOL allow) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacherOrAssistant && self.room.loginUser.groupID == 0) {
            NSIndexPath *indexPath = [tableView indexPathForCell:cell];
            BJLUser *user = [self.speakRequestUserList bjl_objectAtIndex:indexPath.row];
            if (user) {
                [self.room.speakingRequestVM replySpeakingRequestToUserID:user.ID allowed:allow];
            }
        }
    };
    
    return cell;
}

@end

//
//  BJLIcUserViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/10.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcUserViewController.h"
#import "BJLIcUserTableViewCell.h"
#import "BJLIcUserGroupView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

/**
 用于自定义按钮的图片位置，可以根据设置不同的按钮状态的图片来切换
 */
@interface BJLIcUserHeaderButton : UIButton

@property (nonatomic, readonly) UIImageView *customImageView;

- (void)setCustomImage:(UIImage *)customImage forState:(UIControlState)state;

@end

@interface BJLIcUserHeaderButton ()

@property (nonatomic, readwrite) UIImageView *customImageView;
@property (nonatomic) NSMutableDictionary<NSNumber *, UIImage *> *rightImageDictionary;

@end

@implementation BJLIcUserHeaderButton

- (instancetype)init {
    if (self = [super init]) {
        [self addObserverForButtonState];
    }
    return self;
}

- (void)addObserverForButtonState {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self, state)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             UIImage *image = [self.rightImageDictionary bjl_objectForKey:@(self.state) class:[UIImage class]];
             if (image) {
                 self.customImageView.image = image;
             }
             return YES;
         }];
}

- (void)setCustomImage:(UIImage *)customImage forState:(UIControlState)state {
    [self.rightImageDictionary bjl_setObject:customImage forKey:@(state)];
    if (self.state == state) {
        self.customImageView.image = customImage;
    }
}

- (NSMutableDictionary<NSNumber *,UIImage *> *)rightImageDictionary {
    if (!_rightImageDictionary) {
        _rightImageDictionary = [NSMutableDictionary new];
    }
    return _rightImageDictionary;
}

- (UIImageView *)customImageView {
    if (!_customImageView) {
        _customImageView = [UIImageView new];
        _customImageView.backgroundColor = [UIColor clearColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_customImageView];
    }
    return _customImageView;
}

@end

/**
 用户列表包括举手列表，上台用户列表，下台用户，黑名单列表，对应四个 tableview
 在线用户列表不会显示，显示的是台上和台下，以及黑名单的用户列表，这个列表为了随时处理用户列表相关的事件而保存
 目前的设计四个列表只能同时显示一个，通过按钮的选中状态来决定显示或隐藏，不支持同时显示多个
 */
@interface BJLIcUserViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) NSMutableSet<NSString *> *autoAddActiveUserBlackList;
@property (nonatomic) NSMutableArray<BJLUser *> *speakRequestUserList;
@property (nonatomic) NSMutableArray<BJLUser *> *onlineUserList;
@property (nonatomic) NSMutableArray<BJLUser *> *onStageUserList;
@property (nonatomic) NSMutableArray<BJLUser *> *downStageUserList;
@property (nonatomic) NSMutableArray<BJLUser *> *blockedUserList;
@property (nonatomic) NSMutableDictionary<NSString *, NSNumber *> *forbidChatUsers;

// 用户列表分区未分组的用户`StageClassUser`, 和分组的用户`StageGroupUserDic`
@property (nonatomic, nullable) NSArray <BJLUser *> *onStageClassUser, *downStageClassUser;
@property (nonatomic, nullable) NSDictionary <NSNumber *, NSArray<BJLUser *> *> *onStageGroupUserDic, *downStageGroupUserDic;
//教室内小组信息(不包含0分组信息)
@property (nonatomic, nullable) NSArray <BJLUserGroup *> *groupList;
@property (nonatomic) NSInteger onStageSelectedGroupID, downStageSelectedGroupID;

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) UIView *forbidSpeakRequestBackgroundView;
@property (nonatomic) UITableView *speakRequestTableView;
@property (nonatomic) UIButton *forbidSpeakRequestButton;
@property (nonatomic) UIButton *freeAllBlockedUserButton;
@property (nonatomic) BJLIcUserHeaderButton *onStageUserButton;
@property (nonatomic) UITableView *onStageTableView;
@property (nonatomic) BJLIcUserHeaderButton *downStageUserButton;
@property (nonatomic) UITableView *downStageTableView;
@property (nonatomic) BJLIcUserHeaderButton *blockedUserButton;
@property (nonatomic) UITableView *blockedTableView;

@end

@implementation BJLIcUserViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.autoAddActiveUserBlackList = [NSMutableSet new];
        self.speakRequestUserList = [NSMutableArray new];
        self.onlineUserList = [NSMutableArray new];
        self.onStageUserList = [NSMutableArray new];
        self.downStageUserList = [NSMutableArray new];
        self.blockedUserList = [NSMutableArray new];
        self.forbidChatUsers = [NSMutableDictionary new];
        self.onStageClassUser = [NSMutableArray new];
        self.downStageClassUser = [NSMutableArray new];
        self.onStageGroupUserDic = [NSMutableDictionary new];
        self.downStageGroupUserDic = [NSMutableDictionary new];
        self.onStageSelectedGroupID = 0;
        self.downStageSelectedGroupID = 0;
        [self makeObserving];
    }
    return self;
}

- (void)dealloc {
    self.speakRequestTableView.delegate = nil;
    self.speakRequestTableView.dataSource = nil;
    self.onStageTableView.delegate = nil;
    self.onStageTableView.dataSource = nil;
    self.downStageTableView.delegate = nil;
    self.downStageTableView.dataSource = nil;
    self.blockedTableView.delegate = nil;
    self.blockedTableView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviewsAndConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.backgroundView bjlic_drawRectCorners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(5.0, 5.0)];
    [self.backgroundView bjlic_drawBorderWidth:1.0 borderColor:[UIColor colorWithWhite:1.0 alpha:0.05] corners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(5.0, 5.0)];
    [self reloadAllTableViewData];
    [self updateUserListTitle];
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor clearColor];
    // shadow
    self.view.layer.masksToBounds = NO;
    self.view.layer.shadowOpacity = 0.2;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    self.view.layer.shadowRadius = 10.0;
    // 毛玻璃效果
    self.backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view.layer.masksToBounds = YES;
        view;
    });
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    // title
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"学员列表";
        label.accessibilityLabel = BJLKeypath(self, titleLabel);
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.view addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].userViewLargeSpace);
        make.top.equalTo(self.view);
        make.height.greaterThanOrEqualTo(@16.0);
        make.height.equalTo(@32.0).priorityHigh();
    }];
    // close
    UIButton *closeButton = ({
        UIButton *button = [BJLImageButton new];
        button.accessibilityLabel = @"closeButton";
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_popover_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:closeButton];
    [closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.top.equalTo(self.view);
        make.height.equalTo(self.titleLabel);
        make.width.equalTo(closeButton.bjl_height);
    }];
    // shadow line
    UIView *firstSingleLine = [self createShadowSingleLine];
    [self.view addSubview:firstSingleLine];
    // 因为设置了不裁切, 所以左右在设置约束的时候减少 1.0, 使得显示时不会到达边界
    [firstSingleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view).offset(1.0);
        make.right.equalTo(self.view).offset(-1.0);
        make.top.equalTo(self.titleLabel.bjl_bottom);
        make.height.equalTo(@(1.0));
    }];
    // shadow line
    UIView *secondSingleLine = [self createShadowSingleLine];
    [self.view addSubview:secondSingleLine];
    // 因为设置了不裁切, 所以左右在设置约束的时候减少 1.0, 使得显示时不会到达边界
    [secondSingleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view).offset(1.0);
        make.right.equalTo(self.view).offset(-1.0);
        make.top.equalTo(firstSingleLine.bjl_bottom).offset(48.0);
        make.height.equalTo(@(1.0));
    }];
    // segmented control
    self.segmentedControl = ({
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"举手", @"用户"]];
        segmentedControl.accessibilityLabel = BJLKeypath(self, segmentedControl);
        segmentedControl.layer.masksToBounds = YES;
        segmentedControl.backgroundColor = [UIColor clearColor];
        segmentedControl.tintColor = [UIColor whiteColor];
        segmentedControl.selectedSegmentIndex = 0;
        [segmentedControl addTarget:self action:@selector(segmentValueChanged:) forControlEvents:UIControlEventValueChanged];
        segmentedControl;
    });
    [self.view addSubview:self.segmentedControl];
    [self.segmentedControl bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.view).inset([BJLIcAppearance sharedAppearance].userViewLargeSpace);
        make.top.equalTo(firstSingleLine.bjl_bottom).offset([BJLIcAppearance sharedAppearance].userViewSmallSpace);
        make.bottom.equalTo(secondSingleLine.bjl_top).offset(-[BJLIcAppearance sharedAppearance].userViewSmallSpace);
    }];
    // handUp table view
    self.speakRequestTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.accessibilityLabel = BJLKeypath(self, speakRequestTableView);
        tableView.rowHeight = [BJLIcAppearance sharedAppearance].userTableViewCellHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcUserTableViewCell class] forCellReuseIdentifier:BJLIcSpeakRequestUserTableViewCellReuseIdentifier];
        tableView;
    });
    [self.view addSubview:self.speakRequestTableView];
    [self.speakRequestTableView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(secondSingleLine.bjl_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
    // forbid SpeakRequest Button
    self.forbidSpeakRequestButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, forbidSpeakRequestButton);
        button.alpha = 0.8;
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 16.0;
        button.backgroundColor = [UIColor whiteColor];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_userlist_forbidspeakrequest"] forState:UIControlStateNormal];
        [button setTitle:@"禁止举手" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_userlist_allowspeakrequest"] forState:UIControlStateSelected];
        [button setTitle:@"允许举手" forState:UIControlStateSelected];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(updateSpeakingRequestEnable) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.forbidSpeakRequestButton];
    [self.forbidSpeakRequestButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-[BJLIcAppearance sharedAppearance].userViewSmallSpace);
        make.width.equalTo(@106.0);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userCellButtonSize));
    }];
    // forbid SpeakRequest Background View
    self.forbidSpeakRequestBackgroundView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, forbidSpeakRequestBackgroundView);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.forbidSpeakRequestBackgroundView];
    [self.forbidSpeakRequestBackgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.greaterThanOrEqualTo(secondSingleLine);
        make.centerY.equalTo(self.view).priorityHigh();
        make.left.right.equalTo(self.view);
        make.bottom.lessThanOrEqualTo(self.forbidSpeakRequestButton);
    }];
    UIImageView *forbidSpeakRequestImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = @"forbidSpeakRequestImageView";
        imageView.backgroundColor = [UIColor clearColor];
        imageView.image = [UIImage bjlic_imageNamed:@"bjl_userlist_forbidspeakrequest_bg"];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.forbidSpeakRequestBackgroundView addSubview:forbidSpeakRequestImageView];
    [forbidSpeakRequestImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.top.equalTo(self.forbidSpeakRequestBackgroundView);
        make.width.equalTo(self.forbidSpeakRequestBackgroundView).multipliedBy(0.5);
        make.height.equalTo(forbidSpeakRequestImageView.bjl_width);
    }];
    UILabel *forbidSpeakRequestTipLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = @"forbidSpeakRequestTipLabel";
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label.text = @"已设置用户禁止举手";
        label;
    });
    [self.forbidSpeakRequestBackgroundView addSubview:forbidSpeakRequestTipLabel];
    [forbidSpeakRequestTipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(forbidSpeakRequestImageView.bjl_bottom).offset(4.0);
        make.bottom.left.right.equalTo(self.forbidSpeakRequestBackgroundView);
        make.height.equalTo(@20.0);
    }];
    // onStage User Button
    self.onStageUserButton = ({
        BJLIcUserHeaderButton *button = [self createUserOptionButton];
        button.accessibilityLabel = BJLKeypath(self, onStageUserButton);
        [button setTitle:@"台上用户" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showOnStageList) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.onStageUserButton];
    [self.onStageUserButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(secondSingleLine.bjl_top);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userOptionViewHeight));
    }];
    // onStage table view
    self.onStageTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.accessibilityLabel = BJLKeypath(self, onStageTableView);
        tableView.rowHeight = [BJLIcAppearance sharedAppearance].userTableViewCellHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcUserTableViewCell class] forCellReuseIdentifier:BJLIcOnStageTableViewCellReuseIdentifier];
        tableView;
    });
    [self.view addSubview:self.onStageTableView];
    [self.onStageTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.onStageUserButton.bjl_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.lessThanOrEqualTo(self.view.bjl_bottom).offset(-[BJLIcAppearance sharedAppearance].userOptionViewHeight * 2);
    }];
    // downStage User Button
    self.downStageUserButton = ({
        BJLIcUserHeaderButton *button = [self createUserOptionButton];
        button.accessibilityLabel = BJLKeypath(self, downStageUserButton);
        [button setTitle:@"台下用户" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showDownStageList) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.downStageUserButton];
    [self.downStageUserButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.onStageTableView.bjl_bottom);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userOptionViewHeight));
    }];
    // downStage table view
    self.downStageTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.accessibilityLabel = BJLKeypath(self, downStageTableView);
        tableView.rowHeight = [BJLIcAppearance sharedAppearance].userTableViewCellHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcUserTableViewCell class] forCellReuseIdentifier:BJLIcDownStageTableViewCellReuseIdentifier];
        tableView;
    });
    [self.view addSubview:self.downStageTableView];
    [self.downStageTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.downStageUserButton.bjl_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.lessThanOrEqualTo(self.view.bjl_bottom).offset(-[BJLIcAppearance sharedAppearance].userOptionViewHeight);;
    }];
    // blocked user button
    self.blockedUserButton = ({
        BJLIcUserHeaderButton *button = [self createUserOptionButton];
        button.accessibilityLabel = BJLKeypath(self, blockedUserButton);
        [button setTitle:@"黑名单" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showBlockedList) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.blockedUserButton];
    [self.blockedUserButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.downStageTableView.bjl_bottom);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userOptionViewHeight));
    }];
    // blocked table view
    self.blockedTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.accessibilityLabel = BJLKeypath(self, blockedTableView);
        tableView.rowHeight = [BJLIcAppearance sharedAppearance].userTableViewCellHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcUserTableViewCell class] forCellReuseIdentifier:BJLIcBlockedUserTableViewCellReuseIdentifier];
        tableView;
    });
    [self.view addSubview:self.blockedTableView];
    [self.blockedTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.blockedUserButton.bjl_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.lessThanOrEqualTo(self.view.bjl_bottom);
    }];
    self.freeAllBlockedUserButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, freeAllBlockedUserButton);
        button.alpha = 0.8;
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 16.0;
        button.backgroundColor = [UIColor whiteColor];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"全部解禁" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(freeAllBlockedUser) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.freeAllBlockedUserButton];
    [self.freeAllBlockedUserButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.forbidSpeakRequestButton);
    }];
    
    // fire
    [self switchToSpeakRequestView];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, state)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.state == BJLRoomState_connected) {
            [self.room.onlineUsersVM loadBlockedUserList];
        }
        return YES;
    }];
    
    /* 举手 */
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, forbidSpeakingRequest)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.forbidSpeakRequestButton.selected = self.room.speakingRequestVM.forbidSpeakingRequest;
             self.forbidSpeakRequestBackgroundView.hidden = self.forbidSpeakRequestButton.hidden || !self.room.speakingRequestVM.forbidSpeakingRequest;
             self.speakRequestTableView.hidden = self.room.speakingRequestVM.forbidSpeakingRequest;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.speakRequestUserList = [self.room.speakingRequestVM.speakingRequestUsers mutableCopy];
             if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                 return YES;
             }
             [self reloadAllTableViewData];
             [self updateUserListTitle];
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingRequestFromUser:)
             observer:^BOOL(BJLUser *user) {
                 bjl_strongify(self);
                 if (self.receiveSpeakingRequestCallback) {
                     self.receiveSpeakingRequestCallback(user, NO, self.room.speakingRequestVM.speakingRequestUsers.count);
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
                 bjl_strongify(self);
                 if (self.receiveSpeakingRequestCallback) {
                     self.receiveSpeakingRequestCallback(user, YES, self.room.speakingRequestVM.speakingRequestUsers.count);
                 }
                 return YES;
             }];
    
    /* 在线用户 */
    
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.onlineUserList = [self.room.onlineUsersVM.onlineUsers mutableCopy];
             [self updateOnStageUserList];
             [self updateDownStageUserList];
             if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                 return YES;
             }
             [self reloadAllTableViewData];
             [self updateUserListTitle];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsersTotalCount)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                 return YES;
             }
             [self updateUserListTitle];
             return YES;
         }];
    
    /* 黑名单 */
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didReceiveBlockedUserList:)
             observer:^BOOL(NSArray<BJLUser *> *userList) {
        bjl_strongify(self);
        [self.blockedUserList removeAllObjects];
        self.blockedUserList = [userList mutableCopy];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didBlockUser:)
             observer:^BOOL(BJLUser *blockedUser) {
        bjl_strongify(self);
        [self updateUserListWithRemovedUser:blockedUser];
        [self.blockedUserList bjl_addObject:blockedUser];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didFreeBlockedUserWithNumber:)
             observer:^BOOL(NSString *userNumber) {
        bjl_strongify(self);
        for (BJLUser *user in [self.blockedUserList copy]) {
            if ([user.number isEqualToString:userNumber]) {
                [self.blockedUserList bjl_removeObject:user];
            }
        }
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didFreeAllBlockedUsers)
             observer:^BOOL {
        bjl_strongify(self);
        [self.blockedUserList removeAllObjects];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        [self reloadAllTableViewData];
        [self updateUserListTitle];
        return YES;
    }];
    
    /* 上下台 */
    
    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
           filter:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return !!now;
           }
         observer:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self makeObservingAfterLoginUserAvailable];
             return NO;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.playingVM, playingUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.onStageUserList = [self.room.playingVM.playingUsers mutableCopy];
             [self updateOnStageUserList];
             [self updateDownStageUserList];
             if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                 return YES;
             }
             [self reloadAllTableViewData];
             [self updateUserListTitle];
             return YES;
         }];

    /* 禁言 */
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didReceiveForbidUser:fromUser:duration:)
             observer:(BJLMethodObserver)^BOOL(BJLUser *user, BJLUser *fromUser, NSTimeInterval duration) {
                 bjl_strongify(self);
                 // !!!:不进行禁言时间的倒计时，只要禁言就认为一直禁言，除非被解除
                 BOOL forbid = duration > 0;
                 [self.forbidChatUsers bjl_setObject:@(forbid) forKey:user.number];
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self reloadAllTableViewData];
                 return BJLKeepObserving;
             }];
    
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didReceiveForbidUserList:) observer:^BOOL(NSDictionary <NSString *, NSNumber *> * _Nullable forbidUserList) {
        bjl_strongify(self);
        [self.forbidChatUsers removeAllObjects];
        if (!forbidUserList || ![forbidUserList.allKeys count]) {
            return YES;
        }
        
        [forbidUserList enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            NSInteger duration = obj.integerValue;
            BOOL forbid = duration > 0;
            [self.forbidChatUsers bjl_setObject:@(forbid) forKey:key];
        }];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];

    /* 用户分组信息 */
    
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, groupList) observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateGroupList];
        [self updateOnStageUserList];
        [self updateDownStageUserList];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return YES;
        }
        
        [self reloadAllTableViewData];
        return BJLKeepObserving;
    }];
}

- (void)makeObservingAfterLoginUserAvailable {
    bjl_weakify(self);
    
    if (self.room.loginUser.isTeacher) {
        // 自动上台，老师和助教在服务端会自动上台，但是老师也需要发上台信令通知在老师前进教室的用户
        [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserWillAdd:)
                 observer:^BOOL(BJLUser * user) {
                     bjl_strongify(self);
                     // 老师上台需要信令通知其他用户
                     if (user.isTeacher) {
                         [self.room.playingVM requestAddActiveUser:user];
                         return YES;
                     }
                     // 如果是1 V N V M 的教室，不自动上台
                     if ( self.room.featureConfig.maxBackupUserCount > 0) {
                         return YES;
                     }
                     
                     NSInteger count = self.room.featureConfig.maxActiveUserCount;
                     if (self.room.onlineUsersVM.onlineTeacher) {
                         // 老师在线的时候，最大上麦数要除去老师
                         count++;
                     }
                     
                     // 超出上台人数限制
                     if (self.room.playingVM.playingUsers.count >= count) {
                         return YES;
                     }
                     
                     if (user.isAssistant) {
                         // 助教不自动上台
                         return YES;
                     }
                     
                     // 查找用户是否已经在台上了
                     BOOL isActive = NO;
                     for (BJLUser *playingUser in [self.room.playingVM.playingUsers copy]) {
                         if ([playingUser.ID isEqualToString:user.ID]) {
                             isActive = YES;
                             break;
                         }
                     }
                     
                     // 用户在台上，或者在自动上台的黑名单内，不自动上台，这里是基于仅老师控制自动上下台来处理的
                     if (isActive || [self.autoAddActiveUserBlackList containsObject:user.ID]) {
                         return YES;
                     }
                     
                     // 请求上台
                     if (user.onlineState == BJLOnlineState_visible) {
                         [self.room.playingVM requestAddActiveUser:user];
                     }
                     return YES;
                 }];
    }
    else if (self.room.loginUser.isAssistant) {
        // 助教在进入房间后将自己从台上用户移出
        [self bjl_kvo:BJLMakeProperty(self.room, state)
               filter:^BOOL(NSNumber * _Nullable value, NSNumber * _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                   return value.integerValue != oldValue.integerValue;
               }
             observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (self.room.state == BJLRoomState_connected) {
                     [self.room.playingVM requestRemoveActiveUser:self.room.loginUser];
                 }
                 return YES;
             }];
    }
}

#pragma mark - actions

- (void)reloadAllTableViewData {
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    if (self.speakRequestTableView && !self.speakRequestTableView.hidden) {
        [self.speakRequestTableView reloadData];
    }
    if (self.onStageTableView && !self.onStageTableView.hidden) {
        [self.onStageTableView reloadData];
    }
    if (self.downStageTableView && !self.downStageTableView.hidden) {
        [self.downStageTableView reloadData];
    }
    if (self.blockedTableView && !self.blockedTableView.hidden) {
        [self.blockedTableView reloadData];
    }
}

- (void)updateGroupList {
    NSMutableArray <BJLUserGroup *> *groupList = [NSMutableArray new];
    for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
        NSUInteger groupID = group.groupID;
        if (groupID == 0) {
            continue;
        }
        [groupList bjl_addObject:group];
    }
    self.groupList = [groupList copy];
}

- (void)updateOnStageUserList {
    NSMutableArray <BJLUser *> *onStageClassUser = [NSMutableArray new];
    NSMutableDictionary<NSNumber *, NSArray<BJLUser *> *> *onStageGroupUserDic = [NSMutableDictionary new];
    
    for (BJLUserGroup *group in self.groupList) {
        NSUInteger groupID = group.groupID;
        if (groupID == 0) {
            continue;
        }
        NSMutableArray<BJLUser *> *groupUserList = [NSMutableArray new];
        [onStageGroupUserDic bjl_setObject:groupUserList forKey:@(groupID)];
    }

    for (BJLUser *user in self.onStageUserList) {
        NSUInteger groupID = user.groupID;
        if (groupID == 0) {
            [onStageClassUser bjl_addObject:user];
            continue;
        }
        
        NSMutableArray<BJLUser *> *groupUserList = [[onStageGroupUserDic bjl_arrayForKey:@(groupID)] mutableCopy];
        if (!groupUserList) {
            groupUserList = [NSMutableArray new];
        }
        [groupUserList bjl_addObject:user];
        [onStageGroupUserDic bjl_setObject:groupUserList forKey:@(groupID)];
    }
    
    self.onStageGroupUserDic = [onStageGroupUserDic copy];
    self.onStageClassUser = [onStageClassUser copy];
}

- (void)updateDownStageUserList {
    NSMutableArray *list = [self.onlineUserList mutableCopy];
    for (BJLUser *onlineUser in [list copy]) {
        for (BJLUser *onStageUser in [self.onStageUserList copy]) {
            if ([onStageUser isSameUser:onlineUser]) {
                [list removeObject:onlineUser];
            }
        }
    }
    self.downStageUserList = list;
    
    NSMutableArray <BJLUser *> *downStageClassUser = [NSMutableArray new];
    NSMutableDictionary<NSNumber *, NSArray<BJLUser *> *> *downStageGroupUserDic = [NSMutableDictionary new];
    
    for (BJLUserGroup *group in self.groupList) {
        NSUInteger groupID = group.groupID;
        if (groupID == 0) {
            continue;
        }
        NSMutableArray<BJLUser *> *groupUserList = [NSMutableArray new];
        [downStageGroupUserDic bjl_setObject:groupUserList forKey:@(groupID)];
    }

    for (BJLUser *user in list) {
        NSUInteger groupID = user.groupID;
        if (groupID == 0) {
            [downStageClassUser bjl_addObject:user];
            continue;
        }
        
        NSMutableArray<BJLUser *> *groupUserList = [[downStageGroupUserDic bjl_arrayForKey:@(groupID)] mutableCopy];
        if (!groupUserList) {
            groupUserList = [NSMutableArray new];
        }
        [groupUserList bjl_addObject:user];
        [downStageGroupUserDic bjl_setObject:groupUserList forKey:@(groupID)];
    }
    self.downStageGroupUserDic = [downStageGroupUserDic copy];
    self.downStageClassUser = [downStageClassUser copy];
}

- (void)updateUserListWithRemovedUser:(BJLUser *)removedUser {
    // 清理成员列表
    for (BJLUser *user in [self.onlineUserList copy]) {
        if ([user.number isEqualToString:removedUser.number]) {
            [self.onlineUserList removeObject:user];
            break;
        }
    }
    for (BJLUser *user in [self.onStageUserList copy]) {
        if ([user.number isEqualToString:removedUser.number]) {
            [self.onStageUserList removeObject:user];
            break;
        }
    }
    for (BJLUser *user in [self.downStageUserList copy]) {
        if ([user.number isEqualToString:removedUser.number]) {
            [self.downStageUserList removeObject:user];
            break;
        }
    }
}

- (void)updateUserListTitle {
    self.titleLabel.text = self.room.onlineUsersVM.onlineUsersTotalCount > 0 ? [NSString stringWithFormat:@"用户列表(%ld人)", (long)self.room.onlineUsersVM.onlineUsersTotalCount] : @"用户列表";
    NSString *handUpTitle = self.speakRequestUserList.count > 0 ? [NSString stringWithFormat:@"举手(%ld)", (long)self.speakRequestUserList.count] : @"举手";
    [self.segmentedControl setTitle:handUpTitle forSegmentAtIndex:0];
    NSString *onlineTitle = self.onlineUserList.count > 0 ? [NSString stringWithFormat:@"用户(%ld)", (long)self.room.onlineUsersVM.onlineUsersTotalCount] : @"用户";
    [self.segmentedControl setTitle:onlineTitle forSegmentAtIndex:1];
    NSString *onStageTitle = self.onStageUserList.count > 0 ? [NSString stringWithFormat:@"台上用户(%ld)", (long)self.onStageUserList.count] : @"台上用户";
    [self.onStageUserButton setTitle:onStageTitle forState:UIControlStateNormal];
    NSString *downStageTitle = self.downStageUserList.count >  0 ? [NSString stringWithFormat:@"台下用户(%ld)", (long)self.downStageUserList.count] : @"台下用户";
    [self.downStageUserButton setTitle:downStageTitle forState:UIControlStateNormal];
    NSString *blockedTitle = self.blockedUserList.count > 0 ? [NSString stringWithFormat:@"黑名单(%ld)", (long)self.blockedUserList.count] : @"黑名单";
    [self.blockedUserButton setTitle:blockedTitle forState:UIControlStateNormal];
    self.freeAllBlockedUserButton.hidden = !(self.blockedUserButton.selected && self.blockedUserList.count > 0);
}

- (void)updateSpeakingRequestEnable {
    BOOL isSelected = self.forbidSpeakRequestButton.isSelected;
    if (self.forbidSpeakRequestCallback) {
        BOOL success = self.forbidSpeakRequestCallback(!isSelected);
        if (success) {
            // 如果成功调用了改变禁言的状态的方法，刷新举手用户视图
            [self showSpeakingRequestViewWithForbidSpeakingRequest:!isSelected];
        }
    }
}

- (void)freeAllBlockedUser {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        return;
    }
    if (self.showFreeAllBlockedUserCallback) {
        self.showFreeAllBlockedUserCallback();
    }
}

- (void)showSwitchStageTipView {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        return;
    }
    if (self.showSwitchStageTipViewCallback) {
        self.showSwitchStageTipViewCallback();
    }
}

- (void)switchToOnStageListTableView {
    self.onStageUserButton.selected = YES;
    self.downStageUserButton.selected = NO;
    self.blockedUserButton.selected = NO;
    self.segmentedControl.selectedSegmentIndex = 1;
    [self switchToOnlineUserView];
    [self reloadAllTableViewData];
}

- (void)hide {
    if (self.closeCallback) {
        self.closeCallback();
    }
}

#pragma mark - speakrequest, onstage, downstage, blocked list switch

- (void)segmentValueChanged:(UISegmentedControl *)segementControl {
    switch (segementControl.selectedSegmentIndex) {
        case 0:
            [self switchToSpeakRequestView];
            break;
            
        case 1:
            [self switchToOnlineUserView];
            break;
            
        default:
            [self switchToSpeakRequestView];
            break;
    }
}

- (void)switchToSpeakRequestView {
    self.onStageUserButton.hidden = YES;
    self.downStageUserButton.hidden = YES;
    self.blockedUserButton.hidden = YES;
    self.onStageTableView.hidden = YES;
    self.downStageTableView.hidden = YES;
    self.blockedTableView.hidden = YES;
    self.forbidSpeakRequestButton.hidden = NO;
    self.freeAllBlockedUserButton.hidden = YES;
    [self showSpeakingRequestViewWithForbidSpeakingRequest:self.room.speakingRequestVM.forbidSpeakingRequest];
}

- (void)switchToOnlineUserView {
    self.forbidSpeakRequestButton.hidden = YES;
    self.forbidSpeakRequestBackgroundView.hidden = YES;
    self.speakRequestTableView.hidden = YES;
    self.onStageUserButton.hidden = NO;
    self.downStageUserButton.hidden = NO;
    self.blockedUserButton.hidden = NO;
    if (self.blockedUserButton.isSelected) {
        [self showBlockedList];
    }
    else if (self.downStageUserButton.isSelected) {
        [self showDownStageList];
    }
    else {
        [self showOnStageList];
    }
}

- (void)showSpeakingRequestViewWithForbidSpeakingRequest:(BOOL)forbid {
    // 禁言时禁言按钮选中状态，背景视图显示，举手列表隐藏
    self.forbidSpeakRequestButton.selected = forbid;
    self.forbidSpeakRequestBackgroundView.hidden = self.forbidSpeakRequestButton.hidden || !forbid;
    self.speakRequestTableView.hidden = forbid;
    [self reloadAllTableViewData];
}

- (void)showOnStageList {
    self.onStageUserButton.selected = YES;
    self.downStageUserButton.selected = NO;
    self.blockedUserButton.selected = NO;
    self.freeAllBlockedUserButton.hidden = YES;
    [self updateOnStageTableViewHidden:NO];
    [self updateDownStageTableViewHidden:YES];
    [self updateBlockTableViewHidden:YES];
    [self reloadAllTableViewData];
}

- (void)showDownStageList {
    self.onStageUserButton.selected = NO;
    self.downStageUserButton.selected = YES;
    self.blockedUserButton.selected = NO;
    self.freeAllBlockedUserButton.hidden = YES;
    [self updateOnStageTableViewHidden:YES];
    [self updateDownStageTableViewHidden:NO];
    [self updateBlockTableViewHidden:YES];
    [self reloadAllTableViewData];
}

- (void)showBlockedList {
    self.onStageUserButton.selected = NO;
    self.downStageUserButton.selected = NO;
    self.blockedUserButton.selected = YES;
    self.freeAllBlockedUserButton.hidden = !(self.blockedUserButton.selected && self.blockedUserList.count > 0);
    [self updateOnStageTableViewHidden:YES];
    [self updateDownStageTableViewHidden:YES];
    [self updateBlockTableViewHidden:NO];
    [self reloadAllTableViewData];
}

- (void)updateOnStageTableViewHidden:(BOOL)hidden {
    self.onStageTableView.hidden = hidden;
    if (hidden) {
        // 隐藏时将上台列表高度置为0
        [self.onStageTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.onStageTableView.bjl_top).priorityHigh();
            make.bottom.equalTo(self.view.bjl_bottom).offset(-[BJLIcAppearance sharedAppearance].userOptionViewHeight * 2).priorityMedium();
        }];
    }
    else {
        // 显示时将上台列表底部等于整个列表的底部偏移下台列表按钮的高度
        [self.onStageTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.view.bjl_bottom).offset(-[BJLIcAppearance sharedAppearance].userOptionViewHeight * 2).priorityHigh();
            make.bottom.equalTo(self.onStageTableView.bjl_top).priorityMedium();
        }];
    }
}

- (void)updateDownStageTableViewHidden:(BOOL)hidden {
    self.downStageTableView.hidden = hidden;
    if (hidden) {
        // 隐藏时将下台列表高度置为0
        [self.downStageTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.downStageTableView.bjl_top).priorityHigh();
            make.bottom.equalTo(self.view.bjl_bottom).offset(-[BJLIcAppearance sharedAppearance].userOptionViewHeight).priorityMedium();
        }];
    }
    else {
        // 显示时将下台列表的底部等于整个列表的底部
        [self.downStageTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.view.bjl_bottom).offset(-[BJLIcAppearance sharedAppearance].userOptionViewHeight).priorityHigh();
            make.bottom.equalTo(self.downStageTableView.bjl_top).priorityMedium();
        }];
    }
}

- (void)updateBlockTableViewHidden:(BOOL)hidden {
    self.blockedTableView.hidden = hidden;
    if (hidden) {
        // 隐藏时将黑名单列表高度置为0
        [self.blockedTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.blockedTableView.bjl_top).priorityHigh();
            make.bottom.equalTo(self.view.bjl_bottom).priorityMedium();
        }];
    }
    else {
        // 显示时将黑名单列表的底部等于整个列表的底部
        [self.blockedTableView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.view.bjl_bottom).priorityHigh();
            make.bottom.equalTo(self.blockedTableView.bjl_top).priorityMedium();
        }];
    }
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSString *identifier = [self identifierWithTableView:tableView];
    return [self numberOfSectionsWithIdentifier:identifier];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *identifier = [self identifierWithTableView:tableView];
    return [self groupUserListWithIdentifier:identifier section:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [self identifierWithTableView:tableView];
    BJLIcUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    return cell;
}

#pragma mark - table view delegate

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *identifier = [self identifierWithTableView:tableView];
    return [self viewForHeaderWithIdentifier:identifier section:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *identifier = [self identifierWithTableView:tableView];
    return [self heightForHeaderWithIdentifier:identifier Section:section];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [self identifierWithTableView:tableView];
    BJLUser *user = [[self groupUserListWithIdentifier:identifier section:indexPath.section] bjl_objectAtIndex:indexPath.row];
    BJLIcUserTableViewCell *userCell = bjl_as(cell, BJLIcUserTableViewCell);
    BOOL disableOptions = NO;
    BOOL canSwitchStage = NO;
    // 当前登录用户以及老师不能对自己禁言和踢出教室
    if ([user.ID isEqualToString:self.room.loginUser.ID] || user.isTeacher) {
        disableOptions = YES;
    }
    // 助教有切换除老师外的全部用户上下台的权限
    if (self.room.loginUser.isAssistant && !user.isTeacher) {
        canSwitchStage = YES;
    }
    else {
        canSwitchStage = NO;
    }
    
    BJLUserGroup *groupInfo = nil;
    for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
        if (group.groupID == user.groupID) {
            groupInfo = [group copy];
            break;
        }
    }

    [userCell updateWithUser:user disableOptions:disableOptions canSwitchStage:canSwitchStage groupInfo:groupInfo];
    // 目前学生禁言只能保留在老师本地，服务端没有处理，因此如果老师退出教室，而学生如果没有退出教室，老师重新进入时学生的禁言状态会是错误的
    BOOL forbid = [self.forbidChatUsers bjl_boolForKey:user.number defaultValue:NO];
    [userCell updateChatForbid:forbid];
    
    bjl_weakify(self);
    [userCell setAllowSpeakRequestCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        // 同意举手，立即刷新
        NSInteger count = self.room.featureConfig.maxActiveUserCount;
        if (self.room.onlineUsersVM.onlineTeacher) {
            // 老师在线的时候，最大上麦数要除去老师
            count++;
        }
        // 如果上台的用户举手的时候，是不用下台其他用户的
        BOOL isActive = NO;
        for (BJLUser *activeUser in [self.room.playingVM.playingUsers copy]) {
            if ([user.ID isEqualToString:activeUser.ID]) {
                isActive = YES;
                break;
            }
        }
        // 1v1 最多二人
        if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
            count = 2;
        }
        // 非上台的用户举手，并且上台人数超过限制，提示
        if (!isActive && self.room.playingVM.playingUsers.count >= count) {
            [self showSwitchStageTipView];
        }
        else {
            BJLError *error = [self.room.speakingRequestVM replySpeakingRequestToUserID:user.ID allowed:YES];
            if (error) {
                if (self.showErrorMessageCallback) {
                    self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                }
            }
            else {
                [self.speakRequestUserList removeObject:user];
                [self reloadAllTableViewData];
                [self updateUserListTitle];
            }
        }
    }];
    
    [userCell setRefuseSpeakRequestCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        // 拒绝举手，立即刷新
        BJLError *error = [self.room.speakingRequestVM replySpeakingRequestToUserID:user.ID allowed:NO];
        if (error) {
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }
        else {
            [self.speakRequestUserList removeObject:user];
            [self reloadAllTableViewData];
            [self updateUserListTitle];
        }
    }];
    
    [userCell setGoOnStageCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        NSInteger count = self.room.featureConfig.maxActiveUserCount;
        if (self.room.onlineUsersVM.onlineTeacher) {
            // 老师在线的时候，最大上麦数要除去老师
            count++;
        }
        // 1v1 最多二人
        if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
            count = 2;
        }
        // 直接操作上下台的时候不可能将上台的用户再次上台，不需要处理是否在台上的判断
        if (self.room.playingVM.playingUsers.count >= count) {
            [self showSwitchStageTipView];
        }
        else {
            if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType && self.room.loginUser.isAssistant) {
                for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                    if (user.isStudent) {
                        if (self.showErrorMessageCallback) {
                            self.showErrorMessageCallback(@"学生在台上时助教不能上台");
                        }
                        return;
                    }
                }
            }
            // 上台, 开启视频，等待SDK刷新移除用户
            BJLError *error = [self.room.playingVM requestAddActiveUser:user];
            if (error) {
                if (self.showErrorMessageCallback) {
                    self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                }
            }
            else {
                // 移出自动上台黑名单
                [self.autoAddActiveUserBlackList removeObject:user.ID];
            }
        }
    }];
    
    [userCell setGoDownStageCallback:^(BJLUser * _Nonnull user) {
         bjl_strongify(self);
        // 下台, 关闭音视频，等待SDK刷新移除用户
        BJLError *error = [self.room.playingVM requestRemoveActiveUser:user];
        if (error) {
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }
        else {
            // 加入自动上台黑名单
            [self.autoAddActiveUserBlackList addObject:user.ID];
            // 移除PPT权限
            if ([self.room.documentVM.authorizedPPTUserNumbers containsObject:user.number]) {
                [self.room.documentVM updateStudentPPTAuthorized:NO userNumber:user.number];
            }
            // 移除画笔权限
            if ([self.room.drawingVM.drawingGrantedUserNumbers containsObject:user.number]) {
                [self.room.drawingVM updateDrawingGranted:NO userNumber:user.number color:nil];
            }
        }
    }];
    
    [userCell setForbidChatCallback:^(BJLUser * _Nonnull user, BOOL forbid) {
        bjl_strongify(self);
        // 禁言某人，目前是禁言一天
        CGFloat duration = forbid ? 60 * 60 * 24 : 0.0;
        BJLError *error = [self.room.chatVM sendForbidUser:user duration:duration];
        if (error) {
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }
    }];
    
    [userCell setBlockUserCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        if (self.blockUserCallback) {
            self.blockUserCallback(user);
        }
    }];
    
    [userCell setFreeBlockedUserCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        [self.room.onlineUsersVM freeBlockedUserWithNumber:user.number];
    }];
}

#pragma mark - load more user

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    // 只有台下用户列表会存在更多用户的情况
    if (self.room.onlineUsersVM.hasMoreOnlineUsers
        && [self atTheBottomOfTableView]
        && !self.downStageTableView.hidden) {
        [self.room.onlineUsersVM loadMoreOnlineUsersWithCount:20];
    }
}

- (BOOL)atTheBottomOfTableView {
    UITableView *tableView = self.speakRequestTableView;
    if (!self.onStageTableView.hidden) {
        tableView = self.onStageTableView;
    }
    else if (!self.downStageTableView.hidden) {
        tableView = self.downStageTableView;
    }
    else if (!self.blockedTableView.hidden) {
        tableView = self.blockedTableView;
    }
    CGFloat contentOffsetY = tableView.contentOffset.y;
    CGFloat bottom = tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(tableView.frame);
    CGFloat contentHeight = tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    return bottomOffset >= 0.0 - [BJLIcAppearance sharedAppearance].userTableViewCellHeight;
}

#pragma mark - wheel

- (nullable NSString *)identifierWithTableView:(UITableView *)tableView {
    if (tableView == self.speakRequestTableView) {
        return BJLIcSpeakRequestUserTableViewCellReuseIdentifier;
    }
    else if (tableView == self.onStageTableView) {
        return BJLIcOnStageTableViewCellReuseIdentifier;
    }
    else if (tableView == self.downStageTableView) {
        return BJLIcDownStageTableViewCellReuseIdentifier;
    }
    else if (tableView == self.blockedTableView) {
        return BJLIcBlockedUserTableViewCellReuseIdentifier;
    }
    else {
        return nil;
    }
}

- (NSUInteger)numberOfSectionsWithIdentifier:(nullable NSString *)identifier {
    NSUInteger number = 0;
    if ([identifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier]) {
        number = 1;
    }
    else if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        number = 1 + [self.groupList count];
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        number = 1 + [self.groupList count];
    }
    else if ([identifier isEqualToString:BJLIcOnlineUserTableViewCellReuseIdentifier]) {
        number = 1;
    }
    else if ([identifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier]) {
        number = 1;
    }
    return number;
}

- (NSArray<BJLUser *> *)userListWithIdentifier:(nullable NSString *)identifier {
    NSArray *array = [NSArray new];
    if ([identifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier]) {
        array = [self.speakRequestUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        array = [self.onStageUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        array = [self.downStageUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcOnlineUserTableViewCellReuseIdentifier]) {
        array = [self.onlineUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier]) {
        array = [self.blockedUserList copy];
    }
    return array;
}

- (NSArray<BJLUser *> *)groupUserListWithIdentifier:(nullable NSString *)identifier section:(NSInteger)section {
    NSArray *array = [NSArray new];
    if ([identifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier]) {
        array = [self.speakRequestUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        if (section == 0) {
            array = [self.onStageClassUser copy];
        }
        else {
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            if (self.onStageSelectedGroupID == group.groupID) {
                array = [[self.onStageGroupUserDic bjl_arrayForKey:@(group.groupID)] copy];
            }
        }
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        if (section == 0) {
            array = [self.downStageClassUser copy];
        }
        else {
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            if (self.downStageSelectedGroupID == group.groupID) {
                array = [[self.downStageGroupUserDic bjl_arrayForKey:@(group.groupID)] copy];
            }
        }
    }
    else if ([identifier isEqualToString:BJLIcOnlineUserTableViewCellReuseIdentifier]) {
        array = [self.onlineUserList copy];
    }
    else if ([identifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier]) {
        array = [self.blockedUserList copy];
    }
    return array;
}

- (CGFloat)heightForHeaderWithIdentifier:(nullable NSString *)identifier Section:(NSInteger)section {
    CGFloat height = 0;
    if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        if (section != 0) {
            height = 40;
        }
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        if (section != 0) {
            height = 40;
        }
    }
    return height;
}

- (UIView *)viewForHeaderWithIdentifier:(nullable NSString *)identifier section:(NSInteger)section {
    if ([identifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        if (section != 0) {
            BJLIcUserGroupView *groupView = [BJLIcUserGroupView new];
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            [groupView updateWithGroupInfo:group shouldClose:(group.groupID != self.onStageSelectedGroupID)];
            bjl_weakify(self);
            [groupView setClickCallback:^(BOOL show) {
                bjl_strongify(self);
                if (show) {
                    self.onStageSelectedGroupID = group.groupID;
                }
                else {
                    self.onStageSelectedGroupID = 0;
                }
                [self reloadAllTableViewData];
            }];
            return groupView;
        }
    }
    else if ([identifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
        if (section != 0) {
            BJLIcUserGroupView *groupView = [BJLIcUserGroupView new];
            BJLUserGroup *group = [self.groupList bjl_objectAtIndex:section - 1];
            [groupView updateWithGroupInfo:group shouldClose:(group.groupID != self.downStageSelectedGroupID)];
            bjl_weakify(self);
            [groupView setClickCallback:^(BOOL show) {
                bjl_strongify(self);
                if (show) {
                    self.downStageSelectedGroupID = group.groupID;
                }
                else {
                    self.downStageSelectedGroupID = 0;
                }
                [self reloadAllTableViewData];
            }];
            return groupView;
        }
    }
    return [UIView new];
}

- (UIView *)createShadowSingleLine {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05];
    // shadow
    view.layer.masksToBounds = NO;
    view.layer.shadowOpacity = 0.2;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    view.layer.shadowRadius = 10.0;
    return view;
}

- (BJLIcUserHeaderButton *)createUserOptionButton {
    BJLIcUserHeaderButton *button = [BJLIcUserHeaderButton new];
    button.layer.masksToBounds = NO;
    button.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.05].CGColor;
    button.layer.borderWidth = 0.5;
    button.layer.shadowOpacity = 0.2;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    button.layer.shadowRadius = 10.0;
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [button setTitleColor:[UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0] forState:UIControlStateNormal];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, [BJLIcAppearance sharedAppearance].userViewLargeSpace, 0, 0);
    [button setCustomImage:[UIImage bjlic_imageNamed:@"bjl_userlist_fold"] forState:UIControlStateNormal];
    [button setCustomImage:[UIImage bjlic_imageNamed:@"bjl_userlist_expand"] forState:UIControlStateSelected];
    [button.customImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(button.bjl_right).offset(-[BJLIcAppearance sharedAppearance].userViewSmallSpace);
        make.top.bottom.equalTo(button);
        make.centerY.equalTo(button.bjl_centerY);
    }];
    return button;
}

@end

NS_ASSUME_NONNULL_END

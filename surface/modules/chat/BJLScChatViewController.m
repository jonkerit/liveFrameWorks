//
//  BJLScChatViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <SafariServices/SafariServices.h>

#import "BJLScChatViewController.h"
#import "BJLChatViewController.h"
#import "BJLChatViewController+recentMessages.h"
#import "BJLChatUploadingTask.h"
#import "BJLScChatCell.h"
#import "BJLMessageOperatorView.h"
#import "BJLScAppearance.h"
#import "BJLScStickyMessageView.h"

static const NSTimeInterval translateRequestTimeout = 5.0;

@interface BJLScChatViewController () <UIPopoverPresentationControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic) BJLChatStatus chatStatus;
@property (nonatomic, nullable) BJLUser *targetUser;
@property (nonatomic) BOOL onlyShowTeacherOrAssistant;

// NOTE: show sendingMessages in the second section
@property (nonatomic) NSMutableArray<id/* BJLMessage * || BJLChatUploadingTask * */> *allMessages, *currentDataSource;
@property (nonatomic) NSMutableDictionary<NSString *, NSMutableArray *> *whisperMessageDict;
@property (nonatomic) NSMutableArray<BJLMessage *> *unreadMessages, *unreadWhisperMessages, *teacherOrAssistantMessages, *imageMessages;
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) NSMutableDictionary<NSString *, UIImage *> *thumbnailForURLString;

// view
@property (nonatomic) UIView *emptyView;
@property (nonatomic, readwrite) UIView *chatStatusView;
@property (nonatomic) UILabel *chatStatusLabel;
@property (nonatomic) UIButton *unreadMessagesTipButton, *cancelChatButton;
@property (nonatomic) UIView *chatInputView;
@property (nonatomic) BOOL wasAtTheBottomOfTableView;

// translation
@property (nonatomic) NSMutableDictionary <NSString *, BJLMessage *> *currentTranslateCachesDict;
@property (nonatomic) NSMutableDictionary <NSString *, NSNumber *> *translatedMessageSendTimes;
@property (nonatomic, nullable) NSTimer *sendTimeRecordTimer;
@property (nonatomic) UIViewController *optionViewController;

// 用于外部红点提示未读消息数量
@property (nonatomic) NSMutableArray<BJLMessage *> *unreadMessageArray;

// 1v1
@property (nonatomic, readonly) BOOL is1V1Class;

// 置顶消息
@property (nonatomic) BJLScStickyMessageView *stickyMessageView;
@property (nonatomic) BJLConstraint *chatStatusTopConstraint;
@property (nonatomic) BJLConstraint *stickyMessageViewBottomConstraint;

@end

@implementation BJLScChatViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self->_room = room;
        
        /*
         self.allEmoticons = ({
         NSMutableDictionary *allEmoticons = [NSMutableDictionary new];
         for (BJLEmoticon *emoticon in [BJLEmoticon allEmoticons]) {
         [allEmoticons bjl_setObject:emoticon
         forKey:emoticon.key];
         }
         allEmoticons;
         }); */
        
        self.allMessages = [NSMutableArray new];
        self.currentDataSource = self.allMessages;
        self.unreadMessages = [NSMutableArray new];
        self.imageMessages = [NSMutableArray new];

        self.thumbnailForURLString = [NSMutableDictionary new];
        self.translatedMessageSendTimes = [NSMutableDictionary new];
        self.currentTranslateCachesDict = [NSMutableDictionary new];
        
        self.unreadMessageArray = [NSMutableArray new];
        [self makeObserving];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    #if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
    #endif
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (iPhone && self.is1V1Class) {
        self.view.backgroundColor = [UIColor bjl_colorWithHex:0XF7F7F7];
    }
    else {
        self.view.backgroundColor = [UIColor clearColor];
    }
    
    [self setUpSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.wasAtTheBottomOfTableView = [self atTheBottomOfTableView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.tableView.scrollIndicatorInsets = bjl_set(self.tableView.scrollIndicatorInsets, {
        CGFloat adjustment = CGRectGetWidth(self.view.frame) - BJLScScrollIndicatorSize;
        set.left = - adjustment;
        set.right = adjustment;
    });
    
    if (self.wasAtTheBottomOfTableView && ![self atTheBottomOfTableView]) {
        [self scrollToTheEndTableView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateEmptyViewHidden];
    [self.tableView reloadData];
    [self loadUnreadMessages];
    [self scrollToTheEndTableView];
    
    [self.unreadMessageArray removeAllObjects];
    if (self.newMessageCallback) {
        self.newMessageCallback(0);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.thumbnailForURLString removeAllObjects];
}

- (void)dealloc {
    
    [self.sendTimeRecordTimer invalidate];
    self.sendTimeRecordTimer = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - subviews

- (void)setUpSubviews {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat margin = 5.0;
    
    // chatStatusView
    self.chatStatusView = ({
        UIView *view = [[UIView alloc] init];
        view.accessibilityLabel = BJLKeypath(self, chatStatusView);
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
        view.clipsToBounds = YES;
        view.layer.masksToBounds = YES;
        view;
    });
    [self.view addSubview:self.chatStatusView];
    [self.chatStatusView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        [self.chatStatusTopConstraint uninstall];
        self.chatStatusTopConstraint = make.top.equalTo(self.stickyMessageView.bjl_bottom).priorityHigh().constraint;
        make.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@(0.0));
    }];
    // cancelChatButton
    self.cancelChatButton = ({
        UIButton *button = [[UIButton alloc] init];
        button.accessibilityLabel = @"cancelChatButton";
        [button setTitle:@"取消私聊" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHex:0x999999] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor clearColor];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        button.layer.borderColor = [UIColor bjl_colorWithHex:0XE5E5E5].CGColor;
        button.layer.borderWidth = BJLScOnePixel;
        button.layer.cornerRadius = 3.0;
        [button addTarget:self action:@selector(cancelPrivateChat) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.chatStatusView addSubview:self.cancelChatButton];
    [self.cancelChatButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.chatStatusView).offset(-margin);
        make.centerY.equalTo(self.chatStatusView);
        make.width.equalTo(@(64.0));
        make.height.equalTo(@(24.0));
    }];
    // chatStatusLabel
    self.chatStatusLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.accessibilityLabel = BJLKeypath(self, chatStatusLabel);
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor bjl_colorWithHex:0x333333];
        label.numberOfLines = 1;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label;
    });
    [self.chatStatusView addSubview:self.chatStatusLabel];
    [self.chatStatusLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view).offset(margin);
        make.centerY.equalTo(self.chatStatusView);
        make.right.equalTo(self.cancelChatButton.bjl_left).offset(-margin);
    }];
    
    UIButton *backButton = nil;
    if (self.is1V1Class && iPhone) {
        backButton = ({
            UIButton *button = [UIButton new];
            button.accessibilityLabel = @"backButton";
            button.backgroundColor = [UIColor clearColor];
            [button setTitle:@"返回" forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:12.0];
            [button setTitleColor:[UIColor bjl_colorWithHexString:@"#333333"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_chat_back"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(backToVideo) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.view addSubview:backButton];
        [backButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.bottom.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
            make.height.equalTo(@32.0);
            make.width.equalTo(self.view).multipliedBy(1.0/3.0);
        }];
    }
    
    self.chatInputView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, chatInputView);
        view.backgroundColor = [UIColor whiteColor];
        if (!self.is1V1Class || !iPhone) {
            view.layer.masksToBounds = NO;
            view.layer.shadowOpacity = 0.3;
            view.layer.shadowColor = [UIColor blackColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(0.0, -2.0);
            view.layer.shadowRadius = 2.0;
        }
        view;
    });
    [self.view addSubview:self.chatInputView];
    [self.chatInputView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        if (self.is1V1Class && iPhone) {
            make.left.equalTo(backButton.bjl_right);
        }
        else {
            make.left.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        }
        make.right.bottom.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@32.0);
    }];

    UIButton *chatInputButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = @"chatInputButton";
        button.layer.cornerRadius = 2.0;
        button.layer.masksToBounds = YES;
        button.layer.borderColor = [UIColor bjl_colorWithHexString:@"#D0D0D0" alpha:1.0].CGColor;
        button.layer.borderWidth = 1.0;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleLabel.textAlignment = NSTextAlignmentLeft;
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle: @"输入聊天内容" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0] forState:UIControlStateNormal];
        button.titleEdgeInsets = UIEdgeInsetsMake(3.0, 5.0, 3.0, 5.0);
        [button addTarget:self action:@selector(showChatInputView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.chatInputView addSubview:chatInputButton];
    
    if (!self.room.featureConfig.enableWhisper) {
        [chatInputButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.chatInputView).offset(8.0);
            make.top.bottom.equalTo(self.chatInputView).inset(4.0).priorityHigh();
            make.right.equalTo(self.chatInputView).offset(-8.0);
        }];
    }
    else {
        [chatInputButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.chatInputView).offset(8.0);
            make.top.bottom.equalTo(self.chatInputView).inset(4.0).priorityHigh();
        }];

        UIButton *whisperButton = ({
            UIButton *button = [UIButton new];
            button.accessibilityLabel = @"whisper";
            button.layer.cornerRadius = 2.0;
            button.layer.masksToBounds = YES;
            button.layer.borderColor = [UIColor bjl_colorWithHexString:@"#D0D0D0" alpha:1.0].CGColor;
            button.layer.borderWidth = 1.0;
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            button.titleLabel.font = [UIFont systemFontOfSize:12.0];
            [button setTitle: @"私聊" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor bjl_colorWithHexString:@"#333333" alpha:1.0] forState:UIControlStateNormal];
            //        button.titleEdgeInsets = UIEdgeInsetsMake(3.0, 5.0, 3.0, 5.0);
            [button addTarget:self action:@selector(showChatInputViewWithWhisper) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.chatInputView addSubview:whisperButton];
        [whisperButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(chatInputButton.bjl_right).offset(2.0);
            make.top.bottom.equalTo(self.chatInputView).inset(4.0).priorityHigh();
            make.right.equalTo(self.chatInputView).offset(-8.0);
            make.width.equalTo(@(48));
        }];
    }

    // tableView
    [self setUpTableView];
    [self.tableView bjl_removeAllConstraints];
    [self.tableView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.chatStatusView.bjl_bottom);
        make.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.bottom.equalTo(self.chatInputView.bjl_top);
    }];
    
    // unreadMessage
    self.unreadMessagesTipButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, unreadMessagesTipButton);
        button.hidden = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        UIImage *icon = [UIImage bjl_imageNamed:@"bjl_ic_arrow_moremsg"];
        [button setImage:icon forState:UIControlStateNormal];
        button.backgroundColor = [UIColor bjl_darkDimColor];
        CGFloat midSpace = 3.0;
        button.titleEdgeInsets = UIEdgeInsetsMake(0.0, midSpace, 0.0, - midSpace);
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0, BJLViewSpaceM, 0.0, BJLViewSpaceM + midSpace);
        button.layer.cornerRadius = 5.0;
        button;
    });
    [self.view addSubview:self.unreadMessagesTipButton];
    [self.unreadMessagesTipButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view).offset(BJLScScrollIndicatorSize);
        make.bottom.equalTo(self.view).offset(-32.0);
        CGFloat height = 44;
        make.height.equalTo(@(height));
    }];
    
    bjl_weakify(self);
    [self.unreadMessagesTipButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (self.unreadMessagesCount > 0) {
            [self loadUnreadMessages];
            [self scrollToTheEndTableView];
        }
        else {
            [self updateUnreadMessagesTipWithCount:0];
        }
    }];
    
    // emptyView
    self.emptyView = ({
        UIView *view = [BJLHitTestView new];
        view.clipsToBounds = YES;
        view.accessibilityLabel = BJLKeypath(self, emptyView);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view insertSubview:self.emptyView belowSubview:self.chatStatusView];
    [self.emptyView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    UILabel *emptyLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = @"emptyLabel";
        label.text = @"无更多历史消息";
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor bjl_colorWithHexString:@"#DEDEDE" alpha:1.0];
        label;
    });
    [self.emptyView addSubview:emptyLabel];
    [emptyLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.emptyView);
        make.left.right.equalTo(self.emptyView);
        make.top.equalTo(self.emptyView).offset(8.0);
        make.height.equalTo(@20.0).priorityHigh();
    }];
    
    self.stickyMessageView = ({
        BJLScStickyMessageView *stickyMessageView = [[BJLScStickyMessageView alloc] initWithMessage:nil canCancel:self.room.loginUser.isTeacherOrAssistant];
        stickyMessageView.backgroundColor = [UIColor whiteColor];
        stickyMessageView.hidden = YES;
        bjl_weakify(self);
        [stickyMessageView setCancelStickyCallback:^{
            bjl_strongify(self);
            if (self.room.loginUser.isTeacherOrAssistant) {
                BJLError *error = [self.room.chatVM sendStickyMessage:nil];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
            }
        }];
        [stickyMessageView setLinkURLCallback:^BOOL(NSURL * _Nonnull url) {
            bjl_strongify(self);
            return [self openURL:url];
        }];
        [stickyMessageView setUpdateConstraintsCallback:^(BOOL showcompleteMessage) {
            bjl_strongify(self);
            if (!showcompleteMessage) {
                [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
                    [self.chatStatusTopConstraint uninstall];
                    self.chatStatusTopConstraint = make.top.equalTo(self.stickyMessageView.bjl_bottom).constraint;
                }];
            }
            else {
                [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
                    [self.chatStatusTopConstraint uninstall];
                    self.chatStatusTopConstraint = make.top.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view).constraint;
                }];
            }
        }];
        [stickyMessageView setImageSelectCallback:^(BJLMessage * _Nullable message) {
            bjl_strongify(self);
            if (message && message.type == BJLMessageType_image) {
                if (self.showImageViewCallback) self.showImageViewCallback(message, @[message], YES);
            }
        }];
        stickyMessageView;
    });
    
    [self.view addSubview:self.stickyMessageView];
    [self.stickyMessageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.vertical.compressionResistance.hugging.required();
        make.top.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.bottom.lessThanOrEqualTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
    }];

}

- (void)updateInputViewHidden:(BOOL)hidden {
    self.chatInputView.hidden = hidden;
    if (hidden) {
        [self.chatInputView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@0.0);
        }];
    }
    else {
        [self.chatInputView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@32.0);
        }];
    }
}

#pragma mark - private

- (void)updateUnreadMessagesTipWithCount:(NSInteger)unreadMessagesCount {
    if (unreadMessagesCount > 0) {
        NSString *title = [NSString stringWithFormat:@"%td条新消息", unreadMessagesCount];
        [self.unreadMessagesTipButton setTitle:title forState:UIControlStateNormal];
        self.unreadMessagesTipButton.hidden = NO;
    }
    else {
        [self.unreadMessagesTipButton setTitle:nil forState:UIControlStateNormal];
        self.unreadMessagesTipButton.hidden = YES;
    }
}

- (void)loadUnreadMessages {
    if (self.unreadMessages.count <= 0) {
        return;
    }
    [self.unreadMessages removeAllObjects];
    self.unreadMessagesCount = [self.unreadMessages count];
    [self updateUnreadMessagesTipWithCount:self.unreadMessagesCount];
}

- (void)updateEmptyViewHidden {
    BOOL hidden = (self.currentDataSource.count > 0);
    self.emptyView.hidden = hidden;
}

- (void)showChatInputView {
    if (self.showChatInputViewCallback) {
        self.showChatInputViewCallback(NO);
    }
}

- (void)showChatInputViewWithWhisper {
    if (self.showChatInputViewCallback) {
        self.showChatInputViewCallback(YES);
    }
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, receivedMessagesDidOverwrite:)
             observer:^BOOL(NSArray<BJLMessage *> * _Nullable messages) {
                 bjl_strongify(self);
                 
                 [self clearDataSource]; // 清空群聊、私聊数据源 及 高度缓存
                 if (messages.count > 0) {
                     [self.allMessages addObjectsFromArray:messages];
                     [self updateImageMessagesWithMessages:messages];

                     [messages enumerateObjectsUsingBlock:^(BJLMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                         bjl_strongify(self);
                         if (obj.fromUser.isTeacherOrAssistant) {
                             [self.teacherOrAssistantMessages bjl_addObject:obj];
                         }
                     }];
                 }
                 
                 [self updateCurrentDataSource];
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 [self scrollToTheEndTableView];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didReceiveMessages:)
             observer:^BOOL(NSArray<BJLMessage *> *messages) {
                 bjl_strongify(self);
                 
                 for (BJLMessage *message in [messages copy]) {
                     BOOL replacedTask = NO;
                     if (message.type == BJLMessageType_image
                         && [message.fromUser.number isEqualToString:self.room.loginUser.number]) {
                         for (id object in [self.currentDataSource copy]) {
                             BJLChatUploadingTask *task = bjl_as(object, BJLChatUploadingTask);
                             if (task.state == BJLUploadState_uploaded
                                 && [task.result isEqualToString:message.imageURLString]) {
                                 [self.thumbnailForURLString bjl_setObject:task.thumbnail
                                                                    forKey:message.imageURLString];
                                 [self replaceTask:task withMessage:message];
                                 replacedTask = YES;
                                 break;
                             }
                         }
                     }
                     
                     // targetUserNumber：群聊消息中为空，私聊消息中为私聊对象的 number
                     NSString *targetUserNumber = nil;
                     NSString *toUserNumber = message.toUser.number;
                     if (toUserNumber.length > 0) {
                         NSString *fromUserNumber = message.fromUser.number;
                         targetUserNumber = [self.room.loginUser.number isEqualToString:toUserNumber] ? fromUserNumber : toUserNumber;
                     }
                     
                     // 新增消息而非替换
                     if (!replacedTask) {
                         // 未读消息
                         BOOL shouldUpdateUnreadMessage = (self.chatStatus != BJLChatStatus_private);
                         if (self.chatStatus == BJLChatStatus_private) {
                             // 私聊状态时，收到当前私聊的消息才更新未读消息数
                             shouldUpdateUnreadMessage = [targetUserNumber isEqualToString:self.targetUser.number];
                         }
                         
                         // 更新未读消息数
                         if (shouldUpdateUnreadMessage && ![message.fromUser isSameUser:self.room.loginUser]) {
                             [self.unreadMessageArray bjl_addObject:message];
                             [self.unreadMessages bjl_addObject:message];
                             self.unreadMessagesCount = [self.unreadMessages count];
                         }
                                                  
                         // 更新来自老师/助教的消息
                         if (message.fromUser.isTeacherOrAssistant) {
                             [self.teacherOrAssistantMessages bjl_addObject:message];
                         }
                         
                         // 添加 messgae
                         [self addMessageToCurrentDataSource:message targetUserNumber:targetUserNumber];
                     }
                 }
                
                 [self updateImageMessagesWithMessages:messages];

                 if (self.newMessageCallback) {
                     self.newMessageCallback([self.unreadMessageArray count]);
                 }

                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.unreadMessageArray removeAllObjects];
                 [self updateEmptyViewHidden];
                 [self.tableView reloadData];
                 
                 // 滑动到底部
                 BOOL wasAtTheBottomOfTableView = [self atTheBottomOfTableView];
                 if ([messages.lastObject.fromUser.number isEqualToString:self.room.loginUser.number]
                     || wasAtTheBottomOfTableView) {
                     [self scrollToTheEndTableView];
                 }
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self, currentDataSource)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                 return YES;
             }
             [self updateEmptyViewHidden];
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didRevokeMessageWithID:isCurrentUserRevoke:)
             observer:(BJLMethodObserver)^BOOL(NSString *messageID, BOOL isCurrentUserRevoke) {
        bjl_strongify(self);
        if (isCurrentUserRevoke) {
            return YES;
        }
        else {
            [self updateDataSourceWithRevokeMessageID:messageID];
            if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                return YES;
            }
            [self.tableView reloadData];
        }
        return YES;
    }];

    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didReceiveMessageTranslation:messageUUID:)
             observer:^BOOL(NSString *translate, NSString *messageUUID) {
                 bjl_strongify(self);
                 [self didReceiveMessageTranslation:translate messageUUID:messageUUID];
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self, unreadMessagesCount)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             NSInteger unreadMessagesCount = now.integerValue;
             if (unreadMessagesCount > 0 && [self atTheBottomOfTableView]) {
                 [self loadUnreadMessages];
                 [self scrollToTheEndTableView];
             }
             else {
                 [self updateUnreadMessagesTipWithCount:unreadMessagesCount];
             }
             return YES;
         }];
    
    if (!self.is1V1Class) {
        [self bjl_kvo:BJLMakeProperty(self.room.chatVM, stickyMessage) observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            [self udpateStickyMessageView];
            return YES;
        }];
    }
}

- (void)updateImageMessagesWithMessages:(NSArray<BJLMessage *> *)messages {
    for (BJLMessage *message in [messages copy]) {
        if (message.type == BJLMessageType_image) {
            [self.imageMessages bjl_addObject:message];
        }
    }
}

#pragma mark - messageTranslate
- (NSString *)keyForMessgaetranslation:(BJLMessage *)message {
    //    使用消息ID-发送方ID-翻译发送时间戳 做为区分message的唯一字符串
    NSTimeInterval currentTimeInterval = [NSDate timeIntervalSinceReferenceDate];
    NSString *currentTimeString = [NSString stringWithFormat:@"%f",currentTimeInterval];
    
    NSString *key = [NSString stringWithFormat:@"%@-%@-%@", message.ID, message.fromUser.ID, currentTimeString];
    return key;
}

- (void)showOperatorViewWithMessage:(BJLMessage *)message
                              point:(CGPoint)point
                              image:(UIImage *)image {
    bjl_weakify(self);
    BOOL needTranslate = (!message.translation.length && self.room.featureConfig.enableChatTranslation && message.type == BJLMessageType_text);
    // 群聊下，点击老师/助教消息可以弹出”只看老师/助教“选项
    BOOL needShowOnlyTeacherOrAssistant = self.chatStatus == BJLChatStatus_default && message.fromUser.isTeacherOrAssistant && !self.onlyShowTeacherOrAssistant;
    BJLRecallType recallType = BJLRecallTypeNone;
    if ([message.fromUser.number isEqualToString:self.room.loginUser.number]) {
        recallType = BJLRecallTypeNormal;
    }
    else if (self.room.loginUser.isTeacherOrAssistant) {
        recallType = BJLRecallTypeDelete;
    }
       
    NSInteger optionCount = 1;
    optionCount += needTranslate ? 1 : 0;
    optionCount += (recallType == BJLRecallTypeNone) ? 0 : 1;
    optionCount += needShowOnlyTeacherOrAssistant ? 1 : 0;
    CGFloat height = 20.0 + optionCount * BJLMessageOperatorButtonSize;
    CGFloat width = needShowOnlyTeacherOrAssistant ? 120.0 : 64.0f;
    
    self.optionViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor whiteColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = CGSizeMake(width, height);
        viewController.popoverPresentationController.backgroundColor = [UIColor whiteColor];
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self.view;
        viewController.popoverPresentationController.sourceRect = CGRectMake(point.x, point.y, 1.0, 1.0);
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    
    BJLMessageOperatorView *optionView = [[BJLMessageOperatorView alloc] initWithNeedTranslate:needTranslate needShowOnlyTeacherOrAssistant:needShowOnlyTeacherOrAssistant recallType:recallType canStickyMessage:self.room.loginUser.isTeacherOrAssistant && !self.is1V1Class];
    [optionView updateButtonConstraints];
    [optionView setOnClikCopyCallback:^(BOOL on) {
        bjl_strongify(self);
        switch (message.type) {
            case BJLMessageType_text: {
                if(message.text.length) {
                    [[UIPasteboard generalPasteboard] setString:message.text];
                }
                break;
            }
                
            case BJLMessageType_image: {
                if (message.imageURLString) {
                    [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"[img:%@]", message.imageURLString]];
                }
                break;
            }
                
            case BJLMessageType_emoticon: {
                [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"[%@]", message.emoticon.name]];
                break;
            }
            default:
                break;
        }
        [self hideOptionViewController];
    }];
    
    [optionView setOnClikTranslateCallback:^(BOOL on) {
        bjl_strongify(self);
        [self hideOptionViewController];
        if (message && message.type == BJLMessageType_text && message.text.length
           && !message.translation.length) {
            
            NSString *messageUUID = [self keyForMessgaetranslation:message];

            [self startSendTimeRecording:message messageUUID:messageUUID];
            [self.currentTranslateCachesDict bjl_setObject:message forKey:messageUUID];
            BJLError *error = [self.room.chatVM translateMessage:message
                                                     messageUUID:messageUUID
                                                   translateType:([self shouldTranslateToEn:message] ? BJLMessageTranslateTypeZHtoEN : BJLMessageTranslateTypeENtoZH)];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }
    }];
    
    [optionView setOnlyShowTeacherORAssistantMessageCallback:^(BOOL on) {
        bjl_strongify(self);
        [self hideOptionViewController];
        BOOL needShowOnlyTeacherOrAssistant = self.chatStatus == BJLChatStatus_default && message.fromUser.isTeacherOrAssistant;
        if (message && needShowOnlyTeacherOrAssistant) {
            [self startOnlyShowTeacherOrAsisstantMessgae:YES];
        }
    }];
    
    [optionView setRecallMessageCallback:^(BOOL on) {
        bjl_strongify(self);
        [self hideOptionViewController];
        BJLError *error = [self.room.chatVM revokeMessage:message];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
        else {
            [self updateDataSourceWithRevokeMessageID:message.ID];
            [self.tableView reloadData];
        }
    }];
    
    [optionView setStickyMessageCallback:^(BOOL on) {
        bjl_strongify(self);
        [self hideOptionViewController];
        BJLError *error = [self.room.chatVM sendStickyMessage:message];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }];
    
    [self.optionViewController.view addSubview:optionView];
    [optionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.optionViewController.view.bjl_safeAreaLayoutGuide ?: self.optionViewController.view).inset(1.0);
    }];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:self.optionViewController animated:YES completion:nil];
}

- (void)hideOptionViewController {
    [self.optionViewController bjl_dismissAnimated:YES completion:nil];
}

- (void)startSendTimeRecording:(BJLMessage *)message messageUUID:(NSString *)messageUUID {
    
    if (!self.sendTimeRecordTimer || !self.sendTimeRecordTimer.isValid) {
        bjl_weakify(self);
        self.sendTimeRecordTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            bjl_strongify(self);
            if (!self) {
                [timer invalidate];
                return;
            }
            [self checkcRequestTimeOutMessage];
        }];
    }
    
    if (message && messageUUID) {
        [self recordSendTime:message messageUUID:messageUUID];
    }
}

//记录发送翻译信令的message 发送时间
- (void)recordSendTime:(BJLMessage *)message messageUUID:(NSString *)messageUUID{
    if (!message) {
        return;
    }
    
    NSTimeInterval currentTimeInterval = [NSDate timeIntervalSinceReferenceDate];
    NSNumber *currentTime = [NSNumber numberWithDouble:currentTimeInterval];
    
    [self.translatedMessageSendTimes bjl_setObject:currentTime forKey:messageUUID];
}

//轮循检查请求超时的message
- (void)checkcRequestTimeOutMessage {
    bjl_weakify(self);
    NSArray *messageSendTimeKeys = [self.currentTranslateCachesDict allKeys];
    [messageSendTimeKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        bjl_strongify(self);
        NSNumber *sendTime = [self.translatedMessageSendTimes bjl_numberForKey:obj defaultValue:@(-1)];
        
        if (![sendTime isEqualToNumber:@(-1)]) {
            NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
            NSTimeInterval sentSeconds = round(currentTime - sendTime.doubleValue);
            
            //已经请求的时候大于 translateRequestTimeout ,则视为请求超时
            if (sentSeconds > translateRequestTimeout) {
                [self.currentTranslateCachesDict bjl_removeObjectForKey:obj];
                [self.translatedMessageSendTimes removeObjectForKey:obj];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showTranslationFailedMessage];
                });
            }
        }
    }];
}

- (void)didReceiveMessageTranslation:(NSString *)translate messageUUID:(NSString *)messageUUID {
    if (!messageUUID)
        return;
    
    __block BJLMessage *cacheMessage = nil;
    bjl_weakify(self);
    NSArray *messageSendTimeKeys = [self.currentTranslateCachesDict allKeys];
    [messageSendTimeKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        bjl_strongify(self);
        if (obj && [obj isEqualToString:messageUUID] ) {
            cacheMessage = [self.currentTranslateCachesDict bjl_objectForKey:obj class:[BJLMessage class]];
            *stop = YES;
        }
    }];
    
    if (!cacheMessage) {
        return;
    }
    
    [self.currentTranslateCachesDict bjl_removeObjectForKey:messageUUID];
    [self.translatedMessageSendTimes removeObjectForKey:messageUUID];
    
    if (!translate.length) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showTranslationFailedMessage];
        });
        return;
    }
    [cacheMessage updateTranslationString:translate];
    
    NSUInteger index = [self.currentDataSource indexOfObject:cacheMessage];
    if (index == NSNotFound || self.currentDataSource.count <= 0) {
        return;
    }
    
    [self.tableView bjl_clearHeightCaches];
    [self.tableView reloadData];
}

- (void)showTranslationFailedMessage {
    NSArray  *languages = [NSLocale preferredLanguages];
    NSString *language = [languages objectAtIndex:0];
    if ([language hasPrefix:@"zh-Hans"]) {
        [self showProgressHUDWithText:@"翻译失败"];
    }
    else {
        [self showProgressHUDWithText:@"Translate Fail!"];
    }
}

- (BOOL)shouldTranslateToEn:(BJLMessage *)message {
    if (!message || !message.text.length)
        return NO;
    
    NSString *text = message.text;
    
    //判断是否包含中文汉子
    for(int i = 0; i < [text length]; i++)
    {
        unichar ch = [text characterAtIndex:i];
        if (0x4E00 <= ch  && ch <= 0x9FA5) {
            return YES;
        }
    }
    //判断是否为纯数字,是则翻译为英文
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:text]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - public

- (void)refreshMessages {
    [self loadUnreadMessages];
    [self scrollToTheEndTableView];
}

- (void)sendImageFile:(ICLImageFile *)file image:(nullable UIImage *)image {
    [self loadUnreadMessages];
    
    BJLChatUploadingTask *task = [BJLChatUploadingTask uploadingTaskWithImageFile:file room:self.room];
    [self addTaskToCurrentDataSource:task];
    
    [self startObservingUploadingTask:task];
    [task upload];
}

- (void)startObservingUploadingTask:(BJLChatUploadingTask *)task {
    bjl_weakify(self, task);
    
    [self bjl_kvo:BJLMakeProperty(task, state)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self, task);
             [self updateCellWithUploadingTask:task];
             if (task.state == BJLUploadState_uploaded) {
                 [self sendMessageWithUploadingTask:task];
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(task, progress)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self, task);
             [self updateCellWithUploadingTask:task];
             return YES;
         }];
}

- (void)updateCellWithUploadingTask:(BJLChatUploadingTask *)task {
    NSUInteger index = [self.currentDataSource indexOfObject:task];
    if (index == NSNotFound || self.currentDataSource.count <= 0) {
        return;
    }
    [self.tableView reloadData];
}

- (void)sendMessageWithUploadingTask:(BJLChatUploadingTask *)task {
    BJLUser *targetUser = (self.chatStatus == BJLChatStatus_private)? self.targetUser : nil;
    NSDictionary *data = [BJLMessage messageDataWithImageURLString:task.result imageSize:task.imageSize];
    BJLError *error = [self.room.chatVM sendMessageData:data toUser:targetUser];
    if (error) {
        task.error = error;
        [self updateCellWithUploadingTask:task];
        [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
    }
}

- (void)backToVideo {
    if (self.backToVideoCallback) {
        self.backToVideoCallback();
    }
}

#pragma mark - chatStatus

- (void)updateChatStatus:(BJLChatStatus)chatStatus withTargetUser:(nullable BJLUser *)targetUser {
    //    不管是切换到公聊or私聊，切换后， 都要清空只看老师/助教状态
    self.onlyShowTeacherOrAssistant = NO;
    
    self.chatStatus = chatStatus;
    self.targetUser = (chatStatus == BJLChatStatus_private)? targetUser : nil;
    
    CGFloat statusViewHeight = 0.0;
    if (chatStatus == BJLChatStatus_private) {
        self.currentDataSource = [self.whisperMessageDict bjl_objectForKey:self.targetUser.number class:[NSMutableArray class]];
        NSString *tipLabel = @"私聊:";
        NSString *displayName = targetUser.displayName ?: @"---";
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", tipLabel, displayName]];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor bjl_colorWithHex:0x333333] range:NSMakeRange(0, tipLabel.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor bjl_colorWithHex:0x1795FF] range:NSMakeRange(tipLabel.length, displayName.length)];
        [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, tipLabel.length + displayName.length)];

        self.chatStatusLabel.attributedText = attributedString;
        statusViewHeight = 32.0;
        [self.cancelChatButton setTitle:@"取消私聊" forState:UIControlStateNormal];
    }
    else {
        [self showProgressHUDWithText:@"私聊已取消"];
    }
    [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@(statusViewHeight));
    }];
    
    [self updateCurrentDataSource];
    [self.tableView reloadData];
    [self scrollToTheEndTableView];
}

- (void)startPrivateChatWithTargetUser:(BJLUser *)targetUser {
    [self updateChatStatus:BJLChatStatus_private withTargetUser:targetUser];
    if (self.changeChatStatusCallback) {
        self.changeChatStatusCallback(BJLChatStatus_private, targetUser);
    }
}

- (void)cancelPrivateChat {
    if (self.chatStatus == BJLChatStatus_default) {
        // 取消只看老师/助教
        [self startOnlyShowTeacherOrAsisstantMessgae:NO];
    }
    else {
        // 取消私聊
        [self updateChatStatus:BJLChatStatus_default withTargetUser:nil];
    }
    
    if (self.changeChatStatusCallback) {
        self.changeChatStatusCallback(BJLChatStatus_default, nil);
    }
}

- (void)startOnlyShowTeacherOrAsisstantMessgae:(BOOL)show {
    self.onlyShowTeacherOrAssistant = show;
    CGFloat statusViewHeight = 0.0;
    if (self.chatStatus == BJLChatStatus_default && show) {
        self.currentDataSource = [self.whisperMessageDict bjl_objectForKey:self.targetUser.number class:[NSMutableArray class]];
        self.chatStatusLabel.text = [NSString stringWithFormat:@"已开启只看老师/助教"];
        statusViewHeight = 36.0;
        [self.cancelChatButton setTitle:@"取消" forState:UIControlStateNormal];
    }

    [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@(statusViewHeight));
    }];

    [self updateCurrentDataSource];
    [self.tableView reloadData];
    [self scrollToTheEndTableView];
}

#pragma mark - dataSource

// 整体更新数据源
- (void)updateCurrentDataSource {
    // !!!: 私聊消息在不同的聊天状态下样式不同，在切换前需要清除高度缓存
    [self.tableView bjl_clearHeightCaches];
    
    // 切换数据源时清空
    if (self.chatStatus == BJLChatStatus_private) {
        self.currentDataSource = [self.whisperMessageDict bjl_objectForKey:self.targetUser.number class:[NSMutableArray class]] ?: [NSMutableArray array];
        [self.whisperMessageDict bjl_setObject:self.currentDataSource
                                        forKey:self.targetUser.number];
    }
    else {
        if (self.onlyShowTeacherOrAssistant) {
            self.currentDataSource = (NSMutableArray<id> *)self.teacherOrAssistantMessages;
        }
        else {
            self.currentDataSource = self.allMessages;
        }
    }
}

// 清空数据源
- (void)clearDataSource {
    [self.unreadMessages removeAllObjects];
    [self.imageMessages removeAllObjects];
    self.unreadMessagesCount = [self.unreadMessages count];
    [self.allMessages removeAllObjects];
    [self.whisperMessageDict removeAllObjects];
    [self.teacherOrAssistantMessages removeAllObjects];
    [self.tableView bjl_clearHeightCaches]; //清除高度缓存
}

- (void)updateDataSourceWithRevokeMessageID:(NSString *)messageID {
    BJLMessage *targetMessage = nil;
    for (BJLMessage *message in [self.allMessages copy]) {
        if ([message isKindOfClass:[BJLMessage class]] && message && [message.ID isEqualToString:messageID]) {
            [self.allMessages bjl_removeObject:message];
            targetMessage = message;
            break;
        }
    }
    [self.teacherOrAssistantMessages bjl_removeObject:targetMessage];
    NSMutableArray<BJLMessage *> *whisperMessage = [[self.whisperMessageDict bjl_arrayForKey:targetMessage.toUser.number] mutableCopy];
    [whisperMessage bjl_removeObject:targetMessage];
    [self.whisperMessageDict bjl_setObject:whisperMessage forKey:targetMessage.toUser.number];
    [self updateCurrentDataSource];
}

// 增量更新 task
- (void)addTaskToCurrentDataSource:(BJLChatUploadingTask *)task {
    if (!task || ![task isKindOfClass:[BJLChatUploadingTask class]]) {
        return;
    }
    
    [self.currentDataSource bjl_addObject:task];
    
    if (self.chatStatus == BJLChatStatus_private) {
        [self.allMessages bjl_addObject:task];
    }
    [self.tableView reloadData];
    [self scrollToTheEndTableView];
}

// message 替换 task
- (void)replaceTask:(BJLChatUploadingTask *)task withMessage:(BJLMessage *)message {
    NSInteger index = [self.currentDataSource indexOfObject:task];
    [self.currentDataSource bjl_replaceObjectAtIndex:index withObject:message];
    if (self.chatStatus == BJLChatStatus_private) {
        // !!!: 私聊状态下，allMessages 也需要更新
        NSInteger indexInAll  = [self.allMessages indexOfObject:task];
        [self.allMessages bjl_replaceObjectAtIndex:indexInAll withObject:message];
    }
    [self.tableView reloadData];
}

// 增量更新 messages
- (void)addMessageToCurrentDataSource:(BJLMessage *)message targetUserNumber:(nullable NSString *)targetUserNumber{
    [self.allMessages bjl_addObject:message];
    if (targetUserNumber.length > 0) {
        // 私聊消息
        NSMutableArray *whisperMessages = [self.whisperMessageDict bjl_objectForKey:targetUserNumber class:[NSMutableArray class]] ?: [NSMutableArray array];
        [whisperMessages bjl_addObject:message];
        [self.whisperMessageDict bjl_setObject:whisperMessages
                                        forKey:targetUserNumber];
    }
}

#pragma mark - <UIContentContainer>

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    NSLog(@"%@ willTransitionToSizeClasses: %td-%td",
          NSStringFromClass([self class]), newCollection.horizontalSizeClass, newCollection.verticalSizeClass);
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [self.tableView reloadData]; // 更改聊天背景色
    } completion:nil];
}

#pragma mark - tableView

- (void)setUpTableView {
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    
    self.tableView.allowsSelection = YES;
    
    for (NSString *cellIdentifier in [BJLScChatCell allCellIdentifiers]) {
        [self.tableView registerClass:[BJLScChatCell class]
               forCellReuseIdentifier:cellIdentifier];
    }
    
    self.tableView.contentInset = bjl_set(self.tableView.contentInset, {
        set.top = /* set.bottom = */ BJLViewSpaceS;
    });
    self.tableView.scrollIndicatorInsets = bjl_set(self.tableView.contentInset, {
        set.top = /* set.bottom = */ BJLViewSpaceS;
    });
    
    self.tableView.estimatedRowHeight = 44;
    
    if (@available(iOS 11.0, *)) {
        self.tableView.insetsContentViewsToSafeArea = NO;
    }
}

- (void)scrollToTheEndTableView {
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    if ([self atTheBottomOfTableView]) {
        // 已在最底部
        return;
    }
    
    NSInteger section = 0;
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection:section];
    if (numberOfRows <= 0) {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:numberOfRows - 1
                                                inSection:section];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:NO];
}

- (BOOL)atTheTopOfTableView {
    CGFloat contentOffsetY = self.tableView.contentOffset.y;
    CGFloat top = self.tableView.contentInset.top;
    CGFloat topOffset = contentOffsetY + top;
    return topOffset >= 0.0 + BJLViewSpaceS;
}

- (BOOL)atTheBottomOfTableView {
    CGFloat contentOffsetY = self.tableView.contentOffset.y;
    CGFloat bottom = self.tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(self.tableView.frame);
    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    return bottomOffset >= 0.0 - BJLViewSpaceS;
}

- (NSString *)keyWithIndexPath:(NSIndexPath *)indexPath message:(BJLMessage *)message taskMessage:(BJLChatUploadingTask *)task {
    NSString *key = @"";
    if (message) {
        key = [NSString stringWithFormat:@"%@-%@-%f", message.ID, message.fromUser.ID, message.timeInterval];
    }
    else if (task) {
        key = [NSString stringWithFormat:@"task:%@", task.imageFile.filePath];
    }
    return key;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.currentDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLMessage *message = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLMessage);
    BJLChatUploadingTask *task = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLChatUploadingTask);
    if (message) {
        NSString *cellIdentifier = [BJLScChatCell cellIdentifierForMessageType:message.type
                                                                 hasTranslation:(!!message.translation.length)];
        BJLScChatCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                               forIndexPath:indexPath];
        
        BOOL isSender = self.room.loginUser.ID.length && [self.room.loginUser.ID isEqualToString:message.fromUser.ID];
        [cell updateWithMessage:message
                  fromLoginUser:[message.fromUser.number isEqualToString:self.room.loginUser.number]
                     chatStatus:self.chatStatus
                       isSender:isSender];
        bjl_weakify(self);
        cell.updateConstraintsCallback = cell.updateConstraintsCallback ?: ^(BJLScChatCell * _Nullable cell) {
            bjl_strongify(self);
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if (indexPath) {
                BOOL wasAtTheBottomOfTableView = [self atTheBottomOfTableView];
                [self.tableView bjl_clearHeightCachesWithKey:[self keyWithIndexPath:indexPath message:message taskMessage:task]];
                // 使用 reloadRowsAtIndexPaths 可能会因为当前改变了数据源而崩溃
                [self.tableView reloadData];
                if (wasAtTheBottomOfTableView) {
                    [self scrollToTheEndTableView];
                }
            }
        };
        cell.linkURLCallback = cell.linkURLCallback ?: ^BOOL(BJLScChatCell * _Nullable cell, NSURL * _Nonnull url) {
            bjl_strongify(self);
            return [self openURL:url];
        };
        
        // 聊天菜单
        cell.longPressCallback = cell.longPressCallback ?: ^(BJLMessage *message, UIImage * _Nullable image, CGPoint pointInCell) {
            bjl_strongify(self);
            if (message) {
                [self showOperatorViewWithMessage:message
                                            point:[self.view convertPoint:pointInCell fromView:cell]
                                            image:image];
            }
        };
        
        [cell setUserSelectCallback:^(BJLScChatCell * _Nullable cell) {
            bjl_strongify(self);
            if (self.chatStatus == BJLChatStatus_private) {
                return ;
            }
            
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            BJLMessage *message = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLMessage);
            BJLUser *user = message.fromUser;
            CGPoint point = [self.view convertPoint:cell.iconImageView.center fromView:cell.iconImageView.superview];
            if (self.userSelectCallback) {
                self.userSelectCallback(user, point);
            }
        }];
        
        [cell setImageSelectCallback:^(BJLScChatCell * _Nullable cell) {
            bjl_strongify(self);
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            BJLMessage *message = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLMessage);
            if (message && message.type == BJLMessageType_image) {
                if (self.showImageViewCallback) self.showImageViewCallback(message, self.imageMessages, NO);
            }
        }];
        return cell;
    }
    else { // if task
        NSString *cellIdentifier = [BJLScChatCell cellIdentifierForUploadingImage];
        BJLScChatCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                               forIndexPath:indexPath];
        if (task) {
            [cell updateWithUploadingTask:task
                               chatStatus:self.chatStatus
                                 fromUser:self.room.loginUser];
        }
        bjl_weakify(self);
        cell.retryUploadingCallback = cell.retryUploadingCallback ?: ^(BJLScChatCell * _Nullable cell) {
            bjl_strongify(self);
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            BJLChatUploadingTask *uploadingTask = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLChatUploadingTask);
            if (uploadingTask.error) {
                if (!uploadingTask.result) {
                    [uploadingTask upload];
                }
                else {
                    [self sendMessageWithUploadingTask:uploadingTask];
                }
            }
        };
        return cell;
    }
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLMessage *message = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLMessage);
    BJLChatUploadingTask *task = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLChatUploadingTask);
    
    NSString *key = [self keyWithIndexPath:indexPath message:message taskMessage:task];
    NSString *identifier;
    void (^configuration)(BJLScChatCell *cell); //用于计算 cell 高度的设置
    if (message) {
        identifier = [BJLScChatCell cellIdentifierForMessageType:message.type
                                                   hasTranslation:(!!message.translation.length)];
        bjl_weakify(self);
        configuration = ^(BJLScChatCell *cell) {
            bjl_strongify(self);
            cell.bjl_autoSizing = YES;
            BOOL isSender = self.room.loginUser.ID.length && [self.room.loginUser.ID isEqualToString:message.fromUser.ID];
            [cell updateWithMessage:message
                      fromLoginUser:[message.fromUser.number isEqualToString:self.room.loginUser.number]
                         chatStatus:self.chatStatus
                           isSender:isSender];
        };
    }
    else if (task) {
        identifier = [BJLScChatCell cellIdentifierForUploadingImage];
        bjl_weakify(self);
        configuration = ^(BJLScChatCell *cell) {
            bjl_strongify(self);
            cell.bjl_autoSizing = YES;
            [cell updateWithUploadingTask:task
                               chatStatus:self.chatStatus
                                 fromUser:self.room.loginUser];
        };
    }
    return [tableView bjl_cellHeightWithKey:key identifier:identifier configuration:configuration];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    if (self.unreadMessagesCount
        && [self atTheBottomOfTableView]) {
        [self loadUnreadMessages];
        // NO [self scrollToTheEndOf...];
    }
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - sticky

- (BOOL)openURL:(NSURL *)url {
    BOOL shouldOpen = NO;
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        if (@available(iOS 9.0, *)) {
            SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
            if (@available(iOS 13.0, *)) {
                safari.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
            }
#endif
            if (self.presentedViewController) {
                [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
            }
            [self bjl_presentFullScreenViewController:safari animated:YES completion:nil];
        }
        else {
            shouldOpen = YES;
        }
    }
    else if ([scheme hasPrefix:@"bjhl"]) {
        shouldOpen = YES;
    }
    else {
        UIAlertController *alert = [UIAlertController
                                    bjl_lightAlertControllerWithTitle:@"不支持打开此链接"
                                    message:nil
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert bjl_addActionWithTitle:@"知道了"
                                style:UIAlertActionStyleCancel
                              handler:nil];
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self presentViewController:alert animated:YES completion:nil];
    }
    return shouldOpen;
}

- (void)udpateStickyMessageView {
    BJLMessage *message = self.room.chatVM.stickyMessage;
    self.stickyMessageView.hidden = message ? NO : YES;
    
    // 缩略展示置顶消息
    if (message) {
        [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
            [self.chatStatusTopConstraint uninstall];
            self.chatStatusTopConstraint = make.top.equalTo(self.stickyMessageView.bjl_bottom).constraint;
        }];
    }
    else {// 无置顶消息
        [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
            [self.chatStatusTopConstraint uninstall];
            self.chatStatusTopConstraint = make.top.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view).constraint;
        }];
    }
    [self.stickyMessageView updateStickyMessage:message];
}

#pragma mark - getters

- (BOOL)is1V1Class {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return self.room.roomInfo.roomType == BJLRoomType_1v1Class || self.room.roomInfo.roomType == BJLRoomType_1to1;
#pragma clang diagnostic pop
}

- (NSMutableDictionary<NSString *, NSMutableArray *> *)whisperMessageDict {
    if (!_whisperMessageDict) {
        _whisperMessageDict = [[NSMutableDictionary alloc] init];
    }
    return _whisperMessageDict;
}

- (NSMutableArray <BJLMessage *> *)teacherOrAssistantMessages {
    if (!_teacherOrAssistantMessages) {
        _teacherOrAssistantMessages = [NSMutableArray new];
    }
    return _teacherOrAssistantMessages;
}

@end

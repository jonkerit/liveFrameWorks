//
//  BJLIcChatViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/10.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJLAuthorization.h>
#import <BJLiveBase/UITableView+BJLHeightCache.h>
#import <SafariServices/SafariServices.h>

#import "BJLIcChatViewController.h"
#import "BJLIcAppearance.h"
#import "BJLIcChatTableViewCell.h"
#import "BJL_iCloudLoading.h"
#import "BJLEmoticonKeyboardView.h"
#import "BJLIcChatOperatorView.h"
#import "BJLUserInAndOutMessage.h"
#import "BJLIcUserInAndOutCell.h"

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const IcTranslateRequestTimeout = 5.0; //聊天翻译超时时间

@interface BJLIcChatViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverPresentationControllerDelegate, QBImagePickerControllerDelegate_iCloudLoading>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, nullable) NSString *text;
@property (nonatomic) NSMutableArray<id/*BJLMessage * | BJLUserInAndOutMessage */> *messages;
@property (nonatomic) NSMutableArray<BJLMessage *> *imageMessages;
@property (nonatomic) NSMutableArray<BJLMessage *> *unreadMessages;
@property (nonatomic) UIViewController *emoticonViewController;
@property (nonatomic) NSMutableArray<BJLUserInAndOutMessage *> *userInAndOutmessages;

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *unreadMessagesTipButton;
@property (nonatomic) UIButton *forbidChatButton;
@property (nonatomic) UIButton *hideBubbleButton;
@property (nonatomic) UIButton *chatInputEmoticonButton;
@property (nonatomic) UIButton *chatInputTextButton;
@property (nonatomic) UIButton *chatInputImageButton;

/** 翻译*/
@property (nonatomic) NSMutableDictionary <NSString *, BJLMessage *> *currentTranslateCachesDict;
@property (nonatomic) NSMutableDictionary <NSString *, NSNumber *> *translatedMessageSendTimes;
@property (nonatomic, nullable) NSTimer *sendTimeRecordTimer;
@property (nonatomic) UIViewController *optionViewController;

@end

@implementation BJLIcChatViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.messages = [NSMutableArray new];
        self.imageMessages = [NSMutableArray new];
        self.unreadMessages = [NSMutableArray new];
        self.translatedMessageSendTimes = [NSMutableDictionary new];
        self.currentTranslateCachesDict = [NSMutableDictionary new];
        self.userInAndOutmessages = [NSMutableArray new];

        [self makeObserving];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviewsAndConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.backgroundView bjlic_drawRectCorners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(5.0, 5.0)];
    [self.backgroundView bjlic_drawBorderWidth:1.0 borderColor:[UIColor colorWithWhite:1.0 alpha:0.1] corners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(5.0, 5.0)];
    
    // 需要将视图未显示时时没有刷新的数据刷新
    [self.tableView reloadData];
    [self scrollToTheEndTableView];
    self.titleLabel.text = [NSString stringWithFormat:@"聊天(%lu人)", (long)self.room.onlineUsersVM.onlineUsers.count];
    self.forbidChatButton.selected = self.room.chatVM.forbidAll;
}

- (void)dealloc {
    [self.sendTimeRecordTimer invalidate];
    self.sendTimeRecordTimer = nil;
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
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
        label.font = [UIFont systemFontOfSize:14.0];
        label.text = [NSString stringWithFormat:@"聊天(%lu人)", (long)self.room.onlineUsersVM.onlineUsers.count];
        label;
    });
    [self.view addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        make.top.equalTo(self.view);
        make.height.greaterThanOrEqualTo(@16.0);
        make.height.equalTo(@32.0).priorityHigh();
    }];
    
    // close
    UIButton *closeButton = ({
        UIButton *button = [BJLImageButton new];
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
    UIView *singleLine = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        // shadow
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.2;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
        view.layer.shadowRadius = 10.0;
        view;
    });
    [self.view addSubview:singleLine];
    // 因为设置了不裁切, 所以左右在设置约束的时候减少 1.0, 使得显示时不会到达边界
    [singleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view).offset(1.0);
        make.right.equalTo(self.view).offset(-1.0);
        make.top.equalTo(self.titleLabel.bjl_bottom);
        make.height.equalTo(@(1.0));
    }];
    
    // table view
    [self.tableView removeFromSuperview];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    self.tableView.backgroundColor = [UIColor clearColor];
    for (NSString *identifier in [BJLIcChatTableViewCell allCellIdentifiers]) {
        [self.tableView registerClass:[BJLIcChatTableViewCell class] forCellReuseIdentifier:identifier];
    }
    for (NSString *identifier in [BJLIcUserInAndOutCell allCellIdentifiers]) {
        [self.tableView registerClass:[BJLIcUserInAndOutCell class] forCellReuseIdentifier:identifier];
    }

    [self.view addSubview:self.tableView];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(singleLine.bjl_bottom);
        make.left.right.equalTo(self.view);
        make.height.equalTo(self.view).multipliedBy(0.7).priorityHigh();
        make.height.greaterThanOrEqualTo(self.view).multipliedBy(0.4);
    }];
    
    self.unreadMessagesTipButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 4.0;
        button.hidden = YES;
        button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.contentEdgeInsets = UIEdgeInsetsMake(0, [BJLIcAppearance sharedAppearance].chatViewSmallSpace, 0, [BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        [button setTitle:@"有新消息" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(scrollToTheEndTableView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.unreadMessagesTipButton];
    [self.unreadMessagesTipButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-[BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        make.bottom.equalTo(self.tableView);
        make.height.greaterThanOrEqualTo(@16.0);
        make.height.equalTo(@24.0).priorityHigh();
    }];
    
    self.forbidChatButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        button.hidden = self.room.loginUser.isStudent;
        button.titleEdgeInsets = UIEdgeInsetsMake(0, [BJLIcAppearance sharedAppearance].chatViewSmallSpace, 0, 0);
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, [BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_chat_checkbox_normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_chat_checkbox_selected"] forState:UIControlStateSelected];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"禁止聊天" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(forbidChat:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button;
    });
    [self.view addSubview:self.forbidChatButton];
    [self.forbidChatButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        make.top.equalTo(self.unreadMessagesTipButton.bjl_bottom).offset([BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        make.height.equalTo(@16.0);
        make.width.equalTo(@80.0);
    }];
    
    self.hideBubbleButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        button.hidden = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"不显示气泡" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button;
    });
    [self.view addSubview:self.hideBubbleButton];
    [self.hideBubbleButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.greaterThanOrEqualTo(self.forbidChatButton.bjl_right);
        make.right.equalTo(self.view).offset(-[BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        make.top.equalTo(self.unreadMessagesTipButton.bjl_bottom).offset([BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        make.height.equalTo(@16.0);
    }];
    
    UIView *chatInputView = ({
        UIView *view = [UIView new];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 8.0;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor bjl_colorWithHexString:@"#979797" alpha:1.0].CGColor;
        view;
    });
    [self.view addSubview:chatInputView];
    [chatInputView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        if (self.room.loginUser.isStudent) {
            make.top.equalTo(self.tableView.bjl_bottom).offset([BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        }
        else {
            make.top.equalTo(self.forbidChatButton.bjl_bottom).offset([BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        }
        make.left.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        make.bottom.right.equalTo(self.view).offset(-[BJLIcAppearance sharedAppearance].chatViewLargeSpace);
        make.height.greaterThanOrEqualTo(@16.0);
        make.height.equalTo(@44.0).priorityHigh();
    }];
    
    self.chatInputEmoticonButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_chat_emoji_normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_chat_emoji_selected"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(showEmoticonView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [chatInputView addSubview:self.chatInputEmoticonButton];
    [self.chatInputEmoticonButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.bottom.equalTo(chatInputView);
        make.height.equalTo(self.chatInputEmoticonButton.bjl_width);
    }];
    
    self.chatInputImageButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_chat_image_normal"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(chooseImagePickerSourceTypeFromButton:) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [chatInputView addSubview:self.chatInputImageButton];
    [self.chatInputImageButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.right.equalTo(chatInputView);
        make.width.equalTo(self.chatInputImageButton.bjl_height);
    }];
    
    self.chatInputTextButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        button.titleLabel.lineBreakMode = NSLineBreakByClipping;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"点击这里输入最多140个字" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#9D9D9E" alpha:0.5] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showChatInputViewController) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [chatInputView addSubview:self.chatInputTextButton];
    [self.chatInputTextButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.equalTo(chatInputView);
        make.left.equalTo(self.chatInputEmoticonButton.bjl_right);
        make.right.equalTo(self.chatInputImageButton.bjl_left);
    }];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, receivedMessagesDidOverwrite:)
             observer:^BOOL(NSArray<BJLMessage *> * _Nullable messages) {
                 bjl_strongify(self);
                 if (messages.count) {
                     [self.messages removeAllObjects];
                     [self.imageMessages removeAllObjects];
                     [self.unreadMessages removeAllObjects];
                     if (messages.count > 0) {
                         [self.messages addObjectsFromArray:messages];
                         [self updateImageMessagesWithMessages:messages];
                     }
                     
                     if (self.userInAndOutmessages.count > 0) {
                         NSMutableArray *userInAndOutmessages = [NSMutableArray new];
                         for (BJLUserInAndOutMessage *userMessage in self.userInAndOutmessages) {
                             NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                             if (now - userMessage.timeInterval <= 60 && userMessage) {
                                 [userInAndOutmessages addObject:userMessage];
                             }
                         }
                         self.userInAndOutmessages = [userInAndOutmessages mutableCopy];
                         [self.messages addObjectsFromArray:self.userInAndOutmessages];
                     }
                     
                     if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                         return YES;
                     }
                     [self.tableView bjl_clearHeightCaches];
                     [self.tableView reloadData];
                     [self scrollToTheEndTableView];
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didReceiveMessages:)
             observer:^BOOL(NSArray<BJLMessage *> *messages) {
                 bjl_strongify(self);
                 if (!messages.count) {
                     return YES;
                 }
                if (messages.count) {
                    [self.messages addObjectsFromArray:messages];
                    [self updateImageMessagesWithMessages:messages];
                }
                 
                 BOOL wasAtTheBottomOfTableView = [self atTheBottomOfTableView];
                 BJLMessage *lastMessage = messages.lastObject;
                 
                 // 收到未读消息的回调
                 if (![lastMessage.fromUser.number isEqualToString:self.room.loginUser.number]) {
                     [self.unreadMessages addObjectsFromArray:messages];
                     if (self.receiveUnreadMessageCallback) {
                         self.receiveUnreadMessageCallback(self.unreadMessages);
                     }
                 }
                 
                 // 视图未隐藏时,刷新UI
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 
                 // 滑动到底部
                 if ([lastMessage.fromUser.number isEqualToString:self.room.loginUser.number]) {
                     [self scrollToTheEndTableView];
                 }
                 else {
                     if (wasAtTheBottomOfTableView) {
                         [self scrollToTheEndTableView];
                     }
                     else {
                         self.unreadMessagesTipButton.hidden = NO;
                     }
                 }
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

    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.titleLabel.text = [NSString stringWithFormat:@"聊天(%lu人)", (long)self.room.onlineUsersVM.onlineUsers.count];
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidAll)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.forbidChatButton.selected = self.room.chatVM.forbidAll;
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidEnter:)
             observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        // 不提示自己进出的信息
        if ([user.ID isEqualToString:self.room.loginUser.ID]) {
            return YES;
        }

        BJLUserInAndOutMessage *message = [[BJLUserInAndOutMessage alloc] initWithUserIn:user];
        if (message) {
            [self.userInAndOutmessages addObject:message];
            [self.messages addObject:message];
            
            BOOL wasAtTheBottomOfTableView = [self atTheBottomOfTableView];

            // 视图未隐藏时,刷新UI
            if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                return YES;
            }
            [self.tableView reloadData];
            
            if (wasAtTheBottomOfTableView) {
                [self scrollToTheEndTableView];
            }
        }
        
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidExit:)
             observer:^BOOL(BJLUser *now) {
        bjl_strongify(self);
        // 不提示自己进出的信息
        if ([now.ID isEqualToString:self.room.loginUser.ID]) {
            return YES;
        }
        
        BJLUserInAndOutMessage *message = [[BJLUserInAndOutMessage alloc] initWithUserOut:now];
        if (message) {
            [self.userInAndOutmessages addObject:message];
            [self.messages addObject:message];
            
            BOOL wasAtTheBottomOfTableView = [self atTheBottomOfTableView];

            // 视图未隐藏时,刷新UI
            if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                return YES;
            }
            [self.tableView reloadData];
            
            if (wasAtTheBottomOfTableView) {
                [self scrollToTheEndTableView];
            }
        }
        return YES;
    }];
}

#pragma mark - actions

- (void)hide {
    if (self.closeCallback) {
        self.closeCallback();
    }
}

- (void)forbidChat:(UIButton *)button {
    if (self.forbidChatCallback) {
        // 成功开关才改变button的状态
        button.selected = self.forbidChatCallback(!button.isSelected) ? !button.isSelected : button.isSelected;
    }
}

- (void)scrollToTheEndTableView {
    if (!self.tableView
        || self.tableView.hidden) {
        return;
    }
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    if ([self atTheBottomOfTableView]) {
        // 已在最底部
        return;
    }
    
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
    if (numberOfRows <= 0) {
        return;
    }
    self.unreadMessagesTipButton.hidden = YES;
    [self.unreadMessages removeAllObjects];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:numberOfRows - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)sendText:(NSString *)text {
    if (text.length) {
        self.text = text;
        if ([[text substringFromIndex:text.length - 1] isEqualToString:@"\n"]) {
            self.text = [text substringToIndex:text.length - 1];
            [self sendTextMessage];
        }
        else {
            [self.chatInputTextButton setTitle:text forState:UIControlStateNormal];
            [self.chatInputTextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            [self.chatInputImageButton removeTarget:self action:@selector(chooseImagePickerSourceTypeFromButton:) forControlEvents:UIControlEventTouchUpInside];
            [self.chatInputImageButton setImage:[UIImage bjlic_imageNamed:@"bjl_chat_send"] forState:UIControlStateNormal];
            [self.chatInputImageButton addTarget:self action:@selector(sendTextMessage) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    else {
        [self clearChatInputView];
    }
}

- (void)sendTextMessage {
    // 如果是超过最大长度的文本，裁剪后发送，确保能够发送出去
    if (self.text.length > BJLTextMaxLength_chat) {
        self.text = [self.text substringToIndex:NSMaxRange([self.text rangeOfComposedCharacterSequenceAtIndex:BJLTextMaxLength_chat])];
    }
    [self.room.chatVM sendMessage:self.text];
    [self clearChatInputView];
}

- (void)updateDataSourceWithRevokeMessageID:(NSString *)messageID {
    BJLMessage *targetMessage = nil;
    for (BJLMessage *message in [self.messages copy]) {
        if ([message isKindOfClass:[BJLMessage class]] && message && [message.ID isEqualToString:messageID]) {
            [self.messages bjl_removeObject:message];
            targetMessage = message;
            break;
        }
    }
    if (targetMessage.type == BJLMessageType_image) {
            for (BJLMessage *message in [self.imageMessages copy]) {
            if (message && [message.ID isEqualToString:messageID]) {
                [self.imageMessages bjl_removeObject:message];
                break;
            }
        }
    }
    [self.unreadMessages bjl_removeObject:targetMessage];
}

- (void)clearChatInputView {
    self.text = nil;
    [self.chatInputTextButton setTitle:@"点击这里输入最多140个字" forState:UIControlStateNormal];
    [self.chatInputTextButton setTitleColor:[UIColor bjl_colorWithHexString:@"#9D9D9E" alpha:0.5] forState:UIControlStateNormal];
    [self.chatInputImageButton removeTarget:self action:@selector(sendTextMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.chatInputImageButton setTitle:nil forState:UIControlStateNormal];
    [self.chatInputImageButton setImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_image_normal"] forState:UIControlStateNormal];
    [self.chatInputImageButton addTarget:self action:@selector(chooseImagePickerSourceTypeFromButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)sendImageMessage:(ICLImageFile *)imageFile {
    bjl_weakify(self);
    [self.room.chatVM uploadImageFile:imageFile.fileURL
                             progress:nil
                               finish:^(NSString * _Nullable imageURLString, BJLError * _Nullable error) {
                                 bjl_strongify(self);
                                 if (!error) {
                                     [self.room.chatVM sendMessageData:[BJLMessage messageDataWithImageURLString:imageURLString imageSize:imageFile.imageSize]];
                                 }
                             }];
}

- (void)sendEmoticonMessage:(BJLEmoticon *)emoticon {
    [self.room.chatVM sendMessageData:[BJLMessage messageDataWithEmoticonKey:emoticon.key]];
}

- (void)showChatInputViewController {
    if (![self isAllowedToSendMessage]) {
        return;
    }
    if (self.showChatInputViewCallback) {
        self.showChatInputViewCallback(self.text);
    }
}

- (void)showEmoticonView {
    if (![self isAllowedToSendMessage]) {
        return;
    }
    self.emoticonViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = CGSizeMake(375.0, 230.0);
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.backgroundColor = [UIColor whiteColor];
        viewController.popoverPresentationController.sourceView = self.chatInputEmoticonButton;
        viewController.popoverPresentationController.sourceRect = self.chatInputEmoticonButton.bounds;
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    BJLEmoticonKeyboardView *emoticonKeyboardView = [[BJLEmoticonKeyboardView alloc] initForIdiomPad:YES];
    emoticonKeyboardView.emoticons = [BJLEmoticon allEmoticons];
    [self.emoticonViewController.view addSubview:emoticonKeyboardView];
    [emoticonKeyboardView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.emoticonViewController.view.bjl_safeAreaLayoutGuide ?: self.emoticonViewController.view);
    }];
    bjl_weakify(self);
    [emoticonKeyboardView setSelectEmoticonCallback:^(BJLEmoticon * _Nonnull emoticon) {
        bjl_strongify(self);
        [self sendEmoticonMessage:emoticon];
        [self.emoticonViewController bjl_dismissAnimated:YES completion:^{
            bjl_strongify(self);
            self.chatInputEmoticonButton.selected = NO;
        }];
    }];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:self.emoticonViewController animated:YES completion:^{
        bjl_strongify(self);
        self.chatInputEmoticonButton.selected = YES;
    }];
}

- (void)updateImageMessagesWithMessages:(NSArray<BJLMessage *> *)messages {
    for (BJLMessage *message in [messages copy]) {
        if (message.type == BJLMessageType_image) {
            [self.imageMessages bjl_addObject:message];
        }
    }
}

#pragma mark - translate
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
    BJLIcRecallType recallType = BJLIcRecallTypeNone;
    if ([message.fromUser.number isEqualToString:self.room.loginUser.number]) {
        recallType = BJLIcRecallTypeNormal;
    }
    else if (self.room.loginUser.isTeacherOrAssistant) {
        recallType = BJLIcRecallTypeDelete;
    }
    
    NSInteger optionCount = 1;
    optionCount += needTranslate ? 1 : 0;
    optionCount += (recallType == BJLIcRecallTypeNone) ? 0 : 1;
    CGFloat height = 20.0 + optionCount * 40.0;
    CGFloat width = 64.0f;
    
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
    
    BJLIcChatOperatorView *optionView = [[BJLIcChatOperatorView alloc] initWithNeedTranslate:needTranslate recallType:recallType];
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
        if(message && message.type == BJLMessageType_text && message.text.length
           && !message.translation.length) {
            NSString *messageUUID = [self keyForMessgaetranslation:message];
            [self startSendTimeRecording:message messageUUID:messageUUID];
            [self.currentTranslateCachesDict bjl_setObject:message forKey:messageUUID];
            BJLError *error = [self.room.chatVM translateMessage:message
                                                     messageUUID:messageUUID
                                                   translateType:([self shouldTranslateToEn:message] ? BJLMessageTranslateTypeZHtoEN : BJLMessageTranslateTypeENtoZH)];
            if (error) {
                if(self.showErrorMessageCallback) {
                    self.showErrorMessageCallback((error.localizedFailureReason ?: error.localizedDescription));
                }
            }
        }
    }];
    
    [optionView setRecallMessageCallback:^(BOOL on) {
        bjl_strongify(self);
        [self hideOptionViewController];
        BJLError *error = [self.room.chatVM revokeMessage:message];
        if (error) {
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }
        else {
            [self updateDataSourceWithRevokeMessageID:message.ID];
            [self.tableView reloadData];
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
    
    if(!self.sendTimeRecordTimer || !self.sendTimeRecordTimer.isValid) {
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
    
    if(message && messageUUID) {
        [self recordSendTime:message messageUUID:messageUUID];
    }
}

//记录发送翻译信令的message 发送时间
- (void)recordSendTime:(BJLMessage *)message messageUUID:(NSString *)messageUUID{
    if(!message) {
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
        
        if(![sendTime isEqualToNumber:@(-1)]) {
            NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
            NSTimeInterval sentSeconds = round(currentTime - sendTime.doubleValue);
            
            //已经请求的时候大于 translateRequestTimeout ,则视为请求超时
            if(sentSeconds > IcTranslateRequestTimeout) {
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
    __block BJLMessage *cacheMessage = nil;
    NSArray *messageSendTimeKeys = [self.currentTranslateCachesDict allKeys];
    [messageSendTimeKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj && [obj isEqualToString:messageUUID] ) {
            cacheMessage = [self.currentTranslateCachesDict bjl_objectForKey:obj class:[BJLMessage class]];
            *stop = YES;
        }
    }];
    
    if(!cacheMessage) {
        return;
    }
    
    [self.currentTranslateCachesDict bjl_removeObjectForKey:messageUUID];
    [self.translatedMessageSendTimes removeObjectForKey:messageUUID];
    
    if(!translate.length) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showTranslationFailedMessage];
        });
        return;
    }
    [cacheMessage updateTranslationString:translate];
    
    NSUInteger index = [self.messages indexOfObject:cacheMessage];
    if (index == NSNotFound || self.messages.count <= 0) {
        return;
    }
    
    [self.tableView bjl_clearHeightCaches];
    [self.tableView reloadData];
}

- (void)showTranslationFailedMessage {
    NSArray  *languages = [NSLocale preferredLanguages];
    NSString *language = [languages objectAtIndex:0];
    if([language hasPrefix:@"zh-Hans"]) {
        if(self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"翻译失败");
        }
    }
    else {
        if(self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"Translate Fail!");
        }
    }
}

- (BOOL)shouldTranslateToEn:(BJLMessage *)message {
    if(!message || !message.text.length)
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


#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (CGRectGetWidth(tableView.frame) >= CGRectGetWidth([UIScreen mainScreen].bounds) || CGRectGetWidth(tableView.frame) <= 0) {
        return 0;
    }
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLMessage *message = bjl_as([self.messages bjl_objectAtIndex:indexPath.row], BJLMessage);
    BJLUserInAndOutMessage *userMessage = bjl_as([self.messages bjl_objectAtIndex:indexPath.row], BJLUserInAndOutMessage);
    if (message) {
        NSString *identifier = [self identifierWithMessage:message];
        BJLIcChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        [cell updateWithMessage:message cellWidth:CGRectGetWidth(self.tableView.bounds)];
        bjl_weakify(self);
        cell.showChatDetailCallback = cell.showChatDetailCallback ?: ^(BJLMessage * _Nonnull message) {
            bjl_strongify(self);
            if (self.showChatDetailViewCallback) {
                self.showChatDetailViewCallback(message, self.imageMessages);
            }
        };
        bjl_weakify(cell);
        cell.longPressCallback = cell.longPressCallback ?: ^(BJLMessage * _Nonnull message, UIImage * _Nullable image, CGPoint pointInCell) {
            bjl_strongify(self, cell);
            if(message) {
                [self showOperatorViewWithMessage:message point:[self.view convertPoint:pointInCell fromView:cell] image:image];
            }
        };
        cell.updateConstraintsCallback = cell.updateConstraintsCallback ?: ^(BJLIcChatTableViewCell * _Nullable cell) {
            bjl_strongify(self);
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if (indexPath) {
                BOOL wasAtTheBottomOfTableView = [self atTheBottomOfTableView];
                [self.tableView bjl_clearHeightCachesWithKey:[self keyWithIndexPath:indexPath message:message userMessage:userMessage]];
                [self.tableView reloadData];
                if (wasAtTheBottomOfTableView) {
                    [self scrollToTheEndTableView];
                }
            }
        };
        cell.linkURLCallback = cell.linkURLCallback ?: ^BOOL(BJLIcChatTableViewCell * _Nullable cell, NSURL * _Nonnull url) {
            bjl_strongify(self);
            BOOL shouldOpen = NO;
            NSString *scheme = url.scheme.lowercaseString;
            if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
                SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
                if (@available(iOS 13.0, *)) {
                    safari.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
                }
#endif
                if (self.presentedViewController) {
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                }
                [self presentViewController:safari animated:YES completion:nil];
            }
            else {
                if (self.showErrorMessageCallback) {
                    self.showErrorMessageCallback(@"不支持打开此链接");
                }
            }
            return shouldOpen;
        };
        return cell;
    }
    else {
        NSString *identifier = [self identifierWithUserMessage:userMessage];
        BJLIcUserInAndOutCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        [cell updateWithMessage:userMessage cellWidth:CGRectGetWidth(self.tableView.bounds)];
        return cell;
    }
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLMessage *message = bjl_as([self.messages bjl_objectAtIndex:indexPath.row], BJLMessage);
    BJLUserInAndOutMessage *userMessage = bjl_as([self.messages bjl_objectAtIndex:indexPath.row], BJLUserInAndOutMessage);

    NSString *key = [self keyWithIndexPath:indexPath message:message userMessage:userMessage];
    if (message){
        NSString *identifier = [self identifierWithMessage:message];
        bjl_weakify(self);
        CGFloat height = [tableView bjl_cellHeightWithKey:key identifier:identifier configuration:^(BJLIcChatTableViewCell *cell) {
            bjl_strongify(self);
            cell.bjl_autoSizing = YES;
            [cell updateWithMessage:message cellWidth:CGRectGetWidth(self.tableView.bounds)];
        }];
        return height;
    }
    else {
        bjl_weakify(self);
        NSString *identifier = [self identifierWithUserMessage:userMessage];
        CGFloat height = [tableView bjl_cellHeightWithKey:key identifier:identifier configuration:^(BJLIcUserInAndOutCell *cell) {
            bjl_strongify(self);
            cell.bjl_autoSizing = YES;
            [cell updateWithMessage:userMessage cellWidth:CGRectGetWidth(self.tableView.bounds)];
        }];
        return height;
    }
}

#pragma mark - wheel

- (NSString *)keyWithIndexPath:(NSIndexPath *)indexPath message:(BJLMessage *)message userMessage:(BJLUserInAndOutMessage *)userMessage {
    NSString *key = @"";
    if (message){
        key = [NSString stringWithFormat:@"%@-%@-%f", message.ID, message.fromUser.ID, message.timeInterval];
    }
    else if (userMessage) {
        key = [NSString stringWithFormat:@"%@-%f-%@", userMessage.fromUser.ID, userMessage.timeInterval, @(userMessage.isUserIn)];
    }
    return key;
}

- (NSString *)identifierWithMessage:(BJLMessage *)message {
    BOOL isSender = [message.fromUser.number isEqualToString:self.room.loginUser.number];
    NSString *identifier = BJLIcReceiveTextCellReuseIdentifier;
    switch (message.type) {
        case BJLMessageType_text:
            identifier = isSender ?
            ((!!message.translation.length) ? BJLIcSendTextAndTranslationCellReuseIdentifier: BJLIcSendTextCellReuseIdentifier) :
            ((!!message.translation.length) ? BJLIcReceiveTextAndTranslationCellReuseIdentifier: BJLIcReceiveTextCellReuseIdentifier);
            break;
            
        case BJLMessageType_image:
            identifier = isSender ? BJLIcSendImageCellReuseIdentifier : BJLIcReceiveImageCellReuseIdentifier;
            break;
            
        case BJLMessageType_emoticon:
            identifier = isSender ? BJLIcSendEmoticonCellReuseIdentifier : BJLIcReceiveEmoticonCellReuseIdentifier;
            break;
            
        default:
            break;
    }
    return identifier;
}

- (NSString *)identifierWithUserMessage:(BJLUserInAndOutMessage *)message {
    NSString *identifier = BJLIcUserInAndOutCellReuseIdentifier;
    NSInteger index = [self.userInAndOutmessages indexOfObject:message];
    
    BJLUserInAndOutMessage *lastMessage = [self.userInAndOutmessages bjl_objectAtIndex:index - 1];
    if (!lastMessage || (lastMessage && message.timeInterval - lastMessage.timeInterval > 60)) {
        identifier = BJLIcUserInAndOutWithTimeCellReuseIdentifier;
    }
    return identifier;
}

#pragma mark - image

- (void)chooseImagePickerSourceTypeFromButton:(UIButton *)button {
    if (![self isAllowedToSendMessage]) {
        return;
    }
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:button.currentTitle ?: @"发送图片"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [alert bjl_addActionWithTitle:@"拍照"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  [self chooseImageWithSourceType:sourceType];
                              }];
    }
    
    sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [alert bjl_addActionWithTitle:@"从相册中选取"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  [self chooseImageWithSourceType:sourceType];
                              }];
    }
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    
    alert.popoverPresentationController.sourceView = button;
    alert.popoverPresentationController.sourceRect = button.bounds;
    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)chooseImageWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        [BJLAuthorization checkCameraAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
            if (granted) {
                [self chooseImageWithCamera];
            }
            else if (alert) {
                if (self.presentedViewController) {
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                }
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
    else {
        [BJLAuthorization checkPhotosAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
            if (granted) {
                [self chooseImageWithFromPhotoLibrary];
            }
            else if (alert) {
                if (self.presentedViewController) {
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                }
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
}

- (void)chooseImageWithCamera {
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    imagePickerController.allowsEditing = NO;
    imagePickerController.delegate = self;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        imagePickerController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self bjl_presentFullScreenViewController:imagePickerController animated:YES completion:nil];
}

- (void)chooseImageWithFromPhotoLibrary {
    QBImagePickerController *imagePickerController = [QBImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.mediaType = QBImagePickerMediaTypeImage;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.showsNumberOfSelectedAssets = YES;
    imagePickerController.maximumNumberOfSelection = 1; // 1: 避免刷屏
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        imagePickerController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self bjl_presentFullScreenViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    bjl_weakify(self);
    [picker dismissViewControllerAnimated:YES completion:^{
        bjl_strongify(self);
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        UIImage *thumbnail = [image bjl_imageFillSize:BJLAspectFillSize([UIScreen mainScreen].bounds.size,
                                                                        image.size.width / image.size.height)
                                              enlarge:NO];
        NSString *mediaType = info[UIImagePickerControllerMediaType];
        NSError *error = nil;
        ICLImageFile *imageFile = [ICLImageFile imageFileWithImage:image
                                                         thumbnail:thumbnail
                                                         mediaType:mediaType
                                                             error:&error];
        if (!imageFile) {
            if(self.showErrorMessageCallback) {
                self.showErrorMessageCallback(@"照片获取出错");
            }
            return;
        }
        [self sendImageMessage:imageFile];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <QBImagePickerControllerDelegate>

- (void)qb_imagePickerController:(QBImagePickerController *)picker didFinishPickingAssets:(NSArray<PHAsset *> *)assets {
    [picker icl_loadImageFilesWithAssets:assets
                             contentMode:PHImageContentModeAspectFit
                              targetSize:CGSizeMake(BJLAliIMGMaxSize, BJLAliIMGMaxSize)
                           thumbnailSize:[UIScreen mainScreen].bounds.size]; // CGSizeZero
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <QBImagePickerControllerDelegate_iCloudLoading>

- (void)icl_imagePickerController:(QBImagePickerController *)picker
       didFinishLoadingImageFiles:(NSArray<ICLImageFile *> *)imageFiles {
    bjl_weakify(self);
    [picker dismissViewControllerAnimated:YES completion:^{
        bjl_strongify(self);
        [self sendImageMessage:imageFiles.firstObject];
    }];
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.chatInputEmoticonButton.selected = NO;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark -

- (BOOL)isAllowedToSendMessage {
    if (self.room.loginUser.isTeacher) {
        return YES;
    }
    if ( (self.room.loginUser.isStudent && self.room.chatVM.forbidAll)
        || (self.room.loginUser.isStudent && self.room.chatVM.forbidMyGroup)
        || self.room.chatVM.forbidMe) {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"禁言状态不能发送消息");
        }
        return NO;
    }
    return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    if (self.unreadMessages.count
        && [self atTheBottomOfTableView]) {
        [self.unreadMessages removeAllObjects];
        self.unreadMessagesTipButton.hidden = YES;
    }
}

- (BOOL)atTheBottomOfTableView {
    CGFloat contentOffsetY = self.tableView.contentOffset.y;
    CGFloat bottom = self.tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(self.tableView.frame);
    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    return bottomOffset >= 0.0 - [BJLIcAppearance sharedAppearance].chatCellMinUserInOutTextHeight;
}

@end

NS_ASSUME_NONNULL_END

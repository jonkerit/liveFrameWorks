//
//  BJLChatViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-02.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLHitTestView.h>
#import <BJLiveBase/UITableView+BJLHeightCache.h>
#import <SafariServices/SafariServices.h>

#import "BJLChatViewController.h"
#import "BJLChatViewController+recentMessages.h"
#import "BJLChatUploadingTask.h"
#import "BJLMessageCell.h"
#import "BJLMessageOperatorView.h"

NS_ASSUME_NONNULL_BEGIN

static const NSTimeInterval highlightingDelay = 5.0;
static const NSTimeInterval updateAlphaInterval = 0.2;
static const NSTimeInterval translateRequestTimeout = 5.0;

#pragma mark -

/**
 关于发送图片：
 1、每次只能选择一张图片，尽量避免同时上传多张图片引发的问题；
 2、前一张图片没上传完成时，允许选择另一张图片上传，这样体验稍好；
 3、上传图片与其它消息混在一起显示，不使用单独的 section 显示发送队列，避免上传多张图片时引发新消息不显示在底部、点击未读消息的滚动等问题；
 4、上传过程中收到消息显示在消息列表末尾，上传成功后不改变上传图片在列表中的位置，这可能会导致发送者与接收者看到的顺序不一致 —— 微信也是如此；
 5、图片的上传、发送完全并行，不保证发送、接收顺序，避免一个失败其它都无法发送、第一个上传很慢的上传完成后瞬间发送消息过多等问题，这与其它消息的处理保持一致；
 */
@interface BJLChatViewController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;

// 私聊
@property (nonatomic) BJLChatStatus chatStatus;
@property (nonatomic, nullable) BJLUser *targetUser;

@property (nonatomic) UIButton *unreadMessagesTipButton;
@property (nonatomic, readwrite) UIView *chatStatusView;
@property (nonatomic) UILabel *chatStatusLabel;

// NOTE: show sendingMessages in the second section
@property (nonatomic) NSMutableArray<id/* BJLMessage * || BJLChatUploadingTask * */> *allMessages, *currentDataSource;
@property (nonatomic) NSMutableDictionary<NSString *, NSMutableArray *> *whisperMessageDict;

@property (nonatomic) NSMutableArray<BJLMessage *> *unreadMessages, *unreadWhisperMessages, *teacherOrAsisstantMessages;/*, *sendingMessages*/
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) NSMutableDictionary<NSString *, UIImage *> *thumbnailForURLString;

// @property (nonatomic, copy) NSDictionary<NSString *, BJLEmoticon *> *allEmoticons;

@property (nonatomic, nullable) NSTimer *updateAlphaTimer;

@property (nonatomic) BOOL wasAtTheBottomOfTableView;

//只看老师/助教
@property (nonatomic) BOOL onlyShowTeacherOrAssistant;

// translation
@property (nonatomic) NSMutableDictionary <NSString *, BJLMessage *> *currentTranslateCachesDict;
@property (nonatomic) NSMutableDictionary <NSString *, NSNumber *> *translatedMessageSendTimes;
@property (nonatomic, nullable) NSTimer *sendTimeRecordTimer;
@property (nonatomic) UIViewController *optionViewController;

@end

@implementation BJLChatViewController

#pragma mark -

#pragma mark - lifecycle & <BJLRoomChildViewController>

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return nil;
}

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
        self->_messagesReceivingTimeInterval = [NSMutableArray new];
        
        self.thumbnailForURLString = [NSMutableDictionary new];
        self.translatedMessageSendTimes = [NSMutableDictionary new];
        self.currentTranslateCachesDict = [NSMutableDictionary new];
        
        self.alphaMin = 0.2;
        self.alphaMax = 1.0;
    }
    return self;
}

- (void)loadView {
    self.view = [BJLHitTestView viewWithFrame:[UIScreen mainScreen].bounds hitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        if ([hitView isKindOfClass:[UIButton class]]) {
            return hitView;
        }
        UITableViewCell *cell = [hitView bjl_closestViewOfClass:[UITableViewCell class] includeSelf:NO];
        if (cell && hitView != cell.contentView) {
            return hitView;
        }
        return nil;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self setUpSubviews];
    [self makeObserving];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.wasAtTheBottomOfTableView = [self atTheBottomOfTableView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.tableView.scrollIndicatorInsets = bjl_set(self.tableView.scrollIndicatorInsets, {
        CGFloat adjustment = CGRectGetWidth(self.view.frame) - BJLScrollIndicatorSize;
        set.left = - adjustment;
        set.right = adjustment;
    });
    
    if (self.wasAtTheBottomOfTableView && ![self atTheBottomOfTableView]) {
        [self scrollToTheEndTableView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self loadUnreadMessages];
    [self scrollToTheEndTableView];
    
    bjl_weakify(self);
    [self.updateAlphaTimer invalidate];
    self.updateAlphaTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:updateAlphaInterval repeats:YES block:^(NSTimer *timer) {
        bjl_strongify(self);
        [self updateAlphaForCellsWithAnimationDuration:updateAlphaInterval];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.updateAlphaTimer invalidate];
    self.updateAlphaTimer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.thumbnailForURLString removeAllObjects];
}

- (void)dealloc {
    [self.updateAlphaTimer invalidate];
    self.updateAlphaTimer = nil;
    
    [self.sendTimeRecordTimer invalidate];
    self.sendTimeRecordTimer = nil;

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - subviews

- (void)setUpSubviews {
    CGFloat margin = 15.0;
    
    // chatStatusView
    self.chatStatusView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#2CA1F8"];
        view.clipsToBounds = YES;
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 18.0;
        view;
    });
    [self.view addSubview:self.chatStatusView];
    [self.chatStatusView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view).offset(10.0);
        make.left.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view).offset(-18.0);
        make.right.lessThanOrEqualTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@(0.0));
    }];
    // cancelChatButton
    UIButton *cancelChatButton = ({
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(cancelPrivateChat) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.chatStatusView addSubview:cancelChatButton];
    [cancelChatButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.chatStatusView).offset(-margin);
        make.centerY.equalTo(self.chatStatusView);
    }];
    // chatStatusLabel
    self.chatStatusLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;
        label;
    });
    [self.chatStatusView addSubview:self.chatStatusLabel];
    [self.chatStatusLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view).offset(margin);
        make.centerY.equalTo(self.chatStatusView);
        make.right.equalTo(cancelChatButton.bjl_left).offset(-margin);
    }];
    
    // tableView
    [self setUpTableView];
    [self.tableView bjl_removeAllConstraints];
    [self.tableView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.chatStatusView.bjl_bottom);
        make.left.bottom.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
    }];
    
    // unreadMessage
    [self setUpUnreadMessagesTipButton];
}

#pragma mark - private

- (void)setUpUnreadMessagesTipButton {
    self.unreadMessagesTipButton = ({
        UIButton *button = [UIButton new];
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
        make.left.equalTo(self.view).offset(BJLScrollIndicatorSize);
        make.bottom.equalTo(self.view);
        CGFloat height = [BJLMessageCell estimatedRowHeightForMessageType:BJLMessageType_text];
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
    
    self.unreadMessagesTipButton.hidden = YES;
}

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
    [self updateReceivingTimeIntervalWithAllMessagesCount:self.currentDataSource.count];
}

- (void)startHighlighting {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(stopHighlighting)
                                               object:nil];
    _messagesHighlighting = YES;
    [self updateAlphaForCellsWithAnimationDuration:updateAlphaInterval];
}

- (void)stopHighlighting {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(stopHighlighting)
                                               object:nil];
    _messagesHighlighting = NO;
    [self updateAlphaForCellsWithAnimationDuration:updateAlphaInterval];
}

- (void)stopHighlightingWithDelay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(stopHighlighting)
                                               object:nil];
    [self performSelector:@selector(stopHighlighting)
               withObject:nil
               afterDelay:highlightingDelay];
}

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, receivedMessagesDidOverwrite:)
             observer:^BOOL(NSArray<BJLMessage *> * _Nullable messages) {
                 bjl_strongify(self);
                 
                 [self.unreadMessages removeAllObjects];
                 self.unreadMessagesCount = [self.unreadMessages count];
                 
                 [self clearDataSource]; // 清空群聊、私聊数据源 及 高度缓存
                 if (messages.count > 0) {
                     [self.allMessages addObjectsFromArray:messages];
                     
                     [messages enumerateObjectsUsingBlock:^(BJLMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                         if (obj.fromUser.isTeacherOrAssistant) {
                             [self.teacherOrAsisstantMessages bjl_addObject:obj];
                         }
                     }];
                 }
                 
                 [self updateCurrentDataSource];
                 [self scrollToTheEndTableView];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.chatVM, didReceiveMessages:)
             observer:^BOOL(NSArray<BJLMessage *> *messages) {
                 bjl_strongify(self);
                 
                 BOOL wasAtTheBottomOfTableView = [self atTheBottomOfTableView];
                 
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
                         if (shouldUpdateUnreadMessage) {
                             [self.unreadMessages bjl_addObject:message];
                             self.unreadMessagesCount = [self.unreadMessages count];
                         }
                         
                         // 更新来自老师/助教的消息
                         if (message.fromUser.isTeacherOrAssistant) {
                             [self.teacherOrAsisstantMessages bjl_addObject:message];
                         }
                         
                         // 添加 messgae
                         [self addMessageToCurrentDataSource:message targetUserNumber:targetUserNumber];
                     }
                 }
                 
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 
                 // 更新接收消息时间戳数组，必须先更新 dataSource
                 [self updateReceivingTimeIntervalWithAllMessagesCount:self.currentDataSource.count];
                 
                 // 滑动到底部
                 if ([messages.lastObject.fromUser.number isEqualToString:self.room.loginUser.number]
                     || wasAtTheBottomOfTableView) {
                     [self scrollToTheEndTableView];
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
            if (self.optionViewController) {
                [self hideOptionViewController];
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
    
    BJLMessageOperatorView *optionView = [[BJLMessageOperatorView alloc] initWithNeedTranslate:needTranslate needShowOnlyTeacherOrAssistant:needShowOnlyTeacherOrAssistant recallType:recallType canStickyMessage:NO];
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
    NSArray *messageSendTimeKeys = [self.currentTranslateCachesDict allKeys];
    [messageSendTimeKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
    [self startHighlighting];
    [self stopHighlightingWithDelay];
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

#pragma mark - chatStatus

- (void)updateChatStatus:(BJLChatStatus)chatStatus withTargetUser:(nullable BJLUser *)targetUser {
//    不管是切换到公聊or私聊，切换后， 都要清空只看老师/助教状态
    self.onlyShowTeacherOrAssistant = NO;

    self.chatStatus = chatStatus;
    self.targetUser = (chatStatus == BJLChatStatus_private)? targetUser : nil;
    
    CGFloat statusViewHeight = 0.0;
    if (chatStatus == BJLChatStatus_private) {
        self.currentDataSource = [self.whisperMessageDict bjl_objectForKey:self.targetUser.number class:[NSMutableArray class]];
        self.chatStatusLabel.text = [NSString stringWithFormat:@"正在和 %@ 私聊中...", targetUser.displayName];
        statusViewHeight = 36.0;
    }
    else {
        [self showProgressHUDWithText:@"私聊已取消"];
    }
    [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@(statusViewHeight));
    }];
    [self updateCurrentDataSource];
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
    }
    else {
        
    }
    [self.chatStatusView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@(statusViewHeight));
    }];
    [self updateCurrentDataSource];
    [self scrollToTheEndTableView];
}

#pragma mark - dataSource

// 整体更新数据源
- (void)updateCurrentDataSource {
    // !!!: 私聊消息在不同的聊天状态下样式不同，在切换前需要清除高度缓存
    [self.tableView bjl_clearHeightCaches];
    
    // 清空接收时间戳
    [self clearReceivingTimeInterval];
    
    // 切换数据源时清空
    if (self.chatStatus == BJLChatStatus_private) {
        self.currentDataSource = [self.whisperMessageDict bjl_objectForKey:self.targetUser.number class:[NSMutableArray class]] ?: [NSMutableArray array];
        [self.whisperMessageDict bjl_setObject:self.currentDataSource
                                        forKey:self.targetUser.number];
    }
    else {
        if (self.onlyShowTeacherOrAssistant) {
            self.currentDataSource = (NSMutableArray<id> *)self.teacherOrAsisstantMessages;
        }
        else {
            self.currentDataSource = self.allMessages;
        }
    }
    [self updateReceivingTimeIntervalWithAllMessagesCount:self.currentDataSource.count];
    [self.tableView reloadData];
}

// 清空数据源
- (void)clearDataSource {
    [self.allMessages removeAllObjects];
    [self.whisperMessageDict removeAllObjects];
    [self.teacherOrAsisstantMessages removeAllObjects];
    [self clearReceivingTimeInterval];
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
    [self.teacherOrAsisstantMessages bjl_removeObject:targetMessage];
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
    
    self.tableView.allowsSelection = YES;
    
    for (NSString *cellIdentifier in [BJLMessageCell allCellIdentifiers]) {
        [self.tableView registerClass:[BJLMessageCell class]
               forCellReuseIdentifier:cellIdentifier];
    }
    
    self.tableView.contentInset = bjl_set(self.tableView.contentInset, {
        set.top = /* set.bottom = */ BJLViewSpaceS;
    });
    self.tableView.scrollIndicatorInsets = bjl_set(self.tableView.contentInset, {
        set.top = /* set.bottom = */ BJLViewSpaceS;
    });
    
    self.tableView.estimatedRowHeight = [BJLMessageCell estimatedRowHeightForMessageType:BJLMessageType_text];
    
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
    BOOL isHorizontal = BJLIsHorizontalUI(self);
    
    if (message) {
        NSString *cellIdentifier = [BJLMessageCell cellIdentifierForMessageType:message.type
                                                                 hasTranslation:(!!message.translation.length)];
        BJLMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                               forIndexPath:indexPath];
        
        [cell updateWithMessage:message
                    placeholder:message.imageURLString ? [self.thumbnailForURLString objectForKey:message.imageURLString] : nil
                  fromLoginUser:[message.fromUser.number isEqualToString:self.room.loginUser.number]
                     chatStatus:self.chatStatus
                 tableViewWidth:CGRectGetWidth(self.tableView.bounds)
                   isHorizontal:isHorizontal
                           room:self.room];
        bjl_weakify(self);
        cell.updateConstraintsCallback = cell.updateConstraintsCallback ?: ^(BJLMessageCell * _Nullable cell) {
            bjl_strongify(self);
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if (indexPath) {
                BOOL wasAtTheBottomOfTableView = [self atTheBottomOfTableView];
                [self.tableView bjl_clearHeightCachesWithKey:[self keyWithIndexPath:indexPath message:message taskMessage:task]];
                [self.tableView reloadData];
                if (wasAtTheBottomOfTableView) {
                    [self scrollToTheEndTableView];
                }
            }
        };
        cell.linkURLCallback = cell.linkURLCallback ?: ^BOOL(BJLMessageCell * _Nullable cell, NSURL * _Nonnull url) {
            bjl_strongify(self);
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
        };
        
        // 私聊
        if (self.room.featureConfig.enableWhisper) {
            cell.startPrivateChatCallback = cell.startPrivateChatCallback ?: ^(BJLMessageCell * _Nullable cell){
                bjl_strongify(self);
                [self startHighlighting];
                [self stopHighlightingWithDelay];
                NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
                if (indexPath && self.chatStatus != BJLChatStatus_private) {
                    BJLMessage *message = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLMessage);
                    if (message) {
                        // 获取私聊对象
                        BJLUser *targetUser = ([message.fromUser.number isEqualToString:self.room.loginUser.number]
                                               ? message.toUser
                                               : message.fromUser);
                        /**
                         大班课老师/助教，可以与【任何人】相互发私聊消息
                         配置为仅组内可见，则组内助教可以向【组内在线学员]相互发私聊消息
                         配置为仅组间可见，则组内助教可以向【任意在线用户】相互发私聊消息
                         */
                        BJLUser *loginUser = self.room.loginUser;
                        if ([self.room.chatVM canSendPrivateMessageFromeUser:loginUser toUser:targetUser]
                            || [self.room.chatVM canSendPrivateMessageFromeUser:targetUser toUser:loginUser]) {
                            [self startPrivateChatWithTargetUser:targetUser];
                        }
                    }
                }
            };
        }
        
        cell.longPressCallback = cell.longPressCallback ?: ^(BJLMessageCell * _Nullable cell, CGPoint pointInCell, UIImage * _Nullable image) {
            bjl_strongify(self);
            [self startHighlighting];
            [self stopHighlightingWithDelay];
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if (indexPath) {
                BJLMessage *message = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLMessage);
                if (message) {
                    [self showOperatorViewWithMessage:message
                                                point:[self.view convertPoint:pointInCell fromView:cell]
                                                image:image];
                }
            }
        };
        return cell;
    }
    else { // if task
        NSString *cellIdentifier = [BJLMessageCell cellIdentifierForUploadingImage];
        BJLMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                               forIndexPath:indexPath];
        if (task) {
            [cell updateWithUploadingTask:task
                                 fromUser:self.room.loginUser
                                   toUser:self.targetUser
                               chatStatus:self.chatStatus
                           tableViewWidth:CGRectGetWidth(self.tableView.bounds)
                             isHorizontal:isHorizontal
                                     room:self.room];
        }
        bjl_weakify(self);
        cell.retryUploadingCallback = cell.retryUploadingCallback ?: ^(BJLMessageCell * _Nullable cell) {
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateAlphaForCell:cell atIndexPath:indexPath animationDuration:0.0];
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLMessage *message = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLMessage);
    BJLChatUploadingTask *task = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLChatUploadingTask);
    BOOL isHorizontal = BJLIsHorizontalUI(self);

    NSString *key = [self keyWithIndexPath:indexPath message:message taskMessage:task];
    NSString *identifier;
    void (^configuration)(BJLMessageCell *cell); //用于计算 cell 高度的设置
    if (message) {
        identifier = [BJLMessageCell cellIdentifierForMessageType:message.type
                                                   hasTranslation:(!!message.translation.length)];
        configuration = ^(BJLMessageCell *cell) {
            cell.bjl_autoSizing = YES;
            [cell updateWithMessage:message
                        placeholder:message.imageURLString ? [self.thumbnailForURLString objectForKey:message.imageURLString] : nil
                      fromLoginUser:[message.fromUser.number isEqualToString:self.room.loginUser.number]
                         chatStatus:self.chatStatus
                     tableViewWidth:CGRectGetWidth(self.tableView.bounds)
                       isHorizontal:isHorizontal
                               room:self.room];
        };
    }
    else if (task) {
        identifier = [BJLMessageCell cellIdentifierForUploadingImage];
        configuration = ^(BJLMessageCell *cell) {
            cell.bjl_autoSizing = YES;
            [cell updateWithUploadingTask:task
                                 fromUser:self.room.loginUser
                                   toUser:self.targetUser
                               chatStatus:self.chatStatus
                           tableViewWidth:CGRectGetWidth(self.tableView.bounds)
                             isHorizontal:isHorizontal
                                     room:self.room];
        };
    }

    return [tableView bjl_cellHeightWithKey:key identifier:identifier configuration:configuration];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [self startHighlighting];
    [self stopHighlightingWithDelay];
    
    BJLMessage *message = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLMessage);
    BJLChatUploadingTask *uploadingTask = bjl_as([self.currentDataSource bjl_objectAtIndex:indexPath.row], BJLChatUploadingTask);
    if ((message && message.type == BJLMessageType_image)
        || (uploadingTask && uploadingTask.thumbnail)) {
        BJLMessageCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (self.showImageViewCallback) self.showImageViewCallback(cell.imgView);
    }
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self startHighlighting];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self stopHighlightingWithDelay];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - getters

- (NSMutableDictionary<NSString *, NSMutableArray *> *)whisperMessageDict {
    if (!_whisperMessageDict) {
        _whisperMessageDict = [[NSMutableDictionary alloc] init];
    }
    return _whisperMessageDict;
}

- (NSMutableArray <BJLMessage *> *)teacherOrAsisstantMessages {
    if (!_teacherOrAsisstantMessages) {
        _teacherOrAsisstantMessages = [NSMutableArray new];
    }
    return _teacherOrAsisstantMessages;
}

@end

NS_ASSUME_NONNULL_END

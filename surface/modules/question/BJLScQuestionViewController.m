//
//  BJLScQuestionViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScQuestionViewController.h"
#import "BJLScAppearance.h"
#import "BJLScQuestionCell.h"
#import "BJLScQuestionOptionView.h"
#import "BJLScSegment.h"
#import "BJLHeaderRefresh.h"

static const NSInteger perPageQuestionCount = 10;

@interface BJLScQuestionViewController () <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) NSMutableArray<BJLQuestion *> *questionList;
@property (nonatomic) NSMutableArray<BJLQuestion *> *currentQuestionList;
@property (nonatomic) NSInteger totalQuestionPage;
@property (nonatomic) NSInteger currentQuestionPage;
@property (nonatomic) BOOL waitingForRequestQuestion;
@property (nonatomic, nullable) BJLQuestion *replyQuestion; // nil 代表提出新问答
@property (nonatomic) BOOL forbidMe;
@property (nonatomic) BOOL loadLatestQuestion; // UI 展示最后一页问答数据

@property (nonatomic) UIPanGestureRecognizer *gesture;
@property (nonatomic, nullable) UIView *overlayView;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIButton *questionButton;
@property (nonatomic, nullable) UIView *emptyView;
@property (nonatomic) BJLScSegment *segment;
@property (nonatomic, nullable) UIViewController *optionViewController;

@end

@implementation BJLScQuestionViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self->_room = room;
        self.totalQuestionPage = 0;
        self.currentQuestionPage = 0;
        self.replyQuestion = nil;
        self.forbidMe = NO;
        self.waitingForRequestQuestion = NO;
        self.loadLatestQuestion = NO;
        self.questionList = [NSMutableArray new];
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
    
    [self refreshCurrentPage];
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.clipsToBounds = YES;

    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    UIView *topContainerView = [UIView new];
    UIImageView *imageView = [UIImageView new];
    [imageView setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_question_icon"]];
    [topContainerView addSubview:imageView];
    [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@(24));
        make.left.equalTo(topContainerView).offset(BJLScViewSpaceM);
        make.centerY.equalTo(topContainerView);
    }];
    
    UILabel *label = [UILabel new];
    label.text = @"问答";
    label.textColor = [UIColor bjl_colorWithHex:0x44A4A];
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:16];
    [topContainerView addSubview:label];
    [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(imageView.bjl_right).offset(5);
        make.centerY.equalTo(imageView);
        make.right.lessThanOrEqualTo(topContainerView);
    }];
    UIView *line = [UIView new];
    line.backgroundColor = [UIColor bjlsc_grayLineColor];
    [topContainerView addSubview:line];
    [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(topContainerView);
        make.height.equalTo(@(BJLScOnePixel));
    }];
    [self.containerView addSubview:topContainerView];
    [topContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.right.equalTo(self.containerView);
        make.height.equalTo(@(40));
    }];
    
    self.segment = ({
        BJLScSegment *segment = [[BJLScSegment alloc] initWithItems:@[@"待回复", @"待发布", @"已发布"] width:0.0 fontSize:16.0 textColor:[UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0]];
        segment.accessibilityLabel = BJLKeypath(self, segment);
        segment.layer.masksToBounds = NO;
        segment.layer.shadowOpacity = 0.3;
        segment.layer.shadowColor = [UIColor blackColor].CGColor;
        segment.layer.shadowOffset = CGSizeMake(0.0, 2.0);
        segment.layer.shadowRadius = 2.0;
        segment.hidden = YES;
        segment;
    });
    
    [self.tableView removeFromSuperview];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.backgroundColor = [UIColor whiteColor];
    for (NSString *identifier in [BJLScQuestionCell allCellIdentifiers]) {
        [self.tableView registerClass:[BJLScQuestionCell class] forCellReuseIdentifier:identifier];
    }
    
    [self.containerView addSubview:self.tableView];
    [self.containerView addSubview:self.segment];
    [self.segment bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(topContainerView.bjl_bottom);
        make.left.right.equalTo(self.containerView);
        make.height.equalTo(@0.0);
    }];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.containerView);
        make.top.equalTo(self.segment.bjl_bottom);
    }];
    
    self.questionButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, questionButton);
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.layer.borderColor = [UIColor bjl_colorWithHexString:@"#D0D0D0" alpha:1.0].CGColor;
        button.layer.borderWidth = 1.0;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleLabel.textAlignment = NSTextAlignmentLeft;
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle: @"问点啥吧" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0] forState:UIControlStateNormal];
        button.titleEdgeInsets = UIEdgeInsetsMake(3.0, 5.0, 3.0, 5.0);
        [button addTarget:self action:@selector(showQuestionInputView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });

    [self.containerView addSubview:self.questionButton];
    [self.questionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.tableView.bjl_bottom).offset(5.0);
        make.left.equalTo(self.containerView).offset(8.0);
        make.bottom.right.equalTo(self.containerView).offset(-8.0);
        make.height.equalTo(@34.0);
    }];
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (iPhone) {
        self.refreshControl = [[BJLHeaderRefresh alloc] initWithTargrt:self action:@selector(loadQuestionHistory)];
        self.refreshControl.backgroundColor = [UIColor clearColor];
    }
    else {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(loadQuestionHistory) forControlEvents:UIControlEventValueChanged];
    }
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.segment, selectedIndex)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateListWithSegmentIndex:self.segment.selectedIndex];
            if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                return YES;
            }
            [self.tableView reloadData];
            return YES;
        }];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, state)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.state == BJLRoomState_connected) {
                 [self.questionList removeAllObjects];
                 self.totalQuestionPage = 0;
                 self.currentQuestionPage = 0;
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 [self updateQuestionEmptyViewHidden:self.questionList.count];
                 [self refreshCurrentPage];
             }
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didLoadQuestionHistory:currentPage:totalPage:)
             observer:^BOOL(NSArray<BJLQuestion *> *history, NSInteger currentPage, NSInteger totalPage) {
                 bjl_strongify(self);
                 self.totalQuestionPage = totalPage;
                 self.currentQuestionPage = currentPage;
                 // 仅在加载历史问题的时候才添加在末尾
                 if (!self.loadLatestQuestion) {
                     self.loadLatestQuestion = YES;
                     self.currentQuestionPage = totalPage;
                     [self refreshCurrentPage];
                 }
                 else {
                     [self updateQuestionListWithQuestions:history remove:NO append:NO];
                 }
                [self updateListWithSegmentIndex:self.segment.selectedIndex];
                self.waitingForRequestQuestion = NO;
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.refreshControl endRefreshing];
                 [self.tableView reloadData];
                 [self updateQuestionEmptyViewHidden:self.questionList.count];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didSendQuestion:)
             observer:^BOOL(BJLQuestion *question) {
                 bjl_strongify(self);
                 [self updateQuestionListWithQuestions:@[question] remove:NO append:YES];
                 [self updateListWithSegmentIndex:self.segment.selectedIndex];
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 [self updateQuestionEmptyViewHidden:self.questionList.count];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didPublishQuestion:)
             observer:^BOOL(BJLQuestion *question) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isTeacherOrAssistant
                     || [self.room.loginUser.number isEqualToString:question.fromUser.number]) {
                     // 老师和助教收到发布问答时仅更新，或者问答所有者是当前登录用户时
                     [self updateQuestionListWithQuestions:@[question] remove:NO append:NO];
                 }
                 else {
                     // 学生收到发布问答时会新增
                     [self updateQuestionListWithPublishQuestion:question];
                 }
                 [self updateListWithSegmentIndex:self.segment.selectedIndex];
                 if (self.newMessageCallback) {
                     self.newMessageCallback();
                 }
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 [self updateQuestionEmptyViewHidden:self.questionList.count];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUnpublishQuestionWithQuestionID:)
             observer:^BOOL(NSString *questionID) {
                 bjl_strongify(self);
                 // 取消发布问答时只有问答ID，因此特殊处理
                 [self updateQuestionListWithQuestionID:questionID questionState:BJLQuestionUnpublished];
                 [self updateListWithSegmentIndex:self.segment.selectedIndex];
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 [self updateQuestionEmptyViewHidden:self.questionList.count];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReplyQuestion:)
             observer:^BOOL(BJLQuestion *question) {
                 bjl_strongify(self);
                 // 回复问答
                 if (self.room.loginUser.isTeacherOrAssistant) {
                     // 老师和助教直接更新回复的问答
                     [self updateQuestionListWithQuestions:@[question] remove:NO append:NO];
                 }
                 else {
                     // 学生需要根据问答是否是因为回复而发布进行不同的处理
                     [self updateQuestionListWithReplyQuestion:question];
                 }
                 [self updateListWithSegmentIndex:self.segment.selectedIndex];
                 if (self.newMessageCallback) {
                     self.newMessageCallback();
                 }
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didSwitchQuestionForbidForUser:forbid:)
             observer:(BJLMethodFilter)^BOOL(BJLUser *user, BOOL forbid) {
                 bjl_strongify(self);
                 for (BJLQuestion *question in self.questionList) {
                     // 更新问答数据源中全部的禁止问答的状态
                     if ([question.fromUser.number isEqualToString:user.number]) {
                         question.forbid = forbid;
                         // no break
                     }
                 }
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, forbidQuestionList)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.forbidMe = [self.room.roomVM.forbidQuestionList containsObject:self.room.loginUser.number];
             return YES;
         }];
}

#pragma mark - actions

- (void)loadQuestionHistory {
    if (self.currentQuestionPage <= 0) {
        [self.refreshControl endRefreshing];
        return;
    }
    self.currentQuestionPage = MAX(0, --self.currentQuestionPage);
    [self refreshCurrentPage];
}

- (void)refreshCurrentPage {
    // 刷新当前页面数据
    self.waitingForRequestQuestion = YES;
    BJLError *error = [self.room.roomVM loadQuestionHistoryWithPage:self.currentQuestionPage countPerPage:perPageQuestionCount];
    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
}

- (void)updateSegmentHidden:(BOOL)hidden {
    if (!self.room.loginUser || !self.room.loginUser.isTeacherOrAssistant) {
        return;
    }
    self.segment.hidden = hidden;
    if (hidden) {
        [self.segment bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@0.0);
        }];
        self.currentQuestionList = self.questionList;
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return;
        }
        [self.tableView reloadData];
    }
    else {
        [self.segment bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@32.0);
        }];
        [self updateListWithSegmentIndex:self.segment.selectedIndex];
        if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
            return;
        }
        [self.tableView reloadData];
    }
}

- (void)updateListWithSegmentIndex:(NSInteger)segmentIndex {
    if (self.segment.hidden || !self.room.loginUser || !self.room.loginUser.isTeacherOrAssistant) {
        self.currentQuestionList = self.questionList;
        return;
    }
    BJLQuestionState state = BJLQuestionAllState;
    NSMutableArray<BJLQuestion *> *array = [NSMutableArray new];
    switch (segmentIndex) {
        case 0:
            state = BJLQuestionUnreplied;
            break;
            
        case 1:
            state = BJLQuestionUnpublished;
            break;
            
        case 2:
            state = BJLQuestionPublished;
            break;
            
        default:
            break;
    }
    for (BJLQuestion *question in [self.questionList copy]) {
        if (question.state & state) {
            [array addObject:question];
        }
    }
    self.currentQuestionList = array;
}

- (void)updateQuestionEmptyViewHidden:(BOOL)hidden {
    if (hidden) {
        if (self.emptyView) {
            [self.emptyView removeFromSuperview];
            self.emptyView = nil;
        }
    }
    else {
        if (!self.emptyView) {
            self.emptyView = ({
                UIImageView *imageView = [UIImageView new];
                imageView.image = [UIImage bjlsc_imageNamed:@"bjl_sc_question_empty"];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                imageView;
            });
            [self.containerView insertSubview:self.emptyView aboveSubview:self.tableView];
            [self.emptyView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.center.equalTo(self.containerView);
                make.width.equalTo(self.containerView).multipliedBy(0.5);
                make.height.equalTo(self.emptyView.bjl_width).multipliedBy(4.0/3.0);
            }];
        }
    }
}

- (void)showQuestionInputView {
    if (self.showQuestionInputViewCallback) {
        self.showQuestionInputViewCallback();
    }
}

- (void)sendQuestion:(NSString *)content {
    // 如果是超过最大长度的文本，裁剪后发送，确保能够发送出去
    if (content.length > BJLTextMaxLength_chat) {
        content = [content substringToIndex:NSMaxRange([content rangeOfComposedCharacterSequenceAtIndex:BJLTextMaxLength_chat])];
    }
    else if (content.length <= 0 || [content stringByReplacingOccurrencesOfString:@" " withString:@""].length <= 0) {
        return;
    }
    BJLError *error;
    if (self.replyQuestion) {
        error = [self.room.roomVM replyQuestionWithQuestionID:self.replyQuestion.ID reply:content];
    }
    else {
        error = [self.room.roomVM sendQuestion:content];
    }
    self.replyQuestion = nil;
    if (error) {
        [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
    }
}

- (void)clearReplyQuestion {
    self.replyQuestion = nil;
}

// 问答临时保存的回复，状态变为已回复
- (void)updateQuestion:(BJLQuestion *)question reply:(NSString *)reply {
    [question updateQuestionWithUnpubishReply:reply fromUser:self.room.loginUser];
    [self updateListWithSegmentIndex:self.segment.selectedIndex];
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    [self.tableView reloadData];
}

- (void)updateQuestionListWithQuestions:(NSArray<BJLQuestion *> *)questions remove:(BOOL)remove append:(BOOL)append {
    // !!! 更新问答
    for (BJLQuestion *newQuestion in [questions copy]) {
        if (remove) {
            for (BJLQuestion *oldQuestion in [self.questionList copy]) {
                if ([oldQuestion.ID isEqualToString:newQuestion.ID]) {
                    // 查找相同的问答，删除
                    [self.questionList removeObject:oldQuestion];
                }
            }
        }
        else {
            // 更新问答
            BOOL existQuestion = [self replaceQuestionListWithQuestion:newQuestion];
            if (!existQuestion) {
                // 如果没有更新问答，即新增问答
                if (append) {
                    // 添加到末尾
                    [self.questionList bjl_addObject:newQuestion];
                }
                else {
                    // 根据问答 ID 正序排列
                    [self updateQuestionListWithPublishQuestion:newQuestion];
                }
            }
        }
    }
}

- (void)updateQuestionListWithPublishQuestion:(BJLQuestion *)question {
    // !!! 根据发布的新问答更新问答列表，发布的问答可能不是最新的问答，老师和助教在问答发送时就获得了问答，处理更新逻辑
    BOOL insertQuestion = NO;
    for (BJLQuestion *oldQuestion in [self.questionList copy]) {
        // 插入到第一个比新发布的问答序号大的前面
        if ([question.ID integerValue] < [oldQuestion.ID integerValue]) {
            NSInteger index = [self.questionList indexOfObject:oldQuestion];
            [self.questionList bjl_insertObject:question atIndex:index];
            insertQuestion = YES;
            break;
        }
    }
    if (!insertQuestion) {
        // 如果没有直接添加到末尾
        [self.questionList bjl_addObject:question];
    }
}

- (void)updateQuestionListWithReplyQuestion:(BJLQuestion *)question {
    // !!! 目前主要用于学生处理回复的问答
    BOOL existQuestion = [self replaceQuestionListWithQuestion:question];
    if (!existQuestion) {
        // 如果没有更新问答，就作为新发布的问答处理
        [self updateQuestionListWithPublishQuestion:question];
    }
}

- (BOOL)replaceQuestionListWithQuestion:(BJLQuestion *)question {
    // !!! 更新问答
    BOOL existQuestion = NO;
    for (BJLQuestion *oldQuestion in [self.questionList copy]) {
        if ([oldQuestion.ID isEqualToString:question.ID]) {
            // 查找相同的问答，更新数据
            existQuestion = YES;
            // 对于未发布的问答如果有暂存的回复需要取出暂存的回复，放到更新后的问答后面
            if (question.state & BJLQuestionUnpublished) {
                for (BJLQuestionReply *reply in oldQuestion.replies) {
                    if (!reply.publish) {
                        [question updateQuestionWithUnpubishReply:reply.content fromUser:self.room.loginUser];
                    }
                }
            }
            NSUInteger index = [self.questionList indexOfObject:oldQuestion];
            [self.questionList bjl_replaceObjectAtIndex:index withObject:question];
        }
    }
    return existQuestion;
}

- (NSInteger)updateQuestionListWithQuestionID:(NSString *)questionID questionState:(BJLQuestionState)state {
    NSInteger pageIndex = 0;
    // !!! 目前主要用于处理取消发布的问答，问答数据不需要更新的情况下，仅更新问答状态，
    for (BJLQuestion *question in [self.questionList copy]) {
        if ([question.ID isEqualToString:questionID]) {
            pageIndex = question.pageIndex;
            // 改变状态
            question.state = state;
            if (state == BJLQuestionUnpublished
                && ![question.fromUser.number isEqualToString:self.room.loginUser.number]
                && !self.room.loginUser.isTeacherOrAssistant) {
                // 登录者是学生，非自己提出的问答被取消发布，则从数据源中移除
                [self.questionList removeObject:question];
            }
            break;
        }
    }
    return pageIndex;
}

- (void)showOptionViewWithQuestion:(BJLQuestion *)question questionReply:(nullable BJLQuestionReply *)reply point:(CGPoint)point {
    if (self.optionViewController) {
        return;
    }
    BJLScQuestionOptionView *optionView = [[BJLScQuestionOptionView alloc] initWithRoom:self.room question:question reply:reply];
    bjl_weakify(self);
    [optionView setReplyCallback:^(BJLQuestion * _Nonnull question, BJLQuestionReply * _Nullable reply) {
        bjl_strongify(self);
        [self hideOptionViewController];
        self.replyQuestion = question;
        if (self.replyCallback) {
            self.replyCallback(question, reply);
        }
    }];
    // 发布时把所有暂存的回复发布
    [optionView setPublishCallback:^(BJLQuestion * _Nonnull question, BOOL publish) {
        bjl_strongify(self);
        [self hideOptionViewController];
        BJLError *error = nil;
        if (publish) {
            error = [self.room.roomVM publishQuestionWithQuestionID:question.ID];
            if (question.replies.count > 0) {
                for (BJLQuestionReply *reply in [question.replies copy]) {
                    if (!reply.publish) {
                        [self.room.roomVM replyQuestionWithQuestionID:self.replyQuestion.ID reply:reply.content];
                    }
                }
            }
        }
        else {
            error = [self.room.roomVM unpublishQuestionWithQuestionID:question.ID];
        }
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }];
    [optionView setCopyCallback:^(BJLQuestion * _Nonnull question) {
        bjl_strongify(self);
        [self hideOptionViewController];
        NSString *content = [NSString stringWithFormat:@"%@ 提问：%@", question.fromUser.displayName, question.content];
        for (BJLQuestionReply *reply in question.replies) {
            content = [content stringByAppendingString:[NSString stringWithFormat:@"\n%@ 回复：%@", reply.fromUser.displayName, reply.content]];
        }
        [[UIPasteboard generalPasteboard] setString:content];
        [self showProgressHUDWithText:@"内容已复制"];
    }];
    self.optionViewController = ({
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        viewController.modalPresentationStyle = UIModalPresentationPopover;
        viewController.preferredContentSize = optionView.viewSize;
        viewController.popoverPresentationController.backgroundColor = [UIColor whiteColor];
        viewController.popoverPresentationController.delegate = self;
        viewController.popoverPresentationController.sourceView = self.view;
        viewController.popoverPresentationController.sourceRect = CGRectMake(point.x, point.y, 1.0, 1.0);
        viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
        viewController;
    });
    [self.optionViewController.view addSubview:optionView];
    [optionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.optionViewController.view.bjl_safeAreaLayoutGuide ?: self.optionViewController.view);
    }];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:self.optionViewController animated:YES completion:nil];
}

- (void)hideOptionViewController {
    [self.optionViewController dismissViewControllerAnimated:YES completion:nil];
    self.optionViewController = nil;
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.currentQuestionList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BJLQuestion *question = [self.currentQuestionList bjl_objectAtIndex:section];
    return question.replies.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLQuestion *question = [self.currentQuestionList bjl_objectAtIndex:indexPath.section];
    BJLScQuestionCell *cell = nil;
    if (indexPath.row > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:BJLScQuestionReplyCellReuseIdentifier forIndexPath:indexPath];
        [cell updateWithQuestion:question questionReply:bjl_as([question.replies bjl_objectAtIndex:indexPath.row - 1], BJLQuestionReply)];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:BJLScQuestionCellReuseIdentifier forIndexPath:indexPath];
        [cell updateWithQuestion:question questionReply:nil];
    }
    if (self.room.loginUser.isTeacherOrAssistant) {
        bjl_weakify(self, cell);
        [cell setSingleTapCallback:^(BJLQuestion * _Nonnull question, BJLQuestionReply * _Nullable questionReply, CGPoint point) {
            bjl_strongify(self, cell);
            CGPoint targetPoint = [self.view convertPoint:point fromView:cell];
            [self showOptionViewWithQuestion:question questionReply:questionReply point:targetPoint];
        }];
    }
    return cell;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLQuestion *question = [self.currentQuestionList bjl_objectAtIndex:indexPath.section];
    BJLQuestionReply *questionReply;
    NSString *key;
    NSString *identifier;
    if (indexPath.row > 0) {
        questionReply = bjl_as([question.replies bjl_objectAtIndex:indexPath.row - 1], BJLQuestionReply);
        key = [NSString stringWithFormat:@"kQuestionKey %ld %f", (long)question.ID, questionReply.createTime];
        identifier = BJLScQuestionReplyCellReuseIdentifier;
    }
    else {
        key = [NSString stringWithFormat:@"kQuestionKey %ld %f", (long)question.ID, question.createTime];
        identifier = BJLScQuestionCellReuseIdentifier;
    }
    
    CGFloat height = [tableView bjl_cellHeightWithKey:key identifier:identifier configuration:^(BJLScQuestionCell *cell) {
        //bjl_strongify(self);
        cell.bjl_autoSizing = YES;
        [cell updateWithQuestion:question questionReply:questionReply];
    }];
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 32.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 8.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view;
    });
    UIView *view = [UIView new];
    view.clipsToBounds = YES;
    [view bjlsc_drawRectCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight radius:8.0 backgroundColor:[UIColor bjl_colorWithHexString:@"#F5F5F5" alpha:1.0] size:CGSizeMake(tableView.frame.size.width - 16.0, 8.0)];
    [footerView addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(footerView);
        make.left.right.equalTo(footerView).inset(8.0);
        make.height.equalTo(@4.0);
    }];
    return footerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view;
    });
    UILabel *nameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentLeft;
        label;
    });
    [headerView addSubview:nameLabel];
    [nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(headerView).offset(8.0);
        make.centerY.equalTo(headerView);
        make.height.equalTo(@17.0);
    }];
    UILabel *timeLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0];
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [headerView addSubview:timeLabel];
    [timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(headerView).offset(-11.0);
        make.top.bottom.equalTo(nameLabel);
    }];
    UIView *view = [UIView new];
    view.clipsToBounds = YES;
    [view bjlsc_drawRectCorners:UIRectCornerTopLeft | UIRectCornerTopRight radius:8.0 backgroundColor:[UIColor bjl_colorWithHexString:@"#F5F5F5" alpha:1.0] size:CGSizeMake(tableView.frame.size.width - 16.0, 8.0)];
    [headerView addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(headerView).inset(8.0);
        make.bottom.equalTo(headerView);
        make.height.equalTo(@4.0);
    }];
    BJLQuestion *question = [self.currentQuestionList bjl_objectAtIndex:section];
    nameLabel.text = question.fromUser.displayName;
    timeLabel.text = [self timeStringWithTimeInterval:question.createTime];
    return headerView;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - wheel

- (BOOL)atTheBottomOfTableView {
    CGFloat contentOffsetY = self.tableView.contentOffset.y;
    CGFloat bottom = self.tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(self.tableView.frame);
    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    CGFloat minCellHeight = 48.0;
    return bottomOffset >= 0.0 - minCellHeight;
}

- (NSString *)timeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.optionViewController = nil;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    self.optionViewController = nil;
}

@end

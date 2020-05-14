//
//  BJLQuestionViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/1/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLQuestionViewController.h"
#import "BJLQuestionCell.h"

NS_ASSUME_NONNULL_BEGIN

static const NSInteger perPageQuestionCount = 10;

@interface BJLQuestionViewController () <UITextViewDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) NSMutableArray<BJLQuestion *> *questionList;
@property (nonatomic) NSInteger totalQuestionPage;
@property (nonatomic) NSInteger currentQuestionPage;
@property (nonatomic) BOOL waitingForRequestQuestion;
@property (nonatomic, nullable) BJLQuestion *replyQuestion; // nil 代表提出新问答
@property (nonatomic) BOOL forbidMe;

@property (nonatomic) UIPanGestureRecognizer *gesture;
@property (nonatomic, nullable) UIView *overlayView;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIView *topView;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic, nullable) UIView *emptyView;
@property (nonatomic) UIView *bottomView;
@property (nonatomic) UITextView *textView;
@property (nonatomic, nullable) UILabel *forbidMeLabel;
@property (nonatomic, nullable) UILabel *wordCountLabel;
@property (nonatomic, nullable) UIButton *sendQuestionButton;

@end

@implementation BJLQuestionViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self->_room = room;
        self.totalQuestionPage = 0;
        self.currentQuestionPage = 0;
        self.replyQuestion = nil;
        self.forbidMe = NO;
        self.questionList = [NSMutableArray new];
        [self makeObserving];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviewsAndConstraints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 重置状态
    self.replyQuestion = nil;
    self.waitingForRequestQuestion = NO;
    [self refreshCurrentPage];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidChangeFrameNotification
                                                  object:nil];
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor blackColor];
    
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        if (self.view.bjl_safeAreaLayoutGuide) {
            make.top.equalTo(self.view.bjl_safeAreaLayoutGuide);
        }
        else {
            make.top.equalTo(self.view).offset(24.0);
        }
    }];

    self.topView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor bjl_grayImagePlaceholderColor].CGColor;
        view;
    });
    [self.containerView addSubview:self.topView];
    [self.topView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.containerView);
        make.height.equalTo(@32.0);
    }];
    
    self.closeButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_close_black"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.topView addSubview:self.closeButton];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.top.bottom.equalTo(self.topView);
        make.width.equalTo(self.closeButton.bjl_height);
    }];
    
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textColor = [UIColor blackColor];
        label.text = @"问答";
        label;
    });
    [self.topView addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.topView);
        make.top.height.equalTo(self.topView);
        make.right.lessThanOrEqualTo(self.closeButton.bjl_left);
        make.left.greaterThanOrEqualTo(self.topView);
    }];
    
    // table view
    [self.tableView removeFromSuperview];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.backgroundColor = [UIColor bjl_lightGrayBackgroundColor];
    for (NSString *identifier in [BJLQuestionCell allCellIdentifiers]) {
        [self.tableView registerClass:[BJLQuestionCell class] forCellReuseIdentifier:identifier];
    }
    [self.containerView addSubview:self.tableView];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.topView.bjl_bottom);
        make.bottom.equalTo(self.containerView).offset(-50.0);
        make.left.right.equalTo(self.containerView);
    }];
    
    self.bottomView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_lightGrayBackgroundColor];
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.2;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, -2.0);
        view.layer.shadowRadius = 2.0;
        view;
    });
    [self.containerView addSubview:self.bottomView];
    [self.bottomView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView).offset(0.0);
        make.height.equalTo(@50.0);
    }];
    
    self.textView = ({
        UITextView *textView = [UITextView new];
        textView.delegate = self;
        NSMutableAttributedString *attributedText = [NSMutableAttributedString new];
        NSTextAttachment *textAttachment = [NSTextAttachment new];
        textAttachment.image = [UIImage bjl_imageNamed:@"bjl_ic_pencil"];
        textAttachment.bounds = CGRectMake(0, -2.0, 16.0, 16.0);
        [attributedText appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@" 请输入提问内容" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                                                                                                   NSForegroundColorAttributeName : [UIColor bjl_lightGrayTextColor]}]];
        textView.bjl_attributedPlaceholder = attributedText;
        textView.font = [UIFont systemFontOfSize:14.0];
        textView.textColor = [UIColor blackColor];
        textView.backgroundColor = [UIColor whiteColor];
        textView.returnKeyType = UIReturnKeySend;
        textView;
    });
    [self.bottomView addSubview:self.textView];
    [self.textView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomView).insets(UIEdgeInsetsMake(7.0, 10.0, 7.0, 10.0));
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
                 [self updateQuestionListWithQuestions:history remove:NO append:YES];
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 [self updateQuestionEmptyViewHidden:self.questionList.count];
                 // !!! 必须在刷新完之后才认为请求完毕
                 self.waitingForRequestQuestion = NO;
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didSendQuestion:)
             observer:^BOOL(BJLQuestion *question) {
                 bjl_strongify(self);
                 [self updateQuestionListWithQuestions:@[question] remove:NO append:YES];
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
                 if (!self.room.loginUser.isTeacherOrAssistant) {
                     // !!! 对于学生，如果问答被取消发布了，后面页码的问题可能会转移到前面，依次类推，导致数据源中最后一页继续拉取的问答数据比服务端的数据的少了一个，因此需要重新拉取问答数据源里面最大的页码的全量数据
                     NSInteger pageIndex = self.questionList.lastObject.pageIndex;
                     self.waitingForRequestQuestion = YES;
                     BJLError *error = [self.room.roomVM loadQuestionHistoryWithPage:pageIndex countPerPage:perPageQuestionCount];
                     if (error && self.showMessageCallback) {
                         self.showMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                     }
                 }
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
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self.tableView reloadData];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didSwitchQuestionForbidForUser:forbid:)
             observer:(BJLMethodFilter)^BOOL(BJLUser *user, BOOL forbid) {
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
             [self updateBottomViewWithForbidMe:self.forbidMe];
             return YES;
         }];
}

#pragma mark - actions

- (void)showInputView {
    [self updateTextView];
    if (!self.overlayView) {
        self.overlayView = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = @"overlayView";
            view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
            UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeInputView)];
            gesture.numberOfTapsRequired = 1;
            [view addGestureRecognizer:gesture];
            view;
        });
        [self.containerView insertSubview:self.overlayView belowSubview:self.bottomView];
        [self.overlayView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.containerView);
        }];
    }
    
    [self.bottomView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@120.0);
    }];
    [self.textView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomView).insets(UIEdgeInsetsMake(0.0, 0.0, 32.0, 0.0));
    }];
    
    if (!self.sendQuestionButton) {
        self.sendQuestionButton = ({
            UIButton *button = [UIButton new];
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 12.0;
            button.backgroundColor = [UIColor bjl_blueBrandColor];
            [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_question_send"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(sendQuestion) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.bottomView addSubview:self.sendQuestionButton];
        [self.sendQuestionButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.bottomView).offset(-12.0);
            make.bottom.equalTo(self.bottomView).offset(-8.0);
            make.height.equalTo(@24.0);
            make.width.equalTo(@54.0);
        }];
    }
    
    if (!self.wordCountLabel) {
        self.wordCountLabel = ({
            UILabel *label = [UILabel new];
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor bjl_lightGrayTextColor];
            label.textAlignment = NSTextAlignmentRight;
            label.font = [UIFont systemFontOfSize:14.0];
            label;
        });
        [self.bottomView addSubview:self.wordCountLabel];
        [self.wordCountLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.sendQuestionButton.bjl_left).offset(-13.0);
            make.top.bottom.equalTo(self.sendQuestionButton);
        }];
    }
    
    [self updateBottomViewWithForbidMe:self.forbidMe];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    self.wordCountLabel.text = [NSString stringWithFormat:@"%lu/%ld",(unsigned long)self.textView.text.length, (long)BJLTextMaxLength_question];
}

- (void)removeInputView {
    self.replyQuestion = nil;
    self.textView.text = nil;
    [self updateTextView];
    
    [self.overlayView removeFromSuperview];
    self.overlayView = nil;
    [self.sendQuestionButton removeFromSuperview];
    self.sendQuestionButton = nil;
    [self.wordCountLabel removeFromSuperview];
    self.wordCountLabel = nil;
    [self.textView resignFirstResponder];
    [self.bottomView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@50.0);
    }];
    [self.textView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomView).insets(UIEdgeInsetsMake(7.0, 10.0, 7.0, 10.0));
    }];
    [self updateBottomViewWithForbidMe:self.forbidMe];
    self.bottomView.backgroundColor = [UIColor bjl_lightGrayBackgroundColor];
}

- (void)refreshCurrentPage {
    // 刷新当前页面数据
    BJLError *error = [self.room.roomVM loadQuestionHistoryWithPage:self.currentQuestionPage countPerPage:perPageQuestionCount];
    if (error && self.showMessageCallback) {
        self.showMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
    }
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
                imageView.image = [UIImage bjl_imageNamed:@"bjl_ic_question_empty"];
                imageView;
            });
            [self.containerView insertSubview:self.emptyView aboveSubview:self.tableView];
            [self.emptyView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.center.equalTo(self.containerView);
                make.width.equalTo(@160.0);
                make.height.equalTo(@182.0);
            }];
        }
    }
}

- (void)updateBottomViewWithForbidMe:(BOOL)forbidMe {
    if (forbidMe) {
        if (self.overlayView) {
            [self removeInputView];
        }
        else if (!self.forbidMeLabel) {
            self.forbidMeLabel = ({
                UILabel *label = [UILabel new];
                label.userInteractionEnabled = YES;
                label.backgroundColor = [UIColor bjl_lightGrayBackgroundColor];
                label.text = @"已被老师禁止提问";
                label.textColor = [UIColor bjl_lightGrayTextColor];
                label.textAlignment = NSTextAlignmentCenter;
                label.font = [UIFont systemFontOfSize:14.0];
                label;
            });
            [self.bottomView addSubview:self.forbidMeLabel];
            [self.forbidMeLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.textView);
            }];
        }
        
        self.bottomView.backgroundColor = [UIColor whiteColor];
    }
    else {
        [self.forbidMeLabel removeFromSuperview];
        self.forbidMeLabel = nil;
        self.bottomView.backgroundColor = [UIColor bjl_lightGrayBackgroundColor];
    }
}

- (void)updateTextView {
    if (!self.replyQuestion) {
        NSMutableAttributedString *attributedText = [NSMutableAttributedString new];
        NSTextAttachment *textAttachment = [NSTextAttachment new];
        textAttachment.image = [UIImage bjl_imageNamed:@"bjl_ic_pencil"];
        textAttachment.bounds = CGRectMake(0, -2.0, 16.0, 16.0);
        [attributedText appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@" 请输入提问内容" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                                                                                                   NSForegroundColorAttributeName : [UIColor bjl_lightGrayTextColor]}]];
        self.textView.bjl_attributedPlaceholder = attributedText;
    }
    else {
        self.textView.bjl_placeholder = [NSString stringWithFormat:@"回复 %@", self.replyQuestion.fromUser.displayName];
    }
}

- (void)sendQuestion {
    // 如果是超过最大长度的文本，裁剪后发送，确保能够发送出去
    NSString *content = self.textView.text;
    if (content.length > BJLTextMaxLength_question) {
        content = [content substringToIndex:NSMaxRange([content rangeOfComposedCharacterSequenceAtIndex:BJLTextMaxLength_question])];
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
    if (error && self.showMessageCallback) {
        self.showMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
    }
    [self removeInputView];
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
    // !!! 目前主要用于学生处理发布的问答，根据发布的新问答更新问答列表，发布的问答可能不是最新的问答，老师和助教在问答发送时就获得了问答，处理更新逻辑
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


- (void)keyboardChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    CGRect keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
    
    NSTimeInterval animationDuration = bjl_as(userInfo[UIKeyboardAnimationDurationUserInfoKey], NSNumber).doubleValue;
    UIViewAnimationOptions animationOptions = ({
        NSNumber *animationCurveNumber = bjl_as(userInfo[UIKeyboardAnimationCurveUserInfoKey], NSNumber);
        UIViewAnimationCurve animationCurve = (animationCurveNumber != nil
                                               ? animationCurveNumber.unsignedIntegerValue
                                               : UIViewAnimationCurveEaseInOut);
        // @see http://stackoverflow.com/a/19490788/456536
        animationCurve | animationCurve << 16; // @see UIViewAnimationOptionCurveXxxx
    });
    [self.view layoutIfNeeded];
    CGFloat offset = (CGRectGetMinY(keyboardFrame) >= CGRectGetHeight([UIScreen mainScreen].bounds)
                      ? 0.0 : - CGRectGetHeight(keyboardFrame));
    [self.bottomView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(offset);
    }];
    
    [self.view setNeedsLayout];
    // TODO: MingLQ - animate not working
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:animationOptions
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)hide {
    if (self.hideCallback) {
        self.hideCallback();
    }
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.questionList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BJLQuestion *question = [self.questionList bjl_objectAtIndex:section];
    return question.replies.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLQuestion *question = [self.questionList bjl_objectAtIndex:indexPath.section];
    BJLQuestionCell *cell = nil;
    if (indexPath.row > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:BJLQuestionReplyCellReuseIdentifier forIndexPath:indexPath];
        [cell updateWithQuestion:nil questionReply:bjl_as([question.replies bjl_objectAtIndex:indexPath.row - 1], BJLQuestionReply)];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:BJLQuestionCellReuseIdentifier forIndexPath:indexPath];
        [cell updateWithQuestion:question questionReply:nil];
    }
#if DEBUG
    // !!! 调试用回复和复制功能
    if (self.room.loginUser.isTeacherOrAssistant) {
        bjl_weakify(self);
        [cell setSingleTapCallback:^{
            bjl_strongify(self);
            self.replyQuestion = question;
            [self.textView becomeFirstResponder];
            
        }];
        [cell setLongPressCallback:^(NSString * _Nonnull content) {
            [[UIPasteboard generalPasteboard] setString:content];
        }];
    }
#endif
    return cell;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLQuestion *question = [self.questionList bjl_objectAtIndex:indexPath.section];
    BJLQuestionReply *questionReply;
    NSString *key;
    NSString *identifier;
    if (indexPath.row > 0) {
        questionReply = bjl_as([question.replies bjl_objectAtIndex:indexPath.row - 1], BJLQuestionReply);
        key = [NSString stringWithFormat:@"kQuestionKey %ld %f", (long)question.ID, questionReply.createTime];
        identifier = BJLQuestionReplyCellReuseIdentifier;
    }
    else {
        key = [NSString stringWithFormat:@"kQuestionKey %ld %f", (long)question.ID, question.createTime];
        identifier = BJLQuestionCellReuseIdentifier;
    }
    
    CGFloat height = [tableView bjl_cellHeightWithKey:key identifier:identifier configuration:^(BJLQuestionCell *cell) {
        //bjl_strongify(self);
        cell.bjl_autoSizing = YES;
        [cell updateWithQuestion:question questionReply:questionReply];
    }];
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section < [tableView numberOfSections] - 1) {
        return 10.0;
    }
    else if (section == [tableView numberOfSections] - 1) {
        // 最后的 section 加个边框线
        return 1.0;
    }
    return CGFLOAT_MIN;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section < [tableView numberOfSections] - 1) {
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor bjl_grayImagePlaceholderColor].CGColor;
        return view;
    }
    else if (section == [tableView numberOfSections] - 1) {
        // 最后的 section 加个边框线
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_grayImagePlaceholderColor];
        return view;
    }
    return nil;
}

#if DEBUG
// !!! 调试用右滑按钮发布和禁止问答功能
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // section 第一行, 登录用户是助教或老师，可操作
    return !indexPath.row && self.room.loginUser.isTeacherOrAssistant;
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.row && self.room.loginUser.isTeacherOrAssistant) {
        // section 第一行, 登录用户是助教或老师，可操作
        BJLQuestion *question = [self.questionList bjl_objectAtIndex:indexPath.section];
        BOOL publish = question.state & BJLQuestionPublished;
        bjl_weakify(self);
        UITableViewRowAction *publishAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:publish ? @"取消发布" : @"发布" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            bjl_strongify(self);
            [tableView setEditing:NO animated:YES];
            BJLError *error;
            if (publish) {
                error = [self.room.roomVM unpublishQuestionWithQuestionID:question.ID];
            }
            else {
                error = [self.room.roomVM publishQuestionWithQuestionID:question.ID];
            }
            if (error && self.showMessageCallback) {
                self.showMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }];
        // 老师和助教不能被禁止提问
        if (question.fromUser.isTeacherOrAssistant) {
            return @[publishAction];
        }
        UITableViewRowAction *forbidQuestionAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:question.forbid ? @"允许提问" : @"禁止提问" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            bjl_strongify(self);
            [tableView setEditing:NO animated:YES];
            BJLError *error = [self.room.roomVM switchQuestionForbidForUser:question.fromUser forbid:!question.forbid];
            if (error && self.showMessageCallback) {
                self.showMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            }
        }];
        return @[publishAction, forbidQuestionAction];
    }
    return nil;
}
#endif

#pragma mark - text view delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self showInputView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self sendQuestion];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    dispatch_async(dispatch_get_main_queue(), ^{
        // max length
        if (textView.text.length > BJLTextMaxLength_question) {
            UITextRange *markedTextRange = textView.markedTextRange;
            if (!markedTextRange || markedTextRange.isEmpty) {
                textView.text = [textView.text substringToIndex:BJLTextMaxLength_question];
                [textView.undoManager removeAllActions];
            }
        }
        self.wordCountLabel.text = [NSString stringWithFormat:@"%lu/%ld",(unsigned long)self.textView.text.length, (long)BJLTextMaxLength_question];
    });
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark -

// 下拉加载更多
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    if ([self atTheBottomOfTableView] && self.currentQuestionPage < self.totalQuestionPage && !self.waitingForRequestQuestion) {
        self.waitingForRequestQuestion = YES;
        BJLError *error = [self.room.roomVM loadQuestionHistoryWithPage:self.currentQuestionPage + 1 countPerPage:perPageQuestionCount];
        if (error && self.showMessageCallback) {
            self.showMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
        }
    }
}

- (BOOL)atTheBottomOfTableView {
    CGFloat contentOffsetY = self.tableView.contentOffset.y;
    CGFloat bottom = self.tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(self.tableView.frame);
    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    CGFloat minCellHeight = 48.0;
    return bottomOffset >= 0.0 - minCellHeight;
}

@end

NS_ASSUME_NONNULL_END

//
//  BJLIcQuestionAnswerViewController.m
//  BJLiveUI
//
//  Created by fanyi on 2019/5/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcQuestionAnswerViewController.h"
#import "BJLIcQuestionAnswerViewController+protected.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

#import "BJLIcQuestionAnswerOptionCollectionViewCell.h"
#import "BJLIcQuestionAnswerPublishedOptionCollectionViewCell.h"
#import "BJLIcQuestionAnswerSheetUserDetailTableViewCell.h"
#import "BJLIcQuestionAnswerViewController+statistics.h"

#define onePixel (1.0 / [UIScreen mainScreen].scale)

static NSString *const defaultRightAndWrongTitle = @"defaultRightAndWrongTitle";
static NSString *const defaultDefinitionTitle = @"defaultDefinitionTitle";

static NSString *const detailTableViewCellIdentifier = @"detailTableViewCellIdentifier";

@interface BJLIcQuestionAnswerViewController ()<UITextViewDelegate, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) BJLIcQuestionAnswerWindowLayout layout;

@property (nonatomic) NSInteger countDownTime;

@end

@implementation BJLIcQuestionAnswerViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                 answerSheet:(BJLAnswerSheet *)answerSheet
                      layout:(BJLIcQuestionAnswerWindowLayout)layout {
    self = [super init];
    if (self) {
        self->_room = room;
        self.layout = layout;
        self.answerSheet = answerSheet;
        self.countDownTime = (layout == BJLIcQuestionAnswerWindowLayout_publish) ? self.answerSheet.duration : 0;
        [self prepareToOpen];
        self.onlineUserList = [NSMutableArray new];
        self.judgeTitleArray = [NSMutableArray arrayWithArray:@[
                                                                @{@"1":@"对", @"0":@"错"},
                                                                ]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setWindowInterfaceEnabled:YES];
    [self setWindowGesturesEnabled:YES];
    self.forgroundView.userInteractionEnabled = NO;
    self.topBar.hidden = NO;
    
    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.closeButtonHidden = NO;
    self.doubleTapToMaximize = NO;
    self.panToResize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];

    [self makeSubViews];
    [self updateContentViewAndBottomView];
    [self makeObserving];
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    self.answerOptionsCollectionView.delegate = nil;
    self.answerOptionsCollectionView.dataSource = nil;

    self.commentsTextView.delegate = nil;
    self.timeTextField.delegate = nil;
    
    self.judgeTitleTableView.delegate = nil;
    self.judgeTitleTableView.dataSource = nil;
    
    self.detailTableView.delegate = nil;
    self.detailTableView.dataSource = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 仅用于通知上一层是否也要显示一个 overlay 来隐藏键盘，无论上层有没有，控制器内始终会显示一个 overlay
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
    
    [self hideKeyboardView];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidChangeFrameNotification
                                                  object:nil];
}

#pragma mark - private
- (void)keyboardChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    CGRect keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
    if (self.keyboardFrameChangeCallback) {
        self.keyboardFrameChangeCallback(keyboardFrame);
    }
}

- (void)prepareToOpen {
    self.caption = @"答题器";
    self.fixedAspectRatio = 3/2;
    self.minWindowHeight = 240.0f;
    self.minWindowWidth = 481.0;
    
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (isIphone) {
        CGFloat relativeWidth = 0.8;
        CGFloat relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth width:self.minWindowWidth height:self.minWindowHeight];
        self.relativeRect = [self rectInBounds:CGRectMake(0.1, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
    }
    else {
        CGFloat relativeWidth = 0.6f;
        
        CGFloat relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth width:self.minWindowWidth height:self.minWindowHeight];
        self.relativeRect = [self rectInBounds:CGRectMake(0.25, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
    }
}

- (void)makeSubViews {
    // top bar
    self.topGapLine = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, topGapLine);
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        bjl_return view;
    });
    [self.topBar addSubview:self.topGapLine];
    [self.topGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.topBar);
        make.height.equalTo(@(onePixel));
    }];
    
    // bottom bar
    [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(40.0));
    }];
    
    self.bottomGapLine = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomGapLine);
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        bjl_return view;
    });
    [self.bottomBar addSubview:self.bottomGapLine];
    [self.bottomGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.bottomBar);
        make.height.equalTo(@(onePixel));
    }];

    [self makeEditContainView];
    [self makePublishContainView];
    [self makeEndContainView];
}

- (void)makeEditContainView {
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    self.editContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, editContainerView);
        view.backgroundColor = [UIColor clearColor];
        bjl_return view;
    });

    UITapGestureRecognizer *tapGesture = ({
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardView)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture;
    });
    // overlay
    self.overlayView = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = YES;
        view.backgroundColor = [UIColor clearColor];
        [view addGestureRecognizer:tapGesture];
        view.accessibilityLabel = BJLKeypath(self, overlayView);
        view;
    });

    // 选择题目类型
    self.topChoosenContainView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, topChoosenContainView);
        view.backgroundColor = [UIColor clearColor];
        [self.editContainerView addSubview:view];
        bjl_return view;
    });

    UILabel *label = ({
        UILabel *label = [UILabel new];
        label.text = @"类型:";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentLeft;
        [self.topChoosenContainView addSubview:label];
        bjl_return label;
    });
    
    self.choosenButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"选择题" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal | UIControlStateSelected];
        [button setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
        button.layer.cornerRadius = 4.0f;
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        button.accessibilityLabel = BJLKeypath(self, choosenButton);
        [button addTarget:self action:@selector(updateWithChoosenQuestion) forControlEvents:UIControlEventTouchUpInside];
        [self.topChoosenContainView addSubview:button];
        bjl_return button;
    });
    
    self.judgementButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"是非题" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal | UIControlStateSelected];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
        button.layer.cornerRadius = 4.0f;
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        button.accessibilityLabel = BJLKeypath(self, judgementButton);
        [button addTarget:self action:@selector(updateWithJudenmentQuestion) forControlEvents:UIControlEventTouchUpInside];
        [self.topChoosenContainView addSubview:button];
        bjl_return button;
    });
    self.shuoldShowCorrectAnswerButton = ({
        BJLImageRightButton *button = [BJLImageRightButton new];
        button.midSpace = 5.0;
        
        [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
        button.accessibilityLabel = BJLKeypath(self, shuoldShowCorrectAnswerButton);
        [button setTitle:@"答题结束公布正确答案" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button setTitleColor:[UIColor bjl_colorWithHex:0XFFFFFF alpha:0.5] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_notShow"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_show"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(shuoldShowCorrectAnswer) forControlEvents:UIControlEventTouchUpInside];
        [self.topChoosenContainView addSubview:button];

        bjl_return button;
    });
    
    [self.topChoosenContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.editContainerView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight + 10);
        make.left.equalTo(self.editContainerView.bjl_left).offset(10);
        make.right.equalTo(self.editContainerView).offset(-10);
        make.height.equalTo(@(25));
    }];
    
    [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.left.equalTo(self.topChoosenContainView);
    }];
    [self.choosenButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(label);
        make.top.bottom.equalTo(self.topChoosenContainView);
        make.left.equalTo(label.bjl_right).offset(10);
        make.width.equalTo(@(80));
    }];
    [self.judgementButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(label);
        make.top.bottom.equalTo(self.topChoosenContainView);
        make.left.equalTo(self.choosenButton.bjl_right).offset(10);
        make.right.lessThanOrEqualTo(self.shuoldShowCorrectAnswerButton.bjl_left).offset(-10);
        make.width.equalTo(self.choosenButton);
    }];
    [self.shuoldShowCorrectAnswerButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(label);
        make.top.bottom.equalTo(self.topChoosenContainView);
        make.left.greaterThanOrEqualTo(self.judgementButton.bjl_right).offset(10);
        make.right.equalTo(self.topChoosenContainView);
    }];
    
    self.judgementContainView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, judgementContainView);
        view.backgroundColor = [UIColor clearColor];
        view.hidden = (self.answerSheet.answerType == BJLAnswerSheetType_Choosen);
        [self.editContainerView addSubview:view];
        bjl_return view;
    });

    self.judgementTitleContainView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, judgementTitleContainView);
        view.backgroundColor = [UIColor clearColor];
        [self.judgementContainView addSubview:view];
        bjl_return view;
    });
    
    self.judgeTitleButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"对/错" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
        button.titleLabel.textAlignment = NSTextAlignmentLeft;
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 30);
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.layer.cornerRadius = 4.0f;
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        
        button.accessibilityLabel = BJLKeypath(self, judgeTitleButton);
        [button addTarget:self action:@selector(chooseJudgeTitle) forControlEvents:UIControlEventTouchUpInside];

        [self.judgementTitleContainView addSubview:button];
        
        self.judgeTitleIconButton = ({
            UIButton *iconButton = [[UIButton alloc] init];
            [iconButton setImage:[UIImage bjlic_imageNamed:@"bjl_questionResponder_open"] forState:UIControlStateNormal];
            [iconButton setImage:[UIImage bjlic_imageNamed:@"bjl_questionResponder_close"] forState:UIControlStateSelected];
            [iconButton addTarget:self action:@selector(chooseJudgeTitle) forControlEvents:UIControlEventTouchUpInside];
            [button addSubview:iconButton];
            bjl_return iconButton;
        });
        
        [self.judgeTitleIconButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(button);
            make.right.equalTo(button).offset(-5);
            make.height.equalTo(@(24));
            make.width.equalTo(@(24));
        }];
        bjl_return button;
    });
    
    self.judgeTitleTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.tableFooterView = [UIView new];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        tableView.hidden = YES;
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"judgeAnswerSheetCell"];
        [self.judgementTitleContainView addSubview:tableView];
        bjl_return tableView;
    });
    
    self.rightButtonView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, rightButtonView);
        [self.judgementContainView addSubview:view];
        
        self.rightButton = ({
            UIButton *button = [[UIButton alloc] init];
            button.backgroundColor = [UIColor whiteColor];
            // layer
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth/2;
            
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_right"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_right"] forState:UIControlStateSelected];
            
            // action
            [button addTarget:self action:@selector(updateWithChooseRightButton) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:button];
            bjl_return button;
        });
        [self.rightButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(view).offset(-1.5f);
            make.top.equalTo(view);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth));
        }];

        self.selectedRightIconImageView = ({
            UIImageView *imageView = [UIImageView new];
            [imageView setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_selected"]];
            imageView.layer.cornerRadius = 9.0f;
            imageView.clipsToBounds = YES;
            imageView.hidden = YES;
            bjl_return imageView;
        });
        [view addSubview:self.selectedRightIconImageView];
        [self.selectedRightIconImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.width.equalTo(@(18));
            make.bottom.right.equalTo(self.rightButton).offset(3);
        }];
        bjl_return view;
    });

    self.wrongButtonView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, wrongButtonView);
        [self.judgementContainView addSubview:view];
        
        self.wrongButton = ({
            UIButton *button = [[UIButton alloc] init];
            button.backgroundColor = [UIColor whiteColor];
            // layer
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth/2;
            
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_wrong"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_wrong"] forState:UIControlStateSelected];
            
            // action
            [button addTarget:self action:@selector(updateWithChooseWrongButton) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:button];
            bjl_return button;
        });
        [self.wrongButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(view).offset(-1.5f);
            make.top.equalTo(view);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth));
        }];
        
        self.selectedWrongIconImageView = ({
            UIImageView *imageView = [UIImageView new];
            [imageView setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_selected"]];
            imageView.layer.cornerRadius = 9.0f;
            imageView.clipsToBounds = YES;
            imageView.hidden = YES;
            bjl_return imageView;
        });
        [view addSubview:self.selectedWrongIconImageView];
        [self.selectedWrongIconImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.width.equalTo(@(18));
            make.bottom.right.equalTo(self.wrongButton).offset(3);
        }];
        bjl_return view;
    });

    self.rightTextField = ({
        BJLTextField *textField = [BJLTextField new];
        textField.accessibilityLabel = BJLKeypath(self, rightTextField);
        textField.textColor = [UIColor whiteColor];
        textField.font = [UIFont systemFontOfSize:12];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.textInsets = textField.editingInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        textField.text = @"对";
        textField.delegate = self;
        textField.userInteractionEnabled = NO;
        [self.judgementContainView addSubview:textField];
        bjl_return textField;
    });
    self.wrongTextField = ({
        BJLTextField *textField = [BJLTextField new];
        textField.accessibilityLabel = BJLKeypath(self, wrongTextField);
        textField.textColor = [UIColor whiteColor];
        textField.font = [UIFont systemFontOfSize:12];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.textInsets = textField.editingInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        textField.text = @"错";
        textField.delegate = self;
        textField.userInteractionEnabled = NO;
        [self.judgementContainView addSubview:textField];
        bjl_return textField;
    });

    [self.judgementContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.topChoosenContainView.bjl_bottom).offset(isIphone ? 5 : 10);
        make.left.right.equalTo(self.editContainerView);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 2 + (isIphone ? 5 : 15)));
    }];
    
    [self.judgementTitleContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.judgementContainView.bjl_left).offset(10);
        make.top.equalTo(self.judgementContainView).offset(10);
        make.width.equalTo(@(100));
        make.height.equalTo(@(100));
    }];
    
    [self.judgeTitleButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.judgementTitleContainView);
        make.height.equalTo(@(24));
    }];

    [self.judgeTitleTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.judgeTitleButton.bjl_bottom);
        make.left.right.bottom.equalTo(self.judgementTitleContainView);
    }];
    [self.rightButtonView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight));
        make.top.equalTo(self.judgementContainView).offset(isIphone ? 10 : 15);
        make.right.equalTo(self.judgementContainView.bjl_centerX).offset(-10);
    }];
    [self.wrongButtonView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight));
        make.top.equalTo(self.rightButtonView);
        make.left.equalTo(self.judgementContainView.bjl_centerX).offset(10);
    }];
    
    [self.rightTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.rightButtonView);
        make.height.equalTo(@(24));
        make.width.equalTo(@(55));
        make.top.equalTo(self.rightButtonView.bjl_bottom).offset(isIphone ? 5 : 10);
    }];
    [self.wrongTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.wrongButtonView);
        make.height.equalTo(@(24));
        make.width.equalTo(@(55));
        make.top.equalTo(self.wrongButtonView.bjl_bottom).offset(isIphone ? 5 : 10);
    }];
    
    self.optionsContainView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, optionsContainView);
        view.backgroundColor = [UIColor clearColor];
        [self.editContainerView addSubview:view];
        bjl_return view;
    });

    self.collectionView = ({
        // layout
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = isIphone ? 10 : 25;

        // view
        UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        view.backgroundColor = [UIColor clearColor];
        view.showsHorizontalScrollIndicator = NO;
        view.bounces = NO;
        view.alwaysBounceVertical = YES;
        view.pagingEnabled = YES;
        view.dataSource = self;
        view.delegate = self;
        view.accessibilityLabel = BJLKeypath(self, collectionView);
        [view registerClass:[BJLIcQuestionAnswerOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell];
        [self.optionsContainView addSubview:view];
        bjl_return view;
    });
    
    self.minusOptionButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"-" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:26]];
        [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.6] forState:UIControlStateDisabled];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 3, 0)];
        button.layer.cornerRadius = 11.0;
        button.layer.borderColor = [UIColor whiteColor].CGColor;
        button.layer.borderWidth = 1.0;
        button.accessibilityLabel = BJLKeypath(self, minusOptionButton);
        [button addTarget:self action:@selector(minusOptions) forControlEvents:UIControlEventTouchUpInside];
        [self.optionsContainView addSubview:button];
        bjl_return button;
    });
    self.plusOptionButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"+" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:26]];
        [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.6] forState:UIControlStateDisabled];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 3, 0)];
        button.layer.cornerRadius = 11.0;
        button.layer.borderColor = [UIColor whiteColor].CGColor;
        button.layer.borderWidth = 1.0;
        button.accessibilityLabel = BJLKeypath(self, plusOptionButton);
        [button addTarget:self action:@selector(addOptions) forControlEvents:UIControlEventTouchUpInside];
        [self.optionsContainView addSubview:button];
        bjl_return button;
    });

    CGFloat optionsViewHeight = 0;
    CGFloat optionsViewWidth = 0;
    if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
        optionsViewHeight = ([self.answerSheet.options count] <= 4
                             ? [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight
                             : [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 2 + (isIphone ? 5 : 15)); // 1~2 行选项
        optionsViewWidth = [self.answerSheet.options count] <= 4
        ? ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * [self.answerSheet.options count] + (isIphone ? 10 : 25) * ([self.answerSheet.options count] - 1))
        : ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 4 + (isIphone ? 10 : 25) * 3);
    }
    else {
        optionsViewHeight = 75;
        optionsViewWidth = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight*2 + 25;
    }

    [self.optionsContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.topChoosenContainView.bjl_bottom).offset((isIphone ? 5 : 10));
        make.left.greaterThanOrEqualTo(self.editContainerView).offset(10);
        make.right.lessThanOrEqualTo(self.editContainerView).offset(-10);
        make.centerX.equalTo(self.editContainerView);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 2 + (isIphone ? 5 : 15)));
    }];
    [self.minusOptionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.centerY.equalTo(self.optionsContainView);
        make.width.height.equalTo(@(22));
    }];
    
    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.optionsContainView);
        make.left.equalTo(self.minusOptionButton.bjl_right).offset(20);
        make.right.equalTo(self.plusOptionButton.bjl_left).offset(-20);
        make.height.equalTo(@(optionsViewHeight));
        make.width.equalTo(@(optionsViewWidth));
    }];
    [self.plusOptionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.centerY.equalTo(self.optionsContainView);
        make.width.height.equalTo(@(22));
    }];
    
    self.commentsContainView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, commentsContainView);
        view.backgroundColor = [UIColor clearColor];
        [self.editContainerView addSubview:view];
        bjl_return view;
    });
    
    self.optionTipLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"点击选项可设置为正确答案";
        label.textColor = [UIColor bjl_colorWithHex:0xEDEDEE alpha:0.5];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.accessibilityLabel = BJLKeypath(self, optionTipLabel);
        [self.commentsContainView addSubview:label];
        bjl_return label;
    });
    
    self.commentsTextView = ({
        UITextView *textView = [UITextView new];
        textView.delegate = self;
        textView.bjl_placeholderLabel.text = @"您可以在这里添加说明";
        textView.bjl_placeholderLabel.textColor = [UIColor bjl_colorWithHex:0x9B9B9B];
        textView.bjl_placeholderLabel.textAlignment = NSTextAlignmentLeft;
        textView.layer.cornerRadius = 4.0f;
        textView.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        textView.textColor = [UIColor whiteColor];
        textView.font = [UIFont systemFontOfSize:12];
        textView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        textView.layer.borderWidth = onePixel;
        textView.accessibilityLabel = BJLKeypath(self, commentsTextView);
        [self.commentsContainView addSubview:textView];
        bjl_return textView;
    });
    self.commentsTextCountLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"0/50";
        label.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont systemFontOfSize:12];
        label.accessibilityLabel = BJLKeypath(self, commentsTextCountLabel);
        [self.commentsContainView addSubview:label];
        bjl_return label;
    });
    
    [self.commentsContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.optionsContainView.bjl_bottom).offset(isIphone ? 5 : 10);
        make.centerX.equalTo(self.editContainerView);
        make.left.equalTo(self.editContainerView).offset(10);
        make.right.equalTo(self.editContainerView).offset(-10);
        make.bottom.lessThanOrEqualTo(self.editContainerView).offset(-40);
    }];
    [self.optionTipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.centerX.equalTo(self.commentsContainView);
        make.left.greaterThanOrEqualTo(self.commentsContainView).offset(10);
        make.right.lessThanOrEqualTo(self.commentsContainView).offset(-10);
        make.height.equalTo(@(17));
    }];
    [self.commentsTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.optionTipLabel.bjl_bottom).offset((isIphone ? 5 : 10));
        make.bottom.equalTo(self.commentsContainView);
        make.centerX.equalTo(self.commentsContainView);
        make.left.equalTo(self.commentsContainView);
        make.right.equalTo(self.commentsContainView);
        make.height.equalTo(@(44));
    }];
    [self.commentsTextCountLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.right.equalTo(self.commentsTextView).offset(-2);
    }];
    self.bottomEditContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomEditContainerView);
        view.backgroundColor = [UIColor clearColor];
        view.hidden = YES;
        [self.bottomBar addSubview:view];
        bjl_return view;
    });
    
    UIView *cornerView = ({
        UIView *view = [BJLHitTestView new];
        view.clipsToBounds = YES;
        view.layer.cornerRadius = 12.0f;
        view.layer.borderWidth = 1.0f;
        view.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        [self.bottomEditContainerView addSubview:view];
        bjl_return view;
    });

    self.minusTimeButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"-" forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 3, 0)];
        [button.titleLabel setFont:[UIFont systemFontOfSize:26]];
        [button addTarget:self action:@selector(minusAnswerTime) forControlEvents:UIControlEventTouchUpInside];
        [cornerView addSubview:button];
        bjl_return button;
    });
    self.plusTimeButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"+" forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 3, 0)];
        [button.titleLabel setFont:[UIFont systemFontOfSize:26]];
        [button addTarget:self action:@selector(addAnswerTime) forControlEvents:UIControlEventTouchUpInside];
        [cornerView addSubview:button];
        bjl_return button;
    });
    
    self.timeTextField = ({
        BJLTextField *textField = [BJLTextField new];
        textField.accessibilityLabel = BJLKeypath(self, timeTextField);
        textField.textColor = [UIColor whiteColor];
        textField.font = [UIFont systemFontOfSize:16];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.layer.borderWidth = onePixel;
        textField.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        textField.textInsets = textField.editingInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        textField.delegate = self;
        textField.text = @"1";
        [cornerView addSubview:textField];
        bjl_return textField;
    });
    
    UILabel *leftLabel = ({
        UILabel *label  = [UILabel new];
        label.text = @"倒计时: ";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentRight;
        [self.bottomEditContainerView addSubview:label];
        bjl_return label;
    });
    
    UILabel *rightLabel = ({
        UILabel *label  = [UILabel new];
        label.text = @"分后结束答题";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentLeft;
        [self.bottomEditContainerView addSubview:label];
        bjl_return label;
    });
    self.publishButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, publishButton);
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"发布" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(publishQuestion) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomEditContainerView addSubview:button];
        bjl_return button;
    });
    self.resetButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, resetButton);
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"重置" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(resetQuestion) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomEditContainerView addSubview:button];
        bjl_return button;
    });
    [self.bottomEditContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];
    [self.publishButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomEditContainerView);
        make.right.equalTo(self.bottomEditContainerView).offset(-10);
        make.top.bottom.equalTo(self.bottomEditContainerView).inset(8.0);
        make.width.equalTo(@80.0);
    }];
    [self.resetButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.publishButton);
        make.right.equalTo(self.publishButton.bjl_left).offset(-10);
        make.left.greaterThanOrEqualTo(rightLabel.bjl_right).offset(10);
        make.top.bottom.equalTo(self.publishButton);
        make.width.equalTo(self.publishButton);
    }];
    
    [leftLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.publishButton);
        make.left.equalTo(self.bottomEditContainerView.bjl_left).offset(10);
        make.height.equalTo(cornerView);
    }];

    [cornerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(leftLabel);
        make.height.equalTo(@(24));
        make.left.equalTo(leftLabel.bjl_right).offset(10);
        make.right.equalTo(rightLabel.bjl_left).offset(-10);
    }];
    [self.plusTimeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(cornerView);
        make.right.equalTo(self.timeTextField.bjl_left);
        make.height.equalTo(cornerView);
        make.width.equalTo(@(24));
        make.left.equalTo(cornerView.bjl_left);
    }];
    [self.timeTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.hugging.compressionResistance.required();
        make.center.equalTo(cornerView);
        make.height.equalTo(cornerView);
        make.width.equalTo(@(33)).priorityHigh();
    }];
    [self.minusTimeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(cornerView);
        make.left.equalTo(self.timeTextField.bjl_right);
        make.height.equalTo(cornerView);
        make.width.equalTo(@(24));
        make.right.equalTo(cornerView.bjl_right);
    }];
    [rightLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(leftLabel);
        make.left.equalTo(cornerView.bjl_right).offset(10);
        make.height.equalTo(cornerView);
        make.right.lessThanOrEqualTo(self.resetButton.bjl_left).offset(-10);
    }];
}

- (void)makePublishContainView {
    self.publishContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, publishContainerView);
        view.backgroundColor = [UIColor clearColor];
        bjl_return view;
    });
    
    self.countDownTimeLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"结束倒计时: ";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, countDownTimeLabel);
        [self.publishContainerView addSubview:label];
        bjl_return label;
    });
    
    self.answerSituationLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"发布：0人，提交：0人 ";
        label.textColor = [UIColor bjl_colorWithHex:0xEDEDEE alpha:0.5];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.accessibilityLabel = BJLKeypath(self, answerSituationLabel);
        [self.publishContainerView addSubview:label];
        bjl_return label;
    });

    self.publishedCommentsLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.accessibilityLabel = BJLKeypath(self, publishedCommentsLabel);
        [self.publishContainerView addSubview:label];
        bjl_return label;
    });

    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    self.answerOptionsCollectionView = ({
        // layout
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.itemSize = CGSizeMake([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight, 75);
        layout.minimumInteritemSpacing = isIphone ? 10 : 25;
        // view
        UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        view.backgroundColor = [UIColor clearColor];
        view.showsHorizontalScrollIndicator = NO;
        view.bounces = NO;
        view.alwaysBounceVertical = YES;
        view.pagingEnabled = YES;
        view.dataSource = self;
        view.delegate = self;
        view.accessibilityLabel = BJLKeypath(self, answerOptionsCollectionView);
        [view registerClass:[BJLIcQuestionAnswerPublishedOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_ChoosenCell];
        [view registerClass:[BJLIcQuestionAnswerPublishedOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_right];
        [view registerClass:[BJLIcQuestionAnswerPublishedOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_wrong];
        [self.publishContainerView addSubview:view];
        bjl_return view;
    });

    [self.countDownTimeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.publishContainerView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight + 10);
        make.left.equalTo(self.publishContainerView.bjl_left).offset(10);
        make.right.equalTo(self.publishContainerView).offset(-10);
        make.height.equalTo(@(18));
    }];

    CGFloat optionsViewHeight = 75;
    CGFloat optionsViewWidth = ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * [self.answerSheet.options count] + (isIphone ? 10 : 25)*([self.answerSheet.options count] - 1));

    [self.answerOptionsCollectionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.publishContainerView);
        make.left.greaterThanOrEqualTo(self.publishContainerView).offset(10);
        make.right.lessThanOrEqualTo(self.publishContainerView).offset(-10);
        make.height.equalTo(@(optionsViewHeight));
        make.width.equalTo(@(optionsViewWidth));
        make.top.equalTo(self.countDownTimeLabel.bjl_bottom).offset(10);
    }];
    [self.answerSituationLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.publishContainerView);
        make.top.equalTo(self.answerOptionsCollectionView.bjl_bottom).offset((isIphone ? 5 : 10));
        make.left.equalTo(self.publishContainerView).offset(10);
        make.right.equalTo(self.publishContainerView).offset(-10);
    }];
    [self.publishedCommentsLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.vertical.hugging.compressionResistance.required();
        make.centerX.equalTo(self.publishContainerView);
        make.top.equalTo(self.answerSituationLabel.bjl_bottom).offset(isIphone ? 5 : 10);
        make.left.equalTo(self.publishContainerView).offset(10);
        make.right.equalTo(self.publishContainerView).offset(-10);
        make.bottom.lessThanOrEqualTo(self.publishContainerView.bjl_bottom).offset(-40);
    }];

    self.bottomPublishContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomPublishContainerView);
        view.backgroundColor = [UIColor clearColor];
        view.hidden = YES;
        [self.bottomBar addSubview:view];
        bjl_return view;
    });
    
    self.endButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, endButton);
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        button.backgroundColor = [UIColor bjl_colorWithHex:0x1795FF];
        [button setTitle:@"结束" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(endQuestion) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomPublishContainerView addSubview:button];
        bjl_return button;
    });
    self.revokeButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, revokeButton);
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"撤销" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(revokeQuestion) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomPublishContainerView addSubview:button];
        bjl_return button;
    });
    [self.bottomPublishContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];
    
    [self.endButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomPublishContainerView);
        make.right.equalTo(self.bottomPublishContainerView).offset(-10);
        make.top.bottom.equalTo(self.bottomPublishContainerView).inset(8.0);
        make.width.equalTo(@80.0);
    }];
    [self.revokeButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.endButton);
        make.right.equalTo(self.endButton.bjl_left).offset(-10);
        make.left.greaterThanOrEqualTo(self.bottomPublishContainerView.bjl_left).offset(10);
        make.top.bottom.equalTo(self.endButton);
        make.width.equalTo(self.endButton);
    }];
}

- (void)makeEndContainView {
    self.endContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, endContainerView);
        view.backgroundColor = [UIColor clearColor];
        bjl_return view;
    });
    self.detailButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, detailButton);
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        [button setTitle:@"查看详情" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showQuestionAnswerDetail) forControlEvents:UIControlEventTouchUpInside];
        [self.endContainerView addSubview:button];
        bjl_return button;
    });

    self.answerUseTimeLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"用时：0分0秒 ";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, answerUseTimeLabel);
        [self.endContainerView addSubview:label];
        bjl_return label;
    });

    self.publishNumberLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"发布：0人 ";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, publishNumberLabel);
        [self.endContainerView addSubview:label];
        bjl_return label;
    });

    self.chartContainView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, chartContainView);
        view.backgroundColor = [UIColor clearColor];
        [self.endContainerView addSubview:view];
        bjl_return view;
    });

    self.endCommentsLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor bjl_colorWithHex:0xEDEDEE alpha:0.5];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.accessibilityLabel = BJLKeypath(self, endCommentsLabel);
        [self.chartContainView addSubview:label];
        bjl_return label;
    });
    
    self.statisticsLine = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, statisticsLine);
        view.backgroundColor = [UIColor whiteColor];
        [self.chartContainView addSubview:view];
        bjl_return view;
    });
    self.participatedNumberLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"答题：0人 ";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentRight;
        label.accessibilityLabel = BJLKeypath(self, publishNumberLabel);
        [self.chartContainView addSubview:label];
        bjl_return label;
    });

    self.correctRateLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"正确率：0% ";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, correctRateLabel);
        [self.chartContainView addSubview:label];
        bjl_return label;
    });

    [self.answerUseTimeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.endContainerView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight + 10);
        make.left.equalTo(self.endContainerView.bjl_left).offset(10);
        make.right.lessThanOrEqualTo(self.detailButton.bjl_left).offset(-10);
    }];
    
    [self.publishNumberLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.answerUseTimeLabel.bjl_bottom).offset(10);
        make.left.equalTo(self.answerUseTimeLabel);
        make.right.lessThanOrEqualTo(self.endContainerView).offset(-10);
    }];
    
    [self.detailButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.answerUseTimeLabel);
        make.right.lessThanOrEqualTo(self.endContainerView).offset(-10);
        make.height.equalTo(@(25));
        make.width.equalTo(@80.0);
    }];
    [self.chartContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.endContainerView);
        make.top.equalTo(self.endContainerView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight+10);
        make.left.equalTo(self.endContainerView).offset(10);
        make.right.equalTo(self.endContainerView).offset(-10);
        make.bottom.equalTo(self.endContainerView).offset(-50);
    }];
    [self.statisticsLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.chartContainView);
        make.height.equalTo(@(1.0));
        make.bottom.equalTo(self.endCommentsLabel.bjl_top).offset(-30);
    }];
    [self.participatedNumberLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.chartContainView);
        make.right.equalTo(self.statisticsLine.bjl_left).offset(-10);
        make.centerY.equalTo(self.statisticsLine);
        make.height.equalTo(@(90));
    }]; 
    [self.correctRateLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.statisticsLine.bjl_right).offset(10);
        make.right.equalTo(self.chartContainView);
        make.centerY.equalTo(self.statisticsLine);
        make.height.equalTo(@(80));
    }];

    [self.endCommentsLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.vertical.hugging.compressionResistance.required();
        make.centerX.equalTo(self.chartContainView);
        make.top.equalTo(self.statisticsLine.bjl_bottom).offset(30);
        make.left.right.bottom.equalTo(self.chartContainView);
    }];

    self.bottomEndContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomEndContainerView);
        view.backgroundColor = [UIColor clearColor];
        view.hidden = YES;
        [self.bottomBar addSubview:view];
        bjl_return view;
    });
    self.reeditButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, reeditButton);
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        [button setTitle:@"重新编辑" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(reeditQuestion) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomEndContainerView addSubview:button];
        bjl_return button;
    });
    
    self.backButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, backButton);
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle:@"返回" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(backToEndContainerView) forControlEvents:UIControlEventTouchUpInside];
        button.hidden = YES;
        [self.bottomEndContainerView addSubview:button];
        bjl_return button;
    });

    self.correctAnswerLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"正确答案：";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentLeft;
        label.hidden = YES;
        label.accessibilityLabel = BJLKeypath(self, correctAnswerLabel);
        [self.bottomEndContainerView addSubview:label];
        bjl_return label;
    });

    [self.bottomEndContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];
    
    [self.reeditButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomEndContainerView);
        make.right.equalTo(self.bottomEndContainerView).offset(-10);
        make.top.bottom.equalTo(self.bottomEndContainerView).inset(8.0);
        make.width.equalTo(@80.0);
    }];
    
    [self.backButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.reeditButton);
        make.left.equalTo(self.bottomEndContainerView).offset(10);
        make.top.bottom.equalTo(self.bottomEndContainerView).inset(8.0);
    }];
    
    [self.correctAnswerLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.reeditButton);
        make.right.equalTo(self.reeditButton.bjl_left).offset(-10);
        make.top.bottom.equalTo(self.bottomEndContainerView).inset(8.0);
    }];
    
    self.detailContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, detailContainerView);
        view;
    });
    
    self.detailTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.tableFooterView = [UIView new];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.backgroundColor = [UIColor clearColor];
        [tableView registerClass:[BJLIcQuestionAnswerSheetUserDetailTableViewCell class] forCellReuseIdentifier:detailTableViewCellIdentifier];
        [self.detailContainerView addSubview:tableView];
        bjl_return tableView;
    });
    [self.detailTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.detailContainerView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight);
        make.left.right.equalTo(self.detailContainerView);
        make.bottom.equalTo(self.detailContainerView).offset(-40);
    }];
}

- (void)updateContentViewAndBottomView {
    if (self.layout == BJLIcQuestionAnswerWindowLayout_normal) {
        [self setContentViewController:nil contentView:self.editContainerView];
        if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
            [self.choosenButton setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];
            [self.judgementButton setBackgroundColor:[UIColor clearColor]];
        }
        else {
            [self.judgementButton setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];
            [self.choosenButton setBackgroundColor:[UIColor clearColor]];
        }
        [self updateEditContainerView];
    }
    else if (self.layout == BJLIcQuestionAnswerWindowLayout_publish) {
        [self setContentViewController:nil contentView:self.publishContainerView];
        [self updatePublishContainerView];
    }
    else if (self.layout == BJLIcQuestionAnswerWindowLayout_end) {
        [self setContentViewController:nil contentView:self.endContainerView];
        [self updateEndContainerView];
    }
    
    self.bottomEditContainerView.hidden = (self.layout != BJLIcQuestionAnswerWindowLayout_normal);
    self.bottomPublishContainerView.hidden = (self.layout != BJLIcQuestionAnswerWindowLayout_publish);
    self.bottomEndContainerView.hidden = (self.layout != BJLIcQuestionAnswerWindowLayout_end);
}

- (void)updatePublishContainerView {
    self.answerSituationLabel.text = [NSString stringWithFormat:@"发布：%td人，提交：%td人", self.answerSheet.userCountParticipate, self.answerSheet.userCountSubmit];
    self.publishedCommentsLabel.text = self.answerSheet.questionDescription ? : @"";
    
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat optionsViewHeight = 75;
    CGFloat optionsViewWidth = ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * [self.answerSheet.options count] + (isIphone ? 10 : 25)*([self.answerSheet.options count] - 1));

    [self.answerOptionsCollectionView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(optionsViewHeight));
        make.width.equalTo(@(optionsViewWidth));
    }];
    
    [self.answerOptionsCollectionView reloadData];
    [self startCountTimer];
}

- (void)updateEndContainerView {
    // 备注
    self.endCommentsLabel.text = self.answerSheet.questionDescription ? : @"";
    
    //答题用时
    NSInteger startTime = self.answerSheet.startTimeInterval;
    NSInteger endTime = self.answerSheet.endTimeInterval;
    NSInteger duration = endTime - startTime;
    int minutes = ((int)duration) / 60;
    int second = ((int)duration) % 60;

    self.answerUseTimeLabel.text = [NSString stringWithFormat:@"用时：%i分%i秒", minutes, second];
    //发布人数
    self.publishNumberLabel.text = [NSString stringWithFormat:@"发布：%td人", self.answerSheet.userCountParticipate];
    
    //答题人数
    self.participatedNumberLabel.text = [NSString stringWithFormat:@"答题：%td人", self.answerSheet.userCountSubmit];
    
    //正确率
    CGFloat correctRate = self.answerSheet.userCountSubmit > 0 ? (CGFloat)self.answerSheet.userCountCorrect / self.answerSheet.userCountSubmit : 0;
    self.correctRateLabel.text = [NSString stringWithFormat:@"正确率：%.1f%%", correctRate * 100];

}

- (void)startCountTimer {
    [self stopCountDownTimer];
    [self updateCountDownShowTime];
    self.countDownTime --;

    bjl_weakify(self);
    self.countDownTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        
        // 倒计时结束
        if (self.countDownTime <= 0) {
            [timer invalidate];
            
            //老师主动发end结束信令
            if (self.endQuestionAnswerCallback) {
                self.endQuestionAnswerCallback(NO);
            }
            return;
        }
        
        [self updateCountDownShowTime];
        self.countDownTime --;
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
}

// 销毁倒计时
- (void)stopCountDownTimer {
    if (self.countDownTimer || [self.countDownTimer isValid]) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

- (void)updateCountDownShowTime {
    int minutes = ((int)self.countDownTime) / 60;
    int second = ((int)self.countDownTime) % 60;

    self.countDownTimeLabel.text = [NSString stringWithFormat:@"结束倒计时：%i:%i", minutes, second];
}

- (void)updateCorrectAnswerTip {
    if (self.answerSheet.answerType == BJLAnswerSheetType_Judgement) {
        self.optionTipLabel.text = @"点击选项可设置正确答案";
        return;
    }
    
    BOOL hasSetCorrectAnswer = NO;
    NSMutableString *correctAnswer = [[NSMutableString alloc] initWithString:@"已设置正确答案为："];
    for(BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.isAnswer) {
            hasSetCorrectAnswer = YES;
            [correctAnswer appendString:[NSString stringWithFormat:@" %@", option.key]];
        }
    }
    if (hasSetCorrectAnswer) {
        self.optionTipLabel.text = correctAnswer;
    }
    else {
        self.optionTipLabel.text = @"点击选项可设置正确答案";
    }
}

#pragma mark - overrite
- (void)close {
    // 如果在答题中,关闭时需要撤回答题
    BOOL isPublish = (self.layout == BJLIcQuestionAnswerWindowLayout_publish);
    if (isPublish) {
        if (self.closeQuestionAnswerCallback) {
            self.closeQuestionAnswerCallback();
        }
    }
    else {
        if (self.closeCallback) {
            self.closeCallback();
        }
        [self closeWithoutRequest];
    }
}

- (void)open {
    [self openWithoutRequest];
}

#pragma mark - public
- (void)closeQuestionAnswer {
    BOOL isPublish = (self.layout == BJLIcQuestionAnswerWindowLayout_publish);
    if (isPublish) {
        if (self.endQuestionAnswerCallback) {
            self.endQuestionAnswerCallback(YES);
        }
    }
    else {
        if (self.closeCallback) {
            self.closeCallback();
        }
    }
    [self closeWithoutRequest];
}

- (void)hideKeyboardView {
    [self.timeTextField resignFirstResponder];
    [self.rightTextField resignFirstResponder];
    [self.wrongTextField resignFirstResponder];
    [self.commentsTextView resignFirstResponder];

    if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
        [self.overlayView removeFromSuperview];
    }
}

#pragma mark - action
- (void)updateEditContainerView {
    
    self.judgementContainView.hidden = !(self.answerSheet.answerType == BJLAnswerSheetType_Judgement);
    self.optionsContainView.hidden = !(self.answerSheet.answerType == BJLAnswerSheetType_Choosen);
    self.shuoldShowCorrectAnswerButton.selected = self.answerSheet.shouldShowCorrectAnswer;
    
    if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {

        BOOL minusEnable = ([self.answerSheet.options count] > 2) && (self.answerSheet.answerType == BJLAnswerSheetType_Choosen);
        self.minusOptionButton.enabled = minusEnable;
        self.minusOptionButton.layer.borderColor = minusEnable ? [UIColor whiteColor].CGColor : [UIColor colorWithWhite:1 alpha:0.6].CGColor;
        self.minusOptionButton.hidden = !(self.answerSheet.answerType == BJLAnswerSheetType_Choosen);
        
        BOOL plusEnable = ([self.answerSheet.options count] < 8);
        self.plusOptionButton.enabled = plusEnable;
        self.plusOptionButton.layer.borderColor = plusEnable ? [UIColor whiteColor].CGColor : [UIColor colorWithWhite:1 alpha:0.6].CGColor;
        self.plusOptionButton.hidden = !(self.answerSheet.answerType == BJLAnswerSheetType_Choosen);
        
        BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        CGFloat optionsViewHeight = 0;
        CGFloat optionsViewWidth = 0;

        optionsViewHeight = ([self.answerSheet.options count] <= 4
                             ? [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight
                             : [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 2 + (isIphone ? 5 : 15)); // 1~2 行选项
        optionsViewWidth = [self.answerSheet.options count] <= 4
        ? ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * [self.answerSheet.options count] + (isIphone ? 10 : 25) * ([self.answerSheet.options count] - 1))
        : ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 4 + (isIphone ? 10 : 25) * 3);
        [self.collectionView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@(optionsViewHeight));
            make.width.equalTo(@(optionsViewWidth));
        }];
        
        [self.collectionView reloadData];
    }
    else if (self.answerSheet.answerType == BJLAnswerSheetType_Judgement) {
        
        BJLAnswerSheetOption *YESoption = [self.answerSheet.options objectAtIndex:0];
        BJLAnswerSheetOption *NOoption = [self.answerSheet.options objectAtIndex:1];

        self.rightButton.selected = YESoption.isAnswer;
        self.selectedRightIconImageView.hidden = YES;
        
        self.wrongButton.selected = NOoption.isAnswer;
        self.selectedWrongIconImageView.hidden = YES;
        
        [self.judgeTitleButton setTitle:[NSString stringWithFormat:@"%@/%@", YESoption.key, NOoption.key] forState:UIControlStateNormal];
        self.judgeTitleButton.selected = NO;
        self.judgeTitleIconButton.selected = self.judgeTitleButton.selected;

        self.judgeTitleTableView.hidden = YES;
        [self.rightTextField setText:YESoption.key];
        [self.wrongTextField setText:NOoption.key];
        self.rightTextField.userInteractionEnabled = NO;
        self.rightTextField.layer.borderWidth = 0;
        self.wrongTextField.userInteractionEnabled = NO;
        self.wrongTextField.layer.borderWidth = 0;
    }

    [self updateCorrectAnswerTip];
 }

//点击选择题
- (void)updateWithChoosenQuestion {
    [self.choosenButton setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];
    [self.judgementButton setBackgroundColor:[UIColor clearColor]];
    
    self.answerSheet.answerType = BJLAnswerSheetType_Choosen;
    [self initialAnswerOptions];
    [self updateEditContainerView];
}

//点击判断题
- (void)updateWithJudenmentQuestion {
    [self.judgementButton setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];
    [self.choosenButton setBackgroundColor:[UIColor clearColor]];
    
    self.answerSheet.answerType = BJLAnswerSheetType_Judgement;
    [self initialAnswerOptions];
    [self updateEditContainerView];
}

- (void)updateWithChooseRightButton {
    if (self.answerSheet.answerType != BJLAnswerSheetType_Judgement) {
        return;
    }
    
    self.rightButton.selected = !self.rightButton.selected;
    BJLAnswerSheetOption *rightOption = [self.answerSheet.options firstObject];
    rightOption.isAnswer = self.rightButton.selected;
    self.selectedRightIconImageView.hidden = !self.rightButton.selected;

    self.wrongButton.selected = NO;
    BJLAnswerSheetOption *wrongOption = [self.answerSheet.options objectAtIndex:1];
    wrongOption.isAnswer = NO;
    self.selectedWrongIconImageView.hidden = !self.wrongButton.selected;
}

- (void)updateWithChooseWrongButton {
    if (self.answerSheet.answerType != BJLAnswerSheetType_Judgement) {
        return;
    }

    self.rightButton.selected = NO;
    BJLAnswerSheetOption *rightOption = [self.answerSheet.options objectAtIndex:0];
    rightOption.isAnswer = self.rightButton.selected;
    self.selectedRightIconImageView.hidden = !self.rightButton.selected;
    
    self.wrongButton.selected = !self.wrongButton.selected;
    BJLAnswerSheetOption *wrongOption = [self.answerSheet.options objectAtIndex:1];
    wrongOption.isAnswer = self.wrongButton.selected;
    self.selectedWrongIconImageView.hidden = !self.wrongButton.selected;
}

//减少选项
- (void)minusOptions {
    if (self.minusOptionButton.selected || self.answerSheet.answerType != BJLAnswerSheetType_Choosen) {
        return;
    }

    if ([self.answerSheet.options count] <= 2) {
        return;
    }
    
    self.minusOptionButton.selected = YES;
    NSMutableArray *options = [self.answerSheet.options mutableCopy];
    [options removeLastObject];
    self.answerSheet.options = [options copy];
    [self updateEditContainerView];
    
    self.minusOptionButton.selected = NO;
}

//增加选项
- (void)addOptions {
    if (self.plusOptionButton.selected || self.answerSheet.answerType != BJLAnswerSheetType_Choosen) {
        return;
    }
    
    if ([self.answerSheet.options count] >= 8) {
        return;
    }
    self.plusOptionButton.selected = YES;
    NSMutableArray *options = [self.answerSheet.options mutableCopy];
    NSInteger keyInteger = [options count];
    NSString *optionString = [[self optionsArray] objectAtIndex:keyInteger];
    BJLAnswerSheetOption *option = [[BJLAnswerSheetOption alloc] initWithID:optionString isAnswer:NO];
    [options addObject:option];
    self.answerSheet.options = [options copy];
    [self updateEditContainerView];

    self.plusOptionButton.selected = NO;
}

//增加答题时间
- (void)addAnswerTime {
    NSString *time = self.timeTextField.text;
    NSInteger timeInsteger = time.integerValue;
    timeInsteger = MIN(MAX(timeInsteger + 1, 1), NSIntegerMax);
    self.timeTextField.text = [NSString stringWithFormat:@"%td", timeInsteger];
}

//减少答题时间
- (void)minusAnswerTime {
    NSString *time = self.timeTextField.text;
    NSInteger timeInsteger = time.integerValue;
    timeInsteger = MIN(MAX(timeInsteger - 1, 1), NSIntegerMax);
    self.timeTextField.text = [NSString stringWithFormat:@"%td", timeInsteger];
}

//发布答题
- (void)publishQuestion {
    if (self.layout != BJLIcQuestionAnswerWindowLayout_normal) {
        return;
    }

    self.answerSheet.questionDescription = self.commentsTextView.text;
    
    NSInteger minutes = self.timeTextField.text.integerValue;
    
    self.answerSheet.duration = minutes * 60;

    BOOL hasCorrectAnswer = NO;
    BOOL hasJudegeTitle = NO;
    for (BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.isAnswer) {
            hasCorrectAnswer = YES;
        }
        if (option.key && option.key.length) {
            hasJudegeTitle = YES;
        }
    }
    
    if (!hasJudegeTitle && self.answerSheet.answerType == BJLAnswerSheetType_Judgement) {
        if (self.errorCallback) {
            self.errorCallback(@"判断题选择内容不能为空");
        }
        return;
    }
    
    if (!hasCorrectAnswer && self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
        if (self.errorCallback) {
            self.errorCallback(@"请先选择一个正确答案");
        }
        return;
    }
    
    if (self.publishQuestionAnswerCallback) {
        self.publishQuestionAnswerCallback(self.answerSheet);
    }
}

//重置答题
- (void)resetQuestion {
    if (self.layout != BJLIcQuestionAnswerWindowLayout_normal) {
        return;
    }
    [self initialAnswerOptions];
    [self updateEditContainerView];
}

//结束答题
- (void)endQuestion {
    if (self.layout != BJLIcQuestionAnswerWindowLayout_publish) {
        return;
    }
    
    [self stopCountDownTimer];
    if (self.endQuestionAnswerCallback) {
        self.endQuestionAnswerCallback(NO);
    }
}

//撤回答题
- (void)revokeQuestion {
    if (self.layout != BJLIcQuestionAnswerWindowLayout_publish) {
        return;
    }
    
    [self stopCountDownTimer];

    if (self.revokeQuestionAnswerCallback) {
        self.revokeQuestionAnswerCallback();
    }
}

//重新编辑
- (void)reeditQuestion {
    if (self.layout != BJLIcQuestionAnswerWindowLayout_end) {
        return;
    }
    
    self.layout = BJLIcQuestionAnswerWindowLayout_normal;
    [self initialAnswerOptions];
    [self updateContentViewAndBottomView];
}

//查看详情
- (void)showQuestionAnswerDetail {
    if (self.layout != BJLIcQuestionAnswerWindowLayout_end) {
        return;
    }
    
    if (self.requestQuestionDetailCallback) {
        self.requestQuestionDetailCallback(self.answerSheet.ID);
    }
}

- (void)backToEndContainerView {
    [self setContentViewController:nil contentView:self.endContainerView];
    self.backButton.hidden = YES;
    self.correctAnswerLabel.hidden = YES;
}

- (void)initialAnswerOptions {
    self.commentsTextView.text = nil;
    
    if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
        BJLAnswerSheetOption *Aoption = [[BJLAnswerSheetOption alloc] initWithID:@"A" isAnswer:NO];
        BJLAnswerSheetOption *Boption = [[BJLAnswerSheetOption alloc] initWithID:@"B" isAnswer:NO];
        BJLAnswerSheetOption *Coption = [[BJLAnswerSheetOption alloc] initWithID:@"C" isAnswer:NO];
        BJLAnswerSheetOption *Doption = [[BJLAnswerSheetOption alloc] initWithID:@"D" isAnswer:NO];
        self.answerSheet.options = [NSArray arrayWithObjects:Aoption, Boption, Coption, Doption, nil];
    }
    else {
        NSDictionary *dic = [[self judgeTitleArray] firstObject];
        BJLAnswerSheetOption *YESoption = [[BJLAnswerSheetOption alloc] initWithID:[dic bjl_stringForKey:@"1"] isAnswer:NO];
        BJLAnswerSheetOption *NOoption = [[BJLAnswerSheetOption alloc] initWithID:[dic bjl_stringForKey:@"0"] isAnswer:NO];
        self.answerSheet.options = [NSArray arrayWithObjects:YESoption, NOoption, nil];
    }
}

- (void)chooseJudgeTitle {
    self.judgeTitleButton.selected = !self.judgeTitleButton.selected;
    self.judgeTitleIconButton.selected = self.judgeTitleButton.selected;
    
    self.judgeTitleTableView.hidden = !self.judgeTitleButton.selected;
    if (!self.judgeTitleTableView.hidden) {
        [self.judgeTitleTableView reloadData];
    }
}

- (void)shuoldShowCorrectAnswer {
    self.shuoldShowCorrectAnswerButton.selected = !self.shuoldShowCorrectAnswerButton.selected;
    self.answerSheet.shouldShowCorrectAnswer = self.shuoldShowCorrectAnswerButton.selected;
}

#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView == self.commentsTextView) {
        if (self.overlayView.superview && self.overlayView.superview != self.view) {
            if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
                [self.overlayView removeFromSuperview];
            }
        }
        if (!self.overlayView.superview) {
            [self.view insertSubview:self.overlayView aboveSubview:self.forgroundView];
            [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.view);
            }];
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // 替换换行为空格
    if (textView == self.commentsTextView) {
        if ([text isEqualToString:@"\n"]) {
            NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:@" "];
            textView.text = newString;
            return NO;
        }
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (textView == self.commentsTextView) {
            NSString *text = textView.text;
            if (text.length > 50) {
                self.commentsTextView.text = [text substringToIndex:50];
                self.commentsTextCountLabel.text = @"50/50";
                [textView.undoManager removeAllActions];
            }
            else {
                self.commentsTextCountLabel.text = [NSString stringWithFormat:@"%td/50", text.length];
            }
        }
    });
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.timeTextField
        || textField == self.rightTextField
        || textField == self.wrongTextField) {
        if (self.overlayView.superview && self.overlayView.superview != self.view) {
            if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
                [self.overlayView removeFromSuperview];
            }
        }

        if (!self.overlayView.superview) {
            [self.view insertSubview:self.overlayView aboveSubview:self.forgroundView];
            [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.view);
            }];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.timeTextField) {
        NSString *text = textField.text;
        int number = text.intValue;
        if (number >= 1) {
            textField.text = [NSString stringWithFormat:@"%i", number];
        }
        else {
            textField.text = @"1";
        }
    }
    else if (textField == self.rightTextField || textField == self.wrongTextField) {
        // 新增判断题title
        NSDictionary *dic = @{
                              @"1" : self.rightTextField.text ?: @"",
                              @"0" : self.wrongTextField.text ?: @""
                              };
        // 第一对 永远是对/错
        NSDictionary *defaultDic = [self.judgeTitleArray firstObject];
        [self.judgeTitleArray bjl_removeObjectAtIndex:0];
        
        [self.judgeTitleArray bjl_addObject:dic];
        if ([self.judgeTitleArray count] > 3) {
            [self.judgeTitleArray bjl_removeObjectAtIndex:0];
        }
        [self.judgeTitleArray bjl_insertObject:defaultDic atIndex:0];
        
        [self.judgeTitleButton setTitle:[NSString stringWithFormat:@"%@/%@", self.rightTextField.text ?: @"", self.wrongTextField.text ?: @""] forState:UIControlStateNormal];
        
        BJLAnswerSheetOption *YESOption = [self.answerSheet.options firstObject];
        YESOption.key = self.rightTextField.text ?: @"";
        
        BJLAnswerSheetOption *NOOption = [self.answerSheet.options objectAtIndex:1];
        NOOption.key = self.wrongTextField.text ?: @"";
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.timeTextField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        if (![self isValidDuration:newString]) {
            return NO;
        }
        int number = newString.intValue;
        if (number >= 1) {
            return YES;
        }
        return NO;
    }
    else if (textField == self.rightTextField || textField == self.wrongTextField) {
        NSInteger maxCount = 4;
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        if(newString.length > maxCount) {
            return NO;
        }
        return YES;
    }
    
    return YES;
}

- (BOOL)isValidDuration:(NSString *)durationString {
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:durationString]) {
        return YES;
    }
    return NO;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.answerSheet.answerType == BJLAnswerSheetType_Judgement
        && self.layout == BJLIcQuestionAnswerWindowLayout_normal) {
        return 0;
    }

    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.answerSheet.answerType == BJLAnswerSheetType_Judgement
        && self.layout == BJLIcQuestionAnswerWindowLayout_normal) {
        return 0;
    }
    return [self.answerSheet.options count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLAnswerSheetOption *option = [self.answerSheet.options objectAtIndex:indexPath.row];
    
    UICollectionViewCell *tempCell;
    if (collectionView == self.collectionView) {
        BJLIcQuestionAnswerOptionCollectionViewCell *cell;
        if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell forIndexPath:indexPath];
            [cell updateContentWithOptionKey:option.key isSelected:option.isAnswer];
        }
        bjl_weakify(self);
        [cell setOptionSelectedCallback:^(BOOL selected) {
            bjl_strongify(self);
            BJLAnswerSheetOption *option = [self.answerSheet.options objectAtIndex:indexPath.row];
            option.isAnswer = selected;
            [self updateCorrectAnswerTip];
        }];
        tempCell = cell;
    }
    else if (collectionView == self.answerOptionsCollectionView) {
        BJLIcQuestionAnswerPublishedOptionCollectionViewCell *publishedCell;
        if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
            publishedCell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_ChoosenCell forIndexPath:indexPath];
            [publishedCell updateContentWithOptionKey:option.key isSelected:option.isAnswer selectedTimes:option.choosenTimes];
        }
        else if (self.answerSheet.answerType == BJLAnswerSheetType_Judgement) {
            if (indexPath.row == 0) {
                publishedCell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_right forIndexPath:indexPath];
            }
            else {
                publishedCell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_wrong forIndexPath:indexPath];
            }
            [publishedCell updateContentWithSelected:option.isAnswer selectedTimes:option.choosenTimes];
        }
        tempCell = publishedCell;
    }
    
    return tempCell ?: [collectionView dequeueReusableCellWithReuseIdentifier:@"sth new" forIndexPath:indexPath];;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView) {
        if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
            return CGSizeMake([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight, [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight);
        }
        else {
            return CGSizeMake([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight, 75);
        }
    }
    return CGSizeMake([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight, 75);
}

#pragma mark -private
- (NSArray *)optionsArray {
    return @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H"];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionAnswerSheet:) observer:^BOOL(BJLAnswerSheet *answerSheet) {
        bjl_strongify(self);

        if (!self.room.loginUser.isTeacherOrAssistant) {
            return YES;
        }
        
        self.layout = BJLIcQuestionAnswerWindowLayout_publish;
        self.answerSheet = answerSheet;
        self.countDownTime = self.answerSheet.duration;
        [self updateContentViewAndBottomView];

        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveEndQuestionAnswerWithEndTime:) observer:(BJLMethodObserver)^BOOL(NSTimeInterval endTime) {
        bjl_strongify(self);
        
        if (!self.room.loginUser.isTeacherOrAssistant
            || (self.layout != BJLIcQuestionAnswerWindowLayout_publish)) {
            return YES;
        }
        
        self.layout = BJLIcQuestionAnswerWindowLayout_end;
        self.countDownTime = 0;
        [self stopCountDownTimer];
        self.answerSheet.endTimeInterval = endTime;
        [self updateContentViewAndBottomView];
        [self updateStatisticsData];
        return YES;
    }];

    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeQuestionAnswerWithEndTime:) observer:^BOOL(NSTimeInterval endTime) {
        bjl_strongify(self);
        
        if (!self.room.loginUser.isTeacherOrAssistant
            || (self.layout != BJLIcQuestionAnswerWindowLayout_publish)) {
            return YES;
        }
        
        self.layout = BJLIcQuestionAnswerWindowLayout_normal;
        self.countDownTime = 0;
        [self stopCountDownTimer];
        [self initialAnswerOptions];
        [self updateContentViewAndBottomView];
        
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionAnswerSubmited:) observer:^BOOL(BJLAnswerSheet *answerSheet) {
        bjl_strongify(self);
        
        if (!self.room.loginUser.isTeacherOrAssistant) {
            return YES;
        }
        
        self.answerSheet = answerSheet;
        if (self.layout == BJLIcQuestionAnswerWindowLayout_publish) {
            [self.answerOptionsCollectionView reloadData];
            self.answerSituationLabel.text = [NSString stringWithFormat:@"发布：%td人，提交：%td人", self.answerSheet.userCountParticipate, self.answerSheet.userCountSubmit];
        }
        else if (self.layout == BJLIcQuestionAnswerWindowLayout_end) {
            [self updateStatisticsData];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionAnswerDetailInfo:) observer:^BOOL((NSArray<BJLAnswerSheet *> *answerSheetArray)) {
        bjl_strongify(self);
        
        if (!self.room.loginUser.isTeacherOrAssistant) {
            return YES;
        }
        
        for (BJLAnswerSheet *answer in answerSheetArray) {
            if ([answer.ID isEqualToString:self.answerSheet.ID]) {
                self.answerSheet = answer;
                break;
            }
        }
        
        self.backButton.hidden = NO;
        self.correctAnswerLabel.hidden = NO;
        NSMutableString *correctAnswer = [[NSMutableString alloc] initWithString:@"正确答案："];
        for(BJLAnswerSheetOption *option in self.answerSheet.options) {
            if (option.isAnswer) {
                [correctAnswer appendString:[NSString stringWithFormat:@" %@", option.key]];
            }
        }
        self.correctAnswerLabel.text = correctAnswer;

        [self setContentViewController:nil contentView:self.detailContainerView];
        [self.detailTableView reloadData];
        return YES;
    }];
    
    [self makeObservingForAnswerDetailList];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.detailTableView) {
        return [self.onlineUserList count];
    }
    else {
        return [[self judgeTitleArray] count] + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.detailTableView) {
        BJLIcQuestionAnswerSheetUserDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:detailTableViewCellIdentifier forIndexPath:indexPath];
        BJLUser *user = [self.onlineUserList objectAtIndex:indexPath.row];
        
        __block BJLAnswerSheetUserDetail *detailUserInfo = nil;
        [self.answerSheet.userDetails enumerateObjectsUsingBlock:^(BJLAnswerSheetUserDetail * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.userNumber isEqualToString:user.number]) {
                detailUserInfo = [obj copy];
                *stop = YES;
            }
        }];
        
        BJLUserGroup *groupInfo = nil;
        for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
            if (group.groupID == user.groupID) {
                groupInfo = [group copy];
                break;
            }
        }

        [cell updateWithUserDetailModel:detailUserInfo
                            hasSubmited:!!detailUserInfo
                               userInfo:user
                              groupInfo:groupInfo];
        return cell;
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"judgeAnswerSheetCell" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor clearColor];
        if (indexPath.row == [[self judgeTitleArray] count]) {
            cell.textLabel.text = @"自定义";
        }
        else {
            NSDictionary *dic = [[self judgeTitleArray] objectAtIndex:indexPath.row];
            NSString *rightString = [dic bjl_stringForKey:@"1"];
            NSString *wrongString = [dic bjl_stringForKey:@"0"];
            cell.textLabel.text = [NSString stringWithFormat:@"%@/%@", rightString, wrongString];
        }
        cell.textLabel.font = [UIFont systemFontOfSize:12];
        cell.textLabel.textColor = [UIColor whiteColor];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.detailTableView) {
        return 30;
    }
    else return 25;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.detailTableView) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.detailTableView) {
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row > [[self judgeTitleArray] count]) {
        return;
    }
    
    if (indexPath.row >= [[self judgeTitleArray] count]) {
        [self.judgeTitleButton setTitle:@"自定义" forState:UIControlStateNormal];
        BJLAnswerSheetOption *YESOption = [self.answerSheet.options firstObject];
        YESOption.key = @"";
        
        BJLAnswerSheetOption *NOOption = [self.answerSheet.options objectAtIndex:1];
        NOOption.key = @"";

        self.rightTextField.text = @"";
        self.rightTextField.userInteractionEnabled = YES;
        [self.rightTextField resignFirstResponder];
        self.rightTextField.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        self.rightTextField.layer.borderWidth = onePixel;
        self.rightTextField.layer.cornerRadius = 4.0f;
        
        self.wrongTextField.userInteractionEnabled = YES;
        self.wrongTextField.text = @"";
        self.wrongTextField.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        self.wrongTextField.layer.borderWidth = onePixel;
        self.wrongTextField.layer.cornerRadius = 4.0f;
    }
    else {
        NSDictionary *dic = [[self judgeTitleArray] objectAtIndex:indexPath.row];
        NSString *rightString = [dic bjl_stringForKey:@"1"];
        NSString *wrongString = [dic bjl_stringForKey:@"0"];
        self.wrongTextField.text = wrongString;
        self.wrongTextField.layer.borderWidth = 0;
        self.wrongTextField.userInteractionEnabled = NO;
        self.wrongTextField.layer.borderWidth = 0;

        self.rightTextField.text = rightString;
        self.rightTextField.layer.borderWidth = 0;
        self.rightTextField.userInteractionEnabled = NO;
        self.rightTextField.layer.borderWidth = 0;

        [self.judgeTitleButton setTitle:[NSString stringWithFormat:@"%@/%@", rightString, wrongString] forState:UIControlStateNormal];
        
        BJLAnswerSheetOption *YESoption = [[BJLAnswerSheetOption alloc] initWithID:rightString isAnswer:NO];
        BJLAnswerSheetOption *NOoption = [[BJLAnswerSheetOption alloc] initWithID:wrongString isAnswer:NO];
        self.answerSheet.options = [NSArray arrayWithObjects:YESoption, NOoption, nil];
        
        self.rightButton.selected = YESoption.isAnswer;
        self.selectedRightIconImageView.hidden = YES;

        self.rightButton.selected = NOoption.isAnswer;
        self.selectedWrongIconImageView.hidden = YES;
    }
    self.judgeTitleTableView.hidden = YES;
    self.judgeTitleButton.selected = !self.judgeTitleButton.selected;
    self.judgeTitleIconButton.selected = self.judgeTitleButton.selected;
}

@end

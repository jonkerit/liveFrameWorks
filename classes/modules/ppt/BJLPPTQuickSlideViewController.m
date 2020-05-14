//
//  BJLPPTQuickSlideViewController.m
//  Pods
//
//  Created by HuangJie on 2017/7/5.
//  Copyright © 2017年 BaijiaYun. All rights reserved.
//

#import "BJLPPTQuickSlideViewController.h"
#import "BJLOverlayViewController.h"
#import "BJLPPTQuickSlideCell.h"
#import <BJLiveCore/BJLRoom.h>

static CGSize pptSize = {.width = 88.0, .height = 60.0};
static CGFloat miniSpaceWidth = 88 * 0.8 + 46.0;
static CGFloat miniPPTWidth = 58.0;
static NSString * const whiteboardCellReuseIdentifier = @"whiteboardSlidePageCell";
static NSString * const pptPreviewCellReuseIdentifier = @"pptPreviewSlidePageCell";

@interface BJLPPTQuickSlideViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BOOL pullToMiniSize, loaclPageIsWhiteboard, editing, waitingForUpdate;
@property (nonatomic) NSArray<BJLSlidePage *> *whiteboardSlidePages, *pptPreviewSlidePages;
@property (nonatomic) NSInteger maxWhiteboardPageCount, maxPPTPreviewPageCount; // 总数 = 索引 + 1
@property (nonatomic) NSInteger localWhiteboardIndex, localPPTPreviewIndex; // 从0开始，与对应的collectionview的index一致

@property (nonatomic) UIButton *addWhiteboardButton;
@property (nonatomic) UICollectionView *whiteboardCollectionView;
@property (nonatomic) UIView *finishEditWhiteboardView;
@property (nonatomic) UIButton *finishEditWhiteboardButton;
@property (nonatomic) UIView *pptContainerView;
@property (nonatomic) UIImageView *pullImageView;
@property (nonatomic) UICollectionView *pptPreviewCollectionView;

@end

@implementation BJLPPTQuickSlideViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.pullToMiniSize = NO;
        self.editing = NO;
        self.loaclPageIsWhiteboard = YES;
        self.localWhiteboardIndex = 0;
        self.localPPTPreviewIndex = 0;
        self.maxPPTPreviewPageCount = 0;
        self.maxWhiteboardPageCount = 1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.layer.borderWidth = BJLOnePixel;
    self.view.layer.borderColor = [UIColor bjl_grayBorderColor].CGColor;
    
    pptSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? CGSizeMake(88.0, 76.0) : CGSizeMake(88.0, 100.0);
    [self setUpCollectionView];
    [self makeObserving];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self scrollToLocalSlidePage];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, allDocuments)
         observer:^BOOL(NSArray<BJLDocument *> * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateSlidePagesWithAllSlidePages:[self.room.documentVM allSlidePages]];
             [self reloadCollectionView];
             return YES;
         }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.documentVM, currentSlidePage), BJLMakeProperty(self.room.slideshowViewController, localPageIndex)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  NSInteger localPageIndex = self.room.slideshowViewController.localPageIndex;
                  NSInteger whiteboardCount = [self.room.documentVM documentWithID:BJLBlackboardID].pageInfo.pageCount;
                  BJLSlidePage *currentSlidePage = self.room.documentVM.currentSlidePage;
                  if (localPageIndex + 1 <= whiteboardCount) {
                      self.maxWhiteboardPageCount = MIN(whiteboardCount, self.room.documentVM.currentSlidePage.documentPageIndex + 1);
                      self.maxPPTPreviewPageCount = MAX(0, currentSlidePage.documentPageIndex - self.maxWhiteboardPageCount + 1) ;
                      self.localWhiteboardIndex = localPageIndex;
                      self.loaclPageIsWhiteboard = YES;
                  }
                  else {
                      self.maxWhiteboardPageCount = whiteboardCount;
                      self.maxPPTPreviewPageCount = currentSlidePage.documentPageIndex - self.maxWhiteboardPageCount + 1;
                      self.loaclPageIsWhiteboard = NO;
                      self.localPPTPreviewIndex = localPageIndex - whiteboardCount;
                  }
                  [self reloadCollectionView];
                  [self scrollToLocalSlidePage];
              }];
    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateWhiteboardViewActions];
             return YES;
         }];
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.documentVM, didAddWhiteboardPage:),
                             BJLMakeMethod(self.room.documentVM, didDeleteWhiteboardPageWithIndex:)]
                  observer:^{
                      bjl_strongify(self);
                      self.waitingForUpdate = NO;
                  }];
}

#pragma mark - action

// 编辑白板
- (void)enterEditWhitboardMode {
    if (!self.room.featureConfig.enableMutiBoard) {
        return;
    }
    if (self.editing) {
        return;
    }
    
    // UI上控制助教的翻页权限，并给出提示
    if (self.room.loginUser.isAssistant && ![self.room.roomVM getAssistantaAuthorityWithDocumentControl]) {
        self.errorCallback(@"文档权限已被禁用");
        return;
    }

    self.editing = YES;
    [self.finishEditWhiteboardView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(@60.0);
    }];
    [self updatePPTPreviewCollectionViewHidden:YES];
    [self reloadCollectionView];
}

- (void)finishEditWhiteboard {
    if (!self.editing) {
        return;
    }
    self.editing = NO;
    [self.finishEditWhiteboardView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(@0.0);
    }];
    [self reloadCollectionView];
}

// 添加白板
- (void)addWhiteboardPage {
    if (self.room.loginUser.isTeacherOrAssistant && !self.waitingForUpdate) {
        self.waitingForUpdate = YES;
        BJLError *error = [self.room.documentVM addWhiteboardPage];
        if (error) {
            self.waitingForUpdate = NO;
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
}

// 删除白板某页
- (void)deleteWhiteboardPageIndex:(NSInteger)pageIndex {
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:@"确定删除？"
                                message:nil
                                preferredStyle:UIAlertControllerStyleAlert];
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    bjl_weakify(self);
    [alert bjl_addActionWithTitle:@"确定"
                            style:UIAlertActionStyleDestructive
                          handler:^(UIAlertAction * _Nonnull action) {
                              bjl_strongify(self);
                              if (self.room.loginUser.isTeacherOrAssistant && !self.waitingForUpdate) {
                                  self.waitingForUpdate = YES;
                                  BJLError *error = [self.room.documentVM deleteWhiteboardPageWithIndex:pageIndex];
                                  if (error) {
                                      self.waitingForUpdate = NO;
                                      [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                  }
                              }
                          }];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:NO completion:nil];
}

// 拖动非白板的 PPT 手势
- (UIPanGestureRecognizer *)setupGestureToPullPPTView:(UIView *)view {
    __block CGFloat originOffsetX = 0.0;
    __block CGPoint movingTranslation = CGPointZero;
    bjl_weakify(self);
    UIPanGestureRecognizer *panGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIPanGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        UIView *gestureView = self.pptContainerView;
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [gesture setTranslation:CGPointZero inView:self.view];
            originOffsetX = gestureView.frame.origin.x;
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            movingTranslation = [gesture translationInView:self.view];
            NSInteger offsetX = MAX(miniSpaceWidth, MIN(self.view.frame.size.width - miniPPTWidth, movingTranslation.x + originOffsetX));
            [gestureView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.view).offset(offsetX).priorityHigh();
            }];
        }
    }];
    [view addGestureRecognizer:panGesture];
    return panGesture;
}

// 按钮触发来更新非白板的 PPT 列表的位置
- (void)updatePPTViewPullPosition {
    self.pullToMiniSize = !self.pullToMiniSize;
    [self updatePPTContainerViewConstraints];
}

- (void)updatePPTContainerViewConstraints {
    if (self.pullToMiniSize) {
        self.pullImageView.image = [UIImage bjl_imageNamed:@"bjl_ic_pptpull_min"];
        [self.pptContainerView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.view).offset(self.view.frame.size.width - miniPPTWidth).priorityHigh();
        }];
    }
    else {
        self.pullImageView.image = [UIImage bjl_imageNamed:@"bjl_ic_pptpull_max"];
        [self.pptContainerView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.view).offset(miniSpaceWidth).priorityHigh();
        }];
    }
}

// 老师和助教才能添加白板
- (void)updateWhiteboardViewActions {
    if (self.room.loginUser.isTeacherOrAssistant && self.room.featureConfig.enableMutiBoard) {
        self.addWhiteboardButton.enabled = YES;
        miniSpaceWidth = 80 * 0.8 + 46.0;
        [self.addWhiteboardButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.equalTo(@46.0);
        }];
    }
    else {
        miniSpaceWidth = 80 * 0.8;
        self.addWhiteboardButton.enabled = NO;
        [self.addWhiteboardButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.equalTo(@0.0);
        }];
    }
    [self updatePPTContainerViewConstraints];
}

// 按需刷新列表
- (void)reloadCollectionView {
    if ([self cellCountWithCollectionView:self.whiteboardCollectionView] > 0) {
        [self.whiteboardCollectionView reloadData];
    }
    if (self.editing) {
        return;
    }
    BOOL pptPreviewCollectionViewHidden = [self cellCountWithCollectionView:self.pptPreviewCollectionView] <= 0;
    [self updatePPTPreviewCollectionViewHidden:pptPreviewCollectionViewHidden];
}

// 隐藏或显示非白板的 PPT 列表
- (void)updatePPTPreviewCollectionViewHidden:(BOOL)hidden {
    if (hidden) {
        self.pptContainerView.hidden = YES;
        [self.whiteboardCollectionView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(self.addWhiteboardButton.bjl_right);
            make.right.equalTo(self.finishEditWhiteboardView.bjl_left);
            make.top.bottom.equalTo(self.view);
            make.height.greaterThanOrEqualTo(@(60.0 + BJLViewSpaceM * 2)).priorityHigh();
        }];
    }
    else {
        self.pptContainerView.hidden = NO;
        [self.pptPreviewCollectionView reloadData];
        [self.whiteboardCollectionView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(self.addWhiteboardButton.bjl_right);
            make.right.equalTo(self.pptContainerView.bjl_left);
            make.top.bottom.equalTo(self.view);
            make.height.greaterThanOrEqualTo(@(60.0 + BJLViewSpaceM * 2)).priorityHigh();
        }];
    }
}

// 更新数据源
- (void)updateSlidePagesWithAllSlidePages:(NSArray<BJLSlidePage *> *)allSlidePages {
    NSMutableArray *whiteboardSlidePages = [NSMutableArray new];
    NSMutableArray *pptPreviewSlidePages = [NSMutableArray new];
    for (BJLSlidePage *slidePage in allSlidePages) {
        if ([slidePage.documentID isEqualToString:BJLBlackboardID]) {
            [whiteboardSlidePages addObject:slidePage];
        }
        else {
            [pptPreviewSlidePages addObject:slidePage];
        }
    }
    self.whiteboardSlidePages = [whiteboardSlidePages copy];
    self.pptPreviewSlidePages = [pptPreviewSlidePages copy];
}

// 获取当前的各个 PPT 列表的总页数
- (NSInteger)cellCountWithCollectionView:(UICollectionView *)collectionView {
    NSInteger cellCount = 0;
    if (collectionView == self.pptPreviewCollectionView) {
        if (self.room.loginUser.isTeacherOrAssistant) {
            cellCount = self.pptPreviewSlidePages.count;
        }
        else {
            cellCount = MIN((NSInteger)self.maxPPTPreviewPageCount, (NSInteger)self.pptPreviewSlidePages.count);
        }
    }
    else {
        if (self.room.loginUser.isTeacherOrAssistant) {
            cellCount = self.whiteboardSlidePages.count;
        }
        else {
            cellCount = MIN((NSInteger)self.maxWhiteboardPageCount, (NSInteger)self.whiteboardSlidePages.count);
        }
    }
    return cellCount;
}

#pragma mark - UICollectionView

- (void)setUpCollectionView {
    self.addWhiteboardButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, addWhiteboardButton);
        button.backgroundColor = [UIColor whiteColor];
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_ppt_add"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(addWhiteboardPage) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.addWhiteboardButton];
    [self.addWhiteboardButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.bottom.equalTo(self.view);
        make.width.equalTo(@46.0);
    }];
    
    self.whiteboardCollectionView = ({
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0.0;
        layout.minimumLineSpacing = 0.0;
        layout.itemSize = pptSize;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.allowsSelection = NO;
        collectionView.accessibilityLabel = BJLKeypath(self, whiteboardCollectionView);
        collectionView.backgroundColor = [UIColor whiteColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        [collectionView registerClass:[BJLPPTQuickSlideCell class] forCellWithReuseIdentifier:whiteboardCellReuseIdentifier];
        collectionView;
    });
    [self.view addSubview:self.whiteboardCollectionView];
    
    self.pptContainerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, pptContainerView);
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.5;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(-6.0, 0.0);
        view.layer.shadowRadius = 6.0;
        view.backgroundColor = [UIColor whiteColor];
        view;
    });
    [self.view addSubview:self.pptContainerView];
    
    [self.pptContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(miniSpaceWidth).priorityHigh();
        make.right.top.bottom.equalTo(self.view);
    }];
    [self.whiteboardCollectionView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.addWhiteboardButton.bjl_right);
        make.right.equalTo(self.pptContainerView.bjl_left);
        make.top.bottom.equalTo(self.view);
        make.height.greaterThanOrEqualTo(@(60.0 + BJLViewSpaceM * 2)).priorityHigh();
    }];
    
    UIView *pullView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = @"pullView";
        view.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(updatePPTViewPullPosition)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;
        [view addGestureRecognizer:tapGesture];
        UIPanGestureRecognizer *panGesture = [self setupGestureToPullPPTView:view];
        [tapGesture requireGestureRecognizerToFail:panGesture];
        view;
    });
    [self.pptContainerView addSubview:pullView];
    [pullView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.bottom.equalTo(self.pptContainerView);
        make.width.equalTo(@36.0).priorityHigh();
    }];
    
    self.pullImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = BJLKeypath(self, pullImageView);
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = [UIImage bjl_imageNamed:@"bjl_ic_pptpull_max"];
        imageView;
    });
    [self.pptContainerView addSubview:self.pullImageView];
    [self.pullImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(pullView);
        make.width.equalTo(@(self.pullImageView.image.size.width)).priorityHigh();
        make.height.equalTo(@(self.pullImageView.image.size.height)).priorityHigh();
    }];
    
    self.pptPreviewCollectionView = ({
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0.0;
        layout.minimumLineSpacing = 0.0;
        layout.itemSize = pptSize;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.allowsSelection = NO;
        collectionView.accessibilityLabel = BJLKeypath(self, pptPreviewCollectionView);
        collectionView.backgroundColor = [UIColor whiteColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        [collectionView registerClass:[BJLPPTQuickSlideCell class] forCellWithReuseIdentifier:pptPreviewCellReuseIdentifier];
        collectionView;
    });
    [self.pptContainerView addSubview:self.pptPreviewCollectionView];
    [self.pptPreviewCollectionView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(pullView.bjl_right).offset(2.0).priorityHigh();
        make.right.top.bottom.equalTo(self.pptContainerView);
        make.height.greaterThanOrEqualTo(@(60.0 + BJLViewSpaceM * 2)).priorityHigh();
    }];
    
    self.finishEditWhiteboardView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.5;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(-6.0, 0.0);
        view.layer.shadowRadius = 6.0;
        view;
    });
    [self.view addSubview:self.finishEditWhiteboardView];
    [self.finishEditWhiteboardView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.top.bottom.equalTo(self.view);
        make.width.equalTo(@0.0);
    }];
    
    self.finishEditWhiteboardButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor bjl_blueBrandColor];
        button.layer.cornerRadius = 6.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"完成" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(finishEditWhiteboard) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.finishEditWhiteboardView addSubview:self.finishEditWhiteboardButton];
    [self.finishEditWhiteboardButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.finishEditWhiteboardView);
        make.width.equalTo(@40.0).priorityHigh();
        make.height.equalTo(@36.0).priorityHigh();
        make.width.height.lessThanOrEqualTo(self.finishEditWhiteboardView);
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self cellCountWithCollectionView:collectionView];
}

// 单击选中，长按编辑
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    bjl_weakify(self);
    NSInteger whiteboardCount = [self.room.documentVM documentWithID:BJLBlackboardID].pageInfo.pageCount;
    if (collectionView == self.pptPreviewCollectionView) {
        BJLPPTQuickSlideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:pptPreviewCellReuseIdentifier forIndexPath:indexPath];
        [cell setSingleTapCallback:^{
            bjl_strongify(self);
            [self selectPPTPreviewCollectionViewAtIndex:indexPath.row];
        }];
        BJLSlidePage *slidePage = [self.pptPreviewSlidePages bjl_objectAtIndex:indexPath.row];
        [cell updateContentWithSlidePage:slidePage whiteboardCount:whiteboardCount imageSize:pptSize];
        cell.selected = self.loaclPageIsWhiteboard ? NO : (indexPath.row == self.localPPTPreviewIndex);
        return cell;
    }
    else {
        BJLPPTQuickSlideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:whiteboardCellReuseIdentifier forIndexPath:indexPath];
        [cell setSingleTapCallback:^{
            bjl_strongify(self);
            [self selectWhiteboardCollectionViewAtIndex:indexPath.row];
        }];
        if (self.room.loginUser.isTeacherOrAssistant) {
            [cell setLongPressCallback:^{
                bjl_strongify(self);
                [self enterEditWhitboardMode];
            }];
            [cell setDeletePageCallback:^(NSString * _Nonnull documentID, NSInteger pageIndex) {
                bjl_strongify(self);
                if ([documentID isEqualToString:BJLBlackboardID]) {
                    [self deleteWhiteboardPageIndex:pageIndex];
                }
            }];
        }
        BJLSlidePage *slidePage = [self.whiteboardSlidePages bjl_objectAtIndex:indexPath.row];
        [cell updateContentWithSlidePage:slidePage whiteboardCount:whiteboardCount imageSize:pptSize];
        [cell updateEditing:self.editing];
        cell.selected = self.loaclPageIsWhiteboard ? (indexPath.row == self.localWhiteboardIndex) : NO;
        return cell;
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return pptSize;
}

#pragma mark - scroll

- (void)selectWhiteboardCollectionViewAtIndex:(NSInteger)index {
    // UI上控制助教的翻页权限，并给出提示
    if (self.room.loginUser.isAssistant && ![self.room.roomVM getAssistantaAuthorityWithDocumentControl]) {
        self.errorCallback(@"文档权限已被禁用");
        return;
    }
    if (self.room.loginUser.isStudent && self.room.featureConfig.disableStudentChangePPTPage) {
        self.errorCallback(@"文档权限已被禁用");
        return;
    }

    self.loaclPageIsWhiteboard = YES;
    self.localWhiteboardIndex = index;
    [self.room.slideshowViewController setLocalPageIndex:index];
    [self reloadCollectionView];
    [self scrollToLocalSlidePage];
    if (self.selectPPTCallback) {
        self.selectPPTCallback();
    }
}

- (void)selectPPTPreviewCollectionViewAtIndex:(NSInteger)index {
    // UI上控制助教的翻页权限，并给出提示
    if (self.room.loginUser.isAssistant && ![self.room.roomVM getAssistantaAuthorityWithDocumentControl]) {
        self.errorCallback(@"文档权限已被禁用");
        return;
    }
    if (self.room.loginUser.isStudent && self.room.featureConfig.disableStudentChangePPTPage) {
        self.errorCallback(@"文档权限已被禁用");
        return;
    }
    
    self.loaclPageIsWhiteboard = NO;
    NSInteger whiteboardCount = [self.room.documentVM documentWithID:BJLBlackboardID].pageInfo.pageCount;
    self.localPPTPreviewIndex = index;
    [self.room.slideshowViewController setLocalPageIndex:whiteboardCount + index];
    [self reloadCollectionView];
    [self scrollToLocalSlidePage];
    if (self.selectPPTCallback) {
        self.selectPPTCallback();
    }
}

- (void)scrollToLocalSlidePage {
    // 滑动当前页到中间
    if (self.loaclPageIsWhiteboard) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.localWhiteboardIndex inSection:0];
        if (indexPath.row >= [self.whiteboardCollectionView numberOfItemsInSection:0]) {
            return;
        }
        [self.whiteboardCollectionView scrollToItemAtIndexPath:indexPath
                                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                      animated:NO];
    }
    else {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.localPPTPreviewIndex inSection:0];
        if (indexPath.row >= [self.pptPreviewCollectionView numberOfItemsInSection:0]) {
            return;
        }
        [self.pptPreviewCollectionView scrollToItemAtIndexPath:indexPath
                                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                      animated:NO];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.whiteboardCollectionView.delegate = nil;
    self.whiteboardCollectionView.dataSource = nil;
    self.pptPreviewCollectionView.delegate = nil;
    self.pptPreviewCollectionView.dataSource = nil;
}

@end

//
//  BJLScAnswerSheetResultViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import "BJLScWindowViewController+protected.h"

#import "BJLScAnswerSheetResultViewController.h"
#import "BJLScAnswerSheetCell.h"
#import "BJLScAppearance.h"

static NSString * const cellReuseIdentifier = @"resultOptionCell";

@interface BJLScAnswerSheetResultViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) BJLAnswerSheet *answerSheet;

@property (nonatomic) NSArray <BJLAnswerSheetOption *> *selectedOptions;
@property (nonatomic) UIView *answerResultContentView;
@property (nonatomic) UICollectionView *optionsResultView;

@end

@implementation BJLScAnswerSheetResultViewController

- (instancetype)initWithAnswerSheet:(BJLAnswerSheet *)answerSheet {
    self = [super init];
    if (self) {
        self.answerSheet = answerSheet;
        [self prepareToOpen];
    }
    return self;
}

- (void)dealloc {
    if (self.optionsResultView) {
        self.optionsResultView.delegate = nil;
        self.optionsResultView.dataSource = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.doubleTapToMaximize = NO;

    self.bottomBar.hidden = YES;
    self.panToResize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.topBarBackgroundViewHidden = YES;
    self.topBar.backgroundColor = [self blueColor];
    self.view.layer.cornerRadius = 8.0;
    self.view.clipsToBounds = YES;
    self.view.layer.borderWidth = BJLScOnePixel;
    self.view.layer.borderColor = [UIColor bjlsc_grayLineColor].CGColor;
    
    [self showCorrectAnswers];
}

- (void)prepareToOpen {
    NSMutableArray <BJLAnswerSheetOption *> *optionsArray = [NSMutableArray new];
    for (BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.key.length && option.selected) {
            [optionsArray addObject:option];
        }
    }
    self.selectedOptions = [optionsArray copy];

    self.caption = @"答题结果";
    CGFloat optionHeight = [self.selectedOptions count] < 5 ? answerOptionButtonHeight : answerOptionButtonHeight * 2 + 15 * 2;
    self.minWindowHeight = 145 + optionHeight;
    self.minWindowWidth = 250.0;

    CGFloat relativeWidth = 0.2;
    CGFloat relativeHeight = 0.2;
    self.relativeRect = [self rectInBounds:CGRectMake(0.25, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
}

- (void)showCorrectAnswers {
    // top bar
    UIView *topGapLine = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        bjl_return view;
    });
    [self.topBar addSubview:topGapLine];
    [topGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.topBar);
        make.height.equalTo(@(BJLScOnePixel));
    }];
    
    UILabel *tipLabel = [self labelWithTitle:@"我的答案：" color:[self grayTextColor]];
    [self.answerResultContentView addSubview:tipLabel];
    [tipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.answerResultContentView).offset(BJLScControlSize);
        make.left.equalTo(self.answerResultContentView).offset(15.0);
        make.right.equalTo(self.answerResultContentView).offset(-15.0);
        make.height.equalTo(@(25));
    }];
    
    UIView *view = [UIView new];
    [self.answerResultContentView addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(tipLabel.bjl_bottom).offset(BJLScViewSpaceL);
        make.left.right.equalTo(tipLabel);
        make.centerX.equalTo(self.answerResultContentView);
    }];

    if ([self.selectedOptions count]) {
        // options view
        self.optionsResultView = ({
            // layout
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            layout.sectionInset = UIEdgeInsetsZero;
            layout.scrollDirection = UICollectionViewScrollDirectionVertical;

            // view
            UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
            view.backgroundColor = [UIColor clearColor];
            view.showsHorizontalScrollIndicator = NO;
            view.bounces = NO;
            view.alwaysBounceVertical = YES;
            view.pagingEnabled = YES;
            view.dataSource = self;
            view.delegate = self;
            [view registerClass:[BJLScAnswerSheetCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
            view.accessibilityLabel = BJLKeypath(self, optionsResultView);
            view;
        });

        CGFloat optionsViewHeight = 0;
        CGFloat optionsViewWidth = 0;
        BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        optionsViewHeight = ([self.selectedOptions count] <= 4
                             ? answerOptionButtonHeight
                             : answerOptionButtonHeight * 2 + (isIphone ? 10 : 15) * 2); // 1~2 行选项
        optionsViewWidth = [self.selectedOptions count] <= 4
        ? (answerOptionButtonHeight * [self.selectedOptions count] + (isIphone ? 10 : 15) * ([self.selectedOptions count] - 1))
        : (answerOptionButtonHeight * 4 + (isIphone ? 10 : 15) * 3);

        [view addSubview:self.optionsResultView];
        [self.optionsResultView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.center.equalTo(view);
            make.height.equalTo(@(optionsViewHeight));
            make.width.equalTo(@(optionsViewWidth));
        }];
    }
    else {
        UILabel *label = [self labelWithTitle:@"您未参与答题~" color:[self grayTextColor]];
        label.textAlignment = NSTextAlignmentCenter;
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.left.right.equalTo(view);
            make.height.equalTo(@(30));
        }];
    }
    
    NSString *answerString = @"";
    for (BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.key.length && option.isAnswer) {
            answerString = [answerString stringByAppendingString:option.key];
            answerString = [answerString stringByAppendingString:@" "];
        }
    }

    UILabel *correctAnswerLabel = [self labelWithTitle:[NSString stringWithFormat:@"正确答案：%@", answerString] color:[self grayTextColor]];
    [self.answerResultContentView addSubview:correctAnswerLabel];
    [correctAnswerLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(view.bjl_bottom).offset(BJLScViewSpaceL);
        make.left.right.equalTo(tipLabel);
        make.height.equalTo(@(25.0));
        make.bottom.equalTo(self.answerResultContentView.bjl_bottom).offset(-BJLScViewSpaceL);
    }];

    [self setContentViewController:nil contentView:self.answerResultContentView];
}

#pragma mark - override
- (void)close {    
    if (self.closeCallback) {
        self.closeCallback();
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return ([self.selectedOptions count] / 4) + !!([self.selectedOptions count] % 4);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (([self.selectedOptions count] / 4) > section) ? 4 : ([self.selectedOptions count] % 4);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.section * 4 + indexPath.row;

    BJLAnswerSheetOption *option = [[self.selectedOptions bjl_objectAtIndex:index] bjl_as:[BJLAnswerSheetOption class]];
    BJLScAnswerSheetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell updateContentWithSelectedKey:option.key isCorrect:option.isAnswer];
    return cell;
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self itemSize];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                layout:(UICollectionViewFlowLayout *)collectionViewLayout
insetForSectionAtIndex:(NSInteger)section {

    CGSize itemSize = [self itemSize];
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat itemGap = (isIphone ? 10 : 15);
    NSInteger numberOfItems = [collectionView numberOfItemsInSection:section];
    CGFloat combinedItemWidth = (numberOfItems * itemSize.width) + ((numberOfItems - 1) * itemGap);
    if (numberOfItems <= 4) {
        CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
        CGFloat screenScale = [UIScreen mainScreen].scale;
        padding = floor(padding * screenScale) / screenScale;
        return UIEdgeInsetsMake(section != 0 ? itemGap : 0.0, padding, 0.0, padding);
    }
    else {
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
}

- (CGSize)itemSize {
    return CGSizeMake(answerOptionButtonHeight, answerOptionButtonHeight);
}

#pragma mark - getters
- (UIView *)answerResultContentView {
    if (!_answerResultContentView) {
        _answerResultContentView = [UIView new];
        _answerResultContentView.backgroundColor = [UIColor whiteColor];
        _answerResultContentView.clipsToBounds = YES;
        _answerResultContentView.layer.masksToBounds = YES;
        _answerResultContentView.layer.cornerRadius = 4.5;
        _answerResultContentView.accessibilityLabel = BJLKeypath(self, answerResultContentView);
    }
    return _answerResultContentView;
}

#pragma mark - private

- (UILabel *)labelWithTitle:(NSString *)title color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textColor = color;
    label.font = [UIFont systemFontOfSize:12.0];
    label.accessibilityLabel = title.length ? title : @"";
    label.text = title;
    return label;
}

- (UIColor *)grayTextColor {
    return [UIColor bjl_colorWithHexString:@"#666666"];
}

- (UIColor *)blueColor {
    return [UIColor bjl_colorWithHexString:@"#1694FF"];
}

@end

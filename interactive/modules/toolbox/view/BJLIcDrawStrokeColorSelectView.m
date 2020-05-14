//
//  BJLIcStrokeColorSelectView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/7.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcDrawStrokeColorSelectView.h"
#import "BJLIcAppearance.h"
#import "BJLIcToolboxOptionCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDrawStrokeColorSelectView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *strokeColorsView;
@property (nonatomic) NSArray *strokeColors;

@property (nonatomic) NSString *currentColor;

@end

@implementation BJLIcDrawStrokeColorSelectView

- (void)dealloc {
    self.strokeColorsView.dataSource = nil;
    self.strokeColorsView.delegate = nil;
}

#pragma mark - subviews

- (void)setupSubviews {
    [super setupSubviews];
    
    self.strokeColorsView = ({
        UICollectionView *collectionView = [BJLIcDrawSelectionBaseView createSelectCollectionViewWithCellClass:[BJLIcToolboxOptionCell class]
                                                                                                   itemSpacing:10.0
                                                                                                      itemSize:CGSizeMake(32.0, 32.0)];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        bjl_return collectionView;
    });
    [self addSubview:self.strokeColorsView];
    [self.strokeColorsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(0.0, 6.0, 0.0, 6.0));
    }];
}

#pragma mark - observers

- (void)setupObservers {
    if (!self.room) {
        return;
    }
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, strokeColor)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self.strokeColorsView reloadData];
             return YES;
         }];
}

#pragma mark - setting

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.strokeColors.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcToolboxOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:drawSelectionCellReuseIdentifier forIndexPath:indexPath];
    NSString *strokeColor = [self.strokeColors bjl_objectAtIndex:indexPath.row];
    UIImage *colorIcon = [UIImage bjl_imageWithColor:[UIColor bjl_colorWithHexString:strokeColor]
                                                 size:CGSizeMake(32.0, 32.0)];
    cell.showSelectBorder = YES;
    [cell updateContentWithOptionIcon:colorIcon
                         selectedIcon:nil
                          description:nil
                           isSelected:[strokeColor isEqualToString:self.room.drawingVM.strokeColor]];
    bjl_weakify(self);
    [cell setSelectCallback:^(BOOL selected) {
        bjl_strongify(self);
        self.room.drawingVM.strokeColor = strokeColor;
        self.room.drawingVM.shouldRejectColorGranted = YES;
        if (self.room.drawingVM.fillColor) {
            // !!!: fillColor 不为空代表实心图形，需要根据调色板的选择修改填充色
            self.room.drawingVM.fillColor = strokeColor;
        }
    }];
    return cell;
}

#pragma mark - getters

- (NSArray *)strokeColors {
    if (!_strokeColors) {
        _strokeColors = @[@"#F44336", @"#E91E63", @"#D500F9", @"#3D5AFE",
                          @"#03A9F4", @"#00BCD4", @"#4CAF50", @"#8BC34A",
                          @"#FFEB3B", @"#FFC107", @"#FF9800", @"#FF5722",
                          @"#795548", @"#212121", @"#9E9E9E", @"#FFFFFF"];
    }
    return _strokeColors;
}

@end

NS_ASSUME_NONNULL_END

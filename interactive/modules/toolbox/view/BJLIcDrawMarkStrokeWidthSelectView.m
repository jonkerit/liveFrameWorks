//
//  BJLIcDrawMarkStrokeWidthSelectView.m
//  BJLiveUI
//
//  Created by HuangJie on 2020/1/6.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDrawMarkStrokeWidthSelectView.h"
#import "BJLIcAppearance.h"
#import "BJLIcToolboxOptionCell.h"

@interface BJLIcDrawMarkStrokeWidthSelectView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *markStrokeWidthsView;
@property (nonatomic) NSArray *markStrokeWidths;

@property (nonatomic) NSInteger currentWidthIndex;

@end

@implementation BJLIcDrawMarkStrokeWidthSelectView

- (void)dealloc {
    self.markStrokeWidthsView.dataSource = nil;
    self.markStrokeWidthsView.delegate = nil;
}

#pragma mark - subviews

- (void)setupSubviews {
    [super setupSubviews];
    
    self.markStrokeWidthsView = ({
        UICollectionView *collectionView = [BJLIcDrawSelectionBaseView createSelectCollectionViewWithCellClass:[BJLIcToolboxOptionCell class]
                                                                                                   itemSpacing:6.0
                                                                                                      itemSize:CGSizeMake(32.0, 32.0)];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        bjl_return collectionView;
    });
    [self addSubview:self.markStrokeWidthsView];
    [self.markStrokeWidthsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(0.0, 6.0, 0.0, 6.0));
    }];
}

#pragma mark - observers

- (void)setupObservers {
    if (!self.room) {
        return;
    }
    
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, doodleStrokeWidth)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        for (NSInteger index = 0; index < self.markStrokeWidths.count; index++) {
            CGFloat strokeWidth = [[self.markStrokeWidths bjl_objectAtIndex:index] bjl_floatValue];
            if (fabs(strokeWidth - self.room.drawingVM.doodleStrokeWidth) <= FLT_MIN) {
                self.currentWidthIndex = index;
                break;
            }
        }
        [self.markStrokeWidthsView reloadData];
        return YES;
    }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.drawingVM, strokeColor),
                         BJLMakeProperty(self.room.drawingVM, strokeAlpha)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self.markStrokeWidthsView reloadData];
    }];
}

#pragma mark - setting

- (void)setMarkStrokeWidthWithIndex:(NSInteger)index {
    self.room.drawingVM.doodleStrokeWidth = [[self.markStrokeWidths bjl_objectAtIndex:index] integerValue];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.markStrokeWidths.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcToolboxOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:drawSelectionCellReuseIdentifier forIndexPath:indexPath];
    NSInteger strokeWidth = [[self.markStrokeWidths bjl_objectAtIndex:indexPath.row] bjl_integerValue];
    CGSize iconSize = CGSizeMake(16.0, (CGFloat)strokeWidth);
    UIImage *normalIcon = [UIImage bjl_imageWithColor:[UIColor colorWithWhite:1.0 alpha:0.5] size:iconSize];
    UIImage *selectedIcon = [UIImage bjl_imageWithColor:[UIColor bjl_colorWithHexString:self.room.drawingVM.strokeColor alpha:self.room.drawingVM.strokeAlpha] size:iconSize];
    BOOL selected = (indexPath.row == self.currentWidthIndex);
    [cell updateContentWithOptionIcon:normalIcon
                         selectedIcon:selectedIcon
                          description:nil
                           isSelected:selected];
    
    bjl_weakify(self);
    [cell setSelectCallback:^(BOOL selected) {
        bjl_strongify(self);
        [self setMarkStrokeWidthWithIndex:indexPath.row];
    }];
    return cell;
}

#pragma mark - getters

- (NSArray *)markStrokeWidths {
    if (!_markStrokeWidths) {
        _markStrokeWidths = @[@8.0, @12.0, @14.0, @24.0];
    }
    return _markStrokeWidths;
}

@end

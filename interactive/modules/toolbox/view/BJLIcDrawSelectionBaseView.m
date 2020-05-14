//
//  BJLIcDrawSelectionBaseView.m
//  BJLiveUI
//
//  Created by HuangJie on 2020/1/6.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcDrawSelectionBaseView.h"

NSString * const drawSelectionCellReuseIdentifier = @"drawSelectionCell";

@implementation BJLIcDrawSelectionBaseView

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
        [self setupSubviews];
        [self setupObservers];
    }
    return self;
}

- (void)setupSubviews {
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    self.layer.shadowRadius = 10.0;
    
    // 毛玻璃背景
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = ({
        UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 6.0;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        view;
    });
    [self addSubview:effectView];
    [effectView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (void)setupObservers {
}

+ (UICollectionView *)createSelectCollectionViewWithCellClass:(Class)cellClass itemSpacing:(CGFloat)itemSpacing itemSize:(CGSize)itemSize {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = itemSpacing;
    layout.minimumLineSpacing = itemSpacing;
    layout.sectionInset = UIEdgeInsetsMake(itemSpacing, 0.0, itemSpacing, 0.0);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = itemSize;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.bounces = YES;
    collectionView.alwaysBounceVertical = YES;
    collectionView.pagingEnabled = NO;
    collectionView.scrollEnabled = NO;
    if (@available(iOS 11.0, *)) {
        collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [collectionView registerClass:cellClass forCellWithReuseIdentifier:drawSelectionCellReuseIdentifier];
    
    return collectionView;
}

@end

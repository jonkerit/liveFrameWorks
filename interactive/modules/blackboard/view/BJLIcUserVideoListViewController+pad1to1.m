//
//  BJLIcUserVideoListViewController+pad1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController+pad1to1.h"
#import "BJLIcUserVideoListViewController+private.h"

@implementation BJLIcUserVideoListViewController (pad1to1)

- (void)makePad1to1Subviews {
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    self.effectView.userInteractionEnabled = NO;
    [self.view addSubview:self.effectView];
    [self.effectView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 视频列表
    self.videoCollectionView = ({
        // layout: 不要设置 itemSize，触发 UICollectionViewDelegateFlowlayout
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = itemSpacing;
        layout.minimumLineSpacing = 16.0;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.bounces = YES;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.pagingEnabled = NO;
        collectionView.scrollEnabled = NO;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [collectionView registerClass:[BJLIcUserSeatCell class] forCellWithReuseIdentifier:cellReuseIdentifierFor1to1];
        bjl_return collectionView;
    });
    [self.view addSubview:self.videoCollectionView];
    [self.videoCollectionView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (CGSize)pad1to1ItemSize {
    CGFloat itemWidth = self.videoCollectionView.bounds.size.width;
    CGFloat itemHeight = itemWidth / [BJLIcAppearance sharedAppearance].videoAspectRatio;
    
    // 根据屏幕 scale 丢弃部分 itemHeight 精度，保证计算值与屏幕实际渲染效果一致
    CGFloat screenScale = [UIScreen mainScreen].scale;
    itemHeight = floor(itemHeight * screenScale) / screenScale + 40.0;
    
    return CGSizeMake(itemWidth, itemHeight);
}

- (NSInteger)pad1to1CollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

@end

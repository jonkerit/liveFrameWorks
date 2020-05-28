//
//  BJLIcUserVideoListViewController+padUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController+padUserVideoUpside.h"
#import "BJLIcUserVideoListViewController+private.h"

@implementation BJLIcUserVideoListViewController (padUserVideoUpside)

- (void)makePadUserVideoUpsideSubviews {
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
        layout.minimumLineSpacing = itemSpacing;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
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
        [collectionView registerClass:[BJLIcUserSeatCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
        bjl_return collectionView;
    });
    [self.view addSubview:self.videoCollectionView];
    [self.videoCollectionView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (CGSize)padUserVideoUpsideItemSize {
    if (!self.videoUsers.count) {
        return CGSizeZero;
    }
    
    CGFloat itemWidth = 0.0;
    CGFloat itemHeight = self.videoCollectionView.bounds.size.height;
    NSInteger itemCount = self.videoUsers.count;
    if (itemCount > [BJLIcAppearance sharedAppearance].fullSizedVideosCount) {
        itemWidth = (self.videoCollectionView.bounds.size.width - (itemCount - 1) * itemSpacing) / self.videoUsers.count ;
    }
    else {
        itemWidth = itemHeight * [BJLIcAppearance sharedAppearance].videoAspectRatio;
    }
    
    // 根据屏幕 scale 丢弃部分 itemWidth 精度，保证计算值与屏幕实际渲染效果一致
    CGFloat screenScale = [UIScreen mainScreen].scale;
    itemWidth = floor(itemWidth * screenScale) / screenScale;
    
    return CGSizeMake(itemWidth, itemHeight);
}

- (NSInteger)padUserVideoUpsideCollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.videoUsers.count;
}

@end

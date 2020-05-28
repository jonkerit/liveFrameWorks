//
//  BJLIcUserVideoListViewController+padUserVideoDownside.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserVideoListViewController (padUserVideoDownside)

- (void)makePadUserVideoDownsideSubviews;
- (CGSize)padUserVideoDownsideItemSize;
- (NSInteger)padUserVideoDownsideCollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

@end

NS_ASSUME_NONNULL_END

//
//  BJLIcUserVideoListViewController+padUserVideoUpside.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserVideoListViewController (padUserVideoUpside)

- (void)makePadUserVideoUpsideSubviews;
- (CGSize)padUserVideoUpsideItemSize;
- (NSInteger)padUserVideoUpsideCollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

@end

NS_ASSUME_NONNULL_END

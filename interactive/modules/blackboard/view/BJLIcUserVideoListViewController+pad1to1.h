//
//  BJLIcUserVideoListViewController+pad1to1.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserVideoListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserVideoListViewController (pad1to1)

- (void)makePad1to1Subviews;
- (CGSize)pad1to1ItemSize;
- (NSInteger)pad1to1CollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

@end

NS_ASSUME_NONNULL_END

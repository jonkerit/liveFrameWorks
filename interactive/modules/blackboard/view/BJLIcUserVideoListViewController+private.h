//
//  BJLIcUserVideoListViewController+private.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcUserVideoListViewController.h"
#import "BJLIcUserSeatCell.h"
#import "BJLIcAppearance.h"

#define itemSpacing (1.0 / [UIScreen mainScreen].scale)

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserVideoListViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) NSMutableArray<BJLMediaUser *> *videoUsers;
@property (nonatomic, readwrite) NSMutableDictionary *userMediaInfoViews;
@property (nonatomic) UIView *effectView;
@property (nonatomic) UICollectionView *videoCollectionView;

@end

NS_ASSUME_NONNULL_END

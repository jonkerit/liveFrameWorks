//
//  BJLIcDrawSelectionBaseView.h
//  BJLiveUI
//
//  Created by HuangJie on 2020/1/6.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const drawSelectionCellReuseIdentifier;

@interface BJLIcDrawSelectionBaseView : UIView

@property (nonatomic, readonly, weak) BJLRoom *room;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)setupSubviews;

- (void)setupObservers;

+ (UICollectionView *)createSelectCollectionViewWithCellClass:(nullable Class)cellClass
                                                  itemSpacing:(CGFloat)itemSpacing
                                                     itemSize:(CGSize)itemSize;

@end

NS_ASSUME_NONNULL_END

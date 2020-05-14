//
//  BJLContentView.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-02-22.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLConstants.h>

@class BJLPreviewItem;

NS_ASSUME_NONNULL_BEGIN

@interface BJLContentView : UIView

// contentView.superview is its container
@property (nonatomic, readonly, nullable) UIView *content;
@property (nonatomic, readonly) BJLPreviewItem *item;

@property (nonatomic, copy, nullable) void (^toggleTopBarCallback)(id _Nullable sender);
@property (nonatomic, copy, nullable) void (^showMenuCallback)(id _Nullable sender);

@property (nonatomic) NSInteger pageIndex, pageCount;

@property (nonatomic) BOOL showsClearDrawingButton;
@property (nonatomic, copy, nullable) void (^clearDrawingCallback)(id _Nullable sender);

- (void)updateWithPreviewItem:(BJLPreviewItem *)item;

- (void)updateViewsWithItem:(BJLPreviewItem *)item;

- (void)updateViewsForHorizontal:(BOOL)isHorizontal;

- (void)updateViewWithNetWorkLossRateStatus:(BJLNetworkStatus)status;

- (void)removeContent;

@end

NS_ASSUME_NONNULL_END

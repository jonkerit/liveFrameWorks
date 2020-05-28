//
//  BJLPreviewCell.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-06-05.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLConstants.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLPreviewCellID_view, // PPT
* const BJLPreviewCellID_view_label, // video teacher, students, recording
* const BJLPreviewCellID_avatar_label, // audio teacher, students - hasVideo?
* const BJLPreviewCellID_avatar_label_buttons; // request students

@interface BJLPreviewCell : UICollectionViewCell

@property (nonatomic, copy) void (^doubleTapsCallback)(BJLPreviewCell *cell);
@property (nonatomic, copy) void (^actionCallback)(BJLPreviewCell *cell, BOOL allowed);

- (void)updateWithView:(UIView *)view videoRatio:(CGFloat)videoRatio;
- (void)updateLoadingViewHidden:(BOOL)hidden angle:(CGFloat)angle;
- (void)updateWithView:(UIView *)view title:(NSString *)title videoRatio:(CGFloat)videoRatio;
- (void)updateWithLikeCount:(NSInteger)count hidden:(BOOL)hidden;
- (void)updateWithImageURLString:(NSString *)imageURLString title:(NSString *)title hasVideo:(BOOL)hasVideo;

- (void)updateViewWithNetWorkLossRateStatus:(BJLNetworkStatus)status;

+ (CGSize)cellSize;
+ (NSArray<NSString *> *)allCellIdentifiers;

@end

NS_ASSUME_NONNULL_END

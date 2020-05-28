//
//  BJLIcUserSeatCell.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const cellReuseIdentifier = @"userSeatCell";
static NSString * const cellReuseIdentifierFor1to1 = @"userSeatCell1to1";

@interface BJLIcUserSeatCell : UICollectionViewCell

@property (nonatomic, nullable, copy) void (^singleTapCallback)(void);

@property (nonatomic, readonly) UIView *mediaInfoContainerView;

- (void)updateContentWithUser:(BJLUser *)user leavSeat:(BOOL)leaveSeat;

@end

NS_ASSUME_NONNULL_END

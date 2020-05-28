//
//  BJLScImageCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/9.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScImageCell : UICollectionViewCell

@property (nonatomic, readonly) UIImageView *imageView;

@property (nonatomic, nullable) void (^hideCallback)(void);
@property (nonatomic, nullable) void (^saveImageCallback)(UIImage *image);
@property (nonatomic, nullable) void (^cancelStickyCallback)(void);

- (void)updateWithMessage:(BJLMessage *)message isStickyMessage:(BOOL)isStickyMessage;

@end

NS_ASSUME_NONNULL_END

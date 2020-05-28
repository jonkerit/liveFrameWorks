//
//  BJLIcDrawTextOptionView.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/12.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDrawTextOptionView : UIView

@property (nonatomic, readonly) CGSize fitableSize;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (void)remarkConstraintsWithPosition:(BJLIcRectPosition)position;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

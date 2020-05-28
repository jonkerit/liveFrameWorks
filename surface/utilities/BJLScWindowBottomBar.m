//
//  BJLScWindowBottomBar.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-25.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase+Foundation.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLScWindowBottomBar.h"

#import "BJLScAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLScWindowBottomBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self->_backgroundView = ({
            UIImageView *imageView = [UIImageView new];
            imageView.userInteractionEnabled = NO;
            imageView.accessibilityLabel = BJLKeypath(self, backgroundView);
            imageView.image = [UIImage bjlsc_imageNamed:@"window_bottombar"];
            [self addSubview:imageView];
            bjl_return imageView;
        });
        
        
        self->_resizeHandleView = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, resizeHandleView);
            [self addSubview:view];
            bjl_return view;
        });
        
        self->_resizeHandleImageView = ({
            UIImageView *imageView = [UIImageView new];
            imageView.image = [UIImage bjlsc_imageNamed:@"window_triangle"];
            [self.resizeHandleView addSubview:imageView];
            bjl_return imageView;
        });
        
        [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        [self.resizeHandleView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.bottom.right.equalTo(self);
            make.width.height.equalTo(@(userWindowDefaultBarHeight));
        }];
        
        [self.resizeHandleImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.bottom.right.equalTo(self.resizeHandleView);
            make.width.height.equalTo(@16.0);
        }];
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END

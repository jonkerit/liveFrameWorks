//
//  BJLIcVideosGridCell.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/16.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcVideosGridCell.h"
#import "BJLIcUserMediaInfoView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcVideosGridCell ()

// media info
@property (nonatomic, readwrite) UIView *mediaInfoContainerView;

@end

@implementation BJLIcVideosGridCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *subView in self.mediaInfoContainerView.subviews) {
        [subView removeFromSuperview];
    }
}

#pragma mark - subviews

- (void)setupSubviews {
    self.mediaInfoContainerView = [[UIView alloc] init];
    [self.contentView addSubview:self.mediaInfoContainerView];
    [self.mediaInfoContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView);
    }];
}

@end

NS_ASSUME_NONNULL_END

//
//  BJLIcLiveStartView.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/17.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcLiveStartView.h"
#import "BJLIcAppearance.h"

@interface BJLIcLiveStartView ()

@property (nonatomic) UIButton *liveStartButton;

@end

@implementation BJLIcLiveStartView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    UIView *shadowView = ({
        UIView *view = [UIView new];
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.3;
        view.layer.shadowColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 2.0);
        view.layer.shadowRadius = 5.0;
        view;
    });
    [self addSubview:shadowView];
    [shadowView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    self.liveStartButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 4.0;
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, [BJLIcAppearance sharedAppearance].liveStartViewSpace);
        button.titleEdgeInsets = UIEdgeInsetsMake(0, [BJLIcAppearance sharedAppearance].liveStartViewSpace, 0, 0);
        [button setTitle:@"开始上课" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_popover_livestart"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(sendLiveStart) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [shadowView addSubview:self.liveStartButton];
    [self.liveStartButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(shadowView);
    }];
}

- (void)sendLiveStart {
    if (self.liveStartCallback) {
        if (self.liveStartCallback()) {
            [self removeFromSuperview];
        }
    }
}

@end

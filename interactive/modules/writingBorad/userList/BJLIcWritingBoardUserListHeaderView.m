//
//  BJLIcWritingBoardUserListHeaderView.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/11/13.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWritingBoardUserListHeaderView.h"
#import "BJLIcAppearance.h"

@interface BJLIcWritingBoardUserListHeaderView ()

@end

@implementation BJLIcWritingBoardUserListHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self makeSubViews];
    }
    return self;
}

#pragma mark - private

- (void)makeSubViews {
    self.backgroundColor = [UIColor bjl_colorWithHex:0XFFFFFF alpha:0.05];
    bjl_weakify(self);
    UITapGestureRecognizer *tagGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        bjl_returnIfRobot(1.0);
        if (self.tapCallback) {
            self.openButton.selected = !self.openButton.selected;
            self.tapCallback(self.openButton.selected);
        }
    }];
    [self addGestureRecognizer:tagGesture];

    self.groupNameLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:12];
        label.numberOfLines = 1;
        label.textColor = [UIColor bjl_colorWithHex:0XEDEDEE];
        [self addSubview:label];
        label;
    });
    
    self.openButton = ({
        UIButton *button = [BJLButton new];
        button.accessibilityLabel = BJLKeypath(self, openButton);;
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_ic_usergroup_close"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_ic_usergroup_open"] forState:UIControlStateSelected];
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        button.userInteractionEnabled = NO;
        [self addSubview:button];
        button;
    });
        
    [self.openButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self);
        make.width.equalTo(self.openButton.bjl_height);
        make.centerY.equalTo(self);
    }];
    
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(8);
        make.centerY.equalTo(self.openButton);
        make.right.lessThanOrEqualTo(self.openButton.bjl_left).offset(-3);
    }];
    
}

@end

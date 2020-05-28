//
//  BJLUserGroupView.m
//  BJLiveUI
//
//  Created by fanyi on 2019/7/4.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLUserGroupView.h"
#import "BJLViewImports.h"

@interface BJLUserGroupView ()

@property (nonatomic) UIButton *openButton;
@property (nonatomic) UILabel *groupNameLabel;
@property (nonatomic) UIButton *groupColorButton;

@end

@implementation BJLUserGroupView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self makeSubViews];
    }
    return self;
}

#pragma mark - public
- (void)updateWithGroup:(BJLUserGroup *)group
       groupColorString:(NSString *)colorString
               selected:(BOOL)selected
       isLoginUserGroup:(BOOL)isLoginUserGroup
                  count:(NSInteger)count {
    self.groupNameLabel.text = group.name ?: @"";
    self.groupNameLabel.numberOfLines = selected ? 0 : 1;
    [self.groupColorButton setBackgroundColor:[UIColor bjl_colorWithHexString:colorString]];
    self.userNumberLabel.text = [NSString stringWithFormat:@"%@",@(count)];
    self.openButton.selected = selected;
    self.groupColorButton.selected = isLoginUserGroup;
}

#pragma mark - private

- (void)makeSubViews {
    self.backgroundColor = [UIColor whiteColor];
    bjl_weakify(self);
    UITapGestureRecognizer *tagGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        bjl_returnIfRobot(1.0);
        if (self.tagCallback) {
            self.openButton.selected = !self.openButton.selected;
            self.tagCallback(self.openButton.selected);
        }
    }];
    [self addGestureRecognizer:tagGesture];

    self.groupNameLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:18];
        label.numberOfLines = 1;
        label.textColor = [UIColor bjl_colorWithHex:0x4A4A4A];
        [self addSubview:label];
        label;
    });
    
    self.openButton = ({
        UIButton *button = [BJLButton new];
        button.accessibilityLabel = BJLKeypath(self, openButton);;
        [button setImage:[UIImage bjl_imageNamed:@"bjl_usergroup_close"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_usergroup_open"] forState:UIControlStateSelected];
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        button.userInteractionEnabled = NO;
        [self addSubview:button];
        button;
    });
    
    self.groupColorButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, groupColorButton);;
        [button setImage:[UIImage bjl_imageNamed:@"bjl_usergroup_selected"] forState:UIControlStateSelected];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 10;
        button.userInteractionEnabled = NO;
        [self addSubview:button];
        button;
    });

    self.userNumberLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, userNumberLabel);
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont systemFontOfSize:18];
        label.textColor = [UIColor bjl_colorWithHex:0x979797];
        label.text = @"0";
        [self addSubview:label];
        label;
    });
    
    [self.openButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(0);
        make.width.height.equalTo(@(30));
        make.centerY.equalTo(self);
    }];
    
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.openButton.bjl_right);
        make.centerY.equalTo(self.openButton);
        make.right.lessThanOrEqualTo(self.groupColorButton.bjl_left).offset(-10);
    }];
    
    [self.groupColorButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.openButton);
        make.left.greaterThanOrEqualTo(self.groupNameLabel.bjl_right).offset(10);
        make.right.equalTo(self.userNumberLabel.bjl_left).offset(-10);
        make.height.width.equalTo(@(20));
    }];

    [self.userNumberLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.compressionResistance.required();
        make.centerY.equalTo(self.openButton);
        make.right.equalTo(self).offset(-20);
    }];
}

@end

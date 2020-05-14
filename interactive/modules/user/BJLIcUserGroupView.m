//
//  BJLIcUserGroupView.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/12/28.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserGroupView.h"
#import "BJLIcAppearance.h"

@interface BJLIcUserGroupView ()

@property (nonatomic) UIButton *showListButton;
@property (nonatomic, readwrite) UIButton *openButton;
@property (nonatomic, readwrite) UILabel *groupNameLabel;
@property (nonatomic, readwrite) UILabel *colorLabel;
@property (nonatomic, readwrite) UILabel *countLabel;

@end

@implementation BJLIcUserGroupView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self makesubviews];
    }
    return self;
}

- (void)makesubviews {
    [self addSubview:self.showListButton];
    [self addSubview:self.openButton];
    [self addSubview:self.groupNameLabel];
    [self addSubview:self.colorLabel];
    [self addSubview:self.countLabel];
    
    [self.showListButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    [self.openButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(8.0);
        make.centerY.equalTo(self);
        make.size.equal.sizeOffset(CGSizeMake(24, 24));
    }];
    [self.colorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.openButton.bjl_right);
        make.size.equal.sizeOffset(CGSizeMake(12.0, 12.0));
        make.centerY.equalTo(self);
    }];
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.colorLabel.bjl_right).offset(5);
        make.centerY.equalTo(self);
    }];
    [self.countLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.hugging.compressionResistance.required();
        make.left.greaterThanOrEqualTo(self.colorLabel.bjl_right);
        make.right.equalTo(self);
        make.centerY.equalTo(self);
    }];
    
    UIView *line = [UIView new];
    line.backgroundColor = [UIColor bjl_colorWithHex:0XFFFFFF alpha:0.3];
    [self addSubview:line];
    [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.openButton);
        make.right.equalTo(self).offset(-10);
        make.bottom.equalTo(self);
        make.height.equalTo(@(1));
    }];
}

- (void)show {
    if (self.clickCallback) {
        self.clickCallback(!self.openButton.selected);
    }
}

- (void)updateWithGroupInfo:(BJLUserGroup *)groupInfo shouldClose:(BOOL)shouldClose {
    self.groupNameLabel.text = groupInfo.name;
    self.colorLabel.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color];
    self.openButton.selected = !shouldClose;
}

#pragma mark - get
- (UIButton *)showListButton {
    if (!_showListButton) {
        _showListButton = [UIButton new];
        [_showListButton addTarget:self action:@selector(show) forControlEvents:UIControlEventTouchUpInside];
    }
    return _showListButton;
}

- (UIButton *)openButton {
    if (!_openButton) {
        _openButton = [UIButton new];
        [_openButton setImage:[UIImage bjlic_imageNamed:@"bjl_userlist_group_fold"] forState:UIControlStateNormal];
        [_openButton setImage:[UIImage bjlic_imageNamed:@"bjl_userlist_group_expand"] forState:UIControlStateSelected];
    }
    return _openButton;
}

- (UILabel *)colorLabel {
    if (!_colorLabel) {
        _colorLabel = [UILabel new];
        _colorLabel.layer.cornerRadius = 6.0;
        _colorLabel.layer.masksToBounds = YES;
    }
    return _colorLabel;
}

- (UILabel *)groupNameLabel {
    if (!_groupNameLabel) {
        _groupNameLabel = [UILabel new];
        _groupNameLabel.textColor = [UIColor bjl_colorWithHex:0XB7B7B7];
        _groupNameLabel.font = [UIFont systemFontOfSize:14];
        _groupNameLabel.textAlignment = NSTextAlignmentLeft;
        _groupNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _groupNameLabel;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [UILabel new];
        _countLabel.textColor = [UIColor bjl_colorWithHex:0X979797];
        _countLabel.font = [UIFont systemFontOfSize:12];
        _countLabel.textAlignment = NSTextAlignmentRight;
    }
    return _countLabel;
}

@end

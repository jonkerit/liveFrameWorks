//
//  BJLIcQuestionRecordCell.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/1/19.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcQuestionRecordCell.h"
#import "BJLIcAppearance.h"

@interface BJLIcQuestionRecordCell ()

@property (nonatomic) UIImageView *successImageView;
@property (nonatomic) UILabel *nameLabel, *groupColorLabel, *groupNameLabel, *onlineUserCountLabel;

@end

@implementation BJLIcQuestionRecordCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.separatorInset = UIEdgeInsetsMake(0, 10, 0, 10);
        self.backgroundColor = [UIColor clearColor];
        [self makeSubviews];
    }
    return self;
}

- (void)makeSubviews {
    [self.contentView addSubview:self.successImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.groupColorLabel];
    [self.contentView addSubview:self.groupNameLabel];
    [self.contentView addSubview:self.onlineUserCountLabel];
    
    [self.successImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(10);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(32));
    }];
    
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.successImageView);
        make.left.equalTo(self.successImageView.bjl_right).offset(3);
    }];
    
    [self.groupColorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.successImageView);
        make.right.equalTo(self.groupNameLabel.bjl_left).offset(2);
    }];

    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.contentView);
        make.right.lessThanOrEqualTo(self.onlineUserCountLabel.bjl_left);
    }];

    [self.onlineUserCountLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.successImageView);
        make.right.equalTo(self.contentView).offset(-10);
    }];
}

- (void)updateWithUser:(nullable BJLUser *)user groupInfo:(nullable BJLUserGroup *)groupInfo participateUserCount:(NSUInteger)count {
    self.nameLabel.text = user.displayName;
    self.groupColorLabel.hidden = !groupInfo;
    self.groupNameLabel.hidden = !groupInfo;
    self.groupColorLabel.backgroundColor = groupInfo.color ? ([UIColor bjl_colorWithHexString:groupInfo.color] ?: [UIColor clearColor]) : [UIColor clearColor];
    self.groupNameLabel.text = groupInfo.name;
    self.onlineUserCountLabel.text = [NSString stringWithFormat:@"%td人", count];
}

#pragma mark - get
- (UIImageView *)successImageView {
    if (!_successImageView) {
        _successImageView = [UIImageView new];
        [_successImageView setImage:[UIImage bjlic_imageNamed:@"bjl_questionResponder_historyWinner"]];
    }
    return _successImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [UILabel new];
        [_nameLabel setText:@"--"];
        _nameLabel.textColor = [UIColor whiteColor];
        [_nameLabel setFont:[UIFont systemFontOfSize:14.0]];
        [_nameLabel setTextAlignment:NSTextAlignmentLeft];
        _nameLabel.accessibilityLabel = BJLKeypath(self, nameLabel);
    }
    return _nameLabel;
}

- (UILabel *)groupColorLabel {
    if (!_groupColorLabel) {
        _groupColorLabel = [UILabel new];
        _groupColorLabel.hidden = YES;
        _groupColorLabel.layer.cornerRadius = 6.0;
        _groupColorLabel.layer.masksToBounds = YES;
        _groupColorLabel.accessibilityLabel = BJLKeypath(self, groupColorLabel);
    }
    return _groupColorLabel;
}

- (UILabel *)groupNameLabel {
    if (!_groupNameLabel) {
        UILabel *label = [UILabel new];
        label.text = @"--";
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        [label setAlpha:0.5];
        label.hidden = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        _groupNameLabel = label;
    }
    return _groupNameLabel;
}

- (UILabel *)onlineUserCountLabel {
    if (!_onlineUserCountLabel) {
        _onlineUserCountLabel = [UILabel new];
        [_onlineUserCountLabel setText:@"0人"];
        _onlineUserCountLabel.textColor = [UIColor whiteColor];
        [_onlineUserCountLabel setFont:[UIFont systemFontOfSize:14.0]];
        [_onlineUserCountLabel setTextAlignment:NSTextAlignmentRight];
        _onlineUserCountLabel.accessibilityLabel = BJLKeypath(self, onlineUserCountLabel);
    }
    return _onlineUserCountLabel;
}

@end


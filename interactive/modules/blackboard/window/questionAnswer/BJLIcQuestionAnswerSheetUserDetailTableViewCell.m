//
//  BJLIcQuestionAnswerSheetUserDetailTableViewCell.m
//  BJLiveUI
//
//  Created by fanyi on 2019/6/4.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcQuestionAnswerSheetUserDetailTableViewCell.h"

#define onePixel (1.0 / [UIScreen mainScreen].scale)

@interface BJLIcQuestionAnswerSheetUserDetailTableViewCell()

@property (nonatomic) UILabel *nameLabel, *timeLabel, *choicesLabel;
@property (nonatomic) UIView *gapLine;
@property (nonatomic) UILabel *groupColorLabel, *groupNameLabel;

@end

@implementation BJLIcQuestionAnswerSheetUserDetailTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        [self setUpContentView];
    }
    return self;
}

- (void)setUpContentView {
    
    self.gapLine = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0X979797];
        [self.contentView addSubview:view];
        bjl_return view;
    });
    
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        [self.contentView addSubview:label];
        bjl_return label;
    });
    
    self.timeLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label.accessibilityLabel = BJLKeypath(self, timeLabel);
        [self.contentView addSubview:label];
        bjl_return label;
    });

    self.choicesLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont boldSystemFontOfSize:14];
        label.textAlignment = NSTextAlignmentRight;
        label.accessibilityLabel = BJLKeypath(self, choicesLabel);
        [self.contentView addSubview:label];
        bjl_return label;
    });

    self.groupColorLabel = ({
        UILabel *label = [UILabel new];
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        label.accessibilityLabel = BJLKeypath(self, groupColorLabel);
        [self.contentView addSubview:label];
        bjl_return label;
    });
    
    self.groupNameLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"--";
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        [label setAlpha:0.5];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        [self.contentView addSubview:label];
        bjl_return label;
    });

    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.contentView);
        make.left.equalTo(self.gapLine);
    }];
        
    [self.groupColorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.greaterThanOrEqualTo(self.nameLabel.bjl_right);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(12.0));
    }];
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.groupColorLabel.bjl_right).offset(5);
        make.center.equalTo(self.contentView);
    }];

    [self.timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.nameLabel);
        make.left.greaterThanOrEqualTo(self.groupNameLabel.bjl_right).offset(10);
        make.right.equalTo(self.choicesLabel.bjl_left).offset(-10).required();
    }];
    
    [self.choicesLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.nameLabel);
        make.right.equalTo(self.gapLine);
    }];
    
    [self.gapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(12);
        make.height.equalTo(@(onePixel));
        make.right.equalTo(self.contentView).offset(-24);
        make.bottom.equalTo(self.contentView);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateWithUserDetailModel:(nullable BJLAnswerSheetUserDetail *)userDetail
                      hasSubmited:(BOOL)hasSubmited
                         userInfo:(nullable BJLUser *)userInfo
                        groupInfo:(nullable BJLUserGroup *)groupInfo {
    self.nameLabel.text = hasSubmited ? userDetail.user.displayName : userInfo.name;
    self.timeLabel.hidden = ![userDetail.choices count] || !hasSubmited;
    
    self.groupColorLabel.hidden = !groupInfo;
    self.groupNameLabel.hidden = !groupInfo;
    if (groupInfo.color.length) {
        self.groupColorLabel.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color];
    }
    else {
        self.groupColorLabel.backgroundColor = [UIColor clearColor];
    }
    self.groupNameLabel.text = groupInfo.name;
    
    if ([userDetail.choices count] && hasSubmited) {
        int minutes = ((int)userDetail.time) / 60;
        int second = ((int)userDetail.time) % 60;
        self.timeLabel.text = [NSString stringWithFormat:@"用时：%i分%i秒", minutes, second];
        
        NSMutableString *answerString = [NSMutableString new];
        for (NSString *string in userDetail.choices) {
            if (string) {
                [answerString appendString:string];
                [answerString appendString:@" "];
            }
        }
        self.choicesLabel.text = [answerString copy];
    }
    else {
        self.choicesLabel.text = @"未选择";
    }
}

@end

//
//  BJLIcWritingBoardUserTableViewCell.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcWritingBoardUserTableViewCell.h"
#import "BJLIcAppearance.h"

@interface BJLIcWritingBoardUserTableViewCell ()

@property (nonatomic) UIView *containView;
@property (nonatomic) UIButton *readButton;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UIView *userRedDot;
@property (nonatomic) UILabel *groupColorLabel;

@end

@implementation BJLIcWritingBoardUserTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self makeSubviews];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    if(selected) {
        self.containView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.userRedDot.hidden = YES;
    }
    else {
        self.containView.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - public
- (void)updateWithUser:(BJLUser *)user
             hasSubmit:(BOOL)hasSubmit
             hasRedDot:(BOOL)hasRedDot
             groupInfo:(nullable BJLUserGroup *)groupInfo {
    self.nameLabel.text = user.displayName;
    self.readButton.hidden = !hasSubmit;
    self.userRedDot.hidden = !hasRedDot;
    UIColor *color = [UIColor bjl_colorWithHexString:groupInfo.color];
    self.groupColorLabel.hidden = !color;
    self.groupColorLabel.backgroundColor = color;
    
    [self.groupColorLabel bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(color ? @(12) : @(0));
    }];
}

#pragma mark - private
- (void)makeSubviews {
    self.containView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containView);
        view.layer.cornerRadius = 4;
        bjl_return view;
    });
    
    self.readButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_ic_writingboard_check"] forState:UIControlStateNormal];
        button.accessibilityLabel = BJLKeypath(self, readButton);
        button.userInteractionEnabled = NO;
        bjl_return button;
    });
    
    self.groupColorLabel = ({
        UILabel *label = [UILabel new];
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        label.accessibilityLabel = BJLKeypath(self, groupColorLabel);
        bjl_return label;
    });

    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        label.text = @"";
        bjl_return label;
    });
    
    self.userRedDot = ({
        UIView *view = [UIView new];
        view.hidden = NO;
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 4.0;
        view.accessibilityLabel = BJLKeypath(self, userRedDot);
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
        bjl_return view;
    });
    
    [self.contentView addSubview:self.containView];
    [self.containView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(5, 5, 5, 5));
    }];
    [self.containView addSubview:self.readButton];
    [self.containView addSubview:self.groupColorLabel];
    [self.containView addSubview:self.nameLabel];
    [self.containView addSubview:self.userRedDot];
    
    [self.readButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.bottom.equalTo(self.containView);
        make.width.equalTo(@(12));
    }];
    
    [self.groupColorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.left.equalTo(self.containView.bjl_left).offset(12);
        make.height.equalTo(@(12));
        make.width.equalTo(@(12));
    }];
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.containView);
        make.left.equalTo(self.groupColorLabel.bjl_right).offset(2);
    }];
    
    [self.userRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.nameLabel);
        make.left.equalTo(self.nameLabel.bjl_right);
        make.right.lessThanOrEqualTo(self.containView);
        make.height.width.equalTo(@8.0);
    }];
}

@end

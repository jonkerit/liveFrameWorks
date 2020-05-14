//
//  BJLScSpeakRequestUserCell.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScSpeakRequestUserCell.h"
#import "BJLScAppearance.h"

static const CGFloat iconSize = 32.0;

@interface BJLScSpeakRequestUserCell ()

@property (nonatomic) UIImageView *iconImageView;
@property (nonatomic) UILabel * nameLabel;
@property (nonatomic) UIButton *agreeButton;
@property (nonatomic) UIButton *denyButton;
@property (nonatomic) UIView *separatorLine;

@end

@implementation BJLScSpeakRequestUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    self.iconImageView = ({
        UIImageView *view = [UIImageView new];
        view.accessibilityLabel = BJLKeypath(self, iconImageView);
        view.layer.cornerRadius = iconSize/2;
        view.clipsToBounds = YES;
        view.backgroundColor = [UIColor bjlsc_grayLineColor];
        bjl_return view;
    });
    
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        label.textColor = [UIColor bjl_colorWithHex:0X4A4A4A];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentLeft;
        label.numberOfLines = 1;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        bjl_return label;
    });
    
    self.separatorLine = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor bjlsc_grayLineColor];
        view.accessibilityLabel = BJLKeypath(self, separatorLine);
        bjl_return view;
    });
    
    self.agreeButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, agreeButton);
        [button setTitle:@"同意" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHex:0X1795FF] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:16]];
        bjl_return button;
    });
    
    self.denyButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, agreeButton);
        [button setTitle:@"拒绝" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHex:0XFF1F49] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:16]];
        bjl_return button;
    });

    bjl_weakify(self);
    [self.agreeButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (self.agreeRequestCallback) self.agreeRequestCallback(self, YES);
    }];
    [self.denyButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (self.agreeRequestCallback) self.agreeRequestCallback(self, NO);
    }];
    
    [self.contentView addSubview:self.iconImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.agreeButton];
    [self.contentView addSubview:self.separatorLine];
    [self.contentView addSubview:self.denyButton];
    
    [self.iconImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(BJLScViewSpaceL);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(iconSize));
        make.bottom.equalTo(self.contentView).offset(-BJLScViewSpaceM);
        make.top.equalTo(self.contentView).offset(BJLScViewSpaceM);
    }];
    
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.iconImageView);
        make.left.equalTo(self.iconImageView.bjl_right).offset(BJLScViewSpaceM);
        make.right.lessThanOrEqualTo(self.agreeButton.bjl_left).offset(BJLScViewSpaceL);
    }];
    
    [self.denyButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.contentView).offset(-BJLScViewSpaceL);
        make.centerY.equalTo(self.iconImageView);
    }];
    
    [self.separatorLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.denyButton.bjl_left).offset(-BJLScViewSpaceM);
        make.centerY.equalTo(self.iconImageView);
        make.width.equalTo(@(BJLScOnePixel));
        make.top.bottom.equalTo(self.denyButton);
    }];

    [self.agreeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.separatorLine.bjl_left).offset(-BJLScViewSpaceM);
        make.centerY.equalTo(self.iconImageView);
        make.top.bottom.equalTo(self.denyButton);
    }];
}

#pragma mark - public

- (void)updateWithUser:(BJLUser *)user {
    NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(32.0, 32.0),
                                              0.0,
                                              user.avatar,
                                              nil);
    [self.iconImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]];
    
    self.nameLabel.text = user.displayName ?: @"";
}

@end

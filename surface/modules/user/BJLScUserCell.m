//
//  BJLScUserCell.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScUserCell.h"
#import "BJLScAppearance.h"

@interface BJLScUserCell ()

@property (nonatomic) BJLUser *user;
@property (nonatomic, readwrite) UIImageView *avatarImageView;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *roleLabel;

@end

@implementation BJLScUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.avatarImageView.image = nil;
    self.nameLabel.text = nil;
    self.roleLabel.hidden = YES;
}

- (void)makeSubviewsAndConstraints {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.avatarImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.accessibilityLabel = BJLKeypath(self, avatarImageView);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.cornerRadius = 16.0;
        imageView.layer.masksToBounds = YES;
        imageView;
    });
    [self.contentView addSubview:self.avatarImageView];
    [self.avatarImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(8.0);
        make.centerY.equalTo(self.contentView);
        make.height.width.equalTo(@32.0);
    }];
    
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor bjl_colorWithHexString:@"#4A4A4A" alpha:1.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:14.0];
        label.numberOfLines = 1;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label;
    });
    [self.contentView addSubview:self.nameLabel];
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.avatarImageView.bjl_right).offset(10.0);
        make.right.lessThanOrEqualTo(self.roleLabel.bjl_left).offset(-BJLScViewSpaceM);
        make.centerY.equalTo(self.nameLabel);
        make.height.equalTo(self.contentView);
    }];
    
    self.roleLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, roleLabel);
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.cornerRadius = BJLScButtonCornerRadius;
        label.layer.masksToBounds = YES;
        label.layer.borderWidth = BJLScOnePixel;
        label.font = [UIFont systemFontOfSize:11.0];
        label;
    });
    [self.contentView addSubview:self.roleLabel];
    [self.roleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.contentView).offset(-6.0);
        make.centerY.equalTo(self.contentView);
        make.height.equalTo(@20.0);
        make.width.equalTo(@36.0);
    }];
}

- (void)updateWithUser:(BJLUser *)user isSubCell:(BOOL)isSubCell {
    [self.avatarImageView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(isSubCell ? 15 : 8.0);
    }];
    
    self.user = user;
    self.nameLabel.text = user.displayName;
    NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(32.0, 32.0),
                                              0.0,
                                              user.avatar,
                                              nil);
    [self.avatarImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]];
    if (user.isTeacher) {
        self.roleLabel.text = @"老师";
        self.roleLabel.textColor = [UIColor bjlsc_blueBrandColor];
        self.roleLabel.layer.borderColor = [UIColor bjlsc_blueBrandColor].CGColor;
    }
    else if (user.isAssistant) {
        self.roleLabel.text = @"助教";
        self.roleLabel.textColor = [UIColor bjlsc_orangeBrandColor];
        self.roleLabel.layer.borderColor = [UIColor bjlsc_orangeBrandColor].CGColor;
    }
    self.roleLabel.hidden = !user.isTeacherOrAssistant;
    [self.nameLabel bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.lessThanOrEqualTo(user.isStudent ? self.contentView :  self.roleLabel.bjl_left).offset(-BJLScViewSpaceM);
    }];
}

@end

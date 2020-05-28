//
//  BJLEnvelopeResultCell.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLAppearance.h"
#import "BJLEnvelopeResultCell.h"

NSString * const BJLEnvelopeResultCellReuseIdentifier = @"kEnvelopeResultCellReuseIdentifier";

@interface BJLEnvelopeResultCell ()

@property (nonatomic) UIImageView *rankImageView;
@property (nonatomic) UILabel *rankLabel;
@property (nonatomic) UILabel *userNameLabel;
@property (nonatomic) UILabel *scoreLabel;

@end

@implementation BJLEnvelopeResultCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.rankImageView.image = nil;
    self.rankLabel.text = nil;
    self.userNameLabel.text = nil;
    self.scoreLabel.text = nil;
}

- (void)makeSubviewsAndConstraints {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    self.rankImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.contentView addSubview:self.rankImageView];
    [self.rankImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.left.equalTo(self.contentView);
        make.width.height.equalTo(@28.0);
    }];
    self.rankLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [self.rankImageView addSubview:self.rankLabel];
    [self.rankLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.bottom.equalTo(self.contentView);
        make.width.equalTo(@28.0);
    }];
    self.userNameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.contentView addSubview:self.userNameLabel];
    [self.userNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.contentView);
        make.top.bottom.equalTo(self.contentView);
        make.left.greaterThanOrEqualTo(self.rankLabel.bjl_right);
    }];
    self.scoreLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentRight;
        label.textColor = [UIColor blackColor];
        label;
    });
    [self.contentView addSubview:self.scoreLabel];
    [self.scoreLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.contentView);
        make.top.bottom.equalTo(self.contentView);
        make.left.greaterThanOrEqualTo(self.userNameLabel.bjl_right);
    }];
}

- (void)configureWithRank:(NSInteger)rank userName:(nullable NSString *)userName score:(NSInteger)score {
    self.userNameLabel.textColor = [UIColor redColor];
    switch (rank) {
        case 1:
            self.rankImageView.image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_first"];
            break;
            
        case 2:
            self.rankImageView.image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_second"];
            break;
            
        case 3:
            self.rankImageView.image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_third"];
            break;
            
        default:
            self.rankImageView.image = nil;
            self.rankLabel.text = [NSString stringWithFormat:@"%td", rank];
            self.userNameLabel.textColor = [UIColor blackColor];
            break;
    }
    self.userNameLabel.text = userName;
    self.scoreLabel.text = [NSString stringWithFormat:@"%td", score];
}

@end

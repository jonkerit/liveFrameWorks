//
//  BJLIcUserInAndOutCell.m
//  BJLiveUI
//
//  Created by fanyi on 2019/9/9.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLConstants.h>

#import "BJLIcUserInAndOutCell.h"
#import "BJLIcAppearance.h"

NSString
* const BJLIcUserInAndOutCellReuseIdentifier = @"BJLIcUserInAndOutReuseIdentifier",
* const BJLIcUserInAndOutWithTimeCellReuseIdentifier = @"BJLIcUserInAndOutWithTimeCellReuseIdentifier";

@interface BJLIcUserInAndOutCell ()

@property (nonatomic) UILabel *timeLabel;
@property (nonatomic) UILabel *nameLabel;

@end

@implementation BJLIcUserInAndOutCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    if ([self.reuseIdentifier isEqualToString:BJLIcUserInAndOutCellReuseIdentifier]) {
        [self makeMessageLabelAndConstraints];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcUserInAndOutWithTimeCellReuseIdentifier]) {
        [self makeMessageWithTimeLabelAndConstraints];
    }
}

- (void)makeMessageLabelAndConstraints {
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor bjl_colorWithHex:0X6B6B6E];
        label.font = [UIFont systemFontOfSize:12.0];
        label.lineBreakMode = NSLineBreakByTruncatingMiddle;
        label;
    });
    
    [self.contentView addSubview:self.nameLabel];
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset([BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        make.bottom.equalTo(self.contentView).offset(-[BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        make.left.greaterThanOrEqualTo(self.contentView).offset([BJLIcAppearance sharedAppearance].chatViewMediumSpace);
    }];
}

- (void)makeMessageWithTimeLabelAndConstraints {
    self.timeLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor bjl_colorWithHex:0X6B6B6E];
        label.font = [UIFont systemFontOfSize:12.0];
        label.lineBreakMode = NSLineBreakByTruncatingMiddle;
        label;
    });
    [self.contentView addSubview:self.timeLabel];
    [self.timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset([BJLIcAppearance sharedAppearance].chatViewSmallSpace);
    }];

    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor bjl_colorWithHex:0X6B6B6E];
        label.font = [UIFont systemFontOfSize:12.0];
        label.lineBreakMode = NSLineBreakByTruncatingMiddle;
        label;
    });
    
    [self.contentView addSubview:self.nameLabel];
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.timeLabel.bjl_bottom).offset([BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        make.bottom.equalTo(self.contentView.bjl_bottom).offset(-[BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        make.left.greaterThanOrEqualTo(self.contentView).offset([BJLIcAppearance sharedAppearance].chatViewMediumSpace);
    }];
}

- (void)updateWithMessage:(BJLUserInAndOutMessage *)message cellWidth:(CGFloat)cellWidth {
    if (self.timeLabel) {
        self.timeLabel.text = [self timeStringWithTimeInterval:message.timeInterval];
    }
    
    NSMutableString *content = [[NSMutableString alloc] init];

    NSString *nameAndRole = message.fromUser.displayName;
    if (message.fromUser.isTeacher) {
        nameAndRole = [NSString stringWithFormat:@"%@ [ %@ ]", message.fromUser.displayName, @"老师"];
    }
    if (message.fromUser.isAssistant) {
        nameAndRole = [NSString stringWithFormat:@"%@ [ %@ ]", message.fromUser.displayName, @"助教"];
    }
    NSString *isUserInContent = message.isUserIn ? @" 进入教室" : @" 离开教室";
    [content appendString:nameAndRole ?: @""];
    [content appendString:isUserInContent];
    self.nameLabel.text = content;
}

- (NSString *)timeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

+ (NSArray<NSString *> *)allCellIdentifiers {
    return @[BJLIcUserInAndOutCellReuseIdentifier,
             BJLIcUserInAndOutWithTimeCellReuseIdentifier];
}

@end

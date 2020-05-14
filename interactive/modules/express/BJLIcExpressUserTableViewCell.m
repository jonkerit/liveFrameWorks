//
//  BJLIcExpressUserTableViewCell.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/8/19.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcExpressUserTableViewCell.h"
#import "BJLIcAppearance.h"

@interface BJLIcExpressUserTableViewCell ()

@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UIImageView *checkedImageView;

@end

@implementation BJLIcExpressUserTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.checkedImageView.hidden = YES;
    self.nameLabel.text = nil;
}

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor bjl_colorWithHexString:@"#52585C" alpha:1.0];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentLeft;
        label;
    });
    [self.contentView addSubview:self.nameLabel];
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(18.0);
        make.centerY.equalTo(self.contentView);
        make.height.equalTo(@20.0);
    }];
    
    self.checkedImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = [UIImage bjlic_imageNamed:@"express_checked"];
        imageView;
    });
    [self.contentView addSubview:self.checkedImageView];
    [self.checkedImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.contentView.bjl_right).offset(-14.0);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@24.0);
    }];
}

- (void)updateWithName:(NSString *)name selected:(BOOL)selected {
    self.nameLabel.text = name;
    self.checkedImageView.hidden = !selected;
    self.backgroundColor = selected ? [UIColor bjl_colorWithHexString:@"#F6FBFF" alpha:1.0] : [UIColor clearColor];
}

@end

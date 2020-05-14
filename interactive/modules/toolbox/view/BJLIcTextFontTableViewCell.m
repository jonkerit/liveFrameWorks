//
//  BJLIcTextFontTableViewCell.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/12.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcTextFontTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcTextFontTableViewCell ()

@property (nonatomic) UIButton *fontOptionButton;

@end

@implementation BJLIcTextFontTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupContent];
    }
    return self;
}

#pragma mark - content

- (void)setupContent {
    self.backgroundColor = [UIColor clearColor];
    
    self.fontOptionButton = ({
        UIButton *button = [[UIButton alloc] init];
        [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.7] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#03A9F4"] forState:UIControlStateSelected];
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        bjl_return button;
    });
    
    bjl_weakify(self);
    [self.fontOptionButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.selectCallback) {
            self.selectCallback(!button.selected);
        }
    }];
    
    [self.contentView addSubview:self.fontOptionButton];
    [self.fontOptionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
}

#pragma mark - public

- (void)updateContentWithFont:(NSInteger)font selected:(BOOL)selected {
    [self.fontOptionButton setTitle:[NSString stringWithFormat:@"%td", font] forState:UIControlStateNormal];
    self.fontOptionButton.selected = selected;
}

@end

NS_ASSUME_NONNULL_END

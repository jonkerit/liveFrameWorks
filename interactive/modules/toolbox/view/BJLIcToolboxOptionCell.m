//
//  BJLIcToolboxOptionCell.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/10/29.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcToolboxOptionCell.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolboxOptionCell ()

@property (nonatomic) UIButton *optionButton;

@end

@implementation BJLIcToolboxOptionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

#pragma mark - subviews

- (void)setupSubviews {
    self.optionButton = ({
        UIButton *button = [[UIButton alloc] init];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 3.0;
        [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#03A9F4"] forState:UIControlStateSelected];
        
        bjl_weakify(self);
        [button bjl_addHandler:^(UIButton * _Nonnull button) {
            bjl_strongify(self);
            if (self.selectCallback) {
                self.selectCallback(!button.selected);
            }
        }];
        button;
    });
    [self.contentView addSubview:self.optionButton];
    [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView);
    }];
}

#pragma mark - public

- (void)updateContentWithOptionIcon:(UIImage *)icon
                       selectedIcon:(UIImage * _Nullable)selectedIcon
                        description:(NSString * _Nullable)description
                         isSelected:(BOOL)selected {
    [self.optionButton setImage:icon forState:UIControlStateNormal];
    [self.optionButton setImage:selectedIcon forState:UIControlStateSelected];
    [self.optionButton setTitle:description forState:UIControlStateNormal];
    self.optionButton.selected = selected;
    
    if (self.showSelectBorder) {
        UIColor *borderColor = selected ? [UIColor lightGrayColor] : [UIColor clearColor];
        CGFloat borderWidth = selected ? 1.0 : 0.0;
        self.optionButton.layer.borderColor = borderColor.CGColor;
        self.optionButton.layer.borderWidth = borderWidth;
    }
}

@end

NS_ASSUME_NONNULL_END

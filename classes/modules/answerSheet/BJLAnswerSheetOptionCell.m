//
//  BJLAnswerSheetOptionCell.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/6/7.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLAnswerSheetOptionCell.h"
#import "BJLAppearance.h"

@interface BJLAnswerSheetOptionCell ()

@property (nonatomic) UIButton *optionButton;

@end

@implementation BJLAnswerSheetOptionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpContentView];
    }
    return self;
}

#pragma mark - content view

- (void)setUpContentView {
    // option button
    self.optionButton = ({
        UIButton *button = [[UIButton alloc] init];
        button.backgroundColor = [UIColor clearColor];
        // layer
        button.layer.masksToBounds = YES;
        button.layer.borderWidth = 0.5;
        button.layer.borderColor = [UIColor bjl_colorWithHexString:@"#1795FF"].CGColor;
        button.layer.cornerRadius = 17.0;
        
        // title
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.titleLabel.numberOfLines = 0;
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        // action
        [button addTarget:self action:@selector(optionButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.contentView addSubview:self.optionButton];
    [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
}

#pragma mark - action

- (void)optionButtonOnClick:(UIButton *)button {
    // 选中状态
    BOOL selected = !button.selected;
    [self setOptionButtonSelected:selected];
    
    // 回调
    if (self.optionSelectedCallback) {
        self.optionSelectedCallback(selected);
    }
}

- (void)setOptionButtonSelected:(BOOL)selected {
    self.optionButton.selected = selected;
    self.optionButton.backgroundColor = selected ? [UIColor bjl_colorWithHexString:@"#1795FF"] : [UIColor clearColor];
}

#pragma mark - update

- (void)updateContentWithOptionKey:(NSString *)optionKey isSelected:(BOOL)isSelected {
    [self.optionButton setTitle:optionKey forState:UIControlStateNormal];
    [self setOptionButtonSelected:isSelected];
    self.optionButton.layer.cornerRadius = self.contentView.bounds.size.width / 2.0;
}

- (void)updateContentWithSelectedKey:(NSString *)optionKey isCorrect:(BOOL)isCorrect {
    [self.optionButton setTitle:optionKey forState:UIControlStateNormal];
    [self.optionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.optionButton.layer.borderWidth = 0;
    self.optionButton.layer.cornerRadius = self.contentView.bounds.size.width / 2.0;
    [self.optionButton setBackgroundColor:isCorrect ? [UIColor bjl_colorWithHex:0X1795FF]: [UIColor bjl_colorWithHex:0XFF1F49]];
    self.optionButton.userInteractionEnabled = NO;
}

@end

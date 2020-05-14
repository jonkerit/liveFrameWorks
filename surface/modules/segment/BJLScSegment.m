//
//  BJLScSegment.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScSegment.h"
#import "BJLScAppearance.h"

@interface BJLScSegment ()

@property (nonatomic) NSArray<NSString *> *items;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) NSMutableArray<UIButton *> *buttons;
@property (nonatomic) NSMutableArray<UILabel *> *redDots;

@end

@implementation BJLScSegment

- (instancetype)initWithItems:(NSArray<NSString *> *)items width:(CGFloat)width fontSize:(CGFloat)fontSize textColor:(UIColor *)textColor {
    if (self = [super initWithFrame:CGRectZero]) {
        self.items = items;
        self.width = width;
        self.fontSize = fontSize > 0 ? fontSize : 14.0;
        self.textColor = textColor;
        self.backgroundColor = [UIColor whiteColor];
        self.buttons = [NSMutableArray new];
        self.redDots = [NSMutableArray new];
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    for (NSString *title in self.items) {
        UILabel *redDot = [self makeRedDot];
        UIButton *button = [self makeSegmentButtonWithTitle:title redDot:redDot];
        [self.redDots bjl_addObject:redDot];
        [self.buttons bjl_addObject:button];
    }
    
    UIButton *last = nil;
    for (UIButton *button in [self.buttons copy]) {
        [self addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            if (self.width > 0) {
                make.width.equalTo(@(self.width));
            }
            else {
                make.width.equalTo(self.bjl_width).multipliedBy(1.0 / self.buttons.count);
            }
            make.top.bottom.equalTo(self);
            make.left.equalTo(last ? last.bjl_right : self.bjl_left);
        }];
        last = button;
    }
    self.selectedIndex = 0;
}

- (void)changeSelectedIndex:(UIButton *)button {
    NSInteger index = [self.buttons indexOfObject:button];
    if (index != NSNotFound) {
        if (self.selectedIndex != index) {
            self.selectedIndex = index;
        }
    }
}

#pragma mark - setter

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    for (NSInteger i = 0; i < self.buttons.count; i ++) {
        UIButton *button = [self.buttons bjl_objectAtIndex:i];
        button.selected = (selectedIndex == i);
    }
}

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSInteger)index {
    UIButton *button = [self.buttons bjl_objectAtIndex:index];
    if (button) {
        [button setTitle:title forState:UIControlStateNormal];
    }
}

- (void)setImage:(nullable UIImage *)image forSegmentAtIndex:(NSInteger)index {
    UIButton *button = [self.buttons bjl_objectAtIndex:index];
    UILabel *redDot = [self.redDots bjl_objectAtIndex:index];
    if (button) {
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.imageEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 16.0);
        button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 16.0, 0.0, 8.0);
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [button setImage:image forState:UIControlStateNormal];
        redDot.layer.cornerRadius = 4.0;
        [redDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(button).offset(8.0);
            make.left.equalTo(button.imageView.bjl_right).offset(-4.0);
            make.height.width.equalTo(@(8.0));
        }];
    }
}

- (void)updateRedDotAtIndex:(NSInteger)index count:(NSInteger)count ignoreCount:(BOOL)ignoreCount {
    UILabel *redDot = [self.redDots bjl_objectAtIndex:index];
    if (redDot) {
        redDot.hidden = (count <= 0);
        redDot.text = ignoreCount ? nil : count > 99 ? @"···" : [NSString stringWithFormat:@"%td", count];
        
        [redDot bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.width.equalTo(ignoreCount ? @(8) : @(14.0));
        }];
        redDot.layer.cornerRadius = ignoreCount ? 4.0 : 7.0;
        
        UIButton *button = [self.buttons bjl_objectAtIndex:index];
        if (button) {
            [self bringSubviewToFront:button];
        }
    }
}

#pragma mark - wheel

- (UIButton *)makeSegmentButtonWithTitle:(NSString *)title redDot:(UIView *)redDot {
    UIButton *button = [UIButton new];
    button.accessibilityLabel = title;
//    button.clipsToBounds = YES;
    button.backgroundColor = [UIColor whiteColor];
    button.titleLabel.font = [UIFont systemFontOfSize:self.fontSize];
    button.titleLabel.textAlignment = self.items.count > 1 ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:self.textColor forState:UIControlStateNormal];
        
    if (self.items.count > 1) {
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(changeSelectedIndex:) forControlEvents:UIControlEventTouchUpInside];
        
        //seperator
        UIView *view = [UIView new];
        [button addSubview:view];
        [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(button);
            make.bottom.equalTo(button).offset(-4.0);
            make.width.equalTo(@24.0);
            make.height.equalTo(@(BJLScOnePixel));
        }];
        [self bjl_kvo:BJLMakeProperty(button, selected)
             observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                 view.backgroundColor = button.isSelected ? [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] : [UIColor clearColor];
                 return YES;
             }];
        
        // redDot
        [button addSubview:redDot];
        [redDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(button).offset(BJLScOnePixel);
            make.left.equalTo(button.titleLabel.bjl_right);
            make.height.width.equalTo(@(14.0));
        }];
    }
    else {
        button.userInteractionEnabled = NO;
        [button addSubview:redDot];
    }

    return button;
}

- (UILabel *)makeRedDot {
    UILabel *redDot = [UILabel new];
    redDot.hidden = YES;
    redDot.layer.masksToBounds = YES;
    redDot.layer.cornerRadius = 7.0;
    redDot.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
    redDot.textColor = [UIColor whiteColor];
    redDot.textAlignment = NSTextAlignmentCenter;
    redDot.adjustsFontSizeToFitWidth = YES;
    redDot.font = [UIFont systemFontOfSize:10.0];
    return redDot;
}

@end

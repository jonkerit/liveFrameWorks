//
//  BJLIcPopoverViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcPopoverViewController.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcPopoverViewController ()

@property (nonatomic, readwrite) BJLIcPopoverViewType type;
@property (nonatomic) NSString *message;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) BJLIcPopoverView *popoverView;

@end

@implementation BJLIcPopoverViewController

- (instancetype)init {
    return [self initWithPopoverViewType:BJLIcPopoverViewDefaultType];
}

- (instancetype)initWithPopoverViewType:(BJLIcPopoverViewType)type {
    if (self = [super init]) {
        self.type = type;
    }
    return self;
}

- (instancetype)initWithPopoverViewType:(BJLIcPopoverViewType)type message:(NSString *)message {
    if (self = [super init]) {
        self.type = type;
        self.message = message;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviewsAndConstraints];
    [self makeActions];
}

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor clearColor];
    // 毛玻璃效果
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.popoverView = [[BJLIcPopoverView alloc] initWithType:self.type];
    if (self.message) {
        self.popoverView.messageLabel.text = self.message;
    }
    [self.view addSubview:self.popoverView];
    [self.popoverView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(@(self.popoverView.viewSize.width));
        make.height.equalTo(@(self.popoverView.viewSize.height));
        make.height.width.lessThanOrEqualTo(self.view);
    }];
}

- (void)makeActions {
    bjl_weakify(self);
    
    if (self.popoverView.cancelButton) {
        [self.popoverView.cancelButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
            bjl_strongify(self);
            if (self.cancelCallback) {
                self.cancelCallback();
            }
            [self bjl_removeFromParentViewControllerAndSuperiew];
        }];
    }

    if (self.popoverView.confirmButton) {
        [self.popoverView.confirmButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
            bjl_strongify(self);
            if (self.confirmCallback) {
                self.confirmCallback();
            }
            [self bjl_removeFromParentViewControllerAndSuperiew];
        }];
    }
    
    if (self.popoverView.appendButton) {
        [self.popoverView.appendButton bjl_addHandler:^(UIButton * _Nonnull button) {
            bjl_strongify(self);
            if (self.appendCallback) {
                self.appendCallback();
            }
            [self bjl_removeFromParentViewControllerAndSuperiew];
        }];
    }
}

- (void)updateEffectHidden:(BOOL)hidden {
    self.backgroundView.hidden = hidden;
}

@end

NS_ASSUME_NONNULL_END

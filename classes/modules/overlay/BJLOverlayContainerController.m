//
//  BJLOverlayContainerController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-02-14.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLViewControllerImports.h"
#import "BJLOverlayContainerController.h"
#import "BJLOverlayViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLOverlayContainerController ()

@property (nonatomic) UIView *headerContainerView, *contentContainerView, *footerContainerView;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *buttonsStackView;
@property (nonatomic, copy, nullable) NSArray<UIButton *> *rightButtons;

@property (nonatomic, nullable) UIView *footerView;

@end

@implementation BJLOverlayContainerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    
    [self makeSubviews];
    [self makeConstraints];
    
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self, contentViewController)
         observer:^BOOL(UIViewController * _Nullable now, UIViewController * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [old bjl_removeFromParentViewControllerAndSuperiew];
             if (now) {
                 [self bjl_addChildViewController:self.contentViewController
                                        superview:self.contentContainerView];
                 [self.contentViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
                     make.edges.equalTo(self.contentContainerView);
                 }];
             }
             return YES;
         }];
}

- (void)updateViewConstraints {
    [self updateHeaderViewConstraints];
    [super updateViewConstraints];
}

#pragma mark - <UIContentContainer>

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    NSLog(@"%@ willTransitionToSizeClasses: %td-%td",
          NSStringFromClass([self class]), newCollection.horizontalSizeClass, newCollection.verticalSizeClass);
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        // @see - [self updateViewConstraints]
        [self.view setNeedsUpdateConstraints];
    } completion:nil];
}

#pragma mark - private

- (void)makeSubviews {
    self.headerContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor bjl_grayLineColor];
        [view addSubview:line];
        [line bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(view).with.offset(BJLViewSpaceL);
            make.right.greaterThanOrEqualTo(view); // fix warning if view.width == 0.0
            make.bottom.equalTo(view);
            make.height.equalTo(@(BJLOnePixel));
        }];
        view.accessibilityLabel = BJLKeypath(self, headerContainerView);
        [self.view addSubview:view];
        view;
    });
    
    self.footerContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view.accessibilityLabel = BJLKeypath(self, footerContainerView);
        [self.view addSubview:view];
        view;
    });
    
    self.contentContainerView = ({
        UIView *view = [UIView new];
        [self.view insertSubview:view atIndex:0];
        view.accessibilityLabel = BJLKeypath(self, contentContainerView);
        view;
    });
    
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.accessibilityLabel = BJLKeypath(self, titleLabel);
        [self.headerContainerView addSubview:label];
        label;
    });
    
    self.buttonsStackView = ({
        UIView *view = [UIView new];
        view.clipsToBounds = YES;
        view.accessibilityLabel = BJLKeypath(self, buttonsStackView);
        [self.headerContainerView addSubview:view];
        view;
    });
}

- (void)makeConstraints {
    [self.headerContainerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.top.equalTo(self.view);
        if (self.view.bjl_safeAreaLayoutGuide) {
            make.bottom.greaterThanOrEqualTo(self.view.bjl_safeAreaLayoutGuide.bjl_top).offset(0.0); // will update
        }
        else {
            make.height.equalTo(@0.0); // will update
        }
    }];
    
    [self.footerContainerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@0.0).priorityHigh();
    }];
    
    [self.contentContainerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.headerContainerView.bjl_bottom);
        make.bottom.equalTo(self.footerContainerView.bjl_top);
    }];
    
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.headerContainerView.bjl_safeAreaLayoutGuide ?: self.headerContainerView).with.offset(BJLViewSpaceL);
        make.top.bottom.equalTo(self.headerContainerView.bjl_safeAreaLayoutGuide ?: self.headerContainerView);
    }];
    
    [self.buttonsStackView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.horizontal.compressionResistance.required();
        make.left.greaterThanOrEqualTo(self.titleLabel.bjl_right).with.offset(BJLViewSpaceL);
        make.right.top.bottom.equalTo(self.headerContainerView.bjl_safeAreaLayoutGuide ?: self.headerContainerView);
    }];
}

- (void)updateHeaderViewConstraints {
    BOOL shown = self.titleLabel.text.length || self.rightButtons.count;
    self.headerContainerView.hidden = !shown;
    
    /*
    BOOL isHorizontal = BJLIsHorizontalUI(self);
    BOOL hasStatusBar = ![UIApplication sharedApplication].isStatusBarHidden; // */
    
    CGFloat headerHeight = shown ? BJLControlSize : 0.0;
    [self.headerContainerView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        if (self.view.bjl_safeAreaLayoutGuide) {
            make.bottom.greaterThanOrEqualTo(self.view.bjl_safeAreaLayoutGuide.bjl_top).offset(headerHeight); // will update
        }
        else {
            make.height.equalTo(@(headerHeight));
        }
    }];
}

#pragma mark - public

- (void)updateTitle:(nullable NSString *)title {
    self.titleLabel.text = title;
    [self updateHeaderViewConstraints];
}

- (void)updateRightButton:(nullable UIButton *)rightButton {
    [self updateRightButtons:rightButton ? @[rightButton] : nil];
}

- (void)updateRightButtons:(nullable NSArray<UIButton *> *)rightButtons {
    [self.rightButtons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.rightButtons = rightButtons;
    
    UIButton *last = nil;
    for (UIButton *button in self.rightButtons) {
        [self.buttonsStackView addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.right.equalTo(last.bjl_left ?: self.buttonsStackView).with.offset(- (last ? BJLViewSpaceM : BJLViewSpaceL));
            make.centerY.equalTo(self.buttonsStackView);
            make.top.bottom.equalTo(self.buttonsStackView).priorityHigh();
        }];
        last = button;
    }
    [last bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.buttonsStackView).priorityHigh();
    }];
    
    [self updateHeaderViewConstraints];
}

- (void)updateFooterView:(nullable UIView *)footerView {
    [self.footerView removeFromSuperview];
    
    self.footerView = footerView;
    
    if (footerView) {
        [self.footerContainerView addSubview:footerView];
        [footerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.footerContainerView.bjl_safeAreaLayoutGuide ?: self.footerContainerView);
        }];
    }
    
    BOOL shown = !!footerView;
    self.footerContainerView.hidden = !shown;
}

- (void)hide {
    [bjl_as(self.parentViewController, BJLOverlayViewController) hide];
}

@end

#pragma mark -

@implementation UIViewController (BJLOverlayContentViewController)

- (nullable BJLOverlayContainerController *)bjl_overlayContainerController {
    return [self.parentViewController bjl_as:[BJLOverlayContainerController class]];
}

@end

NS_ASSUME_NONNULL_END

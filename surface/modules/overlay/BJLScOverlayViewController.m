//
//  BJLScOverlayViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScOverlayViewController.h"

@interface BJLScOverlayViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, weak) UIView *contentView;
@property (nonatomic, weak) UIViewController *viewController;

@end

@implementation BJLScOverlayViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)showWithContentViewController:(nullable UIViewController *)viewController contentView:(nullable UIView *)view {
    [self removeContentViewAndViewController];
    self.viewController = viewController;
    self.contentView = view;
    if (self.viewController) {
        [self bjl_addChildViewController:self.viewController superview:self.view];
    }
    if (self.contentView) {
        [self.view addSubview:self.contentView];
    }
    if (self.showCallback) {
        self.showCallback();
    }
}

- (void)hide {
    [self removeContentViewAndViewController];
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

- (void)removeContentViewAndViewController {
    if (self.viewController) {
        [self.viewController bjl_removeFromParentViewControllerAndSuperiew];
        self.viewController = nil;
    }
    if (self.contentView) {
        [self.contentView removeFromSuperview];
        self.contentView = nil;
    }
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view != self.view) {
        return NO;
    }
    return YES;
}

@end

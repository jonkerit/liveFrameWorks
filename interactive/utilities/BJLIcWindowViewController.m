//
//  BJLIcWindowViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-18.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLWindowUpdateModel.h>

#import "BJLIcWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"

#import "BJLIcAppearance.h"

const CGPoint BJLPointNull = (CGPoint){.x = INFINITY, .y = INFINITY};

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcWindowViewController ()

@property (nonatomic, readwrite) BJLWindowState state;
@property (nonatomic) BJLWindowState windowedState;

@end

@implementation BJLIcWindowViewController

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tapToBringToFront = YES;
        self.doubleTapToMaximize = YES;
        self.panToMove = YES;
        self.panToResize = YES;
        self.minWindowWidth = 200.0;
        self.minWindowHeight = 100.0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    self.view.backgroundColor = [UIColor clearColor];
    
    [self makeSubviewsAndConstraints];
    [self addHandlers];
    
    [self makeObserveringForWindowState];
    [self makeObserveringForContainer];
    [self makeObserveringForContent];
}

#pragma mark - self

- (void)makeSubviewsAndConstraints {
    self->_backgroundView = ({
//        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
//        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        view.accessibilityLabel = @"backgroundView";
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self->_forgroundView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, forgroundView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self->_topBar = ({
        BJLIcWindowTopBar *view = [BJLIcWindowTopBar new];
        view.accessibilityLabel = BJLKeypath(self, topBar);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self->_bottomBar = ({
        BJLIcWindowBottomBar *view = [BJLIcWindowBottomBar new];
        view.accessibilityLabel = BJLKeypath(self, bottomBar);
        [self.view insertSubview:view belowSubview:self.topBar];
        bjl_return view;
    });
    
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.forgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.topBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
    }];
    
    [self.bottomBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
    }];
    
    [self.topBar setNeedsUpdateConstraints];
}

#pragma mark - parent

- (void)setWindowedParentViewController:(UIViewController *)parentViewController
                              superview:(nullable UIView *)superview {
    self->_windowedParentViewController = parentViewController;
    self->_windowedSuperview = superview;
    if (self.state == BJLWindowState_windowed
        || self.state == BJLWindowState_maximized) {
        [self moveToParentViewControllerAndSuperview];
    }
}

- (void)setFullscreenParentViewController:(UIViewController *)parentViewController
                                superview:(nullable UIView *)superview {
    self->_fullscreenParentViewController = parentViewController;
    self->_fullscreenSuperview = superview;
    if (self.state == BJLWindowState_fullscreen) {
        [self moveToParentViewControllerAndSuperview];
    }
}

- (void)setWindowInterfaceEnabled:(BOOL)windowInterfaceEnabled {
    _windowInterfaceEnabled = windowInterfaceEnabled;
    [self setWindowGesturesEnabled:windowInterfaceEnabled];
    self.fullscreenButtonHidden = !windowInterfaceEnabled;
    self.maximizeButtonHidden = !windowInterfaceEnabled;
    self.closeButtonHidden = !windowInterfaceEnabled;
}

#pragma mark - content

- (void)setContentViewController:(nullable UIViewController *)contentViewController
                     contentView:(nullable UIView *)contentView {
    [self.contentViewController bjl_removeFromParentViewControllerAndSuperiew];
    [self.contentView removeFromSuperview];
    
    self->_contentViewController = contentViewController;
    self->_contentView = contentView ?: contentViewController.view;
    
    if (self.contentViewController) {
        [self bjl_addChildViewController:self.contentViewController superview:self.view aboveSubview:self.backgroundView];
    }
    else if (self.contentView) {
        [self.view insertSubview:self.contentView aboveSubview:self.backgroundView];
    }
    
    [self.contentView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (BJLObservable)setBottomView:(nullable UIView *)bottomView {
    [self.bottomView removeFromSuperview];
    
    self->_bottomView = bottomView;
    
    if (self.bottomView) {
        [self.bottomBar addSubview:self.bottomView];
    }
    
    [self.bottomView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.bottomBar);
    }];
}

#pragma mark - public

- (void)open {
    [self openWithoutRequest];
    [self requestUpdateWithAction:BJLWindowsUpdateAction_open];
}

- (void)openWithoutRequest {
    if (!self.windowedParentViewController) {
        return;
    }
    self.state = BJLWindowState_windowed;
    [self moveToParentViewControllerAndSuperview];
}

/*
- (void)minimize {
    if (!self.windowedParentViewController) {
        return;
    }
    self.windowedState = self.state;
    self.state = BJLWindowState_minimized;
    [self moveToParentViewControllerAndSuperview];
} // */

- (void)maximize {
    [self maximizeWithoutRequest];
    [self requestUpdateWithAction:BJLWindowsUpdateAction_maximize];
}

- (void)maximizeWithoutRequest {
    if (!self.windowedParentViewController || self.state == BJLWindowState_maximized) {
        return;
    }
    self.state = BJLWindowState_maximized;
    [self moveToParentViewControllerAndSuperview];
}

- (void)fullscreen {
    [self fullScreenWithoutRequest];
    [self requestUpdateWithAction:BJLWindowsUpdateAction_fullScreen];
}

- (void)fullScreenWithoutRequest {
    if (!self.fullscreenParentViewController || self.state == BJLWindowState_fullscreen) {
        return;
    }
    self.windowedState = self.state;
    self.state = BJLWindowState_fullscreen;
    [self moveToParentViewControllerAndSuperview];
}

- (void)restore {
    [self restoreWithoutRequest];
    if (self.state == BJLWindowState_maximized) {
        [self requestUpdateWithAction:BJLWindowsUpdateAction_maximize];
    }
    else {
        [self requestUpdateWithAction:BJLWindowsUpdateAction_restore];
    }
}

- (void)restoreWithoutRequest {
    if (!self.windowedParentViewController) {
        return;
    }
    
    BJLWindowState laststate = self.state;
    self.state = (self.windowedState == BJLWindowState_closed
                  ? BJLWindowState_windowed : self.windowedState);
    
    if (self.state  == BJLWindowState_maximized
        && laststate == BJLWindowState_maximized) {
        // fix: 视频窗口 maximize -> fullScreen -> restore -> restore 无法恢复成窗口的问题
        self.state = BJLWindowState_windowed;
    }

    [self moveToParentViewControllerAndSuperview];
    self.windowedState = BJLWindowState_windowed;
}

- (void)close {
    [self closeWithoutRequest];
    [self requestUpdateWithAction:BJLWindowsUpdateAction_close];
}

- (void)closeWithoutRequest {
    self.state = BJLWindowState_closed;
    if (self.parentViewController) {
        [self bjl_removeFromParentViewControllerAndSuperiew];
    }
    else {
        [self.view removeFromSuperview];
    }
}

- (void)bringToFront {
    [self bringToFrontWithoutRequest];
    [self requestUpdateWithAction:BJLWindowsUpdateAction_stick];
}

- (void)bringToFrontWithoutRequest {
    [self.view.superview bringSubviewToFront:self.view];
}

- (void)sendToBackWithoutRequest {
    [self.view.superview sendSubviewToBack:self.view];
}

- (void)updateWithRelativeRect:(CGRect)relativeRect {
    self.relativeRect = relativeRect;
}

@end

NS_ASSUME_NONNULL_END

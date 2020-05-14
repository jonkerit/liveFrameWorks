//
//  AppDelegate+ui.m
//  LivePlayerApp
//
//  Created by MingLQ on 2016-08-19.
//  Copyright © 2016年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/NSInvocation+BJL_M9Dev.h>
#import <BJLiveBase/UIAlertController+BJLAddAction.h>

#import <BJLiveCore/BJLiveCore.h>

#if DEBUG
#import <FLEX/FLEXManager.h>
#endif

#import "AppDelegate+ui.h"

#import "BJAppearance.h"
#import "UIViewController+BJUtil.h"
#import "UIWindow+motion.h"

#import "BJRootViewController.h"
#import "BJLoginViewController.h"

#import "BJAppConfig.h"

/** 如果采用 UINavigationController ，需要控制 navigation 的方向，
 因为 push 出来的教室方向无法由教室内控制器控制。
 不推荐使用。
 */
@interface BJNavigationController : UINavigationController

@end

@implementation BJNavigationController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.topViewController.preferredStatusBarStyle;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.topViewController.supportedInterfaceOrientations;
}

@end

@implementation AppDelegate (ui)

- (void)setupAppearance {
    UINavigationBar *navigationBar = [UINavigationBar appearance];
    [navigationBar setTintColor:[UIColor bj_navigationBarTintColor]];
    [navigationBar setTitleTextAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:18],
                                             NSForegroundColorAttributeName: [UIColor bj_navigationBarTintColor] }];
}

- (void)setupViewControllers {
    [self showViewController];
}

- (void)showViewController {
    Class viewControllerClass = [BJLoginViewController class];
    
    BJRootViewController *rootViewController = [BJRootViewController sharedInstance];
    
    UIViewController *activeViewController = rootViewController.activeViewController;
    if ([activeViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)activeViewController;
        activeViewController = navigationController.viewControllers.firstObject;
    }
    
    if (![activeViewController isKindOfClass:viewControllerClass]) {
        UIViewController *viewController = [[BJNavigationController alloc] initWithRootViewController:[viewControllerClass new]];
        if (rootViewController.presentedViewController) {
            [rootViewController dismissViewControllerAnimated:NO completion:^{
                [rootViewController switchViewController:viewController completion:nil];
            }];
        }
        else {
            [rootViewController switchViewController:viewController completion:nil];
        }
    }
}

#pragma mark - DeveloperTools

#if DEBUG

- (void)setupDeveloperTools {
    [FLEXManager sharedManager].networkDebuggingEnabled = YES;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(didShakeWithNotification:)
                               name:UIEventSubtypeMotionShakeNotification
                             object:nil];
}

- (void)didShakeWithNotification:(NSNotification *)notification {
    UIEventSubtypeMotionShakeState shakeState = [notification.userInfo bjl_integerForKey:UIEventSubtypeMotionShakeStateKey];
    if (shakeState == UIEventSubtypeMotionShakeStateEnded) {
        [self showDeveloperTools];
    }
}

static UIAlertController *AlertController = nil;

- (void)showDeveloperTools {
    if (AlertController) {
        return;
    }
    
    AlertController = [UIAlertController
                       alertControllerWithTitle:@"Developer Tools"
                       message:nil
                       preferredStyle:UIAlertControllerStyleActionSheet];
    
    [AlertController bjl_addActionWithTitle:[self nameOfDeployType:[BJAppConfig sharedInstance].deployType]
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action)
     {
         AlertController = nil;
         [self askToSwitchDeployType];
     }];
    
    UIAlertAction *flexAction =
    [AlertController bjl_addActionWithTitle:@"FLEX"
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action)
     {
         AlertController = nil;
         [[FLEXManager sharedManager] toggleExplorer];
     }];
    if (![FLEXManager sharedManager].isHidden) {
        [flexAction setValue:@YES forKey:@"checked"];
    }
    
    UIAlertAction *logsAction =
    [AlertController bjl_addActionWithTitle:@"监听日志"
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action)
     {
         AlertController = nil;
         NSObject.bjl_kvoLogsEnabled = NSObject.bjl_mpoLogsEnabled = !NSObject.bjl_kvoLogsEnabled;
     }];
    if (NSObject.bjl_kvoLogsEnabled) {
        [logsAction setValue:@YES forKey:@"checked"];
    }
    
    [AlertController bjl_addActionWithTitle:@"崩溃！"
                                      style:UIAlertActionStyleDestructive
                                    handler:^(UIAlertAction *action)
     {
         AlertController = nil;
         exit(0);
     }];
    
    [AlertController bjl_addActionWithTitle:@"取消"
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action)
     {
         AlertController = nil;
     }];
    
    AlertController.popoverPresentationController.sourceView = self.window;
    AlertController.popoverPresentationController.sourceRect = [UIApplication sharedApplication].statusBarFrame;
    AlertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    
    [[UIViewController topViewController] presentViewController:AlertController
                                                       animated:YES
                                                     completion:nil];
}

- (void)askToSwitchDeployType {
    if (AlertController) {
        return;
    }
    
    BJLDeployType currentDeployType = [BJAppConfig sharedInstance].deployType;
    
    AlertController = [UIAlertController
                       alertControllerWithTitle:@"切换环境"
                       message:@"注意：切换环境需要重启应用！"
                       preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (BJLDeployType deployType = 0; deployType < _BJLDeployType_count; deployType++) {
        UIAlertAction *action =
        [AlertController bjl_addActionWithTitle:[self nameOfDeployType:deployType]
                                          style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action)
         {
             AlertController = nil;
             [BJAppConfig sharedInstance].deployType = deployType;
         }];
        if (deployType == currentDeployType) {
            action.enabled = NO;
            [action setValue:@YES forKey:@"checked"];
        }
    }
    
    [AlertController bjl_addActionWithTitle:@"取消"
                                      style:UIAlertActionStyleCancel
                                    handler:^(UIAlertAction *action)
     {
         AlertController = nil;
     }];
    
    AlertController.popoverPresentationController.sourceView = self.window;
    AlertController.popoverPresentationController.sourceRect = [UIApplication sharedApplication].statusBarFrame;
    AlertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    
    [[UIViewController topViewController] presentViewController:AlertController
                                                       animated:YES
                                                     completion:nil];
}

- (NSString *)nameOfDeployType:(BJLDeployType)deployType {
    switch (deployType) {
        case BJLDeployType_test:
            return @"TEST";
        case BJLDeployType_beta:
            return @"BETA";
        case BJLDeployType_www:
            return @"WWW";
        default:
            return BJLStringFromValue(deployType, @"WWW");
    }
}

#endif

@end

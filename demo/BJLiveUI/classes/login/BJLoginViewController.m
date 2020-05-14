//
//  BJLoginViewController.m
//  LivePlayerApp
//
//  Created by MingLQ on 2016-07-01.
//  Copyright © 2016年 BaijiaYun. All rights reserved.
//

#import <BJLiveUI/BJLiveUI.h>

#import "BJLoginViewController.h"
#import "BJLoginView.h"
#import "BJViewControllerImports.h"
#import "BJAppConfig.h"

typedef NS_ENUM(NSInteger, BJRoomLayout) {
    BJRoomLayout_triple,           // 三分屏大班课
    BJRoomLayout_interactiveClass, // 互动(专业)小班课
    BJRoomLayout_normal,           // 普通大班课
};

static NSString * const BJLoginCodeKey = @"BJLoginCode";
static NSString * const BJLoginNameKey = @"BJLoginName";
static NSString * const BJLoginDomainKey = @"BJLoginDomainKey";

@interface BJLoginViewController () <UITextFieldDelegate, BJLRoomViewControllerDelegate, BJLScRoomViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) BJLoginView *codeLoginView;

@end

@implementation BJLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    self.codeLoginView = [self createLoginView];
    
    [self setCode:[userDefaults stringForKey:BJLoginCodeKey]
             name:[userDefaults stringForKey:BJLoginNameKey]
           domain:[userDefaults stringForKey:BJLoginDomainKey]];
    
    [self makeSignals];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.delegate = self;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortraitUpsideDown) forKey:@"orientation"];
    [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortrait) forKey:@"orientation"];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    return iPad ? UIInterfaceOrientationMaskLandscape : UIInterfaceOrientationMaskPortrait;
}

#pragma mark - subview

- (BJLoginView *)createLoginView {
    BJLoginView *loginView = [BJLoginView new];
    [self.view addSubview:loginView];
    [loginView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    return loginView;
}

- (void)makeSignals {
    bjl_weakify(self);
    
    // endEditing
    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer new];
    [self.view addGestureRecognizer:tapGesture];
    UIPanGestureRecognizer *panGesture = [UIPanGestureRecognizer new];
    [self.view addGestureRecognizer:panGesture];
    [[RACSignal merge:@[ tapGesture.rac_gestureSignal,
                         panGesture.rac_gestureSignal ]]
     subscribeNext:^(UIGestureRecognizer *gesture) {
         bjl_strongify(self);
         [self.view endEditing:YES];
     }];
    
    // clear cache if changed
    [[[self.codeLoginView.codeTextField.rac_textSignal
       distinctUntilChanged]
      skip:1]
     subscribeNext:^(NSString *codeText) {
         // bjl_strongify(self);
         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
         [userDefaults removeObjectForKey:BJLoginCodeKey];
         [userDefaults synchronize];
     }];
    [[[self.codeLoginView.nameTextField.rac_textSignal
       distinctUntilChanged]
      skip:1]
     subscribeNext:^(NSString *nameText) {
         // bjl_strongify(self);
         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
         [userDefaults removeObjectForKey:BJLoginNameKey];
         [userDefaults synchronize];
     }];
    
    // delegate
    self.codeLoginView.codeTextField.delegate = self;
    self.codeLoginView.nameTextField.delegate = self;
    
    // doneButton.enabled
    [[RACSignal
      combineLatest:@[ [RACSignal merge:@[ self.codeLoginView.codeTextField.rac_textSignal,
                                           RACObserve(self.codeLoginView.codeTextField, text) ]],
                       [RACSignal merge:@[ self.codeLoginView.nameTextField.rac_textSignal,
                                           RACObserve(self.codeLoginView.nameTextField, text) ]] ]
      reduce:^id(NSString *codeText, NSString *nameText) {
          // bjl_strongify(self);
          return @(codeText.length && nameText.length);
      }]
     subscribeNext:^(NSNumber *enabled) {
         bjl_strongify(self);
         self.codeLoginView.doneButton.enabled = enabled.boolValue;
     }];
    
    // login
    [[self.codeLoginView.doneButton rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(UIButton *button) {
         bjl_strongify(self);
         [self doneWithButton:button];
     }];
}

#pragma mark - events

- (void)doneWithButton:(UIButton *)button {
    [self.view endEditing:YES];
    
    [self storeCodeAndName];
    [self showAlertForChooseLayout];
}

#pragma mark - actions

- (void)showAlertForChooseLayout {
    bjl_weakify(self);
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"选择教室类型"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"大班课三分屏"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        bjl_strongify(self);
        [self enterRoomWithJoinCode:self.codeLoginView.codeTextField.text
                           userName:self.codeLoginView.nameTextField.text
                             domain:self.codeLoginView.privateDomainPrefixField.text
                         layoutType:BJRoomLayout_triple];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"小班课"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        bjl_strongify(self);
        [self enterRoomWithJoinCode:self.codeLoginView.codeTextField.text
                           userName:self.codeLoginView.nameTextField.text
                             domain:self.codeLoginView.privateDomainPrefixField.text
                         layoutType:BJRoomLayout_interactiveClass];
        
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"大班课旧模板"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        bjl_strongify(self);
        [self enterRoomWithJoinCode:self.codeLoginView.codeTextField.text
                           userName:self.codeLoginView.nameTextField.text
                             domain:self.codeLoginView.privateDomainPrefixField.text
                         layoutType:BJRoomLayout_normal];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    alertController.popoverPresentationController.sourceView = self.codeLoginView.doneButton;
    alertController.popoverPresentationController.sourceRect = self.codeLoginView.doneButton.frame;
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)enterRoomWithJoinCode:(NSString *)joinCode userName:(NSString *)userName domain:(NSString *)domain layoutType:(BJRoomLayout)layoutType {
    BJLRoom.deployType = [BJAppConfig sharedInstance].deployType; // !!!: internal
    if (domain.length) {
        [BJLRoom setPrivateDomainPrefix:domain];
    }
    switch (layoutType) {
        case BJRoomLayout_interactiveClass: {
            BJLIcRoomViewController *roomViewController =
            [BJLIcRoomViewController instanceWithSecret:joinCode
                                               userName:userName
                                             userAvatar:nil];
            //[self.navigationController bjl_pushViewController:roomViewController animated:YES completion:nil];
            [self bjl_presentFullScreenViewController:roomViewController animated:YES completion:nil];
            break;
        }
            
        case BJRoomLayout_normal: {
            BJLRoomViewController *roomViewController =
            [BJLRoomViewController instanceWithSecret:joinCode
                                             userName:userName
                                           userAvatar:nil];
            roomViewController.delegate = self;
            //[self.navigationController bjl_pushViewController:roomViewController animated:YES completion:nil];
            [self bjl_presentFullScreenViewController:roomViewController animated:YES completion:nil];
            break;
        }
            
        default: {
            BJLScRoomViewController *roomViewController =
            [BJLScRoomViewController instanceWithSecret:joinCode
                                             userName:userName
                                           userAvatar:nil];
            roomViewController.delegate = self;
            //[self.navigationController bjl_pushViewController:roomViewController animated:YES completion:nil];
            [self bjl_presentFullScreenViewController:roomViewController animated:YES completion:nil];
            break;
        }
    }
}

#pragma mark - state

- (void)setCode:(NSString *)code name:(NSString *)name domain:(NSString *)domain {
    BJLoginView *loginView = self.codeLoginView;
    loginView.privateDomainPrefixField.text = domain;
    loginView.codeTextField.text = code;
    loginView.nameTextField.text = name;
    loginView.doneButton.enabled = code.length && name.length;
}

- (void)storeCodeAndName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.codeLoginView.codeTextField.text
                     forKey:BJLoginCodeKey];
    [userDefaults setObject:self.codeLoginView.nameTextField.text
                     forKey:BJLoginNameKey];
    [userDefaults setObject:self.codeLoginView.privateDomainPrefixField.text?:@""
                     forKey:BJLoginDomainKey];
    [userDefaults synchronize];
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.codeLoginView.codeTextField) {
        [self.codeLoginView.nameTextField becomeFirstResponder];
    }
    else if (textField == self.codeLoginView.nameTextField) {
        if (self.codeLoginView.doneButton.enabled) {
            [self doneWithButton:self.codeLoginView.doneButton];
        }
    }
    return NO;
}

#pragma mark - <BJLRoomViewControllerDelegate> 或 <BJLScRoomViewControllerDelegate> 小班课代理demo中未添加，需要自行添加

/** 进入教室 - 成功 */
- (void)roomViewControllerEnterRoomSuccess:(UIViewController *)roomViewController {
    NSLog(@"[%@ %@]", NSStringFromSelector(_cmd), roomViewController);
}

/** 进入教室 - 失败 */
- (void)roomViewController:(UIViewController *)roomViewController
 enterRoomFailureWithError:(BJLError *)error {
    NSLog(@"[%@ %@, %@]", NSStringFromSelector(_cmd), roomViewController, error);
}

/**
 退出教室 - 正常/异常
 正常退出 `error` 为 `nil`，否则为异常退出
 参考 `BJLErrorCode` */
- (void)roomViewController:(UIViewController *)roomViewController
         willExitWithError:(nullable BJLError *)error {
    NSLog(@"[%@ %@, %@]", NSStringFromSelector(_cmd), roomViewController, error);
    // 教室处于横屏情况下退出可以旋转回竖屏
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    if (!iPad) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortraitUpsideDown) forKey:@"orientation"];
            [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortrait) forKey:@"orientation"];
        });
    }
}

/**
 退出教室 - 正常/异常
 正常退出 `error` 为 `nil`，否则为异常退出
 参考 `BJLErrorCode` */
- (void)roomViewController:(UIViewController *)roomViewController
          didExitWithError:(nullable BJLError *)error {
    NSLog(@"[%@ %@, %@]", NSStringFromSelector(_cmd), roomViewController, error);
}

/**
 点击教室右上方自定义按钮回调，仅旧版本大班课支持
 此方法返回的 view-controller 可以像用户列表一样显示在教室内
 `didMoveToParentViewController:` 后 view-controller 的 `bjl_overlayContainerController` 属性可用
 通过该属性可以设置统一样式的标题、导航栏按钮、底部按钮、以及关闭等，参考 `BJLOverlayContainerController`
 */
- (nullable UIViewController *)roomViewController:(BJLRoomViewController *)roomViewController
        viewControllerToShowForTopBarCustomButton:(UIButton *)button {
    return nil;
}

#pragma mark - UINavigationControllerDelegate

/** 如果是 push 出教室界面，在一个竖屏界面把设备横屏，然后进入会导致无法触发竖屏到横屏的旋转效果，进入后仍然保持横屏状态。
除此之外，即使是立刻触发了旋转逻辑，也会因为旋转需要的时间，导致教室内部一些需要获取固定数值的控件计算错误。
 */
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController.supportedInterfaceOrientations & self.supportedInterfaceOrientations) {
    }
    else {
        [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortraitUpsideDown) forKey:@"orientation"];
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
    }
}

@end

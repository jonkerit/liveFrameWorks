//
//  BJLImageViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-22.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLAuthorization.h>

#import "BJLImageViewController.h"

#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLImageViewController ()

@property (nonatomic, readwrite) UIImageView *imageView;

@end

@implementation BJLImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor bjl_darkGrayBackgroundColor];
    
    self.imageView = [UIImageView new];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    [self.imageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(closeWithGestureRecognizer:)];
    [self.view addGestureRecognizer:tapGesture];
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self
                                                      action:@selector(saveWithGestureRecognizer:)];
    [self.view addGestureRecognizer:longPressGesture];
    [tapGesture requireGestureRecognizerToFail:longPressGesture];
    self.imageView.userInteractionEnabled = YES;
    [self.imageView bjl_makePanGestureToHide:^{
        [self hide];
    } customerHander:nil parentView:self.view];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)closeWithGestureRecognizer:(UITapGestureRecognizer *)tap {
    [self hide];
}

- (void)saveWithGestureRecognizer:(UILongPressGestureRecognizer *)longPress {
    if (!self.imageView.image || longPress.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    UIAlertController *actionSheet = [UIAlertController
                                      bjl_lightAlertControllerWithTitle:@"保存图片"
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    bjl_weakify(self);
    [actionSheet bjl_addActionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        bjl_strongify(self);
        [BJLAuthorization checkPhotosAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
            if (granted) {
                UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            }
            else if (alert) {
                if (self.presentedViewController) {
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                }
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }];
    [actionSheet bjl_addActionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    actionSheet.popoverPresentationController.sourceView = self.imageView;
    actionSheet.popoverPresentationController.sourceRect = ({
        CGRect rect = self.imageView.bounds;
        rect.origin.y = CGRectGetMaxY(rect) - 1.0;
        rect.size.height = 1.0;
        rect;
    });
    actionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message = error ? [NSString stringWithFormat:@"保存图片出错: %@", [error localizedDescription]] : @"图片已保存";
    [self showProgressHUDWithText:message];
}

- (void)hide {
    if (self.hideCallback) self.hideCallback(self);
}

@end

NS_ASSUME_NONNULL_END

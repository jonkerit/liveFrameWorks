//
//  BJLScImageViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/9.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScImageViewController.h"
#import "BJLScAppearance.h"
#import "BJLScImageCell.h"

static NSString *imageCellReuseIdentifier = @"kScImageCellReuseIdentifier";

@interface BJLScImageViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSMutableArray<BJLMessage *> *messages;
@property (nonatomic) NSInteger currentMessageIndex;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIButton *saveImageButton;
@property (nonatomic) BOOL isStickyMessage;

@end

@implementation BJLScImageViewController

- (instancetype)initWithMessage:(BJLMessage *)currentMessage imageMessages:(NSArray<BJLMessage *> *)imageMessages isStickyMessage:(BOOL)isStickyMessage {
    self = [super init];
    if (self) {
        self.messages = [imageMessages mutableCopy];
        self.isStickyMessage = isStickyMessage;
        for (NSInteger i = 0; i < imageMessages.count; i ++) {
            BJLMessage *message = [imageMessages bjl_objectAtIndex:i];
            if ([message.ID isEqualToString:currentMessage.ID]) {
                self.currentMessageIndex = i;
            }
        }
    }
    return self;
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentMessageIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];

    [self makeSubviewsAndConstraints];
}

- (void)makeSubviewsAndConstraints {
    self.collectionView = ({
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0.0;
        layout.minimumLineSpacing = 0.0;
        layout.sectionInset = UIEdgeInsetsZero;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.pagingEnabled = YES;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.accessibilityLabel = BJLKeypath(self, collectionView);
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [collectionView registerClass:[BJLScImageCell class] forCellWithReuseIdentifier:imageCellReuseIdentifier];
        collectionView;
    });
    [self.view addSubview:self.collectionView];
    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    self.saveImageButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_chat_saveimage"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:self.saveImageButton];
    [self.saveImageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.bottom.equalTo(self.view).inset(8.0);
        make.width.height.equalTo(@44.0);
    }];
}

#pragma mark - action
- (void)saveImage {
    BJLScImageCell *cell = (BJLScImageCell *)[self.collectionView cellForItemAtIndexPath:[self.collectionView indexPathForItemAtPoint:self.collectionView.contentOffset]];
    [self saveImage:cell];
}

- (void)saveImage:(BJLScImageCell *)cell {
    if (!cell.imageView.image) {
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
                       UIImageWriteToSavedPhotosAlbum(cell.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                   }
                   else if (alert) {
                       [[UIViewController bjl_topViewController] presentViewController:alert animated:YES completion:nil];
                   }
               }];
    }];
    [actionSheet bjl_addActionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    actionSheet.popoverPresentationController.sourceView = cell.imageView;
    actionSheet.popoverPresentationController.sourceRect = ({
        CGRect rect = cell.imageView.bounds;
        rect.origin.y = CGRectGetMaxY(rect) - 1.0;
        rect.size.height = 1.0;
        rect;
    });
    actionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    
    [[UIViewController bjl_topViewController] presentViewController:actionSheet animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message = error ? [NSString stringWithFormat:@"保存图片出错: %@", [error localizedDescription]] : @"图片已保存";
    [self showProgressHUDWithText:message];
}

- (void)hide {
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

#pragma mark - delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLScImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageCellReuseIdentifier forIndexPath:indexPath];
    BJLMessage *message = [self.messages bjl_objectAtIndex:indexPath.row];
    [cell updateWithMessage:message isStickyMessage:self.isStickyMessage];
    bjl_weakify(self);
    [cell setHideCallback:^{
        bjl_strongify(self);
        [self hide];
    }];
    
    [cell setSaveImageCallback:^(UIImage * _Nonnull image) {
        bjl_strongify(self);
        BJLScImageCell *currentCell = (BJLScImageCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self saveImage:currentCell];
    }];
    
    [cell setCancelStickyCallback:^{
        bjl_strongify(self);
        if (self.cancelStickyCallback) {
            self.cancelStickyCallback();
        }
    }];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.bounds.size;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:self.collectionView.contentOffset];
    self.currentMessageIndex = indexPath.row;
}

@end

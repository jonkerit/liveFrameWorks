//
//  BJLIcChatImageView.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/9/3.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcChatImageView.h"
#import "BJLIcAppearance.h"

static NSString *imageCellReuseIdentifier = @"kIcImageCellReuseIdentifier";

@interface BJLIcImageCell : UICollectionViewCell <UIScrollViewDelegate>

@property (nonatomic, nullable) void (^hideCallback)(void);

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *placeholderLabel;
@property (nonatomic) UIScrollView *scrollView;

@end

@implementation BJLIcImageCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.placeholderLabel.hidden = NO;
}

- (void)makeSubviewsAndConstraints {
    self.scrollView = ({
        UIScrollView *scrollView = [UIScrollView new];
        scrollView.backgroundColor = [UIColor clearColor];
        scrollView.delegate = self;
        scrollView.multipleTouchEnabled = YES;
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 5.0;
        scrollView.pagingEnabled = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        scrollView;
    });
    [self addSubview:self.scrollView];
    [self.scrollView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    self.placeholderLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"正在加载中...";
        label.font = [UIFont systemFontOfSize:16.0];
        label.textColor = [UIColor whiteColor];
        label;
    });
    [self.scrollView addSubview:self.placeholderLabel];
    [self.placeholderLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.scrollView);
    }];
    self.imageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.scrollView addSubview:self.imageView];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(hide)];
    [self addGestureRecognizer:tapGesture];
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self
                                                      action:@selector(saveWithGestureRecognizer:)];
    [self addGestureRecognizer:longPressGesture];
    [tapGesture requireGestureRecognizerToFail:longPressGesture];
}

#pragma mark - scroll view

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self updateCenterForPPTImageView];
}

- (void)updateCenterForPPTImageView {
    CGSize size = self.scrollView.bounds.size;
    CGSize contentSize = self.scrollView.contentSize;
    CGFloat offsetX = ((size.width > contentSize.width) ?
                       (size.width - contentSize.width) * 0.5 : 0.0);
    CGFloat offsetY = ((size.height > contentSize.height) ?
                       (size.height - contentSize.height) * 0.5 : 0.0);
    self.imageView.center = CGPointMake(contentSize.width * 0.5 + offsetX,
                                        contentSize.height * 0.5 + offsetY);
}

- (CGRect)suitableSizeWithImageSize:(CGSize)size {
    CGFloat originX = 0.0;
    CGFloat originY = 0.0;
    CGFloat imageWidth = size.width;
    CGFloat imageHeight = size.height;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = screenHeight * [BJLIcAppearance sharedAppearance].layoutRatio;
    // 图片宽高均大于屏幕宽高
    if (imageWidth > screenWidth && imageHeight > screenHeight) {
        // 图片宽高比大于屏幕, 宽图
        if (imageWidth / imageHeight > screenWidth / screenHeight) {
            imageWidth = screenWidth;
            imageHeight = screenWidth * imageHeight / size.width;
            originX = 0.0;
            originY = (screenHeight - imageHeight) / 2.0;
        }
        // 图片高宽比小于屏幕, 长图
        else {
            imageHeight = screenHeight;
            imageWidth = screenHeight * imageWidth / size.height;
            originX = (screenWidth - imageWidth) / 2.0;
            originY = 0.0;
        }
    }
    // 图片宽大于屏幕宽, 宽图
    else if (imageWidth > screenWidth) {
        imageWidth = screenWidth;
        imageHeight = screenWidth * imageHeight / size.width;
        originX = 0.0;
        originY = (screenHeight - imageHeight) / 2.0;
    }
    // 图片高大于屏幕高, 长图
    else if (imageHeight > screenHeight) {
        imageHeight = screenHeight;
        imageWidth = screenHeight * imageWidth / size.height;
        originX = (screenWidth - imageWidth) / 2.0;
        originY = 0.0;
    }
    // 图片小于屏幕宽高
    else if (imageWidth <= screenWidth && imageHeight <= screenHeight) {
        originX = (screenWidth - imageWidth) / 2.0;
        originY = (screenHeight - imageHeight) / 2.0;
    }
    return CGRectMake(originX, originY, imageWidth, imageHeight);
}

#pragma mark - save image

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
        [self saveImage];
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
    
    [[UIViewController bjl_topViewController] presentViewController:actionSheet animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message = error ? [NSString stringWithFormat:@"保存图片出错: %@", [error localizedDescription]] : @"图片已保存";
    [BJLProgressHUD bjl_showHUDForText:message superview:self animated:YES];
}

- (void)saveImage {
    [BJLAuthorization checkPhotosAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
               if (granted) {
                   UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
               }
               else if (alert) {
                   [[UIViewController bjl_topViewController] presentViewController:alert animated:YES completion:nil];
               }
           }];
}

#pragma mark - callback

- (void)hide {
    if (self.hideCallback) {
        self.hideCallback();
    }
}

- (void)updateWithMessage:(BJLMessage *)message {
    self.placeholderLabel.text = @"正在加载中...";
    bjl_weakify(self);
    if (message.imageWidth > 0 && message.imageHeight > 0) {
        CGRect imageRect = [self suitableSizeWithImageSize:CGSizeMake(message.imageWidth, message.imageHeight)];
        self.scrollView.contentSize = imageRect.size;
        self.imageView.frame = imageRect;
        [self.imageView bjl_setImageWithURL:[NSURL URLWithString:message.imageURLString] placeholder:nil completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
            bjl_strongify(self);
            if (image) {
                self.placeholderLabel.hidden = YES;
            }
            else {
                self.placeholderLabel.text = error.localizedFailureReason ?: error.localizedDescription;
            }
        }];
    }
    else {
        [self.imageView bjl_setImageWithURL:[NSURL URLWithString:message.imageURLString] placeholder:nil completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
            bjl_strongify(self);
            if (image) {
                self.placeholderLabel.hidden = YES;
                CGRect imageRect = [self suitableSizeWithImageSize:CGSizeMake(image.size.width, image.size.height)];
                self.scrollView.contentSize = imageRect.size;
                self.imageView.frame = imageRect;
            }
            else {
                self.placeholderLabel.text = error.localizedFailureReason ?: error.localizedDescription;
            }
            
        }];
    }
}

@end

@interface BJLIcChatImageView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSMutableArray<BJLMessage *> *messages;
@property (nonatomic) NSInteger currentMessageIndex;
@property (nonatomic) BJLMessage *currentMessage;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIButton *saveImageButton;

@end

@implementation BJLIcChatImageView

- (instancetype)initWithMessages:(NSArray<BJLMessage *> *)messages currentMessage:(BJLMessage *)currentMessage {
    if (self = [super initWithFrame:CGRectZero]) {
        self.messages = [messages mutableCopy];
        for (NSInteger i = 0; i < messages.count; i ++) {
            BJLMessage *message = [messages bjl_objectAtIndex:i];
            if ([message.ID isEqualToString:currentMessage.ID]) {
                self.currentMessageIndex = i;
            }
        }
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
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
        [collectionView registerClass:[BJLIcImageCell class] forCellWithReuseIdentifier:imageCellReuseIdentifier];
        collectionView;
    });
    [self addSubview:self.collectionView];
    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    self.saveImageButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_chat_saveimage"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self addSubview:self.saveImageButton];
    [self.saveImageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.bottom.equalTo(self).inset(8.0);
        make.width.height.equalTo(@44.0);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentMessageIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

#pragma mark - action

- (void)updateMessages:(NSMutableArray<BJLMessage *> *)messages {
    self.messages = messages;
    [self.collectionView reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentMessageIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)saveImage {
    BJLIcImageCell *cell = (BJLIcImageCell *)[self.collectionView cellForItemAtIndexPath:[self.collectionView indexPathForItemAtPoint:self.collectionView.contentOffset]];
    [cell saveImage];
}

#pragma mark - delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageCellReuseIdentifier forIndexPath:indexPath];
    BJLMessage *message = [self.messages bjl_objectAtIndex:indexPath.row];
    [cell updateWithMessage:message];
    bjl_weakify(self);
    [cell setHideCallback:^{
        bjl_strongify(self);
        if (self.hideCallback) {
            self.hideCallback();
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

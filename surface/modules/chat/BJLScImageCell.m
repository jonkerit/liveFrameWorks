//
//  BJLScImageCell.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/9.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScImageCell.h"
#import "BJLScAppearance.h"
#import <BJLiveBase/BJLiveBase.h>

@interface BJLScImageCell ()<UIScrollViewDelegate>

@property (nonatomic, readwrite) UIImageView *imageView;
@property (nonatomic) UILabel *placeholderLabel, *userNameLabel;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIButton *cancelStickyButton;

@end

@implementation BJLScImageCell

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
    [self.contentView addSubview:self.scrollView];
    [self.scrollView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView);
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
                                          action:@selector(hide:)];
    [self addGestureRecognizer:tapGesture];
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self
                                                      action:@selector(saveWithGestureRecognizer:)];
    [self addGestureRecognizer:longPressGesture];
    [tapGesture requireGestureRecognizerToFail:longPressGesture];
    
    UIView *nameContainView = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0x666666 alpha:0.5];
        view.layer.cornerRadius = 14.0;
        view.layer.masksToBounds = YES;
        view;
    });
    self.userNameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor bjl_colorWithHex:0x666666 alpha:0.5];
        label.numberOfLines = 1;
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor whiteColor];
        label;
    });
    [self.contentView addSubview:nameContainView];
    [nameContainView addSubview:self.userNameLabel];
    
    [nameContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.equalTo(self.contentView).offset(8.0);
        make.right.lessThanOrEqualTo(self.contentView);
        make.height.equalTo(@(26));
    }];
    [self.userNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.top.bottom.equalTo(nameContainView).with.inset(8);
    }];
    
    self.cancelStickyButton = ({
        UIButton *button = [UIButton new];
        button.hidden = YES;
        [button setTitle:@"取消置顶" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.layer.cornerRadius = 14.0;
        button.layer.masksToBounds = YES;
        [button.titleLabel setFont:[UIFont systemFontOfSize:12.0]];
        [button setBackgroundColor:[UIColor bjl_colorWithHex:0x666666 alpha:0.5]];
        button.accessibilityLabel = BJLKeypath(self, cancelStickyButton);
        [button setContentEdgeInsets:UIEdgeInsetsMake(4, 10, 4, 10)];
        [button addTarget:self action:@selector(cancelSticky) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.contentView addSubview:self.cancelStickyButton];
    [self.cancelStickyButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.top.equalTo(self.contentView).inset(8.0);
        make.left.greaterThanOrEqualTo(self.contentView);
        make.height.equalTo(@(26));
    }];
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
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
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
    
    if (self.saveImageCallback) {
        self.saveImageCallback(self.imageView.image);
    }
}

- (void)hide:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self];
    
    CGRect cancelStickyButtonFrame = [self convertRect:self.cancelStickyButton.frame fromView:self.contentView];
    if (CGRectContainsPoint(cancelStickyButtonFrame, point)) {
        [self cancelSticky];
        return;
    }

    if (self.hideCallback) {
        self.hideCallback();
    }
}

- (void)cancelSticky {
    if (self.cancelStickyCallback) {
        self.cancelStickyCallback();
    }
}

- (void)updateWithMessage:(BJLMessage *)message isStickyMessage:(BOOL)isStickyMessage{
    bjl_weakify(self);
    self.cancelStickyButton.hidden = !isStickyMessage;
    NSString *name = message.fromUser.displayName;
    if (message.fromUser.isTeacherOrAssistant) {
        NSString *roleString = message.fromUser.isTeacher ? @"老师" : @"助教";
        name = [NSString stringWithFormat:@"%@[%@]", message.fromUser.displayName, roleString];
    }
    self.userNameLabel.text = name;

    CGRect imageRect = [self suitableSizeWithImageSize:CGSizeMake(message.imageWidth, message.imageHeight)];
    self.scrollView.contentSize = imageRect.size;
    self.imageView.frame = imageRect;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat maxSize = MAX(screenSize.width, screenSize.height);
    NSString *aliURLString = BJLAliIMG_aspectFit(CGSizeMake(maxSize, maxSize),
                                                 0.0,
                                                 message.imageURLString,
                                                 nil);
    [self.imageView bjl_setImageWithURL:[NSURL URLWithString:aliURLString]
                            placeholder:nil
                             completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
        bjl_strongify(self);
        self.placeholderLabel.hidden = YES;
        CGRect imageRect = [self suitableSizeWithImageSize:image.size];
        self.imageView.frame = imageRect;
    }];
}

@end

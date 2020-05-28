//
//  BJLIcChatDetailViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/16.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcChatDetailViewController.h"
#import "BJLIcChatImageView.h"
#import "BJLIcAppearance.h"
#import "BJLAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcChatDetailViewController ()

@property (nonatomic) BJLMessage *message;
@property (nonatomic) NSArray<BJLMessage *> *imageMessages;
@property (nonatomic) UIImage *image;
@property (nonatomic) NSAttributedString *attributedText;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) BJLIcChatImageView *imageView;
@property (nonatomic) UITextView *messageTextView;

@end

@implementation BJLIcChatDetailViewController

- (instancetype)initWithMessage:(BJLMessage *)message imageMessages:(nonnull NSArray<BJLMessage *> *)imageMessages {
    if (self = [super init]) {
        self.message = message;
        self.imageMessages = imageMessages;
        if (message.type == BJLMessageType_text) {
           NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 15.0;
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            paragraphStyle.alignment = NSTextAlignmentLeft;
            NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:16.0],
                                            NSForegroundColorAttributeName : [UIColor bjl_colorWithHexString:@"#3D3D3E" alpha:1.0],
                                            NSParagraphStyleAttributeName : paragraphStyle};
            if (message.translation.length) {
                self.attributedText = [[NSAttributedString alloc] initWithString:(message.translation.length ? message.translation : message.text) attributes:attributedDic];
            }
            else {
                self.attributedText = [message attributedEmoticonStringWithEmoticonSize:20.0 attributes:attributedDic cached:YES cachedKey:@"cache"];
            }
        }
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 视图在 did appear 的时候才能获取到正确的宽高
    [self makeSubviewsAndConstraints];
    if (self.message.type == BJLMessageType_text) {
        [self makeObserving];
    }
}

- (void)makeSubviewsAndConstraints {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    // 毛玻璃效果
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIView *backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    [self.view addSubview:backgroundView];
    [backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    if (self.message.type == BJLMessageType_image) {
        self.scrollView = ({
            UIScrollView *scrollView = [UIScrollView new];
            scrollView.showsVerticalScrollIndicator = NO;
            scrollView.showsHorizontalScrollIndicator = NO;
            scrollView;
        });
        [self.view addSubview:self.scrollView];
        [self.scrollView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        
        self.imageView = ({
            BJLIcChatImageView *imageView = [[BJLIcChatImageView alloc] initWithMessages:self.imageMessages currentMessage:self.message];
            imageView;
        });
        [self.view addSubview:self.imageView];
        [self.imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.view);
        }];
        bjl_weakify(self);
        [self.imageView setHideCallback:^{
            bjl_strongify(self);
            [self hide];
        }];
    }
    else {
        UIView *messageView = ({
            UIView *view = [UIView new];
            view.backgroundColor = [UIColor clearColor];
            view.layer.masksToBounds = NO;
            view.layer.shadowOpacity = 0.3;
            view.layer.shadowColor = [UIColor blackColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
            view.layer.shadowRadius = 10.0;
            view;
        });
        [self.view addSubview:messageView];
        [messageView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.center.equalTo(self.view);
            make.width.equalTo(@(screenWidth * 4/10));
            make.height.equalTo(@(screenHeight * 8/10));
        }];
        
        self.messageTextView = ({
            UITextView *textView = [UITextView new];
            textView.backgroundColor = [UIColor whiteColor];
            textView.layer.cornerRadius = 16.0;
            textView.layer.masksToBounds = YES;
            textView.showsVerticalScrollIndicator = NO;
            textView.showsHorizontalScrollIndicator = NO;
            textView.editable = NO;
            textView.scrollEnabled = YES;
            textView.userInteractionEnabled = YES;
            textView.font = [UIFont systemFontOfSize:16.0];
            textView.attributedText = self.attributedText;
            textView;
            
        });
        [messageView addSubview:self.messageTextView];
        [self.messageTextView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(messageView);
        }];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        tapGesture.numberOfTapsRequired = 1;
        [self.view addGestureRecognizer:tapGesture];
    }
}

- (void)makeObserving {
    if (self.message.text.length) {
        bjl_weakify(self);
        [self bjl_kvo:BJLMakeProperty(self.messageTextView, bounds)
             observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (!self.messageTextView.bounds.size.height) {
                     return YES;
                 }
                 CGFloat insetSize = 24.0;
                 if (self.messageTextView.contentSize.height <= self.messageTextView.bounds.size.height - insetSize * 2) {
                     insetSize = (self.messageTextView.bounds.size.height - self.messageTextView.contentSize.height) / 2;
                 }
                 self.messageTextView.textContainerInset = UIEdgeInsetsMake(insetSize, 24.0, insetSize, 24.0);
                 return NO;
             }];
    }
}

- (void)hide {
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

@end

NS_ASSUME_NONNULL_END

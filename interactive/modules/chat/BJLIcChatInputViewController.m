//
//  BJLIcChatInputViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/15.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLConstants.h>

#import "BJLIcChatInputViewController.h"
#import "BJLEmoticonKeyboardView.h"
#import "BJLIcAppearance.h"
#import "BJLViewImports.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcChatInputViewController () <UITextViewDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic) NSString *text;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UITextView *textView;
@property (nonatomic) UIView *textViewTapMask;
@property (nonatomic) BJLEmoticonKeyboardView *emoticonKeyboardView;
@property (nonatomic) UIViewController *emoticonViewController;
@property (nonatomic) UIButton *emoticonButton;

@end

@implementation BJLIcChatInputViewController

- (instancetype)initWithText:(NSString *)text {
    if (self = [super init]) {
        self.text = text;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviewsAndConstraints];
    [UIMenuController sharedMenuController].menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"换行" action:@selector(insertNewLine:)] ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidChangeFrameNotification
                                                  object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.emoticonKeyboardView.emoticons = [BJLEmoticon allEmoticons];
    [self.textView becomeFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender {
    if (action == @selector(insertNewLine:)
        && [self.textView isFirstResponder]) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)insertNewLine:(nullable id)sender {
    self.textView.text = [self.textView.text
                          stringByReplacingCharactersInRange:self.textView.selectedRange
                          withString:@"\n"];
}

#pragma mark - subview

- (void)makeSubviewsAndConstraints {
    self.containerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        view;
    });
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(0.0);
    }];
    
    self.emoticonButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.accessibilityLabel = BJLKeypath(self, emoticonButton);
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_chat_emoji_normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_chat_emoji_selected"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(updateEmoticonViewHidden) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.containerView addSubview:self.emoticonButton];
    [self.emoticonButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.containerView).offset(14.0);
        make.centerY.equalTo(self.containerView);
        make.width.height.equalTo(@32.0);
    }];
    
    self.textView = ({
        CGFloat margin = (bjl_iPhoneXSeries() ? 32.0 : 0.0);
        UITextView *textView = [UITextView new];
        textView.accessibilityLabel = BJLKeypath(self, textView);
        textView.backgroundColor = [UIColor clearColor];
        textView.textContainerInset = UIEdgeInsetsMake([BJLIcAppearance sharedAppearance].chatViewSmallSpace, [BJLIcAppearance sharedAppearance].chatViewLargeSpace + margin, [BJLIcAppearance sharedAppearance].chatViewSmallSpace, [BJLIcAppearance sharedAppearance].chatViewLargeSpace + margin);
        textView.textColor = [UIColor whiteColor];
        textView.font = [UIFont systemFontOfSize:33.0];
        textView.returnKeyType = UIReturnKeySend;
        textView.keyboardType = UIKeyboardTypeDefault;
        textView.enablesReturnKeyAutomatically = YES;
        textView.delegate = self;
        textView.text = self.text;
        textView;
    });
    [self.containerView addSubview:self.textView];
    [self.textView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.emoticonButton.bjl_right);
        make.top.right.bottom.equalTo(self.containerView);
        make.height.equalTo(@48.0);
    }];
    
    // 聊天框点击响应视图
    self.textViewTapMask = ({
        UIView *view = [UIView new];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(clearInputView)];
        [view addGestureRecognizer:tapGesture];
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(clearInputView)];
        [view addGestureRecognizer:panGesture];
        view.hidden = YES;
        view;
    });
    [self.containerView addSubview:self.textViewTapMask];
    [self.textViewTapMask bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.textView);
    }];
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    self.emoticonKeyboardView = [[BJLEmoticonKeyboardView alloc] initForIdiomPad:iPad];
    if (iPad) {
        self.emoticonViewController = [UIViewController new];
        [self.emoticonViewController.view addSubview:self.emoticonKeyboardView];
        [self.emoticonKeyboardView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.emoticonViewController.view.bjl_safeAreaLayoutGuide ?: self.emoticonViewController.view);
        }];
    }
    bjl_weakify(self);
    [self.emoticonKeyboardView setSelectEmoticonCallback:^(BJLEmoticon * _Nonnull emoticon) {
        bjl_strongify(self);
        [self updateTextViewWithEmoticon:emoticon];
    }];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    [self bjl_kvo:BJLMakeProperty(self.textView, inputView)
         observer:^BOOL(UIView *  _Nullable now, UIView *  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             // 光标颜色
             self.textView.tintColor = now? [UIColor clearColor] : [UIColor blueColor];
             self.textViewTapMask.hidden = !now;
             return YES;
         }];
}

#pragma mark - notification

- (void)keyboardChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    CGRect keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
    
    NSTimeInterval animationDuration = bjl_as(userInfo[UIKeyboardAnimationDurationUserInfoKey], NSNumber).doubleValue;
    UIViewAnimationOptions animationOptions = ({
        NSNumber *animationCurveNumber = bjl_as(userInfo[UIKeyboardAnimationCurveUserInfoKey], NSNumber);
        UIViewAnimationCurve animationCurve = (animationCurveNumber != nil
                                               ? animationCurveNumber.unsignedIntegerValue
                                               : UIViewAnimationCurveEaseInOut);
        // @see http://stackoverflow.com/a/19490788/456536
        animationCurve | animationCurve << 16; // @see UIViewAnimationOptionCurveXxxx
    });
    [self.view layoutIfNeeded];
    CGFloat offset = (CGRectGetMinY(keyboardFrame) >= CGRectGetHeight([UIScreen mainScreen].bounds)
                      ? 0.0 : - CGRectGetHeight(keyboardFrame));
    [self.containerView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(offset);
    }];
    [self.view setNeedsLayout];
    // TODO: MingLQ - animate not working
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:animationOptions
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

#pragma mark - <UIContentContainer>

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [self.emoticonKeyboardView updateLayoutForTraitCollection:newCollection animated:YES];
    } completion:nil];
}

#pragma mark - action

- (void)clearInputView {
    self.emoticonButton.selected = NO;
    self.textView.inputView = nil;
    [self.textView reloadInputViews];
}

- (void)updateEmoticonViewHidden {
    self.emoticonButton.selected = !self.emoticonButton.isSelected;
    
    if (self.emoticonButton.selected) {
        [self.emoticonKeyboardView updateLayoutForTraitCollection:self.traitCollection animated:NO];
    }
    if (self.emoticonViewController) {
        if (self.emoticonButton.selected) {
            self.emoticonViewController.modalPresentationStyle = UIModalPresentationPopover;
            self.emoticonViewController.preferredContentSize = self.emoticonKeyboardView.frame.size;
            // popoverPresentationController 会被自动重置为空
            self.emoticonViewController.popoverPresentationController.delegate = self;
            self.emoticonViewController.popoverPresentationController.backgroundColor = [UIColor whiteColor];
            self.emoticonViewController.popoverPresentationController.sourceView = self.emoticonButton;
            self.emoticonViewController.popoverPresentationController.sourceRect = self.emoticonButton.bounds;
            self.emoticonViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
            if (self.presentedViewController) {
                [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
            }
            [self presentViewController:self.emoticonViewController animated:YES completion:nil];
        }
        else {
            [self.emoticonViewController bjl_dismissAnimated:YES completion:nil];
        }
    }
    else {
        self.textView.inputView = self.emoticonButton.selected ? self.emoticonKeyboardView : nil;
        [self.textView reloadInputViews];
    }
}

- (void)updateTextViewWithEmoticon:(BJLEmoticon *)emoticon {
    NSRange range = self.textView.selectedRange;
    NSString *text = self.textView.text;
    NSString *formatEmoticonString = [NSString stringWithFormat:@"[%@]", emoticon.name];
    self.textView.text = [text stringByReplacingCharactersInRange:range withString:formatEmoticonString];
    self.textView.selectedRange = NSMakeRange(range.location + formatEmoticonString.length, 0);
}

- (void)hide {
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

#pragma mark - text view delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        textView.text = [textView.text stringByAppendingString:@"\n"];
        [self hide];
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    dispatch_async(dispatch_get_main_queue(), ^{
        // max length
        if (textView.text.length > BJLTextMaxLength_chat) {
            UITextRange *markedTextRange = textView.markedTextRange;
            if (!markedTextRange || markedTextRange.isEmpty) {
                textView.text = [textView.text substringToIndex:BJLTextMaxLength_chat];
                [textView.undoManager removeAllActions];
            }
        }
    });
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.editCallback) {
        self.editCallback(textView.text);
    }
    [self hide];
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.emoticonButton.selected = NO;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end

NS_ASSUME_NONNULL_END

//
//  BJLMessageCell.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-02.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import "BJLMessageCell.h"

#import "BJLViewImports.h"
#import "UITextView+BJLAttributeTapAction.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const BJLMessageDefaultIdentifier = @"default";
static NSString * const BJLMessageEmoticonIdentifier = @"emoticon";
static NSString * const BJLMessageImageIdentifier = @"image";
static NSString * const BJLMessageUploadingImageIdentifier = @"image-uploading";
static NSString * const BJLMessageTranslateIdentifier = @"translate";

// verMargins = (BJLViewSpaceM + BJLViewSpaceS + BJLViewSpaceM) + BJLViewSpaceS
static const CGFloat verMargins = (10.0 + 5.0 + 10.0) + 5.0; // last 5.0: bgView.top+bottom

static const CGFloat fontSize = 14.0;
static const CGFloat oneLineMessageCellHeight = fontSize + verMargins;

static const CGFloat emoticonSize = 32.0;
static const CGFloat emoticonMessageCellHeight = emoticonSize + verMargins;

static const CGFloat imageMinWidth = 50.0, imageMinHeight = 50.0;
static const CGFloat imageMaxWidth = 100.0, imageMaxHeight = 100.0;
static const CGFloat imageMessageCellMinHeight = imageMinHeight + verMargins;

@interface BJLMessageCell () <UITextViewDelegate, BJLAttributeTapActionDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UITextView *textView;
@property (nonatomic, readwrite) UIImageView *imgView;
@property (nonatomic) UIView *imgProgressView;
@property (nonatomic) BJLConstraint *imgProgressViewHeightConstraint;
@property (nonatomic) UIButton *failedBadgeButton;
@property (nonatomic) UIView *bgView;

@property (nonatomic) BJLChatStatus chatStatus;
@property (nonatomic) CGFloat tableViewWidth;
@property (nonatomic) NSRange range_activeUserName;

/** 英汉互译*/
@property (nonatomic) UIView *translationSepratorline;
@property (nonatomic) UITextView *translationTextView;

@end

@implementation BJLMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setUpSubviews];
        [self setUpConstraints];
        [self prepareForReuse];
    }
    return self;
}

#pragma mark - subviews

- (void)setUpSubviews {
    self.backgroundColor = [UIColor clearColor];
    
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.bgView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.cornerRadius = 5;
        view.layer.masksToBounds = YES;
        [self.contentView addSubview:view];
        view;
    });
    
    self.textView = ({
        UITextView *textView = [UITextView new];
        textView.textAlignment = NSTextAlignmentLeft;
        // textView.font = [UIFont systemFontOfSize:fontSize];
        // textView.textColor = [UIColor blackColor];
        {
            textView.textContainerInset = UIEdgeInsetsZero;
            textView.textContainer.lineFragmentPadding = 0;
            // textView.textContainer.maximumNumberOfLines = 0;
            // textView.dataDetectorTypes = UIDataDetectorTypeAll;
            textView.backgroundColor = [UIColor clearColor];
            textView.selectable = YES;
            textView.editable = NO;
            textView.scrollEnabled = NO;
            textView.userInteractionEnabled = YES;
            textView.delegate = self;
        }
        [self.bgView addSubview:textView];
        textView;
    });
    
    BOOL isEmoticon = [self.reuseIdentifier isEqualToString:BJLMessageEmoticonIdentifier];
    BOOL isImage = [self.reuseIdentifier isEqualToString:BJLMessageImageIdentifier];
    BOOL isUploadingImage = [self.reuseIdentifier isEqualToString:BJLMessageUploadingImageIdentifier];
    BOOL isTranslated = [self.reuseIdentifier isEqualToString:BJLMessageTranslateIdentifier];
    if (isEmoticon || isImage || isUploadingImage) {
        self.imgView = ({
            UIImageView *imageView = [UIImageView new];
            imageView.clipsToBounds = YES;
            imageView.contentMode = (isEmoticon
                                     ? UIViewContentModeScaleAspectFit
                                     : UIViewContentModeScaleAspectFill);
            [self.bgView addSubview:imageView];
            imageView;
        });
        
        if (isUploadingImage) {
            self.imgProgressView = ({
                UIView *view = [UIView new];
                view.backgroundColor = [UIColor bjl_darkDimColor];
                [self.bgView addSubview:view];
                view;
            });
            self.failedBadgeButton = ({
                UIButton *button = [UIButton new];
                [button setTitle:@"!" forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                button.backgroundColor = [UIColor bjl_redColor];
                button.layer.cornerRadius = BJLBadgeSize / 2;
                button.layer.masksToBounds = YES;
                [self.contentView addSubview:button];
                button;
            });
            bjl_weakify(self);
            [self.failedBadgeButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
                bjl_strongify(self);
                if (self.retryUploadingCallback) self.retryUploadingCallback(self);
            }];
        }
    }
    else {
        if(isTranslated) {
            self.translationSepratorline = ({
                UIView *view = [UIView new];
                view.backgroundColor = [UIColor bjl_colorWithHex:0xD8D8D8];
                [self.bgView addSubview:view];
                view;
            });
            
            self.translationTextView = ({
                UITextView *textView = [UITextView new];
                textView.textAlignment = NSTextAlignmentLeft;
                textView.textContainerInset = UIEdgeInsetsZero;
                textView.textContainer.lineFragmentPadding = 0;
                textView.backgroundColor = [UIColor clearColor];
                textView.selectable = YES;
                textView.editable = NO;
                textView.scrollEnabled = NO;
                textView.userInteractionEnabled = YES;
                [self.bgView addSubview:textView];
                textView;
            });
        }
    }
    bjl_weakify(self);
    UILongPressGestureRecognizer *longPressGesture = [UILongPressGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if(gesture.state == UIGestureRecognizerStateBegan) {
            if (self.longPressCallback)
                self.longPressCallback(self, [gesture locationInView:self], self.imageView.image);
        }
    }];
    longPressGesture.delegate = self;
    longPressGesture.cancelsTouchesInView = YES;
    [self addGestureRecognizer:longPressGesture];
}

- (void)setUpConstraints {
    // <right>
    [self.bgView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        CGFloat spaceLeft = BJLScrollIndicatorSize, spaceBottom = 3.0, spaceTop = BJLViewSpaceS;
        make.left.top.bottom.equalTo(self.contentView).insets(UIEdgeInsetsMake(spaceTop, spaceLeft, spaceBottom, 0.0));
        // <right>
        make.right.lessThanOrEqualTo(self.contentView).with.offset((self.imgView)? - (BJLBadgeSize + BJLViewSpaceS) : 0.0);
    }];
    
    [self.textView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.equalTo(self.bgView).with.offset(BJLViewSpaceM);
        // <right>
        make.right.equalTo(self.bgView).with.offset(- BJLViewSpaceM);
        make.right.lessThanOrEqualTo(self.bgView).with.offset(- BJLViewSpaceM);
        if (self.imgView) {
            make.bottom.equalTo(self.imgView.bjl_top).with.offset(- BJLViewSpaceS);
        }
        else {
            if(self.translationTextView) {
                make.bottom.equalTo(self.translationSepratorline.bjl_top).with.offset(- BJLViewSpaceS);
            }
            else {
                make.bottom.equalTo(self.bgView).with.offset(- BJLViewSpaceM);
            }
        }
    }];
    
    if(self.translationTextView) {
        [self.translationSepratorline bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.equalTo(self.textView);
            make.height.equalTo(@(1));
            make.top.equalTo(self.textView.bjl_bottom).with.offset(BJLViewSpaceS);
        }];
        [self.translationTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.equalTo(self.textView);
            make.top.equalTo(self.translationSepratorline.bjl_bottom).with.offset(BJLViewSpaceS);
            make.bottom.equalTo(self.bgView).with.offset(- BJLViewSpaceM);
        }];
    }
    if (self.imgView) {
        [self.imgView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.textView.bjl_bottom).offset(BJLViewSpaceS);
            make.left.equalTo(self.bgView).with.offset(BJLViewSpaceM);
            make.bottom.equalTo(self.bgView).with.offset(- BJLViewSpaceM);
            make.right.lessThanOrEqualTo(self.bgView).with.offset(- BJLViewSpaceM);
            make.width.equalTo(@(imageMinWidth));
            make.height.equalTo(@(imageMinHeight)).priorityHigh();
        }];
        
        if ([self.reuseIdentifier isEqualToString:BJLMessageEmoticonIdentifier]) {
            [self updateImgViewConstraintsWithSize:CGSizeMake(emoticonSize, emoticonSize)];
        }
        // else if BJLMessageImageIdentifier || BJLMessageUploadingImageIdentifier:
        // init/reset in prepareForReuse, and update in updateCell
        
        if (self.imgProgressView) {
            [self.imgProgressView bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.left.right.bottom.equalTo(self.imgView);
                self.imgProgressViewHeightConstraint = make.height.equalTo(@0.0).constraint;
            }];
        }
        if (self.failedBadgeButton) {
            [self.failedBadgeButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.left.equalTo(self.bgView.bjl_right).with.offset(BJLViewSpaceS);
                make.centerY.equalTo(self.imgView);
                make.width.height.equalTo(@(BJLBadgeSize));
            }];
        }
    }
}

- (void)updateImgViewConstraintsWithSize:(CGSize)size {
    [self.imgView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.width.equalTo(@(size.width));
        make.height.equalTo(@(size.height)).priorityHigh();
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.textView.text = nil;
    self.textView.attributedText = nil;
    self.translationTextView.text = nil;
    self.imgView.image = nil;
    self.failedBadgeButton.hidden = YES;
}

#pragma mark - private updating

- (void)_updateLabelsWithMessage:(nullable BJLMessage *)message
                        fromUser:(BJLUser *)fromUser
                          toUser:(BJLUser *)toUser
                   fromLoginUser:(BOOL)fromLoginUser
                    isHorizontal:(BOOL)isHorizontal
                 translateResult:(nullable NSString *)translateResult
                            room:(BJLRoom *)room {
    // self.textView.textColor = isHorizontal ? [UIColor whiteColor] : [UIColor blackColor];
    self.bgView.backgroundColor = isHorizontal ? [UIColor bjl_darkDimColor] : [UIColor whiteColor];
    self.bgView.layer.borderWidth = isHorizontal ? 0.0 : BJLOnePixel;
    self.bgView.layer.borderColor = isHorizontal ? nil : [UIColor bjl_grayBorderColor].CGColor;
    
    // 重置点击事件
    [self.textView bjl_removeAllAttributeTapActions];
    
    // 是否为私聊消息
    BOOL isWisperMessage = (toUser.ID.length > 0 && ![toUser.ID isEqualToString:@"-1"]);
    NSString *tapActionString; // 可点击字样
    self.textView.attributedText = ({
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
        
        // fromUser
        NSString *fromUserName = fromLoginUser? @"我" : (fromUser.displayName.length > 0? fromUser.displayName : @"?");
        UIColor *fromUserColor = fromLoginUser? [UIColor orangeColor] : ([room.chatVM canSendPrivateMessageFromeUser:fromUser toUser:toUser]? [UIColor bjl_blueBrandColor] : [UIColor bjl_lightGrayTextColor]);
        NSAttributedString *fromAttrStr = [self createAttributeStringWithText:fromUserName color:fromUserColor];
        [string appendAttributedString:fromAttrStr];
        
        if (isWisperMessage && self.chatStatus != BJLChatStatus_private) {
            // 私聊字样
            NSAttributedString *whisperString = [self createAttributeStringWithText:@" 私聊 " color:[UIColor bjl_lightGrayTextColor]];
            [string appendAttributedString:whisperString];
            
            // toUser
            NSString *toUserName = (fromLoginUser
                                    ? (toUser.displayName.length > 0? toUser.displayName : @"?")
                                    : @"我");
            UIColor *toUserColor = (fromLoginUser
                                    ? ([room.chatVM canSendPrivateMessageFromeUser:toUser toUser:fromUser]? [UIColor bjl_blueBrandColor] : [UIColor bjl_lightGrayTextColor])
                                    : [UIColor orangeColor]);
            NSAttributedString *toAttrStr = [self createAttributeStringWithText:toUserName color:toUserColor];
            [string appendAttributedString:toAttrStr];
            
            self.range_activeUserName = (fromLoginUser
                                         ? NSMakeRange(fromAttrStr.length + whisperString.length, toAttrStr.length)
                                         : NSMakeRange(0, fromAttrStr.length));
            tapActionString = fromLoginUser ? toUserName : fromUserName;
        }
        else {
            tapActionString = fromLoginUser? nil : fromUserName;
            self.range_activeUserName = fromLoginUser? NSMakeRange(0, 0) : NSMakeRange(0, fromAttrStr.length);
        }
        
        NSString *text = message.type == BJLMessageType_text ? message.text : nil;
        NSAttributedString *textAttrStr = text.length ? [message attributedEmoticonStringWithEmoticonSize:fontSize + 4.0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],NSForegroundColorAttributeName: (isHorizontal ?  [UIColor whiteColor] : [UIColor blackColor])} cached:YES cachedKey:(isHorizontal ?  @"white" : @"black")] : [NSAttributedString new];
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [string appendAttributedString:textAttrStr];
        string;
    });
    
    if (tapActionString.length) {
        [self.textView bjl_addAttributeTapActionWithString:tapActionString range:self.range_activeUserName delegate:self];
    }
    self.textView.dataDetectorTypes = (fromUser.isTeacherOrAssistant
                                       ? UIDataDetectorTypeLink
                                       : UIDataDetectorTypeNone);
    self.textView.linkTextAttributes = @{ NSForegroundColorAttributeName: (fromUser.isTeacherOrAssistant
                                                                           ? [UIColor bjl_blueBrandColor]
                                                                           : [UIColor bjl_lightGrayTextColor]) };
    if(translateResult.length) {
        self.translationTextView.attributedText = ({
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
            NSString *text = translateResult.length ? [NSString stringWithFormat:@"%@", translateResult] : @"";
            NSMutableAttributedString *textAttrStr = [[NSMutableAttributedString alloc]
                                                      initWithString:text
                                                      attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12],
                                                                   NSForegroundColorAttributeName: (isHorizontal
                                                                                                    ? [UIColor whiteColor]
                                                                                                    : [UIColor bjl_colorWithHex:0x4A4A4A])
                                                                   }];
            [string appendAttributedString:textAttrStr];
            string;
        });
    }
}

- (NSAttributedString *)createAttributeStringWithText:(NSString *)text color:(UIColor *)color {
    return [[NSMutableAttributedString alloc] initWithString:text
                                                  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                                                               NSForegroundColorAttributeName: color}];
}

- (void)_updateImageViewWithImageOrNil:(nullable UIImage *)image size:(CGSize)size {
    self.imgView.image = image;
    [self updateImgViewConstraintsWithSize:BJLImageViewSize(image ? image.size : size, CGSizeMake(imageMinWidth, imageMinHeight), ({
        /*
        CGFloat imageMaxWidth = MAX(imageMinWidth, (self.tableViewWidth
                                                    - BJLViewSpaceM * 2
                                                    - BJLBadgeSize
                                                    - BJLViewSpaceS));
        CGFloat imageMaxHeight = MAX(imageMinHeight, imageMaxWidth / 4 * 3);
        CGSizeMake(imageMaxWidth, imageMaxHeight); */
        CGSizeMake(imageMaxWidth, imageMaxHeight);
    }))];
}

- (void)_updateImageViewWithImageURLString:(NSString *)imageURLString
                                      size:(CGSize)size
                               placeholder:(UIImage *)placeholder {
    size = (CGSizeEqualToSize(size, CGSizeZero)
            ? CGSizeMake(imageMinWidth, imageMinHeight)
            : size);
    
    [self _updateImageViewWithImageOrNil:placeholder size:size];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat maxSize = MAX(screenSize.width, screenSize.height);
    NSString *aliURLString = BJLAliIMG_aspectFit(CGSizeMake(maxSize, maxSize),
                                                 0.0,
                                                 imageURLString,
                                                 nil);
    bjl_weakify(self);
    self.imgView.backgroundColor = [UIColor bjl_grayImagePlaceholderColor];
    [self.imgView bjl_setImageWithURL:[NSURL URLWithString:aliURLString]
                          placeholder:placeholder
                           completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                               bjl_strongify(self);
                               if (image) {
                                   self.imgView.backgroundColor = [UIColor bjl_grayImagePlaceholderColor];
                               }
                               [self _updateImageViewWithImageOrNil:image size:image.size];
                               if (self.updateConstraintsCallback && !error) self.updateConstraintsCallback(self);
                           }];
}

#pragma mark - public updating

- (void)updateWithMessage:(BJLMessage *)message
              placeholder:(nullable UIImage *)placeholder
            fromLoginUser:(BOOL)fromLoginUser
               chatStatus:(BJLChatStatus)chatStatus
           tableViewWidth:(CGFloat)tableViewWidth
             isHorizontal:(BOOL)isHorizontal
                     room:(nullable BJLRoom *)room {
    self.chatStatus = chatStatus;
    self.tableViewWidth = tableViewWidth;
    
    [self _updateLabelsWithMessage:message
                          fromUser:message.fromUser
                            toUser:message.toUser
                     fromLoginUser:fromLoginUser
                      isHorizontal:isHorizontal
                   translateResult:message.translation
                              room:room];
    
    if (message.type == BJLMessageType_emoticon) {
        if (message.emoticon.cachedImage) {
            self.imgView.image = message.emoticon.cachedImage;
        }
        else {
            NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(emoticonSize, emoticonSize),
                                                      0.0,
                                                      message.emoticon.urlString,
                                                      nil);
            bjl_weakify(message);
            // self.imgView.backgroundColor = [UIColor bjl_grayImagePlaceholderColor];
            [self.imgView bjl_setImageWithURL:[NSURL URLWithString:urlString]
                                  placeholder:nil
                                   completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                                       bjl_strongify(message);
                                       if (image) {
                                           // self.imgView.backgroundColor = nil;
                                           message.emoticon.cachedImage = image;
                                       }
                                   }];
        }
    }
    else if (message.type == BJLMessageType_image) {
        [self _updateImageViewWithImageURLString:message.imageURLString
                                            size:CGSizeMake(message.imageWidth, message.imageHeight)
                                     placeholder:placeholder];
    }
}

- (void)updateWithUploadingTask:(BJLChatUploadingTask *)task
                       fromUser:(BJLUser *)fromUser
                         toUser:(BJLUser *)toUser
                     chatStatus:(BJLChatStatus)chatStatus
                 tableViewWidth:(CGFloat)tableViewWidth
                   isHorizontal:(BOOL)isHorizontal
                           room:(nullable BJLRoom *)room {
    self.chatStatus = chatStatus;
    self.tableViewWidth = tableViewWidth;
    
    [self _updateLabelsWithMessage:nil
                          fromUser:fromUser
                            toUser:toUser
                     fromLoginUser:YES
                      isHorizontal:isHorizontal
                   translateResult:nil
                              room:room];
    [self _updateImageViewWithImageOrNil:task.thumbnail size:task.thumbnail.size];
    self.failedBadgeButton.hidden = !task.error;
    
    [self.imgProgressView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        [self.imgProgressViewHeightConstraint uninstall];
        self.imgProgressViewHeightConstraint = make.height.equalTo(self.imgView).multipliedBy(1.0 - task.progress * 0.9).constraint;
    }];
}

#pragma mark -

+ (NSArray<NSString *> *)allCellIdentifiers {
    return @[ BJLMessageDefaultIdentifier,
              BJLMessageEmoticonIdentifier,
              BJLMessageImageIdentifier,
              BJLMessageUploadingImageIdentifier,
              BJLMessageTranslateIdentifier];
}

+ (NSString *)cellIdentifierForMessageType:(BJLMessageType)type hasTranslation:(BOOL)hasTranslation{
    switch (type) {
        case BJLMessageType_emoticon:
            return BJLMessageEmoticonIdentifier;
        case BJLMessageType_image:
            return BJLMessageImageIdentifier;
        default:
        {
            if(hasTranslation) {
                return BJLMessageTranslateIdentifier;
            }
            return BJLMessageDefaultIdentifier;
        }
    }
}

+ (NSString *)cellIdentifierForUploadingImage {
    return BJLMessageUploadingImageIdentifier;
}

+ (CGFloat)estimatedRowHeightForMessageType:(BJLMessageType)type {
    switch (type) {
        case BJLMessageType_emoticon:
            return emoticonMessageCellHeight;
        case BJLMessageType_image:
            return imageMessageCellMinHeight;
        default:
            return oneLineMessageCellHeight;
    }
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (characterRange.location == self.range_activeUserName.location
         && characterRange.length == self.range_activeUserName.length) {
        if (self.startPrivateChatCallback) {
            self.startPrivateChatCallback(self);
        }
        return NO;
    }
    return self.linkURLCallback(self, URL);
}

// 或者允许选择，然后在点击 BJLControlsViewController、BJLContentView 时调用 [BJLChatViewController.view endEditing:YES]
- (void)textViewDidChangeSelection:(UITextView *)textView {
    textView.selectedTextRange = nil;
}

#pragma mark - <BJLAttributeTapActionDelegate>

- (void)bjl_attributeTapReturnString:(NSString *)string range:(NSRange)range index:(NSInteger)index {
    if (range.location == self.range_activeUserName.location
        && range.length == self.range_activeUserName.length) {
        if (self.startPrivateChatCallback) {
            self.startPrivateChatCallback(self);
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end

NS_ASSUME_NONNULL_END

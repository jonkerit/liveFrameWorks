//
//  BJLScQuestionCell.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScQuestionCell.h"
#import "BJLScAppearance.h"

NSString
* const BJLScQuestionCellReuseIdentifier = @"kQuestionCellReuseIdentifier",
* const BJLScQuestionReplyCellReuseIdentifier = @"kQuestionReplyCellReuseIdentifier";

@interface BJLScQuestionCell ()

@property (nonatomic) BJLQuestion *question;
@property (nonatomic) BJLQuestionReply *reply;
@property (nonatomic) UILabel *contentLabel;

@end

@implementation BJLScQuestionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.contentLabel.attributedText = nil;
}

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor whiteColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    bjl_weakify(self);
    UILongPressGestureRecognizer *longPressGestureRecognizer = [UILongPressGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if (self.longPressCallback) {
            self.longPressCallback(self.question, self.reply, [gesture locationInView:self]);
        }
    }];
    [self addGestureRecognizer:longPressGestureRecognizer];
    UITapGestureRecognizer *singleTapGestureRecognizer = [UITapGestureRecognizer bjl_gestureWithHandler:^(UITapGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        gesture.numberOfTapsRequired = 1;
        if (self.singleTapCallback) {
            self.singleTapCallback(self.question, self.reply, [gesture locationInView:self]);
        }
    }];
    [self addGestureRecognizer:singleTapGestureRecognizer];
    [singleTapGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
    
    if ([self.reuseIdentifier isEqualToString:BJLScQuestionCellReuseIdentifier]) {
        self.contentLabel = ({
            UILabel *label = [UILabel new];
            label.numberOfLines = 0;
            label.layer.masksToBounds = YES;
            label.backgroundColor = [UIColor bjl_colorWithHexString:@"#F5F5F5" alpha:1.0];
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:12.0];
            label.textColor = [UIColor blackColor];
            label;
        });
        [self.contentView addSubview:self.contentLabel];
        CGFloat tempF = -8.0;
        if (isIPhoneXSeries()) {
            tempF = 35.0;
        }
        [self.contentLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.contentView).inset(8.0);
            make.right.equalTo(self.contentView).inset(-tempF);
            make.bottom.top.equalTo(self.contentView);
        }];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLScQuestionReplyCellReuseIdentifier]) {
        self.contentLabel = ({
            UILabel *label = [UILabel new];
            label.numberOfLines = 0;
            label.layer.masksToBounds = YES;
            label.backgroundColor = [UIColor bjl_colorWithHexString:@"#F5F5F5" alpha:1.0];
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:12.0];
            label.textColor = [UIColor blackColor];
            label;
        });
        [self.contentView addSubview:self.contentLabel];
        [self.contentLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.equalTo(self.contentView).inset(8.0);
            make.top.bottom.equalTo(self.contentView);
        }];
        
        UIView *line = ({
            UIView *view = [UIView new];
            view.backgroundColor = [UIColor bjl_colorWithHexString:@"#E0E0E0" alpha:1.0];
            view;
        });
        [self.contentLabel addSubview:line];
        [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.contentLabel);
            make.height.equalTo(@(BJLScOnePixel));
            make.left.right.equalTo(self.contentView).inset(16.0);
        }];
    }
}
static inline BOOL isIPhoneXSeries() {
     BOOL iPhoneXSeries = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return iPhoneXSeries;
    }
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
    if (mainWindow.safeAreaInsets.bottom > 0.0)
        iPhoneXSeries = YES;
    }
    return iPhoneXSeries;
}
- (void)updateWithQuestion:(nullable BJLQuestion *)question questionReply:(nullable BJLQuestionReply *)questionReply {
    self.question = question;
    self.reply = questionReply;
    if ([self.reuseIdentifier isEqualToString:BJLScQuestionCellReuseIdentifier]) {
        self.contentLabel.attributedText = [self attributedStringWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_question_title"] content:question.content contentFont:[UIFont systemFontOfSize:12.0]] ;
    }
    else if ([self.reuseIdentifier isEqualToString:BJLScQuestionReplyCellReuseIdentifier]) {
        self.contentLabel.attributedText = [self attributedStringWithImage:questionReply.publish ? [UIImage bjlsc_imageNamed:@"bjl_sc_question_reply"] : [UIImage bjlsc_imageNamed:@"bjl_sc_question_reply_unpublish"] content:questionReply.content contentFont:[UIFont systemFontOfSize:12.0]];
    }
}

- (NSAttributedString *)attributedStringWithImage:(UIImage *)image content:(NSString *)content contentFont:(UIFont *)contentFont {
    NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
    NSTextAttachment *textAttachment = [NSTextAttachment new];
    textAttachment.image = image;
    textAttachment.bounds = CGRectMake(0.0, -8.0, 24.0, 24.0);
    [attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 8.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    NSAttributedString *userName = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ ", content]
                                                                   attributes:@{NSFontAttributeName : contentFont,
                                                                                NSForegroundColorAttributeName : [UIColor bjl_darkGrayTextColor],
                                                                                NSParagraphStyleAttributeName : paragraphStyle
                                                                                }];
    [attributedString appendAttributedString:userName];
    return attributedString;
}

- (NSString *)timeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

+ (NSArray<NSString *> *)allCellIdentifiers {
    return @[BJLScQuestionCellReuseIdentifier,
             BJLScQuestionReplyCellReuseIdentifier];
}

@end


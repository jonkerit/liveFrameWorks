//
//  BJLIcPromptTableViewCell.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/7.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcPromptTableViewCell.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcPromptModel ()

@property (nonatomic, readwrite) BOOL reachMaxDuration;
@property (nonatomic, readwrite) NSString *prompt;
@property (nonatomic, readwrite) NSInteger maxDuration;
@property (nonatomic, readwrite) BOOL important;

@end

/**
 有两种消失的情况, 第一种是时间到了指定时长, 不需要显示了, 从显示的数据源中会移除这个model
 第二种可能是被点击了之后消失, 这种情况目前不从数据源中移除
 */
@implementation BJLIcPromptModel

- (instancetype)initWithPrompt:(NSString *)prompt duration:(NSInteger)duration important:(BOOL)important {
    if (self = [super init]) {
        self.prompt = prompt;
        self.maxDuration = duration;
        self.reachMaxDuration = NO;
        self.important = important;
        if (duration > 0) {
            bjl_weakify(self);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                bjl_strongify(self);
                self.reachMaxDuration = YES;
            });
        }
    }
    return self;
}

@end

@interface BJLIcPromptTableViewCell ()

@property (nonatomic, nullable) BJLIcPromptModel *promptModel;
@property (nonatomic, nullable) id<BJLObservation> promptDurationObserver;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIButton *promptButton;
@property (nonatomic) UILabel *promptLabel;

@end

@implementation BJLIcPromptTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
        [self makeObserving];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.containerView = ({
        UIView *view = [UIView new];
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.2;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
        view.layer.shadowRadius = 10.0;
        view;
    });
    [self.contentView addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView);
    }];
    
    self.promptButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(clearCell) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.containerView addSubview:self.promptButton];
    [self.promptButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset([BJLIcAppearance sharedAppearance].promptCellSmallSpace);
        make.right.equalTo(self.containerView).offset(-[BJLIcAppearance sharedAppearance].promptCellLargeSpace);
    }];
    
    self.promptLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
        label;
    });
    [self.promptButton addSubview:self.promptLabel];
    [self.promptLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.promptButton).offset(20.0);
        make.right.equalTo(self.promptButton).offset(-20.0);
        make.width.greaterThanOrEqualTo(@(216.0));
        make.top.bottom.equalTo(self.promptButton);
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self clearCell];
}

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self, promptModel)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self stopPromptDurationObserving];
             if (!!now) {
                 [self makePromptDurationObserving];
             }
             return YES;
         }];
}

- (void)makePromptDurationObserving {
    bjl_weakify(self);
    self.promptDurationObserver =  [self bjl_kvo:BJLMakeProperty(self.promptModel, reachMaxDuration)
                                        observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                                            bjl_strongify(self);
                                            if (self.promptModel.reachMaxDuration) {
                                                [self clearCell];
                                            }
                                            return YES;
                                        }];
}

- (void)stopPromptDurationObserving {
    [self.promptDurationObserver stopObserving];
    self.promptDurationObserver = nil;
}

- (void)updateWithPromptModel:(BJLIcPromptModel *)promptModel {
    if (promptModel.reachMaxDuration) {
        [self clearCell];
    }
    else if (promptModel.important) {
        self.containerView.hidden = NO;
        self.promptModel = promptModel;
        self.promptButton.userInteractionEnabled = YES;
        self.promptLabel.text = promptModel.prompt;
        self.promptButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:0.5];
    }
    else {
        self.containerView.hidden = NO;
        self.promptModel = promptModel;
        self.promptButton.userInteractionEnabled = YES;
        self.promptLabel.text = promptModel.prompt;
        self.promptButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:0.5];
    }
}

- (void)updateWithSpecialPromptModel:(BJLIcPromptModel *)promptModel {
    self.promptButton.userInteractionEnabled = NO;
    if (promptModel.reachMaxDuration) {
        [self clearCell];
    }
    else if (promptModel.important) {
        self.containerView.hidden = NO;
        self.promptModel = promptModel;
        self.promptLabel.text = promptModel.prompt;
        self.promptButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:0.5];
    }
    else {
        self.containerView.hidden = NO;
        self.promptModel = promptModel;
        self.promptLabel.text = promptModel.prompt;
        self.promptButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:0.5];
    }
}

- (void)clearCell {
    self.promptModel = nil;
    self.promptButton.userInteractionEnabled = NO;
    self.containerView.hidden = YES;
    self.promptButton.backgroundColor = [UIColor clearColor];
    self.promptLabel.text = nil;
}

@end

NS_ASSUME_NONNULL_END

//
//  BJLIcQuestionAnswerOptionCollectionViewCell.m
//  BJLiveUI
//
//  Created by fanyi on 2019/5/29.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcQuestionAnswerOptionCollectionViewCell.h"
#import "BJLIcAppearance.h"

NSString
* const BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell = @"choosen",
* const BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_right = @"right",
* const BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_wrong = @"wrong";

@interface BJLIcQuestionAnswerOptionCollectionViewCell()

@property (nonatomic) UIButton *optionButton;
@property (nonatomic) UIImageView *selectedIconImageView;
@property (nonatomic) UILabel *wrongLabel;

@end

@implementation BJLIcQuestionAnswerOptionCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        bjl_weakify(self);
        [self bjl_kvo:BJLMakeProperty(self, reuseIdentifier)
               filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                   return !!now;
               }
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 [self setUpContentView];
                 [self prepareForReuse];
                 return NO;
             }];
    }
    return self;
}

- (void)setUpContentView {
    if ([self.reuseIdentifier isEqualToString:BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell]) {
        // option button
        self.optionButton = ({
            UIButton *button = [[UIButton alloc] init];
            button.backgroundColor = [UIColor whiteColor];
            // layer
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth/2;
            
            // title
            button.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
            button.titleLabel.numberOfLines = 0;
            [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF"] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF"] forState:UIControlStateSelected];
            
            // action
            [button addTarget:self action:@selector(optionButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
            
            button;
        });
        [self.contentView addSubview:self.optionButton];
        [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.centerX.equalTo(self.contentView).offset(-1.5f);
            make.centerY.equalTo(self.contentView).offset(-1.5f);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth));
        }];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_wrong]) {
        // option button
        self.optionButton = ({
            UIButton *button = [[UIButton alloc] init];
            button.backgroundColor = [UIColor whiteColor];
            // layer
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth/2;
            
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_wrong"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_wrong_select"] forState:UIControlStateSelected];

            // action
            [button addTarget:self action:@selector(optionButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
            
            button;
        });
        [self.contentView addSubview:self.optionButton];
        [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.centerX.equalTo(self.contentView).offset(-1.5f);
            make.top.equalTo(self.contentView);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth));
        }];
        
        self.wrongLabel = ({
            UILabel *label = [UILabel new];
            label.text = @"错";
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:12];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
        [self.contentView addSubview:self.wrongLabel];
        [self.wrongLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.optionButton);
            make.top.equalTo(self.optionButton.bjl_bottom).offset(5);
            make.bottom.equalTo(self.contentView);
        }];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_right]) {
        // option button
        self.optionButton = ({
            UIButton *button = [[UIButton alloc] init];
            button.backgroundColor = [UIColor whiteColor];
            // layer
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth/2;
            
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_right"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_right_select"] forState:UIControlStateSelected];

            // action
            [button addTarget:self action:@selector(optionButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
            
            button;
        });
        [self.contentView addSubview:self.optionButton];
        [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.centerX.equalTo(self.contentView).offset(-1.5f);
            make.top.equalTo(self.contentView);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth));
        }];
        self.wrongLabel = ({
            UILabel *label = [UILabel new];
            label.text = @"对";
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:12];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
        [self.contentView addSubview:self.wrongLabel];
        [self.wrongLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.optionButton);
            make.top.equalTo(self.optionButton.bjl_bottom).offset(5);
            make.bottom.equalTo(self.contentView);
        }];
    }

    self.selectedIconImageView = ({
        UIImageView *imageView = [UIImageView new];
        [imageView setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_selected"]];
        imageView.layer.cornerRadius = 9.0f;
        imageView.clipsToBounds = YES;
        imageView.hidden = YES;
        imageView;
    });
    [self.contentView addSubview:self.selectedIconImageView];
    [self.selectedIconImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@(18));
        make.bottom.right.equalTo(self.optionButton).offset(3);
    }];
}

- (void)optionButtonOnClick:(UIButton *)button {
    // 选中状态
    BOOL selected = self.selectedIconImageView.hidden;
    [self setOptionButtonSelected:selected];

    // 回调
    if (self.optionSelectedCallback) {
        self.optionSelectedCallback(selected);
    }
}

- (void)setOptionButtonSelected:(BOOL)selected {
    self.selectedIconImageView.hidden = !selected;
}

- (void)updateContentWithOptionKey:(NSString *)optionKey isSelected:(BOOL)isSelected {
    [self.optionButton setTitle:optionKey forState:UIControlStateNormal];
    [self setOptionButtonSelected:isSelected];
}

- (void)updateContentWithSelected:(BOOL)isSelected text:(NSString *)text {
    [self setOptionButtonSelected:isSelected];
    self.wrongLabel.text = text;
}

- (void)updateContentWithOptionKey:(NSString *)optionKey isCorrect:(BOOL)isCorrect {
    [self.optionButton setTitle:optionKey forState:UIControlStateNormal];
    self.optionButton.backgroundColor = isCorrect ? [UIColor whiteColor] : [UIColor bjl_colorWithHex:0XFF1F49];
    [self.optionButton setTitleColor:isCorrect ? [UIColor bjl_colorWithHex:0X1795FF] : [UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)updateContentWithJudgOptionKey:(NSString *)optionKey isCorrect:(BOOL)isCorrect {
    self.wrongLabel.text = optionKey;
    self.optionButton.backgroundColor = isCorrect ? [UIColor whiteColor]: [UIColor bjl_colorWithHex:0XFF1F49];
    self.optionButton.selected = !isCorrect;
}

@end

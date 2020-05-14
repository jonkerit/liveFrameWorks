//
//  BJLIcQuestionAnswerPublishedOptionCollectionViewCell.m
//  BJLiveUI
//
//  Created by fanyi on 2019/6/3.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcQuestionAnswerPublishedOptionCollectionViewCell.h"
#import "BJLIcAppearance.h"

NSString
* const BJLIcQuestionAnswerPublishedOptionCollectionViewCell_ChoosenCell = @"choose",
* const BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_right = @"right",
* const BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_wrong = @"wrong";

@interface BJLIcQuestionAnswerPublishedOptionCollectionViewCell()

@property (nonatomic) UILabel *selectedTimesLabel;
@property (nonatomic) UIButton *optionButton;
@property (nonatomic) UIImageView *selectedIconImageView;

@end

@implementation BJLIcQuestionAnswerPublishedOptionCollectionViewCell

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
    
    self.selectedTimesLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"0次";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label.accessibilityLabel = BJLKeypath(self, selectedTimesLabel);
        [self.contentView addSubview:label];
        bjl_return label;
    });
    [self.selectedTimesLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.top.equalTo(self.contentView);
    }];

    if ([self.reuseIdentifier isEqualToString:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_ChoosenCell]) {
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
            
            button;
        });
        [self.contentView addSubview:self.optionButton];
        [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.selectedTimesLabel.bjl_bottom).offset(10);
            make.centerX.equalTo(self.contentView).offset(-1.5f);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth));
        }];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_wrong]) {
        // option button
        self.optionButton = ({
            UIButton *button = [[UIButton alloc] init];
            button.backgroundColor = [UIColor whiteColor];
            // layer
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth/2;
            
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_wrong"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_wrong"] forState:UIControlStateSelected];
            
            button;
        });
        [self.contentView addSubview:self.optionButton];
        [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.selectedTimesLabel.bjl_bottom).offset(10);
            make.centerX.equalTo(self.contentView).offset(-1.5f);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth));
        }];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_right]) {
        // option button
        self.optionButton = ({
            UIButton *button = [[UIButton alloc] init];
            button.backgroundColor = [UIColor whiteColor];
            // layer
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth/2;
            
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_right"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionAnswer_right"] forState:UIControlStateSelected];
            
            button;
        });
        [self.contentView addSubview:self.optionButton];
        [self.optionButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.selectedTimesLabel.bjl_bottom).offset(10);
            make.centerX.equalTo(self.contentView).offset(-1.5f);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonWidth));
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

- (void)setOptionButtonSelected:(BOOL)selected {
    self.optionButton.selected = selected;
    self.selectedIconImageView.hidden = !selected;
}

- (void)updateContentWithOptionKey:(NSString *)optionKey isSelected:(BOOL)isSelected selectedTimes:(NSInteger)times {
    self.selectedTimesLabel.text = [NSString stringWithFormat:@"%td次", times];
    [self.optionButton setTitle:optionKey forState:UIControlStateNormal];
    [self setOptionButtonSelected:isSelected];
}

- (void)updateContentWithSelected:(BOOL)isSelected selectedTimes:(NSInteger)times {
    self.selectedTimesLabel.text = [NSString stringWithFormat:@"%td次", times];
    [self setOptionButtonSelected:isSelected];
}

@end

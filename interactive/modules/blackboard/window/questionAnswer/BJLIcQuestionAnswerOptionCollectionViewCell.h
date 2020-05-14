//
//  BJLIcQuestionAnswerOptionCollectionViewCell.h
//  BJLiveUI
//
//  Created by fanyi on 2019/5/29.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell,
* const BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_right,
* const BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_wrong;

/** 答题器选项 */
@interface BJLIcQuestionAnswerOptionCollectionViewCell : UICollectionViewCell

@property (nonatomic, copy, nullable) void (^optionSelectedCallback)(BOOL selected);

//作答时，更新cell
- (void)updateContentWithOptionKey:(NSString *)optionKey isSelected:(BOOL)isSelected;

- (void)updateContentWithSelected:(BOOL)isSelected text:(NSString *)text;

// 展示选择结果时，更新cell
- (void)updateContentWithOptionKey:(NSString *)optionKey isCorrect:(BOOL)isCorrect;

- (void)updateContentWithJudgOptionKey:(NSString *)optionKey isCorrect:(BOOL)isCorrect;
@end

NS_ASSUME_NONNULL_END

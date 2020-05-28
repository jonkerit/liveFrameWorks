//
//  BJLIcQuestionAnswerPublishedOptionCollectionViewCell.h
//  BJLiveUI
//
//  Created by fanyi on 2019/6/3.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLIcQuestionAnswerPublishedOptionCollectionViewCell_ChoosenCell,
* const BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_right,
* const BJLIcQuestionAnswerPublishedOptionCollectionViewCell_JudgeCell_wrong;

@interface BJLIcQuestionAnswerPublishedOptionCollectionViewCell : UICollectionViewCell

- (void)updateContentWithOptionKey:(NSString *)optionKey isSelected:(BOOL)isSelected selectedTimes:(NSInteger)times;

- (void)updateContentWithSelected:(BOOL)isSelected selectedTimes:(NSInteger)times;

@end

NS_ASSUME_NONNULL_END

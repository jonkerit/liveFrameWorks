//
//  BJLScAnswerSheetCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScAnswerSheetCell : UICollectionViewCell

@property (nonatomic, copy, nullable) void (^optionSelectedCallback)(BOOL selected);

// 选择题
- (void)updateContentWithOptionKey:(NSString *)optionKey isSelected:(BOOL)isSelected;

// 判断题
- (void)updateContentWithSelectedKey:(NSString *)optionKey isCorrect:(BOOL)isCorrect;

@end

NS_ASSUME_NONNULL_END

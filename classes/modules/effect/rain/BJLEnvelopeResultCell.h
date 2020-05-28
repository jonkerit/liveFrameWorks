//
//  BJLEnvelopeResultCell.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const BJLEnvelopeResultCellReuseIdentifier;

@interface BJLEnvelopeResultCell : UITableViewCell

- (void)configureWithRank:(NSInteger)rank userName:(nullable NSString *)userName score:(NSInteger)score;

@end

NS_ASSUME_NONNULL_END

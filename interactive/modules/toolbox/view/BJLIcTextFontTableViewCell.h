//
//  BJLIcTextFontTableViewCell.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/12.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcTextFontTableViewCell : UITableViewCell

@property (nonatomic, nullable, copy) void (^selectCallback)(BOOL selected);

- (void)updateContentWithFont:(NSInteger)font selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END

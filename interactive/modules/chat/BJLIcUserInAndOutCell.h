//
//  BJLIcUserInAndOutCell.h
//  BJLiveUI
//
//  Created by fanyi on 2019/9/9.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJLUserInAndOutMessage.h"

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString
* const BJLIcUserInAndOutCellReuseIdentifier,
* const BJLIcUserInAndOutWithTimeCellReuseIdentifier;

@interface BJLIcUserInAndOutCell : UITableViewCell

- (void)updateWithMessage:(BJLUserInAndOutMessage *)message cellWidth:(CGFloat)cellWidth;
+ (NSArray<NSString *> *)allCellIdentifiers;

@end

NS_ASSUME_NONNULL_END

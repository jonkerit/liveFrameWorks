//
//  BJLIcToolboxOptionCell.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/10/29.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolboxOptionCell : UICollectionViewCell

@property (nonatomic) BOOL showSelectBorder;
@property (nonatomic, nullable, copy) void (^selectCallback)(BOOL selected);

- (void)updateContentWithOptionIcon:(UIImage *)icon
                       selectedIcon:(UIImage * _Nullable)selectedIcon
                        description:(NSString * _Nullable)description
                         isSelected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END

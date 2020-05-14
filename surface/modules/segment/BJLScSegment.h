//
//  BJLScSegment.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScSegment : UIView

@property (nonatomic) NSInteger selectedIndex;

- (instancetype)initWithItems:(NSArray<NSString *> *)items width:(CGFloat)width fontSize:(CGFloat)fontSize textColor:(UIColor *)textColor;
- (void)setTitle:(nullable NSString *)title forSegmentAtIndex:(NSInteger)index;
- (void)setImage:(nullable UIImage *)image forSegmentAtIndex:(NSInteger)index;
- (void)updateRedDotAtIndex:(NSInteger)index count:(NSInteger)count ignoreCount:(BOOL)ignoreCount;

@end

NS_ASSUME_NONNULL_END

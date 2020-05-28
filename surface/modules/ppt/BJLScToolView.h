//
//  BJLScToolView.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScToolView : UIView

- (instancetype)initWithRoom:(BJLRoom *)room;

@property (nonatomic, nullable) void (^hiddenCallback)(BOOL hidden);
@property (nonatomic, nullable) void (^penCallback)(void);
@property (nonatomic, nullable) void (^clearDrawingCallback)(void);
@property (nonatomic, nullable) void (^showCoursewareCallback)(void);
@property (nonatomic, nullable) void (^openCountDownCallback)(void);
@property (nonatomic, nullable) void (^remakeConstraintsCallback)(void);

- (CGSize)expectedSize;

@end

NS_ASSUME_NONNULL_END

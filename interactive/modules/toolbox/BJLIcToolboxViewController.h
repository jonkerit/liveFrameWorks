//
//  BJLIcToolboxViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/25.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

typedef NS_ENUM(NSInteger, BJLIcToolboxLayoutType) {
    BJLIcToolboxLayoutNormal,
    BJLIcToolboxLayoutMaximized,
    BJLIcToolboxLayoutFullScreen,
};

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolboxViewController : UIViewController

/**
 toolbox 当前布局 type, 布局根据设置的 type 改变
 */
@property (nonatomic, readonly) BJLIcToolboxLayoutType type;

/**
 请求参考视图
 */
@property (nonatomic, nullable) UIView *(^requestReferenceViewCallback)(void);

/**
 显示错误信息
 */
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);

/**
 课件
 */
@property (nonatomic, readonly) UIButton *coursewareButton;

/**
 老师教具
 */
@property (nonatomic, readonly) UIButton *teachingAidButton;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

/**
 取消当前选中的 button 
 */
- (void)cancelCurrentSelectedButton;

/**
 重新布局
 */
- (void)remakeToolboxConstraintsWithLayoutType:(BJLIcToolboxLayoutType)type;

@end

NS_ASSUME_NONNULL_END

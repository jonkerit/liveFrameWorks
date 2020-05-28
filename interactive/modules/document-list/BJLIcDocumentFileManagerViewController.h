//
//  BJLIcDocumentFileManagerViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcDocumentFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileManagerViewController : UIViewController

/** 隐藏文档视图 block */
@property (nonatomic, nullable) void (^hideCallback)(void);

/** 显示错误信息 */
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);

/** 选中某个远端文档, 仅在文档状态是 normal 时回调 */
@property (nonatomic, nullable) void (^selectDocumentFileCallback)(BJLIcDocumentFile *documentFile, UIImage * _Nullable image);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

//
//  BJLIcDocumentFileDisplayListView.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/27.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcDocumentFile.h"

typedef NS_ENUM(NSInteger, BJLIcDocumentFileDisplayLayoutType) {
    BJLIcDocumentFileDisplayLayoutTypeLayoutNormal,
    BJLIcDocumentFileDisplayLayoutTypeLayoutMaximized,
    BJLIcDocumentFileDisplayLayoutTypeLayoutFullScreen,
};

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileDisplayListView : BJLHitTestView

/**
 文档列表当前显示布局类型，与 toolbox 的类型一一对应
 */
@property (nonatomic, readonly) BJLIcDocumentFileDisplayLayoutType type;

/**
 选中文档的回调
 */
@property (nonatomic, nullable) void (^selectDocumentFileCallback)(BJLIcDocumentFile *documentFile);

/**
 userVideoDownside 选中文档
 */
@property (nonatomic, nullable) void (^selectDocumentCallback)(BJLDocument *document, NSInteger index);

/**
 userVideoDownside 上传文档
 */
@property (nonatomic, nullable) void (^uploadDocumentCallback)(void);

/**
 初始化文档侧边栏

 @param room BJLRoom 对于多文档，目前不关心 room，每次根据外界数据更新列表，对于单文档，直接根据 room 的文档数据刷新
 @param singleDisplay 是否是单文档
 @return self
 */
- (instancetype)initWithRoom:(nullable BJLRoom *)room singleDisplay:(BOOL)singleDisplay;

/**
 更新文档列表

 @param documentFileList 文档列表
 @param type 文档列表显示类型
 */
- (void)updateWithDocumentFileList:(NSArray<BJLIcDocumentFile *> *)documentFileList layoutType:(BJLIcDocumentFileDisplayLayoutType)type;

/**
 userVideoDownside 显示侧边栏
 */
- (void)showContainerView;

/**
 userVideoDownside 隐藏侧边栏
 */
- (void)hideContainerView;

@end

NS_ASSUME_NONNULL_END

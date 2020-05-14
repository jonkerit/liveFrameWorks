//
//  BJLIcDocumentFileView.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileView : UIView

/**
 关闭课件管理视图
 */
@property (nonatomic, readonly) UIButton *closeButton;

/**
 添加动效课件按钮
 */
@property (nonatomic, readonly) UIButton *addAnimatedDocumentFileButton;

/**
 添加普通课件按钮
 */
@property (nonatomic, readonly) UIButton *addNormalDocumentFileButton;

/**
 文档集合视图
 */
@property (nonatomic, readonly) UICollectionView *collectionView;

/**
 文档编辑按钮
 */
@property (nonatomic, readonly) UIButton *editDocumentFileButton;

/**
 删除选中的文档按钮
 */
@property (nonatomic, readonly) UIButton *deleteDocumentFileButton;

/**
 取消文档编辑状态的按钮
 */
@property (nonatomic, readonly) UIButton *cancelEditStateButton;

/**
 空文档视图
 */
@property (nonatomic, readonly) UIScrollView *emptyView;

/**
 空文档视图里的添加动态课件的按钮
 */
@property (nonatomic, readonly) UIButton *addAnimatedDocumentFileEmptyButton;

/**
 空文档视图里的添加普通课件的按钮
 */
@property (nonatomic, readonly) UIButton *addNormalDocumentFileEmptyButton;

/**
 更新文档视图显示

 @param hidden NO --> 不存在文档时隐藏, YES --> 存在文档时显示
 */
- (void)updateDocumentFileViewHidden:(BOOL)hidden;

/**
 更新编辑视图的显示

 @param hidden NO --> 编辑模式 YES --> 常规模式
 */
- (void)updateEditViewHidden:(BOOL)hidden;


@end

NS_ASSUME_NONNULL_END

//
//  BJLIcDocumentFileCell.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLIcDocumentFile.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kIcDocumentFileCellHeaderReuseIdentifier = @"kIcDocumentFileCellHeaderReuseIdentifier";

static NSString * const kIcDocumentFileCellReuseIdentifier = @"kIcDocumentFileCellReuseIdentifier";

@interface BJLIcDocumentFileCellHeader : UICollectionReusableView

/**
 更新title

 @param title title
 */
- (void)updateWithTitle:(nullable NSString *)title;

@end

@interface BJLIcDocumentFileCell : UICollectionViewCell

/**
 单指点击回调
 */
@property (nonatomic, nullable) void (^singleTapCallback)(BJLIcDocumentFile *documentFile, UIImage * _Nullable image);

/**
 双指点击回调
 */
@property (nonatomic, nullable) void (^doubleTapCallback)(BJLIcDocumentFile *documentFile);

/**
 更新 cell

 @param file BJLIcDocumentFile
 */
- (void)updateWithDocumentFile:(nullable BJLIcDocumentFile *)file;

/**
 显示错误提示视图
 */
- (void)showErrorView;

@end

NS_ASSUME_NONNULL_END

//
//  BJLIcDocumentPreviewCell.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/29.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BJLDocument;

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentPreviewCell : UICollectionViewCell

/**
 单指点击回调
 */
@property (nonatomic, nullable) void (^singleTapCallback)(BJLDocument * _Nullable document, NSInteger index, BOOL isAlbum);

- (void)updateWithDocument:(BJLDocument *)document;

- (void)updateImageViewBorderHidden:(BOOL)hidden;

@end

@interface BJLIcDocumentDetailPreviewCell : UICollectionViewCell

/**
 单指点击回调
 */
@property (nonatomic, nullable) void (^singleTapCallback)(BJLDocument * _Nullable document, NSInteger index, BOOL isAlbum);

- (void)updateWithDocument:(BJLDocument *)document index:(NSInteger)index;

- (void)updateImageViewBorderHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END

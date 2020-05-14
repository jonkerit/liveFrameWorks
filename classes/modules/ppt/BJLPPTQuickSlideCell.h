//
//  BJLPPTQuickSlideCell.h
//  Pods
//
//  Created by HuangJie on 2017/7/6.
//  Copyright © 2017年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLDocumentVM.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLPPTQuickSlideCell : UICollectionViewCell

@property (nonatomic, copy, nullable) void (^singleTapCallback)(void);
@property (nonatomic, copy, nullable) void (^longPressCallback)(void);
@property (nonatomic, copy, nullable) void (^deletePageCallback)(NSString *documentID, NSInteger pageIndex);

/** 根据 slidePage 更新 cell 内容*/
- (void)updateContentWithSlidePage:(BJLSlidePage *)slidePage whiteboardCount:(NSInteger)whiteboardCount imageSize:(CGSize)imageSize;
- (void)updateEditing:(BOOL)editing;

@end

NS_ASSUME_NONNULL_END

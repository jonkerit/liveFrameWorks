//
//  BJLScPPTQuickSlideCell.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScPPTQuickSlideCell : UICollectionViewCell

@property (nonatomic, copy, nullable) void (^singleTapCallback)(void);
@property (nonatomic, copy, nullable) void (^longPressCallback)(void);
@property (nonatomic, copy, nullable) void (^deletePageCallback)(NSString *documentID, NSInteger pageIndex);

/** 根据 slidePage 更新 cell 内容*/
- (void)updateContentWithSlidePage:(BJLSlidePage *)slidePage whiteboardCount:(NSInteger)whiteboardCount imageSize:(CGSize)imageSize;
- (void)updateEditing:(BOOL)editing;

@end

NS_ASSUME_NONNULL_END

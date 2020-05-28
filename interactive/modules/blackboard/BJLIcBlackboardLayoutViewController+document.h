//
//  BJLIcBlackboardLayoutViewController+document.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController (document)

- (void)makeObserverForDocument;

- (void)updateBlackboardPageNumber:(CGFloat)pageNumber;
- (void)resetDocumentWindowsWithModel:(BJLWindowUpdateModel *)updateModel;
- (void)updateDocumentWindowWithModel:(BJLWindowUpdateModel *)updateModel;

// web 文档
- (void)resetWebDocumentWindowsWithModel:(BJLWindowUpdateModel *)updateModel;
- (void)updateWebDocumentWindowWithModel:(BJLWindowUpdateModel *)updateModel;

@end

NS_ASSUME_NONNULL_END

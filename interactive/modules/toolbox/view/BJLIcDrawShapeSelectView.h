//
//  BJLIcDrawShapeSelectView.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/10/29.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLIcDrawSelectionBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDrawShapeSelectView : BJLIcDrawSelectionBaseView

- (NSString *)shapeOptionKeyWithType:(BJLDrawingShapeType)shapeType filled:(BOOL)filled;

@end

NS_ASSUME_NONNULL_END

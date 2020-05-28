//
//  BJLIcLiveStartView.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/17.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLiveStartView : UIView

@property (nonatomic, nullable) BOOL (^liveStartCallback)(void);

@end

NS_ASSUME_NONNULL_END

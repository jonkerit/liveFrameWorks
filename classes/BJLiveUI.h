//
//  BJLiveUI.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-01-19.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import "BJLOverlayViewController.h"
#import "BJLRoomViewController.h"

#if __has_include("BJLIcRoomViewController.h")
#import "BJLIcRoomViewController.h"
#endif

#if __has_include("BJLScRoomViewController.h")
#import "BJLScRoomViewController.h"
#endif
// 修改了d 
FOUNDATION_EXPORT NSString * BJLiveUIName(void);
FOUNDATION_EXPORT NSString * BJLiveUIVersion(void);

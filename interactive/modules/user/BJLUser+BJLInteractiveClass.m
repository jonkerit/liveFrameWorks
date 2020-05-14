//
//  BJLUser+BJLInteractiveClass.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/12/19.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <objc/runtime.h>
#import "BJLUser+BJLInteractiveClass.h"

@implementation BJLUser (BJLInteractiveClass)

- (BOOL)leaveSeat {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setLeaveSeat:(BOOL)leaveSeat {
    objc_setAssociatedObject(self, @selector(leaveSeat), @(leaveSeat), OBJC_ASSOCIATION_RETAIN);
}

@end

//
//  BJLIcLaserPointView.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/21.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLaserPointView : UIView

@property (nonatomic) NSString *documentID;
@property (nonatomic) NSInteger pageIndex;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)updateShapeShowSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END

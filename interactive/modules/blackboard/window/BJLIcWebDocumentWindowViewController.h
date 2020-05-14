//
//  BJLIcWebDocumentWindowViewController.h
//  BJLiveUI
//
//  Created by HuangJie on 2019/10/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWebViewWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcWebDocumentWindowViewController : BJLIcWebViewWindowViewController

@property (nonatomic, copy, nullable) void (^webDocumentWindowCloseCallback)(NSString *documentID);

- (instancetype)initWithRoom:(BJLRoom *)room webDocumentID:(NSString *)documentID;

@end

NS_ASSUME_NONNULL_END

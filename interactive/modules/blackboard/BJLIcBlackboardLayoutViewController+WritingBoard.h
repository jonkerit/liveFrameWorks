//
//  BJLIcBlackboardLayoutViewController+WritingBoard.h
//  BJLiveCore
//
//  Created by 凡义 on 2019/3/22.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController (WritingBoard)

- (void)makeObserversForWritingBoard;

- (NSString *)keyForWritingBoard:(NSString *)boardID pageIndex:(NSInteger)pageIndex userNumber:(NSString *)userNumber ;

@end

NS_ASSUME_NONNULL_END

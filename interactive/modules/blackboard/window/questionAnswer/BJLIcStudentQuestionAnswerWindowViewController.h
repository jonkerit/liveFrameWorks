//
//  BJLIcStudentQuestionAnswerWindowViewController.h
//  BJLiveUI
//
//  Created by fanyi on 2019/6/3.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

@class BJLRoom;
@class BJLAnswerSheet;

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcStudentQuestionAnswerWindowViewController : BJLIcWindowViewController

@property (nonatomic, nullable) void (^errorCallback)(NSString *message);
@property (nonatomic, nullable) BOOL (^submitCallback)(BJLAnswerSheet *answerSheet);

- (instancetype)initWithRoom:(BJLRoom *)room
               answerSheet:(BJLAnswerSheet *)answerSheet;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

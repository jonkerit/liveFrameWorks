//
//  BJLIcBlackboardLayoutViewController+question.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/5/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+question.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (teacherAid)

- (void)makeObeservingForQuestion {
    
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidExit:) observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        if (user.isTeacher && self.room.loginUser.isStudent) {
//            计时器
            if (self.countDownViewController) {
                [self.countDownViewController closeWithoutRequest];
            }
            
//            抢答器
            if (self.studentResponderViewController) {
                [self.studentResponderViewController hide];
            }
        }
        return YES;;
    }];

    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               return (old.boolValue != now.boolValue);
           }
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self.room.roomVM.liveStarted) {
                 BOOL isTeacher = self.room.loginUser.isTeacher;
                 
                 // 下课时, 结束倒计时
                 if (self.countDownViewController) {
                     [self.countDownViewController closeWithoutRequest];
                 }
                 
                 // 老师下课时, 正在抢答时, 发送抢答结束信令
                 if (self.questionResponderViewController && isTeacher) {
                     [self.questionResponderViewController closeQuestionResponder];
                 }
                 else if (self.studentResponderViewController && self.room.loginUser.isStudent) {
                     [self.studentResponderViewController hide];
                 }
                 
                 // 答题器
                 if (self.questionAnswerWindowViewController && isTeacher) {
                     [self.questionAnswerWindowViewController closeQuestionAnswer];
                 }
             }
             return YES;
         }];

    // 计时器
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUpdateCountDownTimerWithTime:open:)
             observer:(BJLMethodObserver)^BOOL(NSTimeInterval time, BOOL open) {
                 bjl_strongify(self);
                 if (!open) {// 关闭, 助教和老师可以相互收到对方的关闭信令, 所有用户都关闭
                     if (self.countDownViewController) {
                         [self.countDownViewController closeWithoutRequest];
                         self.countDownViewController = nil;
                     }
                 }
                 else {// 打开
                     if (self.countDownViewController) {
                         [self.countDownViewController closeWithoutRequest];
                         self.countDownViewController = nil;
                     }

                     if (self.room.loginUser.isTeacher) {
                         self.countDownViewController = [self displayCountDownWindowWithTime:time layout:BJLIcCountDownWindowLayout_publish];
                     }
                     // 助教
                     else if (self.room.loginUser.isAssistant) {
                         self.countDownViewController = [self displayCountDownWindowWithTime:time layout:BJLIcCountDownWindowLayout_publish];
                     }
                     else {
                         self.countDownViewController = [self displayCountDownWindowWithTime:time layout:BJLIcCountDownWindowLayout_normal];
                     }
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeCountDownTimer) observer:^BOOL{
        bjl_strongify(self);
        if (self.room.loginUser.isStudent) {
            if (self.countDownViewController) {
                [self.countDownViewController closeWithoutRequest];
                self.countDownViewController = nil;
            }
        }
        return YES;
    }];

    // 抢答器
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionResponderWithTime:)
             observer:^BOOL(NSInteger time) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isTeacherOrAssistant) {
                     if (!self.questionResponderViewController) {
                         self.questionResponderViewController = [self displayQuestionResponderWindowWithLayout:BJLIcQuestionResponderWindowLayout_publish];
                     }
                 }
                 else if (self.room.loginUser.isStudent) {
                     if (self.studentResponderViewController) {
                         [self.studentResponderViewController hide];
                         self.studentResponderViewController = nil;
                     }

                     self.studentResponderViewController = [self  displayQuestionResponderWindowWithCountDownTime:time];
                 }
                 return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveCloseQuestionResponder) observer:^BOOL {
        bjl_strongify(self);
        if(self.questionResponderViewController) {
            [self.questionResponderViewController closeWithoutRequest];
            self.questionResponderViewController = nil;
        }
        
        if(self.studentResponderViewController) {
            [self.studentResponderViewController hide];
            self.studentResponderViewController = nil;
            
            if (self.room.loginUser.isStudent) {
                self.showErrorMessageCallback(@"抢答器已被收回");
            }
        }
        return YES;
    }];
    
//    抢答器结果记录
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveEndQuestionResponderWithWinner:) observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        if (!user) {
            return YES;
        }
        
        NSMutableArray<NSDictionary *> *list = [self.questionResponderList mutableCopy];
        if (!list) {
            list = [NSMutableArray new];
        }
        
        NSUInteger onlineUserCount = 0;
        for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
            if (user.role == BJLUserRole_student) {
                onlineUserCount ++;
            }
        }

        NSDictionary *dictionary = @{
            kQuestionRecordUserKey : [[user bjlyy_modelToJSONObject] bjl_asDictionary] ?: @{},
            kQuestionRecordCountKey : @(onlineUserCount)
        };
        [list bjl_addObject:dictionary];
        self.questionResponderList = [list copy];
        return YES;
    }];

//    答题器
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionAnswerSheet:) observer:^BOOL(BJLAnswerSheet * answerSheet) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacherOrAssistant) {
            if (!self.questionAnswerWindowViewController) {
                self.questionAnswerWindowViewController = [self displayQuestionAnswerWindowWithAnswerSheet:answerSheet layout:BJLIcQuestionAnswerWindowLayout_publish];
            }            
        }
        else if (self.room.loginUser.isStudent && !self.room.loginUser.isAudition) {
            if(self.studentQuestionAnswerWindowViewController) {
                [self.studentQuestionAnswerWindowViewController closeWithoutRequest];
                self.studentQuestionAnswerWindowViewController = nil;
            }
            
            self.studentQuestionAnswerWindowViewController = [self displayQuestionAnswerWindowWithAnswerSheet:answerSheet];
        }
        return YES;
    }];
        
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveCloseQuestionAnswer) observer:^BOOL {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        
        if(self.questionAnswerWindowViewController) {
            [self.questionAnswerWindowViewController closeWithoutRequest];
            self.questionAnswerWindowViewController = nil;
        }
        
        if(self.studentQuestionAnswerWindowViewController) {
            [self.studentQuestionAnswerWindowViewController closeWithoutRequest];
            self.studentQuestionAnswerWindowViewController = nil;
            
            if (self.room.loginUser.isStudent) {
                self.showErrorMessageCallback(@"答题器已被收回");
            }
        }
        
        return YES;
    }];

}

@end

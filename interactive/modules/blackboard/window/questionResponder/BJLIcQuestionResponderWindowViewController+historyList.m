//
//  BJLIcQuestionResponderWindowViewController+historyList.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/1/19.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcQuestionResponderWindowViewController+historyList.h"
#import "BJLIcQuestionResponderWindowViewController+protected.h"
#import "BJLIcAppearance.h"

@implementation BJLIcQuestionResponderWindowViewController (historyList)

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return [self.questionResponderList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcQuestionRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([BJLIcQuestionRecordCell class]) forIndexPath:indexPath];
    
    NSDictionary *dic = [self.questionResponderList bjl_objectAtIndex:indexPath.row];
    BJLUser *user = [BJLUser bjlyy_modelWithDictionary:[dic bjl_dictionaryForKey:kQuestionRecordUserKey]];
    NSUInteger count = [dic bjl_unsignedIntegerForKey:kQuestionRecordCountKey];
    BJLUserGroup *groupInfo = nil;
    for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
        if (user.groupID == group.groupID) {
            groupInfo = group;
            break;
        }
    }

    [cell updateWithUser:user groupInfo:groupInfo participateUserCount:count];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 32.0;
}

@end

//
//  BJLIcQuestionAnswerViewController+statistics.m
//  BJLiveUI
//
//  Created by fanyi on 2019/6/4.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcQuestionAnswerViewController+statistics.h"
#import "BJLIcQuestionAnswerViewController+protected.h"

@implementation BJLIcQuestionAnswerViewController (statistics)

- (void)updateStatisticsData {
    if (self.chartView) {
        [self.chartView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    if (!self.chartView) {
        self.chartView = [BJLHitTestView new];
        [self.chartContainView addSubview:self.chartView];
        [self.chartView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.equalTo(self.statisticsLine);
            make.bottom.equalTo(self.statisticsLine.bjl_top);
            make.top.equalTo(self.chartContainView);
        }];
    }
    
    NSInteger count = [self.answerSheet.options count];
    CGFloat width = 16;
    CGFloat height = self.view.frame.size.height/2;

    CGFloat lineWidth = MAX((self.view.frame.size.width - 10-90-10-10-80-10), 0);
    
    CGFloat gap = MAX((lineWidth - width * count)/(count + 1), 0);
    for (NSInteger i = 0 ; i < count; i++) {
        
        BJLAnswerSheetOption *option = [self.answerSheet.options objectAtIndex:i];
        CGFloat rate =  MIN(self.answerSheet.userCountSubmit > 0 ? (CGFloat)option.choosenTimes / self.answerSheet.userCountSubmit : 0, 1);
        
        UIView *view = [UIView new];
        view.backgroundColor =  [UIColor bjl_colorWithHex:0X1795FF];
        
        [self.chartView addSubview:view];
        [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.chartView.bjl_left).offset(width * i + gap * (i+1));
            make.width.equalTo(@(width));
            make.height.equalTo(@(rate * height));
            make.bottom.equalTo(self.chartView);
        }];
        UILabel *rateLabel = [UILabel new];
        rateLabel.text = [NSString stringWithFormat:@"%.1f%%", rate * 100];
        rateLabel.textColor = [UIColor whiteColor];
        rateLabel.font = [UIFont boldSystemFontOfSize:12];
        [self.chartView addSubview:rateLabel];
        [rateLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(view);
            make.height.equalTo(@(20));
            make.bottom.equalTo(view.bjl_top);
        }];

        UILabel *label = [UILabel new];
        label.text = option.key;
        label.textColor = option.isAnswer ? [UIColor bjl_colorWithHex:0X1795FF] : [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:14];
        [self.chartView addSubview:label];

        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(view);
            make.top.equalTo(self.chartView.bjl_bottom);
        }];
    }
}

- (void)makeObservingForAnswerDetailList {
    /* 在线用户 */
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             NSArray<BJLUser *> *onlineUserList = [self.room.onlineUsersVM.onlineUsers copy];
             NSMutableArray<BJLUser *> *mutOnlineUserList = [onlineUserList mutableCopy];
             [onlineUserList enumerateObjectsUsingBlock:^(BJLUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                 if (obj && obj.role != BJLUserRole_student) {
                     [mutOnlineUserList bjl_removeObject:obj];
                 }
             }];
             
             self.onlineUserList = mutOnlineUserList;
             if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden
                 || self.detailTableView.hidden || self.correctAnswerLabel.hidden
                 || !self.detailTableView.superview) {
                 return YES;
             }
             [self.detailTableView reloadData];
             return YES;
         }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.dragging && !scrollView.decelerating) {
        return;
    }
    if (self.room.onlineUsersVM.hasMoreOnlineUsers
        && [self atTheBottomOfTableView]
        && !self.detailTableView.hidden) {
        [self.room.onlineUsersVM loadMoreOnlineUsersWithCount:20];
    }
}

- (BOOL)atTheBottomOfTableView {
    UITableView *tableView = self.detailTableView;

    CGFloat contentOffsetY = tableView.contentOffset.y;
    CGFloat bottom = tableView.contentInset.bottom;
    CGFloat viewHeight = CGRectGetHeight(tableView.frame);
    CGFloat contentHeight = tableView.contentSize.height;
    CGFloat bottomOffset = contentOffsetY + viewHeight - bottom - contentHeight;
    return bottomOffset >= 0.0 - 30;
}

@end

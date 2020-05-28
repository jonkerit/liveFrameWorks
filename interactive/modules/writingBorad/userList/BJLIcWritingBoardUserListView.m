//
//  BJLIcWritingBoardUserListView.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcWritingBoardUserListView.h"
#import "BJLIcWritingBoardUserTableViewCell.h"

#import "BJLIcAppearance.h"

NSString *const BJLIcWritingBoardUserTableViewCellIdentifier = @"BJLIcWritingBoardUserTableViewCell";

@interface BJLIcWritingBoardUserListView ()

@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic, readwrite) UITableView *tableView;
@property (nonatomic, readwrite) UIButton *closeButton;

@end

@implementation BJLIcWritingBoardUserListView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        [self makeSubviews];
    }
    return self;
}

- (void)makeSubviews {
//    self.hitTestBlock = ^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
//        if ([hitView isKindOfClass:[UIButton class]]) {
//            return hitView;
//        }
//        
//        UITableViewCell *cell = [hitView bjl_closestViewOfClass:[UITableViewCell class] includeSelf:NO];
//        if (cell && hitView != cell.contentView) {
//            return hitView;
//        }
//        return nil;
//    };
    
    self.tableView = ({
        UITableView *tableView = [UITableView new];
        tableView.estimatedRowHeight = 30;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.accessibilityLabel = BJLKeypath(self, tableView);
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        [tableView registerClass:[BJLIcWritingBoardUserTableViewCell class] forCellReuseIdentifier:BJLIcWritingBoardUserTableViewCellIdentifier];
        bjl_return tableView;
    });
    
    self.closeButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, closeButton);
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_ic_writingboard_closeUser"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(closeList) forControlEvents:UIControlEventTouchUpInside];
        bjl_return button;
    });

    [self addSubview:self.tableView];
    [self addSubview:self.closeButton];
    
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.left.equalTo(self);
    }];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.right.equalTo(self);
        make.width.equalTo(@(24));
        make.left.equalTo(self.tableView.bjl_right);
    }];
}

- (void)closeList {
    if(self.closeListCallBack) {
        self.closeListCallBack();
    }
}

@end

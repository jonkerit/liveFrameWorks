//
//  BJLIcExpress.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/8/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcExpress.h"

@implementation BJLIcExpress

+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
             BJLInstanceKeypath(BJLIcExpress, userName):               @[@"user_name", @"userName"],
             BJLInstanceKeypath(BJLIcExpress, userNumber):             @[@"user_number", @"userNumber"],
             BJLInstanceKeypath(BJLIcExpress, expressDescription):     @[@"exp_desc", @"expDesc"],
             BJLInstanceKeypath(BJLIcExpress, urlString):              @[@"exp_url", @"expUrl", @"expURL"],
             BJLInstanceKeypath(BJLIcExpress, type):                   @[@"exp_type", @"expType"],
             BJLInstanceKeypath(BJLIcExpress, userRole):               @[@"user_role", @"userRole", @"user_type", @"user_Type"],
             BJLInstanceKeypath(BJLIcExpress, location):               @[@"location"],
             };
}

@end

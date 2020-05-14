//
//  BJLIcExpress.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/8/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcExpress : NSObject<BJLYYModel>

@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *userNumber;
@property (nonatomic) BJLUserRole userRole;
@property (nonatomic) NSString *urlString;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *expressDescription;
@property (nonatomic) NSDictionary *location;

@end

NS_ASSUME_NONNULL_END

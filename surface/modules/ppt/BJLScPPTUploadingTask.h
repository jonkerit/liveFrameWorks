//
//  BJLScPPTUploadingTask.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLUploadingTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScPPTUploadingTask : BJLUploadingTask

@property (nonatomic, readonly, nullable) BJLDocument *result;

+ (instancetype)uploadingTaskWithImageFile:(ICLImageFile *)imageFile room:(BJLRoom *)room;

@end

NS_ASSUME_NONNULL_END

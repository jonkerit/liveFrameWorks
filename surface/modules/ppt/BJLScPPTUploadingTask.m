//
//  BJLScPPTUploadingTask.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScPPTUploadingTask.h"

@interface BJLScPPTUploadingTask ()

@property (nonatomic, readonly, weak) BJLRoom *room;

@end

@implementation BJLScPPTUploadingTask

@dynamic result;

+ (instancetype)uploadingTaskWithImageFile:(ICLImageFile *)imageFile room:(BJLRoom *)room {
    NSParameterAssert(room);
    
    BJLScPPTUploadingTask *task = [super uploadingTaskWithImageFile:imageFile];
    task->_room = room;
    return task;
}

- (nullable NSURLSessionUploadTask *)uploadImageFile:(NSURL *)fileURL
                                            progress:(nullable void (^)(CGFloat progress))progress
                                              finish:(void (^)(id _Nullable result, BJLError * _Nullable error))finish {
    return [self.room.documentVM uploadImageFile:fileURL
                                        progress:progress
                                          finish:finish];
}

@end

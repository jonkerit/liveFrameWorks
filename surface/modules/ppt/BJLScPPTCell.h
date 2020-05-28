//
//  BJLScPPTCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJLScPPTUploadingTask.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const BJLScPPTCellIdentifier_uploading, * const BJLScPPTCellIdentifier_document;

@interface BJLScPPTCell : UITableViewCell

- (void)updateWithUploadingTask:(BJLScPPTUploadingTask *)uploadingTask;
- (void)updateWithDocument:(BJLDocument *)document;

@end

NS_ASSUME_NONNULL_END

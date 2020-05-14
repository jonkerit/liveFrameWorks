//
//  BJLIcWritingBoardCollectionViewCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/31.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BJLiveCore/BJLWritingBoard.h>

NS_ASSUME_NONNULL_BEGIN

@class BJLRoom;

@interface BJLIcWritingBoardCollectionViewCell : UICollectionViewCell

- (void)setupWithRoom:(BJLRoom *)room
         writingBoard:(BJLWritingBoard *)writingBoard;

- (void)updateBrushViewWithUserNumber:(NSString *)UserNumber;

- (void)clearShapes;

- (void)updateUserInteractionEnabled:(BOOL)userInteractionEnabled;

@end

NS_ASSUME_NONNULL_END

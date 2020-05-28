//
//  BJLIcWritingBoradWindowViewController+collectionView.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/4/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWritingBoradWindowViewController+collectionView.h"
#import "BJLIcWritingBoradWindowViewController+protected.h"
#import "BJLIcWritingBoardCollectionViewCell.h"

@implementation BJLIcWritingBoradWindowViewController (collectionView)

#pragma mark - collectionview

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return BJLIcWritingboradUserlistSection_count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case BJLIcWritingboradUserlistSection_loginUser:
            return  self.hasTeacher ? 1 : 0;
        case BJLIcWritingboradUserlistSection_activeUser:
            return [self.activeParticipatedUsers count];
        case BJLIcWritingboradUserlistSection_normal:
            return [self.normalParticipatedUsers count];
        default:
            return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcWritingBoardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell setupWithRoom:self.room writingBoard:self.writingBoard];
    
    BJLUser *user = [self getUserForIndexPath:indexPath];
    if([user.number isEqualToString:self.room.loginUser.number] && self.room.loginUser.isTeacher) {
        [cell updateBrushViewWithUserNumber:BJLWritingboardUserNumberForTeacher];
    }
    else {
        [cell updateBrushViewWithUserNumber:user.number];
    }
    [cell updateUserInteractionEnabled:!(self.room.loginUser.isTeacher && self.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished)];
    return cell;
}

#pragma mark - <UICollectionViewDelegateFlowlayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 这里返回collectionView的bounds，因为存在self.view的bounds不正确的情况
    return self.collectionView.bounds.size;
}

@end

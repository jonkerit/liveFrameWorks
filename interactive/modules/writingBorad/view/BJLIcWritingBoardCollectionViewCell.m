//
//  BJLIcWritingBoardCollectionViewCell.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/31.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLRoom.h>

#import "BJLIcWritingBoardCollectionViewCell.h"
#import "BJLIcAppearance.h"

@interface BJLIcWritingBoardCollectionViewCell()

@property (nonatomic) UIViewController<BJLWritingBoardUI> *writingBoradViewController;

@end

@implementation BJLIcWritingBoardCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        
    }
    return self;
}

- (void)setupWithRoom:(BJLRoom *)room
         writingBoard:(BJLWritingBoard *)writingBoard {
    if(self.writingBoradViewController) {
        return;
    }
    
    self.writingBoradViewController = [room.documentVM writingBoardViewControllerWithWritingBoard:writingBoard];
    
    if(!self.writingBoradViewController) {
        return;
    }
    
    [self.contentView addSubview:self.writingBoradViewController.view];
    BJLConstrains_edgesEqual(self.writingBoradViewController.view, self.contentView);
}

- (void)updateBrushViewWithUserNumber:(NSString *)UserNumber {
    [self.writingBoradViewController updateShapesWithUserNumber:UserNumber];
}

- (void)clearShapes {
    [self.writingBoradViewController clearShapes];
}

- (void)updateUserInteractionEnabled:(BOOL)userInteractionEnabled {
    self.writingBoradViewController.view.userInteractionEnabled = userInteractionEnabled;
}

@end

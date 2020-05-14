//
//  BJLEmoticonCell.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-04-18.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import "BJLEmoticonCell.h"

#import "BJLViewImports.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLEmoticonCell ()

@property (nonatomic) UIImageView *imageView;

@end

@implementation BJLEmoticonCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = ({
            UIImageView *imageView = [UIImageView new];
            [self.contentView addSubview:imageView];
            [imageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.edges.equalTo(self);
            }];
            imageView;
        });
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    [self.imageView bjl_cancelCurrentImageLoading];
}

- (void)updateWithEmoticon:(BJLEmoticon *)emoticon {
    if (emoticon.cachedImage) {
        self.imageView.image = emoticon.cachedImage;
    }
    else if (emoticon) {
        [self.imageView bjl_setImageWithURL:[NSURL URLWithString:emoticon.urlString]
                                placeholder:nil
                                 completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
            if (image) {
                emoticon.cachedImage = image;
            }
        }];
    }
}

@end

NS_ASSUME_NONNULL_END

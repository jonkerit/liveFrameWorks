//
//  BJLRainNode.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(uint32_t, BJLPhysicsCategory) {
    BJLEmptyCategory       =  1 << 1,
    BJLRainCategory        =  1 << 2
};

@interface BJLRainNode : SKSpriteNode

- (instancetype)initWithImageName:(NSString *)imageName size:(CGSize)size;
- (void)setupPhysicsBodySize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END

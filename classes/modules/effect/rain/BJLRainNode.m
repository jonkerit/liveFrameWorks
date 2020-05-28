//
//  BJLRainNode.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLRainNode.h"

@implementation BJLRainNode

- (instancetype)initWithImageName:(NSString *)imageName size:(CGSize)size {
    self = [super initWithImageNamed:imageName];
    if (self) {
        self.name = [NSString stringWithFormat:@"%p-%@", self, imageName];
        self.size = size;
        [self setupPhysicsBodySize:size];
    }
    return self;
}

- (void)setupPhysicsBodySize:(CGSize)size {
    SKPhysicsBody *body = [SKPhysicsBody bodyWithRectangleOfSize:size];
    body.affectedByGravity = YES;
    body.dynamic = YES;
    body.categoryBitMask = BJLRainCategory;
    body.collisionBitMask = BJLEmptyCategory;
    body.contactTestBitMask = BJLEmptyCategory;
    body.mass = 0.2;
    body.restitution = 0.0;
    body.friction = 0.0;
    body.angularVelocity = 0.0;
    body.linearDamping = 0.0;
    body.fieldBitMask = 0;
    self.physicsBody = body;
}

@end

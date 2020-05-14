//
//  BJLRainSence.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLRainSence.h"
#import "BJLRainNode.h"
#import "BJLAppearance.h"
#import "BJLViewControllerImports.h"

static const CGFloat acceleration = 9.8; // 固定 9.8 的加速度，与物理空间加速度一致
static const CGFloat duration = 2.0; // 固定 2s 显示时长

@interface BJLRainSence () <SKPhysicsContactDelegate>

@property (nonatomic) NSInteger rainCount; // 雨水总数量
@property (nonatomic) NSString *rainImageName; // 雨水图片
@property (nonatomic) CGSize rainSize; // 雨水大小
@property (nonatomic) NSInteger preferRowCount; // 雨水每一行数量，目前设置为雨水大小之间间隔一个雨水大小，单位为 个/每秒
@property (nonatomic) NSInteger preferColumnCount; // 雨水列数量，根据总雨水数和每一行雨水数量计算，单位为 个/每秒
@property (nonatomic) CGFloat initialSpeed; // 初始速度，根据加速度和雨水显示时间计算得到，可为负数
@property (nonatomic) CGFloat accelerationDuration; // 加速或者减速到初速度所需的时间
@property (nonatomic) CGFloat accelerationDistance; // 加速或减速到初速度所需距离
@property (nonatomic) BOOL willRain; // 是否下雨，控制刷新雨水的频率
@property (nonatomic) SKNode *rainNode;
@property (nonatomic) NSMutableArray<SKTexture *> *animateTexture;

@end

@implementation BJLRainSence

+ (instancetype)senceWithSize:(CGSize)size rainImageName:(NSString *)rainImageName rainCount:(NSInteger)rainCount rainSize:(CGSize)rainSize {
    return [[self alloc] initWithSize:size rainImageName:rainImageName rainCount:rainCount rainSize:rainSize];
}

- (instancetype)initWithSize:(CGSize)size rainImageName:(NSString *)rainImageName rainCount:(NSInteger)rainCount rainSize:(CGSize)rainSize {
    if (self = [super initWithSize:size]) {
        self.rainCount = rainCount;
        self.rainImageName = rainImageName;
        self.rainSize = rainSize;
        self.totalScore = 0;
        [self prepareForSence];
    }
    return self;
}

- (void)prepareForSence {
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    self.preferRowCount = width / self.rainSize.width / 2;
    self.preferColumnCount = self.rainCount / self.preferRowCount;
    self.initialSpeed = (height - acceleration * pow(duration, 2.0)  / 2) / self.preferColumnCount; // h = 1/2 * a * t^2 + v * t;
    self.accelerationDuration = self.initialSpeed / acceleration; // t = v / a
    self.accelerationDistance = acceleration * self.accelerationDuration / 2; // y = 1/2 * a * t^2
    self.physicsWorld.gravity = CGVectorMake(0, -1); // 坐标系是数学直角坐标系，左下角为原点
    self.physicsWorld.contactDelegate = self;
    self.willRain = YES;
    
    self.backgroundColor = [SKColor clearColor];
    self.scaleMode = SKSceneScaleModeAspectFill;
    self.rainNode = [SKNode node];
    [self addChild:self.rainNode];
    [self createRainNode:self.preferRowCount];
}

- (void)update:(NSTimeInterval)currentTime {
    [self updateRainNode];
}

- (void)createRainNode:(NSUInteger)count {
    if (!self.willRain) {
        return;
    }
    self.willRain = NO;
    // 雨水掉落的间隔和每列的预计雨水数量作为雨水掉落的频率
    CGFloat frequency = duration / self.preferColumnCount;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(frequency * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.willRain = YES;
    });
    // 需要掉落的雨水数量大于每行预计的雨水数量，取一个不大于每行预计的雨水数量随机值
    if (count > self.preferRowCount) {
        NSInteger random = arc4random_uniform((uint32_t)count);
        count = MAX(0, (self.preferRowCount - random)) + self.preferRowCount / 2;
    }
    count = MIN(count, self.preferRowCount);
    for (NSInteger i = 0; i < count; i ++) {
        CGFloat x = (CGFloat)arc4random_uniform(self.size.width * 0.8) + self.size.width * 0.1; // 随机 x 轴位置
        CGFloat y = (CGFloat)arc4random_uniform(self.accelerationDistance + self.size.height) + self.size.height + self.rainSize.height / 2; // 随机 y 轴位置（为了较强随机性，初始加速距离在这种随机数下几乎可以忽略），但至少要在可视距离外初始化
        CGPoint position = CGPointMake(x, y);
        CGFloat zPosition = (CGFloat)arc4random_uniform(100) - 50.0; // 随机 z 轴位置
        BJLRainNode *rainNode = [[BJLRainNode alloc] initWithImageName:self.rainImageName size:self.rainSize];
        rainNode.position = position;
        rainNode.zPosition = zPosition;
        [self.rainNode addChild:rainNode];
    }
}

- (void)updateRainNode {
    NSMutableArray *rainToRemove = [NSMutableArray new];
    for (BJLRainNode *node in [self.rainNode.children copy]) {
        if (node.position.y < - self.rainSize.height) {
            [rainToRemove addObject:node];
        }
    }
    if (rainToRemove.count > 0) {
        [self.rainNode removeChildrenInArray:rainToRemove];
    }
    NSInteger count = self.rainCount - self.rainNode.children.count;
    if (count < 0) {
        return;
    }
    [self createRainNode:(NSUInteger)count];
}

#pragma mark - for red envelope rain

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.userInteractionEnabled) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    NSMutableArray *rainToRemove = [NSMutableArray new];
    for (BJLRainNode *node in [self.rainNode.children copy]) {
        CGRect nodeFrame = node.frame;
        if ([node containsPoint:location]) {
            [rainToRemove addObject:node];
            CGPoint center = CGPointMake(nodeFrame.origin.x + nodeFrame.size.width / 2.0, nodeFrame.origin.y + nodeFrame.size.height / 2.0);
            if (self.requestOpenEnvelopeScoreCallback) {
                bjl_weakify(self);
                self.requestOpenEnvelopeScoreCallback(^(NSInteger score) {
                    bjl_strongify(self);
                    [self showOpenEnvelopAnimation:center score:score];
                    [self storeScore:score];
                });
            }
            break; // only affect one envelope
        }
    }
    if (rainToRemove.count > 0) {
        [self.rainNode removeChildrenInArray:rainToRemove];
    }
}

- (void)storeScore:(NSInteger)score {
    self.totalScore += score;
}

- (void)setCoinImageNames:(NSMutableArray<NSString *> *)coinImageNames {
    _coinImageNames = coinImageNames;
    self.animateTexture = [NSMutableArray new];
    for (NSString *imageName in coinImageNames) {
        SKTexture *texture = [SKTexture textureWithImageNamed:imageName];
        [self.animateTexture bjl_addObject:texture];
    }
}

- (void)showOpenEnvelopAnimation:(CGPoint)center score:(NSInteger)score {
    SKSpriteNode *imageNode = [SKSpriteNode new];
    imageNode.size = CGSizeMake(200.0, 200.0);
    imageNode.position = center;
    imageNode.zPosition = 1001;
    [self addChild:imageNode];
    SKAction *imageAction = [SKAction animateWithTextures:self.animateTexture timePerFrame:0.1];
    [imageNode runAction:imageAction];
    
    SKLabelNode *labelNode = [SKLabelNode labelNodeWithText:[NSString stringWithFormat:@"+%td", score]];
    labelNode.position = center;
    labelNode.zPosition = 1001;
    labelNode.fontSize = 24.0;
    labelNode.fontName = [UIFont systemFontOfSize:24.0].fontName;
    labelNode.fontColor = [UIColor whiteColor];
    [self addChild:labelNode];
    SKAction *labelAction = [SKAction moveToY:center.y + 20.0 duration:1.0];
    [labelNode runAction:labelAction];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [labelNode removeAllActions];
        [labelNode removeFromParent];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [imageNode removeAllActions];
        [imageNode removeFromParent];
    });
}

@end

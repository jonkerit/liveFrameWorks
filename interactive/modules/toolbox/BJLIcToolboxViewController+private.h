//
//  BJLIcToolboxViewController+private.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController.h"
#import "BJLIcAppearance.h"
#import "BJLIcDrawShapeSelectView.h"
#import "BJLIcDrawStrokeWidthSelectView.h"
#import "BJLIcDrawMarkStrokeWidthSelectView.h"
#import "BJLIcDrawStrokeColorSelectView.h"
#import "BJLIcDrawTextOptionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolboxViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, readwrite) BJLIcToolboxLayoutType type;
@property (nonatomic) BOOL selectViewHidden;

@property (nonatomic) UIView *referenceViewForPhone;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *containerView;
@property (nonatomic, nullable) UIView *gestureView;
@property (nonatomic) UIView *singleLine;
@property (nonatomic, readwrite) UIButton
*emptyButton,                            // 置空状态 (暂时去掉)
*PPTButton,                              // 操作PPT，常驻选中状态
*selectButton,                           // 普通选择
*paintBrushButton,                       // 画笔
*markPenButton,                          // 马克笔
*shapeButton,                            // 形状
*laserPointerButton,                     // 激光笔
*textButton,                             // 文字
*imageButton,                            // 图片
*eraserButton,                           // 橡皮
*paletteButton,                          // 调色板
*coursewareButton,                       // 课件
*teachingAidButton,                      // 教具
*groupButton;                            // 分组

@property (nonatomic, nullable) UIButton *currentSelectedButton;

@property (nonatomic) BJLIcDrawShapeSelectView *shapeSelectView;
@property (nonatomic) BJLIcDrawStrokeWidthSelectView *strokeWidthSelectView;
@property (nonatomic) BJLIcDrawMarkStrokeWidthSelectView *markStrokeWidthSelectView;
@property (nonatomic) BJLIcDrawStrokeColorSelectView *strokeColorSelectView;
@property (nonatomic) BJLIcDrawTextOptionView *textOptionView;
@property (nonatomic) BJLDrawingShapeType currentToolboxShape;

@property (nonatomic) CGFloat doodleStrokeWidth;
@property (nonatomic) CGFloat markStrokeWidth;

- (void)setupGesture;
- (NSArray *)teacherButtons;
- (NSArray *)assistantButtons;
- (NSArray *)studentButtons;
- (NSArray *)optionButtons;

@end

NS_ASSUME_NONNULL_END

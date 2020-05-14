//
//  BJLIcToolboxViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/25.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcToolboxViewController.h"
#import "BJLIcToolboxViewController+private.h"
#import "BJLIcToolboxViewController+padUserVideoUpside.h"
#import "BJLIcToolboxViewController+phoneUserVideoUpside.h"
#import "BJLIcToolboxViewController+padUserVideoDownside.h"
#import "BJLIcToolboxViewController+phone1to1.h"
#import "BJLIcToolboxViewController+pad1to1.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcToolboxViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.doodleStrokeWidth = room.drawingVM.doodleStrokeWidth;
        self.markStrokeWidth = 8.0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    bjl_weakify(self);
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        if ([hitView isKindOfClass:[UIButton class]]
            || [hitView isKindOfClass:[UICollectionView class]]
            || [hitView isKindOfClass:[UITableView class]]
            || (hitView == self.gestureView)) {
            return hitView;
        }
        if (!self.selectViewHidden) {
            [self hideSelectViews];
            return hitView;
        }
        return nil;
    }];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    self.view.backgroundColor = [UIColor clearColor];
    self.selectViewHidden = YES;
    self.currentToolboxShape = BJLDrawingShapeType_segment;
    
    [self makeToolboxView];
    [self makeObserving];
    [self cancelCurrentSelectedButton];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    // 布局和父视图有关，因此不能在 viewdidload 中布局，需要在此方法中布局，而此方法会调用多次，需要使用 remake 来正确布局
    [super didMoveToParentViewController:parent];
    if (parent) {
        if (self.room.loginUser.isStudent) {
            [self clearToolbox];
            [self remakeToolboxConstraintsForStudent];
        }
        else if (self.room.loginUser.isTeacherOrAssistant) {
            if (BJLIcToolboxLayoutFullScreen == self.type) {
                [self clearToolbox];
                [self remakeToolboxConstraintsForStudent];
            }
            else {
                [self clearToolbox];
                [self remakeToolboxConstraintsForTeacherOrAssistant];
            }
            [self remakeSelectViewsAndConstraints];
        }
        else {
            [self clearToolbox];
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // border && corner
    if (self.backgroundView
        || (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType && BJLIcToolboxLayoutFullScreen != self.type)) {
        [self.backgroundView bjlic_drawRectCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8.0, 8.0)];
        [self.backgroundView bjlic_drawBorderWidth:1.0 borderColor:[UIColor colorWithWhite:1.0 alpha:0.1] corners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8.0, 8.0)];
    }
}

- (void)makeToolboxView {
    self.emptyButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_empty_normal"]
                                   selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_empty_selected"]
                                      needAction:YES accessibilityLabel:BJLKeypath(self, emptyButton)];
    
    self.PPTButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_empty_selected"]
                                 selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_empty_selected"]
                                    needAction:YES accessibilityLabel:BJLKeypath(self, PPTButton)];
    
    self.selectButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_select_normal"]
                                    selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_select_selected"]
                                       needAction:YES accessibilityLabel:BJLKeypath(self, selectButton)];
    
    self.paintBrushButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_paintbrush_normal"]
                                        selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_paintbrush_selected"]
                                           needAction:YES accessibilityLabel:BJLKeypath(self, paintBrushButton)];
    
    self.markPenButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_marker_normal"]
                                     selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_marker_selected"]
                                        needAction:YES accessibilityLabel:BJLKeypath(self, markPenButton)];
    
    self.shapeButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_shape_segment_normal"]
                                   selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_shape_segment_selected"]
                                      needAction:YES  accessibilityLabel:BJLKeypath(self, shapeButton)];
    
    self.laserPointerButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_laserpointer_normal"]
                                          selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_laserpointer_selected"]
                                             needAction:YES accessibilityLabel:BJLKeypath(self, laserPointerButton)];
    
    self.textButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_text_normal"]
                                  selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_text_selected"]
                                     needAction:YES accessibilityLabel:BJLKeypath(self, textButton)];
    
    self.imageButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_image_normal"]
                                   selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_image_selected"]
                                      needAction:YES accessibilityLabel:BJLKeypath(self, imageButton)];
    
    self.eraserButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_eraser_normal"]
                                    selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_eraser_selected"]
                                       needAction:YES accessibilityLabel:BJLKeypath(self, eraserButton)];
    
    self.paletteButton = [self makeButtonWithImage:nil
                                     selectedImage:nil
                                        needAction:NO accessibilityLabel:BJLKeypath(self, paletteButton)];
    [self.paletteButton addTarget:self action:@selector(updateStrokeColorSelectViewHidden) forControlEvents:UIControlEventTouchUpInside];
    
    self.singleLine = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        view.layer.masksToBounds = NO;
        // shadow
        view.layer.shadowOpacity = 0.5;
        view.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
        view.layer.shadowRadius = 10.0;
        bjl_return view;
    });
    
    self.coursewareButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_courseware_normal"]
                                        selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_courseware_selected"]
                                           needAction:YES accessibilityLabel:BJLKeypath(self, coursewareButton)];
    
    self.teachingAidButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_teachingaid_normal"]
                                         selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_teachingaid_selected"]
                                            needAction:YES accessibilityLabel:BJLKeypath(self, teachingAidButton)];
    
    self.groupButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_group_normal"]
                                   selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_group_selected"]
                                      needAction:NO accessibilityLabel:BJLKeypath(self, groupButton)];
    
    // 线宽选择
    self.strokeWidthSelectView = ({
        BJLIcDrawStrokeWidthSelectView *view = [[BJLIcDrawStrokeWidthSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 马克笔线宽选择
    self.markStrokeWidthSelectView = ({
        BJLIcDrawMarkStrokeWidthSelectView *view = [[BJLIcDrawMarkStrokeWidthSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 图形选择
    self.shapeSelectView = ({
        BJLIcDrawShapeSelectView *view = [[BJLIcDrawShapeSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 颜色选择
    self.strokeColorSelectView = ({
        BJLIcDrawStrokeColorSelectView *view = [[BJLIcDrawStrokeColorSelectView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });
    
    // 字体选择
    self.textOptionView = ({
        BJLIcDrawTextOptionView *view = [[BJLIcDrawTextOptionView alloc] initWithRoom:self.room];
        view.hidden = YES;
        bjl_return view;
    });    
}

#pragma mark - gesture

- (void)setupGesture {
    bjl_weakify(self);
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    __block CGPoint originOffsetPoint = CGPointZero;
    __block CGPoint movingTranslation = CGPointZero;
    __block CGFloat originHeight = 0;
    __block BOOL left = NO;
    CGFloat toolboxWidth = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 32.0 : [BJLIcAppearance sharedAppearance].toolboxWidth;
    UIPanGestureRecognizer *panGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIPanGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        UIView *gestureView = gesture.view;
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [gesture setTranslation:CGPointZero inView:self.view];
            originHeight = gestureView.frame.size.height;
            originOffsetPoint = CGPointMake(gestureView.frame.origin.x, gestureView.frame.origin.y);
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            if (!self.selectViewHidden) {
                [self hideSelectViews];
            }
            movingTranslation = [gesture translationInView:self.view];
            CGFloat offsetX = MAX(0, MIN(originOffsetPoint.x + movingTranslation.x, self.view.frame.size.width - toolboxWidth));
            CGFloat offsetY = MAX(0, MIN(originOffsetPoint.y + movingTranslation.y, self.view.frame.size.height - originHeight));
           
            [gestureView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.view).offset(offsetX);
                make.top.equalTo(self.view).offset(offsetY);
                make.width.equalTo(@(toolboxWidth));
                make.height.equalTo(@(originHeight));
            }];
            [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(gestureView);
            }];
            if (BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType
                || (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType && iPhone)) {
                if (offsetX < self.view.frame.size.width / 2 && left) {
                    left = NO;
                    [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_right];
                }
                else if (offsetX > self.view.frame.size.width / 2 && !left) {
                    left = YES;
                    [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_left];
                }
            }
        }
    }];

    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UITapGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        CGPoint point = [gesture locationInView:self.view];
        for (NSObject *object in [self toolboxArray]) {
            if ([object isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)object;
                if(CGRectContainsPoint(button.frame, point)) {
                    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
    }];
    [tapGesture requireGestureRecognizerToFail:panGesture];
    [self.gestureView addGestureRecognizer:tapGesture];
    [self.gestureView addGestureRecognizer:panGesture];
}

#pragma mark - update

- (void)remakeToolboxConstraintsWithLayoutType:(BJLIcToolboxLayoutType)type {
    self.type = type;
    switch (self.type) {
            // 全屏状态或者最大化状态，改变工具栏布局
        case BJLIcToolboxLayoutFullScreen:
        case BJLIcToolboxLayoutMaximized: {
            // 只有老师才会切换，学生的工具栏的样式是不变的
            if (!self.room.loginUser.isStudent) {
                // 清理工具盒
                [self clearToolbox];
                self.singleLine.hidden = YES;
                if (self.currentSelectedButton == self.laserPointerButton) {
                    [self cancelCurrentSelectedButton];
                }
                [self remakeToolboxConstraintsForStudent];
                [self remakeSelectViewsAndConstraints];
            }
            break;
        }
            // 恢复布局
        case BJLIcToolboxLayoutNormal:
            if (!self.room.loginUser.isStudent) {
                [self clearToolbox];
                self.singleLine.hidden = NO;
                [self remakeToolboxConstraintsForTeacherOrAssistant];
                [self remakeSelectViewsAndConstraints];
            }
            else {
                [self clearToolbox];
                self.singleLine.hidden = YES;
                [self remakeToolboxConstraintsForStudent];
                [self remakeSelectViewsAndConstraints];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - teacher style

- (void)remakeToolboxConstraintsForTeacherOrAssistant {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakePhone1to1ContainerViewForTeacherOrAssistant];
        }
        else {
            [self remakePad1to1ContainerViewForTeacherOrAssistant];
        }
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        // 全屏的时候 toolbox 始终在右侧
        if (BJLIcToolboxLayoutFullScreen == self.type) {
            [self remakePadUserVideoUpsideContainerViewForTeacherOrAssistant];
        }
        else {
            [self remakePadUserVideoDownsideContainerViewForTeacherOrAssistant];
        }
    }
    else {
        if (iPhone) {
            [self remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistant];
        }
        else {
            [self remakePadUserVideoUpsideContainerViewForTeacherOrAssistant];
        }
    }
}

- (NSArray *)teacherButtons {
    return @[/*self.emptyButton,*/
             self.PPTButton,
             self.selectButton,
             self.paintBrushButton,
             self.markPenButton,
             self.shapeButton,
             self.laserPointerButton,
             self.textButton,
             /*self.imageButton,*/
             self.eraserButton,
             self.paletteButton,
             self.coursewareButton,
             self.teachingAidButton
             /*self.groupButton*/];
}

- (NSArray *)assistantButtons {
    return @[/*self.emptyButton,*/
             self.PPTButton,
             self.selectButton,
             self.paintBrushButton,
             self.markPenButton,
             self.shapeButton,
             self.laserPointerButton,
             self.textButton,
             /*self.imageButton,*/
             self.eraserButton,
             self.paletteButton,
             self.coursewareButton
             /*self.teachingAidButton,
              self.groupButton*/];
}

- (NSArray *)optionButtons {
    if (self.room.loginUser.isTeacher) {
        return @[self.coursewareButton,
                 self.teachingAidButton
                  /*self.groupButton*/];
    }
    else if (self.room.loginUser.isAssistant) {
        return @[self.coursewareButton
                 /*self.teachingAidButton,
                  self.groupButton*/];
    }
    else {
        return @[];
    }
}

#pragma mark - student style

- (void)remakeToolboxConstraintsForStudent {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakePhone1to1ContainerViewForStudent];
        }
        else {
            [self remakePad1to1ContainerViewForStudent];
        }
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        // 全屏的时候 toolbox 始终在右侧
        if (BJLIcToolboxLayoutFullScreen == self.type) {
            [self remakePadUserVideoUpsideContainerViewForStudent];
        }
        else {
            [self remakePadUserVideoDownsideContainerViewForStudent];
        }
    }
    else {
        if (iPhone) {
            [self remakePhoneUserVideoUpsideContainerViewForStudent];
        }
        else {
            [self remakePadUserVideoUpsideContainerViewForStudent];
        }
    }
}

- (NSArray *)studentButtons {
    NSMutableArray *array = [NSMutableArray new];
    if (self.room.loginUser.isStudent) {
        if (self.room.documentVM.authorizedPPT) {
            [array addObjectsFromArray:[self studentPPTButtons]];
        }
        if (self.room.drawingVM.drawingGranted || self.room.drawingVM.writingBoardEnabled) {
            [array addObjectsFromArray:[self studentDrawingButtons]];
        }
    }
    else if (self.room.loginUser.isTeacherOrAssistant) {
        [array addObjectsFromArray:[self studentPPTButtons]];
        [array addObjectsFromArray:[self studentDrawingButtons]];
    }
    return array;
}

- (NSArray *)studentDrawingButtons {
    return @[/*self.emptyButton,*/
             self.selectButton,
             self.paintBrushButton,
             self.markPenButton,
             self.shapeButton,
             /*self.laserPointerButton,*/
             self.textButton,
             /*self.imageButton,*/
             self.eraserButton,
             self.paletteButton];
}

- (NSArray *)studentPPTButtons {
    return @[self.PPTButton];
}

#pragma mark - clear

- (NSArray *)toolboxArray {
    NSArray *toolboxArray = @[ self.referenceViewForPhone ?: [NSNull null],
                               self.containerView ?: [NSNull null],
                               self.backgroundView ?: [NSNull null],
                               self.emptyButton ?: [NSNull null],
                               self.PPTButton ?: [NSNull null],
                               self.selectButton ?: [NSNull null],
                               self.paintBrushButton ?: [NSNull null],
                               self.markPenButton ?: [NSNull null],
                               self.shapeButton ?: [NSNull null],
                               self.laserPointerButton ?: [NSNull null],
                               self.textButton ?: [NSNull null],
                               /*self.imageButton,*/
                               self.eraserButton ?: [NSNull null],
                               self.paletteButton ?: [NSNull null],
                               self.coursewareButton ?: [NSNull null],
                               self.singleLine ?: [NSNull null],
                               self.teachingAidButton ?: [NSNull null],
                               /*self.groupButton,*/
                               self.strokeWidthSelectView ?: [NSNull null],
                               self.markStrokeWidthSelectView ?: [NSNull null],
                               self.shapeSelectView ?: [NSNull null],
                               self.strokeColorSelectView ?: [NSNull null],
                               self.textOptionView ?: [NSNull null]];
    return toolboxArray;
}

/** 所有在remake中的视图，都需要在此清空 */
- (void)clearToolbox {
    for (UIView *view in [self toolboxArray]) {
        if ([view respondsToSelector:@selector(removeFromSuperview)]) {
            [view removeFromSuperview];
        }
    }
}

#pragma mark - select

- (void)remakeSelectViewsAndConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_left];
        }
        else {
            [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_top];
        }
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        BOOL top = (BJLIcTeacheVideoPosition_downside == self.room.roomInfo.interactiveClassTeacherVideoPosition);
        [self remakeSelectViewsAndConstraintsWithPosition:top ? BJLIcRectPosition_top : BJLIcRectPosition_bottom];
    }
    else {
        [self remakeSelectViewsAndConstraintsWithPosition:BJLIcRectPosition_left];
    }
}

#pragma mark - observers

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, strokeColor)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             UIColor *strokeColor = [UIColor bjl_colorWithHexString:self.room.drawingVM.strokeColor];
             CGSize size = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? CGSizeMake(16.0, 16.0) : CGSizeMake(24.0, 24.0);
             [self.paletteButton setImage:[UIImage bjl_imageWithColor:strokeColor size:size]
                                 forState:UIControlStateNormal];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingShapeType)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               BJLDrawingShapeType type = now.integerValue;
               switch (type) {
                   case BJLDrawingShapeType_segment:
                   case BJLDrawingShapeType_arrow:
                   case BJLDrawingShapeType_doubleSideArrow:
                   case BJLDrawingShapeType_triangle:
                   case BJLDrawingShapeType_rectangle:
                   case BJLDrawingShapeType_oval:
                   case BJLDrawingShapeType_image:
                       return YES;
                       
                   default:
                       return NO;
               }
           }
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateToolboxShape];
             return YES;
         }];
    
    // 小黑板使用中，老师取消授权画笔时，重置画笔工具状态
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, brushOperateMode)
           filter:^BJLControlObserving(NSNumber * _Nullable value, NSNumber * _Nullable oldValue, BJLPropertyChange * _Nullable change) {
//        bjl_strongify(self);
        BJLBrushOperateMode mode = value.integerValue;
        return (BJLBrushOperateMode_defaut == mode && value.integerValue != oldValue.integerValue);
    }
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self cancelCurrentSelectedButton];
        return YES;
    }];
    
//    此处主要是处理文字画笔工具再编辑时,更新画笔工具的状态
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, brushOperateMode) filter:^BJLControlObserving(NSNumber * _Nullable value, NSNumber * _Nullable oldValue, BJLPropertyChange * _Nullable change) {
            bjl_strongify(self);
            BJLBrushOperateMode mode = value.integerValue;
            return (BJLBrushOperateMode_draw == mode
                    && value.integerValue != oldValue.integerValue
                    && self.room.drawingVM.drawingShapeType ==BJLDrawingShapeType_text );
        }
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                bjl_strongify(self);
        if (self.currentSelectedButton == self.selectButton) {
            [self cancelCurrentSelectedButton];

            self.currentSelectedButton = self.textButton;
            self.currentSelectedButton.selected = YES;
        }
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, doodleStrokeWidth)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        CGFloat strokeWidth = self.room.drawingVM.doodleStrokeWidth;
        if (self.markPenButton.selected) {
            self.markStrokeWidth = strokeWidth;
        }
        else {
            self.doodleStrokeWidth = strokeWidth;
        }
        return YES;
    }];
}

#pragma mark - update toolbox shape

- (void)updateToolboxShape {
    self.currentToolboxShape = self.room.drawingVM.drawingShapeType;
    NSString *shapeKey = [self.shapeSelectView shapeOptionKeyWithType:self.currentToolboxShape filled:!!self.room.drawingVM.fillColor];
    UIImage *image = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"bjl_toolbox_%@_normal", shapeKey]];
    UIImage *selectedImage = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"bjl_toolbox_%@_selected", shapeKey]];
    [self.shapeButton setImage:image forState:UIControlStateNormal];
    [self.shapeButton setImage:selectedImage forState:UIControlStateSelected];
    [self.shapeButton setImage:selectedImage forState:UIControlStateHighlighted];
}

#pragma mark - actions

- (void)cancelCurrentSelectedButton {
    self.currentSelectedButton.selected = NO;
    self.currentSelectedButton = nil;
    // 隐藏颜色选择
    self.paletteButton.selected = NO;
    [self hideSelectViews];
    [self updateSelectViewHidden];
    //self.emptyButton.selected = YES;
    //self.currentSelectedButton = self.emptyButton;
}

- (void)didSelectButton:(UIButton *)button {
    // 如果点击当前选中的 button
    if ([button isEqual:self.currentSelectedButton]) {
        [self cancelCurrentSelectedButton];
    }
    // 点击的 button 不是当前选中的 button
    else {
        // 选中点击的 button
        self.currentSelectedButton.selected = NO;
        self.currentSelectedButton = button;
        self.currentSelectedButton.selected = YES;
    }
    
    // 画笔开关: TODO: coding style
    BOOL drawingEnabled = (self.selectButton.selected
                           || self.paintBrushButton.selected
                           || self.markPenButton.selected
                           || self.shapeButton.selected
                           || self.textButton.selected
                           || self.laserPointerButton.selected
                           || self.eraserButton.selected);
    BJLError *requestError = [self.room.drawingVM updateDrawingEnabled:drawingEnabled];
    if (self.paintBrushButton.selected) {
        // UI上虚线和涂鸦画笔互斥
        self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
        self.room.drawingVM.isDottedLine = NO;
    }
    
    // 普通画笔、马克笔线宽及透明度设置
    if (self.markPenButton.selected) {
        self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
        self.room.drawingVM.doodleStrokeWidth = self.markStrokeWidth;
        self.room.drawingVM.strokeAlpha = 0.3;
    }
    else {
        self.room.drawingVM.doodleStrokeWidth = self.doodleStrokeWidth;
        self.room.drawingVM.strokeAlpha = 1.0;
    }
    
    // 画笔模式操作模式
    BJLBrushOperateMode operateMode = BJLBrushOperateMode_defaut;
    if (drawingEnabled
        && !self.selectButton.selected
        && !self.eraserButton.selected) {
        // 添加画笔开关
        operateMode = BJLBrushOperateMode_draw;
    }
    else if (self.selectButton.selected) {
        // 画笔选择开关
        operateMode = BJLBrushOperateMode_select;
    }
    else if (self.eraserButton.selected) {
        // 橡皮擦开关
        operateMode = BJLBrushOperateMode_erase;
    }
    
    requestError = [self.room.drawingVM updateBrushOperateMode:operateMode] ?: requestError;
    
    // request 之后画笔的开关状态, writingBoardEnabled = YES 则返回有画笔权限
    drawingEnabled = self.room.drawingVM.drawingEnabled || self.room.drawingVM.writingBoardEnabled;
    // 激光笔
    if (self.laserPointerButton.selected) {
        if (drawingEnabled) {
            self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_laserPoint;
        }
    }
    else  {
        if (self.room.drawingVM.drawingShapeType == BJLDrawingShapeType_laserPoint) {
            self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
            self.room.drawingVM.isDottedLine = NO;
        }
    }
    
    // 文字
    if (self.textButton.selected) {
        if (drawingEnabled) {
            self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_text;
        }
    }
    else {
        if (self.room.drawingVM.drawingShapeType == BJLDrawingShapeType_text) {
            self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
        }
    }
    
    // 图形
    if (self.shapeButton.selected) {
        if (drawingEnabled) {
            // 设置图形
            self.room.drawingVM.drawingShapeType = self.currentToolboxShape;
        }
    }
    
    //requestError 是获取的大黑板的drawingEnabled, 如果有小黑板的画笔权限不报错
    if (requestError && !drawingEnabled) {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(requestError.localizedFailureReason);
        }
        [self cancelCurrentSelectedButton];
    }
    
    // 线宽选择
    self.strokeWidthSelectView.hidden = !self.paintBrushButton.selected;
    
    // 马克笔线宽选择
    self.markStrokeWidthSelectView.hidden = !self.markPenButton.selected;
    
    // 图形选择
    self.shapeSelectView.hidden = !self.shapeButton.selected;
    
    // 隐藏颜色选择
    self.paletteButton.selected = NO;
    self.strokeColorSelectView.hidden = YES;
    
    // 文字画笔
    self.textOptionView.hidden = !self.textButton.selected;
    
    [self updateSelectViewHidden];
}

- (void)updateStrokeColorSelectViewHidden {
    // 选择其他工具时可以进行颜色选择，隐藏其他工具选择视图
    BOOL selected = self.paletteButton.selected;
    [self hideSelectViews];
    self.paletteButton.selected = !selected;
    self.strokeColorSelectView.hidden = selected;
    [self updateSelectViewHidden];
}

- (void)updateSelectViewHidden {
    if (!self.strokeWidthSelectView.hidden ||
        !self.markStrokeWidthSelectView.hidden ||
        !self.shapeSelectView.hidden ||
        !self.strokeColorSelectView.hidden ||
        !self.textOptionView.hidden) {
        self.selectViewHidden = NO;
    }
    else {
        self.selectViewHidden = YES;
    }
}

- (void)hideSelectViews {
    self.selectViewHidden = YES;
    self.shapeSelectView.hidden = YES;
    self.strokeWidthSelectView.hidden = YES;
    self.markStrokeWidthSelectView.hidden = YES;
    self.strokeColorSelectView.hidden = YES;
    self.textOptionView.hidden = YES;
    if (self.paletteButton.isSelected) {
        self.paletteButton.selected = NO;
    }
}

#pragma mark - subviews

// position 是相对于 toolbox 的位置
- (void)remakeSelectViewsAndConstraintsWithPosition:(BJLIcRectPosition)position {
    if (self.room.loginUser.isStudent && !self.room.drawingVM.drawingGranted && !self.room.drawingVM.writingBoardEnabled) {
        return;
    }
    CGFloat optionSpacing = 6.0;
    CGFloat optionSize = 32.0;
    
    [self.view addSubview:self.strokeWidthSelectView];
    CGSize strokeWidthSelectViewSize = CGSizeMake(optionSize + optionSpacing * 2,
                                                  optionSize * 4 + optionSpacing * 5);
    [self.strokeWidthSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.paletteButton.bjl_top).offset(-1.0);
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.paintBrushButton);
                break;
                
            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.paletteButton.bjl_bottom).offset(1.0);
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.paintBrushButton);
                break;
                
            case BJLIcRectPosition_left:
                make.right.equalTo(self.backgroundView.bjl_left).offset(-1.0);
                make.top.equalTo(self.paintBrushButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            case BJLIcRectPosition_right:
                make.left.equalTo(self.backgroundView.bjl_right).offset(1.0);
                make.top.equalTo(self.paintBrushButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            default:
                break;
        }
        make.size.equal.sizeOffset(strokeWidthSelectViewSize);
    }];
    
    [self.view addSubview:self.markStrokeWidthSelectView];
    CGSize markStrokeWidthSelectViewSize = CGSizeMake(optionSize + optionSpacing * 2,
                                                      optionSize * 4 + optionSpacing * 5);
    [self.markStrokeWidthSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.markPenButton.bjl_top).offset(-1.0);
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.markPenButton);
                break;
                
            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.markPenButton.bjl_bottom).offset(1.0);
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.markPenButton);
                break;
                
            case BJLIcRectPosition_left:
                make.right.equalTo(self.backgroundView.bjl_left).offset(-1.0);
                make.top.equalTo(self.markPenButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            case BJLIcRectPosition_right:
                make.left.equalTo(self.backgroundView.bjl_right).offset(1.0);
                make.top.equalTo(self.markPenButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            default:
                break;
        }
        make.size.equal.sizeOffset(markStrokeWidthSelectViewSize);
    }];
    
    CGSize shapeSelectViewSize = CGSizeMake(optionSize * 3 + optionSpacing * 4,
                                            optionSize * 5 + optionSpacing * 6);
    [self.view addSubview:self.shapeSelectView];
    [self.shapeSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.shapeButton.bjl_top).offset(-1.0);
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.shapeButton);
                break;
                
            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.shapeButton.bjl_bottom).offset(1.0);
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.shapeButton);
                break;
                
            case BJLIcRectPosition_left:
                make.right.equalTo(self.backgroundView.bjl_left).offset(-1.0);
                make.top.equalTo(self.shapeButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            case BJLIcRectPosition_right:
                make.left.equalTo(self.backgroundView.bjl_right).offset(1.0);
                make.top.equalTo(self.shapeButton).offset(-15.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            default:
                break;
        }
        make.size.equal.sizeOffset(shapeSelectViewSize);
    }];
    
    CGSize strokeColorSelectViewSize = CGSizeMake(optionSize * 4 + 10.0 * 5,
                                                  optionSize * 4 + 10.0 * 5);
    [self.view addSubview:self.strokeColorSelectView];
    [self.strokeColorSelectView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.paletteButton.bjl_top).offset(-1.0);
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.paletteButton);
                break;
                
            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.paletteButton.bjl_bottom).offset(1.0);
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.paletteButton);
                break;
                
            case BJLIcRectPosition_left:
                make.right.equalTo(self.backgroundView.bjl_left).offset(-1.0);
                make.top.equalTo(self.paletteButton).offset(-30.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            case BJLIcRectPosition_right:
                make.left.equalTo(self.backgroundView.bjl_right).offset(1.0);
                make.top.equalTo(self.paletteButton).offset(-30.0).priorityHigh();
                make.bottom.lessThanOrEqualTo(self.view);
                break;
                
            default:
                break;
        }
        make.size.equal.sizeOffset(strokeColorSelectViewSize);
    }];
    
    [self.view addSubview:self.textOptionView];
    [self.textOptionView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        switch (position) {
            case BJLIcRectPosition_top:
                make.bottom.equalTo(self.textButton.bjl_top).offset(-1.0);
                make.top.greaterThanOrEqualTo(self.view);
                make.centerX.equalTo(self.textButton.bjl_left);
                break;
                
            case BJLIcRectPosition_bottom:
                make.top.equalTo(self.textButton.bjl_bottom).offset(1.0);
                make.bottom.lessThanOrEqualTo(self.view);
                make.centerX.equalTo(self.textButton.bjl_left);
                break;
                
            case BJLIcRectPosition_left:
                make.right.equalTo(self.backgroundView.bjl_left).offset(-1.0);
                make.top.equalTo(self.textButton).offset(-15.0).priorityMedium();
                make.top.greaterThanOrEqualTo(self.view);
                make.bottom.lessThanOrEqualTo(self.view).priorityHigh();
                break;
                
            case BJLIcRectPosition_right:
                make.left.equalTo(self.backgroundView.bjl_right).offset(1.0);
                make.top.equalTo(self.textButton).offset(-15.0).priorityMedium();
                make.top.greaterThanOrEqualTo(self.view);
                make.bottom.lessThanOrEqualTo(self.view).priorityHigh();
                break;
                
            default:
                break;
        }
        make.size.equal.sizeOffset(self.textOptionView.fitableSize);
    }];
    [self.textOptionView remarkConstraintsWithPosition:position];
}

#pragma mark - wheel

- (UIButton *)makeButtonWithImage:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage needAction:(BOOL)needAction accessibilityLabel:(NSString *)accessibilityLabel {
    // create custom button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.accessibilityLabel = accessibilityLabel;
    
    // 禁止同时点击
    button.exclusiveTouch = YES;
    
    // selected no tint color
    button.tintColor = [UIColor clearColor];
    if (needAction) {
        [button addTarget:self action:@selector(didSelectButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // use origin image
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setImage:selectedImage forState:UIControlStateHighlighted];
    
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 3.0;
    
    return button;
}

@end

NS_ASSUME_NONNULL_END

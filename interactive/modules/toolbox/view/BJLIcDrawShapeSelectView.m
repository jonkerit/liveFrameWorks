//
//  BJLIcDrawShapeSelectView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/10/29.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcDrawShapeSelectView.h"
#import "BJLIcAppearance.h"
#import "BJLIcToolboxOptionCell.h"

#define kSegment            @"segment"
#define kArrow              @"arrow"
#define kDoubleSideArrow    @"arrow_doubleSide"
#define kRectangle          @"rectangle"
#define kOval               @"oval"
#define kTriangle           @"triangle"

#define kHollow             @"_hollow"
#define kSolid              @"_solid"

#define kShapeStrokeWidth   @"strokeWidth"
#define kShapeDottedLine    @"dottedline"

static NSString * const sessionHeaderIdentifier = @"sessionHeader";

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDrawShapeSelectView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *shapeOptionsView;
@property (nonatomic) NSArray *shapeOptionKeys;
@property (nonatomic) NSArray *shapeStrokeWidths;

@property (nonatomic, nullable) NSString *currentShapeOptionKey;
@property (nonatomic) NSInteger currentWidthIndex;

// 是否为虚线
@property (nonatomic) BOOL isDotteLine;

@end

@implementation BJLIcDrawShapeSelectView

- (void)dealloc {
    self.shapeOptionsView.dataSource = nil;
    self.shapeOptionsView.delegate = nil;
}

#pragma mark - subviews

- (void)setupSubviews {
    [super setupSubviews];
    
    self.shapeOptionsView = ({
        UICollectionView *collectionView = [BJLIcDrawSelectionBaseView createSelectCollectionViewWithCellClass:[BJLIcToolboxOptionCell class]
                                                                                                   itemSpacing:6.0
                                                                                                      itemSize:CGSizeMake(32.0, 32.0)];
        
        [collectionView registerClass:[UICollectionReusableView class]
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:sessionHeaderIdentifier];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        bjl_return collectionView;
    });
    [self addSubview:self.shapeOptionsView];
    [self.shapeOptionsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(0.0, 6.0, 0.0, 6.0));
    }];
}

#pragma mark - observers

- (void)setupObservers {
    if (!self.room) {
        return;
    }
    
    bjl_weakify(self);
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.drawingVM, drawingShapeType),
                         BJLMakeProperty(self.room.drawingVM, fillColor)]
              observer:^(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  self.currentShapeOptionKey = [self shapeOptionKeyWithType:self.room.drawingVM.drawingShapeType
                                                                     filled:!!self.room.drawingVM.fillColor];
                  [self.shapeOptionsView reloadData];
              }];
    
    [self bjl_kvoMerge:@[
                         BJLMakeProperty(self.room.drawingVM, shapeStrokeWidth),
                         BJLMakeProperty(self.room.drawingVM, isDottedLine)
                         ] filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                             return now.doubleValue != old.doubleValue;
                         } observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                             bjl_strongify(self);
                             self.isDotteLine = self.room.drawingVM.isDottedLine;
                             if (self.isDotteLine) {
                                 self.currentWidthIndex = 0;
                             }
                             else {
                                 for (NSInteger index = 0; index < self.shapeStrokeWidths.count; index ++) {
                                     CGFloat strokeWidth = [[self.shapeStrokeWidths bjl_objectAtIndex:index] integerValue];
                                     if (fabs(strokeWidth - self.room.drawingVM.shapeStrokeWidth) <= FLT_MIN) {
                                         self.currentWidthIndex = index;
                                         break;
                                     }
                                 }
                             }
                             [self.shapeOptionsView reloadData];
                         }];
    

}

#pragma mark - setting

- (void)setShapeTypeWithIndex:(NSInteger)index {
    NSString *shapeOptionKey = [self.shapeOptionKeys bjl_objectAtIndex:index];
    if ([shapeOptionKey isEqualToString:self.currentShapeOptionKey]) {
        shapeOptionKey = nil;
    }
    self.currentShapeOptionKey = shapeOptionKey;
    
    BJLDrawingShapeType shapeType = BJLDrawingShapeType_doodle;
    BOOL shapeFilled = [shapeOptionKey containsString:kSolid];
    if ([shapeOptionKey containsString:kSegment]) {
        shapeType = BJLDrawingShapeType_segment;
    }
    else if ([shapeOptionKey containsString:kDoubleSideArrow]) {
        shapeType = BJLDrawingShapeType_doubleSideArrow;
    }
    else if ([shapeOptionKey containsString:kArrow]) {
        // !!!: 此判断不能写在 kDoubleSideArrow 之前
        shapeType = BJLDrawingShapeType_arrow;
    }
    else if ([shapeOptionKey containsString:kRectangle]) {
        shapeType = BJLDrawingShapeType_rectangle;
    }
    else if ([shapeOptionKey containsString:kOval]) {
        shapeType = BJLDrawingShapeType_oval;
    }
    else if ([shapeOptionKey containsString:kTriangle]) {
        shapeType = BJLDrawingShapeType_triangle;
    }
    
    self.room.drawingVM.fillColor = shapeFilled ? self.room.drawingVM.strokeColor : nil;
    self.room.drawingVM.drawingShapeType = shapeType;
    
    if (!self.room.drawingVM.drawingEnabled) {
        BJLError *error = [self.room.drawingVM updateDrawingEnabled:YES];
        if (error) {
            // TODO：显示错误信息
        }
    }
}

- (void)resetShapeType {
    self.room.drawingVM.drawingShapeType = BJLDrawingShapeType_doodle;
    self.room.drawingVM.fillColor = nil;
}

- (void)setShapeStrokeWidthWithIndex:(NSInteger)index {
    self.room.drawingVM.isDottedLine = (index == [self.shapeStrokeWidths count]);
    if (!self.room.drawingVM.isDottedLine) {
        self.room.drawingVM.shapeStrokeWidth = [[self.shapeStrokeWidths bjl_objectAtIndex:index] integerValue];
    }
    else {
        self.room.drawingVM.shapeStrokeWidth = [[self.shapeStrokeWidths bjl_objectAtIndex:0] integerValue];
    }
}

#pragma mark - <UICollectionViewDelegateFlowlayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return CGSizeMake(collectionView.frame.size.width, 1.0);
    }
    return CGSizeZero;
}

#pragma mark - <UICollectionViewDataSource>

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:sessionHeaderIdentifier forIndexPath:indexPath];
    if (indexPath.section == 1) {
        header.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        return header;
    }
    header.bounds = CGRectZero;
    return header;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return self.shapeOptionKeys.count;
    }
    else if (section == 1) {
        return self.shapeStrokeWidths.count + 1;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcToolboxOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:drawSelectionCellReuseIdentifier forIndexPath:indexPath];
    NSString *optionKey;
    BOOL selected = NO;
    if (indexPath.section == 0) {
        // 图形
        optionKey = [self.shapeOptionKeys bjl_objectAtIndex:indexPath.row];
        selected = [optionKey isEqualToString:self.currentShapeOptionKey];
    }
    else if (indexPath.section == 1) {
        // 边线宽
        NSInteger strokeWidth = 0;
        if (indexPath.row < [self.shapeStrokeWidths count]) {
            strokeWidth = [[self.shapeStrokeWidths bjl_objectAtIndex:indexPath.row] bjl_integerValue];
            optionKey = [NSString stringWithFormat:@"%@_%td", kShapeStrokeWidth, strokeWidth];
        }
        else {
            // 虚线
//            strokeWidth = [[self.shapeStrokeWidths bjl_objectAtIndex:0] bjl_integerValue];
            optionKey = kShapeDottedLine;
        }
        selected = (!self.isDotteLine && (self.currentWidthIndex == indexPath.row))
                    || (self.isDotteLine && indexPath.row == [self.shapeStrokeWidths count] && self.currentWidthIndex == 0);
    }
    
    [cell updateContentWithOptionIcon:[self optionIconWithKey:optionKey selected:YES]
                         selectedIcon:[self optionIconWithKey:optionKey selected:NO]
                          description:nil
                           isSelected:selected];
    
    bjl_weakify(self);
    [cell setSelectCallback:^(BOOL selected) {
        bjl_strongify(self);
        if (indexPath.section == 0) {
            if (selected) {
                [self setShapeTypeWithIndex:indexPath.row];
            }
            else {
//                [self resetShapeType];
            }
        }
        else if (indexPath.section == 1){
            [self setShapeStrokeWidthWithIndex:indexPath.row];
        }
    }];
    
    return cell;
}

#pragma mark - getters

- (NSArray *)shapeOptionKeys {
    if (!_shapeOptionKeys) {
        _shapeOptionKeys = @[[self shapeOptionKeyWithType:BJLDrawingShapeType_segment filled:NO],
                             [self shapeOptionKeyWithType:BJLDrawingShapeType_arrow filled:YES],
                             [self shapeOptionKeyWithType:BJLDrawingShapeType_doubleSideArrow filled:YES],
                             [self shapeOptionKeyWithType:BJLDrawingShapeType_rectangle filled:NO],
                             [self shapeOptionKeyWithType:BJLDrawingShapeType_oval filled:NO],
                             [self shapeOptionKeyWithType:BJLDrawingShapeType_triangle filled:NO],
                             [self shapeOptionKeyWithType:BJLDrawingShapeType_rectangle filled:YES],
                             [self shapeOptionKeyWithType:BJLDrawingShapeType_oval filled:YES],
                             [self shapeOptionKeyWithType:BJLDrawingShapeType_triangle filled:YES]
                             ];
    }
    return _shapeOptionKeys;
}

- (NSArray *)shapeStrokeWidths {
    if (!_shapeStrokeWidths) {
        _shapeStrokeWidths = @[@2, @4, @6];
    }
    return _shapeStrokeWidths;
}

#pragma mark - wheel

- (UIImage *)optionIconWithKey:(nullable NSString *)key selected:(BOOL)selected {
    NSString *imageName = [NSString stringWithFormat:@"bjl_toolbox_draw_%@_%@", key, selected ? @"normal" : @"selected"];
    return [UIImage bjlic_imageNamed:imageName];
}

- (NSString *)shapeOptionKeyWithType:(BJLDrawingShapeType)shapeType filled:(BOOL)filled {
    NSString *shapeTypeKey = @"";
    NSString *fillTypeKey = filled ? kSolid : kHollow;
    switch (shapeType) {
        case BJLDrawingShapeType_segment:
            shapeTypeKey = kSegment;
            fillTypeKey = @"";
            break;
            
        case BJLDrawingShapeType_arrow:
            shapeTypeKey = kArrow;
            break;
            
        case BJLDrawingShapeType_doubleSideArrow:
            shapeTypeKey = kDoubleSideArrow;
            break;
            
        case BJLDrawingShapeType_rectangle:
            shapeTypeKey = kRectangle;
            break;
            
        case BJLDrawingShapeType_oval:
            shapeTypeKey = kOval;
            break;
            
        case BJLDrawingShapeType_triangle:
            shapeTypeKey = kTriangle;
            break;
            
        default:
            fillTypeKey = @"";
            break;
    }
    
    return [NSString stringWithFormat:@"shape_%@%@", shapeTypeKey, fillTypeKey];
}

@end

NS_ASSUME_NONNULL_END

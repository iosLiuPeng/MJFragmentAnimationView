//
//  MJFragmentAnimationView.h
//  test
//
//  Created by 刘鹏i on 2018/9/13.
//  Copyright © 2018年 刘鹏. All rights reserved.
//  碎片动画视图

#import <UIKit/UIKit.h>

@interface MJFragmentAnimationView : UIView
@property (nonatomic, strong) UIImage *imgOrigin;   ///< 原图片
@property (nonatomic, assign) CGFloat xCount;       ///< 横向数量
@property (nonatomic, assign) CGFloat yCount;       ///< 纵向数量

@property (nonatomic, copy) void(^completion)(void);///< 完成回调

/**
 开始碎片动画
 
 @param arrRects 原图片的位置（需要转换为当前视图的坐标）
 */
- (void)startAnimationWithRects:(NSArray <NSValue *>*)arrRects;
@end

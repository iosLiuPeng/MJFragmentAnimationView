//
//  MJFragmentAnimationView.m
//  test
//
//  Created by 刘鹏i on 2018/9/13.
//  Copyright © 2018年 刘鹏. All rights reserved.
//

#import "MJFragmentAnimationView.h"

#define AnimationKey @"AnimationKey"

@interface MJFragmentAnimationView () <CAAnimationDelegate>
@property (nonatomic, strong) NSMutableDictionary *dictAnimation;   ///< 进行中的动画 key:animation value:view
@end

@implementation MJFragmentAnimationView
#pragma mark - Life Circle
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self viewConfig];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self viewConfig];
    }
    return self;
}

#pragma mark - Subjoin
- (void)viewConfig
{
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    
    _dictAnimation = [[NSMutableDictionary alloc] init];
}

#pragma mark - Public
/**
 开始碎片动画
 
 @param arrRects 原图片的位置（需要转换为当前视图的坐标）
 */
- (void)startAnimationWithRects:(NSArray <NSValue *>*)arrRects
{
    if (arrRects.count <= 0 || _imgOrigin == nil || _xCount <= 0 || _yCount <= 0) {
        return;
    }
    
    for (NSValue *value in arrRects) {
        
        CGRect imgRect = [value CGRectValue];
        CGFloat width = imgRect.size.width / _xCount;
        CGFloat height = imgRect.size.height / _yCount;
        
        // 修改图片尺寸为传入尺寸
        _imgOrigin = [self imageResize:_imgOrigin andResizeTo:imgRect.size];
        
        for (NSInteger y = 0; y < _yCount; y++) {
            for (NSInteger x = 0; x < _xCount; x++) {
                // 切割图片
                CGSize imageSize = _imgOrigin.size;
                CGFloat scale = _imgOrigin.scale;
                CGFloat subWidth = ((x == _xCount - 1)? imageSize.width - x * width: width) * scale;
                CGFloat subHeight = ((y == _yCount - 1)? imageSize.height - y * height: height) * scale;
                CGRect framRect = CGRectMake(subWidth * x, subHeight * y, subWidth, subHeight);
                CGImageRef croppedCGImage = CGImageCreateWithImageInRect(_imgOrigin.CGImage, framRect);
                UIImage * subImg = [UIImage imageWithCGImage:croppedCGImage scale:scale orientation:UIImageOrientationUp];
                CGImageRelease(croppedCGImage);
                
                // 碎片实际位置
                CGRect subRect = CGRectMake(imgRect.origin.x + width * x, imgRect.origin.y + height * y, width, height);
                
                UIImageView *subImgView = [[UIImageView alloc] initWithImage:subImg];
                subImgView.frame = subRect;
                [self addSubview:subImgView];
                
                // 动画时间
                NSTimeInterval duration = [self fragmentAnimationDurationWithX:x Y:y];
                // 轨迹
                UIBezierPath *path = [self pathWithBigRect:imgRect smallRect:subRect X:x Y:y];

                // 位移动画
                CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
                animation.path = path.CGPath;
                animation.calculationMode = kCAAnimationCubic;
//                animation.rotationMode = kCAAnimationRotateAuto;
                // 透明动画
                CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
                animation2.toValue = @0.0;
                // 变小动画
                CABasicAnimation *animation3 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
                animation3.toValue = @0.2;
                // 动画组
                CAAnimationGroup *group = [CAAnimationGroup animation];
                group.animations = @[animation, animation2, animation3];
                group.duration = duration;
                group.repeatCount = 1;
                group.removedOnCompletion = NO;
                group.fillMode = kCAFillModeForwards;
                group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                group.delegate = self;


                NSString *value = [NSString stringWithFormat:@"%p-%ld-%ld", group, x, y];
                [_dictAnimation setObject:subImgView forKey:value];
                [group setValue:value forKey:AnimationKey];
                [subImgView.layer addAnimation:group forKey:nil];
            }
        }
    }
}

#pragma mark - Private
// 碎片动画时间
- (NSTimeInterval)fragmentAnimationDurationWithX:(NSInteger)x Y:(NSInteger)y
{
    NSTimeInterval base = 0.5;  // 基础时间
//    NSTimeInterval xIncr = 1.0 / _xCount; // 横轴时间增量
    NSTimeInterval yIncr = 0.5 / _yCount; // 纵向轴时间增量
    NSTimeInterval randomIncr = yIncr * 2;// 随机增量范围
    
    NSInteger times = floor(randomIncr * 100.0);
    NSTimeInterval random = (arc4random() % times + 1) / 100.0;
    
    NSTimeInterval duration = base + (_yCount - y - 1) * yIncr + random;
    return duration;
}

/// 运动路径
- (UIBezierPath *)pathWithBigRect:(CGRect)bigRect smallRect:(CGRect)smallRect X:(NSInteger)x Y:(NSInteger)y
{
    // 创建运动轨迹
    UIBezierPath *coinPath = [UIBezierPath bezierPath];
    // 起点
    CGPoint fromPoint = CGPointMake(smallRect.origin.x + smallRect.size.width / 2.0, smallRect.origin.y + smallRect.size.height / 2.0);
    [coinPath moveToPoint:fromPoint];
    // 距离中间点偏移量
    CGFloat offset = (x + 1) - _xCount / 2.0;
    // 终点
    CGPoint toPoint = CGPointMake(smallRect.origin.x + bigRect.size.width * 0.13 * offset, smallRect.origin.y + bigRect.size.height * 4);
    // 控制点
    // 0.5 ~ 1.5
    NSInteger r = floor(1.0 * 10.0);
    CGFloat mulit = (arc4random() % r + 5) / 10.0;
    CGFloat xOffset = (toPoint.x - fromPoint.x) * mulit * (offset > 0? -1: 1);
    // 0.1 ~ 0.3
    NSInteger p = floor(3.0 * 10.0);
    CGFloat mulitp = (arc4random() % p + 10) / 100.0;
    CGFloat yOffset = (toPoint.y - fromPoint.y) * mulitp;
    
    CGPoint controlPoint = CGPointMake(fromPoint.x + xOffset * (offset > 0? -1: 1), fromPoint.y + yOffset);
    [coinPath addQuadCurveToPoint:toPoint controlPoint:controlPoint];
    return coinPath;
}

/// 重绘图片大小
-(UIImage *)imageResize:(UIImage*)img andResizeTo:(CGSize)newSize
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}



#pragma mark - Delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSString *value = [anim valueForKey:AnimationKey];
    
    UIView *view = _dictAnimation[value];
    [_dictAnimation removeObjectForKey:value];
    [view removeFromSuperview];
    
    if (_dictAnimation.count == 0) {
        if (_completion) {
            _completion();
        }
        
        [self removeFromSuperview];
    }
}

@end


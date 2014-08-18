//
//  UIImage+Utilities.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 8/18/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "UIImage+Utilities.h"

@implementation UIImage (Utilities)

+ (UIImage *)applyColor:(UIColor *)color toImage:(UIImage*)img {
    
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, img.scale);
    
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    [img drawInRect:rect];
    CGContextSetFillColorWithColor(contextRef, [color CGColor]);
    CGContextSetBlendMode(contextRef, kCGBlendModeSourceAtop);
    CGContextFillRect(contextRef, rect);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    return result;
}


@end

//
//  SKSpriteNode+Utilities.h
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 8/18/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKSpriteNode (Utilities)
- (NSString*)spritePosition;
- (NSString*)spriteSize;
- (NSString*)spriteSizeAndPosition;
- (CGFloat)spriteBottomEdge;
- (CGFloat)spriteLeftEdge;
- (CGFloat)spriteRightEdge;
@end

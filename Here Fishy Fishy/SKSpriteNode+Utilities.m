//
//  SKSpriteNode+Utilities.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 8/18/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "SKSpriteNode+Utilities.h"

@implementation SKSpriteNode (Utilities)


- (NSString*)spritePosition {
    return [NSString stringWithFormat:@"(x:%2f, y:%2f)", self.position.x, self.position.y];
}

- (NSString*)spriteSize {
    return [NSString stringWithFormat:@"(width:%2f, height:%2f)", self.size.width, self.size.height];
}

- (NSString*)spriteSizeAndPosition {
    return [NSString stringWithFormat:@"position:%@ size:%@", [self spritePosition], [self spriteSize]];
}

- (CGFloat)spriteBottomEdge {
    return self.position.y - self.size.height;
}

@end

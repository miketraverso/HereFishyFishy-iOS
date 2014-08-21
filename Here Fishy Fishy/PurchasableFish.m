//
//  PurchasableFish.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 8/18/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "PurchasableFish.h"

@implementation PurchasableFish

- (id) initWithName:(NSString*)name andId:(NSString*)idName {
    
    self = [super init];
    if (self) {
        
        _name = name;
        _idName = idName;
        _unlocked = false;
        _flapSequence = [SKAction animateWithTextures:
                     @[[SKTexture textureWithImageNamed:[NSString stringWithFormat:@"%@-0", name]],
                      [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"%@-1", name]],
                      [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"%@-0", name]]]
                                     timePerFrame:0.05];
    }
    return self;
}

- (id) initWithName:(NSString*)name andId:(NSString*)idName andUnlocked:(BOOL)unlocked {
    
    self = [self initWithName:name andId:idName];
    [self setUnlocked:unlocked];
    [[NSUserDefaults standardUserDefaults] setBool:unlocked forKey:idName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return self;
}

- (SKTexture*) baseTexture {
    
    return [SKTexture textureWithImage:[UIImage imageNamed: [NSString stringWithFormat:@"%@-0", _name]]];
}

- (UIImage*) baseImage {
    
    return [UIImage imageNamed: [NSString stringWithFormat:@"%@-0", _name]];
}

- (SKTexture*) deadTexture {
    
    return [SKTexture textureWithImage:[UIImage imageNamed: [NSString stringWithFormat:@"%@-dead", _name]]];
}

- (UIImage*) deadImage {
    
    return [UIImage imageNamed: [NSString stringWithFormat:@"%@-dead", _name]];
}

- (SKAction*) flapSequence {
    return _flapSequence;
}

- (SKAction*) animateToPosition:(CGFloat)height andStartFrom:(CGFloat)start {
    
    SKAction *moveToSurfaceAction = [SKAction moveToY:height * 0.5 + start duration:0.5];
    SKAction *moveToSurfaceAction2 = [SKAction moveToY:height * 0.4 + start duration:0.5];
    return [SKAction sequence:@[_flapSequence, moveToSurfaceAction, _flapSequence, moveToSurfaceAction2 ]];
}
@end

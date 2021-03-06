//
//  PurchasableFish.h
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 8/18/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PurchasableFish : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *idName;
@property (strong, nonatomic) SKAction *flapSequence;
@property (nonatomic) BOOL unlocked;

- (id) initWithName:(NSString*)name andId:(NSString*)idName;
- (id) initWithName:(NSString*)name andId:(NSString*)idName andUnlocked:(BOOL)unlocked;
- (SKTexture*) baseTexture;
- (UIImage*) baseImage;
- (SKTexture*) deadTexture;
- (UIImage*) deadImage;
- (SKAction*) flapSequence;
- (SKAction*) animateToPosition:(CGFloat)height andStartFrom:(CGFloat)start;
@end

//
//  HFFPurchaseFishy.h
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 8/18/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "HFFScene.h"

@interface HFFPurchaseFishy : SKScene<SKPhysicsContactDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) id<HFFSceneDelegate> delegate;

-(id)initWithSize:(CGSize)size andDelegate:(id<HFFSceneDelegate>)delegate;

@end

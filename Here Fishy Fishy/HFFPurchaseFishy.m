//
//  HFFPurchaseFishy.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 8/18/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "HFFPurchaseFishy.h"
#import "HFFViewController.h"
#import "HFFScene.h"
#import "UIImage+Utilities.h"
#import <M13OrderedDictionary.h>
#import "PurchasableFish.h"

@implementation HFFPurchaseFishy
{
    SKNode *_worldNode;
    SKSpriteNode *_fishyFishy;
    SKSpriteNode *_prevButton, *_buyButton, *_nextButton, *_playButton;
    SKSpriteNode *_obstacleLeft, *_obstacleRight;
    CGPoint _fishyVelocity;
    
    float _playableStart, _playableHeight;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _delta;
    
    SKAction *_bubbleAction;
    SKAction *_fadeIn,*_fadeInSlow;
    
    BOOL _hitGround, _hitObstacle, _loadedGameOver;
    GameState _gameState;
    
    SKLabelNode *_score, *_scoreShadow;
    NSInteger _bestScore;
    NSInteger _obstaclesPassed;
    
    UIAlertView *_restoreAlert;
    BOOL _isRestoreAlertShowing;
    
    AVAudioPlayer *_player;
    
    M13MutableOrderedDictionary *purchaseableItems;
    NSInteger current;
    SKAction *sequence, *redSequence, *stinkySequence, *clownSequence, *superSequence, *missySequence, *woodSequence;

}

-(id)initWithSize:(CGSize)size andDelegate:(id<HFFSceneDelegate>)delegate {
    
    if (self = [super initWithSize:size]) {
        
        _delegate = delegate;
        _worldNode = [SKNode node];
        [self addChild:_worldNode];
        [self.physicsWorld setContactDelegate:self];
        [self.physicsWorld setGravity:CGVectorMake(0, 0)];

        _restoreAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        _isRestoreAlertShowing = false;
        [_restoreAlert setDelegate:self];

        _fadeIn = [SKAction sequence:@[[SKAction waitForDuration:kAnimDelay*3],
                                       [SKAction fadeInWithDuration:kAnimDelay]]];
        _fadeInSlow = [SKAction sequence:@[[SKAction waitForDuration:kAnimDelay*5],
                                           [SKAction fadeInWithDuration:kAnimDelay]]];
        [self setupStore];
        
        PurchasableFish *orange = [[PurchasableFish alloc] initWithName:@"fish" andId:@"com.traversoft.hff.fish"];
        PurchasableFish *red = [[PurchasableFish alloc] initWithName:@"red" andId:@"com.traversoft.hff.redfish"];
        PurchasableFish *girl = [[PurchasableFish alloc] initWithName:@"girl" andId:@"com.traversoft.hff.missy"];
        PurchasableFish *superFish = [[PurchasableFish alloc] initWithName:@"super-fish" andId:@"com.traversoft.hff.super"];
        PurchasableFish *clown = [[PurchasableFish alloc] initWithName:@"clown" andId:@"com.traversoft.hff.clown"];
        PurchasableFish *stinky = [[PurchasableFish alloc] initWithName:@"stinky" andId:@"com.traversoft.hff.stinky"];
        PurchasableFish *woody = [[PurchasableFish alloc] initWithName:@"wood-fish" andId:@"com.traversoft.hff.woody"];
        
        purchaseableItems = [[M13MutableOrderedDictionary alloc]
                             initWithObjects:@[orange, red, girl, clown, stinky, woody, superFish]
                             pairedWithKeys:@[orange.idName, red.idName, girl.idName, clown.idName, stinky.idName, woody.idName, superFish.idName]];
        current = 0;
    }
    return self;
}

- (void)setupStore
{
    _gameState = GameStateStore;
    [self setupFishyFishy];
    [self setupBackground];
    [self setupForeground];
    [self setupObstacles];
    [self setupUserInterface];
    
    [_fishyFishy removeAllActions];
    
    SKAction *moveToSurfaceAction = [SKAction moveToY:_playableHeight * 0.5 + _playableStart duration:0.5];
    SKAction *flap = [SKAction animateWithTextures:FISHY_MOVE_ANIM timePerFrame:0.05];
    SKAction *moveToSurfaceAction2 = [SKAction moveToY:_playableHeight * 0.4 + _playableStart duration:0.5];
    
    sequence = [SKAction sequence:@[flap, moveToSurfaceAction, flap, moveToSurfaceAction2 ]];
    
    [_fishyFishy runAction:[SKAction repeatActionForever:sequence]];
    
}

- (void)setupFishyFishy
{
    _fishyFishy = [[SKSpriteNode alloc] initWithImageNamed:@"fish-0"];
    [_fishyFishy setPosition:CGPointMake(self.size.width/2, self.size.height/2)];
    [_fishyFishy setZPosition:LayerFishyFishy];
    [_worldNode addChild:_fishyFishy];
}

-(void)flapFishy
{
    [self runAction:_bubbleAction];
    
    SKAction *walk = [SKAction animateWithTextures:FISHY_MOVE_ANIM timePerFrame:0.05];
    [_fishyFishy runAction:walk];
    
    _fishyVelocity = CGPointMake(0, kImpulse);
}

- (void)setupObstacles {
    
    _obstacleLeft = [SKSpriteNode spriteNodeWithImageNamed:@"obstacle-weeds"];
    [_obstacleLeft setZPosition:LayerObstacle];
    [_obstacleLeft setName:@"Obstacle"];
    [_obstacleLeft setPosition:CGPointMake([_fishyFishy spriteLeftEdge] + 2*kMarginDouble, _playableStart + 2*kMarginDouble)];
    
    _obstacleRight = [SKSpriteNode spriteNodeWithImageNamed:@"obstacle-weeds"];
    [_obstacleRight setXScale:-1.0f];
    [_obstacleRight setZPosition:LayerObstacle];
    [_obstacleRight setName:@"Obstacle"];
    [_obstacleRight setPosition:CGPointMake([_fishyFishy spriteRightEdge] - kMarginDouble, _playableStart + 2*kMarginDouble)];
    
    [_worldNode addChild:_obstacleLeft];
    [_worldNode addChild:_obstacleRight];
}

- (void)setupBackground {
    
    SKSpriteNode *background = [[SKSpriteNode alloc] initWithImageNamed:@"background"];
    [background setAnchorPoint:CGPointMake(0.5, 1)];
    [background setPosition:CGPointMake(self.size.width/2, self.size.height)];
    [background setName:@"background"];
    [background setZPosition:LayerBackground];
    
    _playableHeight = background.size.height;
    _playableStart = self.size.height - background.size.height;
    [_worldNode addChild:background];
}

- (void)setupForeground {
    
    for (int backgroundIndex = 0; backgroundIndex < kNumberOfForegrounds; backgroundIndex++) {
        SKSpriteNode *foreground = [[SKSpriteNode alloc] initWithImageNamed:@"foreground"];
        [foreground setAnchorPoint:CGPointMake(0.0, 1.0)];
        [foreground setPosition:CGPointMake( backgroundIndex * self.size.width, _playableStart)];
        [foreground setZPosition:LayerForeground];
        [foreground setName:@"Foreground"];
        [_worldNode addChild:foreground];
    }
}

- (void)setupUserInterface {
    
    SKSpriteNode *prev = [SKSpriteNode spriteNodeWithImageNamed:@"playButton"];
    prev.position = CGPointZero;
    prev.zPosition = LayerUI;
    prev.xScale = -1.0;
    _prevButton = [SKSpriteNode spriteNodeWithImageNamed: @"button"];
    _prevButton.position = CGPointMake(self.position.x + _prevButton.size.width/2, [_obstacleLeft spriteBottomEdge] + 2*kMarginDouble);
    _prevButton.zPosition = LayerUI;
    [_prevButton addChild:prev];
    [_worldNode addChild:_prevButton];
    
    SKSpriteNode *next = [SKSpriteNode spriteNodeWithImageNamed:@"playButton"];
    next.position = CGPointZero;
    next.zPosition = LayerUI;
    _nextButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _nextButton.position = CGPointMake(self.size.width - _nextButton.size.width/2, [_obstacleRight spriteBottomEdge] + 2*kMarginDouble);
    _nextButton.zPosition = LayerUI;
    [_nextButton addChild:next];
    [_worldNode addChild:_nextButton];

    
    SKSpriteNode *play = [SKSpriteNode spriteNodeWithImageNamed:@"play"];
    [play setScale:0.8];
    play.zPosition = LayerUI;
    _playButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _playButton.position = CGPointMake(self.size.width/2,[_fishyFishy spriteBottomEdge] + 4*kMarginDouble);
    _playButton.zPosition = LayerUI;
    [_playButton addChild:play];
    [_worldNode addChild:_playButton];

    
    SKSpriteNode *buy = [SKSpriteNode spriteNodeWithImageNamed:@"buy"];
    buy.position = CGPointMake(self.size.width/2, [_fishyFishy spriteBottomEdge]);
    buy.zPosition = LayerUI;
    [_worldNode addChild:buy];


    SKSpriteNode *price = [SKSpriteNode spriteNodeWithImageNamed:@"price"];
    price.position = CGPointZero;
    price.zPosition = LayerUI;
    _buyButton = [SKSpriteNode spriteNodeWithImageNamed:@"button-yellow"];
    _buyButton.position = CGPointMake(self.size.width/2, [buy spriteBottomEdge] - kMarginHalf);
    _buyButton.zPosition = LayerUI;
    [_buyButton addChild:price];
    [_worldNode addChild:_buyButton];

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];

    if ([_playButton containsPoint:touchLocation]) {
        
        SKView * skView = (SKView *)self.view;
        SKScene *scene = [[HFFScene alloc] initWithSize:skView.bounds.size andDelegate:nil];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        scene.scaleMode = SKSceneScaleModeAspectFill;
        [skView presentScene:scene];
    }
    if ([_nextButton containsPoint:touchLocation]) {
        [_nextButton setAlpha:1.f];
        current+=1;
        if (current >= purchaseableItems.count) {
            current = 0;
        }
        PurchasableFish *fish = (PurchasableFish*)[purchaseableItems objectAtIndex:current];
        [_fishyFishy removeAllActions];
        [_fishyFishy setTexture:[fish baseTexture]];
        [_fishyFishy runAction:[SKAction repeatActionForever:[fish animateToPosition:_playableHeight andStartFrom:_playableStart]]];

    }
    if ([_prevButton containsPoint:touchLocation]) {
        [_prevButton setAlpha:1.f];
        if (current <= 0) {
            current = purchaseableItems.count - 1;
        }
        else {
            current-=1;
        }
        PurchasableFish *fish = (PurchasableFish*)[purchaseableItems objectAtIndex:current];
        [_fishyFishy removeAllActions];
        [_fishyFishy setTexture:[fish baseTexture]];
        [_fishyFishy runAction:[SKAction repeatActionForever:[fish animateToPosition:_playableHeight andStartFrom:_playableStart]]];

    }
    
}
@end

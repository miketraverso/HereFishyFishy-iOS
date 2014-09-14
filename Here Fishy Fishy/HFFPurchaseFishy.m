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
#import "HFFAppDelegate.h"
#import "PurchasableFish.h"

@implementation HFFPurchaseFishy
{
    SKNode *_worldNode;
    SKSpriteNode *_fishyFishy;
    SKSpriteNode *_prevButton, *_buyButton, *_okButton, *_nextButton, *_playButton;
    SKSpriteNode *_obstacleLeft, *_obstacleRight;
    SKSpriteNode *price, *buy, *ok;
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
    
    HFFAppDelegate *_appDelegate;
    AVAudioPlayer *_player;
    NSInteger current;
    SKAction *sequence, *redSequence, *stinkySequence, *clownSequence, *superSequence, *missySequence, *woodSequence, *oldfishSequence, *catfishSequence, *goldFishSequence;

}

-(id)initWithSize:(CGSize)size andDelegate:(id<HFFSceneDelegate>)delegate {
    
    if (self = [super initWithSize:size]) {
        
        _hffSceneDelegate = delegate;
        _appDelegate = (HFFAppDelegate *)[[UIApplication sharedApplication] delegate];

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
        

        current = 0;
    }
    return self;
}

-(void)willMoveFromView:(SKView *)view {
    [super willMoveFromView:view];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)didMoveToView:(SKView *)view {

    [super didMoveToView:view];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseComplete) name:@"TransactionCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreComplete) name:@"RestoreTransactionSuccessful" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseComplete:) name:@"TransactionCompletedWithProductIdentifier" object:nil];
}


- (void)setupStore
{
    _gameState = GameStateStore;
    [self setupFishyFishy];
    [self setupBackground];
    [self setupForeground];
    [self setupObstacles];
    [self setupUserInterface];
    [self setFish:0];
//    for (NSInteger index = 0; index < _appDelegate.purchaseableItems.count; index++) {
//        [self setFish:index];
//    }
    
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

-(void)flapFishy {

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

    
    buy = [SKSpriteNode spriteNodeWithImageNamed:@"buy"];
    buy.position = CGPointMake(self.size.width/2, [_fishyFishy spriteBottomEdge]);
    buy.zPosition = LayerUI;
    [_worldNode addChild:buy];


    price = [SKSpriteNode spriteNodeWithImageNamed:@"price"];
    price.position = CGPointZero;
    price.zPosition = LayerUI;
    
    ok = [SKSpriteNode spriteNodeWithImageNamed:@"ok"];
    ok.position = CGPointZero;
    ok.zPosition = LayerUI;
    _okButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _okButton.position = CGPointMake(self.size.width/2, [buy spriteBottomEdge] - kMarginHalf);
    _okButton.zPosition = LayerUI;
    [_okButton addChild:ok];
    [_worldNode addChild:_okButton];
    [_okButton setHidden:YES];
    

    _buyButton = [SKSpriteNode spriteNodeWithImageNamed:@"button-yellow"];
    _buyButton.position = CGPointMake(self.size.width/2, [buy spriteBottomEdge] - kMarginHalf);
    _buyButton.zPosition = LayerUI;
    [_buyButton addChild:price];
    [_worldNode addChild:_buyButton];

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];

    if ([_playButton containsPoint:touchLocation]) {
        
        SKView * skView = (SKView *)self.view;
        SKScene *scene = [[HFFScene alloc] initWithSize:skView.bounds.size andDelegate:_hffSceneDelegate];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        
        scene.scaleMode = SKSceneScaleModeAspectFill;
        [skView presentScene:scene];
    }
    if ([_nextButton containsPoint:touchLocation]) {
        [_nextButton setAlpha:1.f];
        current+=1;
        if (current >= _appDelegate.purchaseableItems.count) {
            current = 0;
        }

        [self setFish:current];
    }
    
    if ([_prevButton containsPoint:touchLocation]) {
        [_prevButton setAlpha:1.f];
        if (current <= 0) {
            current = _appDelegate.purchaseableItems.count - 1;
        }
        else {
            current-=1;
        }
        
        [self setFish:current];
    }
    
    if ([_buyButton containsPoint:touchLocation]) {
        
        PurchasableFish *fish = (PurchasableFish*)[_appDelegate.purchaseableItems objectAtIndex:current];
        
        if (!fish.unlocked) {
            
            SKProduct *product = [_hffSceneDelegate inAppPurchaseForProductId:[fish idName]];
            if (product) {
                
                //if (![[HFFInAppPurchaseHelper sharedInstance] productPurchased:product.productIdentifier]) {
                    NSLog(@"Buying %@...", fish.name);
                    CLS_LOG(@"Trying to buy :: %@", product.productIdentifier);
                    [[HFFInAppPurchaseHelper sharedInstance] buyProduct:product];
                //}
            }
            else {
                
                CLS_LOG(@"Error trying to buy :: %@", fish.name);

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops..." message:@"Something went wrong. Please try your purchase again in a few." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            }
        }
    }
    if ([_okButton containsPoint:touchLocation]) {
        
        PurchasableFish *fish = (PurchasableFish*)[_appDelegate.purchaseableItems objectAtIndex:current];
        if (fish != nil) {

            if (fish.unlocked) {
                CLS_LOG(@"Selected to play as :: %@", fish.name);

                [_appDelegate setSelectedFish:fish];
                SKView * skView = (SKView *)self.view;
                SKScene *scene = [[HFFScene alloc] initWithSize:skView.bounds.size andDelegate:_hffSceneDelegate];
                scene.scaleMode = SKSceneScaleModeAspectFill;
                
                scene.scaleMode = SKSceneScaleModeAspectFill;
                [skView presentScene:scene];
            }
        }
    }
}

-(void)setFish:(NSInteger)index {
    
    if (index < 0 && index > _appDelegate.purchaseableItems.count) {
        return;
    }
    
    PurchasableFish *fish = (PurchasableFish*)[_appDelegate.purchaseableItems objectAtIndex:index];
    [_fishyFishy removeAllActions];
    [_fishyFishy setTexture:[fish baseTexture]];
    [_fishyFishy runAction:[SKAction repeatActionForever:[fish animateToPosition:_playableHeight andStartFrom:_playableStart]]];
    
    if ([fish unlocked]) {
        
        [_buyButton setHidden:YES];
        [_okButton setHidden:NO];
        [self update:0];
    }
    else {
        [_buyButton setHidden:NO];
        [_okButton setHidden:YES];
    }
}

- (void)purchaseComplete:(NSNotification *) notification {
        
    if ([notification.name isEqualToString:@"TransactionCompletedWithProductIdentifier"])
    {
        NSDictionary* userInfo = notification.userInfo;
        if (userInfo) {
            
            NSString *productId = (NSString*)userInfo[@"productIdentifier"];
            NSLog (@"Successfully received test notification! %@", productId);
         
            PurchasableFish *fish = [[_appDelegate purchaseableItems] objectForKey:productId];
            [fish setUnlocked:YES];
            [self setFish:[[_appDelegate purchaseableItems] indexOfObject:fish]];
        }
    }
}

- (void)restoreComplete {
    
    CLS_LOG(@"Restore completed");
    for (PurchasableFish *fish in _appDelegate.purchaseableItems) {
        [fish setUnlocked:[[NSUserDefaults standardUserDefaults] boolForKey:[fish idName]]];
    }
}

- (void)purchaseComplete {

    _restoreAlert.title = @"Thank you!";
    _restoreAlert.message = @"Thank you for your purchase!";
    if (!_isRestoreAlertShowing)
    {
        _isRestoreAlertShowing = true;
        [_restoreAlert show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    _isRestoreAlertShowing = false;
    [self setFish:current];
}

@end

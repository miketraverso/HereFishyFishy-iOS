//
//  HFFScene.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 2/17/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "HFFScene.h"
#import "HFFPurchaseFishy.h"
#import "HFFAppDelegate.h"

@implementation HFFScene
{
    SKNode *_worldNode;
    SKSpriteNode *_fishyFishy;
    SKSpriteNode *_okButton, *_shareButton, *_buyButton, *_rateButton, *_gamecenterButton, *_restoreButton, *_buyFishyButton, *_buyFishy;
    SKSpriteNode *_crabby, *_whaley;
    CGPoint _fishyVelocity;
    CGPoint _crabbyVelocity, _whaleyVelocity;
    
    float _playableStart, _whaleStart, _crabStart;
    float _playableHeight;

    int _foregroundSwitches;

    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _delta;
    
    SKAction *_bubbleAction;
    SKAction *_newHighScoreAction;
    SKAction *_crashAction;
    SKAction *_fallingAction;
    SKAction *_hitGroundAction;
    SKAction *_popAction;
    SKAction *_coinAction;
    SKAction *_backgroundAction;
    SKAction *_gameOverAction;
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
}

-(void)didMoveToView:(SKView *)view {
    [super didMoveToView:view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreFailed) name:@"RestoreTransactionFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreCompleteFinished:) name:@"RestoreCompleteFinished" object:nil];
}
-(void)willMoveFromView:(SKView *)view
{
    [super willMoveFromView:view];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)initWithSize:(CGSize)size andDelegate:(id<HFFSceneDelegate>)delegate
{
    if (self = [super initWithSize:size])
    {
        
        _delegate = delegate;

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
        _foregroundSwitches = 0;
        _loadedGameOver = NO;
        [self switchToTutorial];
    }
    return self;
}

#pragma mark - Gameplay
-(void)flapFishy
{
    [self runAction:_bubbleAction];
    
    SKAction *walk = [[_appDelegate selectedFish] flapSequence];
    [_fishyFishy runAction:walk];

    _fishyVelocity = CGPointMake(0, kImpulse);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    
    switch (_gameState) {
        case GameStateMainMenu:
            break;
            
        case GameStateStore:
            break;

        case GameStateTutorial:
            
            [_fishyFishy removeAllActions];

            if ([_gamecenterButton containsPoint:touchLocation]) {

                CLS_LOG(@"Launched GameCenter");

                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"gamecenter:/me/account"]];
            }
            else if ([_buyFishyButton containsPoint:touchLocation]) {
                
                CLS_LOG(@"Launched Fish Store");

                SKView * skView = (SKView *)self.view;
                SKScene *scene = [[HFFPurchaseFishy alloc] initWithSize:skView.bounds.size andDelegate:_delegate];
                scene.scaleMode = SKSceneScaleModeAspectFill;
                
                scene.scaleMode = SKSceneScaleModeAspectFill;
                [skView presentScene:scene transition: [SKTransition revealWithDirection:SKTransitionDirectionUp duration:1.0]];
            }

            else {
                
                CLS_LOG(@"Pressed Play");

                [self switchToPlay];
            }
            break;
            
        case GameStatePlay:
            [self flapFishy];
            break;
            
        case GameStateFalling:
            break;
            
        case GameStateShowingScore:
            break;
            
        case GameStateGameOver:
            if (_okButton.alpha == 1.0) {
                
                if ([_okButton containsPoint:touchLocation]) {
                    
                    CLS_LOG(@"Replay pressed");
                    [self switchToNewGame];
                }
                
                if ([_shareButton containsPoint:touchLocation]) {
                
                    CLS_LOG(@"Share pressed");
                    [self shareScore];
                }
                
                if ([_rateButton containsPoint:touchLocation]) {
                    
                    CLS_LOG(@"Share pressed");
                    if ([[UIApplication sharedApplication] canOpenURL:
                        [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", kAppId]]]) {
                        
                        [[UIApplication sharedApplication] openURL:
                         [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", kAppId]]];
                    }
                }
                
                if ([_buyButton containsPoint:touchLocation]) {
                    
                    CLS_LOG(@"Buy no-ads pressed");
                    [self buyButtonTapped];
                }
                
                if ([_restoreButton containsPoint:touchLocation]) {
                    
                    CLS_LOG(@"Restore pressed");
                    [self restorePurchases];
                }
                
                if ([_buyFishyButton containsPoint:touchLocation]) {
                    
                    CLS_LOG(@"Fish Store pressed");
                    SKView * skView = (SKView *)self.view;
                    SKScene *scene = [[HFFPurchaseFishy alloc] initWithSize:skView.bounds.size andDelegate:_delegate];
                    scene.scaleMode = SKSceneScaleModeAspectFill;
                    
                    scene.scaleMode = SKSceneScaleModeAspectFill;
                    [skView presentScene:scene transition: [SKTransition revealWithDirection:SKTransitionDirectionUp duration:1.0]];
                }
                
                _loadedGameOver = NO;
            }
            break;
    }
}


#pragma mark - Updates
-(void)updateScore
{
    [_worldNode enumerateChildNodesWithName:@"ObstacleTop" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *obstacle = (SKSpriteNode*)node;
        NSNumber *passed = obstacle.userData[@"passed"];
        
        if (passed && passed.boolValue)
            return;
        
        if (_fishyFishy.position.x > obstacle.position.x - obstacle.size.width/2 + 30)
        {
            ++_obstaclesPassed;
            // Divide obstacles passed by 2 because each obstacle has a top and bottom
            [_score setText:[NSString stringWithFormat:@"%ld", (long)[self getScore]]];
            [_scoreShadow setText:[NSString stringWithFormat:@"%ld", (long)[self getScore]]];
            
            obstacle.userData[@"passed"] = @YES;
            
            if ([self getScore] == 1+[self getBestScore])
            {
                [self runAction:_newHighScoreAction withKey:@"NewHighScore"];
            }
            else
            {
                [self runAction:_coinAction withKey:@"Coin"];
            }
            
            if ([self getScore] > 0 && [self getScore] % kCrabFrequency == 0) {
                
                if (arc4random_uniform(100) > 33.0) {
                    
                    // Draw crab in background
                    [self updateCrabby];
                    CLS_LOG(@"Crabby witnessed");
                }
            }
            if ([self getScore] > 0 && [self getScore] % kWhaleFrequency == 0) {
                
                // Draw whale in background
                NSLog(@"WHALEY %i - %li", _foregroundSwitches, _obstaclesPassed);
                [self updateWhaley];
                CLS_LOG(@"Whaley witnessed");
            }

        }
    }];
}

-(void)update:(CFTimeInterval)currentTime
{
    if (_lastUpdateTime)
    {
        _delta = currentTime - _lastUpdateTime;
    }
    else
    {
        _delta = 0;
    }
    _lastUpdateTime = currentTime;
    
    switch (_gameState) {
        case GameStateMainMenu:
            break;
        
        case GameStatePlay:
            [self checkHitGround];
            [self checkHitObstacle];
            [self updateFishyFishy];
            [self updateForeground];
            [self updateScore];
            break;
        
        case GameStateShowingScore:
            break;
        
        case GameStateTutorial:
            break;
        
        case GameStateFalling:
            [self checkHitGround];
            [self updateFishyFishy];
            break;
        
        case GameStateGameOver:
            break;
        
        default:
            break;
    }
}

- (void)checkHitGround
{
    if (_hitGround)
    {
        _hitGround = NO;
        _fishyVelocity = CGPointZero;
        [self runAction:_crashAction withKey:@"Crash"];
        [self switchScoreState];
    }
}

- (void)checkHitObstacle
{
    if (_hitObstacle)
    {
        _hitObstacle = NO;
        _fishyVelocity = CGPointZero;
        [self runAction:_crashAction withKey:@"Crash"];
        [self switchScoreState];
    }
}

- (void)updateFishyFishy
{
    // Apply gravity to fishy
    CGPoint gravity = CGPointMake(0, kGravity);
    CGPoint gravityStep = CGPointMultiplyScalar(gravity, _delta);
    _fishyVelocity = CGPointAdd(_fishyVelocity, gravityStep);
    
    // Apply velocity to fishy
    CGPoint velocityStep = CGPointMultiplyScalar(_fishyVelocity, _delta);
    [_fishyFishy setPosition: CGPointAdd(_fishyFishy.position, velocityStep)];
    
    // Check to see if fishy hit the ground
    if (_fishyFishy.position.y - _fishyFishy.size.height/2 <= _playableStart)
    {
        [_fishyFishy setPosition:CGPointMake(_fishyFishy.position.x,_playableStart + _fishyFishy.size.height/2)];
    }
    
    // Check to see if fishy hit the ceiling
    if (_fishyFishy.position.y + _fishyFishy.size.height/2 >= _playableHeight + _playableStart)
    {
        [_fishyFishy setPosition:CGPointMake(_fishyFishy.position.x, _playableHeight + _playableStart - _fishyFishy.size.height/2)];
    }
}

- (void)updateCrabby {
    
    SKAction *crawlAcrossGround = [SKAction moveToX:720.0f duration:3.0f];
    SKAction *animate = [SKAction animateWithTextures:CRABBY_MOVE_ANIM timePerFrame:0.25f];
    [_crabby runAction:[SKAction repeatActionForever:animate]];
    [_crabby runAction:crawlAcrossGround completion:^{
        [_crabby setPosition:CGPointMake(-150.0f, _crabStart)];
        [_crabby removeAllActions];
    }];
}

- (void)updateWhaley {
    
    SKAction *passby = [SKAction moveToX:_whaley.frame.size.width * -1 duration:7.0f];
    SKAction *animate = [SKAction animateWithTextures:WHALEY_MOVE_ANIM timePerFrame:2.0f];
    
    CGPoint velocityStep = CGPointMultiplyScalar(_whaleyVelocity, _delta);
    [_whaley setPosition: CGPointAdd(_whaley.position, velocityStep)];
    [_whaley runAction:[SKAction repeatActionForever:animate]];
    [_whaley runAction:passby completion:^{
        if (!_hitGround && !_hitObstacle) {
            [self startSpawningObstacles];
            [_whaley setPosition:CGPointMake(_whaley.frame.size.width, _whaleStart)];
            [_whaley removeAllActions];
        }
    }];
}

- (void)updateForeground
{
    [_worldNode enumerateChildNodesWithName:@"Foreground" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *foreground = (SKSpriteNode*)node;
        CGPoint movementAmount = CGPointMake(kGroundSpeed * _delta, 0);
        [foreground setPosition:CGPointAdd(foreground.position, movementAmount)];
        
        if (foreground.position.x < -foreground.size.width)
        {
            NSLog(@"Switched! %i - %li", _foregroundSwitches, (long)_obstaclesPassed);
            _foregroundSwitches ++;
            [foreground setPosition:CGPointAdd(foreground.position, CGPointMake(foreground.size.width *  kNumberOfForegrounds, 0))];
        }
    }];
}

#pragma mark - Obstacles
- (SKSpriteNode*)createObstacle:(ObstacleType)obstacleType_
{
    SKSpriteNode *obstacle = [SKSpriteNode spriteNodeWithImageNamed:@"obstacle-weeds"];
    [obstacle setZPosition:LayerObstacle];
    if (obstacleType_ == ObstacleTop)
        [obstacle setName:@"ObstacleTop"];
    else
        [obstacle setName:@"ObstacleBottom"];
    [obstacle setUserData:[NSMutableDictionary dictionary]];
    
    CGFloat offsetX = obstacle.frame.size.width * obstacle.anchorPoint.x;
    CGFloat offsetY = obstacle.frame.size.height * obstacle.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
//    
//    CGPathMoveToPoint(path, NULL, 39 - offsetX, 311 - offsetY);
//    CGPathAddLineToPoint(path, NULL, 75 - offsetX, 300 - offsetY);
//    CGPathAddLineToPoint(path, NULL, 80 - offsetX, 1 - offsetY);
//    CGPathAddLineToPoint(path, NULL, 3 - offsetX, 1 - offsetY);
//    CGPathAddLineToPoint(path, NULL, 4 - offsetX, 298 - offsetY);
  
    CGPathMoveToPoint(path, NULL, 49 - offsetX, 310 - offsetY);
    CGPathAddLineToPoint(path, NULL, 89 - offsetX, 244 - offsetY);
    CGPathAddLineToPoint(path, NULL, 85 - offsetX, 1 - offsetY);
    CGPathAddLineToPoint(path, NULL, 4 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 3 - offsetX, 254 - offsetY);

    CGPathCloseSubpath(path);
    obstacle.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    obstacle.physicsBody.categoryBitMask = EntityCategoryObstacle;
    obstacle.physicsBody.collisionBitMask = 0;
    obstacle.physicsBody.contactTestBitMask = EntityCategoryPlayer;
    
    CGPathRelease(path);
    return obstacle;
}

- (void)startSpawningObstacles {
    
    SKAction *firstDelay = [SKAction waitForDuration:kFirstObstacleSpawn];
    SKAction *spawn = [SKAction performSelector:@selector(spawnObstacle) onTarget:self];
    SKAction *regularDelay = [SKAction waitForDuration:kSubsequentObstacleSpawn];
    SKAction *spawnSequence = [SKAction sequence:@[spawn, regularDelay]];
    SKAction *foreverSpawnObstacles = [SKAction repeatAction:spawnSequence count:kWhaleFrequency];
    SKAction *overallSequence = [SKAction sequence:@[firstDelay, foreverSpawnObstacles]];
    [self removeActionForKey:@"Spawn"];
    [self runAction:overallSequence withKey:@"Spawn"];
}

- (void)stopSpawningObstacles
{
    [self removeActionForKey:@"Spawn"];
    [_worldNode enumerateChildNodesWithName:@"ObstacleTop" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
    [_worldNode enumerateChildNodesWithName:@"ObstacleBottom" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
}

- (void)stopSpawningAllObstacles
{
    [self removeActionForKey:@"Spawn"];
    [_worldNode enumerateChildNodesWithName:@"ObstacleTop" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
    [_worldNode enumerateChildNodesWithName:@"ObstacleBottom" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
    [_worldNode enumerateChildNodesWithName:@"Crabby" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
    [_worldNode enumerateChildNodesWithName:@"Whaley" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
}

- (void)spawnObstacle
{
    SKSpriteNode *bottomObstacle = [self createObstacle:ObstacleBottom];
    SKSpriteNode *topObstacle = [self createObstacle:ObstacleTop];
    
    float startX = self.size.width + bottomObstacle.size.width/2;
    float bottomObstacleMin = (_playableStart - bottomObstacle.size.height / 2) + _playableHeight * kBottomObstacleMinFraction;
    float bottomObstacleMax = (_playableStart - bottomObstacle.size.height / 2) + _playableHeight * kBottomObstacleMaxFraction;
    
    [bottomObstacle setPosition:CGPointMake(startX, RandomFloatRange(bottomObstacleMin, bottomObstacleMax))];
    [topObstacle setZRotation:DegreesToRadians(180.0f)];
    [topObstacle setPosition:CGPointMake(startX, bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + _fishyFishy.size.height * kGapMultiplier)];

    [_worldNode addChild:bottomObstacle];
    [_worldNode addChild:topObstacle];
    
    float movementX = (self.size.width + topObstacle.size.width) * -1;
    float movementDuration = movementX / kGroundSpeed;
    SKAction *sequence = [SKAction sequence:@[[SKAction moveByX:movementX y:0 duration:movementDuration],
                                              [SKAction removeFromParent]
                                              ]];
    [topObstacle runAction:sequence];
    [bottomObstacle runAction:sequence];
}

#pragma mark - Switch States
- (void)switchScoreState
{
    _gameState = GameStateShowingScore;
    [_fishyFishy removeAllActions];
    [self stopSpawningAllObstacles];
    
    SKAction *moveRight = [SKAction moveToX:-35 duration:.10];
    SKAction *moveLeft = [SKAction moveToX: 35 duration:.10];
    SKAction *moveCenter = [SKAction moveToX:0 duration:.10];
    SKAction *shakeSequence = [SKAction sequence:@[moveRight, moveLeft, moveRight, moveLeft, moveCenter]];
    [_worldNode runAction:shakeSequence];
    
    SKAction *deadAction = [SKAction setTexture:[[_appDelegate selectedFish] deadTexture]];
    SKAction *rotateAction = [SKAction rotateByAngle:DegreesToRadians(180) duration:0.5];
    SKAction *moveToSurfaceAction = [SKAction moveToY:self.size.height - _fishyFishy.size.height/2 duration:1.5];
    SKAction *moveToSurfaceAction2 = [SKAction moveToY:self.size.height - _fishyFishy.size.height duration:0.5];
    SKAction *moveToSurfaceAction3 = [SKAction moveToY:self.size.height - _fishyFishy.size.height/2 duration:0.5];
    SKAction *sequence = [SKAction sequence:@[deadAction, rotateAction, moveToSurfaceAction, moveToSurfaceAction2, moveToSurfaceAction3]];

    [_fishyFishy runAction:sequence];
    
    CLS_LOG(@"Game ended with score %ld", (long)[self getScore]);
    [self setupScoreCard];
}

- (void)switchToFalling
{
    _gameState = GameStateFalling;
    [self stopSpawningAllObstacles];
}

- (void)switchToNewGame
{
    SKScene *newScene = [[HFFScene alloc] initWithSize:self.size andDelegate:_delegate];
    SKTransition *transition = [SKTransition fadeWithColor:[SKColor blackColor] duration:0.5];
    [self.view presentScene:newScene transition:transition];
}

- (void)switchToGameOver
{
    while (_player.volume > 0)
    {
        _player.volume = _player.volume - 0.25;
    }
    
    [_player stop];
    [self runAction:_gameOverAction withKey:@"GameOver"];
    _gameState = GameStateGameOver;
}

- (void)switchToPlay {
    
    // Set state
    _gameState = GameStatePlay;
    
    [self addScoreToUI];
    
    // Remove tutorial
    [_worldNode enumerateChildNodesWithName:@"Tutorial" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
                                             [SKAction fadeOutWithDuration:0.5],
                                             [SKAction removeFromParent]
                                             ]]];
    }];
    
    
    [_worldNode enumerateChildNodesWithName:@"BuyFishy" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
                                             [SKAction fadeOutWithDuration:0.5],
                                             [SKAction removeFromParent]
                                             ]]];
    }];
    
    [_worldNode enumerateChildNodesWithName:@"GameCenter" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
                                             [SKAction fadeOutWithDuration:0.5],
                                             [SKAction removeFromParent]
                                             ]]];
    }];

    
    // Remove wobble
    [_fishyFishy removeActionForKey:@"Wobble"];
    
    [_player setNumberOfLoops:-1];
    [_player play];

    // Start spawning
    [self startSpawningObstacles];
    
    // Move player
    [self flapFishy];
}

- (void)switchToTutorial
{
    _gameState = GameStateTutorial;
    [self setupBackground];
    [self setupForeground];
    [self setupFishyFishy];
    [self setupWhaley];
    [self setupCrabby];
    [self setupSounds];
    [self setupScore];
    
    [_fishyFishy removeAllActions];
    
    SKAction *moveToSurfaceAction = [SKAction moveToY:_playableHeight * 0.7 + _playableStart duration:0.5];
    SKAction *flap = [[_appDelegate selectedFish] flapSequence];
    SKAction *moveToSurfaceAction2 = [SKAction moveToY:_playableHeight * 0.65 + _playableStart duration:0.5];
    SKAction *sequence = [SKAction sequence:@[flap, moveToSurfaceAction, flap, moveToSurfaceAction2 ]];
    [self flapFishy];
    [_fishyFishy runAction:[SKAction repeatActionForever:sequence]];

    [self setupTutorial];
}

#pragma mark - Kiip
//- (void)showKiipRewardForNewHighScore
//{
//    NSString *momentName = @"Beating your best score!";
//
//    if (![[NSUserDefaults standardUserDefaults] boolForKey:momentName])
//    {
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:momentName];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//
//        [[Kiip sharedInstance] saveMoment:momentName withCompletionHandler:^(KPPoptart *poptart, NSError *error) {
//            if (error)
//            {
//                NSLog([NSString stringWithFormat:@"Kiip error: %@", [error userInfo]]);
//            }
//            if (poptart)
//            {
//                [poptart show];
//            }
//            if (!poptart)
//            {
//                // handle logic when there is no reward to give.
//            }
//        }];
//    }
//}
//
//- (void)showKiipRewardForObstacles
//{
//    NSString *momentName = @"";
//    
//    if ([self getScore] >= 1 && [self getScore] < 5)
//    {
//        momentName = @"Getting past 1 obstacle!";
//    }
//    else if ([self getScore] >= 5 && [self getScore] < 10)
//    {
//        momentName = @"Getting past 5 obstacles!";
//    }
//    else if ([self getScore] >= 10 && [self getScore] < 25)
//    {
//        momentName = @"Getting past 10 obstacles!";
//    }
//    else if ([self getScore] >= 25 && [self getScore] < 50)
//    {
//        momentName = @"Getting past 25 obstacles!";
//    }
//    else if ([self getScore] >= 50 && [self getScore] < 100)
//    {
//        momentName = @"Getting past 50 obstacles!";
//    }
//    else if ([self getScore] >= 100)
//    {
//        momentName = @"Getting past 100 or more obstacles!";
//    }
//    
//    // No Kiip reward to give
//    if ([momentName isEqualToString:@""])
//        return;
//    
//    if (![[NSUserDefaults standardUserDefaults] boolForKey:momentName])
//    {
//        // Update the user has been presented with this award already
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:momentName];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//        
//        // Get user the Kiip reward
//        [[Kiip sharedInstance] saveMoment:momentName withCompletionHandler:^(KPPoptart *poptart, NSError *error) {
//            if (error)
//            {
//                NSLog([NSString stringWithFormat:@"Kiip error: %@", [error userInfo]]);
//            }
//            if (poptart)
//            {
//                [poptart show];
//            }
//            if (!poptart)
//            {
//                // handle logic when there is no reward to give.
//            }
//        }];
//    }
//}

#pragma mark - Setup
- (void)setupScore
{
    _scoreShadow = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    [_scoreShadow setFontColor:[SKColor whiteColor]];
    _scoreShadow.fontSize = kFontSize;
    [_scoreShadow setPosition:CGPointMake(self.size.width/2-2, self.size.height+1 - kMargin)];
    [_scoreShadow setText:@"0"];
    [_scoreShadow setVerticalAlignmentMode:SKLabelVerticalAlignmentModeTop];
    [_scoreShadow setZPosition:LayerUI];
    
    _score = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    [_score setFontColor:[SKColor blackColor]];
    _score.fontSize = kFontSize;
    [_score setPosition:CGPointMake(self.size.width/2, self.size.height - kMargin)];
    [_score setText:@"0"];
    [_score setVerticalAlignmentMode:SKLabelVerticalAlignmentModeTop];
    [_score setZPosition:LayerUI];
}

- (void)addScoreToUI
{
    [_score runAction:[SKAction fadeInWithDuration:1.5]];
    [_scoreShadow runAction:[SKAction fadeInWithDuration:1.5]];
    
    [_worldNode addChild:_score];
    [_worldNode addChild:_scoreShadow];
}

- (void)setupBackground
{
    SKSpriteNode *background = [[SKSpriteNode alloc] initWithImageNamed:@"background"];
    [background setAnchorPoint:CGPointMake(0.5, 1)];
    [background setPosition:CGPointMake(self.size.width/2, self.size.height)];
    [background setName:@"background"];
    [background setZPosition:LayerBackground];
    
    // Set the playable area attributes
    _playableHeight = background.size.height;
    _playableStart = self.size.height - background.size.height;
    _crabStart = _playableStart - 5.0f;
    _whaleStart = _playableStart - 20.0f;
    [_worldNode addChild:background];
    
    CGPoint lowerLeft = CGPointMake(0, _playableStart);
    CGPoint lowerRight= CGPointMake(self.size.width, _playableStart);
    self.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:lowerLeft toPoint:lowerRight];
    self.physicsBody.categoryBitMask = EntityCategoryGround;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = EntityCategoryPlayer;
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

- (void)setupFishyFishy {

    _fishyFishy = [[SKSpriteNode alloc] initWithTexture:[[_appDelegate selectedFish] baseTexture]];
    [_fishyFishy setScale:.45f];
    [_fishyFishy setPosition:CGPointMake(self.size.width * 0.2, _playableHeight * 0.7 + _playableStart)];
    [_fishyFishy setZPosition:LayerFishyFishy];
    [_worldNode addChild:_fishyFishy];
    
    CGFloat offsetX = _fishyFishy.frame.size.width * _fishyFishy.anchorPoint.x;
    CGFloat offsetY = _fishyFishy.frame.size.height * _fishyFishy.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 59 - offsetX, 27 - offsetY);
    CGPathAddLineToPoint(path, NULL, 51 - offsetX, 6 - offsetY);
    CGPathAddLineToPoint(path, NULL, 33 - offsetX, 1 - offsetY);
    CGPathAddLineToPoint(path, NULL, 15 - offsetX, 11 - offsetY);
    CGPathAddLineToPoint(path, NULL, 1 - offsetX, 19 - offsetY);
    CGPathAddLineToPoint(path, NULL, 3 - offsetX, 31 - offsetY);
    CGPathAddLineToPoint(path, NULL, 35 - offsetX, 46 - offsetY);
    CGPathCloseSubpath(path);
    
    _fishyFishy.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    _fishyFishy.physicsBody.categoryBitMask = EntityCategoryPlayer;
    _fishyFishy.physicsBody.collisionBitMask = 0;
    _fishyFishy.physicsBody.contactTestBitMask = EntityCategoryGround | EntityCategoryObstacle;
    
    CGPathRelease(path);
}

- (void)setupCrabby {
    
    _crabby = [[SKSpriteNode alloc] initWithImageNamed:@"crabby-1"];
    [_crabby setAnchorPoint:CGPointMake(0.5, 0.0)];
    [_crabby setPosition:CGPointMake( -150.0f, _crabStart)];
    [_crabby setZPosition:LayerForeground];
    [_crabby setName:@"Crabby"];
    [_worldNode addChild:_crabby];
}

- (void)setupWhaley {
    
    _whaley = [[SKSpriteNode alloc] initWithImageNamed:@"whale-1"];
    [_whaley setAnchorPoint:CGPointMake(0.0, 0.0)];
    [_whaley setPosition:CGPointMake(_whaley.frame.size.width, _whaleStart)];
    [_whaley setZPosition:LayerForeground];
    [_whaley setName:@"Whaley"];
    [_worldNode addChild:_whaley];
    
    CGFloat offsetX = _whaley.frame.size.width * _whaley.anchorPoint.x;
    CGFloat offsetY = _whaley.frame.size.height * _whaley.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathMoveToPoint(path, NULL, 14 - offsetX, 3 - offsetY);
    CGPathAddLineToPoint(path, NULL, 0 - offsetX, 72 - offsetY);
    CGPathAddLineToPoint(path, NULL, 2 - offsetX, 121 - offsetY);
    CGPathAddLineToPoint(path, NULL, 15 - offsetX, 136 - offsetY);
    CGPathAddLineToPoint(path, NULL, 42 - offsetX, 104 - offsetY);
    CGPathAddLineToPoint(path, NULL, 81 - offsetX, 106 - offsetY);
    CGPathAddLineToPoint(path, NULL, 80 - offsetX, 74 - offsetY);
    CGPathAddLineToPoint(path, NULL, 166 - offsetX, 125 - offsetY);
    CGPathAddLineToPoint(path, NULL, 237 - offsetX, 136 - offsetY);
    CGPathAddLineToPoint(path, NULL, 342 - offsetX, 130 - offsetY);
    CGPathAddLineToPoint(path, NULL, 354 - offsetX, 5 - offsetY);
    CGPathCloseSubpath(path);
    
    _whaley.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    _whaley.physicsBody.categoryBitMask = EntityCategoryObstacle;
    _whaley.physicsBody.collisionBitMask = 0;
    _whaley.physicsBody.contactTestBitMask = EntityCategoryPlayer;
    
    CGPathRelease(path);
}

- (void)setupScoreCard
{
    SKAction *pops = [SKAction sequence:@[
                                          [SKAction waitForDuration:kAnimDelay],
                                          _popAction,
                                          [SKAction waitForDuration:kAnimDelay],
                                          _popAction,
                                          [SKAction waitForDuration:kAnimDelay*.02],
                                          _popAction,
                                          [SKAction runBlock:^{
        [self switchToGameOver];
    }]
                                          ]];
    [self runAction:pops];
    
    BOOL KiipRewardsOn = YES;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"kiipRewards"])
    {
        KiipRewardsOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"kiipRewards"];
    }
    
    if ([self getScore] > [self getBestScore])
    {
        [self setBestScore];
//        if (!KiipRewardsOn)
//            [self showKiipRewardForNewHighScore];
    }
//    else
//    {
//        if (!KiipRewardsOn)
//            [self showKiipRewardForObstacles];
//    }
    
    _restoreButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _restoreButton.position = CGPointMake(self.size.width/2-2, self.size.height+1 - kMargin - 20);
    _restoreButton.zPosition = LayerUI;
    [_worldNode addChild:_restoreButton];
    
    SKSpriteNode *restore = [SKSpriteNode spriteNodeWithImageNamed:@"restore"];
    restore.position = CGPointZero;
    restore.zPosition = LayerUI;
    [_restoreButton addChild:restore];

    SKSpriteNode *gameOver = [SKSpriteNode spriteNodeWithImageNamed:@"gameOver"];
    gameOver.position = CGPointMake(self.size.width/2, [_restoreButton spriteBottomEdge] + 5);
    gameOver.zPosition = LayerUI;
    [_worldNode addChild:gameOver];

    SKSpriteNode *scorecard = [SKSpriteNode spriteNodeWithImageNamed:@"scorecard"];
    scorecard.position = CGPointMake(self.size.width/2, [gameOver spriteBottomEdge] - kMarginThreeQuarters);
    scorecard.name = @"Tutorial";
    scorecard.zPosition = LayerUI;
    [_worldNode addChild:scorecard];
    
    SKLabelNode *lastScoreShadow = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    lastScoreShadow.fontColor = [SKColor blackColor];
    lastScoreShadow.fontSize = kFontSize;
    lastScoreShadow.position = CGPointMake(-scorecard.size.width * 0.25+ 2, -scorecard.size.height * 0.2 - 1);
    lastScoreShadow.text = [NSString stringWithFormat:@"%ld", (long)[self getScore]];
    [scorecard addChild:lastScoreShadow];
    
    SKLabelNode *bestScoreShadow = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    bestScoreShadow.fontColor = [SKColor blackColor];
    bestScoreShadow.fontSize = kFontSize;
    bestScoreShadow.position = CGPointMake(scorecard.size.width * 0.25 + 2, -scorecard.size.height * 0.2 - 1);
    bestScoreShadow.text = [NSString stringWithFormat:@"%ld", (long)[self getBestScore]];
    [scorecard addChild:bestScoreShadow];

    SKLabelNode *lastScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    lastScore.fontColor = [SKColor whiteColor];
    lastScore.fontSize = kFontSize;
    lastScore.position = CGPointMake(-scorecard.size.width * 0.25, -scorecard.size.height * 0.2);
    lastScore.text = [NSString stringWithFormat:@"%ld", (long)[self getScore]];
    [scorecard addChild:lastScore];
    
    SKLabelNode *bestScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    bestScore.fontColor = [SKColor whiteColor];
    bestScore.fontSize = kFontSize;
    bestScore.position = CGPointMake(scorecard.size.width * 0.25, -scorecard.size.height * 0.2);
    bestScore.text = [NSString stringWithFormat:@"%ld", (long)[self getBestScore]];
    [scorecard addChild:bestScore];
    
    _buyButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    if (![self hasRemoveAdsBeenPurchased]) {
        
        _buyButton.position = CGPointMake(self.size.width/2, [scorecard spriteBottomEdge] + kMarginHalf);
        _buyButton.zPosition = LayerUI;
        
        SKSpriteNode *removeAdsNode = [SKSpriteNode spriteNodeWithImageNamed:@"removeads"];
        removeAdsNode.position = CGPointZero;
        removeAdsNode.zPosition = LayerUI;
        
        [_worldNode addChild:_buyButton];
        [_buyButton addChild:removeAdsNode];
    }
    
    _okButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _okButton.position = CGPointMake(self.size.width * 0.75, [scorecard spriteBottomEdge] - _okButton.size.height );
    _okButton.zPosition = LayerUI;
    [_worldNode addChild:_okButton];
    
    SKSpriteNode *ok = [SKSpriteNode spriteNodeWithImageNamed:@"ok"];
    ok.position = CGPointZero;
    ok.zPosition = LayerUI;
    [_okButton addChild:ok];
    
    _shareButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _shareButton.position = CGPointMake(self.size.width * 0.25, [scorecard spriteBottomEdge] - _shareButton.size.height );
    _shareButton.zPosition = LayerUI;
    [_worldNode addChild:_shareButton];
    
    SKSpriteNode *share = [SKSpriteNode spriteNodeWithImageNamed:@"share"];
    share.position = CGPointZero;
    share.zPosition = LayerUI;
    [_shareButton addChild:share];
    
    _buyFishyButton.position = CGPointMake(self.size.width * 0.25, [_shareButton spriteBottomEdge] - kMarginHalf);
    _buyFishyButton.zPosition = LayerUI;
    [_worldNode addChild:_buyFishyButton];

    _rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _rateButton.position = CGPointMake(self.size.width * 0.75, [_okButton spriteBottomEdge] - kMarginHalf);
    _rateButton.zPosition = LayerUI;
    
    SKSpriteNode *rate = [SKSpriteNode spriteNodeWithImageNamed:@"rate"];
    rate.position = CGPointZero;
    rate.zPosition = LayerUI;

    [_worldNode addChild:_rateButton];
    [_rateButton addChild:rate];

    gameOver.scale = 0;
    gameOver.alpha = 0;
    SKAction *group = [SKAction group:@[
                                        [SKAction fadeInWithDuration:kAnimDelay],
                                        [SKAction scaleTo:1.0 duration:kAnimDelay]
                                        ]];
    group.timingMode = SKActionTimingEaseInEaseOut;
    [gameOver runAction:[SKAction sequence:@[
                                             [SKAction waitForDuration:kAnimDelay],
                                             group
                                             ]]];
    CGPoint scoreCardPosition = scorecard.position;
    scorecard.position = CGPointMake(self.size.width * 0.5, -scorecard.size.height/2);
    SKAction *moveTo = [SKAction moveTo:scoreCardPosition duration:kAnimDelay];
    moveTo.timingMode = SKActionTimingEaseInEaseOut;
    [scorecard runAction:[SKAction sequence:@[
                                              [SKAction waitForDuration:kAnimDelay*2],
                                              moveTo
                                              ]] completion:^{ }];
    
    _okButton.alpha = 0;
    _shareButton.alpha = 0;
    _rateButton.alpha = 0;
    _buyButton.alpha = 0;
    _restoreButton.alpha = 0;
    _buyFishyButton.alpha = 0;
    
    [_okButton runAction:_fadeIn];
    [_shareButton runAction:_fadeIn];
    [_rateButton runAction:_fadeIn];
    [_restoreButton runAction:_fadeInSlow];
    [_buyFishyButton runAction:_fadeIn];
    [_buyButton runAction:_fadeIn completion:^{ _loadedGameOver = YES; }];
}

- (BOOL)hasRemoveAdsBeenPurchased {
    
    for (SKProduct *productIter in  [self.delegate getProducts]) {
        if (productIter != nil) {
            if ([[HFFInAppPurchaseHelper sharedInstance] productPurchased:@"com.traversoft.hff.no.ads"])
            {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"com.traversoft.hff.no.ads"];
                return YES;
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"com.traversoft.hff.no.ads"];
    return NO;
}

- (void)setupSounds
{
    _newHighScoreAction = [SKAction playSoundFileNamed:@"ding.m4a" waitForCompletion:NO];
    _bubbleAction = [SKAction playSoundFileNamed:@"bubbleUp.m4a" waitForCompletion:NO];
    _crashAction = [SKAction playSoundFileNamed:@"crash.m4a" waitForCompletion:NO];
    _coinAction = [SKAction playSoundFileNamed:@"littleDing.m4a" waitForCompletion:NO];
    _popAction = [SKAction playSoundFileNamed:@"pop.wav" waitForCompletion:NO];
    _gameOverAction = [SKAction playSoundFileNamed:@"gameOverLose.wav" waitForCompletion:NO];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"backgroundLoop" ofType:@"m4a"]];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];

}

- (void)setupTutorial
{
    SKSpriteNode *tutorial = [SKSpriteNode spriteNodeWithImageNamed:@"tap"];
    tutorial.position = CGPointMake((int)self.size.width * 0.5, _playableStart - _playableStart * 0.3);
    tutorial.name = @"Tutorial";
    tutorial.zPosition = LayerUI;
    [_worldNode addChild:tutorial];
    
    tutorial.scale = 0;
    SKAction *scaleIn = [SKAction scaleTo:1.0 duration:kAnimDelay];
    SKAction *scaleOut = [SKAction scaleTo:0.95 duration:kAnimDelay];
    SKAction *sequence = [SKAction sequence:@[scaleIn, scaleOut]];

    scaleIn.timingMode = SKActionTimingEaseInEaseOut;
    scaleOut.timingMode = SKActionTimingEaseInEaseOut;
    [tutorial runAction:[SKAction repeatActionForever:sequence]];

    SKSpriteNode *ready = [SKSpriteNode spriteNodeWithImageNamed:@"title-fancy"];
    ready.position = CGPointMake(self.size.width * 0.5, _playableHeight * 0.4 + _playableStart);
    ready.name = @"Tutorial";
    ready.zPosition = LayerUI;
    [_worldNode addChild:ready];
    
    _gamecenterButton = [SKSpriteNode spriteNodeWithImageNamed:@"gamecenter"];
    _gamecenterButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.85 );
    _gamecenterButton.name = @"GameCenter";
    _gamecenterButton.zPosition = LayerGameCenter;
    [_worldNode addChild:_gamecenterButton];
    
    

    _buyFishyButton = [[SKSpriteNode alloc] initWithImageNamed:@"button"];
    _buyFishyButton.anchorPoint = CGPointMake(0.5f, 0.5f);
    _buyFishyButton.position = CGPointMake(self.size.width/2, [ready spriteBottomEdge] + kMargin);
    _buyFishyButton.zPosition = LayerGameCenter;
    _buyFishyButton.name = @"BuyFishy";

    _buyFishy = [[SKSpriteNode alloc] initWithImageNamed:@"fish-0"];
    _buyFishy.anchorPoint = CGPointMake(0.5f, 0.5f);
    [_buyFishy setScale:0.75];
    _buyFishy.zPosition = LayerGameCenter;
    _buyFishy.name = @"BuyFishy";

    SKAction *walk = [[_appDelegate selectedFish] flapSequence];
    [_buyFishy runAction:[SKAction repeatActionForever:walk]];

    [_buyFishyButton addChild:_buyFishy];
    [_worldNode addChild:_buyFishyButton];
}

- (void)switchScene:(SKScene*)newScene {

    SKView * skView = (SKView *)self.view;
    newScene.scaleMode = SKSceneScaleModeAspectFill;
    [skView presentScene:newScene];
}

#pragma mark - SKPhysicsContactDelegate
- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *otherBody = (contact.bodyA.categoryBitMask == EntityCategoryPlayer ? contact.bodyB : contact.bodyA);

    if (otherBody.categoryBitMask == EntityCategoryObstacle)
    {
        _hitObstacle = YES;
        return;
    }
    else if (otherBody.categoryBitMask == EntityCategoryGround)
    {
        _hitGround = YES;
        return;
    }
}

#pragma mark - Scores
- (NSInteger)getBestScore
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"best_score"];
}

- (void)setBestScore
{
    CLS_LOG(@"New best score reached :: %ld", (long)[self getScore]);
    [[NSUserDefaults standardUserDefaults] setInteger:[self getScore] forKey:@"best_score"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reportScore:[self getScore] forLeaderboardID:@"com.traversoft.hff.highscores"];
}

- (NSInteger)getScore
{
    return _obstaclesPassed;
}

- (void) reportScore:(int64_t)score forLeaderboardID: (NSString*) identifier
{
    GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier: identifier];
    scoreReporter.value = score;
    scoreReporter.context = 0;
    
    NSArray *scores = @[scoreReporter];
    [GKScore reportScores:scores withCompletionHandler:^(NSError *error) {
        if (error)
        {
            NSLog(@"Error reporting score %@", error);
        }
    }];
}


#pragma mark - Share Score
- (void)shareScore {
    
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@?mt=8", kAppId]; //APP_STORE_ID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    UIImage *screenshot = [self.delegate screenshot];
    
    NSString *initialTextString = [NSString stringWithFormat:@"Yay!!! I scored %ld points in Here Fishy Fishy!", (long)[self getScore]];
    [self.delegate shareString:initialTextString url:url image:screenshot];
}


- (void)buyButtonTapped
{
    SKProduct *product = [self.delegate inAppPurchaseForProductId:@"com.traversoft.hff.no.ads"];
    if (product)
        
    {
        if (![[HFFInAppPurchaseHelper sharedInstance] productPurchased:@"com.traversoft.hff.no.ads"])
        {
            NSLog(@"Buying %@...", product.productIdentifier);
            CLS_LOG(@"Buying %@...", product.productIdentifier);
            [[HFFInAppPurchaseHelper sharedInstance] buyProduct:product];
        }
    }
    else
    {
        CLS_LOG(@"Issue buying com.traversoft.hff.no.ads...");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops..." message:@"Something went wrong. Please try your purchase again in a few." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}

- (void)restorePurchases
{
//    for (SKProduct *product in  [self.delegate getProducts]) {
//        if (product) {
    NSLog(@"Restoring transactions...");// product.productIdentifier);
    [[HFFInAppPurchaseHelper sharedInstance] restoreCompletedTransactions];
//    }
//    else {
//    oops = TRUE;
//    break;
//        }
//    }
//    if (oops)
//    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops..." message:@"Something went wrong. Please try your restoring your purchases in a few." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
//    }
//    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"restoreAllPurchases"];
        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
}

- (void)restoreComplete {
    
}

-(void)restoreCompleteFinished:(NSNotification*)notification {
    
    _restoreAlert.title = @"Success";
    _restoreAlert.message = @"Restored purchase";
    if (!_isRestoreAlertShowing)
    {
        NSLog(@"Restored transactions SUCCESS...");
        _isRestoreAlertShowing = true;
        [_restoreAlert show];
        if ([notification.name isEqualToString:@"RestoreCompleteFinished"])
        {
            NSDictionary* userInfo = notification.userInfo;
            if (userInfo) {
                NSMutableArray *productIds = (NSMutableArray*)userInfo[@"productIdentifiers"];
                CLSNSLog (@"Successfully received restore transaction success notification! %lu", (unsigned long)productIds.count);
                

                for (int index = 0; index < _appDelegate.purchaseableItems.count; index++) {
                    
                    PurchasableFish *fish = [[_appDelegate purchaseableItems] objectAtIndex:index];
                    if ([productIds indexOfObject:[fish idName]] != NSNotFound) {

                        [fish setUnlocked:YES];
                        [fish setUnlocked:[[NSUserDefaults standardUserDefaults] boolForKey:[fish idName]]];
                        CLSNSLog (@"Successfully unlocked %@ from restored transaction", [fish idName]);
                    }
                }
            }
        }
        
        
        CLS_LOG(@"Restore completed");
    }
}

- (void)restoreSuccess:(NSNotification*)notification
{
    _restoreAlert.title = @"Success";
    _restoreAlert.message = @"Restored purchase";
    if (!_isRestoreAlertShowing)
    {
        NSLog(@"Restored transactions SUCCESS...");
        _isRestoreAlertShowing = true;
        [_restoreAlert show];
        if ([notification.name isEqualToString:@"RestoreTransactionSuccessful"])
        {
            NSDictionary* userInfo = notification.userInfo;
            if (userInfo) {
                NSString *productId = (NSString*)userInfo[@"productIdentifier"];
                NSLog (@"Successfully received restore transaction success notification! %@", productId);
                PurchasableFish *fish = [_appDelegate.purchaseableItems objectForKey:productId];
                [fish setUnlocked:[[NSUserDefaults standardUserDefaults] boolForKey:[fish idName]]];
            }
        }
        
        
        CLS_LOG(@"Restore completed");
    }
}

- (void)restoreFailed
{
    _restoreAlert.title = @"Oops...";
    _restoreAlert.message = @"Error restoring purchase. Please try again.";
    if (!_isRestoreAlertShowing)
    {
        NSLog(@"Restored transactions FAILED...");
        _isRestoreAlertShowing = true;
        [_restoreAlert show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    _isRestoreAlertShowing = false;
}

@end

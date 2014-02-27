//
//  HFFScene.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 2/17/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "HFFScene.h"
#import <GameKit/GameKit.h>
#import <StoreKit/StoreKit.h>
#import "HFFInAppPurchaseHelper.h"
#import <KiipSDK/KiipSDK.h>

typedef NS_ENUM(int, Layer) {
    LayerBackground,
    LayerObstacle,
    LayerForeground,
    LayerFishyFishy,
    LayerUI
};

typedef NS_OPTIONS(int, EntityCategory) {
    EntityCategoryPlayer = 1 << 0,
    EntityCategoryObstacle = 1 << 1,
    EntityCategoryGround = 1 << 2
};

static const int kNumberOfForegrounds = 2;
static const float kGravity = -1500.0;
static const float kImpulse = 400.0;
static const float kGroundSpeed = -150.0f;
static const float kGapMultiplier = 2.5;
static const float kBottomObstacleMinFraction = 0.1;
static const float kBottomObstacleMaxFraction = 0.6;
static const float kFirstObstacleSpawn = 1.75;
static const float kSubsequentObstacleSpawn = 1.5;
static const float kMargin = 30;
static const float kAnimDelay = 0.3;

static NSString *const kFontName = @"KarmaticArcade";
//static NSString *const kFontName = @"CourierNewPS-BoldMT";

#define FISHY_MOVE_ANIM @[[SKTexture textureWithImageNamed:@"fish-0"],[SKTexture textureWithImageNamed:@"fish-1"],[SKTexture textureWithImageNamed:@"fish-0"]]

@implementation HFFScene
{
    SKNode *_worldNode;
    SKSpriteNode *_fishyFishy;
    SKSpriteNode *_okButton, *_shareButton, *_buyButton, *_rateButton;
    CGPoint _fishyVelocity;
    
    float _playableStart;
    float _playableHeight;

    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _delta;
    
    SKAction *_flapAction;
    SKAction *_dingAction;
    SKAction *_whackAction;
    SKAction *_fallingAction;
    SKAction *_hitGroundAction;
    SKAction *_popAction;
    SKAction *_coinAction;
    
    BOOL _hitGround, _hitObstacle;
    GameState _gameState;
    
    SKLabelNode *_score;
    NSInteger _bestScore;
    NSInteger _obstaclesPassed;
}

-(id)initWithSize:(CGSize)size andDelegate:(id<HFFSceneDelegate>)delegate
{
    if (self = [super initWithSize:size])
    {
        _delegate = delegate;

        _worldNode = [SKNode node];
        [self addChild:_worldNode];
        [self.physicsWorld setContactDelegate:self];
        [self.physicsWorld setGravity:CGVectorMake(0, 0)];

        [self switchToTutorial];
    }
    return self;
}

#pragma mark - Gameplay
-(void)flapFishy
{
    [self runAction:_flapAction];
    
    SKAction *walk = [SKAction animateWithTextures:FISHY_MOVE_ANIM timePerFrame:0.05];
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
        case GameStateTutorial:
            [self switchToPlay];
            break;
        case GameStatePlay:
            [self flapFishy];
            break;
        case GameStateFalling:
            break;
        case GameStateShowingScore:
            break;
        case GameStateGameOver:
            if ([_okButton containsPoint:touchLocation])
            {
                [self switchToNewGame];
            }
            if ([_shareButton containsPoint:touchLocation])
            {
                [self shareScore];
            }
            if ([_rateButton containsPoint:touchLocation])
            {
                // Go to rate page
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id493350516"]];
            }
            if ([_buyButton containsPoint:touchLocation])
            {
                // Make purchase
                [self buyButtonTapped];
            }

            break;
    }
}


#pragma mark - Updates
-(void)updateScore
{
    [_worldNode enumerateChildNodesWithName:@"Obstacle" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *obstacle = (SKSpriteNode*)node;
        NSNumber *passed = obstacle.userData[@"passed"];
        
        if (passed && passed.boolValue)
            return;
        
        if (_fishyFishy.position.x > obstacle.position.x - obstacle.size.width/2)
        {
            ++_obstaclesPassed;
            // Divide obstacles passed by 2 because each obstacle has a top and bottom
            [_score setText:[NSString stringWithFormat:@"%d", [self getScore]]];
            obstacle.userData[@"passed"] = @YES;
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
        [self switchScoreState];
    }
}

- (void)checkHitObstacle
{
    if (_hitObstacle)
    {
        _hitObstacle = NO;
        _fishyVelocity = CGPointZero;
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

- (void)updateForeground
{
    [_worldNode enumerateChildNodesWithName:@"Foreground" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *foreground = (SKSpriteNode*)node;
        CGPoint movementAmount = CGPointMake(kGroundSpeed * _delta, 0);
        [foreground setPosition:CGPointAdd(foreground.position, movementAmount)];
        
        if (foreground.position.x < -foreground.size.width)
        {
            [foreground setPosition:CGPointAdd(foreground.position, CGPointMake(foreground.size.width *  kNumberOfForegrounds, 0))];
        }
    }];
}

#pragma mark - Obstacles
- (SKSpriteNode*)createObstacle
{
    SKSpriteNode *obstacle = [SKSpriteNode spriteNodeWithImageNamed:@"obstacle-weeds"];
    [obstacle setZPosition:LayerObstacle];
    [obstacle setName:@"Obstacle"];
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
    return obstacle;
}

- (void)startSpawningObstacles
{
    SKAction *firstDelay = [SKAction waitForDuration:kFirstObstacleSpawn];
    SKAction *spawn = [SKAction performSelector:@selector(spawnObstacle) onTarget:self];
    SKAction *regularDelay = [SKAction waitForDuration:kSubsequentObstacleSpawn];
    SKAction *spawnSequence = [SKAction sequence:@[spawn, regularDelay]];
    SKAction *foreverSpawnObstacles = [SKAction repeatActionForever:spawnSequence];
    SKAction *overallSequence = [SKAction sequence:@[firstDelay, foreverSpawnObstacles]];
    [self runAction:overallSequence withKey:@"Spawn"];
}

- (void)stopSpawningObstacles
{
    [self removeActionForKey:@"Spawn"];
    [_worldNode enumerateChildNodesWithName:@"Obstacle" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];

}

- (void)spawnObstacle
{
    SKSpriteNode *bottomObstacle = [self createObstacle];
    SKSpriteNode *topObstacle = [self createObstacle];
    
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
    [self stopSpawningObstacles];
    
    SKAction *deadAction = [SKAction setTexture:[SKTexture textureWithImageNamed:@"fish-dead"]];
    SKAction *rotateAction = [SKAction rotateByAngle:DegreesToRadians(180) duration:0.5];
    SKAction *moveToSurfaceAction = [SKAction moveToY:self.size.height - _fishyFishy.size.height/2 duration:1.5];
    SKAction *moveToSurfaceAction2 = [SKAction moveToY:self.size.height - _fishyFishy.size.height duration:0.5];
    SKAction *moveToSurfaceAction3 = [SKAction moveToY:self.size.height - _fishyFishy.size.height/2 duration:0.5];
    SKAction *sequence = [SKAction sequence:@[deadAction, rotateAction, moveToSurfaceAction, moveToSurfaceAction2, moveToSurfaceAction3]];
    [_fishyFishy runAction:sequence];

    [self setupScoreCard];
}

- (void)switchToFalling {
    _gameState = GameStateFalling;
    [self stopSpawningObstacles];
}

- (void)switchToNewGame
{
    SKScene *newScene = [[HFFScene alloc] initWithSize:self.size andDelegate:_delegate];
    SKTransition *transition = [SKTransition fadeWithColor:[SKColor blackColor] duration:0.5];
    [self.view presentScene:newScene transition:transition];
}

- (void)switchToGameOver {
    _gameState = GameStateGameOver;
}

- (void)switchToPlay {
    
    // Set state
    _gameState = GameStatePlay;
    
    // Remove tutorial
    [_worldNode enumerateChildNodesWithName:@"Tutorial" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
                                             [SKAction fadeOutWithDuration:0.5],
                                             [SKAction removeFromParent]
                                             ]]];
    }];
    
    // Remove wobble
    [_fishyFishy removeActionForKey:@"Wobble"];
    
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
    //    [self setupSounds];
    [self setupScore];
    
    
    [self flapFishy];
    [self flapFishy];
    [self setupTutorial];
}

#pragma mark - Kiip
- (void)showKiipRewardForNewHighScore
{
    NSString *momentName = @"Beating your best score!";

    if (![[NSUserDefaults standardUserDefaults] boolForKey:momentName])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:momentName];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [[Kiip sharedInstance] saveMoment:momentName withCompletionHandler:^(KPPoptart *poptart, NSError *error) {
            if (error)
            {
                NSLog([NSString stringWithFormat:@"Kiip error: %@", [error userInfo]]);
            }
            if (poptart)
            {
                [poptart show];
            }
            if (!poptart)
            {
                // handle logic when there is no reward to give.
            }
        }];
    }
}

- (void)showKiipRewardForObstacles
{
    NSString *momentName = @"";
    
    if ([self getScore] >= 1 && [self getScore] < 5)
    {
        momentName = @"Getting past 1 obstacle!";
    }
    else if ([self getScore] >= 5 && [self getScore] < 10)
    {
        momentName = @"Getting past 5 obstacles!";
    }
    else if ([self getScore] >= 10 && [self getScore] < 25)
    {
        momentName = @"Getting past 10 obstacles!";
    }
    else if ([self getScore] >= 25 && [self getScore] < 50)
    {
        momentName = @"Getting past 25 obstacles!";
    }
    else if ([self getScore] >= 50 && [self getScore] < 100)
    {
        momentName = @"Getting past 50 obstacles!";
    }
    else if ([self getScore] >= 100)
    {
        momentName = @"Getting past 100 or more obstacles!";
    }
    
    // No Kiip reward to give
    if ([momentName isEqualToString:@""])
        return;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:momentName])
    {
        // Update the user has been presented with this award already
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:momentName];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Get user the Kiip reward
        [[Kiip sharedInstance] saveMoment:momentName withCompletionHandler:^(KPPoptart *poptart, NSError *error) {
            if (error)
            {
                NSLog([NSString stringWithFormat:@"Kiip error: %@", [error userInfo]]);
            }
            if (poptart)
            {
                [poptart show];
            }
            if (!poptart)
            {
                // handle logic when there is no reward to give.
            }
        }];
    }
}

#pragma mark - Setup
- (void)setupScore
{
    _score = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    [_score setFontColor:[SKColor blackColor]];
    [_score setPosition:CGPointMake(self.size.width/2, self.size.height - kMargin)];
    [_score setText:@"0"];
    [_score setVerticalAlignmentMode:SKLabelVerticalAlignmentModeTop];
    [_score setZPosition:LayerUI];
    [_worldNode addChild:_score];
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
    
    [_worldNode addChild:background];
    
    CGPoint lowerLeft = CGPointMake(0, _playableStart);
    CGPoint lowerRight= CGPointMake(self.size.width, _playableStart);
    self.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:lowerLeft toPoint:lowerRight];
    self.physicsBody.categoryBitMask = EntityCategoryGround;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = EntityCategoryPlayer;
    
}

- (void)setupForeground
{
    for (int backgroundIndex = 0; backgroundIndex < kNumberOfForegrounds; backgroundIndex++)
    {
        SKSpriteNode *foreground = [[SKSpriteNode alloc] initWithImageNamed:@"foreground"];
        [foreground setAnchorPoint:CGPointMake(0.0, 1.0)];
        [foreground setPosition:CGPointMake( backgroundIndex * self.size.width, _playableStart)];
        [foreground setZPosition:LayerForeground];
        [foreground setName:@"Foreground"];
        [_worldNode addChild:foreground];
    }
}

- (void)setupFishyFishy
{
    _fishyFishy = [[SKSpriteNode alloc] initWithImageNamed:@"fish-0"];
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
}

- (void)setupScoreCard
{
    if ([self getScore] > [self getBestScore])
    {
        [self setBestScore];
        [self showKiipRewardForNewHighScore];
    }
    else
    {
        [self showKiipRewardForObstacles];
    }
    
    
    SKSpriteNode *scorecard = [SKSpriteNode spriteNodeWithImageNamed:@"scorecard"];
    scorecard.position = CGPointMake(self.size.width * 0.5, self.size.height/2);
    scorecard.name = @"Tutorial";
    scorecard.zPosition = LayerUI;
    [_worldNode addChild:scorecard];
    
    SKLabelNode *lastScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    lastScore.fontColor = [SKColor whiteColor];
    lastScore.position = CGPointMake(-scorecard.size.width * 0.25, -scorecard.size.height * 0.2);
    lastScore.text = [NSString stringWithFormat:@"%d", [self getScore]];
    [scorecard addChild:lastScore];
    
    SKLabelNode *bestScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    bestScore.fontColor = [SKColor whiteColor];
    bestScore.position = CGPointMake(scorecard.size.width * 0.25, -scorecard.size.height * 0.2);
    bestScore.text = [NSString stringWithFormat:@"%d", [self getBestScore]];
    [scorecard addChild:bestScore];
    
    SKSpriteNode *gameOver = [SKSpriteNode spriteNodeWithImageNamed:@"gameOver"];
    gameOver.position = CGPointMake(self.size.width/2, self.size.height/2 + scorecard.size.height/2 + kMargin + gameOver.size.height/2);
    gameOver.zPosition = LayerUI;
    [_worldNode addChild:gameOver];
    
    _okButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _okButton.position = CGPointMake(self.size.width * 0.25, self.size.height/2 - scorecard.size.height/2 - kMargin - _okButton.size.height/2);
    _okButton.zPosition = LayerUI;
    [_worldNode addChild:_okButton];
    
    SKSpriteNode *ok = [SKSpriteNode spriteNodeWithImageNamed:@"ok"];
    ok.position = CGPointZero;
    ok.zPosition = LayerUI;
    [_okButton addChild:ok];
    
    _shareButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _shareButton.position = CGPointMake(self.size.width * 0.75, self.size.height/2 - scorecard.size.height/2 - kMargin - _shareButton.size.height/2);
    _shareButton.zPosition = LayerUI;
    [_worldNode addChild:_shareButton];
    
    SKSpriteNode *share = [SKSpriteNode spriteNodeWithImageNamed:@"share"];
    share.position = CGPointZero;
    share.zPosition = LayerUI;
    [_shareButton addChild:share];
    
    _buyButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _buyButton.position = CGPointMake(self.size.width * 0.25, self.size.height/2 - scorecard.size.height/2 - 3.3 * kMargin - _buyButton.size.height/2);
    _buyButton.zPosition = LayerUI;
    [_worldNode addChild:_buyButton];
    
    SKSpriteNode *buy = [SKSpriteNode spriteNodeWithImageNamed:@"buy"];
    buy.position = CGPointZero;
    buy.zPosition = LayerUI;
    [_buyButton addChild:buy];

    _rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    _rateButton.position = CGPointMake(self.size.width * 0.75, self.size.height/2 - scorecard.size.height/2 - 3.3 * kMargin - _rateButton.size.height/2);
    _rateButton.zPosition = LayerUI;
    [_worldNode addChild:_rateButton];
    
    SKSpriteNode *rate = [SKSpriteNode spriteNodeWithImageNamed:@"rate"];
    rate.position = CGPointZero;
    rate.zPosition = LayerUI;
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
    
    scorecard.position = CGPointMake(self.size.width * 0.5, -scorecard.size.height/2);
    SKAction *moveTo = [SKAction moveTo:CGPointMake(self.size.width/2, self.size.height/2) duration:kAnimDelay];
    moveTo.timingMode = SKActionTimingEaseInEaseOut;
    [scorecard runAction:[SKAction sequence:@[
                                              [SKAction waitForDuration:kAnimDelay*2],
                                              moveTo
                                              ]]];
    
    _okButton.alpha = 0;
    _shareButton.alpha = 0;
    _rateButton.alpha = 0;
    _buyButton.alpha = 0;
    SKAction *fadeIn = [SKAction sequence:@[
                                            [SKAction waitForDuration:kAnimDelay*3],
                                            [SKAction fadeInWithDuration:kAnimDelay]
                                            ]];
    [_okButton runAction:fadeIn];
    [_shareButton runAction:fadeIn];
    [_rateButton runAction:fadeIn];
    [_buyButton runAction:fadeIn];
    SKAction *pops = [SKAction sequence:@[
//                                          [SKAction waitForDuration:kAnimDelay],
//                                          _popAction,
//                                          [SKAction waitForDuration:kAnimDelay],
//                                          _popAction,
//                                          [SKAction waitForDuration:kAnimDelay],
//                                          _popAction,
                                          [SKAction runBlock:^{
        [self switchToGameOver];
    }]
                                          ]];
    [self runAction:pops];
}

- (void)setupSounds
{
    _dingAction = [SKAction playSoundFileNamed:@"ding.wav" waitForCompletion:NO];
    _flapAction = [SKAction playSoundFileNamed:@"flap.wav" waitForCompletion:NO];
    _whackAction = [SKAction playSoundFileNamed:@"whack.wav" waitForCompletion:NO];
    _fallingAction = [SKAction playSoundFileNamed:@"fall.wav" waitForCompletion:NO];
    _hitGroundAction = [SKAction playSoundFileNamed:@"ground.wav" waitForCompletion:NO];
    _popAction = [SKAction playSoundFileNamed:@"pop.wav" waitForCompletion:NO];
    _coinAction = [SKAction playSoundFileNamed:@"coin.wav" waitForCompletion:NO];
}

- (void)setupTutorial
{
    SKSpriteNode *tutorial = [SKSpriteNode spriteNodeWithImageNamed:@"tap"];
    tutorial.position = CGPointMake((int)self.size.width * 0.5, _playableStart - _playableStart * 0.3
                                    );
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
    [[NSUserDefaults standardUserDefaults] setInteger:[self getScore] forKey:@"best_score"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reportScore:[self getScore] forLeaderboardID:@"com.traversoft.hff.highscores"];
}

- (NSInteger)getScore
{
    return _obstaclesPassed/2 ;
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
            NSLog([NSString stringWithFormat:@"Error reporting score %@", error.userInfo]);
        }
    }];
}


#pragma mark - Share Score
- (void)shareScore {
    
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8", 384800918]; //APP_STORE_ID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    UIImage *screenshot = [self.delegate screenshot];
    
    NSString *initialTextString = [NSString stringWithFormat:@"Yay!!! I scored %d points in Here Fishy Fishy!", [self getScore]];
    [self.delegate shareString:initialTextString url:url image:screenshot];
}


- (void)buyButtonTapped
{
    SKProduct *product = [[self.delegate getProducts] objectAtIndex:0]; // Only one IAP to buy  - Remove ads    
    
    if (product)
    {
        NSLog(@"Buying %@...", product.productIdentifier);
        [[HFFInAppPurchaseHelper sharedInstance] buyProduct:product];   
    }
}
@end

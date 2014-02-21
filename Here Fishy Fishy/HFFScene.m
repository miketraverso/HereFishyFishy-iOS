//
//  HFFScene.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 2/17/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "HFFScene.h"

typedef NS_ENUM(int, Layer) {
    LayerBackground,
    LayerObstacle,
    LayerForeground,
    LayerFishyFishy
};

typedef NS_OPTIONS(int, EntityCategory) {
    EntityCategoryPlayer = 1 << 0,
    EntityCategoryObstacle = 1 << 1,
    EntityCategoryGround = 1 << 2
};

static const int kNumberOfForegrounds = 2;
static const float kGravity = -1500.0;
static const float kImpulse = 300.0;
static const float kGroundSpeed = -150.0f;
static const float kGapMultiplier = 2.5;
static const float kBottomObstacleMinFraction = 0.1;
static const float kBottomObstacleMaxFraction = 0.6;
static const float kFirstObstacleSpawn = 1.75;
static const float kSubsequentObstacleSpawn = 1.5;

#define FISHY_MOVE_ANIM @[[SKTexture textureWithImageNamed:@"fish-0"],[SKTexture textureWithImageNamed:@"fish-1"],[SKTexture textureWithImageNamed:@"fish-0"]]

@implementation HFFScene
{
    SKNode *_worldNode;
    SKSpriteNode *_fishyFishy;
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
    
}

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        _worldNode = [SKNode node];
        [self addChild:_worldNode];
        
        [self setupBackground];
        [self setupForeground];
        //[self setupSounds];
        [self setupFishyFishy];
        [self startSpawningObstacles];
        
        [self.physicsWorld setContactDelegate:self];
        [self.physicsWorld setGravity:CGVectorMake(0, 0)];
        [self flapFishy];
        [self flapFishy];

        _gameState = GameStatePlay;
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
    switch (_gameState) {
        case GameStateMainMenu:
            break;
            
        case GameStatePlay:
            [self flapFishy];
            break;
            
        case GameStateShowingScore:
            [self switchToNewGame];
                break;
            
        case GameStateTutorial:
            break;
            
        case GameStateFalling:
            break;
            
        case GameStateGameOver:
            break;
            
        default:
            break;
    }
}


#pragma mark - Updates
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
        [_fishyFishy setZRotation:DegreesToRadians(180)];
        [_fishyFishy setPosition:CGPointMake(_fishyFishy.position.x, _playableStart + _fishyFishy.size.width/2)];
        [self switchScoreState];
    }
}

- (void)checkHitObstacle
{
    if (_hitObstacle)
    {
        _hitObstacle = NO;
        [self switchToFalling];
    }
}

- (void)switchScoreState
{
    _gameState = GameStateShowingScore;
    [_fishyFishy removeAllActions];
    [self stopSpawningObstacles];
}

- (void)switchToFalling {
    _gameState = GameStateFalling;
    [_fishyFishy removeAllActions];
    [self stopSpawningObstacles];
}

- (void)switchToNewGame
{
    SKScene *newScene = [[HFFScene alloc] initWithSize:self.size];
    SKTransition *transition = [SKTransition fadeWithColor:[SKColor blackColor] duration:0.5];
    [self.view presentScene:newScene transition:transition];
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
    SKSpriteNode *obstacle = [SKSpriteNode spriteNodeWithImageNamed:@"obstacle"];
    [obstacle setZPosition:LayerObstacle];
    [obstacle setName:@"Obstacle"];
    
    CGFloat offsetX = obstacle.frame.size.width * obstacle.anchorPoint.x;
    CGFloat offsetY = obstacle.frame.size.height * obstacle.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 39 - offsetX, 311 - offsetY);
    CGPathAddLineToPoint(path, NULL, 75 - offsetX, 300 - offsetY);
    CGPathAddLineToPoint(path, NULL, 80 - offsetX, 1 - offsetY);
    CGPathAddLineToPoint(path, NULL, 3 - offsetX, 1 - offsetY);
    CGPathAddLineToPoint(path, NULL, 4 - offsetX, 298 - offsetY);
    
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

#pragma mark - Setup
- (void)setupBackground
{
    SKSpriteNode *background = [[SKSpriteNode alloc] initWithImageNamed:@"background"];
    [background setAnchorPoint:CGPointMake(0.5, 1)];
    [background setPosition:CGPointMake(self.size.width/2, self.size.height)];
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
    [_fishyFishy setPosition:CGPointMake(self.size.width * 0.2, _playableHeight * 0.6 + _playableStart)];
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

@end

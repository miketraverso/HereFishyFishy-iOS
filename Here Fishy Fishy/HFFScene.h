//
//  HFFMyScene.h
//  Here Fishy Fishy
//

//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(int, GameState) {
    GameStateMainMenu,
    GameStateTutorial,
    GameStatePlay,
    GameStateFalling,
    GameStateShowingScore,
    GameStateGameOver
};

@interface HFFScene : SKScene<SKPhysicsContactDelegate>

@end

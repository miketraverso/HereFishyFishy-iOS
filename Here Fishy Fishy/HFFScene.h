//
//  HFFScene.h
//  Here Fishy Fishy
//

//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>


@protocol HFFSceneDelegate
- (UIImage *)screenshot;
- (void)shareString:(NSString *)string url:(NSURL*)url image:(UIImage *)screenshot;
- (NSArray*)getProducts;
- (SKProduct*)inAppPurchaseForProductId:(NSString*)productId;
@end


@interface HFFScene : SKScene<SKPhysicsContactDelegate, UIAlertViewDelegate>
-(id)initWithSize:(CGSize)size andDelegate:(id<HFFSceneDelegate>)delegate;
@property (strong, nonatomic) id<HFFSceneDelegate> hffSceneDelegate;

@end

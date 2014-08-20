//
//  HFFViewController.h
//  Here Fishy Fishy
//

//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <SKUtils/SKUtils.h>

@interface HFFViewController : UIViewController

- (SKProduct*)inAppPurchaseForProductId:(NSString*)productId;

@end

//
//  HFFAppDelegate.h
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 2/17/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameCenterManager.h"
//#import <KiipSDK/KiipSDK.h>
#import <M13OrderedDictionary.h>
#import "PurchasableFish.h"

@interface HFFAppDelegate : UIResponder <UIApplicationDelegate>//,KiipDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) GameCenterManager *gameCenterManager;
@property (strong, nonatomic) M13MutableOrderedDictionary *purchaseableItems;
@property (strong, nonatomic) PurchasableFish *selectedFish;
@end

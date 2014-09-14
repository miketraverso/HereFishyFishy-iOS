//
//  HFFViewController.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 2/17/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "HFFViewController.h"
#import "HFFScene.h"
#import <iAd/iAd.h>
#import "GameCenterManager.h"
#import <GameKit/GameKit.h>
#import "HFFInAppPurchaseHelper.h"

@interface HFFViewController () <HFFSceneDelegate, GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate, GameCenterManagerDelegate>
{
    GameCenterManager *gameCenterManager;
    NSArray *_products;
    __block BOOL _shouldShowAds;
}
@end

@implementation HFFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([GameCenterManager isGameCenterAvailable]) {
        
        gameCenterManager = [[GameCenterManager alloc] init];
        [gameCenterManager setDelegate:self];
        [gameCenterManager authenticateLocalUser];
    }
    else {
        
        // The current device does not support Game Center.
        
    }

    _products = nil;
    _shouldShowAds = YES;
    
    [[HFFInAppPurchaseHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success)
        {
            _products = products;
            for (SKProduct *product in products) {

                if ([[HFFInAppPurchaseHelper sharedInstance] productPurchased:[product productIdentifier]]) {
                    
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[product productIdentifier]];
                    
                    if ([[HFFInAppPurchaseHelper sharedInstance] productPurchased:@"com.traversoft.hff.no.ads"]) {

                        _shouldShowAds = NO;
                        self.canDisplayBannerAds = _shouldShowAds;
                        CLS_LOG(@"Not showing ads");
                    } else {
                        
                        _shouldShowAds = YES;
                        self.canDisplayBannerAds = _shouldShowAds;
                        CLS_LOG(@"Showing ads");
                    }

                    SKProduct *pro = [self inAppPurchaseForProductId:[product productIdentifier]];
                    if ( pro ) {
                        
                        if ([[HFFInAppPurchaseHelper sharedInstance] productPurchased:[pro productIdentifier]]) {
                            
                            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[pro productIdentifier]];
                        }
                        else {
                            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[pro productIdentifier]];
                        }
                    }
                }
            }
        }
    }];
    [[NSUserDefaults standardUserDefaults] synchronize];

    
    // Configure the view.
    SKView * skView = (SKView *)self.view;
//    skView.showsFPS = YES;
//    skView.showsNodeCount = YES;
    
    SKScene *scene = [[HFFScene alloc] initWithSize:skView.bounds.size andDelegate:self];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    self.canDisplayBannerAds = YES;
    [skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)shareString:(NSString *)string url:(NSURL*)url image:(UIImage *)image
{
    UIActivityViewController *vc = [[UIActivityViewController alloc]
                                    initWithActivityItems:@[string, url, image]
                                    applicationActivities:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (UIImage *)screenshot
{
    CLS_LOG(@"Taking screenshot");

    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 1.0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (NSArray*)getProducts
{
    return _products;
}

- (SKProduct*)inAppPurchaseForProductId:(NSString*)productId {
    
    for (SKProduct *product in  [self getProducts]) {
        if (product) {
            if ([[[product productIdentifier] lowercaseString] isEqualToString: productId])
            {
                return product;
            }
        }
    }
    return nil;
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
    
}

- (void) processGameCenterAuth: (NSError*) error
{
	if (error)
//	{
//		[gameCenterManager reloadHighScoresForCategory: self.currentLeaderBoard];
//	}
//	else
	{
        CLS_LOG(@"Error processing game center auth :: %@", error);

		UIAlertView* alert= [[UIAlertView alloc] initWithTitle: @"Game Center Account Required"
                                                        message: [NSString stringWithFormat: @"Reason: %@", [error localizedDescription]]
                                                       delegate: self cancelButtonTitle: @"Try Again..." otherButtonTitles: nil];
		[alert show];
	}
	
}


@end

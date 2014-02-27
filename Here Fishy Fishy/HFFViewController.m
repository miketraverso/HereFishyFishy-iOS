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
        
        
    } else {
        
        // The current device does not support Game Center.
        
    }

    _products = nil;
    _shouldShowAds = YES;
    
    [[HFFInAppPurchaseHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success)
        {
            _products = products;
            if ([[HFFInAppPurchaseHelper sharedInstance] productPurchased:@"com.traversoft.hff.noads"])
            {
                _shouldShowAds = NO;
                self.canDisplayBannerAds = _shouldShowAds;
            }
            else
            {
                _shouldShowAds = YES;
                self.canDisplayBannerAds = _shouldShowAds;
            }
        }
    }];
    
    
    // Configure the view.
    SKView * skView = (SKView *)self.view;
//    skView.showsFPS = YES;
//    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    SKScene *scene = [[HFFScene alloc] initWithSize:skView.bounds.size andDelegate:self];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    self.canDisplayBannerAds = YES;
    // Present the scene.
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
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 1.0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (NSArray*)getProducts
{
    return _products;
}


- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
    
}

@end

//
//  HFFAppDelegate.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 2/17/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "HFFAppDelegate.h"
#import "HFFInAppPurchaseHelper.h"

@implementation HFFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [HFFInAppPurchaseHelper sharedInstance];
    [self restorePurchases];
    
//    Kiip *kiip = [[Kiip alloc] initWithAppKey:@"467748b0b19978c496eb7bf8ae4f4b3c" andSecret:@"34275e8cbdf01b74cf3e58bb924b4d19"];
//    kiip.delegate = self;
//    [Kiip setSharedInstance:kiip];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self restorePurchases];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)restorePurchases
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"restoreAllPurchases"])
    {
        BOOL shouldRestore = [[NSUserDefaults standardUserDefaults] boolForKey:@"restoreAllPurchases"];
        
        if (shouldRestore)
            [[HFFInAppPurchaseHelper sharedInstance] restoreCompletedTransactions];
    }
}
@end

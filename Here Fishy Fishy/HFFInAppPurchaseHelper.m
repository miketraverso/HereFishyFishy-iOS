//
//  HFFInAppPurchaseHelper.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 2/25/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "HFFInAppPurchaseHelper.h"

@implementation HFFInAppPurchaseHelper

+ (HFFInAppPurchaseHelper *)sharedInstance
{
    static dispatch_once_t once;
    static HFFInAppPurchaseHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      @"com.traversoft.hff.noads",
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end

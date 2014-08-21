//
//  HFFInAppPurchaseHelper.m
//  Here Fishy Fishy
//
//  Created by Michael R Traverso on 2/25/14.
//  Copyright (c) 2014 traversoft. All rights reserved.
//

#import "InAppPurchaseHelper.h"

#import <StoreKit/StoreKit.h>

@interface InAppPurchaseHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";

@implementation InAppPurchaseHelper
{
    SKProductsRequest * _productsRequest;
    RequestProductsCompletionHandler _completionHandler;
    NSSet * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
}

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers
{
    if ((self = [super init]))
    {
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers)
        {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased)
            {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                NSLog(@"Previously purchased: %@", productIdentifier);
            }
            else
            {
                NSLog(@"Not purchased: %@", productIdentifier);
            }
        }
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }

    return self;
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler
{
    _completionHandler = [completionHandler copy];
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    
    NSLog(@"Loaded list of products...");
    _productsRequest = nil;
    
    NSArray * skProducts = response.products;
    for (SKProduct * skProduct in skProducts)
    {
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Failed to load list of products.");
    _productsRequest = nil;
    _completionHandler(NO, nil);
    _completionHandler = nil;
}

- (BOOL)productPurchased:(NSString *)productIdentifier {
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)buyProduct:(SKProduct *)product
{
    
    NSLog(@"Buying %@...", product.productIdentifier);
    
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"Received restored transactions: %lu", (unsigned long)queue.transactions.count);
    NSMutableArray *restoredTransactions = [[NSMutableArray alloc] init];
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        [self restoreTransaction:transaction];
        
        NSLog(@"Restored Transaction... %@", transaction.originalTransaction.payment.productIdentifier);
        if (![transaction.originalTransaction.payment.productIdentifier isEqualToString:@"com.traversoft.hff.no.ads"]) {

            [restoredTransactions addObject:transaction.originalTransaction.payment.productIdentifier];
        }
    }

    NSDictionary* userInfo = @{@"productIdentifiers": restoredTransactions };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreCompleteFinished" object:nil userInfo:userInfo];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    CLSNSLog(@"Restored Transaction Failed...");
    CLSNSLog(@"Error %@", [error userInfo]);
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"completeTransaction...");
    
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TransactionCompleted" object:nil];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if ([transaction.originalTransaction.payment.productIdentifier isEqualToString:@"com.traversoft.hff.no.ads"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreTransactionSuccessful" object:nil userInfo:nil];
    }
    else {
        NSDictionary* userInfo = @{@"productIdentifier": transaction.originalTransaction.payment.productIdentifier };
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:transaction.originalTransaction.payment.productIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreTransactionSuccessful" object:nil userInfo:userInfo];
    }
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{    
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreTransactionFailed" object:nil];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    NSDictionary* userInfo = @{@"productIdentifier": productIdentifier };
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TransactionCompletedWithProductIdentifier" object:nil userInfo:userInfo];
    
}

- (void)restoreCompletedTransactions
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end

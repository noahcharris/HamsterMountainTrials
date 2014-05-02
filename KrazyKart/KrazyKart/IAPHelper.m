//
//  IAPHelper.m
//
//
//



/*
 
 THE PRODUCT IDs AND NOTIFICATION CALLS TO THE PURCHASE HANDLERS ARE BOTH IN THIS CLASS
 
 */

#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>   //import the store kit

NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";


@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver> //implement the protocol for receiving store messages
@end

@implementation IAPHelper




+ (IAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static IAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      @"com.noahharris.hamstermountainrun.removeads",
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}


- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                NSLog(@"Previously purchased: %@", productIdentifier);
            } else {
                NSLog(@"Not purchased: %@", productIdentifier);
            }
        }
        
    }
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    return self;
}



- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    
    NSLog(@"requesting products...");
    _completionHandler = [completionHandler copy];
    
    
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
    
}



- (BOOL)productPurchased:(NSString *)productIdentifier {
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}



- (void)buyProduct:(SKProduct *)product {
    
    NSLog(@"Buying %@...", product.productIdentifier);
    
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

/*
 - (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
 
 [_purchasedProductIdentifiers addObject:productIdentifier];
 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
 [[NSUserDefaults standardUserDefaults] synchronize];
 [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
 
 }
 */







#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSLog(@"Loaded list of products...");
    _productsRequest = nil;
    
    NSArray * skProducts = response.products;
    for (SKProduct * skProduct in skProducts) {
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"Failed to load list of products.");
    NSLog(@"%@", error);
    _productsRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
    
}








#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
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


- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}





- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"completeTransaction...");
    
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:transaction forKey:@"transaction"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"productBought" object:self userInfo:dataDict];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restoreTransaction...");
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:transaction forKey:@"transaction"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"productBought" object:self userInfo:dataDict];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}






/*
 -(void) dealloc {
 [super dealloc];
 [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
 }
 */


@end
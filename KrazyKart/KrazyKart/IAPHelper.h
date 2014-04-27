//
//  IAPHelper.h
//
//

#import <StoreKit/StoreKit.h>
UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface IAPHelper : NSObject {
    
    SKProductsRequest * _productsRequest;   //keep a copy of the request object on hand
    
    RequestProductsCompletionHandler _completionHandler;    // the handler
    NSSet * _productIdentifiers;                            //keep a list of identifiers passed in
    NSMutableSet * _purchasedProductIdentifiers;            //previously purchased identifiers
    
}

+ (IAPHelper*)sharedInstance;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;
- (void)restoreCompletedTransactions;

@end
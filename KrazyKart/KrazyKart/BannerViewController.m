//
//  BannerViewController.m
//  Hamster Mountain Trials


#import <iAd/iAd.h>

#import "BannerViewController.h"
#import "cocos2d.h"

@implementation BannerViewController

@synthesize iAdBannerView;

@synthesize gAdBannerView;




-(void)initiAdBanner
{
    if (!self.iAdBannerView)
    {
                                    //self.view.frame.size.height
        CGRect rect = CGRectMake(0, 0 , 0, 0);
        self.iAdBannerView = [[ADBannerView alloc] initWithFrame:rect];
        
        //self.iAdBannerView = [[ADBannerView alloc] initWithFrame:CGRectZero];
        [self.iAdBannerView setRequiredContentSizeIdentifiers:[NSSet setWithObjects:
                                                               //       ADBannerContentSizeIdentifier320x50,
                                                               ADBannerContentSizeIdentifierLandscape, nil]];
        
        self.iAdBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
        
        
        self.iAdBannerView.delegate = self;
        self.iAdBannerView.hidden = TRUE;
        [self.view addSubview:self.iAdBannerView];
        [self hideBanner:iAdBannerView];
    }
}

-(void)initgAdBanner
{
    //janky
    BOOL IS_IPAD = false;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        IS_IPAD = true;
    }
    else
    {
        IS_IPAD = false;
    }

    
    if (!self.gAdBannerView)
    {
        CGPoint origin = CGPointMake(0.0,
                                     self.view.frame.size.height);
        
        self.gAdBannerView = [[[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner
                                                             origin:origin]
                              autorelease];
        if (IS_IPAD)
        {
            self.gAdBannerView.adUnitID = @"a1511abac90ecda";
        } else {
            self.gAdBannerView.adUnitID = @"a1511abb4509b21";
        }
        self.gAdBannerView.rootViewController = self;
        self.gAdBannerView.delegate = self;
        self.gAdBannerView.hidden = TRUE;
        [self.view addSubview:self.gAdBannerView];
    }
}


-(void)hideBanner:(UIView *)banner
{
    if (banner && !banner.hidden)
    {
        [UIView beginAnimations:@"hideBanner" context:nil];
        banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height);
        [UIView commitAnimations];
        banner.hidden = TRUE;
        
    }
}

-(void)showBanner:(UIView *)banner
{
    
    //janky
    BOOL IS_IPAD = false;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        IS_IPAD = true;
    }
    else
    {
        IS_IPAD = false;
    }
    
    if (banner && banner.hidden)
    {
        if (IS_IPAD)
        {
            bannerWidth = 1024;
            bannerHeight = 66;
        }
        else
        {
            bannerWidth = 480;
            bannerHeight = 32;
        }
        
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [UIView beginAnimations:@"showBanner" context:nil];
                                    //winSize.height-bannerHeight
        banner.frame = CGRectMake(0, 24, bannerWidth, bannerHeight);
        //banner.frame = CGRectOffset(banner.frame, 0, -bannerHeight);
        [UIView commitAnimations];
        banner.hidden = FALSE;
    }
}



// iAd delegate methods

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    
    NSLog(@"iAd load...");
    [self showBanner:iAdBannerView];  //new method
    [self hideBanner:gAdBannerView];
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error;
{
    NSLog(@"iAdError, %@", error);
    [self hideBanner:iAdBannerView];
    NSLog(@"Requesting ad from admob");
    [self.gAdBannerView loadRequest:[GADRequest request]];
}



// AdMob delegate methods

- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    NSLog(@"Admob load");
    [self hideBanner:self.iAdBannerView];
    [self showBanner:self.gAdBannerView];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    NSLog(@"Admob error: %@", error);
    [self hideBanner:self.gAdBannerView];
}









#pragma mark - old methods
/*
 
 - (void)viewDidLoad {
 
 [super viewDidLoad];
 
 if ([[NSUserDefaults standardUserDefaults] objectForKey:@"removedAds"] != nil)
 return;
 
 if (IS_IPAD)
 {
 bannerWidth = 1024;
 bannerHeight = 66;
 }
 else
 {
 bannerWidth = 480;
 bannerHeight = 32;
 }
 
 
 
 self.iAdBannerView = [[ADBannerView alloc] initWithFrame:CGRectZero];
 [self.iAdBannerView setRequiredContentSizeIdentifiers:[NSSet setWithObjects:
 //       ADBannerContentSizeIdentifier320x50,
 ADBannerContentSizeIdentifierLandscape, nil]];
 
 self.iAdBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
 
 [self.iAdBannerView setDelegate:self];
 
 [self.view addSubview:self.iAdBannerView];
 [self moveBannerOffScreen];
 
 
 }
 
 
 -(void)moveBannerOnScreen
 {
 CGSize windowSize = [[CCDirector sharedDirector] winSize];
 
 [UIView beginAnimations:@"BannerViewIntro" context:NULL];
 
 self.iAdBannerView.frame = CGRectMake(0, windowSize.height-bannerHeight, bannerWidth, bannerHeight);
 [UIView commitAnimations];
 }
 
 -(void)moveBannerOffScreen
 {
 CGSize windowSize = [[CCDirector sharedDirector] winSize];
 
 self.iAdBannerView.frame = CGRectMake(0, windowSize.height, bannerWidth, bannerHeight);
 
 }
 
 
 
 
 
 -(void)bannerViewDidLoadAd:(ADBannerView *)banner  //old method
 {
 NSLog(@"bannerViewDidLoadAd");
 
 [self moveBannerOnScreen];
 }
 
 
 
 -(void)onExit
 {
 [self.iAdBannerView setDelegate:nil];
 }
 
 */

@end

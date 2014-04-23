//
//  BannerViewController.h
//  Hamster Mountain Trials

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#import <iAd/iAd.h>
#import "GADBannerView.h"

@interface BannerViewController  : UIViewController <ADBannerViewDelegate, GADBannerViewDelegate>
{
    ADBannerView *iAdBannerView;
    GADBannerView *gAdBannerView;
    float bannerWidth;
    float bannerHeight;
}

@property (nonatomic,retain) ADBannerView *iAdBannerView;
@property (nonatomic, retain) GADBannerView *gAdBannerView;


//oldmethods
-(void)moveBannerOffScreen;
-(void)moveBannerOnScreen;
-(void)onExit;

//new methods
-(void)initiAdBanner;
-(void)initgAdBanner;
-(void)showBanner:(UIView *)banner;
-(void)hideBanner:(UIView *)banner;

//iAd delegate methods
-(void)bannerViewWillLoadAd:(ADBannerView *)banner;
-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error;

//AdMob delegate methods
-(void)adViewDidReceiveAd:(GADBannerView *)view;
-(void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error;




@end

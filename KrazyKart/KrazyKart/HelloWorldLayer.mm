//
//  HelloWorldLayer.mm
//  KrazyKart
//
//  Created by Noah Harris on 4/18/14.
//  Copyright __MyCompanyName__ 2014. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#include <iostream>


enum {
	kTagParentNode = 1,
};

    
#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()
-(void) createNewHamster;
-(void) drawStartingArea;
-(void) checkAndDrawNextColumn;
-(void) checkAndRemoveColumns;
-(void) tick:(ccTime)dt;
-(void) runAnimation;
-(void) kick1;
-(void) kick2;



@end

@implementation HelloWorldLayer





+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
    HelloWorldLayer *layer = [HelloWorldLayer node];
    [scene addChild:layer];
    return scene;
}




// ###############################
// ###### IN APP PURCHASES #######
// ###############################

-(void) handlePurchases {
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(receiveProducts:)
     name:@"productsReceived"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(provideProducts:)
     name:@"productBought"
     object:nil];
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"removedAds"] == nil) {
        
        adsRemoved = false;
        //IN APP PURCHASES
        
        _helper = [IAPHelper sharedInstance];      //create an instance of our in-app purchase helper
        
        //ask for products
        [_helper requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
            if (success) {

                NSDictionary *dataDict = [NSDictionary dictionaryWithObject:products forKey:@"productsList"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"productsReceived" object:self userInfo:dataDict];
            } else {
                //??
            }
        }];
        
        
        //check to restore completed transactions
        //[_helper restoreCompletedTransactions];
        
        
    } else {
        adsRemoved = true;
    }
    
    
}

-(void)receiveProducts:(NSNotification *)note {
    
    NSDictionary *theData = [note userInfo];
    _products = [[NSMutableArray alloc] initWithArray:[theData objectForKey:@"productsList"]];
    if ([_products count] != 0) {
        NSLog(@"SK product objects stored");
        _removeAds = [_products objectAtIndex:0];
        
        
        //#########
        showRemoveAdsButton = true;
        //##########
        
        
        
    }
    NSLog(@"no product objects to store");
    NSLog(_removeAds.productIdentifier);
    
}

// ##########  THIS IS WHERE THE PRODUCTS ARE ACTUALLY PROVIDED TO THE USER ################

-(void)provideProducts:(NSNotification *)note {
    NSDictionary *theData = [note userInfo];
    SKPaymentTransaction *transaction = [theData objectForKey:@"transaction"];
    NSLog(@"Attempting to provide products..");
    NSLog(transaction.originalTransaction.payment.productIdentifier);
    if ([transaction.originalTransaction.payment.productIdentifier isEqualToString:@"removeads"]) {
        
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"removedAds"];
        
        adsRemoved = true;
        showRemoveAdsButton = false;
        [_banner stop];
        
    }
//    if ([transaction.originalTransaction.payment.productIdentifier isEqualToString:@"drawingPack"]) {
//        [self onBoughtDrawingPack];
//    }
    
}


// ###############################
// ###############################
// ###############################





-(id) init
{
	if( (self=[super init])) {
        
        
        [self handlePurchases];

        
        //AD CONTROLLER INITIALIZATION
        if (!adsRemoved) {
            _banner = [[BannerViewController alloc] init];
            [_banner initiAdBanner];
            [_banner initgAdBanner];
            [[CCDirector sharedDirector].openGLView addSubview:_banner.view];
        }
        
        //load numberSpriteSheet (when removing this be sure to load from files not sprite frames when scorekeeping
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"numberSheet.plist"];
        
        numberSprites = [CCSpriteBatchNode batchNodeWithFile:@"numberSheet.png"];
        
        starting = true;
        
        //!!!!!!!!! FOR TESTING !!!!!!!
        //showRemoveAdsButton = false;
        
        
        //variables
        kick1x = 0;
        kick2x = 0;
        kick1y = 18.3;
        kick2y = 6;

        //0.5 for iphone
        scaling = 1.0;
        //negative is forward for these two values
        //45
        torque = -55;
        topSpeed = -12.5;
        
        //0.14
        bounce = 0.14;
        
        
        gravity1 = b2Vec2(0.0f, -11.3f);
        gravity2 = b2Vec2(0.0f, -8.0f);
        
        hamsterStartX = 6.25;
        hamsterStartY = 26;
        
        
        lastColumnCornerDistance = 10;
        lastColumnCornerHeight = 1 + screenOffsetY;
        lastPlatformNumber = 11;
        
        platformNumber = 0;
        
        
        //check for ipad
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            isiPhone = false;
        }
        else
        {
            isiPhone = true;
        }
        
        NSLog(@"HEIGHT OF THE MAIN SCREEN %f", [UIScreen mainScreen].bounds.size.height);
        
        //check phone version ( I DON'T THINK THIS IS WORKING )
        if (isiPhone) {
            if([UIScreen mainScreen].bounds.size.height == 568){
                isiPhone5 = true;
                NSLog(@"IPHONE 5");
            } else{
                isiPhone5 = false;
            }
            
        }
        
        //check retina
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0)) {
            isRetina = true;
        } else {
            isRetina = false;
        }
        
        
        
        // ####### DEVICE IDENTIFICATION LOGIC #########
        if (!isiPhone) {
            if (isRetina) {
                
                //TODO IPAD RETINA
                NSLog(@"ipad retina");
                scaling = 1.0f;
                screenOffsetX = 305;
                screenOffsetY = 4;
                
                backgroundOffsetX = -10;
                
                scoreColumn1X1 = 6;
                scoreColumn2X1 = 7;
                scoreColumn3X1 = 8;
                
                scoreColumn1Y1 = 16;
                scoreColumn2Y1 = 16;
                scoreColumn3Y1 = 16;
                
                scoreColumn1X2 = -4.5;
                scoreColumn2X2 = -3.5;
                scoreColumn3X2 = -2.5;
                
                scoreColumn1Y2 = 14;
                scoreColumn2Y2 = 14;
                scoreColumn3Y2 = 14;
                
                scorePrefixX = -4.5;
                scorePrefixY = 16;
                
                highScoreColumn1X = 17.5;
                highScoreColumn2X = 18.5;
                highScoreColumn3X = 19.5;
                
                highScoreColumn1Y = 14;
                highScoreColumn2Y = 14;
                highScoreColumn3Y = 14;
                
                highScorePrefixX = 18;
                highScorePrefixY = 16;
                
                instructionsX = 6;
                instructionsY = 10;
                
                restartX1 = -1;
                restartY1 = 5;
                
                restartX2 = 6;
                restartY2 = 5;
                
                removeAdsX = 13;
                removeAdsY = 5;
                
            } else {
                //TODO IPAD ORIGINAL
                NSLog(@"ipad original");
                scaling = 1.0f;
                screenOffsetX = 200;
                screenOffsetY = 4;
                
                backgroundOffsetX = -5;
                
                scoreColumn1X1 = 9.5;
                scoreColumn2X1 = 10.5;
                scoreColumn3X1 = 11.5;
                
                scoreColumn1Y1 = 16;
                scoreColumn2Y1 = 16;
                scoreColumn3Y1 = 16;
                
                scoreColumn1X2 = 0;
                scoreColumn2X2 = 1;
                scoreColumn3X2 = 2;
                
                scoreColumn1Y2 = 14;
                scoreColumn2Y2 = 14;
                scoreColumn3Y2 = 14;
                
                scorePrefixX = 0;
                scorePrefixY = 16;
                
                highScoreColumn1X = 20.5;
                highScoreColumn2X = 21.5;
                highScoreColumn3X = 22.5;
                
                highScoreColumn1Y = 14;
                highScoreColumn2Y = 14;
                highScoreColumn3Y = 14;
                
                highScorePrefixX = 21;
                highScorePrefixY = 16;
                
                instructionsX = 10;
                instructionsY = 11.5;
                
                restartX1 = 2;
                restartY1 = 5;
                
                restartX2 = 10;
                restartY2 = 5;
                
                removeAdsX = 17;
                removeAdsY = 5;
                
            }
        } else {
            if (isRetina) {
                
                if (isiPhone5) {
                    NSLog(@"4 inch retina iphone");
                    scaling = 0.5f;
                    screenOffsetX  = -30;
                    screenOffsetY = -1;
                    
                    backgroundOffsetX = 2;
                    
                    scoreColumn1X1 = 10.4;
                    scoreColumn2X1 = 11.4;
                    scoreColumn3X1 = 12.4;
                    
                    scoreColumn1X2 = 0.8;
                    scoreColumn2X2 = 1.8;
                    scoreColumn3X2 = 2.8;
                    
                    scoreColumn1Y1 = 10;
                    scoreColumn2Y1 = 10;
                    scoreColumn3Y1 = 10;
                    
                    scoreColumn1Y2 = 8;
                    scoreColumn2Y2 = 8;
                    scoreColumn3Y2 = 8;
                    
                    scorePrefixX = 0.8;
                    scorePrefixY = 10;
                    
                    highScoreColumn1X = 20.5;
                    highScoreColumn2X = 21.5;
                    highScoreColumn3X = 22.5;
                    
                    highScoreColumn1Y = 8;
                    highScoreColumn2Y = 8;
                    highScoreColumn3Y = 8;
                    
                    highScorePrefixX = 21;
                    highScorePrefixY = 10;
                    
                    instructionsX = 10.5;
                    instructionsY = 5;
                    
                    restartX1 = 4.2;
                    restartY1 = 0;
                    
                    restartX2 = 10.5;
                    restartY2 = 0;
                    
                    removeAdsX = 17;
                    removeAdsY = 0;

                    
                } else {
                    
                    //TODO IPHONE RETINA 3.5 inch
                    NSLog(@"3.5-inch iphone retina");
                    scaling = 0.5f;
                    screenOffsetX  = -30;
                    screenOffsetY = -1;
                    
                    backgroundOffsetX = 2;
                    
                    scoreColumn1X1 = 9.3;
                    scoreColumn2X1 = 10.3;
                    scoreColumn3X1 = 11.3;
                    
                    scoreColumn1X2 = -0.7;
                    scoreColumn2X2 = 0.3;
                    scoreColumn3X2 = 1.3;
                    
                    scoreColumn1Y1 = 10;
                    scoreColumn2Y1 = 10;
                    scoreColumn3Y1 = 10;
                    
                    scoreColumn1Y2 = 8;
                    scoreColumn2Y2 = 8;
                    scoreColumn3Y2 = 8;
                    
                    scorePrefixX = -0.7;
                    scorePrefixY = 10;
                    
                    highScoreColumn1X = 19;
                    highScoreColumn2X = 20;
                    highScoreColumn3X = 21;
                    
                    highScoreColumn1Y = 8;
                    highScoreColumn2Y = 8;
                    highScoreColumn3Y = 8;
                    
                    highScorePrefixX = 19.5;
                    highScorePrefixY = 10;
                    
                    instructionsX = 9;
                    instructionsY = 5;
                    
                    restartX1 = 2.7;
                    restartY1 = 0;
                    
                    restartX2 = 9;
                    restartY2 = 0;
                    
                    removeAdsX = 15.5;
                    removeAdsY = 0;
                }
                
                
            } else {
             
                //TODO ORIGINAL IPHONE
                NSLog(@"original iphone");
                scaling = 0.5f;
                screenOffsetX  = 10;
                screenOffsetY = -1;
                
                backgroundOffsetX = 2;
                
                scoreColumn1X1 = 6.3;
                scoreColumn2X1 = 7.3;
                scoreColumn3X1 = 8.3;
                
                scoreColumn1X2 = -3.5;
                scoreColumn2X2 = -2.5;
                scoreColumn3X2 = -1.5;
                
                scoreColumn1Y1 = 10;
                scoreColumn2Y1 = 10;
                scoreColumn3Y1 = 10;
                
                scoreColumn1Y2 = 8;
                scoreColumn2Y2 = 8;
                scoreColumn3Y2 = 8;
                
                scorePrefixX = -3.7;
                scorePrefixY = 10;
                
                highScoreColumn1X = 17;
                highScoreColumn2X = 18;
                highScoreColumn3X = 19;
                
                highScoreColumn1Y = 8;
                highScoreColumn2Y = 8;
                highScoreColumn3Y = 8;
                
                highScorePrefixX = 17.5;
                highScorePrefixY = 10;
                
                instructionsX = 6;
                instructionsY = 5;
                
                restartX1 = -0.3;
                restartY1 = 0;
                
                restartX2 = 6;
                restartY2 = 0;
    
                removeAdsX = 12.8;
                removeAdsY = 0;
            }
        }
        
        
        scoreColumn1X = scoreColumn1X1;
        scoreColumn2X = scoreColumn2X1;
        scoreColumn3X = scoreColumn3X1;
        
        scoreColumn1Y = scoreColumn1Y1;
        scoreColumn2Y = scoreColumn2Y1;
        scoreColumn3Y = scoreColumn3Y1;
        
        
        
        
        //for testing
        //[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"highScore"];
        
        self.isTouchEnabled = YES;
		CGSize winSize = [CCDirector sharedDirector].winSize;
        
        //scorekeeping
        score = 0;
        score_queue = new std::queue<int>();
        score_queue->push(2);
        
        //draw background
        if (isRetina) {
            _background = [CCSprite spriteWithFile:@"background.png"];
            _background.position = ccp(winSize.width/(2), winSize.height/(2));
            [self addChild:_background];
        } else {
            _background = [CCSprite spriteWithFile:@"NRbackground.png"];
            _background.position = ccp(winSize.width/(2), winSize.height/(2));
            [self addChild:_background];
        }
        
        //INITALIZE SCORE TO ZERO
        if (isRetina) {
            scoreColumn1 = [CCSprite spriteWithFile:@"number0.png"];
        } else {
            scoreColumn1 = [CCSprite spriteWithFile:@"NRnumber0.png"];
        }
        [self addChild:scoreColumn1 z:11];
        
        // Create a world
        _world = new b2World(gravity1);
        
        //contact listener
        contactListener = new MyContactListener;
        
        _world->SetContactListener(contactListener);
        
//        //DEBUG DRAWING
//        m_debugDraw = new GLESDebugDraw(PTM_RATIO);
//		_world->SetDebugDraw(m_debugDraw);
//		uint32 flags = 0;
//		flags += b2Draw::e_shapeBit;
//		m_debugDraw->SetFlags(flags);
        
        id zoomOut = [CCScaleTo actionWithDuration:0.0f scale:scaling];
        [self runAction:zoomOut];
        
        //[self createNewHamster];
        //[self drawStartingArea];
        
        [self gameOver];
        [self schedule:@selector(tick:)];
        
        //will need this if number of platforms gets out of hand
        //[self schedule:@selector(checkAndRemoveColumns) interval:3.0];
        
	}
	return self;
}


- (void)tick:(ccTime) dt {
    
    _world->Step(dt, 10, 10);
    
    //update hamster sprites
    if (!gameOver) {
        _ball.position = ccp(_body->GetPosition().x * PTM_RATIO,
                             _body->GetPosition().y * PTM_RATIO);
        _ball.rotation = -1 * CC_RADIANS_TO_DEGREES(_body->GetAngle());
        
        _lines.position = ccp(_body->GetPosition().x * PTM_RATIO,
                              _body->GetPosition().y * PTM_RATIO);
        _lines.rotation = -1 * CC_RADIANS_TO_DEGREES(_body->GetAngle());
        
        _shading.position = ccp(_body->GetPosition().x * PTM_RATIO,
                                _body->GetPosition().y * PTM_RATIO);
        //hamster
        _hamster.position = ccp(_body->GetPosition().x * PTM_RATIO,
                                _body->GetPosition().y * PTM_RATIO);
    }
    
    
    //acceleration
    if (!gameOver) {
        if (_body->GetAngularVelocity() > topSpeed) {
            
            _body->ApplyTorque(torque);
        }
    }

    
    //scroll screen
    b2Vec2 pos;
    if (!gameOver) {
        pos = _body->GetPosition();                  //110
    }
    if (gameOver) {
        //why the fuck is it 5.4 and not 6.25???
        pos.x = 5.4;
    }
	CGPoint newPos = ccp(-1 * pos.x * PTM_RATIO * scaling + screenOffsetX, self.position.y * PTM_RATIO);
	[self setPosition:newPos];
    
    //scroll background
    CGSize winSize = [CCDirector sharedDirector].winSize;
    _background.position = ccp(pos.x * PTM_RATIO + winSize.width/(2) + backgroundOffsetX * PTM_RATIO, self.position.y * PTM_RATIO + winSize.height/(2));
    
    
    //starting screen (gameover) stuff
    if (gameOver) {
        instructions.position = ccp(pos.x * PTM_RATIO + instructionsX * PTM_RATIO, instructionsY * PTM_RATIO);
        highScorePrefixLabel.position = ccp(pos.x * PTM_RATIO + highScorePrefixX * PTM_RATIO, highScorePrefixY * PTM_RATIO);
        _restartButton.position = ccp(pos.x * PTM_RATIO + restartX * PTM_RATIO, self.position.y * PTM_RATIO + restartY * PTM_RATIO);
        scorePrefix.position = ccp(pos.x * PTM_RATIO + scorePrefixX * PTM_RATIO, self.position.y * PTM_RATIO + scorePrefixY * PTM_RATIO);
        
        if (showRemoveAdsButton) {
            _removeAdsButton.position = ccp(pos.x * PTM_RATIO + removeAdsX * PTM_RATIO, self.position.y * PTM_RATIO + removeAdsY * PTM_RATIO);
        }
    }
    
    //drawing more columns
    if (!gameOver) {
        if ((pos.x + 50) > lastColumnCornerDistance) {
            [self drawNextColumn];
        }
    }
    
    //game over detection
    if (pos.y < -10) {
        if (!gameOver) {
            [self gameOver];
        }
    }
    
    
    
    //########################################
    //############# SCOREKEEPING #############
    //########################################
    
    
    if (!score_queue->empty() && score_queue->front() < pos.x) {
        score_queue->pop();
        if (!gameOver) {
            if (score < 999) {
                score ++;
            }
            
            [self removeChild:scoreColumn1 cleanup:YES];
            [self removeChild:scoreColumn2 cleanup:YES];
            [self removeChild:scoreColumn3 cleanup:YES];
            
            if (isRetina ) {
                
                if (score > 9) {
                    scoreOffset = -0.5;
                    if (score > 99) {
                        scoreOffset = -1.0;
                        //3 columns
                        int column1 = score / 100;
                        int column2 = (score % 100) / 10;
                        int column3 = score % 10;
                        
                        scoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column1]];
                        scoreColumn2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column2]];
                        scoreColumn3 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column3]];
                        //scoreColumn1 = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"number%d.png",column1]];
                        //scoreColumn2 = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"number%d.png",column2]];
                        //scoreColumn3 = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"number%d.png",column3]];
                        
                        [self addChild:scoreColumn1 z:11];
                        [self addChild:scoreColumn2 z:11];
                        [self addChild:scoreColumn3 z:11];
                    } else {
                        //2 columns
                        int column1 = (score % 100) / 10;
                        int column2 = score % 10;
                        scoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column1]];
                        scoreColumn2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column2]];
                        //scoreColumn1 = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"number%d.png",column1]];
                        //scoreColumn2 = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"number%d.png",column2]];
                        [self addChild:scoreColumn1 z:11];
                        [self addChild:scoreColumn2 z:11];

                    }
                } else {
                    //1 column
                    int column1 = score % 10;
                    scoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column1]];
                    //scoreColumn1 = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"number%d.png",column1]];
                    [self addChild:scoreColumn1 z:11];

                }
                
             //non-retina
            } else {
                
                if (score > 9) {
                    scoreOffset = -0.5;
                    if (score > 99) {
                        scoreOffset = -1.0;
                        //3 columns
                        int column1 = score / 100;
                        int column2 = (score % 100) / 10;
                        int column3 = score % 10;
                        scoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column1]];
                        scoreColumn2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column2]];
                        scoreColumn3 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column3]];
                        [self addChild:scoreColumn1 z:11];
                        [self addChild:scoreColumn2 z:11];
                        [self addChild:scoreColumn3 z:11];
                    } else {
                        //2 columns
                        int column1 = (score % 100) / 10;
                        int column2 = score % 10;
                        scoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column1]];
                        scoreColumn2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column2]];
                        [self addChild:scoreColumn1 z:11];
                        [self addChild:scoreColumn2 z:11];
                    }
                } else {
                    //1 column
                    int column1 = score % 10;
                    scoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column1]];
                    [self addChild:scoreColumn1 z:11];
                }
                
            }
            
        }
    }
    
    if (scoreColumn1) {
        scoreColumn1.position = ccp(pos.x * PTM_RATIO + scoreColumn1X * PTM_RATIO + scoreOffset * PTM_RATIO, scoreColumn1Y * PTM_RATIO);
    }
    if (scoreColumn2) {
        scoreColumn2.position = ccp(pos.x * PTM_RATIO + scoreColumn2X * PTM_RATIO + scoreOffset * PTM_RATIO, scoreColumn2Y * PTM_RATIO);
    }
    if (scoreColumn3) {
        scoreColumn3.position = ccp(pos.x * PTM_RATIO + scoreColumn3X * PTM_RATIO + scoreOffset * PTM_RATIO, scoreColumn3Y * PTM_RATIO);
    }
    
    if (highScoreColumn1) {
        highScoreColumn1.position = ccp(pos.x * PTM_RATIO + highScoreColumn1X * PTM_RATIO + highScoreOffset * PTM_RATIO, highScoreColumn1Y * PTM_RATIO);
    }
    if (highScoreColumn2) {
        highScoreColumn2.position = ccp(pos.x * PTM_RATIO + highScoreColumn2X * PTM_RATIO + highScoreOffset * PTM_RATIO, highScoreColumn2Y * PTM_RATIO);
    }
    if (highScoreColumn3) {
        highScoreColumn3.position = ccp(pos.x * PTM_RATIO + highScoreColumn3X * PTM_RATIO + highScoreOffset * PTM_RATIO, highScoreColumn3Y * PTM_RATIO);
    }

   
}



-(void)gameOver {
    gameOver = true;
    
    if (!starting) {
        //empty the score queue
        while (!score_queue->empty()) {
            score_queue->pop();
        }
        //remove platforms
        [self checkAndRemoveColumns];
        platformNumber = 0;
        
        //remove hamster
        [self removeChild:_ball cleanup:YES];
        [self removeChild:_lines cleanup:YES];
        [self removeChild:_shading cleanup:YES];
        [self removeChild:_hamster cleanup:YES];
        [self removeChild:spriteSheet cleanup:YES];
    }
    
    //switch score x position to its game over values
    scoreColumn1X = scoreColumn1X2;
    scoreColumn2X = scoreColumn2X2;
    scoreColumn3X = scoreColumn3X2;
    
    scoreColumn1Y = scoreColumn1Y2;
    scoreColumn2Y = scoreColumn2Y2;
    scoreColumn3Y = scoreColumn3Y2;
    
    //check if remove ads button should be displayed or not and adjust the position of the start button
    restartX = restartX1;
    restartY = restartY1;
    if (!showRemoveAdsButton) {
        restartX = restartX2;
        restartY = restartY2;
    }

    
    //show all the buttons and whatnot
    if (isRetina) {
        _restartButton= [CCMenuItemImage
                         itemFromNormalImage:@"startButton.png" selectedImage:@"startButton.png"
                         target:self selector:@selector(restartTapped)];
        _restartButton.position = ccp(-300, 280);
        
        if (showRemoveAdsButton) {
            _removeAdsButton= [CCMenuItemImage
                               itemFromNormalImage:@"removeAdsButton.png" selectedImage:@"removeAdsButton.png"
                               target:self selector:@selector(removeAdsTapped)];
            _removeAdsButton.position = ccp(-500, 280);
            
            starMenu = [CCMenu menuWithItems:_restartButton, _removeAdsButton, nil];
        } else {
            starMenu = [CCMenu menuWithItems:_restartButton, nil];
        }
        starMenu.position = CGPointZero;
        [self addChild:starMenu];
        
        scorePrefix = [CCSprite spriteWithFile:@"scorePrefix.png"];
        scorePrefix.position = ccp(-300, 280);
        [self addChild:scorePrefix z:11];
        
        highScorePrefixLabel = [CCSprite spriteWithFile:@"bestButton.png"];
        highScorePrefixLabel.position = ccp(-300, 280);
        [self addChild:highScorePrefixLabel z:11];
        
        instructions = [CCSprite spriteWithFile:@"instructions.png"];
        instructions.position = ccp(-300, 280);
        [self addChild:instructions z:12];

    } else {
        _restartButton= [CCMenuItemImage
                         itemFromNormalImage:@"NRstartButton.png" selectedImage:@"NRstartButton.png"
                         target:self selector:@selector(restartTapped)];
        _restartButton.position = ccp(-300, 280);
        
        if (showRemoveAdsButton) {
            _removeAdsButton= [CCMenuItemImage
                               itemFromNormalImage:@"NRremoveAdsButton.png" selectedImage:@"NRremoveAdsButton.png"
                               target:self selector:@selector(removeAdsTapped)];
            _removeAdsButton.position = ccp(-300, 280);
            starMenu = [CCMenu menuWithItems:_restartButton, _removeAdsButton, nil];
        } else {
            starMenu = [CCMenu menuWithItems:_restartButton, nil];
        }
        starMenu.position = CGPointZero;
        [self addChild:starMenu];
        
        scorePrefix = [CCSprite spriteWithFile:@"NRscorePrefix.png"];
        scorePrefix.position = ccp(-300, 280);
        [self addChild:scorePrefix z:11];
        
        highScorePrefixLabel = [CCSprite spriteWithFile:@"NRbestButton.png"];
        highScorePrefixLabel.position = ccp(-300, 280);
        [self addChild:highScorePrefixLabel z:11];
        
        instructions = [CCSprite spriteWithFile:@"NRinstructions.png"];
        instructions.position = ccp(-300, 1000);
        [self addChild:instructions z:12];
    }
    
    starting = false;
    
    //highscore keeping
    if (score > [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"]
        || [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"] == nil) {
        
        [[NSUserDefaults standardUserDefaults] setInteger:score forKey:@"highScore"];
    }
    int highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"];
    
    //display highscore
    if (isRetina ) {
        if (highScore > 9) {
            if (highScore > 99) {
                //3 columns
                int column1 = highScore / 100;
                int column2 = (highScore % 100) / 10;
                int column3 = highScore % 10;
                highScoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column1]];
                highScoreColumn2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column2]];
                highScoreColumn3 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column3]];
                [self addChild:highScoreColumn1 z:11];
                [self addChild:highScoreColumn2 z:11];
                [self addChild:highScoreColumn3 z:11];
            } else {
                //2 columns
                int column1 = (highScore % 100) / 10;
                int column2 = highScore % 10;
                highScoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column1]];
                highScoreColumn2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column2]];
                [self addChild:highScoreColumn1 z:11];
                [self addChild:highScoreColumn2 z:11];
            }
        } else {
            //1 column
            int column1 = highScore % 10;
            highScoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"number%d.png",column1]];
            [self addChild:highScoreColumn1 z:11];
        }
    //non-retina
    } else {
        
        if (highScore > 9) {
            if (highScore > 99) {
                //3 columns
                int column1 = highScore / 100;
                int column2 = (highScore % 100) / 10;
                int column3 = highScore % 10;
                highScoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column1]];
                highScoreColumn2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column2]];
                highScoreColumn3 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column3]];
                [self addChild:highScoreColumn1 z:11];
                [self addChild:highScoreColumn2 z:11];
                [self addChild:highScoreColumn3 z:11];
            } else {
                //2 columns
                int column1 = (highScore % 100) / 10;
                int column2 = highScore % 10;
                highScoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column1]];
                highScoreColumn2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column2]];
                [self addChild:highScoreColumn1 z:11];
                [self addChild:highScoreColumn2 z:11];
            }
        } else {
            //1 column
            int column1 = highScore % 10;
            highScoreColumn1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"NRnumber%d.png",column1]];
            [self addChild:highScoreColumn1 z:11];
        }
    }
}


-(void)nothing {
    //for highscore prefix label
}

- (void)restartTapped {
    gameOver = false;
    
    [self createNewHamster];
    
    [self removeChild:starMenu cleanup:YES];
    [self removeChild:highScoreLabel cleanup:YES];
    [self removeChild:highScorePrefixLabel cleanup:YES];
    [self removeChild:scorePrefix cleanup:YES];
    [self removeChild:instructions cleanup:YES];
    if (showRemoveAdsButton) {
        [self removeChild:_removeAdsButton cleanup:YES];
    }
    
    score = 0;
    scoreOffset = 0;
    
    //switch score x position to its in-game values
    scoreColumn1X = scoreColumn1X1;
    scoreColumn2X = scoreColumn2X1;
    scoreColumn3X = scoreColumn3X1;
    
    scoreColumn1Y = scoreColumn1Y1;
    scoreColumn2Y = scoreColumn2Y1;
    scoreColumn3Y = scoreColumn3Y1;
    
    [self removeChild:scoreColumn1 cleanup:YES];
    [self removeChild:scoreColumn2 cleanup:YES];
    [self removeChild:scoreColumn3 cleanup:YES];
    
    scoreColumn2 = nil;
    scoreColumn3 = nil;
    
    [self removeChild:highScoreColumn1 cleanup:YES];
    [self removeChild:highScoreColumn2 cleanup:YES];
    [self removeChild:highScoreColumn3 cleanup:YES];
    
    highScoreColumn1 = nil;
    highScoreColumn2 = nil;
    highScoreColumn3 = nil;
    
    if (isRetina) {
        scoreColumn1 = [CCSprite spriteWithFile:@"number0.png"];
    } else {
        scoreColumn1 = [CCSprite spriteWithFile:@"NRnumber0.png"];
    }
    [self addChild:scoreColumn1 z:11];
    
    [self drawStartingArea];
}


-(void)removeAdsTapped {
    
    SKProduct *product = _products[0];
    NSLog(@"Buying: %@...", product.productIdentifier);
    
    if ([self connected] == NO)
    {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Can not connect to iTunes Store. Please check your internet connection and try again."
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
        return;
    }
    [_helper buyProduct:_removeAds];
    
}

- (BOOL)connected
{
    Reachability *reachability = [Reachability reachabilityWithHostName:@"google.com"];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return !(networkStatus == NotReachable);
}



- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _world->SetGravity(gravity2);
    if (contactListener->getGround() == 1) {
        [self kick1];
        nextKick = true;
    }
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    nextKick = false;
    _world->SetGravity(gravity1);
}


- (void)kick1 {
        if (!nextKick) {
            b2Vec2 force = b2Vec2(kick1x, kick1y);
            if (contactListener->getGround() == 1) {
                _body->ApplyLinearImpulse(force,_body->GetPosition());
                //_body->ApplyTorque(-10);
                [self scheduleOnce:@selector(kick2) delay:0.3];
            }
        }
}

-(void) kick2 {
    if (nextKick) {
        b2Vec2 force = b2Vec2(kick2x, kick2y);
        _body->ApplyLinearImpulse(force,_body->GetPosition());
    }
}


-(void) createNewHamster {
    
    
    if (isRetina) {
        _ball = [CCSprite spriteWithFile:@"hamsterEmptyBall.png" rect:CGRectMake(0, 0, 52, 52)];
    } else {
        _ball = [CCSprite spriteWithFile:@"NRhamsterEmptyBall.png" rect:CGRectMake(0, 0, 52, 52)];
    }

    
    _ball.position = ccp(-300, 300);
    [self addChild:_ball z:0];
    
    // Create ball body and shape
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(hamsterStartX, hamsterStartY + screenOffsetY);
    ballBodyDef.userData = _ball;
    _body = _world->CreateBody(&ballBodyDef);
    b2CircleShape circle;
    circle.m_radius = 26.0/PTM_RATIO;
    
    b2FixtureDef ballShapeDef;
    ballShapeDef.shape = &circle;
    ballShapeDef.density = 1.4f;
    ballShapeDef.friction = 10.0f;
    ballShapeDef.restitution = bounce;
    _body->CreateFixture(&ballShapeDef);
    
    //sensor shape
    b2PolygonShape sensorShape;
    sensorShape.SetAsBox(0.6, 0.3, b2Vec2(0,-0.7), 0);
    
    //sensor body
    b2BodyDef sensorBodyDef;
    sensorBodyDef.type = b2_dynamicBody;
    sensorBodyDef.position.Set(100/PTM_RATIO, 300/PTM_RATIO);
    sensorBodyDef.userData = _ball;
    _sensor = _world->CreateBody(&sensorBodyDef);
    
    //add foot sensor fixture
    b2FixtureDef sensorFixtureDef;
    sensorFixtureDef.shape = &sensorShape;
    sensorFixtureDef.density = 0;
    sensorFixtureDef.isSensor = true;
    b2Fixture* footSensorFixture = _sensor->CreateFixture( &sensorFixtureDef );
    footSensorFixture->SetUserData( (void*)3 );
    
    
    //join between jump sensor and ball
    b2RevoluteJointDef revoluteJointDef;
    revoluteJointDef.bodyA = _body;
    revoluteJointDef.bodyB = _sensor;
    revoluteJointDef.localAnchorA.Set(0,0);
    revoluteJointDef.localAnchorB.Set(0,0);
    revoluteJointDef.referenceAngle = 0;
    revoluteJointDef.collideConnected = false;
    
    _joint = (b2RevoluteJoint*)_world->CreateJoint( &revoluteJointDef );
    
    //different hamsters for retina/non-retina
    if (isRetina) {
        _shading = [CCSprite spriteWithFile:@"hamsterShading.png" rect:CGRectMake(0, 0, 52, 52)];
        _shading.position = ccp(100, 300);
        [self addChild:_shading];
        
        //animation
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"hamsterRun.plist"];
        
        spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"hamsterRun.png"];
        [self addChild:spriteSheet];
        
        runFrames = [NSMutableArray array];
        for (int i=1; i<=2; i++) {
            [runFrames addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"hamsterRun%d.png",i]]];
        }
        
        runAnim = [CCAnimation animationWithSpriteFrames:runFrames delay:0.1f];
        //runAnim.delayPerUnit = 0.15f;
        
        _hamster = [CCSprite spriteWithSpriteFrameName:@"hamsterRun1.png"];
        _hamster.position = ccp(100, 300);
        
        runAction = [CCRepeatForever actionWithAction:
                     [CCAnimate actionWithAnimation:runAnim]];
        
        [_hamster runAction:runAction];
        [spriteSheet addChild:_hamster];
        
        //ball lines (on top of hamster)
        _lines = [CCSprite spriteWithFile:@"hamsterBallLines.png" rect:CGRectMake(0, 0, 52, 52)];
        _lines.position = ccp(100, 300);
        [self addChild:_lines z:10];
    } else {
        _shading = [CCSprite spriteWithFile:@"NRhamsterShading.png" rect:CGRectMake(0, 0, 52, 52)];
        _shading.position = ccp(100, 300);
        [self addChild:_shading];
        
        //animation
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"NRhamsterRun.plist"];
        
        spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"NRhamsterRun.png"];
        [self addChild:spriteSheet];
        
        runFrames = [NSMutableArray array];
        for (int i=1; i<=2; i++) {
            [runFrames addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"NRhamsterRun%d.png",i]]];
        }
        
        runAnim = [CCAnimation animationWithSpriteFrames:runFrames delay:0.1f];
        //runAnim.delayPerUnit = 0.15f;
        
        _hamster = [CCSprite spriteWithSpriteFrameName:@"NRhamsterRun1.png"];
        _hamster.position = ccp(100, 300);
        
        runAction = [CCRepeatForever actionWithAction:
                     [CCAnimate actionWithAnimation:runAnim]];
        
        [_hamster runAction:runAction];
        [spriteSheet addChild:_hamster];
        
        //ball lines (on top of hamster)
        _lines = [CCSprite spriteWithFile:@"NRhamsterBallLines.png" rect:CGRectMake(0, 0, 52, 52)];
        _lines.position = ccp(100, 300);
        [self addChild:_lines z:10];
    }
}


//while screenOffsetX works in tick
//screenOffsetY adjusts the column heights
-(void) drawStartingArea {
    [self drawColumn:11 atDistance:4 atHeight:1+screenOffsetY];
}


-(void) drawNextColumn {
    float x = (float)[self getRandomNumberBetween:3 to:7];
    
    //first 4 platforms have less height variance
    float y;
    if (platformNumber < 5) {
        y = (float)[self getRandomNumberBetween:1 to:2];
    } else {
        y = (float)[self getRandomNumberBetween:1 to:3];
    }
    
    y += screenOffsetY;
    
    //this prevents down slopes from leading into higher columns (too hard)
    if (lastPlatformNumber == 2 || lastPlatformNumber == 3 || lastPlatformNumber == 10) {
        while (y > lastColumnCornerHeight) {
            y = (float)[self getRandomNumberBetween:1 to:3];
            y += screenOffsetY;
        }
    }

    int n = [self getRandomNumberBetween:1 to:12];
    
    //removes hard and medium difficulty platforms for the first 5
    while (platformNumber < 6 && (n == 2 || n == 3 || n == 6 || n == 9 || n == 1 || n == 8)) {
        n = [self getRandomNumberBetween:1 to:12];
    }
    
    //removes hard platforms from the first nine
    while (platformNumber < 10 && platformNumber > 5 && (n == 2 || n == 3 || n == 6 || n == 9)) {
        n = [self getRandomNumberBetween:1 to:12];
    }
    
    float temp = [self drawColumn:n atDistance: (lastColumnCornerDistance + x) atHeight:y];
    
    lastColumnCornerDistance += temp + x;
    lastColumnCornerHeight = y;
    lastPlatformNumber = n;
    
    score_queue->push(lastColumnCornerDistance - temp);
    
    platformNumber++;

}

-(void) checkAndRemoveColumns {
    //if any bodies in the column array (I will make one) are sufficiently behind the current position,
    //remove them
    for (b2Body* b = _world->GetBodyList(); b; b = b->GetNext())
    {
        _world->DestroyBody(b);
        if (b->GetUserData() != nil) {
            [self removeChild: (CCSprite *)b->GetUserData() cleanup:YES];
        }
    }
    lastColumnCornerDistance = 10;
}


-(int)getRandomNumberBetween:(int)from to:(int)to {
    return (int)from + arc4random() % (to-from+1);
}


//returns the width, so that lastColumnCornerDistance can be reset
- (float)drawColumn:(int)n atDistance:(int)x atHeight:(int)y {
    
    // Create body and definition
    b2BodyDef platformBodyDef;
    platformBodyDef.position.Set(0,0);
    
    b2Body *platformBody;platformBody = _world->CreateBody(&platformBodyDef);
    b2EdgeShape platformEdge1;
    b2EdgeShape platformEdge2;
    b2EdgeShape platformEdge3;
    b2FixtureDef platformFixtureDef;
    platformFixtureDef.friction = 10.0f;
    
    if (n == 1) {
    
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 88.0/PTM_RATIO , y + 25.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 88.0/PTM_RATIO, y + 25.0/PTM_RATIO), b2Vec2(x + 88.0/PTM_RATIO, -10));
    
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
    
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);

        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);

        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform1.png"];
            platform.position = ccp(x*PTM_RATIO + 44, y*PTM_RATIO-130);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform1.png"];
            platform.position = ccp(x*PTM_RATIO + 44, y*PTM_RATIO-130);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 88.0/PTM_RATIO;
        
    } else if (n == 2) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 119.0/PTM_RATIO , y - 25.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 119.0/PTM_RATIO, y - 25.0/PTM_RATIO), b2Vec2(x + 119.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform2.png"];
            platform.position = ccp(x*PTM_RATIO + 59.5, y*PTM_RATIO-124);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform2.png"];
            platform.position = ccp(x*PTM_RATIO + 59.5, y*PTM_RATIO-124);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 119.0/PTM_RATIO;

    } else if (n == 3) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 88.0/PTM_RATIO , y - 25.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 88.0/PTM_RATIO, y - 25.0/PTM_RATIO), b2Vec2(x + 88.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform3.png"];
            platform.position = ccp(x*PTM_RATIO + 44, y*PTM_RATIO-154);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform3.png"];
            platform.position = ccp(x*PTM_RATIO + 44, y*PTM_RATIO-154);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        return 88.0/PTM_RATIO;
        
    } else if (n == 4) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 120.0/PTM_RATIO , y));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 120.0/PTM_RATIO, y), b2Vec2(x + 120.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform4.png"];
            platform.position = ccp(x*PTM_RATIO + 60, y*PTM_RATIO-150);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform4.png"];
            platform.position = ccp(x*PTM_RATIO + 60, y*PTM_RATIO-150);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 120.0/PTM_RATIO;
        
    } else if (n == 5) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 119.0/PTM_RATIO , y + 25.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 119.0/PTM_RATIO, y + 25.0/PTM_RATIO), b2Vec2(x + 119.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform5.png"];
            platform.position = ccp(x*PTM_RATIO + 59.5, y*PTM_RATIO-100);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform5.png"];
            platform.position = ccp(x*PTM_RATIO + 59.5, y*PTM_RATIO-100);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 119.0/PTM_RATIO;
        
    } else if (n == 6) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 110.0/PTM_RATIO , y + 50.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 110.0/PTM_RATIO, y + 50.0/PTM_RATIO), b2Vec2(x + 110.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform6.png"];
            platform.position = ccp(x*PTM_RATIO + 55, y*PTM_RATIO-124);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform6.png"];
            platform.position = ccp(x*PTM_RATIO + 55, y*PTM_RATIO-124);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 110.0/PTM_RATIO;
        
    } else if (n == 7) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 200.0/PTM_RATIO , y + 25.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 200.0/PTM_RATIO, y + 25.0/PTM_RATIO), b2Vec2(x + 200.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform7.png"];
            platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-119);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform7.png"];
            platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-119);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 200.0/PTM_RATIO;
        
    } else if (n == 8) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 90.0/PTM_RATIO , y));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 90.0/PTM_RATIO, y), b2Vec2(x + 90.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform8.png"];
            platform.position = ccp(x*PTM_RATIO + 45, y*PTM_RATIO-153);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform8.png"];
            platform.position = ccp(x*PTM_RATIO + 45, y*PTM_RATIO-153);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 90.0/PTM_RATIO;
        
    } else if (n == 9) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 76.0/PTM_RATIO , y + 50.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 76.0/PTM_RATIO, y + 50.0/PTM_RATIO), b2Vec2(x + 76.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform9.png"];
            platform.position = ccp(x*PTM_RATIO + 38, y*PTM_RATIO-100);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform9.png"];
            platform.position = ccp(x*PTM_RATIO + 38, y*PTM_RATIO-100);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 76.0/PTM_RATIO;
        
    } else if (n == 10) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 200.0/PTM_RATIO , y - 25.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 200.0/PTM_RATIO, y - 25.0/PTM_RATIO), b2Vec2(x + 200.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform10.png"];
            platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-144);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform10.png"];
            platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-144);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 200.0/PTM_RATIO;
        
    } else if (n == 11) {

        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 200.0/PTM_RATIO , y));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 200.0/PTM_RATIO, y), b2Vec2(x + 200.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform11.png"];
            platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-150);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform11.png"];
            platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-150);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 200.0/PTM_RATIO;
        
    } else if (n == 12) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 200.0/PTM_RATIO , y + 50.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, -10));
        platformEdge3.Set(b2Vec2(x + 200.0/PTM_RATIO, y + 50.0/PTM_RATIO), b2Vec2(x + 200.0/PTM_RATIO, -10));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform12.png"];
            platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-118);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform12.png"];
            platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-118);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 200.0/PTM_RATIO;
        
    }
    return 0;

}

//-(void) draw
//{
//	//
//	// IMPORTANT:
//	// This is only for debug purposes
//	// It is recommend to disable it
//	//
//	[super draw];
//	
//	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
//	
//	kmGLPushMatrix();
//	
//	_world->DrawDebugData();
//	
//	kmGLPopMatrix();
//}


-(void) dealloc
{
	delete _world;
    _body = NULL;
	_world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
	
	[super dealloc];
}

@end

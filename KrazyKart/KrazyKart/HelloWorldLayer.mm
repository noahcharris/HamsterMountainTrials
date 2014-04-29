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
        [_helper restoreCompletedTransactions];
        
    } else {
        adsRemoved = true;
    }
    
    //AD CONTROLLER INITIALIZATION
    
    if (!adsRemoved) {
        _banner = [[BannerViewController alloc] init];
        [_banner initiAdBanner];
        [_banner initgAdBanner];
        [[CCDirector sharedDirector].openGLView addSubview:_banner.view];
    }
    
    
}

-(void)receiveProducts:(NSNotification *)note {
    
    NSDictionary *theData = [note userInfo];
    _products = [[NSMutableArray alloc] initWithArray:[theData objectForKey:@"productsList"]];
    _removeAds = [_products objectAtIndex:0];
    NSLog(@"SK product objects stored");
    NSLog(_removeAds.productIdentifier);
    
    //check if the product has been purchased
//    if ([_helper productPurchased:_removeAds.productIdentifier]) {
//        
//    }
    
}

-(void)provideProducts:(NSNotification *)note {
    //TODO
    showingBuyPopup = NO;
    //[self itemNodeByName:@"loader"].visible = NO;
    NSDictionary *theData = [note userInfo];
    SKPaymentTransaction *transaction = [theData objectForKey:@"transaction"];
    NSLog(transaction.originalTransaction.payment.productIdentifier);
    if ([transaction.originalTransaction.payment.productIdentifier isEqualToString:@"removeAds"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"removedAds"];
        
        adsRemoved = true;
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
        
        kick1x = 0;
        kick2x = 1;
        kick1y = 23;
        kick2y = 12;

        //0.5 for iphone
        scaling = 1.0;
        //negative is forward for these two values
        torque = -35;
        topSpeed = -10;
        
        //0.14
        bounce = 0.14;
        
        
        gravity1 = b2Vec2(0.0f, -10.5f);
        gravity2 = b2Vec2(0.0f, -8.0f);
        
        //this affects screen view
        screenOffsetX = 120;
        //this affects column draw height
        screenOffsetY = 5;
        
        hamsterStartX = 6.25;
        hamsterStartY = 26;
        
        
        
        scoreLabelX = -3;
        scoreLabelY = 8;
        
        highScorePrefixX = 0;
        highScorePrefixY = 8;
        
        highScoreX = 2;
        highScoreY = 8;
        
        restartX = 7;
        restartY = 8;
        
        removeAdsX = 5;
        removeAdsY = 8;

        
        lastColumnCornerDistance = 10;
        lastColumnCornerHeight = 1;
        lastPlatformNumber = 10;
        
        
        //check for ipad
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            isiPhone = false;
        }
        else
        {
            isiPhone = true;
        }
        
        //check phone version
        if (isiPhone) {
            if([UIScreen mainScreen].bounds.size.height == 568){
                isiPhone5 = true;
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
        
        
        
        
        
        //for testing
        //[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"highScore"];
        
        

        [self handlePurchases];
        
        

        self.isTouchEnabled = YES;
		CGSize winSize = [CCDirector sharedDirector].winSize;
        
        //scorekeeping
        score = 0;
        score_queue = new std::queue<int>();
        score_queue->push(2);
        
        scoreLabel = [CCLabelTTF labelWithString:@"0" fontName:@"Marker Felt" fontSize:24];
        scoreLabel.position = ccp(240, 160); //Middle of the screen...
        [self addChild:scoreLabel z:1];
        
        //draw background
        _background = [CCSprite spriteWithFile:@"background.png"];
        _background.position = ccp(winSize.width/(2*0.6), winSize.height/(2*0.6));
        [self addChild:_background];
        
        // Create a world
        // -10.5
        _world = new b2World(gravity1);
        
        //contact listener
        contactListener = new MyContactListener;
        
        _world->SetContactListener(contactListener);
        
        //DEBUG DRAWING
        m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		_world->SetDebugDraw(m_debugDraw);
		uint32 flags = 0;
		flags += b2Draw::e_shapeBit;
		m_debugDraw->SetFlags(flags);
        
        
        
        
        //zoom out (DON't ZOOM out on IPAD, maybe even zoom in)
        //0.6
        id zoomOut = [CCScaleTo actionWithDuration:0.0f scale:scaling];
        [self runAction:zoomOut];
        
        
        
        
        //START THE GAME
        [self createNewHamster];
        [self drawStartingArea];
        [self schedule:@selector(tick:)];
        
        //will need this if number of platforms gets out of hand
        //[self schedule:@selector(checkAndRemoveColumns) interval:3.0];
        
	}
	return self;
}


- (void)tick:(ccTime) dt {
    
    _world->Step(dt, 10, 10);
    
    //update sprites
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
    
    
    

    //good setup: top speed = -12, torque = -26.5
    // -9.5 -35
    
    
    // -13.2
    // -40
    if (_body->GetAngularVelocity() > topSpeed) {
        
        _body->ApplyTorque(torque);
    }

    //moving screen
    b2Vec2 pos = _body->GetPosition();                  //110
    if (gameOver) {
        //why the fuck is it 5.4 and not 6.25???
        pos.x = 5.4;
    }
	CGPoint newPos = ccp(-1 * pos.x * PTM_RATIO * scaling + screenOffsetX, self.position.y * PTM_RATIO);
	[self setPosition:newPos];
    
    //scroll background
    CGSize winSize = [CCDirector sharedDirector].winSize;
    _background.position = ccp(pos.x * PTM_RATIO + winSize.width/(2), self.position.y * PTM_RATIO + winSize.height/(2));
    
    
    
    //game over stuff
    if (gameOver) {
        highScoreLabel.position = ccp(pos.x * PTM_RATIO + highScoreX * PTM_RATIO, highScoreY * PTM_RATIO);
        highScorePrefixLabel.position = ccp(pos.x * PTM_RATIO + highScorePrefixX * PTM_RATIO, highScorePrefixY * PTM_RATIO);
        _restartButton.position = ccp(pos.x * PTM_RATIO + restartX * PTM_RATIO, self.position.y * PTM_RATIO + restartY * PTM_RATIO);
        
        if (!adsRemoved) {
            _removeAdsButton.position = ccp(pos.x * PTM_RATIO + removeAdsX * PTM_RATIO, self.position.y * PTM_RATIO + removeAdsY * PTM_RATIO);
        }
    }
    
    //DRAWING COLUMNS
    if ((pos.x + 50) > lastColumnCornerDistance) {
        [self drawNextColumn];
    }
    
    
    //score stuff
    scoreLabel.position = ccp(pos.x * PTM_RATIO + scoreLabelX * PTM_RATIO, scoreLabelY * PTM_RATIO);
    if (score_queue->front() < pos.x) {
        score_queue->pop();
        if (pos.x > 11 && !gameOver) {
            score ++;
            [scoreLabel setString:[NSString stringWithFormat:@"%d", score]];
        }
    }
    
    
    if (pos.y < -2.7) {
        if (!gameOver) {
            [self gameOver];
        }
    }
   
}






-(void)gameOver {
    gameOver = true;
    _restartButton= [CCMenuItemImage
                     itemFromNormalImage:@"Icon.png" selectedImage:@"Icon-Small.png"
                     target:self selector:@selector(restartTapped)];
    _restartButton.position = ccp(-300, 280);
    
    _removeAdsButton= [CCMenuItemImage
                     itemFromNormalImage:@"blocks.png" selectedImage:@"Icon-Small.png"
                     target:self selector:@selector(removeAds)];
    _removeAdsButton.position = ccp(-300, 280);
    
    starMenu = [CCMenu menuWithItems:_restartButton, _removeAdsButton, nil];
    starMenu.position = CGPointZero;
    [self addChild:starMenu];
    
    highScoreLabel = [CCLabelTTF labelWithString:@"0" fontName:@"Marker Felt" fontSize:24];
    highScoreLabel.position = ccp(-300, 160); //off the screen
    
    highScorePrefixLabel = [CCLabelTTF labelWithString:@"High Score:" fontName:@"Marker Felt" fontSize:24];
    highScoreLabel.position = ccp(-300, 160); //off the screen
    
    [self addChild:highScoreLabel z:1];
    [self addChild:highScorePrefixLabel z:1];
    
    NSLog(@"%d", [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"]);
    
    if (score > [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"]
        || [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"] == 0) {
        
        NSLog(@"hi");
        [[NSUserDefaults standardUserDefaults] setInteger:score forKey:@"highScore"];
    }
    
    [highScoreLabel setString:[NSString stringWithFormat:@"%d",[[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"]]];
    
}

- (void)restartTapped {
    
    //remove the restart
    [self checkAndRemoveColumns];
    
    //hamster body is destroyed by checkAndRemoveColumns,
    //but we still have to clean up sprites
    [self removeChild:_ball cleanup:YES];
    [self removeChild:_lines cleanup:YES];
    [self removeChild:_shading cleanup:YES];
    [self removeChild:_hamster cleanup:YES];
    [self removeChild:spriteSheet cleanup:YES];
    
    [self createNewHamster];
    gameOver = false;
    [self removeChild:starMenu cleanup:YES];
    [self removeChild:highScoreLabel cleanup:YES];
    [self removeChild:highScorePrefixLabel cleanup:YES];
    score = 0;
    [scoreLabel setString:[NSString stringWithFormat:@"%d", 0]];
    
    //empty the queue
    while (!score_queue->empty()) {
        score_queue->pop();
    }
    
    [self drawStartingArea];
    
}




-(void)removeAds {
    //TODO
}




- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (contactListener->getGround() == 1) {
        NSLog(@"on");
        [self kick1];
        nextKick = true;
        _world->SetGravity(gravity2);
    }
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"off");
    nextKick = false;
    _world->SetGravity(gravity1);
}


- (void)kick1 {
        if (!nextKick) {
            b2Vec2 force = b2Vec2(kick1x, kick1y);
            //_body->ApplyLinearImpulse(force,_body->GetPosition());
            if (contactListener->getGround() == 1) {
                NSLog(@"kick1");
                _body->ApplyLinearImpulse(force,_body->GetPosition());
                //_body->ApplyTorque(-10);
                [self scheduleOnce:@selector(kick2) delay:0.3];
            }
        }
    

}

-(void) kick2 {
    if (nextKick) {
        NSLog(@"kick2");
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
    //[self addChild:_hamster z:1];
    
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
    //NSLog(@"Draw next column");
    float x = (float)[self getRandomNumberBetween:3 to:7];
    float y = (float)[self getRandomNumberBetween:1 to:2];
    y += screenOffsetY;
    
    //this prevents down slopes from leading into higher columns (too hard)
    if (lastPlatformNumber == 2 || lastPlatformNumber == 3 || lastPlatformNumber == 10) {
        while (y < lastColumnCornerHeight) {
            y = (float)[self getRandomNumberBetween:1 to:4];
            y += screenOffsetY;
        }
    }
    int n = [self getRandomNumberBetween:1 to:12];
    
    float temp = [self drawColumn:n atDistance: (lastColumnCornerDistance + x) atHeight:y];
    
    lastColumnCornerDistance += temp + x;
    lastColumnCornerHeight = y;
    lastPlatformNumber = n;
    
    //store the beginning of the platform, for use by scorekeeper
    score_queue->push(lastColumnCornerDistance - temp);

    
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

//returns the width, so that lastCorner can be reset
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 88.0/PTM_RATIO, y + 25.0/PTM_RATIO), b2Vec2(x + 88.0/PTM_RATIO, 0));
    
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 119.0/PTM_RATIO, y - 25.0/PTM_RATIO), b2Vec2(x + 119.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 88.0/PTM_RATIO, y - 25.0/PTM_RATIO), b2Vec2(x + 88.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 120.0/PTM_RATIO, y), b2Vec2(x + 120.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 119.0/PTM_RATIO, y + 25.0/PTM_RATIO), b2Vec2(x + 119.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 110.0/PTM_RATIO, y + 50.0/PTM_RATIO), b2Vec2(x + 110.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 200.0/PTM_RATIO, y + 25.0/PTM_RATIO), b2Vec2(x + 200.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 90.0/PTM_RATIO, y), b2Vec2(x + 90.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 76.0/PTM_RATIO, y + 50.0/PTM_RATIO), b2Vec2(x + 76.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 200.0/PTM_RATIO, y - 25.0/PTM_RATIO), b2Vec2(x + 200.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 200.0/PTM_RATIO, y), b2Vec2(x + 200.0/PTM_RATIO, 0));
        
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
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 200.0/PTM_RATIO, y + 50.0/PTM_RATIO), b2Vec2(x + 200.0/PTM_RATIO, 0));
        
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

-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	_world->DrawDebugData();
	
	kmGLPopMatrix();
}


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

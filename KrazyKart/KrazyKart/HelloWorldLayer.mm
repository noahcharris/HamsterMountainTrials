//
//  HelloWorldLayer.mm
//  KrazyKart
//
//  Created by Noah Harris on 4/18/14.
//  Copyright __MyCompanyName__ 2014. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"
#include <iostream.h>

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




//[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"packBought"];
//if ([[NSUserDefaults standardUserDefaults] objectForKey:@"removedAds"] == nil)

-(void) handlePurchases {
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"removedAds"] == nil) {
        
        adsRemoved = false;
        //IN APP PURCHASES
        
        _helper = [IAPHelper sharedInstance];      //create an instance of our in-app purchase helper
        
        [_helper requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
            if (success) {

                NSDictionary *dataDict = [NSDictionary dictionaryWithObject:products forKey:@"productsList"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"productsReceived" object:self userInfo:dataDict];
            }
        }];
        
    } else {
        adsRemoved = true;
    }
    if (!adsRemoved) {
        banner = [[BannerViewController alloc] init];
        [banner initiAdBanner];
        [banner initgAdBanner];
        [[CCDirector sharedDirector].openGLView addSubview:banner.view];
    }
}





-(id) init
{
	if( (self=[super init])) {
        
        kick1x = 0;
        kick2x = 0;
        kick1y = 25;
        kick2y = 8;

        //0.5 for iphone
        scaling = 0.5;
        //negative is forward for these two values
        torque = -45;
        topSpeed = -12.5;
        
        screenOffsetX = 100;
        screenOffsetY = 10;
        
        
        //initalize these variables
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
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"highScore"];

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
        b2Vec2 gravity = b2Vec2(0.0f, -10.5f);
        _world = new b2World(gravity);
        
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
        pos.x = 6.25 * scaling;
    }
	CGPoint newPos = ccp(-1 * pos.x * PTM_RATIO * scaling, self.position.y * PTM_RATIO);
	[self setPosition:newPos];
    
    //scroll background
    CGSize winSize = [CCDirector sharedDirector].winSize;
    _background.position = ccp(pos.x * PTM_RATIO + winSize.width/(2), self.position.y * PTM_RATIO + winSize.height/(2));
    
    
    //game over stuff
    if (gameOver) {
        highScoreLabel.position = ccp(pos.x * PTM_RATIO + 100, 270);
        highScorePrefixLabel.position = ccp(pos.x * PTM_RATIO, 270);
        _restartButton.position = ccp(pos.x * PTM_RATIO + 300, self.position.y * PTM_RATIO + 270);
    }
    
    //DRAWING COLUMNS
    if ((pos.x + 50) > lastColumnCornerDistance) {
        [self drawNextColumn];
    }
    
    
    //score stuff
    scoreLabel.position = ccp(pos.x * PTM_RATIO - 90, 270);
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
    starMenu = [CCMenu menuWithItems:_restartButton, nil];
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
    [self drawStartingArea];
    
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
    
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (contactListener->getGround() == 1) {
        [self kick1];
        nextKick = true;
    }
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    nextKick = false;
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

    
    _ball.position = ccp(100, 300);
    [self addChild:_ball z:0];
    //[self addChild:_hamster z:1];
    
    // Create ball body and shape
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(200/PTM_RATIO, 250/PTM_RATIO);
    ballBodyDef.userData = _ball;
    _body = _world->CreateBody(&ballBodyDef);
    b2CircleShape circle;
    circle.m_radius = 26.0/PTM_RATIO;
    
    b2FixtureDef ballShapeDef;
    ballShapeDef.shape = &circle;
    ballShapeDef.density = 1.4f;
    ballShapeDef.friction = 10.0f;
    ballShapeDef.restitution = 0.14f;
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



-(void) drawStartingArea {
    
    
    [self drawColumn:10 atDistance:4 atHeight:1];
    
    
}


-(void) drawNextColumn {
    //NSLog(@"Draw next column");
    float x = (float)[self getRandomNumberBetween:3 to:7];
    float y = (float)[self getRandomNumberBetween:1 to:4];
    
    //this prevents down slopes from leading into higher columns (too hard)
    if (lastPlatformNumber == 2 || lastPlatformNumber == 3) {
        while (y > lastColumnCornerHeight) {
            y = (float)[self getRandomNumberBetween:1 to:4];
        }
    }
    int n = [self getRandomNumberBetween:1 to:9];
    lastPlatformNumber = n;
    
    float temp = [self drawColumn:n atDistance: (lastColumnCornerDistance + x) atHeight:y];
    
    lastColumnCornerDistance += temp + x;
    
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
        
    } else if (n == 2) {    //ALWAYS HEIGHT 2 FOR PLATFORM 2
        
        platformEdge1.Set(b2Vec2(x, 2), b2Vec2(x + 119.0/PTM_RATIO , 2 - 25.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, 2), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 119.0/PTM_RATIO, 2 - 25.0/PTM_RATIO), b2Vec2(x + 119.0/PTM_RATIO, 0));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform2.png"];
            platform.position = ccp(x*PTM_RATIO + 59.5, 2*PTM_RATIO-124);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform2.png"];
            platform.position = ccp(x*PTM_RATIO + 59.5, 2*PTM_RATIO-124);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        }
        
        return 119.0/PTM_RATIO;

    } else if (n == 3) {    //ALWAYS HEIGHT 2 FOR PLATFORM 3
        
        platformEdge1.Set(b2Vec2(x, 2), b2Vec2(x + 88.0/PTM_RATIO , 2 - 25.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, 2), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 88.0/PTM_RATIO, 2 - 25.0/PTM_RATIO), b2Vec2(x + 88.0/PTM_RATIO, 0));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        
        
        if (isRetina) {
            CCSprite *platform = [CCSprite spriteWithFile:@"platform3.png"];
            platform.position = ccp(x*PTM_RATIO + 44, 2*PTM_RATIO-154);
            [self addChild:platform z:10];
            platformBody->SetUserData(platform);
        } else {
            CCSprite *platform = [CCSprite spriteWithFile:@"NRplatform3.png"];
            platform.position = ccp(x*PTM_RATIO + 44, 2*PTM_RATIO-154);
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

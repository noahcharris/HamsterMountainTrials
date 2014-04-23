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

#import "PhysicsSprite.h"

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









-(id) init
{
	if( (self=[super init])) {
        
        self.isTouchEnabled = YES;
		CGSize winSize = [CCDirector sharedDirector].winSize;
        
        lastColumnCornerDistance = 10;
        lastColumnCornerHeight = 0;
        
        
        //draw background
        _background = [CCSprite spriteWithFile:@"background.png"];
        _background.position = ccp(winSize.width/2, winSize.height/2);
        [self addChild:_background];
        
        
        
        // Create a world
        b2Vec2 gravity = b2Vec2(0.0f, -10.5f);
        _world = new b2World(gravity);
        
        
        contactListener = new MyContactListener;
        
        _world->SetContactListener(contactListener);
        
        
        //debug drawing setup
        m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		_world->SetDebugDraw(m_debugDraw);
		uint32 flags = 0;
		flags += b2Draw::e_shapeBit;
		m_debugDraw->SetFlags(flags);
        
        
        
        
        [self createNewHamster];
        

        
        [self drawStartingArea];
        
        
        //[self drawColumn:7 atDistance:10 atHeight:1];
        
        
        
        [self schedule:@selector(tick:)];
        
        //[self schedule:@selector(checkAndRemoveColumns) interval:3.0];
        
        
        

	}
	return self;
}





//THIS IS WHERE EVERYTHING IS UPDATED

- (void)tick:(ccTime) dt {
    
    
    
    
    _world->Step(dt, 10, 10);
    //ball
    //CCSprite *ballData = (CCSprite *)b->GetUserData();
    _ball.position = ccp(_body->GetPosition().x * PTM_RATIO,
                            _body->GetPosition().y * PTM_RATIO);
    _ball.rotation = -1 * CC_RADIANS_TO_DEGREES(_body->GetAngle());
    
    _lines.position = ccp(_body->GetPosition().x * PTM_RATIO,
                         _body->GetPosition().y * PTM_RATIO);
    _lines.rotation = -1 * CC_RADIANS_TO_DEGREES(_body->GetAngle());
    
    _shading.position = ccp(_body->GetPosition().x * PTM_RATIO,
                            _body->GetPosition().y * PTM_RATIO);
    
    //hamster
    //NSLog(@"HAMSTER:  %f", _hamster.position.x);
    _hamster.position = ccp(_body->GetPosition().x * PTM_RATIO,
                           _body->GetPosition().y * PTM_RATIO);


    
    if (_body->GetAngularVelocity() > -10.0f) {
        
        _body->ApplyTorque(-40);
        
    }
    //NSLog(@"%f", _body->GetAngularVelocity());
    
   // NSLog(@"%d", contactListener->getGround());
    

    b2Vec2 pos = _body->GetPosition();
	CGPoint newPos = ccp(-1 * pos.x * PTM_RATIO + 110, self.position.y * PTM_RATIO);
	[self setPosition:newPos];
    
    //scroll background
    CGSize winSize = [CCDirector sharedDirector].winSize;
    _background.position = ccp(pos.x * PTM_RATIO - 110 + winSize.width/2, self.position.y * PTM_RATIO + winSize.height/2);
    
    //game over stuff
    if (gameOver) {
        _restartButton.position = ccp(pos.x * PTM_RATIO + 300, self.position.y * PTM_RATIO + 270);
    }
    
    //DRAWING COLUMNS
    if ((pos.x + 50) > lastColumnCornerDistance) {
        [self drawNextColumn];
    }
    
    
    
    
    
    if (pos.y < -2.7) {
        //NSLog(@"END GAME");
        
        if (!gameOver) {
            _restartButton= [CCMenuItemImage
                            itemFromNormalImage:@"Icon.png" selectedImage:@"Icon-Small.png"
                            target:self selector:@selector(restartTapped)];
            _restartButton.position = ccp(400, 280);
            starMenu = [CCMenu menuWithItems:_restartButton, nil];
            starMenu.position = CGPointZero;
            [self addChild:starMenu];
        }
        gameOver = true;
    }
    
}



- (void)kick1 {
        if (!nextKick) {
            b2Vec2 force = b2Vec2(0, 20);
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
        b2Vec2 force = b2Vec2(0, 7);
        _body->ApplyLinearImpulse(force,_body->GetPosition());
    }
}



- (void)restartTapped {
    
    //remove the restart
    [self checkAndRemoveColumns];
    [self drawStartingArea];
    [self createNewHamster];
    gameOver = false;
    [self removeChild:starMenu cleanup:YES];
    
}



-(void) createNewHamster {
    _ball = [CCSprite spriteWithFile:@"hamsterEmptyBall.png" rect:CGRectMake(0, 0, 52, 52)];
    //_hamster = [CCSprite spriteWithFile:@"hamsterRun1.png"];
    //_hamster.position = ccp(100, 300);
    _ball.position = ccp(100, 300);
    [self addChild:_ball z:0];
    //[self addChild:_hamster z:1];
    
    // Create ball body and shape
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(100/PTM_RATIO, 100/PTM_RATIO);
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
    
    
    _shading = [CCSprite spriteWithFile:@"hamsterShading.png" rect:CGRectMake(0, 0, 52, 52)];
    _shading.position = ccp(100, 300);
    [self addChild:_shading];
    
    //animation
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"hamsterRun.plist"];
    
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"hamsterRun.png"];
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
    
}



-(void) drawStartingArea {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    // Create edges around the entire screen
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0,0);
    
    b2Body *groundBody = _world->CreateBody(&groundBodyDef);
    b2EdgeShape groundEdge;
    b2FixtureDef boxShapeDef;
    boxShapeDef.friction = 10.0f;
    boxShapeDef.shape = &groundEdge;
    
    
    //chain stuff
    b2Vec2 vs[4];
    
    vs[0].Set(1.7f, 0.0f);
    
    vs[1].Set(2.0f, 1.25f);
    
    vs[2].Set(0.0f, 0.0f);
    
    vs[3].Set(-3.6f, 0.4f);
    
    b2ChainShape chain;
    b2FixtureDef chainShapeDef;
    chainShapeDef.friction = 10.0f;
    chainShapeDef.shape = &chain;
    
    chain.CreateChain(vs, 4);
    
    groundBody->CreateFixture(&chainShapeDef);
    
    
    //wall definitions
    groundEdge.Set(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RATIO, 0));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(0,0), b2Vec2(0,winSize.height/PTM_RATIO));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(0, winSize.height/PTM_RATIO),
                   b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO));
    groundBody->CreateFixture(&boxShapeDef);
}


-(void) drawNextColumn {
    NSLog(@"Draw next column");
    float x = (float)[self getRandomNumberBetween:3 to:7];
    int n = [self getRandomNumberBetween:1 to:7];
    float temp = [self drawColumn:n atDistance: (lastColumnCornerDistance + x) atHeight:1];
    lastColumnCornerDistance += temp + x;
    
}

-(void) checkAndRemoveColumns {
    //if any bodies in the column array (I will make one) are sufficiently behind the current position,
    //remove them
    for (b2Body* b = _world->GetBodyList(); b; b = b->GetNext())
    {
        _world->DestroyBody(b);
        if (b->GetUserData() != nil) {
            cout << "HELLO";
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

    
    
    
        CCSprite *platform = [CCSprite spriteWithFile:@"platform1.png"];
        platform.position = ccp(x*PTM_RATIO + 44, y*PTM_RATIO-130);
        [self addChild:platform z:10];
        
        platformBody->SetUserData(platform);
        
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
        
        
        
        
        CCSprite *platform = [CCSprite spriteWithFile:@"platform2.png"];
        platform.position = ccp(x*PTM_RATIO + 59.5, y*PTM_RATIO-124);
        [self addChild:platform z:10];
        
        platformBody->SetUserData(platform);
        
        return 119.0/PTM_RATIO;

    } else if (n == 3) {
        
        platformEdge1.Set(b2Vec2(x, y), b2Vec2(x + 110.0/PTM_RATIO , y - 50.0/PTM_RATIO));
        platformEdge2.Set(b2Vec2(x, y), b2Vec2(x, 0));
        platformEdge3.Set(b2Vec2(x + 110.0/PTM_RATIO, y - 50.0/PTM_RATIO), b2Vec2(x + 110.0/PTM_RATIO, 0));
        
        platformFixtureDef.shape = &platformEdge1;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge2;
        platformBody->CreateFixture(&platformFixtureDef);
        
        platformFixtureDef.shape = &platformEdge3;
        platformBody->CreateFixture(&platformFixtureDef);
        
        
        
        
        CCSprite *platform = [CCSprite spriteWithFile:@"platform3.png"];
        platform.position = ccp(x*PTM_RATIO + 55, y*PTM_RATIO-175);
        [self addChild:platform z:10];
        
        platformBody->SetUserData(platform);
        
        return 110.0/PTM_RATIO;
        
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
        
        
        CCSprite *platform = [CCSprite spriteWithFile:@"platform4.png"];
        platform.position = ccp(x*PTM_RATIO + 60, y*PTM_RATIO-150);
        [self addChild:platform z:10];
        
        platformBody->SetUserData(platform);
        
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
        
        CCSprite *platform = [CCSprite spriteWithFile:@"platform5.png"];
        platform.position = ccp(x*PTM_RATIO + 59.5, y*PTM_RATIO-100);
        [self addChild:platform z:10];
        
        platformBody->SetUserData(platform);
        
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
        
        CCSprite *platform = [CCSprite spriteWithFile:@"platform6.png"];
        platform.position = ccp(x*PTM_RATIO + 55, y*PTM_RATIO-124);
        [self addChild:platform z:10];
        
        platformBody->SetUserData(platform);
        
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
        
        CCSprite *platform = [CCSprite spriteWithFile:@"platform7.png"];
        platform.position = ccp(x*PTM_RATIO + 100, y*PTM_RATIO-119);
        [self addChild:platform z:10];
        
        platformBody->SetUserData(platform);
        
        return 200.0/PTM_RATIO;
        
    }




    
    
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

@end

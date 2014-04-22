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


@property (nonatomic, strong) CCSprite *hamster;
//@property (nonatomic, strong) CCAction *walkAction;
//@property (nonatomic, strong) CCAction *moveAction;

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
        
        run = false;
        
        
        
        // Create a world
        b2Vec2 gravity = b2Vec2(0.0f, -9.8f);
        _world = new b2World(gravity);
        
        
        //debug drawing setup
        m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		_world->SetDebugDraw(m_debugDraw);
		uint32 flags = 0;
		flags += b2Draw::e_shapeBit;
		m_debugDraw->SetFlags(flags);
        
        
        
        
        [self createNewHamster];
        
        
        
        
        

        
        [self drawStartingArea];
        
        
        
        [self schedule:@selector(tick:)];
        
        [self schedule:@selector(checkAndRemoveColumns) interval:3.0];
        
        
        

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
            
    //hamster
    //NSLog(@"HAMSTER:  %f", _hamster.position.x);
    _hamster.position = ccp(_body->GetPosition().x * PTM_RATIO,
                           _body->GetPosition().y * PTM_RATIO);


    
    if (_body->GetAngularVelocity() > -10.0f) {
        
        _body->ApplyTorque(-40);
        
    }
    //NSLog(@"%f", _body->GetAngularVelocity());
    

    b2Vec2 pos = _body->GetPosition();
	
	CGPoint newPos = ccp(-1 * pos.x * PTM_RATIO + 110, self.position.y * PTM_RATIO);
	
	[self setPosition:newPos];
    
    if (gameOver) {
        _restartButton.position = ccp(pos.x * PTM_RATIO + 300, self.position.y * PTM_RATIO + 270);
    }
    
    //check for game end
    if (pos.y < -2.7) {
        NSLog(@"END GAME");
        
        if (!gameOver) {
//          [self createNewHamster];
        
            // create restart button
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





//need to throttle kick?

- (void)kick1 {
        if (!nextKick) {
            b2Vec2 force = b2Vec2(0, 20);
            //_body->ApplyLinearImpulse(force,_body->GetPosition());
            if (contactListener->getGround()) {
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
    [self createNewHamster];
    gameOver = false;
    [self removeChild:starMenu cleanup:YES];
    
}

-(void) checkAndDrawNextColumn {
    //check how far away the 'lastColumnEdge' is. If it is close enough, generate
    //a random number between a set bounds, and create the next column that distance ahead
    //of lastColumnEdge,
    //generate a second random value between 1 and n, use that to determine which of n options will be drawn
    //then give lastColumnEdge its new value.
}


-(void) checkAndRemoveColumns {
    //if any bodies in the column array (I will make one) are sufficiently behind the current position,
    //remove them
}


-(void) createNewHamster {
    _ball = [CCSprite spriteWithFile:@"iphoneHamsterBall.png" rect:CGRectMake(0, 0, 52, 52)];
    //_hamster = [CCSprite spriteWithFile:@"hamsterRun1.png"];
    //_hamster.position = ccp(100, 300);
    _ball.position = ccp(100, 300);
    [self addChild:_ball z:0];
    //[self addChild:_hamster z:1];
    
    // Create ball body and shape
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(100/PTM_RATIO, 50/PTM_RATIO);
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
    
    contactListener = new MyContactListener;
    
    _world->SetContactListener(contactListener);
    
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
    
    groundEdge.Set(b2Vec2(19, 0), b2Vec2(22, 0));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(27, 0), b2Vec2(30, 0));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(36, 2), b2Vec2(40, 1.7));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(45, 1), b2Vec2(50, 1.4));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(59.6, 3), b2Vec2(70, 3));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(75, 5.5), b2Vec2(82, 6.2));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(90, 0.5), b2Vec2(93, 0.3));
    groundBody->CreateFixture(&boxShapeDef);
    
    groundEdge.Set(b2Vec2(100, 0.5), b2Vec2(110, 0.3));
    groundBody->CreateFixture(&boxShapeDef);
    
    
    groundEdge.Set(b2Vec2(0, winSize.height/PTM_RATIO),
                   b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO));
    groundBody->CreateFixture(&boxShapeDef);
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
    [self kick1];
    nextKick = true;
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    nextKick = false;
}

@end

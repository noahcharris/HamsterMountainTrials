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
-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
-(void) tick:(ccTime)dt;
- (void)kick;
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
        
        // Create sprite and add it to the layer
        
        _ball = [CCSprite spriteWithFile:@"ball.png" rect:CGRectMake(0, 0, 52, 52)];
        _ball.position = ccp(100, 300);
        [self addChild:_ball];
        
        //this is set to true during touch sequence
        nextKick = false;
    
        
        
        // Create a world
        b2Vec2 gravity = b2Vec2(0.0f, -8.0f);
        _world = new b2World(gravity);
        
        
        //debug drawing setup
        m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		_world->SetDebugDraw(m_debugDraw);
		uint32 flags = 0;
		flags += b2Draw::e_shapeBit;
		m_debugDraw->SetFlags(flags);
        
        
        
        
        
        
        // Create edges around the entire screen
        b2BodyDef groundBodyDef;
        groundBodyDef.position.Set(0,0);
        
        b2Body *groundBody = _world->CreateBody(&groundBodyDef);
        b2EdgeShape groundEdge;
        b2FixtureDef boxShapeDef;
        boxShapeDef.friction = 10.0f;
        boxShapeDef.shape = &groundEdge;
        
        
        
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
        
        
        //my own contributions:
        groundEdge.Set(b2Vec2(0, 0), b2Vec2(6, 3));
        groundBody->CreateFixture(&boxShapeDef);
        
        groundEdge.Set(b2Vec2(19, 0), b2Vec2(22, 0));
        groundBody->CreateFixture(&boxShapeDef);
        
        groundEdge.Set(b2Vec2(25, 0), b2Vec2(30, 0));
        groundBody->CreateFixture(&boxShapeDef);
        
        groundEdge.Set(b2Vec2(36, 2), b2Vec2(40, 1.7));
        groundBody->CreateFixture(&boxShapeDef);

        groundEdge.Set(b2Vec2(45, 1), b2Vec2(50, 1.4));
        groundBody->CreateFixture(&boxShapeDef);

        groundEdge.Set(b2Vec2(60, 3), b2Vec2(70, 3));
        groundBody->CreateFixture(&boxShapeDef);

        
        
        
        groundEdge.Set(b2Vec2(0, winSize.height/PTM_RATIO),
                       b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO));
        groundBody->CreateFixture(&boxShapeDef);
        
//        groundEdge.Set(b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO),
//                       b2Vec2(winSize.width/PTM_RATIO, 0));
//        groundBody->CreateFixture(&boxShapeDef);
        
        
        // Create ball body and shape
        b2BodyDef ballBodyDef;
        ballBodyDef.type = b2_dynamicBody;
        ballBodyDef.position.Set(100/PTM_RATIO, 300/PTM_RATIO);
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
        sensorShape.SetAsBox(0.5, 0.3, b2Vec2(0,-0.7), 0);
        
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
        
        
        
        
        
        //[self schedule:@selector(kick) interval:3.0];
        
        [self schedule:@selector(tick:)];
        

	}
	return self;
}



//THIS IS WHERE EVERYTHING IS UPDATED

- (void)tick:(ccTime) dt {
    
    _world->Step(dt, 10, 10);
    for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) {
        if (b->GetUserData() != NULL) {
            CCSprite *ballData = (CCSprite *)b->GetUserData();
            ballData.position = ccp(b->GetPosition().x * PTM_RATIO,
                                    b->GetPosition().y * PTM_RATIO);
            ballData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
        }
    }
    
    if (_body->GetAngularVelocity() > -10.0f) {
        
        _body->ApplyTorque(-21);
        
    }
    //NSLog(@"%f", _body->GetAngularVelocity());
    
    b2Vec2 pos = _body->GetPosition();
	
	CGPoint newPos = ccp(-1 * pos.x * PTM_RATIO + 110, self.position.y * PTM_RATIO);
	
	[self setPosition:newPos];
    
    
    
    //check for game end
    if (pos.y < -2.7) {
        NSLog(@"END GAME");
    }
    
}

//need to throttle kick

- (void)kick {
    b2Vec2 force = b2Vec2(0, 20);
    //_body->ApplyLinearImpulse(force,_body->GetPosition());
    if (contactListener->getGround()) {
        NSLog(@"kick1");
        _body->ApplyLinearImpulse(force,_body->GetPosition());
    }
    //_body->ApplyTorque(-10);

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


//-(void) initPhysics
//{
//	
//	CGSize s = [[CCDirector sharedDirector] winSize];
//	
//	b2Vec2 gravity;
//	gravity.Set(0.0f, -10.0f);
//	world = new b2World(gravity);
//	
//	
//	// Do we want to let bodies sleep?
//	world->SetAllowSleeping(true);
//	
//	world->SetContinuousPhysics(true);
//	
//	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
//	world->SetDebugDraw(m_debugDraw);
//	
//	uint32 flags = 0;
//	flags += b2Draw::e_shapeBit;
//	//		flags += b2Draw::e_jointBit;
//	//		flags += b2Draw::e_aabbBit;
//	//		flags += b2Draw::e_pairBit;
//	//		flags += b2Draw::e_centerOfMassBit;
//	m_debugDraw->SetFlags(flags);		
//	
//	
//	// Define the ground body.
//	b2BodyDef groundBodyDef;
//	groundBodyDef.position.Set(0, 0); // bottom-left corner
//	
//	// Call the body factory which allocates memory for the ground body
//	// from a pool and creates the ground box shape (also from a pool).
//	// The body is also added to the world.
//	b2Body* groundBody = world->CreateBody(&groundBodyDef);
//	
//	// Define the ground box shape.
//	b2EdgeShape groundBox;		
//	
//	// bottom
//	
//	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
//	groundBody->CreateFixture(&groundBox,0);
//	
//	// top
//	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
//	groundBody->CreateFixture(&groundBox,0);
//	
//	// left
//	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
//	groundBody->CreateFixture(&groundBox,0);
//	
//	// right
//	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
//	groundBody->CreateFixture(&groundBox,0);
//}

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

//-(void) addNewSpriteAtPosition:(CGPoint)p
//{
//	CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
//	CCNode *parent = [self getChildByTag:kTagParentNode];
//	
//	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
//	//just randomly picking one of the images
//	int idx = (CCRANDOM_0_1() > .5 ? 0:1);
//	int idy = (CCRANDOM_0_1() > .5 ? 0:1);
//	PhysicsSprite *sprite = [PhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(32 * idx,32 * idy,32,32)];						
//	[parent addChild:sprite];
//	
//	sprite.position = ccp( p.x, p.y);
//	
//	// Define the dynamic body.
//	//Set up a 1m squared box in the physics world
//	b2BodyDef bodyDef;
//	bodyDef.type = b2_dynamicBody;
//	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
//	b2Body *body = world->CreateBody(&bodyDef);
//	
//	// Define another box shape for our dynamic body.
//	b2PolygonShape dynamicBox;
//	dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
//	
//	// Define the dynamic body fixture.
//	b2FixtureDef fixtureDef;
//	fixtureDef.shape = &dynamicBox;	
//	fixtureDef.density = 1.0f;
//	fixtureDef.friction = 0.3f;
//	body->CreateFixture(&fixtureDef);
//	
//	[sprite setPhysicsBody:body];
//}
//
//-(void) update: (ccTime) dt
//{
//	//It is recommended that a fixed time step is used with Box2D for stability
//	//of the simulation, however, we are using a variable time step here.
//	//You need to make an informed choice, the following URL is useful
//	//http://gafferongames.com/game-physics/fix-your-timestep/
//	
//	int32 velocityIterations = 8;
//	int32 positionIterations = 1;
//	
//	// Instruct the world to perform a single step of simulation. It is
//	// generally best to keep the time step and iterations fixed.
//	world->Step(dt, velocityIterations, positionIterations);	
//}


- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    nextKick = true;
    [self kick];
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    nextKick = false;
}

@end

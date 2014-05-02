//
//  IntroLayer.m
//  KrazyKart
//
//  Created by Noah Harris on 4/18/14.
//  Copyright __MyCompanyName__ 2014. All rights reserved.
//


// Import the interfaces
#import "IntroLayer.h"
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"


#pragma mark - IntroLayer

// HelloWorldLayer implementation
@implementation IntroLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	IntroLayer *layer = [IntroLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// 
-(void) onEnter
{
	[super onEnter];
    NSLog(@"On ENTER!");
    //much better here don't you think?
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"wind.mp3"];
	
	// In one second transition to the new scene
	//[self scheduleOnce:@selector(makeTransition:) delay:0];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.0 scene:[HelloWorldLayer scene] withColor:ccWHITE]];
}

-(void) makeTransition:(ccTime)dt
{
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.0 scene:[HelloWorldLayer scene] withColor:ccWHITE]];
}
@end

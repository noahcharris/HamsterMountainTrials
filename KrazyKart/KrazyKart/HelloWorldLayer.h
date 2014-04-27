//
//  HelloWorldLayer.h
//  KrazyKart
//
//  Created by Noah Harris on 4/18/14.
//  Copyright __MyCompanyName__ 2014. All rights reserved.
//


#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "MyContactListener.h"
#import "BannerViewController.h"
#import "IAPHelper.h"
#include <queue>

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32


@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
	b2World* _world;
	GLESDebugDraw *m_debugDraw;
    b2Body *_body;
    b2Body *_sensor;
    CCSprite *_background;
    CCSprite *_ball;
    CCSprite *_lines;
    CCSprite *_shading;
    CCSprite *_hamster;
    b2RevoluteJoint *_joint;
    
    float lastColumnCornerDistance;
    float lastColumnCornerHeight;
    
    NSMutableArray *runFrames;
    CCAction *runAction;
    CCAnimation *runAnim;
    CCSprite *hamster;
    
    MyContactListener *contactListener;
    
    BOOL gameOver;
    BOOL nextKick;
    
    
    
    //in app purchase stuff
    IAPHelper* _helper;
    NSMutableArray *_products;
    BOOL adsRemoved;
    BannerViewController *banner;
    
    
    std::queue<int> *score_queue;
    int score;
    CCLabelTTF *scoreLabel;
    CCLabelTTF *highScoreLabel;
    
    
    CCMenuItem *_restartButton;
    CCMenu *starMenu;
    


}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end

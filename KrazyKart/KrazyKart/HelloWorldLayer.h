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

#import "Reachability.h"

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
    CCSpriteBatchNode *spriteSheet;
    b2RevoluteJoint *_joint;
    
    float lastColumnCornerDistance;
    float lastColumnCornerHeight;
    
    int platformNumber;
    
    int lastPlatformNumber;
    
    NSMutableArray *runFrames;
    CCAction *runAction;
    CCAnimation *runAnim;
    CCSprite *hamster;
    
    MyContactListener *contactListener;
    
    BOOL gameOver;
    BOOL nextKick;
    
    float kick1x;
    float kick2x;
    float kick1y;
    float kick2y;
    float scaling;
    float torque;
    float topSpeed;
    float bounce;
    b2Vec2 gravity1;
    b2Vec2 gravity2;
    
    float screenOffsetX;
    float screenOffsetY;
    
    float backgroundOffsetX;
    float backgroundOffsetY;
    
    float hamsterStartX;
    float hamsterStartY;
    
    float scoreLabelX;
    float scoreLabelY;
    
    float highScorePrefixX;
    float highScorePrefixY;
    
    float scorePrefixX;
    float scorePrefixY;
    
    float highScoreX;
    float highScoreY;
    
    float restartX;
    float restartY;
    
    float restartX1;
    float restartY1;
    
    float restartX2;
    float restartY2;
    
    float removeAdsX;
    float removeAdsY;
    
    float instructionsX;
    float instructionsY;
    
    float scoreColumn1X;
    float scoreColumn2X;
    float scoreColumn3X;
    
    //for providing alternate score positions for in-game/game-over screens
    float scoreColumn1X1;
    float scoreColumn2X1;
    float scoreColumn3X1;
    float scoreColumn1X2;
    float scoreColumn2X2;
    float scoreColumn3X2;
    
    float scoreColumn1Y1;
    float scoreColumn2Y1;
    float scoreColumn3Y1;
    float scoreColumn1Y2;
    float scoreColumn2Y2;
    float scoreColumn3Y2;
    
    
    float highScoreColumn1X;
    float highScoreColumn2X;
    float highScoreColumn3X;
    
    float scoreColumn1Y;
    float scoreColumn2Y;
    float scoreColumn3Y;
    float highScoreColumn1Y;
    float highScoreColumn2Y;
    float highScoreColumn3Y;
    
    float scoreOffset;
    float highScoreOffset;

    
    BOOL starting;
    
    //dimensions
    BOOL isiPhone;
    BOOL isiPhone5;
    BOOL isRetina;
    
    
    //in app purchase stuff
    IAPHelper* _helper;
    NSMutableArray *_products;
    SKProduct *_removeAds;
    
    BOOL adsRemoved;
    BOOL showingBuyPopup;
    
    BOOL showRemoveAdsButton;
    
    BannerViewController *_banner;
    
    
    std::queue<int> *score_queue;
    int score;
    CCLabelTTF *scoreLabel;
    CCLabelTTF *highScoreLabel;
    
    CCSprite *instructions;
    
    CCSpriteBatchNode *numberSprites;
    
    NSMutableArray *numberArray;
    
    CCSprite *number0;
    CCSprite *number1;
    CCSprite *number2;
    CCSprite *number3;
    CCSprite *number4;
    CCSprite *number5;
    CCSprite *number6;
    CCSprite *number7;
    CCSprite *number8;
    CCSprite *number9;
    
    CCSprite *scoreColumn1;
    CCSprite *scoreColumn2;
    CCSprite *scoreColumn3;
    CCSprite *highScoreColumn1;
    CCSprite *highScoreColumn2;
    CCSprite *highScoreColumn3;
    
    CCSprite *scorePrefix;
    CCSprite *highScorePrefixLabel;
    CCMenuItem *_restartButton;
    CCMenuItem *_removeAdsButton;
    CCMenu *starMenu;
    


}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end

//
//  MyContactListener.h
//  KrazyKart
//
//  Created by Noah Harris on 4/21/14.
//
//

#ifndef __KrazyKart__MyContactListener__
#define __KrazyKart__MyContactListener__

#include <iostream>
#include "Box2D.h"

class MyContactListener : public b2ContactListener
{
private:
    bool onGround = false;
public:
    void BeginContact(b2Contact* contact);
    void EndContact(b2Contact* contact);
    bool getGround();
};

#endif /* defined(__KrazyKart__MyContactListener__) */

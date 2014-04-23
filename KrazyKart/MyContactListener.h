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
    int numFootContacts = 0;
public:
    MyContactListener();
    void BeginContact(b2Contact* contact);
    void EndContact(b2Contact* contact);
    int getGround();
};

#endif /* defined(__KrazyKart__MyContactListener__) */

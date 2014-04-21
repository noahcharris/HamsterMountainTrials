//
//  MyContactListener.h
//  KrazyKart
//
//  Created by Noah Harris on 4/21/14.
//
//

#ifndef KrazyKart_MyContactListener_h
#define KrazyKart_MyContactListener_h

class MyContactListener : public b2ContactListener
{
public:
    BOOL onGround;
    
    void BeginContact(b2Contact* contact);
    
    void EndContact(b2Contact* contact);
    
    BOOL getGround();

};

#endif

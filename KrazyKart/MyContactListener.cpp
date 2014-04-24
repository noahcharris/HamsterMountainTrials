//
//  MyContactListener.cpp
//  KrazyKart
//
//  Created by Noah Harris on 4/21/14.
//
//

#include "MyContactListener.h"
#import "Box2D.h"


MyContactListener::MyContactListener() {
    numFootContacts = 0;
}
    
void MyContactListener::BeginContact(b2Contact* contact) {
        //check if fixture A was the foot sensor
        void* fixtureUserData = contact->GetFixtureA()->GetUserData();
        if ( (int)fixtureUserData == 3 ) {
            numFootContacts = numFootContacts + 1;
        }
        
        //check if fixture B was the foot sensor
        fixtureUserData = contact->GetFixtureB()->GetUserData();
        if ( (int)fixtureUserData == 3 ) {
            numFootContacts = numFootContacts + 1;
        }
    }
    
void MyContactListener::EndContact(b2Contact* contact) {
        //check if fixture A was the foot sensor
        void* fixtureUserData = contact->GetFixtureA()->GetUserData();
        if ( (int)fixtureUserData == 3 ) {
            numFootContacts = numFootContacts - 1;
        }
        //numFootContacts--;
        //check if fixture B was the foot sensor
        fixtureUserData = contact->GetFixtureB()->GetUserData();
        if ( (int)fixtureUserData == 3 ) {
            numFootContacts = numFootContacts - 1;
        }
    }
    
int MyContactListener::getGround() {
        if (numFootContacts > 0) {
            return 1;
        } else {
            return 0;
        }
    }
    
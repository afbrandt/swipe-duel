//
//  Gameplay.h
//  SwipeDuel
//
//  Created by Andrew Brandt on 11/8/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
@class SessionManager;

typedef NS_ENUM(NSInteger, GameEvent) {
    GameEventReady,
    GameEventEnd,
    GameEventTap,
    GameEventUpOne,
    GameEventDownOne,
    GameEventLeftOne,
    GameEventRightOne,
    GameEventFizzle
};

@interface Gameplay : CCNode<MCSessionDelegate>

@property (nonatomic, strong) SessionManager *connectionManager;

@property (nonatomic, assign) BOOL isSwiping, isBusy;
@property (nonatomic, assign) CGPoint first, last;
@property (nonatomic, strong) NSMutableArray *swipe;
@property (nonatomic, strong) NSArray *peers;

@end

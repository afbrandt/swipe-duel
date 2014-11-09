//
//  Gameplay.h
//  SwipeDuel
//
//  Created by Andrew Brandt on 11/8/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

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

@interface Gameplay : CCNode

@end

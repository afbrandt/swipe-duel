//
//  Gameplay.m
//  SwipeDuel
//
//  Created by Andrew Brandt on 11/8/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "MainScene.h"
#import "Player.h"
#import "AppDelegate.h"

@implementation Gameplay {
    CCNode *opponent;
    Player *player;
    float delay;
}


- (void)didLoadFromCCB {
    self.isSwiping = NO;
    self.isBusy = NO;
    self.swipe = [NSMutableArray new];
    self.peers = ((AppController *)[[UIApplication sharedApplication] delegate]).manager.session.connectedPeers;
    self.connectionManager = ((AppController *)[[UIApplication sharedApplication] delegate]).manager;
    self.last = ccpAdd(opponent.position, ccp(100,0));
}

- (void)onEnter {
    [super onEnter];
    self.userInteractionEnabled = YES;
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedEvent:) name:@"event-received" object:nil];
    self.connectionManager.session.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameOver:) name:@"player-dead" object:nil];
}

- (void)update: (CCTime)dt {
    if (self.isBusy) {
        delay -= dt;
        if (delay < 0.0f) {
            self.isBusy = NO;
        }
    }
}

- (void)onExit {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super onExit];
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    self.isSwiping = YES;
    self.first = touch.locationInWorld;
    [self.swipe addObject:touch];
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    [self.swipe addObject:touch];
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    self.isSwiping = NO;
    self.last = touch.locationInWorld;
    [self.swipe addObject:touch];
    
    if (!self.isBusy) {
        GameEvent spell = [self getSpellFromSwipe];
    
        //[self sendEvent:GameEventTap];
        NSLog(@"current magic: %ld", (long)player.magicPoints);
    
        self.isBusy = YES;
        if([player canCast:spell]) {
            NSLog(@"spell cast!");
            [self createEvent:spell];
            [self sendEvent:spell];
        } else {
            NSLog(@"spell failed");
            [self createEvent:GameEventFizzle];
            [self sendEvent:GameEventFizzle];
        }
    }
    NSLog(@"%lo touches cleared...", (unsigned long)[self.swipe count]);
    [self.swipe removeAllObjects];
}

- (GameEvent)getSpellFromSwipe {
    if ([self.swipe count] < 5) {
        return GameEventTap;
    } else {
        int diffX = self.last.x - self.first.x;
        int diffY = self.last.y - self.first.y;
        if (diffX == 0) diffX = 0.1f;
        if (diffY/diffX > 1.8) {
            if (diffY > 0) {
                return GameEventUpOne;
            } else {
                return GameEventDownOne;
            }
        } else {
            if (diffX > 0) {
                return GameEventRightOne;
            } else {
                return GameEventLeftOne;
            }
        }
    }
    return GameEventFizzle;
}

- (void)gameOver: (NSNotification *)message {
    [self sendEvent:GameEventEnd];
    [self.animationManager runAnimationsForSequenceNamed:@"RecapSummon"];
}

- (void)mainMenu {
    MainScene *main = (MainScene *)[CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] presentScene:main];
}

#pragma mark - Event handling methods

- (void)sendEvent: (GameEvent)event {
    NSNumber *num = [NSNumber numberWithInteger:event];
    NSDictionary *payload = @{@"event":num};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:payload];
    //NSData *data = [@"hello world" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    [self.connectionManager.session sendData:data toPeers:self.peers withMode:MCSessionSendDataReliable error:&error];
}

- (void)createEvent: (GameEvent)event {
    [player spendMagic:event];
    CCAction *path;
    CCNode *spell = [CCNode node];
    spell.position = self.last;
    CCParticleSystem *effect;
    switch (event) {
        case GameEventTap:
            delay = 0.1f;
            self.isBusy = YES;
            effect = (CCParticleSystem *)[CCBReader load:@"Spells/MagicMissile"];
            effect.autoRemoveOnFinish = YES;
            path = [CCActionMoveTo actionWithDuration:1.0f position:opponent.position];
            break;
        case GameEventUpOne:
            delay = 1.0f;
            self.isBusy = YES;
            spell = [CCBReader load:@"Spells/FireBlast"];
            spell.position = self.last;
            path = [CCActionJumpTo actionWithDuration:1.0f position:opponent.position height:10.f jumps:1];
            break;
        case GameEventDownOne:
            delay = 0.3f;
            self.isBusy = YES;
            spell = [CCBReader load:@"Spells/Nullify"];
            spell.position = opponent.position;
            path = [CCAction action];
            break;
        case GameEventLeftOne:
            delay = 2.0f;
            self.isBusy = YES;
            spell = [CCBReader load:@"Spells/MegaBlast"];
            spell.position = self.last;
            path = [CCActionMoveTo actionWithDuration:2.0f position:opponent.position];
            break;
        case GameEventRightOne:
            delay = 1.0f;
            self.isBusy = YES;
            spell = (CCParticleSystem *)[CCBReader load:@"Spells/IceStorm"];
            spell.position = ccpAdd(opponent.position, ccp(0,100));
            path = [CCAction action];
            break;
        case GameEventFizzle:
            spell = [CCNode node];
            spell.position = self.last;
            effect = (CCParticleSystem *)[CCBReader load:@"Spells/Fizzle"];
            effect.autoRemoveOnFinish = YES;
            break;
        case GameEventReady:
        case GameEventEnd:
            break;
    }
    [self addChild:spell];
    if (effect) {
        [spell addChild:effect];
    }
    if (path) {
        [spell.animationManager setCompletedAnimationCallbackBlock:^(id sender) {
            [spell removeFromParent];
        }];
        [spell runAction:path];
    }
}

- (void)receivedEvent: (NSData *)message {
    NSDictionary *payload = (NSDictionary *) [NSKeyedUnarchiver unarchiveObjectWithData:message];
    NSNumber *num = payload[@"event"];
    GameEvent event = [num integerValue];
    CCNode *spell = [CCNode node];
    CCAction *path;
    spell.position = opponent.position;
    CCParticleSystem *effect;
    switch (event) {
        case GameEventTap:
            effect = (CCParticleSystem *)[CCBReader load:@"Spells/MagicMissile"];
            effect.autoRemoveOnFinish = YES;
            path = [CCActionMoveTo actionWithDuration:1.0f position:self.first];
            break;
        case GameEventUpOne:
            spell = [CCBReader load:@"Spells/FireBlast"];
            spell.position = self.last;
            path = [CCActionJumpTo actionWithDuration:1.0f position:self.first height:0.5f jumps:1];
            break;
        case GameEventDownOne:
            spell = [CCBReader load:@"Spells/Nullify"];
            spell.position = opponent.position;
            path = [CCAction action];
            break;
        case GameEventLeftOne:
            spell = [CCBReader load:@"Spells/MegaBlast"];
            spell.position = opponent.position;
            path = [CCActionMoveTo actionWithDuration:2.0f position:self.first];
            break;
        case GameEventRightOne:
            spell = (CCParticleSystem *)[CCBReader load:@"Spells/IceStorm"];
            spell.position = ccpAdd(opponent.position, ccp(0,100));
            path = [CCAction action];
            break;
        case GameEventFizzle:
            spell = [CCNode node];
            spell.position = self.last;
            effect = (CCParticleSystem *)[CCBReader load:@"Spells/Fizzle"];
            effect.autoRemoveOnFinish = YES;
            break;
        case GameEventReady:
            break;
        case GameEventEnd:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"player-dead" object:nil];
            break;
    }
    [self addChild:spell];
    if (effect) {
        [spell addChild:effect];
    }
    if (path) {
        [spell.animationManager setCompletedAnimationCallbackBlock:^(id sender) {
            [spell removeFromParent];
        }];
        [spell runAction:path];
    }
    [player spendHealth:event];
}


#pragma mark - MCSessionDelegate methods

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    switch (state) {
        case MCSessionStateConnected:
            break;
        case MCSessionStateConnecting:
            break;
        case MCSessionStateNotConnected:
            break;
    }
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
   NSLog(@"Received new data!");
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self receivedEvent:data];
    });
}


-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
   //not used...
}


-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
   //not used...
}


-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
   //not used...
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void(^)(BOOL accept))certificateHandler {
    certificateHandler(YES);
}

@end

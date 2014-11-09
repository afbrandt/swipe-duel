//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "Gameplay.h"

@implementation MainScene {
    BOOL browsing;
    
    CCNode *contentNode;
    
    CCButton *startBrowseButton;
}

- (void)onEnter {
    [super onEnter];
    
    _appDelegate = (AppController *)[[UIApplication sharedApplication] delegate];
    startBrowseButton.userInteractionEnabled = YES;
    browsing = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startGame) name:@"peer-connect" object:nil];
}

- (void)onExit {
    [self.appDelegate.manager advertiseSelf:NO];
    [self.appDelegate.manager browse:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super onExit];
}

- (void)browseForDevice {
    startBrowseButton.userInteractionEnabled = NO;
    CCNode *dialog = [CCBReader load:@"SearchDialog" owner:self];
    dialog.position = ccp(0, self.boundingBox.size.height);
    
    CCAction *present = [CCActionMoveTo actionWithDuration:0.3f position:ccp(0,0)];
    [dialog.animationManager setCompletedAnimationCallbackBlock:^(id sender) {
        //[[self.appDelegate manager] advertiseSelf:YES];
        //[[self.appDelegate manager] browse:YES];
    }];
    [contentNode addChild:dialog];
    [dialog runAction:present];
    [[self.appDelegate manager] advertiseSelf:YES];
    [[self.appDelegate manager] browse:YES];
}

- (void)startGame {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        Gameplay *gameplay = (Gameplay *)[CCBReader loadAsScene:@"Gameplay"];
        CCTransition *fade = [CCTransition transitionCrossFadeWithDuration:0.3f];
        [[CCDirector sharedDirector] replaceScene:gameplay withTransition:fade];
    });
}

@end

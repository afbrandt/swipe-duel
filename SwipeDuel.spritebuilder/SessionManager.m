//
//  SessionManager.m
//  SwipeDuel
//
//  Created by Andrew Brandt on 11/8/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "SessionManager.h"

static NSString* const SWIPE_DUEL_SERVICE_KEY = @"swipe-duel-key";

@interface SessionManager ()

@property (nonatomic, strong) MCPeerID *remotePeerID;
@property (nonatomic, assign) MCSessionState connectionState;

@end

@implementation SessionManager

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        self.session = [[MCSession alloc] initWithPeer:self.localPeerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.localPeerID serviceType:@"swipe-duel-key"];
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID discoveryInfo:nil serviceType:@"swipe-duel-key"];
        self.browser.delegate = self;
        self.advertiser.delegate = self;
        self.session.delegate = self;
    }

    return self;
}

- (void)dealloc {
    [self.browser stopBrowsingForPeers];
    [self.advertiser stopAdvertisingPeer];
    [self.session disconnect];
}

-(void)advertiseSelf: (BOOL)shouldAdvertise {
    if (shouldAdvertise) {
        self.advertiser.delegate = self;
        [self.advertiser startAdvertisingPeer];
    } else {
        [self.advertiser stopAdvertisingPeer];
        self.advertiser = nil;
    }
}

- (void)browse: (BOOL)shouldBrowse {
    if (shouldBrowse) {
        self.browser.delegate = self;
        [self.browser startBrowsingForPeers];
    } else {
        self.browser.delegate = nil;
        [self.browser stopBrowsingForPeers];
    }
}

#pragma mark - MCSessionDelegate methods
-(void)session:(MCSession *)session peer: (MCPeerID *)peerID didChangeState: (MCSessionState)state{
    switch (state) {
        case MCSessionStateConnected:
            self.connectionState = MCSessionStateConnected;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"peer-connect" object:peerID];
            NSLog(@"connected!");
            break;
        case MCSessionStateConnecting:
            self.connectionState = MCSessionStateConnecting;
            NSLog(@"connecting...");
            break;
        case MCSessionStateNotConnected:
            NSLog(@"not connected!");
        break;
    }
}

#pragma mark - MCSessionDelegate methods
-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSLog(@"Received data!");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"event-received" object:data];
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void(^)(BOOL accept))certificateHandler {
    certificateHandler(YES);
}

#pragma mark - MCNearbyServiceAdvertiserDelegate methods
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler {
    //NSLog([[NSString alloc] initWithData:context encoding:NSASCIIStringEncoding]);
    NSLog(@"received invite");
    invitationHandler(YES, self.session);
}

#pragma mark - MCNearbyServiceBrowserDelegate methods
// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)remotePeerID withDiscoveryInfo:(NSDictionary *)info {
    BOOL shouldInvite = self.localPeerID.hash < remotePeerID.hash;
    if (shouldInvite && self.connectionState == MCSessionStateNotConnected) {
        NSLog(@"inviting peer!");
        //NSLog([remotePeerID displayName]);
        NSData *payload = [self.localPeerID.displayName dataUsingEncoding:NSASCIIStringEncoding];
        [browser invitePeer:remotePeerID toSession:self.session withContext:nil timeout:0];
    }
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"didNotStartBrowsingForPeers: %@", error);
}

@end

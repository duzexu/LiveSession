//
//  LSStreamingViewController.h
//  LiveSessions
//
//  Created by Nirav Bhatt on 3/8/13.
//  Copyright (c) 2013 IPhoneGameZone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Opentok/Opentok.h>
#import "ParseHelper.h"

enum streamingMode
{
    streamingModeIncoming = 0,
    streamingModeOutgoing = 1
};

@interface LSStreamingViewController : UIViewController<OTSessionDelegate, OTSubscriberDelegate, OTPublisherDelegate>
{
    OTSession* _session;
    OTPublisher* _publisher;
    OTSubscriber* _subscriber;
    int m_mode;
    int m_connectionAttempts;
    LSAppDelegate *appDelegate;
    bool bAudio;
}

- (IBAction)touchDisconnect:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *disconnectButton;
- (IBAction)doneStreaming:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *_statusLabel;

@property (copy, nonatomic) NSString* callReceiverID;
@property (assign, nonatomic) bool bAudio;
@property (assign, nonatomic) bool bVideo;



@end

//
//  LSStreamingViewController.m
//  LiveSessions
//
//  Created by Nirav Bhatt on 3/8/13.
//  Copyright (c) 2013 IPhoneGameZone. All rights reserved.
//

#import "LSStreamingViewController.h"


@implementation LSStreamingViewController


//TODO: Replace this with your own 8-digit API key number from tokbox.com
static NSString* const kApiKey = @"30107422";

static bool subscribeToSelf = NO; // Change to NO if you want to subscribe streams other than your own


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void) showReceiverBusyMsg
{
    self._statusLabel.text = @"Receiver is busy on another call. Please try later.";
    [self performSelector:@selector(goBack) withObject:nil afterDelay:5.0];
}

-(void)goBack
{
    self._statusLabel.hidden = YES;
    [self dismissModalViewControllerAnimated:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    appDelegate = [[UIApplication sharedApplication] delegate];
    self.bAudio = YES;
    NSLog(@"Before: %f %f %f %f", self.view.frame.origin.x,self.view.frame.origin.y,self.view.frame.size.width, self.view.frame.size.height);
    [self.view setFrame:CGRectMake(0, 44, 320, 436)];
    NSLog(@"After: %f %f %f %f", self.view.frame.origin.x,self.view.frame.origin.y,self.view.frame.size.width, self.view.frame.size.height);   
}

- (void) viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionSaved) name:kSessionSavedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReceiverBusyMsg) name:kReceiverBusyNotification object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    if (![self.callReceiverID isEqualToString:@""])
    {
        m_mode = streamingModeOutgoing; //generate session
        [self initOutGoingCall];
        //connect, publish/subscriber -> will be taken care by
        //sessionSaved observer handler.
    }
    else
    {
        m_mode = streamingModeIncoming; //connect, publish, subscribe
        m_connectionAttempts = 1;
        [self connectWithPublisherToken];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateSubscriber
{
    for (NSString* streamId in _session.streams) {
        OTStream* stream = [_session.streams valueForKey:streamId];
        if (stream.connection.connectionId != _session.connection.connectionId) {
            _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
            break;
        }
    }
}

#pragma Opentok methods
- (void) initOutGoingCall
{
    NSMutableDictionary * inputDict = [NSMutableDictionary dictionary];
    [inputDict setObject:[ParseHelper loggedInUser].objectId forKey:@"callerID"];
    [inputDict setObject:appDelegate.userTitle forKey:@"callerTitle"];
    [inputDict setObject:self.callReceiverID forKey:@"receiverID"];
    [inputDict setObject:[NSNumber numberWithBool:self.bAudio] forKey:@"isAudio"];
    [inputDict setObject:[NSNumber numberWithBool:self.bVideo] forKey:@"isVideo"];
     m_connectionAttempts = 1;
    [ParseHelper saveSessionToParse:inputDict];
}

- (void) sessionSaved
{
    [self connectWithSubscriberToken];
}

- (void) connectWithPublisherToken
{
    NSLog(@"connectWithPublisherToken");
    [self doConnect:appDelegate.publisherToken :appDelegate.sessionID];
}

- (void) connectWithSubscriberToken
{
    NSLog(@"connectWithSubscriberToken");    
    [self doConnect:appDelegate.subscriberToken :appDelegate.sessionID];
}

- (void)doConnect : (NSString *) token :(NSString *) sessionID
{
    _session = [[OTSession alloc] initWithSessionId:sessionID
                                           delegate:self];
    [_session addObserver:self forKeyPath:@"connectionCount"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [_session connectWithApiKey:kApiKey token:token];
}

- (void)doDisconnect
{
    [_session disconnect];
}

- (void)doPublish
{
    _publisher = [[OTPublisher alloc] initWithDelegate:self name:UIDevice.currentDevice.name];
    _publisher.publishAudio = self.bAudio;
    _publisher.publishVideo = self.bVideo;
    [_session publish:_publisher];
    
    //symmetry is beauty.
    float x = 5.0;
    float y = 5.0;
    float publisherWidth = 120.0;
    float publisherHeight = 120.0;
    
    [_publisher.view setFrame:CGRectMake(x,y,publisherWidth,publisherHeight)];
    [self.view addSubview:_publisher.view];
    [self.view bringSubviewToFront:self.disconnectButton];
    [self.view bringSubviewToFront:self._statusLabel];
    
    NSLog(@"%f-%f-%f-%f", _publisher.view.frame.origin.x, _publisher.view.frame.origin.y, _publisher.view.frame.size.width, _publisher.view.frame.size.height);
     
    _publisher.view.layer.cornerRadius = 10.0;
    _publisher.view.layer.masksToBounds = YES;
    _publisher.view.layer.borderWidth = 5.0;
    _publisher.view.layer.borderColor = [UIColor yellowColor].CGColor;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"connectionCount"])
    {
        //this is kept blank for possible implementation
        //in case one wants to handle more than 2 participants.
    }
}

- (void)doUnpublish
{
    [_session unpublish:_publisher];
}

#pragma mark - OTSessionDelegate methods

- (void)sessionDidConnect:(OTSession*)session
{ 
    NSLog(@"sessionDidConnect: %@", session.sessionId);
    NSLog(@"- connectionId: %@", session.connection.connectionId);
    NSLog(@"- creationTime: %@", session.connection.creationTime);
    [self.disconnectButton setHidden:NO];
    [self.view bringSubviewToFront:self.disconnectButton];
    
    self._statusLabel.text = @"Connected, waiting for stream...";  
    [self.view bringSubviewToFront:self._statusLabel];
   
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
 
    NSLog(@"sessionDidDisconnect: %@", session.sessionId);

    self._statusLabel.text = @"Session disconnected...";
    [self.view bringSubviewToFront:self._statusLabel];
    
    //for cases when the other party disconnected the session. Fire the timer again.
     self.disconnectButton.hidden = YES;
    
    //set the polling on.
    [ParseHelper setPollingTimer:YES];
    [ParseHelper deleteActiveSession];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error
{
    NSLog(@"session: didFailWithError:");
    NSLog(@"- description: %@", error.localizedDescription);
    NSString * errorMsg;
    if (m_connectionAttempts < 10)
    {
        m_connectionAttempts++;
        errorMsg = [NSString stringWithFormat:@"Session failed to connect - Reconnecting attempt %d",m_connectionAttempts];
        self._statusLabel.text = errorMsg;
        [self.view bringSubviewToFront:self._statusLabel];
        if (m_mode == streamingModeOutgoing)
        {
            [self performSelector:@selector(connectWithSubscriberToken) withObject:nil afterDelay:15.0];
        }
        else
        {
            [self performSelector:@selector(connectWithPublisherToken) withObject:nil afterDelay:15.0];
        }
    }
    else
    {
        m_connectionAttempts = 1;
        errorMsg = [NSString stringWithFormat:@"Session failed to connect - disconnecting now"];
        self._statusLabel.text = errorMsg;
        [self performSelector:@selector(doneStreaming:) withObject:nil afterDelay:10.0];
    }   
}

- (void)session:(OTSession*)mySession didReceiveStream:(OTStream*)stream
{
    NSLog(@"session: didReceiveStream:");
    NSLog(@"- connection.connectionId: %@", stream.connection.connectionId);
    NSLog(@"- connection.creationTime: %@", stream.connection.creationTime);
    NSLog(@"- session.sessionId: %@", stream.session.sessionId);
    NSLog(@"- streamId: %@", stream.streamId);
    NSLog(@"- type %@", stream.type);
    NSLog(@"- creationTime %@", stream.creationTime);
    NSLog(@"- name %@", stream.name);
    NSLog(@"- hasAudio %@", (stream.hasAudio ? @"YES" : @"NO"));
    NSLog(@"- hasVideo %@", (stream.hasVideo ? @"YES" : @"NO"));
    if ( (subscribeToSelf && [stream.connection.connectionId isEqualToString: _session.connection.connectionId])
        ||
        (!subscribeToSelf && ![stream.connection.connectionId isEqualToString: _session.connection.connectionId])
        ) {
        if (!_subscriber) {
            _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
            _subscriber.subscribeToAudio = self.bAudio;
            _subscriber.subscribeToVideo = self.bVideo;
        }
        NSLog(@"subscriber.session.sessionId: %@", _subscriber.session.sessionId);
        NSLog(@"- stream.streamId: %@", _subscriber.stream.streamId);
        NSLog(@"- subscribeToAudio %@", (_subscriber.subscribeToAudio ? @"YES" : @"NO"));
        NSLog(@"- subscribeToVideo %@", (_subscriber.subscribeToVideo ? @"YES" : @"NO"));
    }
}

- (void)session:(OTSession*)session didDropStream:(OTStream*)stream
{ 
    NSLog(@"session didDropStream (%@)", stream.streamId);
    if (!subscribeToSelf
        && _subscriber
        && [_subscriber.stream.streamId isEqualToString: stream.streamId]) {
        _subscriber = nil;
        [self updateSubscriber];     
        self._statusLabel.text = @"Stream dropped, disconnecting...";
        [self.view bringSubviewToFront:self._statusLabel];        
        [self performSelector:@selector(doneStreaming:) withObject:nil afterDelay:5.0];
    }
}

#pragma mark - OTPublisherDelegate methods

- (void)publisher:(OTPublisher*)publisher didFailWithError:(OTError*) error
{
    NSLog(@"publisher: %@ didFailWithError:", publisher);
    NSLog(@"- error code: %d", error.code);
    NSLog(@"- description: %@", error.localizedDescription);  

    self._statusLabel.text = @"Failed to share your camera feed, disconnecting...";
    [self.view bringSubviewToFront:self._statusLabel];
    
    [self performSelector:@selector(doneStreaming:) withObject:nil afterDelay:5.0];
}

- (void)publisherDidStartStreaming:(OTPublisher *)publisher
{
    NSLog(@"publisherDidStartStreaming: %@", publisher);
    NSLog(@"- publisher.session: %@", publisher.session.sessionId);
    NSLog(@"- publisher.name: %@", publisher.name);
    [self.view bringSubviewToFront:self._statusLabel];
    self._statusLabel.text = @"Started your camera feed..."; 
}

-(void)publisherDidStopStreaming:(OTPublisher*)publisher
{
    NSLog(@"publisherDidStopStreaming:%@", publisher);
    self._statusLabel.text = @"Stopping your camera feed...";
    [self.view bringSubviewToFront:self._statusLabel];
}

#pragma mark - OTSubscriberDelegate methods
- (void)subscriberDidConnectToStream:(OTSubscriber*)subscriber
{
    NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
   
    float subscriberWidth = [[UIScreen mainScreen] bounds].size.width;
    float subscriberHeight = [[UIScreen mainScreen] bounds].size.height - self.navigationController.navigationBar.frame.size.height;
    
    
    NSLog(@"screenheight %f", [[UIScreen mainScreen] bounds].size.height);
     NSLog(@"navheight %f", self.navigationController.navigationBar.frame.size.height);
    
    //fill up entire screen except navbar.
    [subscriber.view setFrame:CGRectMake(0, 0, subscriberWidth, subscriberHeight)];
    
    [self.view addSubview:subscriber.view];
    self.disconnectButton.hidden = NO;
    
    if (_publisher)
    {
        [self.view bringSubviewToFront:_publisher.view];
        [self.view bringSubviewToFront:self.disconnectButton];
        [self.view bringSubviewToFront:self._statusLabel];
    }
    subscriber.view.layer.cornerRadius = 10.0;
    subscriber.view.layer.masksToBounds = YES;
    subscriber.view.layer.borderWidth = 5.0;
    subscriber.view.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self._statusLabel.text = @"Connected and streaming...";
    [self.view bringSubviewToFront:self._statusLabel];
}

- (void)subscriberVideoDataReceived:(OTSubscriber*)subscriber {
    NSLog(@"subscriberVideoDataReceived (%@)", subscriber.stream.streamId);
    self._statusLabel.text = @"Receiving Stream...";
    [self.view bringSubviewToFront:self._statusLabel];
}

- (void)subscriber:(OTSubscriber *)subscriber didFailWithError:(OTError *)error
{
    NSLog(@"subscriber: %@ didFailWithError: ", subscriber.stream.streamId);
    NSLog(@"- code: %d", error.code);
    NSLog(@"- description: %@", error.localizedDescription);
    self._statusLabel.text = @"Error receiving video feed, disconnecting...";
    [self.view bringSubviewToFront:self._statusLabel];
    [self performSelector:@selector(doneStreaming:) withObject:nil afterDelay:5.0];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
   
    [self set_statusLabel:nil];
    [self setDisconnectButton:nil];
    [super viewDidUnload];
}

- (void) disConnectAndGoBack
{
    [self doUnpublish];
    [self doDisconnect];
    self.disconnectButton.hidden = YES;
    [ParseHelper deleteActiveSession];
    
    //set the polling on.
    [ParseHelper setPollingTimer:YES];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)doneStreaming:(id)sender
{
    [self disConnectAndGoBack];
}
- (IBAction)touchDisconnect:(id)sender
{
    [self disConnectAndGoBack];
}
@end

//
//  LSAppDelegate.h
//  LiveSessions
//
//  Created by Nirav Bhatt on 4/13/13.
//  Copyright (c) 2013 IPhoneGameZone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParseHelper.h"


@interface LSAppDelegate : UIResponder <UIApplicationDelegate>
{
    UIBackgroundTaskIdentifier backgroundTask;
}

@property (strong, nonatomic) UIWindow *window;

@property (copy, nonatomic) NSString* userTitle;

@property (copy, nonatomic) NSString* callerTitle;
@property (copy, nonatomic) NSString* sessionID;
@property (copy, nonatomic) NSString* publisherToken;
@property (copy, nonatomic) NSString* subscriberToken;

@property (assign, nonatomic) bool bFullyLoggedIn;  //to say user also entered his title

@property (retain, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) NSTimer * appTimer;
//-(BOOL)isInternetConnected;
-(void)fireListeningTimer;

@end

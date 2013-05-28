//
//  ParseHelper.m
//  LiveSessions
//
//  Created by Nirav Bhatt on 3/9/13.
//  Copyright (c) 2013 IPhoneGameZone. All rights reserved.
//
#define kUIAlertViewTagUserName 100
#define kUIAlertViewTagIncomingCall  200

#import "ParseHelper.h"

@implementation ParseHelper

//will initiate the call by saving session
//if there is a session already existing, do not save,
//just pop an alert
+(void)saveSessionToParse:(NSDictionary *)inputDict
{    
    NSString * receiverID = [inputDict objectForKey:@"receiverID"];

    //check if the recipient is either the caller or receiver in one of the activesessions.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"receiverID = '%@' OR callerID = %@", receiverID, receiverID];
    PFQuery *query = [PFQuery queryWithClassName:@"ActiveSessions" predicate:predicate];
    
    [query getFirstObjectInBackgroundWithBlock:^
    (PFObject *object, NSError *error)
    {
        if (!object)
        {
            NSLog(@"No session with receiverID exists.");
            [self storeToParse:inputDict];
        }
        else
        {
           [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kReceiverBusyNotification object:nil]];
           return;
        }
    }];
}

+(void) storeToParse:(NSDictionary *)inputDict
{
    __block PFObject *activeSession = [PFObject objectWithClassName:@"ActiveSessions"];
    NSString * callerID = [inputDict objectForKey:@"callerID"];
    if (callerID)
    {
        [activeSession setObject:callerID forKey:@"callerID"];
    }
    bool bAudio = [[inputDict objectForKey:@"isAudio"]boolValue];
    [activeSession setObject:[NSNumber numberWithBool:bAudio] forKey:@"isAudio"];
    
    bool bVideo = [[inputDict objectForKey:@"isVideo"]boolValue];
    [activeSession setObject:[NSNumber numberWithBool:bVideo] forKey:@"isVideo"];
    
    NSString * receiverID = [inputDict objectForKey:@"receiverID"];
    if (receiverID)
    {
        [activeSession setObject:receiverID forKey:@"receiverID"];
    }
    
    //callerTitle
    NSString * callerTitle = [inputDict objectForKey:@"callerTitle"];
    if (receiverID)
    {
        [activeSession setObject:callerTitle forKey:@"callerTitle"];
    }
    
    [activeSession saveInBackgroundWithBlock:^(BOOL succeeded, NSError* error)
     {
         if (!error)
         {
             NSLog(@"sessionID: %@, publisherToken: %@ , subscriberToken: %@", activeSession[@"sessionID"],activeSession[@"publisherToken"],
                   activeSession[@"subscriberToken"]);
             
             LSAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
             appDelegate.sessionID = activeSession[@"sessionID"];
             appDelegate.subscriberToken = activeSession[@"subscriberToken"];
             appDelegate.publisherToken = activeSession[@"publisherToken"];
             appDelegate.callerTitle = activeSession[@"callerTitle"];
             [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kSessionSavedNotification object:nil]];
         }
         else
         {
             NSLog(@"savesession error!!! %@", [error localizedDescription]);
             NSString * msg = [NSString stringWithFormat:@"Failed to save outgoing call session. Please try again.  %@", [error localizedDescription]];
             [self showAlert:msg];
         }         
     }];
}

+(void) showUserTitlePrompt
{
    UIAlertView *userNameAlert = [[UIAlertView alloc] initWithTitle:@"LiveSessions" message:@"Enter your name:" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    userNameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    userNameAlert.tag = kUIAlertViewTagUserName;
    [userNameAlert show];
}


+(void) anonymousLogin
{
    loggedInUser = [PFUser currentUser];
    if (loggedInUser)
    {
        [self showUserTitlePrompt];       
        return;
    }
    
    [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error)
     {
         if (error)
         {
             NSLog(@"Anonymous login failed.%@", [error localizedDescription]);
             NSString * msg = [NSString stringWithFormat:@"Failed to login anonymously. Please try again.  %@", [error localizedDescription]];
             [self showAlert:msg];
         }
         else
         {            
             loggedInUser = [PFUser user];
             loggedInUser = user;
             [self showUserTitlePrompt];
         }
     }];
}

+(void) initData
{
    if (!objectsUnderDeletionQueue)
        objectsUnderDeletionQueue = [NSMutableArray array];
}

+ (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (kUIAlertViewTagUserName == alertView.tag)
    {
        //lets differe saving title till we have the location.
        //saveuserwithlocationtoparse will handle it.
        LSAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
        appDelegate.userTitle = [[alertView textFieldAtIndex:0].text copy];
        appDelegate.bFullyLoggedIn = YES;
        
        //fire appdelegate timer
        [appDelegate fireListeningTimer];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kLoggedInNotification object:nil]];
    }
    else if (kUIAlertViewTagIncomingCall == alertView.tag)
    {
        if (buttonIndex != [alertView cancelButtonIndex])   //accept the call
        {
            //accept the call
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kIncomingCallNotification object:nil]];
        }
        else
        {
            //user did not accept call, restart timer          
            //start polling for new call.
            [self setPollingTimer:YES];
        }
    }
}

+ (void) deleteActiveUser
{
    NSString * activeUserobjID = [self activeUserObjectID];
    if (!activeUserobjID || [activeUserobjID isEqualToString:@""])
        return;
    
    PFQuery *query = [PFQuery queryWithClassName:@"ActiveUsers"];
    [query whereKey:@"userID" equalTo:activeUserobjID];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
    {
        if (!object)
        {
            NSLog(@"No such users exists.");
        }
        else
        {
            // The find succeeded.
            NSLog(@"Successfully retrieved the ActiveUser.");
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
             {
                 if (succeeded && !error)
                 {
                     NSLog(@"User deleted from parse");
                     activeUserObjectID = nil;
                 }
                 else
                 {
                     //[self showAlert:[error description]];
                      NSLog(@"%@", [error description]);
                 }
             }];
        }
    }];
}

+ (bool) isUnderDeletion : (id) argObjectID
{
    return [objectsUnderDeletionQueue containsObject:argObjectID];
}

+ (void) deleteActiveSession
{
    NSLog(@"deleteActiveSession");
    LSAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    NSString * activeSessionID = appDelegate.sessionID;
    
    if (!activeSessionID || [activeSessionID isEqualToString:@""])
        return;
  

    PFQuery *query = [PFQuery queryWithClassName:@"ActiveSessions"];
    [query whereKey:@"sessionID" equalTo:appDelegate.sessionID];

    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
    {
        if (!object)
        {
            NSLog(@"No session exists.");     
        }
        else
        {
            // The find succeeded.
            NSLog(@"Successfully retrieved the object.");
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
            {
                if (succeeded && !error)
                {
                    NSLog(@"Session deleted from parse");                   
                }
                else
                {
                    //[self showAlert:[error description]];
                    NSLog(@"%@", [error description]);
                }
            }];
        }
    }];
}

+ (void) saveUserWithLocationToParse:(PFUser*) user :(PFGeoPoint *) geopoint
{
    __block PFObject *activeUser;
    
    PFQuery *query = [PFQuery queryWithClassName:@"ActiveUsers"];
    [query whereKey:@"userID" equalTo:user.objectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error)
        {
            // if user is active user already, just update the entry
            // otherwise create it.
            if (objects.count == 0)
            {
                activeUser = [PFObject objectWithClassName:@"ActiveUsers"];
            }
            else
            {
                
                activeUser = (PFObject *)[objects objectAtIndex:0];
            }
            LSAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
            [activeUser setObject:user.objectId forKey:@"userID"];
            [activeUser setObject:geopoint forKey:@"userLocation"];
            [activeUser setObject:appDelegate.userTitle forKey:@"userTitle"];
            [activeUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
            {
                if (error)
                {
                    NSString * errordesc = [NSString stringWithFormat:@"Save to ActiveUsers failed.%@", [error localizedDescription]];
                    [self showAlert:errordesc];
                    NSLog(@"%@", errordesc);
                }
                else
                {
                    NSLog(@"Save to ActiveUsers succeeded.");
                    activeUserObjectID = activeUser.objectId;
                   
                    NSLog(@"%@", activeUserObjectID);
                }
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kUserLocSavedNotification object:nil]];
            }];
        }
        else
        {
            NSString * msg = [NSString stringWithFormat:@"Failed to save updated location. Please try again.  %@", [error localizedDescription]];
            [self showAlert:msg];
        }
    }];
}

+(void) showAlert : (NSString *) message
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"LiveSessions" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

+(NSString*) activeUserObjectID
{
    return activeUserObjectID;
}

+(PFUser*) loggedInUser
{    
    return loggedInUser;
}

+(void) setPollingTimer : (bool) bArg
{
    bPollingTimerOn = bArg;
}

+ (void) invalidateTimer
{
    NSLog(@"invalidating");
    bPollingTimerOn = NO;
    LSAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.appTimer invalidate];
    appDelegate.appTimer = nil;
}

//poll parse ActiveSessions object for incoming calls.
+(void) pollParseForActiveSessions
{
    __block PFObject *activeSession;
    
    if (!bPollingTimerOn)
        return;
    
    PFQuery *query = [PFQuery queryWithClassName:@"ActiveSessions"];
    
    NSString* currentUserID = [self loggedInUser].objectId;
    [query whereKey:@"receiverID" equalTo:currentUserID];  
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error)
         {
             // if user is active user already, just update the entry
             // otherwise create it.
             LSAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
         
             if (objects.count == 0)
             {
            
             }
             else
             {
                 activeSession = (PFObject *)[objects objectAtIndex:0];                 
                 appDelegate.sessionID = activeSession[@"sessionID"];
                 appDelegate.subscriberToken = activeSession[@"subscriberToken"];
                 appDelegate.publisherToken = activeSession[@"publisherToken"];
                 appDelegate.callerTitle = activeSession[@"callerTitle"];
                // future use:
                 //appDelegate.bAudioCallOnly = !([activeSession[@"isVideo"] boolValue]);
                 
                 //done with backend object, remove it.
                 [self setPollingTimer:NO];
                 [self deleteActiveSession];
                 
                 NSString *msg = [NSString stringWithFormat:@"Incoming Call from %@, Accept?", appDelegate.callerTitle];
                 
                 UIAlertView *incomingCallAlert = [[UIAlertView alloc] initWithTitle:@"LiveSessions" message:msg delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
                
                 incomingCallAlert.tag = kUIAlertViewTagIncomingCall;
                 [incomingCallAlert show];                 
             }
         }
         else
         {
             NSString * msg = [NSString stringWithFormat:@"Failed to retrieve active session for incoming call. Please try again. %@", [error localizedDescription]];
             [self showAlert:msg];
         }
     }];
}
@end

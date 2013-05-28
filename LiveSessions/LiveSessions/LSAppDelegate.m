//
//  LSAppDelegate.m
//  LiveSessions
//
//  Created by Nirav Bhatt on 4/13/13.
//  Copyright (c) 2013 IPhoneGameZone. All rights reserved.
//

#import "LSAppDelegate.h"
#import "LSViewController.h"

@implementation LSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
	
	//TODO: Replace the following with your own 40-digit values from Parse.com	
    [Parse setApplicationId:@"hKaqH9QOjF93eGfCToVnzNvDRoHwFuv5EgU2nf63"
                  clientKey:@"CKc1dL3Pof6n4eU3ph7R5SHh4fLlAqQTpkpXwSgJ"];
    
    self.bFullyLoggedIn = NO;
    [ParseHelper initData];
    [self registerNotifs];
    [ParseHelper anonymousLogin];
    return YES;
}

- (void) registerNotifs
{
    UINavigationController * navController = (UINavigationController *)[[self window] rootViewController];
    LSViewController * firstVC = (LSViewController * )[[navController viewControllers]objectAtIndex:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:firstVC selector:@selector(didCallArrive) name:kIncomingCallNotification object:nil];
 
    [[NSNotificationCenter defaultCenter] addObserver:firstVC selector:@selector(didLogin) name:kLoggedInNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:firstVC selector:@selector(didUserLocSaved) name:kUserLocSavedNotification object:nil];
}
						
- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{    
    backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
        
        // Clean up any unfinished task business by marking where you        
        // stopped or ending the task outright.        
        [application endBackgroundTask:backgroundTask];        
        backgroundTask = UIBackgroundTaskInvalid;        
    }];
 
    // Start the long-running task and return immediately.    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
        // Do the work associated with the task, preferably in chunks.
        [ParseHelper deleteActiveSession];
        [ParseHelper deleteActiveUser];
        [application endBackgroundTask:backgroundTask];        
        backgroundTask = UIBackgroundTaskInvalid;        
    });    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    self.bFullyLoggedIn = NO;
    [ParseHelper initData];
    [ParseHelper anonymousLogin];    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//this method will be called once logged in. It will poll parse ActiveSessions object
//for incoming calls.
-(void) fireListeningTimer
{
    if (self.appTimer && [self.appTimer isValid])
        return;
    
    self.appTimer = [NSTimer scheduledTimerWithTimeInterval:8.0
                                                     target:self
                                                   selector:@selector(onTick:)
                                                   userInfo:nil
                                                    repeats:YES];
    [ParseHelper setPollingTimer:YES];  
    NSLog(@"fired timer");
}


-(void)onTick:(NSTimer *)timer
{
    NSLog(@"OnTick");
    [ParseHelper pollParseForActiveSessions];  
}

@end

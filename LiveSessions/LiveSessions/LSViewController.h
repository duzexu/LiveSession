//
//  LSViewController.h
//  LiveSessions
//
//  Created by Nirav Bhatt on 4/13/13.
//  Copyright (c) 2013 IPhoneGameZone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParseHelper.h"
#import "LSAppDelegate.h"
#import "LSStreamingViewController.h"

@interface LSViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>
{
    NSMutableArray * m_userArray; 
    NSString * m_receiverID;
    __weak IBOutlet UITableView *m_userTableView;
    bool bAudioOnly;
    LSAppDelegate * appDelegate;
    CLLocationManager * locationManager;
}
- (IBAction)touchRefresh:(id)sender;

@end

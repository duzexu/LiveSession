//
//  LSViewController.m
//  LiveSessions
//
//  Created by Nirav Bhatt on 4/13/13.
//  Copyright (c) 2013 IPhoneGameZone. All rights reserved.
//

#define RANGE_IN_MILES 200.0
#import "LSViewController.h"

@interface LSViewController ()

@end

@implementation LSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
    
    m_userArray = [NSMutableArray array];
    appDelegate = [[UIApplication sharedApplication] delegate];
    m_userTableView.backgroundColor = [UIColor clearColor];
}

- (void) viewDidAppear:(BOOL)animated
{
   // if (appDelegate.bFullyLoggedIn)
   //     [self fireNearUsersQuery:50.0 :appDelegate.currentLocation.coordinate :YES];
    // [m_userTableView reloadData];
}

//- (void) viewWillAppear:(BOOL)animated
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCallArrive) name:kIncomingCallNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showReceiverBusyMsg) name:kReceiverBusyNotification object:nil];//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogin) name:kLoggedInNotification object:nil];
//}


- (void) didLogin
{
   [self startUpdate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [locationManager startMonitoringSignificantLocationChanges];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [m_userArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary * dict = [m_userArray objectAtIndex:indexPath.row];
    
    if (!dict)
        return nil;
    
    NSString * userTitle = [dict objectForKey:@"userTitle"];   
   
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        // Init new cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //background view
    [cell setBackgroundColor:[UIColor clearColor]];    
   // [cell setBackgroundView:[[UIView alloc] init]];
   // UIImage * backImg = [UIImage imageNamed:@"cellrow.png"];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ [UIImage imageNamed:@"cellrow.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];  
    // cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = userTitle;   
    cell.textLabel.font = [UIFont fontWithName:@"Verdana" size:13];
    cell.contentView.backgroundColor = [UIColor clearColor];
 
 //   [cell.textLabel sizeToFit];    
     
    UIButton *videoCallButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    videoCallButton.frame = CGRectMake(cell.frame.size.width - 50, 10.0f, 40.0, 40.0f);
  //  videoCallButton.layer.borderColor = [UIColor redColor].CGColor;
  //  videoCallButton.layer.borderWidth = 3.5;
    videoCallButton.tag = indexPath.row;
   // [videoCallButton setTitle:@"Chat" forState:UIControlStateNormal];
    [videoCallButton addTarget:self action:@selector(startVideoChat:) forControlEvents:UIControlEventTouchUpInside];
    [videoCallButton setBackgroundImage:[UIImage imageNamed:@"phonecall.png"] forState:UIControlStateNormal];
    [cell addSubview:videoCallButton];
    return cell;
}


//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSMutableDictionary * dict = [m_userArray objectAtIndex:indexPath.row];
//    NSString * receiverID = [dict objectForKey:@"userID"];
//    m_receiverID = [receiverID copy];
//    [self goToStreamingVC];
//}

- (void) startVideoChat:(id) sender
{
    UIButton * button = (UIButton *)sender;
    
    if (button.tag < 0) //out of bounds
    {
        [ParseHelper showAlert:@"User is no longer online."];
        return;
    }
    
    NSMutableDictionary * dict = [m_userArray objectAtIndex:button.tag];
    NSString * receiverID = [dict objectForKey:@"userID"];
    m_receiverID = [receiverID copy];
    [self goToStreamingVC];
}

- (void) goToStreamingVC
{
    //[self presentModalViewController:streamingVC animated:YES];
    //
    [self performSegueWithIdentifier:@"StreamingSegue" sender:self];
}

-(void) prepareForSegue:(UIStoryboardPopoverSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"StreamingSegue"])
    {
        //  UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        
        UINavigationController * navcontroller =  (UINavigationController *) segue.destinationViewController;
        
        LSStreamingViewController * streamingVC =  (LSStreamingViewController *)navcontroller.topViewController;
        
        streamingVC.callReceiverID = [m_receiverID copy];
    
        if (bAudioOnly)
        {
            streamingVC.bAudio = YES;
            streamingVC.bVideo = NO;
        }
        else
        {
            streamingVC.bAudio = YES;
            streamingVC.bVideo = YES;
        }
    }
}

//if and when a call arrives
- (void) didCallArrive
{
    //pass blank because call has arrived, no need for receiverID.
    m_receiverID = @"";
    [self goToStreamingVC];
}

//called when user or location update is called
//so that paused location services can resume.
- (void) didUserLocSaved
{
    [self startUpdate];
}

//this method polls for new users that gets added / removed from surrounding region.
//distanceinMiles - range in Miles
//bRefreshUI - whether to refresh table UI
//argCoord - location around which to execute the search.
-(void) fireNearUsersQuery : (CLLocationDistance) distanceinMiles :(CLLocationCoordinate2D)argCoord :(bool)bRefreshUI
{
    CGFloat miles = distanceinMiles;
    NSLog(@"fireNearUsersQuery %f",miles);
    
    PFQuery *query = [PFQuery queryWithClassName:@"ActiveUsers"];
    [query setLimit:1000];
    [query whereKey:@"userLocation"
       nearGeoPoint:
     [PFGeoPoint geoPointWithLatitude:argCoord.latitude longitude:argCoord.longitude] withinMiles:miles];    
    
    //deletee all existing rows,first from front end, then from data source. 
    [m_userArray removeAllObjects];
    [m_userTableView reloadData];    
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error)
        {
            for (PFObject *object in objects)
            {
                //if for this user, skip it.
                NSString *userID = [object valueForKey:@"userID"];
                NSString *currentuser = [ParseHelper loggedInUser].objectId;
                NSLog(@"%@",userID);
                NSLog(@"%@",currentuser);
                
                if ([userID isEqualToString:currentuser])
                {
                    NSLog(@"skipping - current user");
                    continue;
                }
                
                NSString *userTitle = [object valueForKey:@"userTitle"];
                
                NSMutableDictionary * dict = [NSMutableDictionary dictionary];
                [dict setObject:userID forKey:@"userID"];
                [dict setObject:userTitle forKey:@"userTitle"];
               
                // TODO: if reverse-geocoder is added, userLocation can be converted to
                // meaningful placemark info and user's address can be shown in table view.
                // [dict setObject:userTitle forKey:@"userLocation"];
                [m_userArray addObject:dict];
            }
            
            //when done, refresh the table view
            if (bRefreshUI)
            {
                [m_userTableView reloadData];
            }
        }
        else
        {
            NSLog(@"%@",[error description]);
        }
    }];
}

- (void)viewDidUnload {
    m_userTableView = nil;
    [super viewDidUnload];
}

- (IBAction)touchRefresh:(id)sender
{
    CLLocationDistance d = RANGE_IN_MILES;
    //fetch users from 50 miles around.
    NSLog(@"%f %f", appDelegate.currentLocation.coordinate.latitude, appDelegate.currentLocation.coordinate.longitude);
    [self fireNearUsersQuery:d :appDelegate.currentLocation.coordinate :YES];
}

#pragma location methods
- (void)startUpdate
{
    if (locationManager)
    {
        [locationManager stopUpdatingLocation];
    }
    else
    {
        locationManager = [[CLLocationManager alloc] init];
        [locationManager setDelegate:self];
        [locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
        [locationManager setDistanceFilter:30.0];
    }
    
    [locationManager startUpdatingLocation];
}

- (void)stopUpdate
{
    if (locationManager)
    {
        [locationManager stopUpdatingLocation];
    }
}


//this will store finalized user location.
//once done, it will save it in ActiveUsers row and then fetch nearer users to show in table.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    CLLocationDistance meters = [newLocation distanceFromLocation:oldLocation];
    //discard if inaccurate, or if user hasn't moved much.
    if (meters != -1 && meters < 50.0)
        return;    
 
    
    NSLog(@"## Latitude  : %f", newLocation.coordinate.latitude);
    NSLog(@"## Longitude : %f", newLocation.coordinate.longitude);

    
    appDelegate.currentLocation = newLocation;
    
    //pause the updates, until didUserLocSaved is called
    //via kUserLocSavedNotification notification.    
    [self stopUpdate];
    
    PFUser * thisUser = [ParseHelper loggedInUser] ;
  
    [ParseHelper saveUserWithLocationToParse:thisUser :[PFGeoPoint geoPointWithLocation:appDelegate.currentLocation]];
    [self fireNearUsersQuery:RANGE_IN_MILES :appDelegate.currentLocation.coordinate :YES];
}
@end

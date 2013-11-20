//
//  FMCCollectDataViewController.h
//  Test
//
//  Created by Esteban Uribe on 11/19/13.
//  Copyright (c) 2013 estebanuribe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FMCCollectDataViewController : UIViewController

@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) CLLocationManager *manager;
@property NSString *photoLocation;

@property NSData *imageData;

@property IBOutlet UITextField *location;
@property IBOutlet UITextField *date;
@property IBOutlet UITextField *incidentType;
@property IBOutlet UITextField *incidentCategory;
@property IBOutlet UIButton    *camera;

- (IBAction)updateLocation:(id)sender;
- (IBAction)changeDate:(id)sender;
- (IBAction)changeIncidentType:(id)sender;
- (IBAction)changeIncidentCategory:(id)sender;
- (IBAction)takePhoto:(id)sender;

- (IBAction)submit:(id)sender;


@end

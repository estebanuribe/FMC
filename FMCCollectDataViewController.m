//
//  FMCCollectDataViewController.m
//  Test
//
//  Created by Esteban Uribe on 11/19/13.
//  Copyright (c) 2013 estebanuribe. All rights reserved.
//

#import "FMCCollectDataViewController.h"


#import "SFAccountManager.h"
#import "SFAuthenticationManager.h"
#import "SFPushNotificationManager.h"
#import "SFOAuthInfo.h"
#import "SFLogger.h"

#import "SFRestAPI+Blocks.h"


@interface FMCCollectDataViewController ()

@end

@implementation FMCCollectDataViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentLocation = nil;
        _photoLocation = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _manager = [[CLLocationManager alloc] init];
    if (CLLocationManager.locationServicesEnabled == NO) {
        NSLog(@"Can't locate anything");
    }
    
    _date.text = NSDate.date.description;
    
    _manager.delegate = self;
    _manager.desiredAccuracy = kCLLocationAccuracyBest;
    _manager.distanceFilter = kCLDistanceFilterNone;
    
    [_manager startUpdatingLocation];
    
    
    
    // Do any additional setup after loading the view from its nib.
}

#pragma mark Location Manager Delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (CLLocation *loc in locations) {
        if (!_currentLocation) {
            _currentLocation = loc;
        } else if ([loc.timestamp compare:_currentLocation.timestamp] == NSOrderedDescending) {
            _currentLocation = loc;
        }
    }

    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:_currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error){
            NSLog(@"Geocode failed with error: %@", error);
            [self displayError:error];
            return;
        }
        CLPlacemark *place = ([placemarks count]?placemarks[0]:nil);
        if(place) {
            NSLog(@"Received placemarks: %@", placemarks);
            _location.text = [NSString stringWithFormat:@"%@ %@", place.subThoroughfare, place.thoroughfare];
        }
    }];

    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error %@", error.userInfo);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)displayError:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(),^ {
        
        NSString *message;
        switch ([error code])
        {
            case kCLErrorGeocodeFoundNoResult: message = @"kCLErrorGeocodeFoundNoResult";
                break;
            case kCLErrorGeocodeCanceled: message = @"kCLErrorGeocodeCanceled";
                break;
            case kCLErrorGeocodeFoundPartialResult: message = @"kCLErrorGeocodeFoundNoResult";
                break;
            default: message = [error description];
                break;
        }
        
        UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"An error occurred."
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];;
        [alert show];
    });   
}

- (void)takePhoto:(id)sender {
    
    
    UIImagePickerController *camera = [[UIImagePickerController alloc] init];
    camera.delegate = self;
    camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    camera.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    camera.allowsEditing = NO;
    
    [self presentModalViewController:camera animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSURL *mediaUrl = info[UIImagePickerControllerMediaURL];
    
    //obtaining saving path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"latest_photo.png"];

    if(image) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:imagePath atomically:YES];
        _photoLocation = imagePath;
    }
}

- (void)image:(UIImage *) image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"image location: %@", image);
}

- (void)submit:(id)sender {
    NSString *firstName = @"Esteban";
    NSString *lastName = @"Uribe";
    NSString *phoneNumber = @"(555) 440-5555";
    NSString *email = @"esteban@fixmycity.co";
    NSDictionary *fields = @{@"FirstName":firstName, @"LastName":lastName, @"Phone":phoneNumber, @"Email":email};
    
    SFRestRequest *contactCreateRequest = [[SFRestAPI sharedInstance] requestForCreateWithObjectType:@"Contact" fields:fields];
    
    [[SFRestAPI sharedInstance] sendRESTRequest:contactCreateRequest failBlock:nil completeBlock:^(NSDictionary *contactDictionary) {
        if ([contactDictionary isKindOfClass:[NSDictionary class]]) {
            CLLocationCoordinate2D coordinate = _currentLocation.coordinate;
            
            NSString *issueObject = @"Issues__c";
            NSDictionary *issueFields = @{@"category__c":@"Street Repair", @"type__c":@"broken side walk", @"Issue_Reporter__c":contactDictionary[@"id"], @"location__Latitude__s":@(coordinate.latitude),
                                          @"location__Longitude__s":@(coordinate.longitude)};
            
            SFRestRequest *issueCreateRequest = [[SFRestAPI sharedInstance] requestForCreateWithObjectType:issueObject fields:issueFields];
            [[SFRestAPI sharedInstance] send:issueCreateRequest delegate:self];
            [[SFRestAPI sharedInstance] sendRESTRequest:issueCreateRequest failBlock:nil completeBlock:^(NSDictionary *issueDictionary) {
                NSString *fileName = [NSString stringWithFormat:@"%@_%@_%@.png", issueDictionary[@"id"], contactDictionary[@"id"], NSDate.date.description];
            }];
            
        }
    }];
}


@end

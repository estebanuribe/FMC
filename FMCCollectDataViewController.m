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

#import "zkSforce.h"
#import "zkAuthentication.h"



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
    
    _incident_types = @[@"Crime Issue", @"Street Issue", @"Traffic Issue", @"Other Issue"];
    _incident_categories = @{@"Crime Issue":@[@"Gang Activity", @"Graffiti", @"Other Issue"],
                             @"Street Issue":@[@"Pot Hole", @"Broken Side Walk", @"Broken Street Light", @"Other Issue"],
                             @"Traffic Issue": @[@"Pot Holes", @"Broken Traffic Light", @"Missing Lane Markers", @"Other Issue"],
                             @"Other Issue":@[@"Hipsters", @"Hackers", @"Other Issue"]};
    
    _type = YES;
    _category = NO;
    [self.picker selectRow:INT16_MAX/2 + 2 inComponent:0 animated:NO];
    [self.picker selectRow:INT16_MAX/2 inComponent:1 animated:NO];
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
        _imageData = UIImageJPEGRepresentation(image, 0.5);
        
        
        [_imageData writeToFile:imagePath atomically:YES];
        _photoLocation = imagePath;
    }
}

- (void)image:(UIImage *) image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"image location: %@", image);
}

- (IBAction)updateLocation:(id)sender {
    _manager.delegate = self;
    _manager.desiredAccuracy = kCLLocationAccuracyBest;
    _manager.distanceFilter = kCLDistanceFilterNone;
    
    [_manager startUpdatingLocation];
}

- (IBAction)changeIncidentType:(id)sender {
    self.incidentCategory.enabled = NO;
    self.location.enabled = NO;
    self.camera.enabled = NO;
    self.type = YES;
    self.category = NO;
    self.containerView.hidden = NO;
    self.containerView.userInteractionEnabled = YES;
    [self.containerView removeFromSuperview];
    CGRect frame = self.containerView.frame;
    frame.origin.y = self.view.frame.size.height - self.containerView.frame.size.height;
    self.containerView.frame = frame;
    [self.view addSubview:self.containerView];
    self.picker.delegate = self;
    self.picker.dataSource = self;
    [self.picker reloadAllComponents];
}

- (IBAction)changeIncidentCategory:(id)sender {
    
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
            
            NSString *issueObject = @"FMC__Issues__c";
            _selected_type = _incident_types[[self.picker selectedRowInComponent:0]];
            _selected_cat = _incident_categories[_selected_cat][[self.picker selectedRowInComponent:1]];
            NSDictionary *issueFields = @{@"FMC__category__c":_selected_cat, @"FMC__type__c":_selected_type, @"FMC__Issue_Reporter__c":contactDictionary[@"id"], @"FMC__location__Latitude__s":@(coordinate.latitude),
                                          @"FMC__location__Longitude__s":@(coordinate.longitude)};
            
            SFRestRequest *issueCreateRequest = [[SFRestAPI sharedInstance] requestForCreateWithObjectType:issueObject fields:issueFields];

            [[SFRestAPI sharedInstance] sendRESTRequest:issueCreateRequest failBlock:nil completeBlock:^(NSDictionary *issueDictionary) {
                
                SFOAuthCredentials *credentials = [SFAccountManager sharedInstance].credentials;
                
                ZKSforceClient *client = [[ZKSforceClient alloc] init];
                [client loginWithRefreshToken:credentials.refreshToken authUrl:credentials.instanceUrl oAuthConsumerKey:credentials.clientId];
                
                NSString *fileName = [NSString stringWithFormat:@"%@_%@_%@.png", issueDictionary[@"id"], contactDictionary[@"id"], NSDate.date.description];
                
            
            
                
                ZKSObject *attachment = [[ZKSObject alloc] initWithType:@"Attachment"];
                [attachment setFieldValue:fileName field:@"Name"];
                [attachment setFieldValue:issueDictionary[@"id"] field:@"ParentId"];
                [attachment setFieldValue:[_imageData base64Encoding] field:@"Body"];
                
                NSArray *results = [client create:@[attachment]];
                
                ZKSaveResult *sr = [results objectAtIndex:0];
                if ([sr success])
                    NSLog(@"new issues file id %@", [sr id]);
                else
                    NSLog(@"error creating issues file %@ %@", [sr statusCode], [sr message]);
            }];
            
        }
    }];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
/*    if (component == 0) {
        return _incident_types.count;
    } else if (component == 1) {
        NSString *typeName = _incident_types[[pickerView selectedRowInComponent:0]];
        NSArray *cats = _incident_categories[typeName];
        return cats.count;
    }*/
    return INT16_MAX;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) {
        row = row % _incident_types.count;
        return _incident_types[row];
    } else if (component == 1) {
        row = row % _incident_categories.count;
        NSString *typeName = _incident_types[[pickerView selectedRowInComponent:0]];
        NSArray *cats = _incident_categories[typeName];
        return cats[row];
    }
    return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        [pickerView reloadComponent:1];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UILabel *label = (UILabel *)view;
    if(!label ) {
        CGRect frame = CGRectZero;
        frame.size = [pickerView rowSizeForComponent:component];
        label = [[UILabel alloc] initWithFrame:frame];
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
    }
    
    if (component == 0) {
        row = row % _incident_types.count;
        label.text = _incident_types[row];
    } else if (component == 1) {
        NSInteger selectedRow = [pickerView selectedRowInComponent:0] % _incident_types.count;
        NSString *typeName = _incident_types[selectedRow];
        NSArray *cats = _incident_categories[typeName];
        row = row % cats.count;
        label.text = cats[row];
    }
    
    return label;
/*    if (component == 1) {
        UILabel *label = (UILabel *)view;
        if (!label) {
            label = [[UILabel alloc] init];
            label.lineBreakMode = NSLineBreakByWordWrapping;
            label.numberOfLines = 2;
            label.font = [label.font fontWithSize:10];
        }
        return label;
    }*/
    
}



@end

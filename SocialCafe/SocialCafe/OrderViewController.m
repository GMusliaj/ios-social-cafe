/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OrderViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "SCProtocols.h"
#import "FriendViewContoller.h"
#import "PlaceViewController.h"
#import "ConfirmationViewController.h"
#import "PhotoViewController.h"

NSString *const kPlaceholderMessage = @"Say some more ...";

@interface OrderViewController ()
<CLLocationManagerDelegate,
FBPlacePickerDelegate,
UITextViewDelegate,
UIActionSheetDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet FBProfilePictureView *userProfilePictureView;
@property (weak, nonatomic) IBOutlet UILabel *orderSummaryLabel;
@property (weak, nonatomic) IBOutlet UITextView *orderMessageTextView;
@property (weak, nonatomic) IBOutlet UIImageView *orderImageView;
@property (weak, nonatomic) IBOutlet UILabel *orderTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderLikesLabel;
@property (weak, nonatomic) IBOutlet UIView *orderFacepileView;
@property (strong, nonatomic) NSObject<FBGraphPlace> *selectedPlace;
@property (strong, nonatomic) NSArray *selectedFriends;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSString *initialOrderSummary;
@property (strong, nonatomic) NSString *enteredMessage;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) UIImage *selectedPhoto;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void)updateSummary;

@end

@implementation OrderViewController
@synthesize userProfilePictureView = _userProfilePictureView;
@synthesize orderSummaryLabel = _orderSummaryLabel;
@synthesize orderMessageTextView = _orderMessageTextView;
@synthesize orderTitleLabel = _orderTitleLabel;
@synthesize orderLikesLabel = _orderLikesLabel;
@synthesize orderFacepileView = _orderFacepileView;
@synthesize orderImageView = _orderImageView;
@synthesize selectedPlace = _selectedPlace;
@synthesize selectedFriends = _selectedFriends;
@synthesize locationManager = _locationManager;
@synthesize menuItem =_menuItem;
@synthesize user = _user;
@synthesize initialOrderSummary = _initialOrderSummary;
@synthesize enteredMessage = _enteredMessage;
@synthesize imagePicker = _imagePicker;
@synthesize popover = _popover;
@synthesize selectedPhoto = _selectedPhoto;
@synthesize activityIndicator = _activityIndicator;

#pragma mark - View life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if (self.menuItem) {
        self.orderTitleLabel.text = [self.menuItem objectForKey:@"title"];
        self.orderImageView.image = [UIImage imageNamed:[self.menuItem objectForKey:@"picture"]];
        self.orderLikesLabel.text =
            [NSString stringWithFormat:@"%@ others enjoyed this.",
             [self.menuItem objectForKey:@"likeCount"]];
    }
    if (self.user.id) {
        self.userProfilePictureView.profileID = self.user.id;
    }
    if (self.user.name) {
        self.initialOrderSummary = [NSString stringWithFormat:@"%@ ordered %@",
                                       self.user.name,
                                       [self.menuItem objectForKey:@"title"]];
    } else {
        self.initialOrderSummary = [NSString stringWithFormat:@"Ordered %@",
                                       [self.menuItem objectForKey:@"title"]];
    }
    self.orderSummaryLabel.text =  [NSString stringWithFormat:@"%@.", self.initialOrderSummary];
    [self.orderSummaryLabel sizeToFit];
    
    // Get the CLLocationManager going.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    // We don't want to be notified of small changes in location, preferring to use our
    // last cached results, if any.
    self.locationManager.distanceFilter = 50;
    [self.locationManager startUpdatingLocation];
    
    self.orderMessageTextView.delegate = self;
    
}

- (void)viewDidUnload
{
    [self setOrderTitleLabel:nil];
    [self setOrderImageView:nil];
    [self setUserProfilePictureView:nil];
    [self setOrderSummaryLabel:nil];
    [self setOrderMessageTextView:nil];
    [self setOrderLikesLabel:nil];
    [self setOrderFacepileView:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.imagePicker = nil;
    self.popover = nil;
}

- (void)dealloc {
    _locationManager.delegate = nil;
    _imagePicker.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation = UIInterfaceOrientationPortrait);
}

#pragma mark - Helper methods
/*
 * This method publishes the order action to the user's timeline.
 */
- (void) publishMenuSelection:(NSString *)photoURL {
    if (FBSession.activeSession.isOpen) {
        // Get the OG object representing the drink
        id<SCOGBeverage> beverage = (id<SCOGBeverage>)[FBGraphObject graphObject];
        beverage.url = [self.menuItem objectForKey:@"url"];
        
        // Set up the OG action parameters
        id<SCOGOrderBeverageAction> action = (id<SCOGOrderBeverageAction>)[FBGraphObject graphObject];
        action.beverage = beverage;
        action.size = @"Medium";
        if (self.selectedPlace) {
            [action setObject:self.selectedPlace forKey:@"place"];
        }
        if (self.selectedFriends.count > 0) {
            [action setObject:self.selectedFriends forKey:@"tags"];
        }
        if (self.enteredMessage && ![self.enteredMessage isEqualToString:@""]) {
            [action setObject:self.enteredMessage forKey:@"message"];
        }
        if (photoURL) {
            NSMutableDictionary *image = [[NSMutableDictionary alloc] init];
            [image setObject:photoURL forKey:@"url"];
            
            NSMutableArray *images = [[NSMutableArray alloc] init];
            [images addObject:image];
            
            action.image = images;
        }
        
        // Publish the action
        [FBRequestConnection startForPostWithGraphPath:@"me/social-cafe:order"
                                 graphObject:action
                    completionHandler:^(FBRequestConnection *connection,
                                        id result,
                                        NSError *error) {
                        [self.activityIndicator stopAnimating];
                        [self.view setUserInteractionEnabled:YES];
            if (error) {
                NSLog(@"error: domain = %@, code = %d",
                      error.domain, error.code); 
                NSString *alertText = [NSString stringWithFormat:@"There was an error ordering your menu item."];
                [[[UIAlertView alloc] initWithTitle:@"Result"
                                            message:alertText
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil]
                 show];
            } else {
                NSLog(@"Published order action: %@", [result objectForKey:@"id"]);
                [self performSegueWithIdentifier:@"SegueToConfirmation" sender:self];
            }
        }];
    }
}

/*
 * This method uploads a user photo and then gets the photo information for
 * use in the order action.
 */
- (void)postPhotoThenOpenGraphAction {
    // Set up the batch request connection
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    // First request uploads the photo.
    FBRequest *request1 = [FBRequest requestForUploadPhoto:self.selectedPhoto];
    [connection addRequest:request1
         completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (!error) {
         }
     }
            batchEntryName:@"photopost"
     ];
    
    // Second request retrieves photo information for just-created photo so we can grab its source.
    FBRequest *request2 = [FBRequest requestForGraphPath:@"{result=photopost:$.id}"];
    [connection addRequest:request2
         completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (!error &&
             result) {
             NSString *source = [result objectForKey:@"source"];
             [self publishMenuSelection:source];
         }
     }
     ];
    
    [connection start];
}

/*
 * This sets up the placeholder text.
 */
- (void)resetOrderMessage
{
    self.orderMessageTextView.text = kPlaceholderMessage;
    self.orderMessageTextView.textColor = [UIColor lightGrayColor];
}

/*
 * Method to update the summary label when the user enters order
 * info such as picking a friend or a place.
 */
- (void)updateSummary {

    self.orderSummaryLabel.text = self.initialOrderSummary;
    
    NSString *extraInfoText = @"";
    int friendCount = self.selectedFriends.count;
    if (friendCount > 2) {
        // Just to mix things up, don't always show the first friend.
        id<FBGraphUser> randomFriend = [self.selectedFriends objectAtIndex:arc4random() % friendCount];
        extraInfoText = [NSString stringWithFormat:@" with %@ and %d others", 
                           randomFriend.name,
                           friendCount - 1];
    } else if (friendCount == 2) {
        id<FBGraphUser> friend1 = [self.selectedFriends objectAtIndex:0];
        id<FBGraphUser> friend2 = [self.selectedFriends objectAtIndex:1];
        extraInfoText = [NSString stringWithFormat:@" with %@ and %@",
                           friend1.name,
                           friend2.name];
    } else if (friendCount == 1) {
        id<FBGraphUser> friend = [self.selectedFriends objectAtIndex:0];
        extraInfoText = [NSString stringWithFormat:@" with %@", friend.name];
    }
    
    if (self.selectedPlace) {
        extraInfoText = [extraInfoText stringByAppendingString:
                                        [NSString stringWithFormat:@" at %@",
                                         self.selectedPlace.name]];
    }
    self.orderSummaryLabel.text =  [NSString stringWithFormat:@"%@%@.",
                                    self.initialOrderSummary, extraInfoText];
    [self.orderSummaryLabel sizeToFit];
}

/* 
 * Method to set up the segue view controllers
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SegueToPlacePicker"]) {
        // This sets up the place picker
        PlaceViewController *ppvc = (PlaceViewController *) segue.destinationViewController;
        __block OrderViewController *myself = self;
        ppvc.selectItemCallback = ^(id sender, id selectedItems) {
            myself.selectedPlace = selectedItems;
            [myself updateSummary];
        };
        ppvc.locationCoordinate = self.locationManager.location.coordinate;
        ppvc.radiusInMeters = 1000;
        ppvc.resultsLimit = 50;
        ppvc.searchText = @"restaurant";
        if (!(ppvc.locationCoordinate.latitude || 
              ppvc.locationCoordinate.longitude)) {
            ppvc.locationCoordinate = CLLocationCoordinate2DMake(48.857875, 2.294635);
        }
        //ppvc.delegate = ppvc;
        [ppvc loadData];
    } else if ([segue.identifier isEqualToString:@"SegueToFriendPicker"]) {
        // This sets up the friend picker
        FriendViewContoller *fpvc = (FriendViewContoller *) segue.destinationViewController;
        __block OrderViewController *myself = self;
        fpvc.selectItemCallback = ^(id sender, id selectedItems) {
            myself.selectedFriends = selectedItems;
            [myself updateSummary];
        };
        [fpvc loadData];
    } else if ([segue.identifier isEqualToString:@"SegueToConfirmation"]) {
        // This sets up the order confirmation controller
        NSMutableDictionary *orderData =
                [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                     [self.menuItem objectForKey:@"title"], @"title",
                     [self.menuItem objectForKey:@"likeCount"], @"likeCount",
                     self.orderSummaryLabel.text, @"summary",
                     [self.menuItem objectForKey:@"url"], @"url",
                     nil];
        if (self.selectedPlace) {
            [orderData setValue:self.selectedPlace.id forKey:@"placeId"];
        }
        if (self.enteredMessage && ![self.enteredMessage isEqualToString:@""]) {
            [orderData setValue:self.enteredMessage forKey:@"message"];
        }
        if (self.selectedPhoto) {
           [orderData setValue:self.selectedPhoto forKey:@"picture"];
        } else {
            [orderData setValue:
             [UIImage imageNamed:
              [self.menuItem objectForKey:@"picture"]] forKey:@"picture"];
        }
        ConfirmationViewController *cvc = (ConfirmationViewController *) segue.destinationViewController;
        cvc.order = orderData;
    } else if ([segue.identifier isEqualToString:@"SegueToPhotoViewer"]) {
        // This sets up the photo viewer and confirmation controller
        __block OrderViewController *myself = self;
        PhotoViewController *pvc = (PhotoViewController *) segue.destinationViewController;
        pvc.image = self.selectedPhoto;
        pvc.confirmCallback = ^(id sender, bool confirm) {
            if(!confirm) {
                myself.selectedPhoto = nil;
            } else {
                myself.orderImageView.image = myself.selectedPhoto;
            }
        };
    }
}

/*
 * Helper method to normalize an image
 */
- (UIImage*) normalizedImage:(UIImage*)image {
	CGImageRef          imgRef = image.CGImage;
	CGFloat             width = CGImageGetWidth(imgRef);
	CGFloat             height = CGImageGetHeight(imgRef);
	CGAffineTransform   transform = CGAffineTransformIdentity;
	CGRect              bounds = CGRectMake(0, 0, width, height);
    CGSize              imageSize = bounds.size;
	CGFloat             boundHeight;
    UIImageOrientation  orient = image.imageOrientation;
    
	switch (orient) {
		case UIImageOrientationUp: //EXIF = 1
			transform = CGAffineTransformIdentity;
			break;
            
		case UIImageOrientationDown: //EXIF = 3
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
            
		case UIImageOrientationLeft: //EXIF = 6
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
            
		case UIImageOrientationRight: //EXIF = 8
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
            
		default:
            // image is not auto-rotated by the photo picker, so whatever the user
            // sees is what they expect to get. No modification necessary
            transform = CGAffineTransformIdentity;
            break;
	}
    
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    if ((image.imageOrientation == UIImageOrientationDown) ||
        (image.imageOrientation == UIImageOrientationRight) ||
        (image.imageOrientation == UIImageOrientationUp)) {
        // flip the coordinate space upside down
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -height);
    }
    
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return imageCopy;
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation {
    if (!oldLocation ||
        (oldLocation.coordinate.latitude != newLocation.coordinate.latitude && 
         oldLocation.coordinate.longitude != newLocation.coordinate.longitude)) {
            FBCacheDescriptor *cacheDescriptor = 
            [FBPlacePickerViewController cacheDescriptorWithLocationCoordinate:newLocation.coordinate
                                                                radiusInMeters:1000
                                                                    searchText:nil 
                                                                  resultsLimit:50 
                                                              fieldsForRequest:nil];
            [cacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
        }
}

- (void)locationManager:(CLLocationManager *)manager 
       didFailWithError:(NSError *)error {
	NSLog(@"Location error: %@", error);
}

#pragma mark - UITextViewDelegate methods
/*
 * This method does some cleanup when the user message
 * text entry is completed.
 */
- (void)doneEditing {
    self.enteredMessage = self.orderMessageTextView.text;
    [self.orderMessageTextView resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
    if ([self.orderMessageTextView.text isEqualToString:@""]) {
        [self resetOrderMessage];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:kPlaceholderMessage]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    // Add a done button in the top nav so the message entry
    // can be dismissed.
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                   target:self
                                   action:@selector(doneEditing)];
    [[self navigationItem] setRightBarButtonItem:doneButton];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self doneEditing];
}

#pragma mark - UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    // If user presses cancel, do nothing
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    
    if (!self.imagePicker) {
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
    }
    
    // Set the source type of the imagePicker to the users selection
    if (buttonIndex == 0) {
        // If its the simulator, camera is no good
        if(TARGET_IPHONE_SIMULATOR){
            [[[UIAlertView alloc] initWithTitle:@"Camera not supported in simulator."
                                        message:@"(>'_')>"
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
            return;
        }
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else if (buttonIndex == 1) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Can't use presentModalViewController for image picker on iPad
        if (!self.popover) {
            self.popover = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
        }
        [self.popover presentPopoverFromRect:CGRectZero
                                      inView:self.view
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:YES];
    } else {
        [self presentModalViewController:self.imagePicker animated:YES];
    }
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    // Save the image
    self.selectedPhoto = image;
    // Go to the photo view controller
    [self performSegueWithIdentifier:@"SegueToPhotoViewer" sender:self];
    // Dismiss the image picker
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - Action methods
- (IBAction)photoButtonClicked:(id)sender {
    // Give user's a choice of picking a picture from
    // the photo library or by taking a photo.
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                delegate:self
                       cancelButtonTitle:@"Cancel"
                  destructiveButtonTitle:nil
                       otherButtonTitles:@"Take Photo", @"Choose Existing", nil];
    [actionSheet showInView:self.view];
}

- (IBAction)orderButtonClicked:(id)sender {
    // Start the progress indicator
    [self.activityIndicator startAnimating];
    // Disable any user interactions
    [self.view setUserInteractionEnabled:NO];
    
    // Check if the user has selected a custom image
    if (self.selectedPhoto) {
        // If an image is selected then post the photo to the
        // app's album first before publishing the order action
        self.selectedPhoto = [self normalizedImage:self.selectedPhoto];
        [self postPhotoThenOpenGraphAction];
    } else {
        // Publish the order action
        [self publishMenuSelection:nil];
    }
}

@end

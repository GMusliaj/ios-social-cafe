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

#import "ConfirmationViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "SCProtocols.h"

@interface ConfirmationViewController ()


@property (weak, nonatomic) IBOutlet UIImageView *orderImageView;
@property (weak, nonatomic) IBOutlet UILabel *orderTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderLikesLabel;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *placeProfilePictureView;
@property (weak, nonatomic) IBOutlet UILabel *orderSummaryLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;

@end

@implementation ConfirmationViewController
@synthesize placeProfilePictureView;
@synthesize orderImageView;
@synthesize orderTitleLabel;
@synthesize orderLikesLabel;
@synthesize orderSummaryLabel;
@synthesize orderMessageLabel;
@synthesize likeButton;
@synthesize order = _order;

#pragma mark - Helper methods
/*
 * This method helps get error details that are embedded
 * in the "userInfo" dictionary. It contains useful info
 * for error responses.
 */
- (NSInteger)getInnerErrorCode:(NSError *)error
{
    NSInteger errorCodeInResponse = 0;
    if ([[error userInfo] objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"]) {
        errorCodeInResponse = [[[[[[error userInfo]
                                   objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"]
                                  objectForKey:@"body"]
                                 objectForKey:@"error"]
                                objectForKey:@"code"] integerValue];
    }
    return errorCodeInResponse;
}

#pragma mark - Initialization methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.orderImageView.image = [self.order objectForKey:@"picture"];
    if ([self.order objectForKey:@"placeId"]) {
        self.placeProfilePictureView.profileID = [self.order objectForKey:@"placeId"];
    } else {
        self.placeProfilePictureView.hidden = YES;
    }
    self.orderTitleLabel.text = [self.order objectForKey:@"title"];
    self.orderLikesLabel.text = [NSString stringWithFormat:@"%@ others enjoyed this.",
                                 [self.order objectForKey:@"likeCount"]];
    self.orderSummaryLabel.text = [self.order objectForKey:@"summary"];
    if ([self.order objectForKey:@"message"]) {
        self.orderMessageLabel.text = [self.order objectForKey:@"message"];
    } else {
        self.orderMessageLabel.hidden = YES;
    }
    
}

- (void)viewDidUnload
{
    [self setOrderTitleLabel:nil];
    [self setOrderLikesLabel:nil];
    [self setOrderSummaryLabel:nil];
    [self setOrderMessageLabel:nil];
    [self setPlaceProfilePictureView:nil];
    [self setOrderImageView:nil];
    [self setLikeButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation = UIInterfaceOrientationPortrait);
}

#pragma mark - Action methods
/*
 * When the user taps this button we publish and OG
 * like action for the given drink.
 */
- (IBAction)likeButtonAction:(id)sender {
    // Publish the OG Like action
    if (FBSession.activeSession.isOpen) {
        // Set the OG object properties that represents a drink
        id<SCOGBeverage> beverage = (id<SCOGBeverage>)[FBGraphObject graphObject];
        beverage.url = [self.order objectForKey:@"url"];
        
        // Set up the OG action properties
        id<SCOGLikeAction> action = (id<SCOGLikeAction>)[FBGraphObject graphObject];
        // The action's object will be the drink
        action.object = beverage;
        
        // Start the OG request
        [FBRequestConnection startForPostWithGraphPath:@"me/og.likes"
                                           graphObject:action completionHandler:
         ^(FBRequestConnection *connection, id result, NSError *error) {
             if (error) {
                 NSLog(@"error: domain = %@, code = %d",
                       error.domain, error.code);
                 NSString *alertText;
                 // Check for an error that means the user has already liked
                 // this object
                 if ([self getInnerErrorCode:error] == 3501) {
                     alertText = [NSString stringWithFormat:
                                 @"You have already said you enjoyed the drink"];
                     
                     // Set the UI to match the fact that the user has already
                     // liked this drink.
                     [self.likeButton setImage:[UIImage imageNamed:@"enjoyed"]
                                      forState: UIControlStateNormal];
                 } else {
                     alertText = [NSString stringWithFormat:
                                  @"There was a problem sending the info."];
                 }
                 [[[UIAlertView alloc] initWithTitle:@"Oops"
                                             message:alertText
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil]
                  show];
             } else {
                 // Change the like button
                 // Future Enhancements - (1) allow users to unlike if already
                 // liked and (2) keep track of this info in the Menu object.
                 [self.likeButton setImage:[UIImage imageNamed:@"enjoyed"]
                                  forState: UIControlStateNormal];
                 
                 // Successful OG like publish, echo results
                 NSLog(@"Like action: %@", [result objectForKey:@"id"]);
                 NSString *alertText = [NSString stringWithFormat:
                                        @"Glad you enjoyed your drink."];
                 [[[UIAlertView alloc] initWithTitle:@"Thanks"
                                             message:alertText
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil]
                  show];
             }
         }];
    }
}

/*
 * When the user taps this button we go back to the
 * root view controller.
 */
- (IBAction)returnToMenuButtonAction:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end

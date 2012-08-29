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

#import <FacebookSDK/FacebookSDK.h>
#import "LoginViewController.h"
#import "MenuViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

#pragma mark - Helper methods
/*
 * This is the session state callback handler.
 */
- (void) sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error {
    switch (state) {
        case FBSessionStateOpen: {
            // If the session is open, cache friend data
            FBCacheDescriptor *cacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
            [cacheDescriptor prefetchAndCacheForSession:session];
            
            // Go to the menu page
            [self performSegueWithIdentifier:@"SegueToMenu" sender:self];
            break;
        }
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed: {
            break;
        }
        default:
            break;
    }
}

/*
 * This method opens the user session
 */
- (void)openSession
{
    // Ask for permissions for publishing, getting info about uploaded
    // custom photos.
    NSArray *permissions = [NSArray arrayWithObjects:
                            @"publish_actions",
                            @"user_photos",
                            nil];
    [FBSession openActiveSessionWithPermissions:permissions
                                   allowLoginUI:YES
                              completionHandler:^(FBSession *session,
                                                  FBSessionState state,
                                                  NSError *error) {
        [self sessionStateChanged:session state:state error:error];
    }];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqual:@"SegueToMenu"]) {
        [self.presentingViewController dismissModalViewControllerAnimated:NO];
    }
}

#pragma mark - View life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation = UIInterfaceOrientationPortrait);
}

#pragma mark - Action methods
- (IBAction)loginButtonClicked:(id)sender {
    // Login the user
    [self openSession];
}

@end

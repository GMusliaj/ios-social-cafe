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

#import "AppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>
#import "MenuViewController.h"

@interface AppDelegate ()
@property (strong, nonatomic) NSURL *openedURL;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize openedURL = _openedURL;

#pragma mark - Helper methods
/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val = [[kv objectAtIndex:1]
                         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [FBProfilePictureView class];
    [FBPlacePickerViewController class];
    [FBFriendPickerViewController class];
    // Override point for customization after application launch.
    return YES;
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation {
    
    // Save the incoming URL to test deep links later.
    self.openedURL = url;
    
    // We need to handle URLs by passing them to FBSession in order for SSO authentication
    // to work.
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (FBSession.activeSession.state == FBSessionStateCreatedOpening) {
        [FBSession.activeSession close]; // so we close our session and start over
    }
    
    // Check for an incoming deep link and set the info in the Menu View Controller
    // Process the saved URL
    NSString *query = [self.openedURL fragment];
    NSDictionary *params = [self parseURLParams:query];
    // Check if target URL exists
    if ([params valueForKey:@"target_url"]) {
        // If the incoming link is a deep link then set things up to take the user to
        // the menu view controller (if necessary), then pass along the deep link. The
        // menu controller will take care of sending the user to the correct experience.
        NSString *targetURL = [params valueForKey:@"target_url"];
        
        // Get the navigation controller.
        UINavigationController *navController = (UINavigationController *) self.window.rootViewController;
        // Get the menu view controller, the first view controller
        MenuViewController *menuViewController =
        (MenuViewController *) [[navController viewControllers] objectAtIndex:0];
        
        // Call the view controller method to set the deep link
        [menuViewController initMenuFromUrl:targetURL];
        id currentController = [navController topViewController];
        // If necessary, pop to the menu view controller that is the
        // root view controller.
        if (![currentController isKindOfClass:[MenuViewController class]]) {
            // The menu view controller will handle the redirect
            [navController popToRootViewControllerAnimated:NO];
        } else {
            [menuViewController populateUserDetails];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

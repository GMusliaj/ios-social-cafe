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

#import "Menu.h"

static NSString *kPublishServer = @"http://social-cafe.herokuapp.com";

@interface Menu ()

@property (readwrite,nonatomic) NSMutableArray *items;

-(void)update:(NSUInteger)index;
-(void)refresh:(BOOL)force;
@end

@implementation Menu
@synthesize items = _items;
@synthesize profileID = _profileID;
@synthesize delegate = _delegate;

#pragma mark - Initialization methods
/*
 * Initialization when there is no personalized
 * menu info
 */
-(id)init {
    return [self initWithProfileID:nil];
}

/*
 * Initialization method for personalized menu
 * info. In this method the profile ID can be set.
 */
-(id)initWithProfileID:(NSString *)profileID {
    self = [super init];
    if (self) {
        self.items = [[NSMutableArray alloc] init];
        [self.items addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"latte.png", @"picture",
                                   @"Cafe Latte", @"title",
                                   [NSString stringWithFormat:@"%@/latte.php",kPublishServer], @"url",
                                   nil]];
        [self.items addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"icedmocha.png", @"picture",
                                   @"Iced Mocha", @"title",
                                   [NSString stringWithFormat:@"%@/icedmocha.php",kPublishServer], @"url",
                                   nil]];
        [self.items addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"earlgrey.png", @"picture",
                                   @"Earl Grey Tea", @"title",
                                   [NSString stringWithFormat:@"%@/earlgrey.php",kPublishServer], @"url",
                                   nil]];
        self.profileID = profileID;
        [self refresh:YES];
    }
    return self;
}

- (void) setProfileID:(NSString *)profileID
{
    _profileID = profileID;
    [self refresh:YES];
}

/*
 * Method that updates the menu data.
 */
-(void)update:(NSUInteger)index
{
    if (self.profileID != nil) {
        // Currently the menu info is hard coded. Future enhancements would include
        // getting custom info for a given user, ex: number of likes/orders for the
        // friends of a given user.
        [[self.items objectAtIndex:index] setObject:@"2" forKey:@"likeCount"];
        [[self.items objectAtIndex:index] setObject:@"5" forKey:@"orderCount"];
        
        // Notify the delegate that the data has changed
        if ([self.delegate respondsToSelector:@selector(menu:didLoadData:index:)]) {
            [self.delegate menu:self
                    didLoadData:[self.items objectAtIndex:index]
                          index:index];
        }
    }
}

/*
 * This method is called to refresh the menu data
 */
-(void)refresh:(BOOL)force
{
    for (int i = 0; i < [self.items count]; i++) {
        if (force ||
            ([[self.items objectAtIndex:i] objectForKey:@"likeCount"] == nil) ||
            ([[self.items objectAtIndex:i] objectForKey:@"orderCount"] == nil))
        {
            [self update:i];
        }
    }
}

@end

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

#import "PlaceViewController.h"

@interface PlaceViewController ()
<FBPlacePickerDelegate>

@end

@implementation PlaceViewController

@synthesize selectItemCallback = _selectItemCallback;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.delegate = self;
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

#pragma mark FBPlacePickerDelegate methods

- (void)placePickerViewControllerSelectionDidChange:(FBPlacePickerViewController *)placePicker {
    if (self.selectItemCallback) {
        self.selectItemCallback(self, placePicker.selection);
    }
    if (placePicker.selection) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end

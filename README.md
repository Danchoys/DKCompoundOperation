# DKCompoundOperation

[![Version](https://img.shields.io/cocoapods/v/DKCompoundOperation.svg?style=flat)](http://cocoapods.org/pods/DKCompoundOperation)
[![License](https://img.shields.io/cocoapods/l/DKCompoundOperation.svg?style=flat)](http://cocoapods.org/pods/DKCompoundOperation)
[![Platform](https://img.shields.io/cocoapods/p/DKCompoundOperation.svg?style=flat)](http://cocoapods.org/pods/DKCompoundOperation)

This easy-to-use and lightweight component allows to organize operations in sequences, providing a single interface for progress and completion tracking. It also makes possible the cancellation of the whole compound operation through the NSProgress instance.

## Usage

The following code shows how to make a two-step operation of exporting video from ALAssetsLibrary and uploading the result to the remote server. It assumes that there are two classed: `ExportVidoOperation` and `UploadVideoOperation`, inheriting from `DKOperation`.

```Objective-C

import <DKCompoundOperation/DKCompoundOperation.h>

static NSInteger const kExportOperationProgressFraction = 30;
static NSInteger const kUploadOperationProgressFraction = 65;
static NSInteger const kCleanupOperationProgressFraction = 5;

<...>

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, weak) NSProgress *progress;

<...>

DKCompoundOperation *operation = [[DKCompoundOperation alloc] init];
[operation addOperationWithBlock:^DKOperation *{
    return [ExportVideoOperation operationWithVideoAssetURL:assetURL];
} progressFraction:kExportOperationProgressFraction];
[operation addOperationWithBlock:^DKOperation *{
    return [UploadVideoOperation operation];
} progressFraction:kUploadOperationProgressFraction];
[operation addOperationWithOperationBlock:^(DKOperation *operation) {
    operation.progress.totalUnitCount = 150;
    // Perform some cleanup operations 
    // updating operation.progress
    operation.completeOperation(YES, nil);
} progressFraction:kCleanupOperationProgressFraction];
operation.completionBlock = ^(BOOL success, NSError *error) {
    if (error) {
        NSLog(@"Error occured: %@", error);
        return;
    }
    self.completedLabel.hidden = NO;
};
self.progress = operation.progress;
[self.queue addCompoundOperation:operation];

```

You may track changes to the progress object using KVO. For more information, visit the [NSProgress Class Reference](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSProgress_Class/index.html) and [Key-Value Observing Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html).

## Installation

DKCompoundOperation is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "DKCompoundOperation"
```

## Author

Daniil Konoplev, danchoys@icloud.com

## License

DKCompoundOperation is available under the MIT license. See the LICENSE file for more info.

//
//  DKCompoundOperation.h
//  DKCompoundOperation
//
//  Created by Daniil Konoplev on 27/05/15.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Daniil Konoplev
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
@class DKOperation;

/// This allows for easy operation grouping. It provides a single
/// progress tracking interface through the NSProgress object. Using
/// this object consumer may also cancel the whole compound operation.
@interface DKCompoundOperation : NSObject

/// This block is invoked once the compound operation finishes.
/// It is invoked on the same operation queue it was set.
@property (nonatomic, strong) void (^completionBlock)(BOOL success, NSError *error);

/// Progress tracking interface which also allows cancellation
/// of the compound operation.
@property (nonatomic, readonly) NSProgress *progress;

/// Use this method to add operations. You are supposed to return a freshly
/// @param operationCreationBlock You are supposed to return a freshly created
/// instance of DKOperation from this block.
/// @param progressFraction This parameter defines what part of the whole compound
/// operation the operation being added plays. The whole operation is supposed to
/// have the value of 100. Therefore if you want this suboperation to maintain only
/// 30% of progress, you need to pass 30 as progressFraction.
- (void)addOperationWithBlock:(DKOperation * (^)(void))operationCreationBlock progressFraction:(NSInteger)progressFraction;

@end

/// Base class for suboperations, used in DKCompoundOperation. Do not override
/// -main method. If you happen to creat an asynchronous operation, make sure you
/// call -main from you -start method implementation.
@interface DKOperation : NSOperation

/// Designated initializer. You need to pass freshly a created
/// NSProgress instance as the progress parameter.
- (instancetype)initWithProgress:(NSProgress *)progress NS_DESIGNATED_INITIALIZER;

/// Base progress object of the operation
@property (nonatomic, readonly) NSProgress *progress;

/// You need to invoke this block as soon as the operation completes
@property (nonatomic, readonly) void (^completeOperation)(BOOL success, NSError *error);

/// This is a substitute for the -main method. Perform all the
/// necessary actions here. Base implementation does nothing.
- (void)performOperation;

/// This method is called as the final step of the provided completeOperation
/// block. For asynchronous operations this is a proper place to update the
/// finished and executing flags. Base implementation does nothing.
- (void)finalizeOperation;

@end

/// This category allows to dispatch compound operations,
/// using ordinary NSOperationQueue.
@interface NSOperationQueue (DKCompoundOperation)

/// Adds compound operation to the queue. The operation won't
/// be deallocated before all the suboperations get completed.
- (void)addCompoundOperation:(DKCompoundOperation *)operation;

@end
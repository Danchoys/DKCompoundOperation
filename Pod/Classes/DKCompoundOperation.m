//
//  DKCompoundOperation.m
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

#import "DKCompoundOperation.h"

static NSInteger const kMaxFractionSum = 100;

@interface DKOperation ()

@property (nonatomic) BOOL success;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) DKCompoundOperation *compoundOperation;

@end

@implementation DKOperation

- (instancetype)initWithProgress:(NSProgress *)progress {
    if (!(self = [super init]))
        return nil;
    if (!progress)
        return nil;
    _progress = progress;
    __weak typeof(self) _self = self;
    _completeOperation = ^(BOOL success, NSError *error) {
        _self.success = success;
        _self.error = error;
        [_self finalizeOperation];
    };
    return self;
}

- (void)main {
    if (![self checkDependencies]) {
        DKOperation *lastDependency = [self.dependencies lastObject];
        self.completeOperation(lastDependency.success, lastDependency.error);
        return;
    }
    [self performOperation];
}

- (BOOL)checkDependencies {
    if (!self.dependencies.count)
        return YES;
    DKOperation *lastDependency = [self.dependencies lastObject];
    return lastDependency.success;
}

- (void)performOperation {}
- (void)finalizeOperation {}

@end

@interface DKBlockOperation ()

@property (nonatomic, strong) void (^block)(DKOperation *operation);

@end

@implementation DKBlockOperation

+ (instancetype)operationWithBlock:(void (^)(DKOperation *))block {
    return [[DKBlockOperation alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(void (^)(DKOperation *))block {
    self = [super initWithProgress:[NSProgress progressWithTotalUnitCount:0]];
    if (!self)
        return nil;
    if (!block)
        return nil;
    _block = block;
    return self;
}

- (void)performOperation {
    self.block(self);
}

@end

@interface DKCompoundOperation ()

@property (nonatomic) NSInteger fractionSum;
@property (nonatomic, readonly) NSMutableArray *operations;
@property (nonatomic, strong) NSOperationQueue *completionBlockQueue;

@end

@implementation DKCompoundOperation

- (instancetype)init {
    self = [super init];
    if (self) {
        _fractionSum = 0;
        _progress = [NSProgress progressWithTotalUnitCount:100];
        _progress.pausable = NO;
        _progress.cancellable = YES;
        __weak typeof(self) _self = self;
        _progress.cancellationHandler = ^{
            DKOperation *operation = [_self.operations lastObject];
            [operation cancel];
        };
        _operations = [NSMutableArray array];
    }
    return self;
}

- (void)setCompletionBlock:(void (^)(BOOL, NSError *))completionBlock {
    _completionBlock = completionBlock;
    self.completionBlockQueue = [NSOperationQueue currentQueue];
}

- (void)addOperationCreatedUsingBlock:(DKOperation *(^)(void))operationCreationBlock progressFraction:(NSInteger)progressFraction {
    self.fractionSum += progressFraction;
    NSAssert(self.fractionSum <= kMaxFractionSum, @"Internal inconsistency: sum of progress fractions can not exceed %ld", kMaxFractionSum);
    [self.progress becomeCurrentWithPendingUnitCount:progressFraction];
    [self addOperation:operationCreationBlock()];
    [self.progress resignCurrent];
}

- (void)addOperationWithOperationBlock:(void (^)(DKOperation *))operationBlock progressFraction:(NSInteger)progressFraction {
    NSAssert(operationBlock != nil, @"Internal inconsistency: block can not be nil");
    [self addOperationCreatedUsingBlock:^DKOperation *{
        return [DKBlockOperation operationWithBlock:operationBlock];
    } progressFraction:progressFraction];
}

- (void)addOperation:(DKOperation *)operation {
    NSOperation *lastOperation = [_operations lastObject];
    if (lastOperation) {
        [operation addDependency:lastOperation];
        lastOperation.completionBlock = nil;
    }
    __weak DKOperation *_operation = operation;
    __weak typeof(self) _self = self;
    operation.completionBlock = ^{
        if (_self.completionBlock && _self.completionBlockQueue)
            [_self.completionBlockQueue addOperations:@[[NSBlockOperation blockOperationWithBlock:^{
                _self.completionBlock(_operation.success, _operation.error);
            }]] waitUntilFinished:YES];
        _operation.compoundOperation = nil;
    };
    [_operations addObject:operation];
}

@end

@implementation NSOperationQueue (DKCompoundOperation)

- (void)addCompoundOperation:(DKCompoundOperation *)operation {
    NSAssert(operation.fractionSum == kMaxFractionSum, @"Internal inconsistency: sum of progress fractions must be exactly %ld at the time of adding to the queue", kMaxFractionSum);
    [[operation.operations lastObject] setCompoundOperation:operation];
    [self addOperations:[operation.operations copy] waitUntilFinished:NO];
}

@end

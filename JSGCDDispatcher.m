#import "JSGCDDispatcher.h"

NSString *const JSDefaultSerialQueueName = @"com.jsgcd.dispatch";

static JSGCDDispatcher *gSharedGCDDispatcher;

#if TARGET_OS_IPHONE
@interface JSGCDDispatcher()
- (void)addBackgroundTaskID:(UIBackgroundTaskIdentifier)identifier;
- (UIBackgroundTaskIdentifier)removeBackgroundTaskID:(UIBackgroundTaskIdentifier)identifier;
@property (readonly, retain) NSMutableSet *backgroundTasks;
@property (nonatomic, retain) UIApplication *application;
@end
#endif

@implementation JSGCDDispatcher
@synthesize serialQueueID = _serialQueueID;
#if TARGET_OS_IPHONE
@synthesize backgroundTasks = _backgroundTasks;
@synthesize application = _application;
#endif

#pragma mark -
#pragma mark Class Methods

+ (void)initialize {
  if (self == [JSGCDDispatcher class]) {
    gSharedGCDDispatcher = [[self alloc] initWithSerialQueueID:JSDefaultSerialQueueName];    
  }
}

+ (id)sharedDispatcher {
  return gSharedGCDDispatcher;    
}

+ (id)dispatcherWithSerialQueueID:(NSString *)serialQueueID {
  return [[[self alloc] initWithSerialQueueID:serialQueueID] autorelease];
}

#pragma mark -
#pragma mark Instance Methods

- (id)initWithSerialQueueID:(NSString *)serialQueueID {
  if ((self = [super init])) {
    _serialQueueID = [serialQueueID copy];
    serial_dispatch_queue = dispatch_queue_create([self.serialQueueID UTF8String], NULL);
    serial_group = dispatch_group_create();
#if TARGET_OS_IPHONE
    _backgroundTasks = [[NSMutableSet alloc] init];
#endif
  }
  
  return self;
}

#if TARGET_OS_IPHONE

- (UIApplication *)application {
  if (!_application) {
    _application = [UIApplication sharedApplication];
  }
  return [[_application retain] autorelease];
}

#else

#endif


- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  dispatch_release(serial_dispatch_queue);
  dispatch_release(serial_group);  
  [_serialQueueID release];
  [super dealloc];
}

#pragma mark -
#pragma mark Dispatching Methods

- (void)dispatch:(void (^)(void))block priority:(dispatch_queue_priority_t)priority {
  dispatch_async(dispatch_get_global_queue(priority, 0), block);
}

- (void)dispatch:(void (^)(void))block {
  [self dispatch:block priority:DISPATCH_QUEUE_PRIORITY_DEFAULT];
}

- (void)dispatchOnSerialQueue:(void (^)(void))block {
  dispatch_group_async(serial_group, serial_dispatch_queue, block);
}

- (void)dispatchOnMainThread:(void (^)(void))block {
  // If a block is submitted to the queue that is already on the main run loop, 
  // the thread will block forever waiting for the completion of the block -- which will never happen.
  if ([NSThread currentThread] == [NSThread mainThread]) {
    block();    
  } else {
    dispatch_sync(dispatch_get_main_queue(), block);    
  }
}

- (void)submitSerialQueueCompletionListener:(void (^)(void))block {
  dispatch_group_notify(serial_group, serial_dispatch_queue, block);
}

- (void)waitForSerialQueueToComplete:(NSTimeInterval)timeout {
  dispatch_group_wait(serial_group, timeout * NSEC_PER_SEC);
}

#pragma mark - Resume and Suspend

- (void)suspendSerialQueue {
  dispatch_suspend(serial_dispatch_queue);
}

- (void)resumeSerialQueue {
  dispatch_resume(serial_dispatch_queue);
}

#if TARGET_OS_IPHONE

#pragma mark - iOS Background Queuing

- (void)dispatchBackgroundTask:(void (^)(UIBackgroundTaskIdentifier identifier))block priority:(dispatch_queue_priority_t)priority {
  UIBackgroundTaskIdentifier bgTask = [self.application beginBackgroundTaskWithExpirationHandler:^{
    UIBackgroundTaskIdentifier identifier = [self removeBackgroundTaskID:bgTask];
    [self.application endBackgroundTask:identifier];      
  }];  
  
  [self addBackgroundTaskID:bgTask];
  
  void(^gcdBlock)(void) = ^{
    UIBackgroundTaskIdentifier identifier = [self removeBackgroundTaskID:bgTask];
    @try {
      block(identifier);        
    }
    @catch (NSException *exception) {
      NSLog(@"Exception thrown in backgrond task: %@", exception);
    }
    @finally {
      [self.application endBackgroundTask:identifier];
    }
  };
  [self dispatch:gcdBlock priority:priority];
}
#endif

#pragma mark - Private

#if TARGET_OS_IPHONE
- (void)addBackgroundTaskID:(UIBackgroundTaskIdentifier)identifier {
  if (identifier != UIBackgroundTaskInvalid) {
    [self.backgroundTasks addObject:[NSNumber numberWithUnsignedInteger:identifier]];    
  }  
}

- (UIBackgroundTaskIdentifier)removeBackgroundTaskID:(UIBackgroundTaskIdentifier)identifier {
  NSNumber *boxedIdentifier = [NSNumber numberWithUnsignedInteger:identifier];
  if ([self.backgroundTasks containsObject:boxedIdentifier]) {
    [self.backgroundTasks removeObject:boxedIdentifier];
    return identifier;
  } else {
    return UIBackgroundTaskInvalid;
  }
}

#endif
@end

#import "MPWBlockContext.h"

@implementation MPWBlockContext(gcd)

typedef void (^voidBlock)(void );



-(void)onMainThread
{
    [[JSGCDDispatcher sharedDispatcher] dispatchOnMainThread:(voidBlock)self];
}

-(void)dispatch
{
    [self retain];
    [[JSGCDDispatcher sharedDispatcher] dispatch:^{ [self value]; [self release]; }];
}



@end




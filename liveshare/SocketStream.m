//
//  SocketStream.m
//  liveshare
//
//  Created by Cleiton Amaral Souza on 15/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SocketStream.h"

@implementation SocketStream

@synthesize inputStream;
@synthesize outputStream;

-(SocketStream *)init{
    
    if (( self = [super init] )) {
        [self initNetworkCommunication];   
    }
    return self;
}


-(void)sendFileChunks:(NSString *)msg{
    
  /*  NSString *response  = [NSString stringWithFormat:msg,nil];
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[self.outputStream write:[data bytes] maxLength:[data length]];
*/
  //pega o arquivo
    NSMutableArray *filesArray = [[NSMutableArray alloc] init];
    
    NSString *bundleRoot = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:bundleRoot];
    
    NSString *filename;
    
    while ((filename = [direnum nextObject] )) {
        
        if ([filename hasSuffix:@".mp4"]) {   //change the suffix to what you are looking for
            // Do work here
            [filesArray addObject:filename];
        }
    }
    
    filename = [filesArray objectAtIndex:filesArray.count -1];
    
    bundleRoot = [bundleRoot stringByAppendingFormat:[NSString stringWithFormat:@"/%@",filename],nil];
    
    NSUInteger SIZE = 512;
    
    NSUInteger total_filelenght = [[NSData dataWithContentsOfFile:bundleRoot] length];
    NSUInteger offset = 0;
    
    int i =0;
    
    while (total_filelenght >= offset) {
        
        NSData *data = [self dataWithContentsOfFile:bundleRoot atOffset:offset withSize:SIZE];
        
        i+=1;
        [self.outputStream write:[data bytes] maxLength:[data length]];
        
        offset += [data length] + 1;
        
        NSUInteger reminderBytes = total_filelenght - offset;
        
          NSLog(@"reminderBytes %d", reminderBytes);
        
        if (reminderBytes < SIZE){
            SIZE = reminderBytes;
        }
    }
        NSLog(@"Transmited %i", i);
    
    NSString *response  = [NSString stringWithFormat:@"quit",nil];
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[self.outputStream write:[data bytes] maxLength:[data length]];


}

- (NSData *) dataWithContentsOfFile:(NSString *)path atOffset:(off_t)offset withSize:(size_t)bytes
{
    FILE *file = fopen([path UTF8String], "rb");
    if(file == NULL)
        return nil;
    
    void *data = malloc(bytes);  // check for NULL!
    fseeko(file, offset, SEEK_SET);
    fread(data, 1, bytes, file);  // check return value, in case read was short!
    fclose(file);
    
    // NSData takes ownership and will call free(data) when it's released
    return [NSData dataWithBytesNoCopy:data length:bytes];
}



/*
 NSString *method = [NSString stringWithString:@"uploadStream"];
 
 NSString*pt = [[NSBundle mainBundle] pathForResource:@"Screen Recording 17" ofType:@"mp4"];
 NSMutableData *videoData = [NSMutableData dataWithData:[NSData dataWithContentsOfFilet]];
 NSMutableData *stringData = [NSMutableData dataWithData:[@"Screen Recording 17" dataUsingEncoding:NSUTF8StringEncoding]];
 NSLog(@"%d",stringData.length);
 
 Base64Transcoder *base64Transcoder = [[Base64Transcoder alloc] init];
 NSString *base64String = [[base64Transcoder base64EncodedStringfromData:videoData
 WithNewLineValidation:[NSNumber numberWithBool:YES]] copy];
 // [args addObject:@"helloegkjvdsfnvkeljsnfbvekjrnbverggjkn efnvkeljsnfbvekjrnbjkkerttrtnfgnregjknerkgjenrgkje rngkjsdasd"];
 
 for (int length = 0; length < [base64String lengthOfBytesUsingEncoding:NSUTF8StringEncoding]; length++) {
 NSMutableArray *args = [NSMutableArray array];
 
 int offset = length;
 length = length+97;
 [args addObject:[base64String substringWithRange:NSMakeRange(offset,length)]];
 // NSLog(@"invoke : %@ %d",args, length);
 [socket invoke:method withArgs:args];
 args = nil;
 sleep(4);
 }
 */

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
	switch (streamEvent) {
            
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
            
		case NSStreamEventHasBytesAvailable:
            
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output && [output length] > 1) {
                            NSLog(@"server said: %@", output);
                        }
                    }
                }
            }
            
			break;			
            
		case NSStreamEventErrorOccurred:
			NSLog(@"Can not connect to the host!");
			break;
            
		case NSStreamEventEndEncountered:
            NSLog(@"End encoutered!");
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            
			break;
            
		default:
			NSLog(@"Unknown event");
	}
}

- (void)initNetworkCommunication {
    
    CFReadStreamRef  readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)@"192.168.1.169", 2008, &readStream, &writeStream);
    
    self.inputStream  = (__bridge  NSInputStream *)readStream;
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    
    [self.inputStream  setDelegate:self];
    [self.outputStream setDelegate:self];
    
    [self.inputStream  scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.inputStream  open];
    [self.outputStream open];
}

-(void)endNetworkCommunication{
    
    [self.inputStream close];
    [self.outputStream close];
}

@end

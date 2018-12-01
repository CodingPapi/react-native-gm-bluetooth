//
//  JCBabyPrinterTool.h
//  XYFrameWork
//
//  Created by zhaohu on 2018/4/17.
//  Copyright © 2018年 xiaoyao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#include <CoreGraphics/CGImage.h>
#import "zlib.h"
#define MAX_DATA_SIZE (1024*1000)
typedef void(^BLOCK_CALLBACK_SCAN_FIND)(CBPeripheral*);
@interface JCBabyPrinterTool : NSObject{
    Byte _buffer[MAX_DATA_SIZE];
    int _offset;
    CGImageRef CGImage;
}

+(NSData*) gzipData:(NSData*)pUncompressedData;  //压缩
+(NSData*) ungzipData:(NSData *)compressedData;  //解压缩

-(bool)startJob:(int)goto_gap;
- (void)flushRead;

-(bool)startPage:(float) width height:(float)height orientation :(int)orientation;

-(bool)endPage;

-(UIImage *) createPrintImg:(UIImage*) image x:(float) x y:(float)  y widths:(float) widths heihts:( float) heights rotations:(int)rotations gotopaper:(int )gotopaper;
-(bool) drawBitmap:(UIImage*) image x:(float) x y:(float)  y widths:(float) widths heihts:( float) heights rotations:(int)rotations gotopaper:(int )gotopaper;

-(void) print_status_detect;
-(int)print_status_get:(int)timeout;

@property (getter=getDataLength,readonly)int dataLength;
-(BOOL) addData:(Byte *)data length:(int)length;
-(BOOL) addByte:(Byte)byte;
-(BOOL) addShort:(ushort)data;
-(BOOL) add:(NSString *)text;
-(NSData*) getData;
-(void) reset;
-(BOOL) addC:(NSString *)text;
@end

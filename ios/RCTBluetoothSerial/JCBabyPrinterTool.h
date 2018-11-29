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
    int _sendedDataLength;
    int leftDataLength;
    CGImageRef CGImage;
    NSMutableArray * array1;
    int isconnect;
}

@property (strong, nonatomic) CBPeripheral* peripheral;
@property (strong, nonatomic) CBCharacteristic* writeCharacteristic;

+(NSData*) gzipData:(NSData*)pUncompressedData;  //压缩
+(NSData*) ungzipData:(NSData *)compressedData;  //解压缩

-(bool)startJob:(int)goto_gap;
- (void)flushRead;

-(bool)startPage:(float) width height:(float)height orientation :(int)orientation;

-(bool)endPage;

-(bool) drawText:(NSString *) text xx:(float)xx yy:(float)yy t_width:(float) width t_height:(float) t_height textfontHeight:(float) textfontHeight;

-(bool) drawTextRegular:(NSString *) text x:(float) x y:(float) y width:(float) width heiht: (float) height  fontHeight:(float) fontHeight fontStyle:(int) fontStyle;


-(bool) drawBarcode:(NSString *)text type:(float)type x:(float)x y:( float)y width:(float)width height:(float)height fontHeight:(float)fontHeight;

-(bool) drawQrCode:(NSString *)text x:(float) x y:( float) y width:( int) width;

-(bool) drawLine:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2  lineWidth:(int)lineWidth;

-(bool) drawRectangle:(float) x y:(float) y width:( float) width heiht:( float) height  lineWidth:(int)lineWidth;

-(bool) drawBitmap:(UIImage*) image x:(float) x y:(float)  y widths:(float) widths heihts:( float) heights rotations:(int)rotations gotopaper:(int )gotopaper;

-(int) mmToPixel:(int) mm;

-(int) pixelToMm:(int) pixel;

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

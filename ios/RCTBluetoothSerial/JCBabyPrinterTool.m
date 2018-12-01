//
//  JCBabyPrinterTool.m
//  XYFrameWork
//
//  Created by zhaohu on 2018/4/17.
//  Copyright © 2018年 xiaoyao. All rights reserved.
//

#import "JCBabyPrinterTool.h"

@interface JCBabyPrinterTool ()
- (void)waitUI:(int)ms;


@property (strong, nonatomic) BLOCK_CALLBACK_SCAN_FIND scanFindCallback;
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSMutableArray* nServices;
@property int _h;

@property int _orientation;
@end

@implementation JCBabyPrinterTool

- (bool)writeData:(NSData*)data
{
    int sended=0;
    while(sended<data.length)
    {
        int len=data.length-sended;
        if(len>120)len=120;
        NSData *d = [data subdataWithRange:NSMakeRange(sended, len)];
        [self.peripheral writeValue:d forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithResponse];
        sended+=len;
        NSLog(@"发送...");
    }
    return true;
}

/*
 * 绘制打印页面
 */

+ (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 33 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
            
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}

-(bool) drawBitmap:(UIImage*) image rotations:(int)rotations gotopaper:(int )gotopaper
{
    
    UIImage *rotationimage=image;
    
    if(rotations==0)   rotationimage=[JCBabyPrinterTool image:rotationimage rotation:UIImageOrientationUpMirrored];
    if(rotations==90){
        rotationimage= [JCBabyPrinterTool image:rotationimage rotation:UIImageOrientationLeft];
    }
    if(rotations==180) rotationimage= [JCBabyPrinterTool image:rotationimage rotation:UIImageOrientationDown];
    if(rotations==270)
    {
        UIImage *image2= [JCBabyPrinterTool image:rotationimage rotation:UIImageOrientationLeft];
        UIImage *image3=[JCBabyPrinterTool image:image2 rotation:UIImageOrientationDown];
        // UIImage *image4=[Bluetooth image:image3 rotation:UIImageOrientationLeft];
        rotationimage=image3;
    }
    
    CGSize size = CGSizeMake(width_+xx, height_+yy);
    UIGraphicsBeginImageContext(size);
    [rotationimage drawInRect:CGRectMake(xx, yy, rotationimage.size.width, rotationimage.size.height)];
    rotationimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    size_t width = CGImageGetWidth(rotationimage.CGImage);
    size_t height = CGImageGetHeight(rotationimage.CGImage);

    
    size_t bytesPerRow = (width - 1) / 8 + 1;
    uint8_t imageBytes[bytesPerRow * height];
    [self cnc_getCompressedBinaryzationBytes:imageBytes reverse:YES img:rotationimage.CGImage];
    
    NSString *begin;
    NSData *pngdata;
    
    [self addData:imageBytes length:bytesPerRow * height];
    pngdata= [self getData];
    [self reset];
    
    int sended=0;
    while(sended<bytesPerRow * height)
    {
        Byte b[4]={0x1f,0x10,bytesPerRow%256,bytesPerRow/256};
        [self addData:b length:4];
        NSData *d = [pngdata subdataWithRange:NSMakeRange(sended, bytesPerRow)];
        NSUInteger len = [d length];
        Byte *byteData = (Byte*)malloc(len);
        memcpy(byteData, [d bytes], len);
        [self addData:byteData length:len];
        
        sended+=bytesPerRow;
        
    }
    NSData *data = [self getData];
    [self reset];
    NSData *dataDeflate = [JCBabyPrinterTool gzipData:data];
    [self writeData:dataDeflate];
    //    0：连续纸；1：定位孔(如不支持定位孔，则调整至间隙纸)；2：间隙纸；3：黑标纸。
    if(gotopaper ==0)
    {
        
    }
    if(gotopaper ==1)
    {
        Byte a[2] ;
        a[0]=0x1d;a[1]=0x0c;
        NSData *adata = [[NSData alloc] initWithBytes:a length:2];
        [ self writeData:adata];
    }
    if(gotopaper ==2)
    {
        Byte a[2] ;
        a[0]=0x1d;a[1]=0x0c;
        NSData *adata = [[NSData alloc] initWithBytes:a length:2];
        [ self writeData:adata];
    }
    if(gotopaper ==3) //左黑标
    {
        Byte a[1] ;
        a[0]=0x0c;
        NSData *adata = [[NSData alloc] initWithBytes:a length:1];
        [ self writeData:adata];
    }
    if(gotopaper ==4) //右黑标
    {
        Byte a[1] ;
        a[0]=0x0e;
        NSData *adata = [[NSData alloc] initWithBytes:a length:1];
        [ self writeData:adata];
    }
    return  true;
}
//压缩
+(NSData*) gzipData: (NSData*)pUncompressedData
{
    if (!pUncompressedData || [pUncompressedData length] == 0)
    {
        NSLog(@"%s: Error: Can't compress an empty or null NSData object.", __func__);
        return nil;
    }
    int deflateStatus;
    float buffer = 1.1;
    do {
        z_stream zlibStreamStruct;
        zlibStreamStruct.zalloc    = Z_NULL; // Set zalloc, zfree, and opaque to Z_NULL so
        zlibStreamStruct.zfree     = Z_NULL; // that when we call deflateInit2 they will be
        zlibStreamStruct.opaque    = Z_NULL; // updated to use default allocation functions.
        zlibStreamStruct.total_out = 0; // Total number of output bytes produced so far
        zlibStreamStruct.next_in   = (Bytef*)[pUncompressedData bytes]; // Pointer to input bytes
        zlibStreamStruct.avail_in  = (uInt)[pUncompressedData length]; // Number of input bytes left to process
        int initError = deflateInit2(&zlibStreamStruct, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
        if (initError != Z_OK)
        {
            NSString *errorMsg = nil;
            switch (initError)
            {
                case Z_STREAM_ERROR:
                    errorMsg = @"Invalid parameter passed in to function.";
                    break;
                case Z_MEM_ERROR:
                    errorMsg = @"Insufficient memory.";
                    break;
                case Z_VERSION_ERROR:
                    errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                    break;
                default:
                    errorMsg = @"Unknown error code.";
                    break;
            }
            NSLog(@"%s: deflateInit2() Error: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
            return nil;
        }
        
        // Create output memory buffer for compressed data. The zlib documentation states that
        // destination buffer size must be at least 0.1% larger than avail_in plus 12 bytes.
        NSMutableData *compressedData = [NSMutableData dataWithLength:[pUncompressedData length] * buffer + 12];
        do {
            // Store location where next byte should be put in next_out
            zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;
            // Calculate the amount of remaining free space in the output buffer
            // by subtracting the number of bytes that have been written so far
            // from the buffer's total capacity
            zlibStreamStruct.avail_out = (uInt)([compressedData length] - zlibStreamStruct.total_out);
            deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);
        } while ( deflateStatus == Z_OK );
        if (deflateStatus == Z_BUF_ERROR && buffer < 32) {
            continue;
        }
        // Check for zlib error and convert code to usable error message if appropriate
        if (deflateStatus != Z_STREAM_END) {
            NSString *errorMsg = nil;
            switch (deflateStatus)
            {
                case Z_ERRNO:
                    errorMsg = @"Error occured while reading file.";
                    break;
                case Z_STREAM_ERROR:
                    errorMsg = @"The stream state was inconsistent (e.g., next_in or next_out was NULL).";
                    break;
                case Z_DATA_ERROR:
                    errorMsg = @"The deflate data was invalid or incomplete.";
                    break;
                case Z_MEM_ERROR:
                    errorMsg = @"Memory could not be allocated for processing.";
                    break;
                case Z_BUF_ERROR:
                    errorMsg = @"Ran out of output buffer for writing compressed bytes.";
                    break;
                case Z_VERSION_ERROR:
                    errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                    break;
                default:
                    errorMsg = @"Unknown error code.";
                    break;
            }
            NSLog(@"%s: zlib error while attempting compression: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
            // Free data structures that were dynamically created for the stream.
            deflateEnd(&zlibStreamStruct);
            return nil;
        }
        
        // Free data structures that were dynamically created for the stream.
        deflateEnd(&zlibStreamStruct);
        [compressedData setLength: zlibStreamStruct.total_out];
        int countsize=compressedData.length;
        Byte aa[] ={(countsize>>0)&0xff};
        Byte bb[] = {(countsize>>8)&0xff};
        Byte cc[] = {(countsize>>16)&0xff};
        Byte dd[] = {(countsize>>24)&0xff};
        [compressedData replaceBytesInRange:NSMakeRange(4, 1) withBytes:aa length:1];
        [compressedData replaceBytesInRange:NSMakeRange(5, 1) withBytes:bb length:1];
        [compressedData replaceBytesInRange:NSMakeRange(6, 1) withBytes:cc length:1];
        [compressedData replaceBytesInRange:NSMakeRange(7, 1) withBytes:dd length:1];
        
        uLong crc = crc32(0L, Z_NULL, 0);
        crc = crc32(crc, compressedData.bytes+8,compressedData.length-12);
        
        Byte a[] ={(crc>>0)&0xff};
        Byte b[] = {(crc>>8)&0xff};
        Byte c[] = {(crc>>16)&0xff};
        Byte d[] = {(crc>>24)&0xff};
        
        [compressedData replaceBytesInRange:NSMakeRange(countsize-4, 1) withBytes:a length:1];
        [compressedData replaceBytesInRange:NSMakeRange(countsize-3, 1) withBytes:b length:1];
        [compressedData replaceBytesInRange:NSMakeRange(countsize-2, 1) withBytes:c length:1];
        [compressedData replaceBytesInRange:NSMakeRange(countsize-1, 1) withBytes:d length:1];
        return compressedData;
    } while ( false );
    return nil;
}

- (void)cnc_getBinaryzationBytes:(char *)data reverse:(BOOL)reverse img:(CGImageRef) img
{
    [self cnc_getBinaryzationBytes:data threshold:128 reverse:reverse img:img];
}

- (void)cnc_getBinaryzationBytes:(char *)data threshold:(int)threshold reverse:(BOOL)reverse img:(CGImageRef) img
{
    if (!data) {
        return;
    }
    
    CGImageRef imageRef = img;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    uint32_t *pixels = malloc(width * height * sizeof(uint32_t));
    if (!pixels) {
        return;
    }
    
    size_t byteWidth = (width - 1) / 8 + 1;
    Byte s[(4+byteWidth)*height];
    NSString * string;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t bitsPerComponent = 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    for (int i = 0; i < height; i++) {
        
        
        for (int j = 0; j < width; j++) {
            
            uint8_t *rgbaPixel = (uint8_t *)&pixels[i * width + j];
            
            // http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
            uint8_t gray = 0.299 * rgbaPixel[2] + 0.587 * rgbaPixel[1] + 0.114 * rgbaPixel[0];
            data[i * width + j] = gray < threshold ? (uint8_t)reverse : (uint8_t)!reverse;
            
        }
    }
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    if (pixels) {
        free(pixels);
    }
}

- (void)cnc_getCompressedBinaryzationBytes:(char *)data  reverse:(BOOL)reverse img:(CGImageRef) img
{
    int threshold=128;
    bool littleEndian=NO;
    if (!data) {
        return;
    }
    
    CGImageRef imageRef = img;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    uint8_t *imageBytes = malloc(width * height * sizeof(uint8_t));
    if (!imageBytes) {
        return;
    }
    
    [self cnc_getBinaryzationBytes:imageBytes threshold:threshold reverse:reverse img:img];
    size_t byteWidth = (width - 1) / 8 + 1;
    Byte s[(4+byteWidth)*height];
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < byteWidth; j++) {
            uint8_t unit = 0;
            for (int k = 0; k < 8; k++) {
                if (((j << 3) + k) < width) {
                    uint8_t pixel = imageBytes[i * width + (j << 3) + k];
                    if (littleEndian) {
                        unit |= (pixel & 1) << k;
                    } else {
                        unit |= (pixel & 1) << (7 - k);
                    }
                }
            }
            
            data[i * byteWidth + j] = unit;
        }
    }
    if (imageBytes) {
        free(imageBytes);
    }
}

-(BOOL) addData:(Byte *)data length:(int)length{
    if (_offset + length > MAX_DATA_SIZE)
        return FALSE;
    memcpy(_buffer + _offset, data, length);
    _offset += length;
    return TRUE;
}

-(NSData*) getData{
    NSData *data;
    data = [[NSData alloc]initWithBytes:_buffer length:[self getDataLength]];
    return data;
}

@end

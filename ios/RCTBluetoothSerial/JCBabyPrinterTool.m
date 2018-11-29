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
//@property (strong, nonatomic) NSMutableArray * array1;
@property int _h;

@property int _orientation;
@end

@implementation JCBabyPrinterTool

static Byte receiveBuffer[1024];
static int receiveLength=0;

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

- (void)flushRead
{
    receiveLength=0;
}

- (bool)readBytes:(BytePtr)data len:(int)len timeout:(int)timeout
{
    for(int i=0;i<timeout/10;i++)
    {
        if(receiveLength>=len)break;
        [self waitUI:10];
    }
    if(receiveLength<len)return false;
    for(int i=0;i<len;i++)
    {
        data[i]=receiveBuffer[i];
    }
    for(int i=len;i<receiveLength;i++)
    {
        receiveBuffer[i-len]=receiveBuffer[i];
    }
    receiveLength-=len;
    return true;
    
    
}

/*
 * 绘制打印页面
 */

-(bool)startJob:(int)goto_gap
{
    NSData *data = [self getData];
    [self writeData:data];
    
    if (goto_gap==1)
    {
        Byte a[2] ;
        a[0]=0x1d;a[1]=0x0c;
        NSData *adata = [[NSData alloc] initWithBytes:a length:2];
        [self writeData:adata];
    }
    if (goto_gap==2) {//zuo heibiao
        Byte a[]={0x0c};
        NSData *adata = [[NSData alloc] initWithBytes:a length:1];
        [self writeData:adata];
    }
    if (goto_gap==3) {//you heibiao
        Byte a[]={0x0e};
        NSData *adata = [[NSData alloc] initWithBytes:a length:1];
        [self writeData:adata];
    }
    if (goto_gap==0) {//
        
    }
    return true;
}


-(bool)startPage:(float) width height:(float)height orientation :(int)orientation
{
    int nheiht=height;
    self._h=nheiht;
    self._orientation=orientation;
    
    NSString *begin = [NSString stringWithFormat:@"! 0 200 200 %d 1\r\n",nheiht];
    [self addC:begin];
    return true;
    
}

-(bool)endPage
{
    [  self addC:@"PRINT\r\n"];
    return true;
}


-(bool) drawText:(NSString *) text xx:(float)xx yy:(float)yy t_width:(float) t_width t_height:(float) t_height textfontHeight:(float) textfontHeight
{
    int x=xx;
    int y=yy;
    int width=t_width;
    int height=t_height;
    int fontHeight=textfontHeight;
    
    int rotate=0;
    // x=x*8;
    // y=y*8;
    // width=width*8;
    // height=height*8;
    
    int cx=0;
    int cy=0;
    int f_height = 0;
    // TODO Auto-generated method stub
    if(fontHeight==16){f_height=16;}
    if(fontHeight==24){ f_height=24;}
    if(fontHeight==32)
    {
        
        f_height=32;
    }
    if(fontHeight==48)
    {
        
        f_height=48;
    }
    
    if(fontHeight==64)
    {
        
        f_height=64;
    }
    if(fontHeight==72)
    {
        
        f_height=72;
    }
    if(fontHeight==96)
    {
        
        f_height=96;
    }
    
    //             if(width==0)
    //             {
    //                    impl.DrawText(x, y, text, fontHeight, 0, false, false);
    //                    return true;
    //             }
    //             if(height==0)
    //             {
    //                    impl.DrawText(x, y, text, fontHeight, 0, false, false);
    //                    return true;
    //             }
    
    
    int _x=width/f_height;
    int _y=height/f_height;
    int _xx=_x;
    int ii=0;
    
    
    bool ver=true;
    int a=text.length;
    if(_y==1)
    {
        if(a>=_x)
        {
            
            //  NSString * s=  text.substring(ii, _x);
            NSString * s= [text substringWithRange:NSMakeRange(ii,_x)];
            
            //  impl.DrawText(x, y, s, fontHeight, 0, false, rotate);
            
            [self Text :x y:y text:s  font :fontHeight  textSize:0 bold: false  rotate: rotate];
        }
        else
        {
            
            [self Text :cx y:cy text:text font :fontHeight  textSize:0 bold: false  rotate: rotate];
            
        }
        
        
        
        //            DrawText(text_x,text_y,str,fontsize,rotate,bold,reverse,underline);
        
    }
    else
    {
        int b=text.length;
        
        
        
        if(_x==1)
        {
            
            for(int i=0;i<b;i++)//////////
            {
                if(_x*_y>b)
                {
                    NSString * s= [text substringWithRange:NSMakeRange(ii,_x)];
                    //      impl.DrawText(x, y+(f_height*(i+1)), s, fontHeight, 0, false, rotate);
                    [self Text :x y:y+(f_height*(i+1)) text:s  font :fontHeight  textSize:0 bold: false  rotate: rotate];
                    
                    //  ii++;
                    //  _x++;
                }
                else
                {
                    // String s=text.substring(ii, _x);
                    NSString * s= [text substringWithRange:NSMakeRange(ii,_x)];
                    // impl.DrawText(x, y+(f_height*(i+1))-(height-(b/_x*f_height))/2, s, fontHeight, 0, false, rotate);
                    [self Text :x y:y+(f_height*(i+1))-(height-(b/_x*f_height))/2 text:s  font :fontHeight  textSize:0 bold: false  rotate: rotate];
                    
                    //  ii++;
                    //   _x++;
                }
            }
        }
        else
            
        {
            int t;
            int tt=0;
            if((_x-a)>=0&&ver==true)
            {
                
                [self Text :cx y:cy text:text  font :fontHeight  textSize:0 bold: false  rotate: rotate];
                ver=false;
                return true;
            }
            if(_x-a<0)
            {
                int line=b/_x;
                for( t=0;t<_y;t++)
                {
                    
                    ver=false;
                    //   String s=text.substring(ii, _x);
                    NSString * s= [text substringWithRange:NSMakeRange(ii,_x)];
                    
                    //impl.DrawText(x, y+(f_height*(tt++)), s, fontHeight, 0, false, rotate);
                    [self Text :x y:y+(f_height*(tt++)) text:s  font :fontHeight  textSize:0 bold: false  rotate: rotate];
                    ii=ii+3;
                    a=a-_xx;
                    // _x=_x+_xx;
                    
                    if((_xx-a)>=0)
                    {
                        //s=text.substring(ii, text.length());
                        s=[text substringWithRange:NSMakeRange(ii,a)];
                        //    DrawText(text_x,text_y+(f_height*(tt++)),s,fontsize,rotate,bold,reverse,underline);
                        //impl.DrawText(x, y+(f_height*(tt++)), s, fontHeight, 0, false, rotate);
                        [self Text :x y:y+(f_height*(tt++)) text:s  font :fontHeight  textSize:0 bold: false  rotate: rotate];
                        
                        return true;
                    }
                    
                }
            }
            
        }
    }
    return true;
    
}

-(bool) drawTextRegular:(NSString *) text x:(float) x y:(float) y width:(float) width heiht: (float) height  fontHeight:(float) fontHeight fontStyle:(int) fontStyle
{
    return true;
}


-(bool) drawBarcode:(NSString *)text type:(int)type x:(float)x y:( float)y width:(float)width height:(float)height fontHeight:(float)fontHeight
{
    int xx=x;
    int yy=y;
    int width_=width;
    int height_=height;
    
    
    NSString * t=@"128";
    if(type==20)t=@"UPC-A";
    if(type==21)t=@"UPC-E";
    if(type==22)t=@"EAN13";
    if(type==23)t=@"EAN8";
    if(type==24)t=@"39";
    if(type==25)t=@"I2OF5";
    if(type==26)t=@"CODABAR";
    if(type==27)t=@"93";
    if(type==28)t=@"128";
    //if(type==29)t="UPC-A";
    //if(type==30)t="UPC-A";
    if(type==60)t=@"128";
    
    NSString * cmd = @"BARCODE";
    // if(rotate)cmd="VBARCODE";
    NSString * str = [NSString stringWithFormat:@"%@ %@ %d 1 %d %d %d %@\r\n",cmd,t, width_,height_,xx,yy,text];
    [self addC:str];
    return true;
}

-(bool) drawQrCode:(NSString *)text x:(float) x y:( float) y width:( int) width
{
    int xx=x;
    int yy=y;
    NSString *cmd =@"BARCODE";
    // if(rotate)cmd=@"VBARCODE";
    NSString *str = [NSString stringWithFormat:@"%@ QR %d %d M %d U %d\r\n",cmd,xx,yy,2,width];
    [self addC:str];
    [self addC:@"MA,"];
    [self addC:text];
    [self addC:@"\r\nENDQR\r\n"];
    return true;
}

-(bool) drawLine:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2  lineWidth:(int)lineWidth
{
    int xx1=x1;
    int yy1=y1;
    int xx2=x2;
    int yy2=y2;
    
    NSString *str = [NSString stringWithFormat:@"LINE %d %d %d %d %d\r\n", xx1,yy1,xx2,yy2,lineWidth];
    [self addC:str];
    return true;
}
-(bool) drawRectangle:(float) x y:(float) y width:( float) width heiht:( float) height  lineWidth:(int)lineWidth
{
    int xx=x;
    int yy=y;
    int width_=width;
    int height_=height;
    
    NSString *str = [NSString stringWithFormat:@"BOX %d %d %d %d %d\r\n", xx,yy,xx+width_,yy+height_,lineWidth];
    [self addC:str];
    return true;
}

+ (UIImage *)imageWithColor:(UIColor *)color w:(int)w h:(int)h{
    CGRect rect = CGRectMake(0.0f, 0.0f, w, h); //宽高 1.0只要有值就够了
    UIGraphicsBeginImageContext(rect.size); //在这个范围内开启一段上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);//在这段上下文中获取到颜色UIColor
    CGContextFillRect(context, rect);//用这个颜色填充这个上下文
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();//从这段上下文中获取Image属性,,,结束
    UIGraphicsEndImageContext();
    
    return image;
}

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
-(UIImage *)reSizeImage:(UIImage *)image h:(int)h w:(int)w
{
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    [image drawInRect:CGRectMake(0, 0, w,h)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return reSizeImage;
    
}

-(bool) drawBitmap:(UIImage*) image x:(float) x y:(float)  y widths:(float) widths heihts:( float) heights rotations:(int)rotations gotopaper:(int )gotopaper
{
    int xx=x;
    int yy=y;
    int width_=widths;
    int height_=heights;
    
    UIImage *image1 = [JCBabyPrinterTool imageWithColor:UIColor.whiteColor w:width_+xx h:height_+yy];
    image=[self reSizeImage:image h:height_ w:width_];
    UIImage *rotationimage=image;
    
    if(rotations==0)   rotationimage=[JCBabyPrinterTool image:rotationimage rotation:UIImageOrientationUpMirrored];
    if(rotations==90){
        rotationimage= [JCBabyPrinterTool image:rotationimage rotation:UIImageOrientationLeft];
        float imagewidth = rotationimage.size.width;
        float imageHeight = rotationimage.size.height;
        if(rotationimage.size.width > rotationimage.size.height)
        {
            imagewidth = rotationimage.size.height;
            imageHeight = imagewidth * (rotationimage.size.height/rotationimage.size.width);
        }
        else if(rotationimage.size.width < rotationimage.size.height){
            imageHeight = rotationimage.size.width;
            imagewidth = imageHeight * (rotationimage.size.width/rotationimage.size.height);
        }
        rotationimage= [self reSizeImage:rotationimage h:imageHeight w:imagewidth];
    }
    if(rotations==180) rotationimage= [JCBabyPrinterTool image:rotationimage rotation:UIImageOrientationDown];
    if(rotations==270)
    {
        UIImage *image2= [JCBabyPrinterTool image:rotationimage rotation:UIImageOrientationLeft];
        UIImage *image3=[JCBabyPrinterTool image:image2 rotation:UIImageOrientationDown];
        // UIImage *image4=[Bluetooth image:image3 rotation:UIImageOrientationLeft];
        rotationimage=image3;
        float imagewidth = rotationimage.size.width;
        float imageHeight = rotationimage.size.height;
        if(rotationimage.size.width > rotationimage.size.height)
        {
            imagewidth = rotationimage.size.height;
            imageHeight = imagewidth * (rotationimage.size.height/rotationimage.size.width);
        }
        else if(rotationimage.size.width < rotationimage.size.height){
            imageHeight = rotationimage.size.width;
            imagewidth = imageHeight * (rotationimage.size.width/rotationimage.size.height);
        }
        rotationimage= [self reSizeImage:rotationimage h:imageHeight w:imagewidth];
    }
    
    
    CGSize size = CGSizeMake(width_+xx, height_+yy);
    UIGraphicsBeginImageContext(size);
    [image1 drawInRect:CGRectMake(0, 0, image.size.width+xx,image.size.height+yy)];
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
    
    /* int y0=0;
     while(y0<height)
     {
     int hh=height-y0;
     for (int yy = y0; yy < y0+hh; yy++) {
     for (int xx = 0; xx < width; xx++) {
     uint8_t *rgbaPixel = (uint8_t *)&pixels[yy * width + xx];
     uint8_t gray = 0.299 * rgbaPixel[2] + 0.587 * rgbaPixel[1] + 0.114 * rgbaPixel[0];
     data[(yy-y0) * width + xx] = gray < threshold ? (uint8_t)reverse : (uint8_t)!reverse;
     }
     }
     
     
     }*/
    
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



-(void) print_status_detect
{
    Byte byte[2] = {0x1d,0x99};
    NSData *adata = [[NSData alloc] initWithBytes:byte length:2];
    [self writeData:adata];
}

-(int)print_status_get:(int)timeout
{
    Byte readdate[4];
    int a=0;
    
    if(![self readBytes:readdate len:4 timeout:timeout])
    {
        return -1;
    }
    if (readdate[0]!=0x1d) {
        return -1;
    }
    if (readdate[1]!=0x99) {
        return -1;
    }
    if(readdate[3]!=0xff)
    {
        return -1;
    }
    
    if ((readdate[2] & 0x1)!=0) {
        a=1;
    }
    if ((readdate[2]& 0x02)!=0) {
        a=2;
    }
    return a;
}


-(int) mmToPixel:(int) mm
{
    return mm;
}

-(int) pixelToMm:(int) pixel
{
    
    return pixel ;
}




@synthesize dataLength;
-(id)init{
    self = [super init];
    _offset = 0;
    _sendedDataLength = 0;
    return self;
}

-(void)reset{
    _offset = 0;
    _sendedDataLength = 0;
}

-(int) getDataLength{
    return _offset;
}

-(BOOL) addData:(Byte *)data length:(int)length{
    if (_offset + length > MAX_DATA_SIZE)
        return FALSE;
    memcpy(_buffer + _offset, data, length);
    _offset += length;
    return TRUE;
}

-(BOOL) addByte:(Byte)byte{
    if (_offset + 1 > MAX_DATA_SIZE)
        return FALSE;
    _buffer[_offset++] = byte;
    return TRUE;
}

-(BOOL) addShort:(ushort)data{
    if (_offset + 2 > MAX_DATA_SIZE)
        return FALSE;
    _buffer[_offset++] = (Byte)data;
    _buffer[_offset++] = (Byte)(data>>8);
    return TRUE;
}

-(BOOL) add:(NSString *)text{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData* gbk = [text dataUsingEncoding:enc];
    Byte* gbkBytes = (Byte*)[gbk bytes]  ;
    if(![self addData:gbkBytes length:gbk.length])
        return FALSE;
    return [self addByte:0x00];
}

-(BOOL) addC:(NSString *)text{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData* gbk = [text dataUsingEncoding:enc];
    Byte* gbkBytes = (Byte*)[gbk bytes]  ;
    if(![self addData:gbkBytes length:gbk.length])
        return FALSE;
    return true;
}

-(NSData*) getData{
    
    
    NSData *data;
    data = [[NSData alloc]initWithBytes:_buffer+_sendedDataLength length:[self getDataLength]];
    //_offset -= [self getDataLength];
    //_sendedDataLength +=[self getDataLength];
    return data;
}
-(void) Text: (int) x y:(int) y text:(NSString *) text font :(int) font  textSize:(int) textSize bold:(bool) bold  rotate:(int) rotate
{
    int f_size=24;
    int f_height=24;
    
    
    NSString *textScale=@"";
    if(font==16){f_size=55;f_height=16;}
    if(font==24){ f_size=24;f_height=24;}
    if(font==32)
    {
        //f_size=55;// textScale = String.format("SETMAG %d %d\r\n", 2,2);
        //add(textScale.getBytes());
        f_size=56;
        f_height=32;
    }
    if(font==48)
    {
        f_size=24; textScale =[NSString stringWithFormat:@"SETMAG %d %d\r\n", 2,2];
        [self addC:textScale];
        f_height=48;
    }
    
    if(font==64)
    {
        f_size=56; textScale =[NSString stringWithFormat:@"SETMAG %d %d\r\n", 2,2];
        [self addC:textScale];
        f_height=64;
    }
    if(font==72)
    {
        f_size=24;  textScale =[NSString stringWithFormat:@"SETMAG %d %d\r\n", 3,3];
        [self addC:textScale];
        f_height=72;
    }
    if(font==96)
    {
        f_size=56;  textScale =[NSString stringWithFormat:@"SETMAG %d %d\r\n", 3,3];
        [self addC:textScale];
        f_height=96;
    }
    
    /*if(bold==1)
     {
     add("SETBOLD 1\r\n".getBytes());
     }
     else
     {
     add("SETBOLD 0\r\n".getBytes());
     }
     */
    NSString * cmd = @"T";
    if(rotate==90)cmd=@"VT";
    if(rotate==180)cmd=@"T180";
    if(rotate==270)cmd=@"T270";
    
    NSString * str =[NSString stringWithFormat:@"%@ %d %d %d %d %@\r\n",cmd,f_size,0,x,y,text];
    [self addC:str];
    [self addC:@"SETMAG 0 0 \r\n"];
    
}
#pragma mark - 帮助方法

- (NSString *)hexStringFromBytes:(const uint8_t *)bytes length:(size_t)length
{
    if (!bytes) {
        return @"";
    }
    
    NSMutableString *hex = [NSMutableString string];
    for (size_t i = 0; i < length; i++) {
        [hex appendFormat:@"%02X", bytes[i]];
    }
    
    return hex;
}

@end

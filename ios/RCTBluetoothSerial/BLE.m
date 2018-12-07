
/*

 Copyright (c) 2013 RedBearLab

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#import "BLE.h"
#import "BLEDefines.h"

@implementation BLE

@synthesize delegate;
@synthesize CM;
@synthesize peripherals;
@synthesize activePeripheral;

static bool isConnected = false;
static int rssi = 0;
static const int MAX_BUF_LENGTH = 100;

// TODO should have a configurable list of services
CBUUID *redBearLabsServiceUUID;
CBUUID *adafruitServiceUUID;
CBUUID *lairdServiceUUID;
CBUUID *blueGigaServiceUUID;
CBUUID *rongtaSerivceUUID;
CBUUID *posnetSerivceUUID;
CBUUID *serialServiceUUID;
CBUUID *readCharacteristicUUID;
CBUUID *writeCharacteristicUUID;

-(void) readRSSI
{
    [activePeripheral readRSSI];
}

-(BOOL) isConnected
{
    return isConnected;
}

-(void) read
{
//    CBUUID *uuid_service = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
//    CBUUID *uuid_char = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];

//    [self readValue:uuid_service characteristicUUID:uuid_char p:activePeripheral];
     [self readValue:serialServiceUUID characteristicUUID:readCharacteristicUUID p:activePeripheral];

}

-(void) write:(NSData *)d
{
    NSLog(@"%@", @"write in ble.m");
    NSInteger data_len = d.length;
    NSData *buffer;
    int i = 0;
    
    for(; i < data_len; i+=MAX_BUF_LENGTH)
    {
        NSInteger remainLength = data_len-i;
        NSInteger bufLen = ((remainLength)>MAX_BUF_LENGTH) ? MAX_BUF_LENGTH:remainLength;
        buffer = [d subdataWithRange:NSMakeRange(i, bufLen)];
        
        NSLog(@"Buffer data %i %i %@", remainLength, i, [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding]);
        
        [self writeValue:serialServiceUUID characteristicUUID:writeCharacteristicUUID p:activePeripheral data:buffer];
    }
}

-(void) enableReadNotification:(CBPeripheral *)p
{
//    CBUUID *uuid_service = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
//    CBUUID *uuid_char = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];
//
//    [self notification:uuid_service characteristicUUID:uuid_char p:p on:YES];
    [self notification:serialServiceUUID characteristicUUID:readCharacteristicUUID p:p on:YES];

}

-(void) notification:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];

    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
               [self CBUUIDToString:serviceUUID],
               p.identifier.UUIDString);

        return;
    }

    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];

    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    [p setNotifyValue:on forCharacteristic:characteristic];
}

-(UInt16) frameworkVersion
{
    return RBL_BLE_FRAMEWORK_VER;
}

-(NSString *) CBUUIDToString:(CBUUID *) cbuuid;
{
    NSData *data = cbuuid.data;

    if ([data length] == 2)
    {
        const unsigned char *tokenBytes = [data bytes];
        return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
    }
    else if ([data length] == 16)
    {
        NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
        return [nsuuid UUIDString];
    }

    return [cbuuid description];
}

-(void) readValue: (CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];

    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];

    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    [p readValueForCharacteristic:characteristic];
}

-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];

    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];

    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    NSLog(@"%@", @"writeValue in ble.m");
    
    NSLog(@"Buffer data %i", data.length);
    if ((characteristic.properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite) {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    else if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse) {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

-(UInt16) swap:(UInt16)s
{
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

- (void) controlSetup
{
    self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (int) findBLEPeripherals:(int) timeout
{
    if (self.CM.state != CBCentralManagerStatePoweredOn)
    {
        NSLog(@"CoreBluetooth not correctly initialized !");
        NSLog(@"State = %ld (%s)\r\n", (long)self.CM.state, [self centralManagerStateToString:self.CM.state]);
        return -1;
    }

    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];

#if TARGET_OS_IPHONE
    redBearLabsServiceUUID = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
    adafruitServiceUUID = [CBUUID UUIDWithString:@ADAFRUIT_SERVICE_UUID];
    lairdServiceUUID = [CBUUID UUIDWithString:@LAIRD_SERVICE_UUID];
    blueGigaServiceUUID = [CBUUID UUIDWithString:@BLUEGIGA_SERVICE_UUID];
    rongtaSerivceUUID = [CBUUID UUIDWithString:@RONGTA_SERVICE_UUID];
    posnetSerivceUUID = [CBUUID UUIDWithString:@POSNET_SERVICE_UUID];

    NSArray *services = @[redBearLabsServiceUUID, adafruitServiceUUID, lairdServiceUUID, blueGigaServiceUUID, rongtaSerivceUUID, posnetSerivceUUID];
    [self.CM scanForPeripheralsWithServices:services options: nil];
#else
    [self.CM scanForPeripheralsWithServices:nil options:nil]; // Start scanning
#endif

    NSLog(@"scanForPeripheralsWithServices");

    return 0; // Started scanning OK !
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    done = false;

    [[self delegate] bleDidDisconnect];

    isConnected = false;
}

- (void) connectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connecting to peripheral with UUID : %@", peripheral.identifier.UUIDString);

    self.activePeripheral = peripheral;
    self.activePeripheral.delegate = self;
    [self.CM connectPeripheral:self.activePeripheral
                       options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (const char *) centralManagerStateToString: (int)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }

    return "Unknown state";
}

- (void) scanTimer:(NSTimer *)timer
{
    [self.CM stopScan];
    NSLog(@"Stopped Scanning");
    NSLog(@"Known peripherals : %lu", (unsigned long)[self.peripherals count]);
    [self printKnownPeripherals];
}

- (void) printKnownPeripherals
{
    NSLog(@"List of currently known peripherals :");

    for (int i = 0; i < self.peripherals.count; i++)
    {
        CBPeripheral *p = [self.peripherals objectAtIndex:i];

        if (p.identifier != NULL)
            NSLog(@"%d  |  %@", i, p.identifier.UUIDString);
        else
            NSLog(@"%d  |  NULL", i);

        [self printPeripheralInfo:p];
    }
}

- (void) printPeripheralInfo:(CBPeripheral*)peripheral
{
    NSLog(@"------------------------------------");
    NSLog(@"Peripheral Info :");

    if (peripheral.identifier != NULL)
        NSLog(@"UUID : %@", peripheral.identifier.UUIDString);
    else
        NSLog(@"UUID : NULL");

    NSLog(@"Name : %@", peripheral.name);
    NSLog(@"-------------------------------------");
}

- (BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2
{
    if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString])
        return TRUE;
    else
        return FALSE;
}

-(void) getAllServicesFromPeripheral:(CBPeripheral *)p
{
    [p discoverServices:nil]; // Discover all services without filter
}

-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p
{
    for (int i=0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        //        printf("Fetching characteristics for service with UUID : %s\r\n",[self CBUUIDToString:s.UUID]);
        [p discoverCharacteristics:nil forService:s];
    }
}

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];

    if (memcmp(b1, b2, UUID1.data.length) == 0)
        return 1;
    else
        return 0;
}

-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2
{
    char b1[16];

    [UUID1.data getBytes:b1];
    UInt16 b2 = [self swap:UUID2];

    if (memcmp(b1, (char *)&b2, 2) == 0)
        return 1;
    else
        return 0;
}

-(UInt16) CBUUIDToInt:(CBUUID *) UUID
{
    char b1[16];
    [UUID.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}

-(CBUUID *) IntToCBUUID:(UInt16)UUID
{
    char t[16];
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:t length:16];
    return [CBUUID UUIDWithData:data];
}

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID])
            return s;
    }

    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }

    return nil; //Characteristic not found on this service
}

#if TARGET_OS_IPHONE
    //-- no need for iOS
#else
- (BOOL) isLECapableHardware
{
    NSString * state = nil;

    switch ([CM state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;

        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;

        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;

        case CBCentralManagerStatePoweredOn:
            return TRUE;

        case CBCentralManagerStateUnknown:
        default:
            return FALSE;

    }

    NSLog(@"Central manager state: %@", state);

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
    [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];

    return FALSE;
}
#endif

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
#if TARGET_OS_IPHONE
    char *stateString = [self centralManagerStateToString:central.state];

    NSLog(@"Status of CoreBluetooth central manager changed %ld (%s)", (long)central.state, stateString);

    bool isBluetoothEnabled = false;
    if (central.state == CBCentralManagerStatePoweredOn) {
        isBluetoothEnabled = true;
    }

    if (!isBluetoothEnabled && isConnected) {
        [[self delegate] bleDidDisconnect];
        done = false;
        isConnected = false;
    }

    [[self delegate] bleDidChangedState:isBluetoothEnabled];
#else
    [self isLECapableHardware];
#endif
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!self.peripherals)
        self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
    else
    {
        for(int i = 0; i < self.peripherals.count; i++)
        {
            CBPeripheral *p = [self.peripherals objectAtIndex:i];
            [p bts_setAdvertisementData:advertisementData RSSI:RSSI];

            if ((p.identifier == NULL) || (peripheral.identifier == NULL))
                continue;

            if ([self UUIDSAreEqual:p.identifier UUID2:peripheral.identifier])
            {
                [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
                NSLog(@"Duplicate UUID found updating...");
                return;
            }
        }

        [self.peripherals addObject:peripheral];

        NSLog(@"New UUID, adding");
    }

    NSLog(@"didDiscoverPeripheral");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (peripheral.identifier != NULL)
        NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
    else
        NSLog(@"Connected to NULL successful");

    self.activePeripheral = peripheral;
    [self.activePeripheral discoverServices:nil];
    [self getAllServicesFromPeripheral:peripheral];
}

static bool done = false;

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error)
    {
        NSLog(@"Characteristics of service with UUID : %@ found\n",[self CBUUIDToString:service.UUID]);

        for (int i=0; i < service.characteristics.count; i++)
        {
            CBCharacteristic *c = [service.characteristics objectAtIndex:i];
            NSLog(@"Found characteristic %@\n",[ self CBUUIDToString:c.UUID]);
            CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];

            if ([service.UUID isEqual:s.UUID])
            {
                if (!done)
                {
                    [self enableReadNotification:activePeripheral];
                    [[self delegate] bleDidConnect];
                    isConnected = true;
                    done = true;
                }

                break;
            }
        }
    }
    else
    {
        NSLog(@"Characteristic discorvery unsuccessful!");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error)
    {
        // Determine if we're connected to Red Bear Labs, Adafruit or Laird hardware
        for (CBService *service in peripheral.services) {

            if ([service.UUID isEqual:redBearLabsServiceUUID]) {
                NSLog(@"RedBearLabs Bluetooth");
                serialServiceUUID = redBearLabsServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@RBL_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:adafruitServiceUUID]) {
                NSLog(@"Adafruit Bluefruit LE");
                serialServiceUUID = adafruitServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@ADAFRUIT_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@ADAFRUIT_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:lairdServiceUUID]) {
                NSLog(@"Laird BL600");
                serialServiceUUID = lairdServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@LAIRD_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@LAIRD_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:blueGigaServiceUUID]) {
                NSLog(@"BlueGiga Bluetooth");
                serialServiceUUID = blueGigaServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@BLUEGIGA_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@BLUEGIGA_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:rongtaSerivceUUID]) {
                serialServiceUUID = rongtaSerivceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@RONGTA_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@RONGTA_CHAR_RX_UUID];
            } else if ([service.UUID isEqual:posnetSerivceUUID]) {
                NSLog(@"Posnet");
                serialServiceUUID = posnetSerivceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@POSNET_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@POSNET_CHAR_RX_UUID];
            } else {
                // ignore unknown services
            }
        }

        // TODO - future versions should just get characteristics we care about
        // [peripheral discoverCharacteristics:characteristics forService:service];
        [self getAllCharacteristicsFromPeripheral:peripheral];
    }
    else
    {
        NSLog(@"Service discovery was unsuccessful!");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error)
    {
        //        printf("Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:peripheral.UUID]);
    }
    else
    {
        NSLog(@"Error in setting notification state for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
               [self CBUUIDToString:characteristic.UUID],
               [self CBUUIDToString:characteristic.service.UUID],
               peripheral.identifier.UUIDString);

        NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    static unsigned char buf[512];
    NSInteger data_len;

    if (!error)
    {
        if ([characteristic.UUID isEqual:readCharacteristicUUID])
        {
            data_len = characteristic.value.length;
            [characteristic.value getBytes:buf length:data_len];

            [[self delegate] bleDidReceiveData:buf length:data_len];
        }
    }
    else
    {
        NSLog(@"updateValueForCharacteristic failed!");
    }
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (!isConnected)
        return;

    if (rssi != peripheral.RSSI.intValue)
    {
        rssi = peripheral.RSSI.intValue;
        [[self delegate] bleDidUpdateRSSI:activePeripheral.RSSI];
    }
}

// B3 Printer method

- (void)createAndPrintImg:(NSString *)qrContent textSize:(float) textSize tdSizeSmall:(float) tdSizeSmall tdSizeMiddle:(float) tdSizeMiddle adjustTextHeight:(float) adjustTextHeight rotation:(int) rotation gotoPaper:(int) gotoPaper
                      width:(int) width height:(int) height qrSideLength:(int) qrSideLength x1:(float) x1 x2:(float) x2 x3:(float) x3 qrX:(float) qrX
                         y1:(float) y1 y2:(float) y2 y3:(float) y3 y4:(float) y4 qrY:(float) qrY name:(NSString *) name code: (NSString *) code spec:(NSString *) spec
                   material:(NSString *) material principal:(NSString *) principal supplier:(NSString *) supplier description:(NSString *) description {
    
    // make label image
    CGRect rect = CGRectMake(0, 0, width, height);
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor.whiteColor CGColor]);
    CGContextFillRect(context, rect);
    // make qrCode
    UIImage* qrCodeImg = [self createQrCode:qrContent sideLength:qrSideLength];
    // font config
    UIFont* font = [UIFont boldSystemFontOfSize:textSize];
    NSDictionary* fontAttr = @{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor blackColor]};
    // draw qrCode
    [qrCodeImg drawInRect:CGRectMake(qrX, qrY, qrCodeImg.size.width, qrCodeImg.size.height)];
    
    // draw text
    [name drawAtPoint:CGPointMake(x1, y1) withAttributes:fontAttr];
    [code drawAtPoint:CGPointMake(x2, y1) withAttributes:fontAttr];
    [spec drawAtPoint:CGPointMake(x1, y2) withAttributes:fontAttr];
    [material drawAtPoint:CGPointMake(x2, y2) withAttributes:fontAttr];
    [principal drawAtPoint:CGPointMake(x1, y3) withAttributes:fontAttr];
    [supplier drawAtPoint:CGPointMake(x2, y3) withAttributes:fontAttr];
    [description drawAtPoint:CGPointMake(x3, y4) withAttributes:fontAttr];
    
    UIImage* oriImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // perform rotation
    UIImage* rotatedImage = [self imageRotatedByDegrees:oriImage degrees:rotation];
    // get image bytes
    
    NSData * imageData = [self getImageData:rotatedImage];
    
    //write image data

    [self write:imageData];
    
    
    // write label type data
    // 0：连续纸；1：定位孔(如不支持定位孔，则调整至间隙纸)；2：间隙纸；3：黑标纸。
    if(gotoPaper ==0)
    {
        
    }
    if(gotoPaper ==1)
    {
        Byte a[2] ;
        a[0]=0x1d;a[1]=0x0c;
        NSData *adata = [[NSData alloc] initWithBytes:a length:2];
        [self write:adata];
    }
    if(gotoPaper ==2)
    {
        Byte a[2] ;
        a[0]=0x1d;a[1]=0x0c;
        NSData *adata = [[NSData alloc] initWithBytes:a length:2];
        [self write:adata];
    }
    if(gotoPaper ==3) //左黑标
    {
        Byte a[1] ;
        a[0]=0x0c;
        NSData *adata = [[NSData alloc] initWithBytes:a length:1];
        [self write:adata];
    }
    if(gotoPaper ==4) //右黑标
    {
        Byte a[1] ;
        a[0]=0x0e;
        NSData *adata = [[NSData alloc] initWithBytes:a length:1];
        [self write:adata];
    }
}

- (NSData *) getImageData:(UIImage *)image {
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    
    size_t bytesPerRow = (width - 1) / 8 + 1;
    int bytesLength = bytesPerRow * height;
    
    uint8_t imageBytes[bytesLength];
    [self cnc_getCompressedBinaryzationBytes:imageBytes reverse:YES img:image.CGImage];
    
    //NSString *begin;
    
    Byte *oriImageBuffer = (Byte*)malloc(bytesLength);
    memcpy(oriImageBuffer, imageBytes, bytesLength);
    NSData *oriImageData = [[NSData alloc] initWithBytes:oriImageBuffer length:bytesPerRow * height];
    Byte result[1024*1000];
    //Byte result[bytesLength];
    int offset=0;
    int sended=0;
    while(sended<bytesPerRow * height)
    {
        Byte b[4]={0x1f,0x10,bytesPerRow%256,bytesPerRow/256};
        //[self addData:b length:4];
        memcpy(result + offset, b, 4);
        offset += 4;
        NSData *d = [oriImageData subdataWithRange:NSMakeRange(sended, bytesPerRow)];
        memcpy(result + offset, [d bytes], [d length]);
        offset += [d length];
    }
    
    NSData *data;
    data = [[NSData alloc]initWithBytes:result length:offset];
    
    NSData *dataDeflate = [self gzipData:data];
    
    return dataDeflate;
}

- (UIImage *)createQrCode:(NSString *)qrContent sideLength:(int) sideLength {
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [qrContent dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    CIImage *image = [filter outputImage];
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(sideLength/CGRectGetWidth(extent), sideLength/CGRectGetHeight(extent));
    
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImg = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImg);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImg);
    return [UIImage imageWithCGImage:scaledImage];
}

- (UIImage *)imageRotatedByDegrees:(UIImage *)image degrees:(CGFloat)degrees {
    CGFloat radians = degrees * (M_PI / 180.0);
    
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0, image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 1);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);
    
    CGContextRotateCTM(bitmap, radians);
    
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2 , image.size.width, image.size.height), image.CGImage );
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

//压缩
- (NSData*) gzipData: (NSData*)pUncompressedData
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
    //Byte s[(4+byteWidth)*height];
    //NSString * string;
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
    //Byte s[(4+byteWidth)*height];
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
@end

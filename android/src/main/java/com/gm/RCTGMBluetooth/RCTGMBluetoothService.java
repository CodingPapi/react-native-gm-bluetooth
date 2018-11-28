package com.gm.RCTGMBluetooth;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.util.Log;

import com.google.zxing.BarcodeFormat;
import com.journeyapps.barcodescanner.BarcodeEncoder;

import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.zip.CRC32;
import java.util.zip.GZIPOutputStream;

import static com.gm.RCTGMBluetooth.RCTGMBluetoothPackage.TAG;

/**
 * This class does all the work for setting up and managing Bluetooth
 * connections with other devices. It has a thread that listens for
 * incoming connections, a thread for connecting with a device, and a
 * thread for performing data transmissions when connected.
 *
 * This code was based on the Android SDK BluetoothChat Sample
 * $ANDROID_SDK/samples/android-17/BluetoothChat
 */
class RCTGMBluetoothService {
    // Debugging
    private static final boolean D = true;

    // UUIDs
    private static final UUID UUID_SPP = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

    // Member fields
    private BluetoothAdapter mAdapter;
    private ConnectThread mConnectThread;
    private ConnectedThread mConnectedThread;
    private RCTGMBluetoothModule mModule;
    private String mState;

    // Constants that indicate the current connection state
    private static final String STATE_NONE = "none";       // we're doing nothing
    private static final String STATE_CONNECTING = "connecting"; // now initiating an outgoing connection
    private static final String STATE_CONNECTED = "connected";  // now connected to a remote device

    /**
     * Constructor. Prepares a new RCTGMBluetoothModule session.
     * @param module Module which handles service events
     */
    RCTGMBluetoothService(RCTGMBluetoothModule module) {
        mAdapter = BluetoothAdapter.getDefaultAdapter();
        mState = STATE_NONE;
        mModule = module;
    }

    /********************************************/
    /** Methods available within whole package **/
    /********************************************/

    /**
     * Start the ConnectThread to initiate a connection to a remote device.
     * @param device  The BluetoothDevice to connect
     */
    synchronized void connect(BluetoothDevice device) {
        if (D) Log.d(TAG, "connect to: " + device);

        if (mState.equals(STATE_CONNECTING)) {
            cancelConnectThread(); // Cancel any thread attempting to make a connection
        }

        cancelConnectedThread(); // Cancel any thread currently running a connection

        // Start the thread to connect with the given device
        mConnectThread = new ConnectThread(device);
        mConnectThread.start();
        setState(STATE_CONNECTING);
    }

    /**
     * Check whether service is connected to device
     * @return Is connected to device
     */
    boolean isConnected () {
        return getState().equals(STATE_CONNECTED);
    }

    /**
     * Write to the ConnectedThread in an unsynchronized manner
     * @param out The bytes to write
     * @see ConnectedThread#write(byte[])
     */
    void write(byte[] out) {
        if (D) Log.d(TAG, "Write in service, state is " + STATE_CONNECTED);
        ConnectedThread r; // Create temporary object

        // Synchronize a copy of the ConnectedThread
        synchronized (this) {
            if (!isConnected()) return;
            r = mConnectedThread;
        }

        r.write(out); // Perform the write unsynchronized
    }

    /**
     * Stop all threads
     */
    synchronized void stop() {
        if (D) Log.d(TAG, "stop");

        cancelConnectThread();
        cancelConnectedThread();

        setState(STATE_NONE);
    }

    /*********************/
    /** B3 Printer methods **/
    /*********************/

    void createThenPrint(String qrContent, float textSize, int rotation, int gotoPaper,
                                 int width, int height, int qrSideLength,
                                 float x1, float x2, float x3, float qrX,
                                 float y1, float y2, float y3, float y4, float qrY,
                                 String name, String code, String spec, String material,
                                 String principal, String supplier, String description) {

        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
        Canvas canvas = new Canvas(bitmap);
        Paint paint = new Paint();
        paint.setColor(Color.BLACK);
        paint.setTextSize(textSize);
        paint.setTextAlign(Paint.Align.LEFT);
        paint.setStrokeWidth(1.0f);
        canvas.drawColor(Color.WHITE);

        // first stage, generate QRCode
        // second stage, draw QRCode and text onto bitmap
        // third stage, send bitmap object to printer
        Bitmap qrCode = null;
        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            qrCode = barcodeEncoder.encodeBitmap(qrContent, BarcodeFormat.QR_CODE, qrSideLength, qrSideLength);
        } catch (Exception e) {

        }

        if (qrCode != null) {
            canvas.drawBitmap(qrCode, qrX, qrY, paint);
        }

        canvas.drawText(name, x1, y1, paint);
        canvas.drawText(spec, x1, y2, paint);
        canvas.drawText(principal, x1, y3, paint);
        canvas.drawText(code, x2, y1, paint);
        canvas.drawText(material, x2, y2, paint);
        canvas.drawText(supplier, x2, y3, paint);
        canvas.drawText(description, x3, y4, paint);

        int labelWidth = 0;
        int labelHeight = 0;
        if (rotation == 90 || rotation == 270) {
            labelWidth = bitmap.getHeight();
            labelHeight = bitmap.getWidth();
        } else {
            labelWidth = bitmap.getWidth();
            labelHeight = bitmap.getHeight();
        }

        labelHeight = labelHeight > 600 ? 600 : labelHeight;

        Matrix matrix = new Matrix();
        matrix.postRotate(rotation);
        Bitmap rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
        bitmap.recycle();

        performPrint(rotatedBitmap, gotoPaper);

    }

    private performPrint(Bitmap bitmap, int gotoPaper) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();

//        if (width > PrinterDotWidth) {
//            width = PrinterDotWidth;
//        }

        int len = (width + 7) / 8;
        byte[] data = new byte[(len + 4) * height];
        int ndata = 0;
        int[] RowData = new int[width * height];
        bitmap.getPixels(RowData, 0, width, 0, 0, width, height);

        for (int i = 0; i < height; ++i) {
            data[ndata + 0] = 31;
            data[ndata + 1] = 16;
            data[ndata + 2] = (byte) (len % 256);
            data[ndata + 3] = (byte) (len / 256);

            for (int j = 0; j < len; ++j) {
                data[ndata + 4 + j] = 0;
            }

            int size;
            for (int j = 0; j < width; ++j) {
                size = RowData[i * width + j];
                int b = size >> 0 & 255;
                int g = size >> 8 & 255;
                int r = size >> 16 & 255;
                int grey = (r + g + b) / 3;
                if (grey < 128) {
                    data[ndata + 4 + j / 8] |= (byte) (128 >> j % 8);
                }
            }

            for (size = len - 1; size >= 0 && data[ndata + 4 + size] == 0; --size) {
                ;
            }

            ++size;
            data[ndata + 2] = (byte) (len % 256);
            data[ndata + 3] = (byte) (len / 256);
            ndata += 4 + len;
        }

        data = codec(data, ndata);
        write(data);

        if (gotoPaper == 1) {
            write(new byte[]{29, 12});
        }

        if (gotoPaper == 2) {
            write(new byte[]{14});
        }

        if (gotoPaper == 3) {
            write(new byte[]{12});
        }

        if (gotoPaper == 4) {
            write(new byte[]{29, 12});
        }
    }

    private byte[] codec(byte[] data, int len) {
        byte[] gzipData = (byte[]) null;
        ByteArrayOutputStream gzipStram = new ByteArrayOutputStream();

        try {
            GZIPOutputStream zos = new GZIPOutputStream(new BufferedOutputStream(gzipStram));
            zos.write(data);
            zos.close();
        } catch (IOException var9) {
            var9.printStackTrace();
            mModule.onError(var9);
        }

        gzipData = gzipStram.toByteArray();
        long length = (long) gzipData.length;
        CRC32 crc32 = new CRC32();
        crc32.update(gzipData, 8, (int) (length - 8L - 4L));
        long crc = crc32.getValue();
        gzipData[4] = (byte) ((int) (length >> 0 & 255L));
        gzipData[5] = (byte) ((int) (length >> 8 & 255L));
        gzipData[6] = (byte) ((int) (length >> 16 & 255L));
        gzipData[7] = (byte) ((int) (length >> 24 & 255L));
        gzipData[gzipData.length - 4] = (byte) ((int) (crc >> 0 & 255L));
        gzipData[gzipData.length - 3] = (byte) ((int) (crc >> 8 & 255L));
        gzipData[gzipData.length - 2] = (byte) ((int) (crc >> 16 & 255L));
        gzipData[gzipData.length - 1] = (byte) ((int) (crc >> 24 & 255L));
        return gzipData;
    }



    /*********************/
    /** Private methods **/
    /*********************/

    /**
     * Return the current connection state.
     */
    private synchronized String getState() {
        return mState;
    }

    /**
     * Set the current state of connection
     * @param state  An integer defining the current connection state
     */
    private synchronized void setState(String state) {
        if (D) Log.d(TAG, "setState() " + mState + " -> " + state);
        mState = state;
    }

    /**
     * Start the ConnectedThread to begin managing a Bluetooth connection
     * @param socket  The BluetoothSocket on which the connection was made
     * @param device  The BluetoothDevice that has been connected
     */
    private synchronized void connectionSuccess(BluetoothSocket socket, BluetoothDevice device) {
        if (D) Log.d(TAG, "connected");

        cancelConnectThread(); // Cancel any thread attempting to make a connection
        cancelConnectedThread(); // Cancel any thread currently running a connection

        // Start the thread to manage the connection and perform transmissions
        mConnectedThread = new ConnectedThread(socket);
        mConnectedThread.start();

        mModule.onConnectionSuccess("Connected to " + device.getName());
        setState(STATE_CONNECTED);
    }


    /**
     * Indicate that the connection attempt failed and notify the UI Activity.
     */
    private void connectionFailed() {
        mModule.onConnectionFailed("Unable to connect to device"); // Send a failure message
        RCTGMBluetoothService.this.stop(); // Start the service over to restart listening mode
    }

    /**
     * Indicate that the connection was lost and notify the UI Activity.
     */
    private void connectionLost() {
        mModule.onConnectionLost("Device connection was lost");  // Send a failure message
        RCTGMBluetoothService.this.stop(); // Start the service over to restart listening mode
    }

    /**
     * Cancel connect thread
     */
    private void cancelConnectThread () {
        if (mConnectThread != null) {
            mConnectThread.cancel();
            mConnectThread = null;
        }
    }

    /**
     * Cancel connected thread
     */
    private void cancelConnectedThread () {
        if (mConnectedThread != null) {
            mConnectedThread.cancel();
            mConnectedThread = null;
        }
    }

    /**
     * This thread runs while attempting to make an outgoing connection
     * with a device. It runs straight through; the connection either
     * succeeds or fails.
     */
    private class ConnectThread extends Thread {
        private BluetoothSocket mmSocket;
        private final BluetoothDevice mmDevice;

        ConnectThread(BluetoothDevice device) {
            mmDevice = device;
            BluetoothSocket tmp = null;

            // Get a BluetoothSocket for a connection with the given BluetoothDevice
            try {
                tmp = device.createRfcommSocketToServiceRecord(UUID_SPP);
            } catch (Exception e) {
                mModule.onError(e);
                Log.e(TAG, "Socket create() failed", e);
            }
            mmSocket = tmp;
        }

        public void run() {
            if (D) Log.d(TAG, "BEGIN mConnectThread");
            setName("ConnectThread");

            // Always cancel discovery because it will slow down a connection
            mAdapter.cancelDiscovery();

            // Make a connection to the BluetoothSocket
            try {
                // This is a blocking call and will only return on a successful connection or an exception
                if (D) Log.d(TAG,"Connecting to socket...");
                mmSocket.connect();
                if (D) Log.d(TAG,"Connected");
            } catch (Exception e) {
                Log.e(TAG, e.toString());
                mModule.onError(e);

                // Some 4.1 devices have problems, try an alternative way to connect
                try {
                    Log.i(TAG,"Trying fallback...");
                    mmSocket = (BluetoothSocket) mmDevice.getClass().getMethod("createRfcommSocket", new Class[] {int.class}).invoke(mmDevice,1);
                    mmSocket.connect();
                    Log.i(TAG,"Connected");
                } catch (Exception e2) {
                    Log.e(TAG, "Couldn't establish a Bluetooth connection.");
                    mModule.onError(e2);
                    try {
                        mmSocket.close();
                    } catch (Exception e3) {
                        Log.e(TAG, "unable to close() socket during connection failure", e3);
                        mModule.onError(e3);
                    }
                    connectionFailed();
                    return;
                }
            }

            // Reset the ConnectThread because we're done
            synchronized (RCTGMBluetoothService.this) {
                mConnectThread = null;
            }

            connectionSuccess(mmSocket, mmDevice);  // Start the connected thread

        }

        void cancel() {
            try {
                mmSocket.close();
            } catch (Exception e) {
                Log.e(TAG, "close() of connect socket failed", e);
                mModule.onError(e);
            }
        }
    }

    /**
     * This thread runs during a connection with a remote device.
     * It handles all incoming and outgoing transmissions.
     */
    private class ConnectedThread extends Thread {
        private final BluetoothSocket mmSocket;
        private final InputStream mmInStream;
        private final OutputStream mmOutStream;

        ConnectedThread(BluetoothSocket socket) {
            if (D) Log.d(TAG, "create ConnectedThread");
            mmSocket = socket;
            InputStream tmpIn = null;
            OutputStream tmpOut = null;

            // Get the BluetoothSocket input and output streams
            try {
                tmpIn = socket.getInputStream();
                tmpOut = socket.getOutputStream();
            } catch (Exception e) {
                Log.e(TAG, "temp sockets not created", e);
                mModule.onError(e);
            }

            mmInStream = tmpIn;
            mmOutStream = tmpOut;
        }

        public void run() {
            Log.i(TAG, "BEGIN mConnectedThread");
            byte[] buffer = new byte[1024];
            int bytes;

            // Keep listening to the InputStream while connected
            while (true) {
                try {
                    bytes = mmInStream.read(buffer); // Read from the InputStream
                    String data = new String(buffer, 0, bytes, "ISO-8859-1");

                    mModule.onData(data); // Send the new data String to the UI Activity
                } catch (Exception e) {
                    Log.e(TAG, "disconnected", e);
                    mModule.onError(e);
                    connectionLost();
                    RCTGMBluetoothService.this.stop(); // Start the service over to restart listening mode
                    break;
                }
            }
        }

        /**
         * Write to the connected OutStream.
         * @param buffer  The bytes to write
         */
        void write(byte[] buffer) {
            try {
                String str = new String(buffer, "UTF-8");
                if (D) Log.d(TAG, "Write in thread " + str);
                mmOutStream.write(buffer);
            } catch (Exception e) {
                Log.e(TAG, "Exception during write", e);
                mModule.onError(e);
            }
        }

        void cancel() {
            try {
                mmSocket.close();
            } catch (Exception e) {
                Log.e(TAG, "close() of connect socket failed", e);
            }
        }
    }
}

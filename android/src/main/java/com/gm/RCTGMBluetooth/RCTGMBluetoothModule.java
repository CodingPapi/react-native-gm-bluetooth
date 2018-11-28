package com.gm.RCTGMBluetooth;

import java.lang.reflect.Method;
import java.util.Set;
import javax.annotation.Nullable;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.util.Log;
import android.util.Base64;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.Promise;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import static com.gm.RCTGMBluetooth.RCTGMBluetoothPackage.TAG;

@SuppressWarnings("unused")
public class RCTGMBluetoothModule extends ReactContextBaseJavaModule implements ActivityEventListener, LifecycleEventListener {

    // Debugging
    private static final boolean D = true;

    // Event names
    private static final String BT_ENABLED = "bluetoothEnabled";
    private static final String BT_DISABLED = "bluetoothDisabled";
    private static final String CONN_SUCCESS = "connectionSuccess";
    private static final String CONN_FAILED = "connectionFailed";
    private static final String CONN_LOST = "connectionLost";
    private static final String DEVICE_READ = "read";
    private static final String ERROR = "error";

    // Other stuff
    private static final int REQUEST_ENABLE_BLUETOOTH = 1;
    private static final int REQUEST_PAIR_DEVICE = 2;
    // Members
    private BluetoothAdapter mBluetoothAdapter;
    private RCTGMBluetoothService mBluetoothService;
    private ReactApplicationContext mReactContext;

    private StringBuffer mBuffer = new StringBuffer();

    // Promises
    private Promise mEnabledPromise;
    private Promise mConnectedPromise;
    private Promise mDeviceDiscoveryPromise;
    private Promise mPairDevicePromise;
    private String delimiter = "";

    public RCTGMBluetoothModule(ReactApplicationContext reactContext) {
        super(reactContext);

        if (D) Log.d(TAG, "Bluetooth module started");

        mReactContext = reactContext;

        if (mBluetoothAdapter == null) {
            mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        }

        if (mBluetoothService == null) {
            mBluetoothService = new RCTGMBluetoothService(this);
        }

        if (mBluetoothAdapter != null && mBluetoothAdapter.isEnabled()) {
            sendEvent(BT_ENABLED, null);
        } else {
            sendEvent(BT_DISABLED, null);
        }

        mReactContext.addActivityEventListener(this);
        mReactContext.addLifecycleEventListener(this);
        registerBluetoothStateReceiver();
    }

    @Override
    public String getName() {
        return "RCTGMBluetooth";
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent intent) {
        if (D) Log.d(TAG, "On activity result request: " + requestCode + ", result: " + resultCode);
        if (requestCode == REQUEST_ENABLE_BLUETOOTH) {
            if (resultCode == Activity.RESULT_OK) {
                if (D) Log.d(TAG, "User enabled Bluetooth");
                if (mEnabledPromise != null) {
                    mEnabledPromise.resolve(true);
                }
            } else {
                if (D) Log.d(TAG, "User did *NOT* enable Bluetooth");
                if (mEnabledPromise != null) {
                    mEnabledPromise.reject(new Exception("User did not enable Bluetooth"));
                }
            }
            mEnabledPromise = null;
        }

        if (requestCode == REQUEST_PAIR_DEVICE) {
            if (resultCode == Activity.RESULT_OK) {
                if (D) Log.d(TAG, "Pairing ok");
            } else {
                if (D) Log.d(TAG, "Pairing failed");
            }
        }
    }

    @Override
    public void onNewIntent(Intent intent) {
        if (D) Log.d(TAG, "On new intent");
    }


    @Override
    public void onHostResume() {
        if (D) Log.d(TAG, "Host resume");
    }

    @Override
    public void onHostPause() {
        if (D) Log.d(TAG, "Host pause");
    }

    @Override
    public void onHostDestroy() {
        if (D) Log.d(TAG, "Host destroy");
        mBluetoothService.stop();
    }

    @Override
    public void onCatalystInstanceDestroy() {
        if (D) Log.d(TAG, "Catalyst instance destroyed");
        super.onCatalystInstanceDestroy();
        mBluetoothService.stop();
    }

    /*******************************/
    /** Methods Available from JS **/
    /*******************************/

    /*************************************/
    /** Bluetooth state related methods **/

    @ReactMethod
    /**
     * Request user to enable bluetooth
     */
    public void requestEnable(Promise promise) {
        // If bluetooth is already enabled resolve promise immediately
        if (mBluetoothAdapter != null && mBluetoothAdapter.isEnabled()) {
            promise.resolve(true);
        // Start new intent if bluetooth is note enabled
        } else {
            Activity activity = getCurrentActivity();
            mEnabledPromise = promise;
            Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            if (activity != null) {
                activity.startActivityForResult(intent, REQUEST_ENABLE_BLUETOOTH);
            } else {
                Exception e = new Exception("Cannot start activity");
                Log.e(TAG, "Cannot start activity", e);
                mEnabledPromise.reject(e);
                mEnabledPromise = null;
                onError(e);
            }
        }
    }

    @ReactMethod
    /**
     * Enable bluetooth
     */
    public void enable(Promise promise) {
        if (mBluetoothAdapter != null && !mBluetoothAdapter.isEnabled()) {
            mBluetoothAdapter.enable();
        }
        promise.resolve(true);
    }

    @ReactMethod
    /**
     * Disable bluetooth
     */
    public void disable(Promise promise) {
        if (mBluetoothAdapter != null && mBluetoothAdapter.isEnabled()) {
            mBluetoothAdapter.disable();
        }
        promise.resolve(true);
    }

    @ReactMethod
    /**
     * Check if bluetooth is enabled
     */
    public void isEnabled(Promise promise) {
        if (mBluetoothAdapter != null) {
            promise.resolve(mBluetoothAdapter.isEnabled());
        } else {
            promise.resolve(false);
        }
    }

    @ReactMethod
    public void withDelimiter(String delimiter, Promise promise) {
        this.delimiter = delimiter;
        promise.resolve(true);
    }

    /**************************************/
    /** Bluetooth device related methods **/

    @ReactMethod
    /**
     * List paired bluetooth devices
     */
    public void list(Promise promise) {
        WritableArray deviceList = Arguments.createArray();
        if (mBluetoothAdapter != null) {
            Set<BluetoothDevice> bondedDevices = mBluetoothAdapter.getBondedDevices();

            for (BluetoothDevice rawDevice : bondedDevices) {
                WritableMap device = deviceToWritableMap(rawDevice);
                deviceList.pushMap(device);
            }
        }
        promise.resolve(deviceList);
    }

    @ReactMethod
    /**
     * Discover unpaired bluetooth devices
     */
    public void discoverUnpairedDevices(final Promise promise) {
        if (D) Log.d(TAG, "Discover unpaired called");

        mDeviceDiscoveryPromise = promise;
        registerBluetoothDeviceDiscoveryReceiver();

        if (mBluetoothAdapter != null) {
            mBluetoothAdapter.startDiscovery();
        } else {
            promise.resolve(Arguments.createArray());
        }
    }

    @ReactMethod
    /**
     * Cancel discovery
     */
    public void cancelDiscovery(final Promise promise) {
        if (D) Log.d(TAG, "Cancel discovery called");

        if (mBluetoothAdapter != null) {
            if (mBluetoothAdapter.isDiscovering()) {
                mBluetoothAdapter.cancelDiscovery();
            }
        }
        promise.resolve(true);
    }


    @ReactMethod
    /**
     * Pair device
     */
    public void pairDevice(String id, Promise promise) {
        if (D) Log.d(TAG, "Pair device: " + id);

        if (mBluetoothAdapter != null) {
            mPairDevicePromise = promise;
            BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(id);
            if (device != null) {
                pairDevice(device);
            } else {
                mPairDevicePromise.reject(new Exception("Could not pair device " + id));
                mPairDevicePromise = null;
            }
        } else {
            promise.resolve(false);
        }
    }

    @ReactMethod
    /**
     * Unpair device
     */
    public void unpairDevice(String id, Promise promise) {
        if (D) Log.d(TAG, "Unpair device: " + id);

        if (mBluetoothAdapter != null) {
            mPairDevicePromise = promise;
            BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(id);
            if (device != null) {
                unpairDevice(device);
            } else {
                mPairDevicePromise.reject(new Exception("Could not unpair device " + id));
                mPairDevicePromise = null;
            }
        } else {
            promise.resolve(false);
        }
    }

    /********************************/
    /** Connection related methods **/

    @ReactMethod
    /**
     * Connect to device by id
     */
    public void connect(String id, Promise promise) {
        mConnectedPromise = promise;
        if (mBluetoothAdapter != null) {
            BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(id);
            if (device != null) {
                mBluetoothService.connect(device);
            } else {
                promise.reject(new Exception("Could not connect to " + id));
            }
        } else {
            promise.resolve(true);
        }
    }

    @ReactMethod
    /**
     * Disconnect from device
     */
    public void disconnect(Promise promise) {
        mBluetoothService.stop();
        promise.resolve(true);
    }

    @ReactMethod
    /**
     * Check if device is connected
     */
    public void isConnected(Promise promise) {
        promise.resolve(mBluetoothService.isConnected());
    }

    /*********************/
    /** Write to device **/

    @ReactMethod
    /**
     * Write to device over serial port
     */
    public void writeToDevice(String message, Promise promise) {
        if (D) Log.d(TAG, "Write " + message);
        byte[] data = Base64.decode(message, Base64.DEFAULT);
        mBluetoothService.write(data);
        promise.resolve(true);
    }

    @ReactMethod
    public void writeHexToDevice(String hexString, Promise promise){
        mBluetoothService.write(hexStringToBytes(hexString));
        promise.resolve(true);
    }

    @ReactMethod
    public void writeTextToDevice(String Text, Promise promise){
        byte[] send;
        try {
            send = Text.getBytes("GB2312");
        } catch (Exception e) {
            send = Text.getBytes();
        }
        mBluetoothService.write(send);
        promise.resolve(true);
    }

    /**********************/
    /** Read from device **/

    @ReactMethod
    /**
     * Read from device over serial port
     */
    public void readFromDevice(Promise promise) {
        if (D) Log.d(TAG, "Read");
        int length = mBuffer.length();
        String data = mBuffer.substring(0, length);
        mBuffer.delete(0, length);
        promise.resolve(data);
    }

    @ReactMethod
    public void readUntilDelimiter(String delimiter, Promise promise) {
        promise.resolve(readUntil(delimiter));
    }


    /***********/
    /** Other **/

    @ReactMethod
    /**
     * Clear data in buffer
     */
    public void clear(Promise promise) {
        mBuffer.setLength(0);
        promise.resolve(true);
    }

    @ReactMethod
    /**
     * Get length of data available to read
     */
    public void available(Promise promise) {
        promise.resolve(mBuffer.length());
    }


    @ReactMethod
    /**
     * Set bluetooth adapter name
     */
    public void setAdapterName(String newName, Promise promise) {
        if (mBluetoothAdapter != null) {
            mBluetoothAdapter.setName(newName);
        }
        promise.resolve(true);
    }

    @ReactMethod
    /**
     * Print by B3 bluetooth printer
     */
    public void b3Print(ReadableMap info, Promise promise) {
        if (D) Log.d(TAG, "b3Print " + info.toString());

        String qrContent = options.hasKey("qrContent") ? options.getString("qrContent") : "";
        double textSize = options.hasKey("textSize") ? options.getDouble("textSize") : 16D;
        int rotation = options.hasKey("rotation") ? options.getInt("rotation") : 0;
        int gotoPaper = options.hasKey("gotoPaper") ? options.getInt("gotoPaper") : 1;
        int width = options.hasKey("width") ? options.getInt("width") : 480;
        int height = options.hasKey("height") ? options.getInt("height") : 240;
        int qrSideLength = options.hasKey("qrSideLength") ? options.getInt("qrSideLength") : 150;
        double x1 = options.hasKey("x1") ? options.getDouble("x1") : 0;
        double x2 = options.hasKey("x2") ? options.getDouble("x2") : 0;
        double x3 = options.hasKey("x3") ? options.getDouble("x3") : 0;
        double qrX = options.hasKey("qrX") ? options.getDouble("qrX") : 0;
        double y1 = options.hasKey("y1") ? options.getDouble("y1") : 0;
        double y2 = options.hasKey("y2") ? options.getDouble("y2") : 0;
        double y3 = options.hasKey("y3") ? options.getDouble("y3") : 0;
        double y4 = options.hasKey("y4") ? options.getDouble("y4") : 0;
        double qrY = options.hasKey("qrY") ? options.getDouble("qrY") : 0;
        String name = options.hasKey("name") ? options.getString("name") : "";
        String code = options.hasKey("code") ? options.getString("code") : "";
        String spec = options.hasKey("spec") ? options.getString("spec") : "";
        String material = options.hasKey("material") ? options.getString("material") : "";
        String principal = options.hasKey("principal") ? options.getString("principal") : "";
        String supplier = options.hasKey("supplier") ? options.getString("supplier") : "";
        String description = options.hasKey("description") ? options.getString("description") : "";

        mBluetoothService.createThenPrint(qrContent, textSize, rotation, gotoPaper, width, height, qrSideLength,
                x1, x2, x3, qrX, y1, y2, y3, y4, qrY, name, code, spec, material, principal, supplier, description);
        promise.resolve(true);
    }

    /****************************************/
    /** Methods available to whole package **/
    /****************************************/

    /**
     * Handle connection success
     * @param msg Additional message
     */
    void onConnectionSuccess(String msg) {
        WritableMap params = Arguments.createMap();
        params.putString("message", msg);
        sendEvent(CONN_SUCCESS, null);
        if (mConnectedPromise != null) {
            mConnectedPromise.resolve(params);
        }
        mConnectedPromise = null;
    }

    /**
     * handle connection failure
     * @param msg Additional message
     */
    void onConnectionFailed(String msg) {
        WritableMap params = Arguments.createMap();
        params.putString("message", msg);
        sendEvent(CONN_FAILED, null);
        if (mConnectedPromise != null) {
            mConnectedPromise.reject(new Exception(msg));
        }
        mConnectedPromise = null;
    }

    /**
     * Handle lost connection
     * @param msg Message
     */
    void onConnectionLost (String msg) {
        WritableMap params = Arguments.createMap();
        params.putString("message", msg);
        sendEvent(CONN_LOST, params);
    }

    /**
     * Handle error
     * @param e Exception
     */
    void onError (Exception e) {
        WritableMap params = Arguments.createMap();
        params.putString("message", e.getMessage());
        sendEvent(ERROR, params);
    }

    /**
     * Handle read
     * @param data Message
     */
    void onData (String data) {
        mBuffer.append(data);
        String completeData = readUntil(this.delimiter);
        if (completeData != null && completeData.length() > 0) {
            WritableMap params = Arguments.createMap();
            params.putString("data", completeData);
            sendEvent(DEVICE_READ, params);
        }
    }

    private String readUntil(String delimiter) {
        String data = "";
        int index = mBuffer.indexOf(delimiter, 0);
        if (index > -1) {
            data = mBuffer.substring(0, index + delimiter.length());
            mBuffer.delete(0, index + delimiter.length());
        }
        return data;
    }

    /*********************/
    /** Private methods **/
    /*********************/

    /**
     * Check if is api level 19 or above
     * @return is above api level 19
     */
    private boolean isKitKatOrAbove () {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;
    }

    /**
     * Send event to javascript
     * @param eventName Name of the event
     * @param params Additional params
     */
    private void sendEvent(String eventName, @Nullable WritableMap params) {
        if (mReactContext.hasActiveCatalystInstance()) {
            if (D) Log.d(TAG, "Sending event: " + eventName);
            mReactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
        }
    }

    /**
     * Convert BluetoothDevice into WritableMap
     * @param device Bluetooth device
     */
    private WritableMap deviceToWritableMap(BluetoothDevice device) {
        if (D) Log.d(TAG, "device" + device.toString());

        WritableMap params = Arguments.createMap();

        params.putString("name", device.getName());
        params.putString("address", device.getAddress());
        params.putString("id", device.getAddress());

        if (device.getBluetoothClass() != null) {
            params.putInt("class", device.getBluetoothClass().getDeviceClass());
        }

        return params;
    }

    /**
     * Pair device before kitkat
     * @param device Device
     */
    private void pairDevice(BluetoothDevice device) {
        try {
            if (D) Log.d(TAG, "Start Pairing...");
            Method m = device.getClass().getMethod("createBond", (Class[]) null);
            m.invoke(device, (Object[]) null);
            registerDevicePairingReceiver(device.getAddress(), BluetoothDevice.BOND_BONDED);
            if (D) Log.d(TAG, "Pairing finished.");
        } catch (Exception e) {
            Log.e(TAG, "Cannot pair device", e);
            if (mPairDevicePromise != null) {
                mPairDevicePromise.reject(e);
                mPairDevicePromise = null;
            }
            onError(e);
        }
    }

    /**
     * Unpair device
     * @param device Device
     */
    private void unpairDevice(BluetoothDevice device) {
        try {
            if (D) Log.d(TAG, "Start Unpairing...");
            Method m = device.getClass().getMethod("removeBond", (Class[]) null);
            m.invoke(device, (Object[]) null);
            registerDevicePairingReceiver(device.getAddress(), BluetoothDevice.BOND_NONE);
        } catch (Exception e) {
            Log.e(TAG, "Cannot unpair device", e);
            if (mPairDevicePromise != null) {
                mPairDevicePromise.reject(e);
                mPairDevicePromise = null;
            }
            onError(e);
        }
    }

    /**
     * Register receiver for device pairing
     * @param deviceId Id of device
     * @param requiredState State that we require
     */
    private void registerDevicePairingReceiver(final String deviceId, final int requiredState) {
        IntentFilter intentFilter = new IntentFilter();

        intentFilter.addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED);

        final BroadcastReceiver devicePairingReceiver = new BroadcastReceiver() {
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();

                if (BluetoothDevice.ACTION_BOND_STATE_CHANGED.equals(action)) {
                    final int state = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.ERROR);
                    final int prevState	= intent.getIntExtra(BluetoothDevice.EXTRA_PREVIOUS_BOND_STATE, BluetoothDevice.ERROR);

                    if (state == BluetoothDevice.BOND_BONDED && prevState == BluetoothDevice.BOND_BONDING) {
                        if (D) Log.d(TAG, "Device paired");
                        if (mPairDevicePromise != null) {
                            mPairDevicePromise.resolve(true);
                            mPairDevicePromise = null;
                        }
                        try {
                            mReactContext.unregisterReceiver(this);
                        } catch (Exception e) {
                            Log.e(TAG, "Cannot unregister receiver", e);
                            onError(e);
                        }
                    } else if (state == BluetoothDevice.BOND_NONE && prevState == BluetoothDevice.BOND_BONDED){
                        if (D) Log.d(TAG, "Device unpaired");
                        if (mPairDevicePromise != null) {
                            mPairDevicePromise.resolve(true);
                            mPairDevicePromise = null;
                        }
                        try {
                            mReactContext.unregisterReceiver(this);
                        } catch (Exception e) {
                            Log.e(TAG, "Cannot unregister receiver", e);
                            onError(e);
                        }
                    }

                }
            }
        };

        mReactContext.registerReceiver(devicePairingReceiver, intentFilter);
    }

    /**
     * Register receiver for bluetooth device discovery
     */
    private void registerBluetoothDeviceDiscoveryReceiver() {
        IntentFilter intentFilter = new IntentFilter();

        intentFilter.addAction(BluetoothDevice.ACTION_FOUND);
        intentFilter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);

        final BroadcastReceiver deviceDiscoveryReceiver = new BroadcastReceiver() {
            private WritableArray unpairedDevices = Arguments.createArray();
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (D) Log.d(TAG, "onReceive called");

                if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    WritableMap d = deviceToWritableMap(device);
                    unpairedDevices.pushMap(d);
                } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                    if (D) Log.d(TAG, "Discovery finished");
                    if (mDeviceDiscoveryPromise != null) {
                        mDeviceDiscoveryPromise.resolve(unpairedDevices);
                        mDeviceDiscoveryPromise = null;
                    }

                    try {
                        mReactContext.unregisterReceiver(this);
                    } catch (Exception e) {
                        Log.e(TAG, "Unable to unregister receiver", e);
                        onError(e);
                    }
                }
            }
        };

        mReactContext.registerReceiver(deviceDiscoveryReceiver, intentFilter);
    }

    /**
     * Register receiver for bluetooth state change
     */
    private void registerBluetoothStateReceiver() {
        IntentFilter intentFilter = new IntentFilter();

        intentFilter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);

        final BroadcastReceiver bluetoothStateReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                final String action = intent.getAction();

                if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
                    final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);
                    switch (state) {
                        case BluetoothAdapter.STATE_OFF:
                            if (D) Log.d(TAG, "Bluetooth was disabled");
                            sendEvent(BT_DISABLED, null);
                            break;
                        case BluetoothAdapter.STATE_ON:
                            if (D) Log.d(TAG, "Bluetooth was enabled");
                            sendEvent(BT_ENABLED, null);
                            break;
                    }
                }
            }
        };

        mReactContext.registerReceiver(bluetoothStateReceiver, intentFilter);
    }

    public static byte[] hexStringToBytes(String hexString) {
        hexString = hexString.toLowerCase();
        String[] hexStrings = hexString.split(" ");
        byte[] bytes = new byte[hexStrings.length];
        for (int i = 0; i < hexStrings.length; i++) {
            char[] hexChars = hexStrings[i].toCharArray();
            bytes[i] = (byte) (charToByte(hexChars[0]) << 4 | charToByte(hexChars[1]));
        }
        return bytes;
    }
    private static byte charToByte(char c) {
        return (byte) "0123456789abcdef".indexOf(c);
    }
}

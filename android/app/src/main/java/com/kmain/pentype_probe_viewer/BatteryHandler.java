package com.kmain.pentype_probe_viewer;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;

import generalplus.com.GPCamLib.CamWrapper;

public class BatteryHandler extends Handler {
    private final BatteryStatusCallback callback;

    public interface BatteryStatusCallback {
        void onBatteryLevelReceived(int level);
    }

    public BatteryHandler(BatteryStatusCallback callback) {
        super(Looper.getMainLooper());
        this.callback = callback;
    }

    @Override
    public void handleMessage(Message msg) {
        if (msg.what == CamWrapper.GPCALLBACKTYPE_CAMSTATUS) {
            Bundle data = msg.getData();
            int cmdId = data.getInt(CamWrapper.GPCALLBACKSTATUSTYPE_CMDID);
            byte[] payload = data.getByteArray(CamWrapper.GPCALLBACKSTATUSTYPE_DATA);

            if (cmdId == CamWrapper.GPSOCK_General_CMD_GetDeviceStatus && payload != null && payload.length > 0) {
                int batteryLevel = payload[0] & 0xFF;
                callback.onBatteryLevelReceived(batteryLevel);
            }
        }
    }
}

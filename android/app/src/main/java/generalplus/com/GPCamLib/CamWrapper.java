package generalplus.com.GPCamLib;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

import com.kmain.pentype_probe_viewer.MainActivity;

import io.flutter.plugin.common.MethodChannel;

import java.io.File;
import java.io.IOException;

public class CamWrapper {

    private final static String TAG = "CamWrapper";
    private static volatile String m_ParameterFilePath;
    private static volatile String m_ParameterFileName;
    private static volatile Handler m_NowViewHandler;
    private static volatile int m_NowViewIndex;
    private static volatile CamWrapper m_ComWrapperInstance;
    private static volatile boolean m_bNewFile;
    private static volatile boolean m_bSupportPWlength;

    public final static String DEFAULT_MAPPING_STR = "A=MOVI,avi;J=PICT,jpg;L=LOCK,avi;S=SOSO,avi";
    public final static String GP22_DEFAULT_MAPPING_STR = "A=MOVI,mov;J=PICT,jpg;L=LOCK,mov;S=SOSO,mov;V=MOVI,avi;K=LOCK,avi;O=SOSO,avi";
    public final static String STREAMING_URL = "rtsp://%s:8080/?action=stream";
    public final static String RTSP_STREAMING_URL = "rtsp://%s:8080/?action=stream";
    public final static String COMMAND_URL = "192.168.25.1";
    public final static String CamDefaulFolderName = "GoPlusCam";
    public final static String SaveFileToDevicePath = "/DCIM/Camera/";
    public final static String SaveLogFileName = "GoPlusCamCmdLog";
    public final static String ConfigFileName = "GoPlusCamConf.ini";
    public final static String ParameterFileName = "Menu.xml";
    public final static String DefaultParameterFileName = "Default_Menu.xml";
    public final static boolean bIsDefault = false;
    public final static String EventMessgae_SMS = "android.provider.Telephony.SMS_RECEIVED";
    public final static int SupportMaxLogLength = 65536;
    public final static int SupportMaxShowLogLength = 200;

    public final static int Error_ServerIsBusy = 0xFFFF;
    public final static int Error_InvalidCommand = 0xFFFE;
    public final static int Error_RequestTimeOut = 0xFFFD;
    public final static int Error_ModeError = 0xFFFC;
    public final static int Error_NoStorage = 0xFFFB;
    public final static int Error_WriteFail = 0xFFFA;
    public final static int Error_GetFileListFail = 0xFFF9;
    public final static int Error_GetThumbnailFail = 0xFFF8;
    public final static int Error_FullStorage = 0xFFF7;
    public final static int Error_NoFile = 0xFFF3;

    public final static int Error_SocketClosed = 0xFFC1;
    public final static int Error_LostConnection = 0xFFC0;

    public final static int STREAMING_PORT = 8080;
    public final static int COMMAN_PORT = 8081;

    //GP_SOCK_TYPE 2Byte
    public final static int GP_SOCK_TYPE_CMD = 0x0001;
    public final static int GP_SOCK_TYPE_ACK = 0x0002;
    public final static int GP_SOCK_TYPE_NAK = 0x0003;

    //GP_SOCK_MODE_ID 1Byte
    public final static int GPSOCK_MODE_General = 0x00;
    public final static int GPSOCK_MODE_Record = 0x01;
    public final static int GPSOCK_MODE_CapturePicture = 0x02;
    public final static int GPSOCK_MODE_Playback = 0x03;
    public final static int GPSOCK_MODE_Menu = 0x04;
    public final static int GPSOCK_MODE_Firmware = 0x05;
    public final static int GPSOCK_MODE_Firmware_CV = 0x06;
    public final static int GPSOCK_MODE_Vendor = 0xFF;

    //GP_SOCK_CMD_ID 1Byte
    public final static int GPSOCK_General_CMD_SetMode = 0x00;
    public final static int GPSOCK_General_CMD_GetDeviceStatus = 0x01;
    public final static int GPSOCK_General_CMD_GetParameterFile = 0x02;
    public final static int GPSOCK_General_CMD_Poweroff = 0x03;
    public final static int GPSOCK_General_CMD_RestartStreaming = 0x04;
    public final static int GPSOCK_General_CMD_AuthDevice = 0x05;
    public final static int GPSOCK_General_CMD_CheckMapping = 0x07;
    public final static int GPSOCK_General_CMD_GetSetPIP = 0x08;

    public final static int GPSOCK_Record_CMD_Start = 0x00;
    public final static int GPSOCK_Record_CMD_Audio = 0x01;

    public final static int GPSOCK_CapturePicture_CMD_Capture = 0x00;

    public final static int GPSOCK_Playback_CMD_Start = 0x00;
    public final static int GPSOCK_Playback_CMD_Pause = 0x01;
    public final static int GPSOCK_Playback_CMD_GetFileCount = 0x02;
    public final static int GPSOCK_Playback_CMD_GetNameList = 0x03;
    public final static int GPSOCK_Playback_CMD_GetThumbnail = 0x04;
    public final static int GPSOCK_Playback_CMD_GetRawData = 0x05;
    public final static int GPSOCK_Playback_CMD_Stop = 0x06;
    public final static int GPSOCK_Playback_CMD_GetSpecficName = 0x07;
    public final static int GPSOCK_Playback_CMD_DeleteFile = 0x08;
    public final static int GPSOCK_Playback_CMD_ERROR = 0xFF;

    public final static int GPSOCK_Menu_CMD_GetParameter = 0x00;
    public final static int GPSOCK_Menu_CMD_SetParameter = 0x01;

    public final static int GPSOCK_Vendor_CMD_Vendor = 0x00;

    public final static int GPTYPE_ConnectionStatus_Idle = 0x00;
    public final static int GPTYPE_ConnectionStatus_Connecting = 0x01;
    public final static int GPTYPE_ConnectionStatus_Connected = 0x02;
    public final static int GPTYPE_ConnectionStatus_DisConnected = 0x03;
    public final static int GPTYPE_ConnectionStatus_SocketClosed = 0x0A;

    public final static int GPDEVICEMODE_Record = 0x00;
    public final static int GPDEVICEMODE_Capture = 0x01;
    public final static int GPDEVICEMODE_Playback = 0x02;
    public final static int GPDEVICEMODE_Menu = 0x03;
    public final static int GPDEVICEMODE_USB = 0x04;

    public final static int GPBATTERTY_LEVEL0 = 0x00;
    public final static int GPBATTERTY_LEVEL1 = 0x01;
    public final static int GPBATTERTY_LEVEL2 = 0x02;
    public final static int GPBATTERTY_LEVEL3 = 0x03;
    public final static int GPBATTERTY_LEVEL4 = 0x04;
    public final static int GPBATTERTY_GHARGE = 0x05;

    public final static int GPVIEW_STREAMING = 0x00;
    public final static int GPVIEW_MENU = 0x01;
    public final static int GPVIEW_FILELIST = 0x02;

    public final static int GPCALLBACKTYPE_CAMSTATUS = 0x00;
    public final static int GPCALLBACKTYPE_CAMDATA = 0x01;

    public static final int GPFILEFLAG_AVISTREAMING = 0x01;
    public static final int GPFILEFLAG_JPGSTREAMING = 0x02;

    public static final int GPSOCK_Firmware_CMD_Download = 0x00;
    public static final int GPSOCK_Firmware_CMD_SendRawData = 0x01;
    public static final int GPSOCK_Firmware_CMD_Upgrade = 0x02;

    public final static String GPFILECALLBACKTYPE_FILEURL = "FileURL";
    public final static String GPFILECALLBACKTYPE_FILEINDEX = "FileIndex";
    public final static String GPFILECALLBACKTYPE_FILEFLAG = "FileFlag";
    public final static String GPFILECALLBACKTYPE_FILETIME = "FileTime";

    public final static String GPCALLBACKSTATUSTYPE_CMDINDEX = "CmdIndex";
    public final static String GPCALLBACKSTATUSTYPE_CMDTYPE = "CmdType";
    public final static String GPCALLBACKSTATUSTYPE_CMDMODE = "CmdMode";
    public final static String GPCALLBACKSTATUSTYPE_CMDID = "CmdID";
    public final static String GPCALLBACKSTATUSTYPE_DATASIZE = "DataSize";
    public final static String GPCALLBACKSTATUSTYPE_DATA = "Data";


    public void requestBatteryLevel() {
        new Thread(() -> {
            //Log.d(TAG, "requestBatteryLevel() 호출됨");  // ✅ 확인용 로그
            GPCamSendGetStatus();  // 네이티브 요청
        }).start();
    }

    static {
        try {
            //Log.i(TAG, "Trying to load GPCam.so ...");
            System.loadLibrary("GPCam");
        } catch (UnsatisfiedLinkError Ule) {
            //Log.e(TAG, "Cannot load GPCam.so ...");
            Ule.printStackTrace();
        } finally {
        }
    }

    public CamWrapper() {
        m_ComWrapperInstance = this;
    }

    public synchronized void SetViewHandler(Handler viewHandler, int viewIndex) {
        // Handler 유효성 검사
        if (viewHandler == null) {
            throw new IllegalArgumentException("ViewHandler must not be null.");
        }

        // ViewIndex 범위 검사 (예: 0~3 사이만 허용한다고 가정)
        if (viewIndex < 0 || viewIndex > 3) {
            throw new IllegalArgumentException("ViewIndex out of range (0~3): " + viewIndex);
        }

        m_NowViewHandler = viewHandler;
        m_NowViewIndex = viewIndex;
    }

    public static CamWrapper getComWrapperInstance() {
        return m_ComWrapperInstance;
    }

    void GPCamDataCallBack(boolean bIsWrite, int i32DataSize, byte[] pbyData) {

    }

    void GPCamStatusCallBack(int i32CMDIndex, int i32Type, int i32Mode, int i32CMDID, int i32DataSize, byte[] pbyData) {

        Log.d("CamWrapper", "StatusCallback: CMDID=" + i32CMDID + ", DataSize=" + i32DataSize);
        //Log.d("CamWrapper", "StatusCallback: CMDID=" + i32CMDID + ", DataSize=" + (i32DataSize > 2));
        //Log.d("CamWrapper", "StatusCallback: CMDID=" + i32CMDID + ", DataSize=" + (i32DataSize > 2));

        // 아래에 이 블럭 추가
        if (i32CMDID == GPSOCK_General_CMD_GetDeviceStatus) {
            if (pbyData != null && i32DataSize > 2) {
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < i32DataSize; i++) {
                    sb.append(String.format("[%d]=0x%02X ", i, pbyData[i]));
                }
                Log.d(TAG, "Battery raw data: " + sb.toString());

                int batteryRaw = pbyData[2] & 0xFF;
                int batteryLevel = batteryRaw & 0x0F;

                if (batteryLevel > GPBATTERTY_GHARGE) {
                    batteryLevel = GPBATTERTY_GHARGE;
                }

                Log.i(TAG, "🔋 배터리 레벨: " + batteryLevel);

                if (MainActivity.getInstance().getFlutterEngineInstance() != null) {
                    final int finalBatteryLevel = batteryLevel;
                    new Handler(Looper.getMainLooper()).post(() -> {
                        new MethodChannel(
                                MainActivity.getInstance().getFlutterEngineInstance().getDartExecutor().getBinaryMessenger(),
                                "battery_status_channel"
                        ).invokeMethod("onBatteryLevel", finalBatteryLevel);
                    });
                }
            } else {
                //Log.w(TAG, "⚠️ 유효하지 않은 배터리 응답, level -1 전송");

                if (MainActivity.getInstance().getFlutterEngineInstance() != null) {
                    new Handler(Looper.getMainLooper()).post(() -> {
                        new MethodChannel(
                                MainActivity.getInstance().getFlutterEngineInstance().getDartExecutor().getBinaryMessenger(),
                                "battery_status_channel"
                        ).invokeMethod("onBatteryLevel", -1);
                    });
                }
            }
        }

        if (m_NowViewHandler != null) {
            Message msg = new Message();
            msg.what = GPCALLBACKTYPE_CAMSTATUS;
            Bundle bundle = new Bundle();
            bundle.putInt(GPCALLBACKSTATUSTYPE_CMDINDEX, i32CMDIndex);
            bundle.putInt(GPCALLBACKSTATUSTYPE_CMDTYPE, i32Type);
            bundle.putInt(GPCALLBACKSTATUSTYPE_CMDMODE, i32Mode);
            bundle.putInt(GPCALLBACKSTATUSTYPE_CMDID, i32CMDID);
            bundle.putInt(GPCALLBACKSTATUSTYPE_DATASIZE, i32DataSize);
            bundle.putByteArray(GPCALLBACKSTATUSTYPE_DATA, pbyData);
            msg.setData(bundle);
            m_NowViewHandler.sendMessage(msg);
        }
	
		/*if(displayValuesHelper != null)
			displayValuesHelper.getGPCamStatus(i32CMDIndex, i32Type, i32Mode, i32CMDID, i32DataSize, pbyData);	*/
    }

    // ────────────────  메서드 (private) ────────────────
    private native int GPCamConnectToDevice(String IPAddress, int Port);

    private native void GPCamDisconnect();

    private native void GPCamSetDownloadPath(String Path);

    private native int GPCamAbort(int Index);

    private native int GPCamSendSetMode(int Mode);

    private native int GPCamSendGetSetPIP(int i32Type);

    private native int GPCamSendGetStatus();

    private native int GPCamSendGetParameterFile(String FileName);

    private native int GPCamSendPowerOff();

    private native int GPCamSendRestartStreaming();

    private native int GPCamSendRecordCmd();

    private native int GPCamSendAudioOnOff(boolean IsOn);

    private native int GPCamSendCapturePicture();

    private native int GPCamSendStartPlayback(int Index);

    private native int GPCamSendPausePlayback();

    private native int GPCamSendGetFullFileList();

    private native int GPCamSendGetFileThumbnail(int Index);

    private native int GPCamSendGetFileRawdata(int Index);

    private native int GPCamSendStopPlayback();

    private native int GPCamSetNextPlaybackFileListIndex(int Index);

    private native int GPCamSendDeleteFile(int Index);

    private native int GPCamSendGetParameter(int ID);

    private native int GPCamSendSetParameter(int ID, int Size, byte[] Data);

    private native int GPCamSendFirmwareDownload(long FileSize, long Checksum);

    private native int GPCamSendFirmwareRawData(long Size, byte[] Data);

    private native int GPCamSendFirmwareUpgrade();

    private native int GPCamSendCVFirmwareDownload(long FileSize, long Checksum);

    private native int GPCamSendCVFirmwareRawData(long Size, byte[] Data);

    private native int GPCamSendCVFirmwareUpgrade(long Area);

    private native int GPCamSendVendorCmd(byte[] Data, int Size);

    private native int GPCamGetStatus();

    private native String GPCamGetFileName(int Index);

    private native boolean GPCamGetFileTime(int Index, byte[] Time);

    private native int GPCamGetFileIndex(int Index);

    private native int GPCamGetFileSize(int Index);

    private native byte GPCamGetFileExt(int Index);

    private native byte[] GPCamGetFileExtraInfo(int Index);

    private native void GPCamClearCommandQueue();

    private native boolean GPCamSetFileNameMapping(String FileName);

    private native void GPCamCheckFileMapping();

    // ──────────────── Public 래퍼 메서드 ────────────────
    public int connectToDevice(String ip, int port) {
        if (ip == null || ip.isEmpty() || port <= 0 || port > 65535) return -1;
        return GPCamConnectToDevice(ip, port);
    }

    public void disconnect() {
        GPCamDisconnect();
    }

    public void setDownloadPath(String path) {
        if (path != null) {
            GPCamSetDownloadPath(path);
        }
    }

    public int abort(int index) {
        return GPCamAbort(index);
    }

    public int setMode(int mode) {
        return GPCamSendSetMode(mode);
    }

    public int getSetPIP(int type) {
        return GPCamSendGetSetPIP(type);
    }

    public int getStatus() {
        return GPCamSendGetStatus();
    }

    public int getParameterFile(String fileName) {
        return GPCamSendGetParameterFile(fileName);
    }

    public int powerOff() {
        return GPCamSendPowerOff();
    }

    public int restartStreaming() {
        return GPCamSendRestartStreaming();
    }

    public int recordCmd() {
        return GPCamSendRecordCmd();
    }

    public int toggleAudio(boolean isOn) {
        return GPCamSendAudioOnOff(isOn);
    }

    public int capturePicture() {
        return GPCamSendCapturePicture();
    }

    public int startPlayback(int index) {
        return GPCamSendStartPlayback(index);
    }

    public int pausePlayback() {
        return GPCamSendPausePlayback();
    }

    public int getFullFileList() {
        return GPCamSendGetFullFileList();
    }

    public int getFileThumbnail(int index) {
        return GPCamSendGetFileThumbnail(index);
    }

    public int getFileRawData(int index) {
        return GPCamSendGetFileRawdata(index);
    }

    public int stopPlayback() {
        return GPCamSendStopPlayback();
    }

    public int setNextPlaybackFileIndex(int index) {
        return GPCamSetNextPlaybackFileListIndex(index);
    }

    public int deleteFile(int index) {
        return GPCamSendDeleteFile(index);
    }

    public int getParameter(int id) {
        return GPCamSendGetParameter(id);
    }

    public int setParameter(int id, int size, byte[] data) {
        return GPCamSendSetParameter(id, size, data);
    }

    public int firmwareDownload(long fileSize, long checksum) {
        return GPCamSendFirmwareDownload(fileSize, checksum);
    }

    public int firmwareRawData(long size, byte[] data) {
        return GPCamSendFirmwareRawData(size, data);
    }

    public int firmwareUpgrade() {
        return GPCamSendFirmwareUpgrade();
    }

    public int cvFirmwareDownload(long fileSize, long checksum) {
        return GPCamSendCVFirmwareDownload(fileSize, checksum);
    }

    public int cvFirmwareRawData(long size, byte[] data) {
        return GPCamSendCVFirmwareRawData(size, data);
    }

    public int cvFirmwareUpgrade(long area) {
        return GPCamSendCVFirmwareUpgrade(area);
    }

    public int sendVendorCommand(byte[] data, int size) {
        return GPCamSendVendorCmd(data, size);
    }

    public int getFileStatus() {
        return GPCamGetStatus();
    }

    public String getFileName(int index) {
        return GPCamGetFileName(index);
    }

    public boolean getFileTime(int index, byte[] time) {
        return GPCamGetFileTime(index, time);
    }

    public int getFileIndex(int index) {
        return GPCamGetFileIndex(index);
    }

    public int getFileSize(int index) {
        return GPCamGetFileSize(index);
    }

    public byte getFileExt(int index) {
        return GPCamGetFileExt(index);
    }

    public byte[] getFileExtraInfo(int index) {
        return GPCamGetFileExtraInfo(index);
    }

    public void clearCommandQueue() {
        GPCamClearCommandQueue();
    }

    public boolean setFileNameMapping(String name) {
        return GPCamSetFileNameMapping(name);
    }
    public void SetGPCamSetDownloadPath(String filePath) {
        // 1. null, 빈 문자열 체크
        if (filePath == null || filePath.trim().isEmpty()) {
            throw new IllegalArgumentException("File path must not be null or empty.");
        }

        // 2. 경로 정규화 및 안전한 디렉토리 검사 (예: /app/safe/download)
        try {
            File baseDir = new File("/app/safe/download"); // 안전한 루트 디렉토리
            File target = new File(filePath);
            String canonicalBase = baseDir.getCanonicalPath();
            String canonicalTarget = target.getCanonicalPath();

            if (!canonicalTarget.startsWith(canonicalBase)) {
                throw new IllegalArgumentException("File path is outside of allowed directory.");
            }
        } catch (IOException e) {
            throw new IllegalArgumentException("Invalid file path.", e);
        }

        // 3. 길이 제한 (선택)
        if (filePath.length() > 512) {
            throw new IllegalArgumentException("File path too long.");
        }

        // 4. 필요 시 문자 패턴 검사
        // if (!filePath.matches("[A-Za-z0-9_./\\\\:-]+")) {
        //     throw new IllegalArgumentException("File path contains illegal characters.");
        // }

        m_ParameterFilePath = filePath;
        GPCamSetDownloadPath(m_ParameterFilePath);
    }

    public String GetGPCamSetDownloadPath() {
        return m_ParameterFilePath;
    }

    public void SetGPCamSendGetParameterFile(String fileName) {
        // 1. null, 빈 문자열 검사
        if (fileName == null || fileName.trim().isEmpty()) {
            throw new IllegalArgumentException("File name must not be null or empty.");
        }

        // 2. 경로 탐색 방지 (단순 예시)
        if (fileName.contains("..") || fileName.contains("/") || fileName.contains("\\")) {
            throw new IllegalArgumentException("Invalid file name: " + fileName);
        }

        // 3. 길이 제한
        if (fileName.length() > 128) {
            throw new IllegalArgumentException("File name too long: " + fileName.length());
        }

        // 4. 허용되지 않는 문자 필터링 (선택)
        // if (!fileName.matches("[A-Za-z0-9._-]+")) {
        //     throw new IllegalArgumentException("File name contains illegal characters");
        // }

        m_ParameterFileName = fileName;
        GPCamSendGetParameterFile(m_ParameterFileName);
    }

    public String GetGPCamSendGetParameterFile() {
        return m_ParameterFileName;
    }

}

package com.kmain.pentype_probe_viewer;

import static com.kmain.pentype_probe_viewer.StreamConstants.STREAMING_ADDR;

import androidx.annotation.Nullable;

import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;

import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;

import java.io.IOException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableEntryException;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.cert.CertificateException;

import javax.crypto.BadPaddingException;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Debug;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.provider.Settings;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyInfo;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import com.generalplus.ffmpegLib.ffmpegWrapper;
import com.scottyab.rootbeer.RootBeer;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.security.KeyFactory;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.security.spec.MGF1ParameterSpec;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;
import javax.crypto.KeyGenerator;
import javax.crypto.Mac;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;
import javax.crypto.spec.SecretKeySpec;

import generalplus.com.GPCamLib.CamWrapper;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

@TargetApi(Build.VERSION_CODES.KITKAT)
public class MainActivity extends FlutterActivity {
    private static MainActivity instance; // 싱글톤처럼 보관
    private FlutterEngine flutterEngineInstance;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        instance = this; // 현재 인스턴스를 보관
    }

    public static MainActivity getInstance() {
        return instance;
    }

    public void setFlutterEngineInstance(@NonNull FlutterEngine engine) {
        this.flutterEngineInstance = engine;
    }

    @Nullable
    public FlutterEngine getFlutterEngineInstance() {
        return flutterEngineInstance;
    }

    private static final String TAG = "MainActivity";
    private static final String VIDEO_TAG = "VideoRecorder";

    // 보안 관련 상수
    private static final String KEY_ALIAS = "pentype_kek_capture";
    private static final String HMAC_KEY_ALIAS = "HMAC_KEY_ALIAS";
    private static final String ANDROID_KEYSTORE = "AndroidKeyStore";
    private static final String TRANSFORMATION = "AES/GCM/NoPadding";
    private static final String RSA_KEY_ALIAS = "pentype_kek_rsa";

    // 멤버 변수
    private GLSurfaceViewFactory glSurfaceViewFactory;
    private KeyStore rsaKeyStore;
    private File directory;
    private SecureRandom secureRandom;

    private final Handler mCamStatusHandler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(Message msg) {
            if (msg.what == CamWrapper.GPCALLBACKTYPE_CAMSTATUS) {
                Bundle data = msg.getData();
                int cmdID = data.getInt(CamWrapper.GPCALLBACKSTATUSTYPE_CMDID);
                int mode = data.getInt(CamWrapper.GPCALLBACKSTATUSTYPE_CMDMODE);
                int dataSize = data.getInt(CamWrapper.GPCALLBACKSTATUSTYPE_DATASIZE);
                byte[] pbyData = data.getByteArray(CamWrapper.GPCALLBACKSTATUSTYPE_DATA);

                Log.d("CAM_STATUS", "CmdID=" + cmdID + ", Mode=" + mode + ", Size=" + dataSize);

                if (cmdID == CamWrapper.GPSOCK_General_CMD_GetDeviceStatus && pbyData != null && pbyData.length > 2) {
                    int batteryRaw = pbyData[2] & 0xFF;
                    int batteryLevel = batteryRaw & 0x0F;
                    Log.d("CAM_STATUS", "BatteryLevel: " + batteryLevel);
                }
            }
        }
    };

    /**
     * 보안 체크 수행
     */
    private boolean performSecurityChecks() {
        Log.d("SecurityCheck", "isDebuggerConnected: " + Debug.isDebuggerConnected());

        if (isDebuggerAttached()) {
            Log.w("SecurityCheck", "isDebuggerAttached() == true");
            return true;
        }

        if (isBeingDebugged()) {
            Log.w("SecurityCheck", "isBeingDebugged() == true");
            return true;
        }

        if (detectFrida()) {
            Log.w("SecurityCheck", "detectFrida() == true");
            return true;
        }

        if (detectXposed()) {
            Log.w("SecurityCheck", "detectXposed() == true");
            return true;
        }

        RootBeer rootBeer = new RootBeer(this);

        if (rootBeer.isRooted()) {
            Log.w("SecurityCheck", "RootBeer: 디바이스가 루팅됨");
            return true;
        }

        Log.i("SecurityCheck", "모든 보안 체크 통과 (문제 없음)");
        return false;
    }

    private void handleSecurityViolation(String message) {
        //Log.e("PENTYPE_DEBUG", message);
        System.err.println(message.toUpperCase().replace("됨", " DETECTED!"));
        finishAffinity();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // 디렉토리 초기화
        initializeDirectories();

        // KeyStore 초기화
        initializeKeyStore();

        // Platform View 등록
        registerPlatformViews(flutterEngine);

        // MethodChannel 설정
        setupMethodChannels(flutterEngine);

        // 명령 포트 연결 시도
        int result = CamWrapper.getComWrapperInstance().connectToDevice(CamWrapper.COMMAND_URL, 8081);
        //Log.d("MainActivity", "명령 포트 연결 결과: " + result);

        // Handler 추가
        CamWrapper.getComWrapperInstance().SetViewHandler(mCamStatusHandler, CamWrapper.GPVIEW_STREAMING);
    }

    private void initializeDirectories() {
        Context context = getApplicationContext();
        directory = new File(context.getFilesDir(), "MyApp");
        if (!directory.exists()) {
            directory.mkdirs();
        }
    }

    private void initializeKeyStore() {
        try {
            secureRandom = new SecureRandom();
            rsaKeyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
            rsaKeyStore.load(null);

            if (!rsaKeyStore.containsAlias(RSA_KEY_ALIAS)) {
                //Log.i(VIDEO_TAG, "RSA KEK가 존재하지 않아 새로 생성합니다.");
                createKekRSA();

                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    //Log.d(VIDEO_TAG, "RSA 키 생성 후 딜레이 1초 뒤 복호화 시도 가능");
                }, 1000);
            } else {
                //Log.i(VIDEO_TAG, "RSA KEK가 이미 존재합니다: " + RSA_KEY_ALIAS);
            }
        } catch (KeyStoreException kse) {
            Log.e(VIDEO_TAG, "KeyStore 초기화 실패", kse);
            throw new RuntimeException("KeyStore 초기화 실패", kse);
        } catch (NoSuchAlgorithmException nsae) {
            Log.e(VIDEO_TAG, "RSA 알고리즘을 찾을 수 없음", nsae);
            throw new RuntimeException("RSA 알고리즘 오류", nsae);
        } catch (NoSuchProviderException nspe) {
            Log.e(VIDEO_TAG, "보안 프로바이더를 찾을 수 없음", nspe);
            throw new RuntimeException("보안 프로바이더 오류", nspe);
        } catch (InvalidAlgorithmParameterException iape) {
            Log.e(VIDEO_TAG, "RSA KEK 생성 파라미터 오류", iape);
            throw new RuntimeException("RSA KEK 파라미터 오류", iape);
        } catch (CertificateException ce) {
            Log.e(VIDEO_TAG, "인증서 오류", ce);
            throw new RuntimeException("인증서 오류", ce);
        } catch (IOException ioe) {
            Log.e(VIDEO_TAG, "I/O 오류로 KeyStore 초기화 실패", ioe);
            throw new RuntimeException("KeyStore I/O 오류", ioe);
        } catch (Exception e) {
            Log.e(VIDEO_TAG, "KeyStore 초기화 또는 RSA KEK 생성 중 알 수 없는 오류", e);
            throw new RuntimeException("KeyStore 초기화 오류(알 수 없음)", e);
        }
    }

    private void registerPlatformViews(FlutterEngine flutterEngine) {
        glSurfaceViewFactory = new GLSurfaceViewFactory(probeRenderer);
        flutterEngine.getPlatformViewsController().getRegistry()
                .registerViewFactory("gl_surface_view", glSurfaceViewFactory);
    }

    /**
     * Method Channel 설정
     */
    private void setupMethodChannels(FlutterEngine flutterEngine) {

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "security_check")
                .setMethodCallHandler(new SecurityCheckChannelHandler());
        // FFmpeg 채널
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "ffmpeg_channel")
                .setMethodCallHandler(new FFmpegChannelHandler());

        // WiFi 설정 채널
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "wifi_settings")
                .setMethodCallHandler(new WiFiSettingsHandler());

        // KEK 암호화 채널
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "kek_channel")
                .setMethodCallHandler(new KekChannelHandler());

        // 파일 암호화 채널
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "crypto_channel")
                .setMethodCallHandler(new CryptoChannelHandler());

        // HMAC 채널
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "hmac")
                .setMethodCallHandler(new HmacChannelHandler());

        // 배터리 잔량 확인 채널
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "battery_channel")
                .setMethodCallHandler((call, result) -> {
                    String method = call.method;

                    switch (method) {
                        case "requestBatteryStatus":
                            CamWrapper.getComWrapperInstance().requestBatteryLevel();

                            new Handler().postDelayed(() -> {
                                CamWrapper.getComWrapperInstance().setMode(CamWrapper.GPDEVICEMODE_Record);
                                CamWrapper.getComWrapperInstance().restartStreaming();
                            }, 1000);

                            result.success(null);
                            break;

                        case "reconnectToCam":
                            int connResult = CamWrapper.getComWrapperInstance().connectToDevice(CamWrapper.COMMAND_URL, 8081);
                            //Log.d("MainActivity", "명령 포트 연결 결과: " + connResult);
                            result.success(connResult);
                            break;

                        // 필요한 경우 여기에 추가적인 메소드 처리 가능
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    public class SecurityCheckChannelHandler implements MethodChannel.MethodCallHandler {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
            switch (call.method) {
                case "runSecurityChecks":
                    boolean threatDetected = performSecurityChecks();
                    result.success(threatDetected);
                    break;

                case "terminateApp":
                    Log.e("SecurityCheck", "보안 위협 감지로 앱을 종료합니다."); // ✅ 로그 추가
                    android.os.Process.killProcess(android.os.Process.myPid());
                    result.success(null);
                    break;

                default:
                    result.notImplemented();
                    break;
            }
        }
    }

    /**
     * FFmpeg 채널 핸들러
     */
    private class FFmpegChannelHandler implements MethodChannel.MethodCallHandler {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
            //Log.d(VIDEO_TAG, "ffmpeg_channel 메서드 호출: " + call.method);

            switch (call.method) {
                case "startStreaming":
                    handleStartStreaming(call, result);
                    break;
                case "stopStreaming":
                    handleStopStreaming(call, result);
                    break;
                case "captureEncryptedRequest":
                    handleCaptureEncrypted(call, result);
                    break;
                case "recordStart":
                    handleRecordStart(call, result);
                    break;
                case "recordStop":
                    handleRecordStop(result);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        }
    }

    /**
     * WiFi 설정 채널 핸들러
     */
    private class WiFiSettingsHandler implements MethodChannel.MethodCallHandler {

        WifiManager wifiManager = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);

        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
            WifiInfo wifiInfo = wifiManager.getConnectionInfo();
            switch (call.method) {
                case "openWiFiSettings":
                    Intent intent = new Intent(Settings.ACTION_WIFI_SETTINGS);
                    startActivity(intent);
                    result.success("Wi-Fi settings opened");
                    break;

                case "isWifiConnected":
                    boolean isConnected = wifiInfo != null && wifiInfo.getNetworkId() != -1;
                    result.success(isConnected);
                    break;

                case "getWifiRssi":
                    if (wifiInfo != null) {
                        int rssi = wifiInfo.getRssi();
                        result.success(rssi);
                    } else {
                        result.error("UNAVAILABLE", "WiFiInfo not available", null);
                    }
                    break;

                default:
                    result.notImplemented();
                    break;
            }
        }
    }

    /**
     * KEK 채널 핸들러
     */
    private class KekChannelHandler implements MethodChannel.MethodCallHandler {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
            try {
                switch (call.method) {
                    case "encryptDek":
                        byte[] dek = call.argument("dek");
                        byte[] encrypted = encryptDekWithRSA(dek);
                        result.success(Base64.encodeToString(encrypted, Base64.NO_WRAP));
                        break;
                    case "decryptDek":
                        String encryptedBase64 = call.argument("encryptedDek");
                        byte[] encryptedDek = Base64.decode(encryptedBase64, Base64.NO_WRAP);
                        byte[] decrypted = decryptDekWithRSA(encryptedDek);
                        result.success(Base64.encodeToString(decrypted, Base64.NO_WRAP));
                        break;
                    default:
                        result.notImplemented();
                }
            } catch (InvalidKeyException ike) {
                Log.e(VIDEO_TAG, "RSA 연산 중 키 오류", ike);
                result.error("RSA_KEY_ERROR", "잘못된 키", Log.getStackTraceString(ike));
            } catch (BadPaddingException bpe) {
                Log.e(VIDEO_TAG, "RSA 연산 중 패딩 오류", bpe);
                result.error("RSA_PADDING_ERROR", "패딩 오류", Log.getStackTraceString(bpe));
            } catch (IllegalBlockSizeException ibse) {
                Log.e(VIDEO_TAG, "RSA 연산 중 블록 크기 오류", ibse);
                result.error("RSA_BLOCK_ERROR", "블록 크기 오류", Log.getStackTraceString(ibse));
            } catch (NoSuchAlgorithmException | NoSuchPaddingException |
                     InvalidAlgorithmParameterException ex) {
                Log.e(VIDEO_TAG, "RSA 연산 중 알고리즘/파라미터 오류", ex);
                result.error("RSA_ALGO_ERROR", "알고리즘 오류", Log.getStackTraceString(ex));
            } catch (SecurityException se) {
                Log.e(VIDEO_TAG, "RSA 연산 중 보안 오류", se);
                result.error("RSA_SECURITY_ERROR", "보안 오류", Log.getStackTraceString(se));
            } catch (Exception e) {
                Log.e(VIDEO_TAG, "RSA 연산 중 알 수 없는 오류", e);
                result.error("RSA_UNKNOWN_ERROR", "알 수 없는 오류", Log.getStackTraceString(e));
            }
        }
    }

    private class CryptoChannelHandler implements MethodChannel.MethodCallHandler {
        private final ExecutorService executor = Executors.newSingleThreadExecutor();
        private final Handler mainHandler = new Handler(Looper.getMainLooper());

        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
            String inputPath = call.argument("input");
            String outputPath = call.argument("output");
            byte[] dek = call.argument("dek");
            byte[] iv = call.argument("iv");

            Runnable cryptoTask = () -> {
                try {
                    switch (call.method) {
                        case "encryptFile":
                            encryptFile(new File(inputPath), new File(outputPath), dek, iv);
                            break;

                        case "decryptFile":
                            decryptFile(new File(inputPath), new File(outputPath), dek, iv);
                            break;

                        default:
                            postResult(() -> result.notImplemented());
                            return;
                    }

                    postResult(() -> result.success(true));

                } catch (InvalidKeyException ike) {
                    Log.e("VIDEO_TAG", "암호화 채널 오류: 잘못된 키", ike);
                    postResult(() -> result.error("CRYPTO_KEY_ERROR", "잘못된 키", Log.getStackTraceString(ike)));
                } catch (BadPaddingException bpe) {
                    Log.e("VIDEO_TAG", "암호화 채널 오류: 패딩 오류", bpe);
                    postResult(() -> result.error("CRYPTO_PADDING_ERROR", "패딩 오류", Log.getStackTraceString(bpe)));
                } catch (IllegalBlockSizeException ibse) {
                    Log.e("VIDEO_TAG", "암호화 채널 오류: 블록 크기 오류", ibse);
                    postResult(() -> result.error("CRYPTO_BLOCK_ERROR", "블록 크기 오류", Log.getStackTraceString(ibse)));
                } catch (InvalidAlgorithmParameterException iape) {
                    Log.e("VIDEO_TAG", "암호화 채널 오류: 알고리즘 파라미터 오류", iape);
                    postResult(() -> result.error("CRYPTO_PARAM_ERROR", "파라미터 오류", Log.getStackTraceString(iape)));
                } catch (NoSuchAlgorithmException | NoSuchPaddingException ex) {
                    Log.e("VIDEO_TAG", "암호화 채널 오류: 알고리즘/패딩 오류", ex);
                    postResult(() -> result.error("CRYPTO_ALGO_ERROR", "알고리즘 오류", Log.getStackTraceString(ex)));
                } catch (SecurityException se) {
                    Log.e("VIDEO_TAG", "암호화 채널 오류: 보안 오류", se);
                    postResult(() -> result.error("CRYPTO_SECURITY_ERROR", "보안 오류", Log.getStackTraceString(se)));
                } catch (Exception e) {
                    Log.e("VIDEO_TAG", "암호화 채널 오류: 알 수 없는 오류", e);
                    postResult(() -> result.error("CRYPTO_UNKNOWN_ERROR", "알 수 없는 오류", Log.getStackTraceString(e)));
                }
            };

            executor.execute(cryptoTask);
        }

        private void postResult(Runnable resultCallback) {
            mainHandler.post(resultCallback);
        }
    }

    /**
     * HMAC 채널 핸들러
     */
    private class HmacChannelHandler implements MethodChannel.MethodCallHandler {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
            if ("generateHmac".equals(call.method)) {
                String patientId = call.argument("patientId");
                try {
                    String hmac = generateHmac(patientId);
                    result.success(hmac);
                } catch (InvalidKeyException ike) {
                    Log.e("MainActivity", "HMAC 생성 중 키 오류", ike);
                    result.error("HMAC_KEY_ERROR", "잘못된 키", Log.getStackTraceString(ike));
                } catch (NoSuchAlgorithmException nsae) {
                    Log.e("MainActivity", "HMAC 생성 중 알고리즘 오류", nsae);
                    result.error("HMAC_ALGO_ERROR", "지원하지 않는 알고리즘", Log.getStackTraceString(nsae));
                } catch (UnsupportedEncodingException uee) {
                    Log.e("MainActivity", "HMAC 생성 중 인코딩 오류", uee);
                    result.error("HMAC_ENCODING_ERROR", "인코딩 오류", Log.getStackTraceString(uee));
                } catch (SecurityException se) {
                    Log.e("MainActivity", "HMAC 생성 중 보안 오류", se);
                    result.error("HMAC_SECURITY_ERROR", "보안 오류", Log.getStackTraceString(se));
                } catch (Exception e) {
                    Log.e("MainActivity", "HMAC 생성 중 알 수 없는 오류", e);
                    result.error("HMAC_UNKNOWN_ERROR", "알 수 없는 오류", Log.getStackTraceString(e));
                }
            } else {
                result.notImplemented();
            }
        }
    }

    // === 핸들러 메서드들 ===
    private final TextRenderer textRenderer = new TextRenderer();
    private final ffmpegWrapper ffmpegWrapperInstance = new ffmpegWrapper();
    private final ProbeRenderer probeRenderer = new ProbeRenderer(textRenderer, ffmpegWrapperInstance);

    private void handleStartStreaming(MethodCall call, MethodChannel.Result result) {
        String userId = call.argument("user_id");
        String patientId = call.argument("patient_id");

        textRenderer.setUserID("user: " + userId);
        textRenderer.setPatientInformation("Patient Id:" + safeString(patientId));

        // 1. 모드 설정 및 스트리밍 재시작 요청 (네이티브 쪽은 비동기일 가능성 있음)
        CamWrapper.getComWrapperInstance().setMode(CamWrapper.GPDEVICEMODE_Record);
        CamWrapper.getComWrapperInstance().restartStreaming();

        // 2. 약간의 대기 후 실제 ffmpeg 스트리밍 시작

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            ffmpegWrapper.setStreaming(true);
            int resultCode = ffmpegWrapper.initAndPlay(STREAMING_ADDR, "");
        }, 1000); // 약간의 여유 시간 후 ffmpeg 호출
    }

    private void handleStopStreaming(MethodCall call, MethodChannel.Result result) {
        //Log.d(VIDEO_TAG, "스트리밍 종료 요청");
        ffmpegWrapper.stop();  // 네이티브 자원 정리
        result.success(null);
    }

    private void handleCaptureEncrypted(MethodCall call, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                // 요청 파라미터 추출
                String fileName = call.argument("file_name");
                byte[] dek = Base64.decode((String) call.argument("dek"), Base64.DEFAULT);
                byte[] iv = Base64.decode((String) call.argument("iv"), Base64.DEFAULT);
                File file = new File(directory, fileName + ".png.enc");

                GLSurfaceViewPlatformView platformView = glSurfaceViewFactory.getGLSurfaceViewPlatformView();
                if (platformView != null) {
                    long fileSize = platformView.saveBitmapToEncryptedFile(file, dek, iv);

                    // 메인 스레드로 결과 전송
                    new Handler(Looper.getMainLooper()).post(() -> {
                        result.success(fileSize); // ✅ 반환값만 호출, return 사용 금지
                    });
                } else {
                    Log.e(VIDEO_TAG, "PlatformView가 null입니다");
                    new Handler(Looper.getMainLooper()).post(() -> {
                        result.error("NULL_PLATFORM_VIEW", "PlatformView is null", null);
                    });
                }
            } catch (Exception e) {
                Log.e(VIDEO_TAG, "캡처 중 알 수 없는 오류 발생", e);
                new Handler(Looper.getMainLooper()).post(() -> {
                    result.error("UNKNOWN_ERROR", "알 수 없는 오류 발생", null);
                });
            }
        }).start();
    }

    private void handleRecordStart(MethodCall call, MethodChannel.Result result) {
        String fileName = call.argument("file_name");

        //Log.i(TAG, "Record Start");
        if (fileName == null || fileName.isEmpty()) {
            result.error("INVALID_NAME", "File name is null or empty", null);
            return;
        }

        File file = new File(directory, fileName + ".mp4");
        probeRenderer.startRecording(file);
        result.success("Recording started: " + file.getAbsolutePath());
    }

    private void handleRecordStop(MethodChannel.Result result) {
        //Log.d(TAG, "Stopping recording with completion callback...");

        probeRenderer.stopRecording(() -> {
            File file = new File(directory, "tmp.mp4");

            long lastSize = -1;
            try {
                for (int i = 0; i < 10; i++) {
                    Thread.sleep(300);
                    long size = file.length();
                    if (size > 0 && size == lastSize) break;
                    lastSize = size;
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                Log.e(TAG, "Thread sleep interrupted", e);
            } catch (SecurityException se) { // 정말 발생 가능한 예외만
                Log.e(TAG, "보안 오류", se);
            }

            // ✅ return 문 제거하고 단순히 핸들러에서 콜백 호출
            new Handler(Looper.getMainLooper()).post(() -> {
                //Log.d(TAG, "✅ Recording fully stopped and file closed");
                result.success("Recording stopped");
            });
        });
    }

    // === 보안 체크 메서드들 ===

    private boolean isDebuggerAttached() {
        return Debug.isDebuggerConnected() || Debug.waitingForDebugger();
    }

    private boolean isBeingDebugged() {
        try {
            BufferedReader reader = new BufferedReader(new FileReader("/proc/self/status"));
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.startsWith("TracerPid:")) {
                    int tracerPid = Integer.parseInt(line.split("\\s+")[1]);
                    Log.d("SecurityCheck", "TracerPid: " + tracerPid); // ← 추가
                    return tracerPid != 0;
                }
            }
            reader.close();
        } catch (Exception e) {
            Log.e("SecurityCheck", "TracerPid 체크 중 오류: " + e.getMessage());
        }
        return false;
    }

    private boolean detectFrida() {
        String[] suspiciousProcesses = {
                "frida-server", "frida-agent", "gum-js-loop"
        };
        try {
            Process exec = Runtime.getRuntime().exec("ps");
            BufferedReader reader = new BufferedReader(new InputStreamReader(exec.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                for (String keyword : suspiciousProcesses) {
                    if (line.contains(keyword)) {
                        return true;
                    }
                }
            }
            reader.close();
        } catch (IOException ioe) {
            Log.e("MainActivity", "파일 처리 중 오류 발생", ioe);
            return false;
        }
        return false;
    }

    private boolean detectXposed() {
        StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
        for (StackTraceElement element : stackTrace) {
            if (element.getClassName().contains("de.robv.android.xposed")) {
                return true;
            }
        }
        return false;
    }

    private boolean isDeviceRooted(Context context) {
        RootBeer rootBeer = new RootBeer(context);
        return rootBeer.isRooted();
    }

    // === 암호화 관련 메서드들 ===

    private void createKekRSA() throws Exception {
        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_RSA, ANDROID_KEYSTORE);

        KeyGenParameterSpec.Builder builder = new KeyGenParameterSpec.Builder(
                RSA_KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
                .setKeySize(2048)
                .setUserAuthenticationRequired(false);

        keyPairGenerator.initialize(builder.build());
        keyPairGenerator.generateKeyPair();

        //Log.i(VIDEO_TAG, "RSA KEK 생성 완료: " + RSA_KEY_ALIAS);
    }

    private byte[] encryptDekWithRSA(byte[] dek) {
        OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                "SHA-256",
                "MGF1",
                MGF1ParameterSpec.SHA1,
                PSource.PSpecified.DEFAULT
        );

        Cipher cipher = null;
        try {
            KeyStore.Entry entry = rsaKeyStore.getEntry(RSA_KEY_ALIAS, null);
            if (!(entry instanceof KeyStore.PrivateKeyEntry)) {
                throw new IllegalStateException("RSA 키쌍이 유효하지 않거나 찾을 수 없습니다.");
            }
            java.security.PublicKey publicKey = ((KeyStore.PrivateKeyEntry) entry).getCertificate().getPublicKey();

            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] pubKeyHash = digest.digest(publicKey.getEncoded());

            cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            cipher.init(Cipher.ENCRYPT_MODE, publicKey, oaepParams);
            byte[] encrypted = cipher.doFinal(dek);

            return encrypted;
        } catch (InvalidKeyException ike) {
            Log.e(VIDEO_TAG, "RSA 암호화 실패: 잘못된 키", ike);
            throw new RuntimeException("RSA 암호화 실패: 잘못된 키", ike);
        } catch (InvalidAlgorithmParameterException iape) {
            Log.e(VIDEO_TAG, "RSA 암호화 실패: 잘못된 알고리즘 파라미터", iape);
            throw new RuntimeException("RSA 암호화 실패: 잘못된 파라미터", iape);
        } catch (BadPaddingException bpe) {
            Log.e(VIDEO_TAG, "RSA 암호화 실패: 패딩 오류", bpe);
            throw new RuntimeException("RSA 암호화 실패: 패딩 오류", bpe);
        } catch (IllegalBlockSizeException ibse) {
            Log.e(VIDEO_TAG, "RSA 암호화 실패: 블록 크기 오류", ibse);
            throw new RuntimeException("RSA 암호화 실패: 블록 크기 오류", ibse);
        } catch (NoSuchPaddingException | NoSuchAlgorithmException e) {
            Log.e(VIDEO_TAG, "암호화 알고리즘/패딩 오류", e);
            throw new RuntimeException("암호화 실패", e);
        } catch (KeyStoreException | UnrecoverableEntryException e) {
            Log.e(TAG, "키스토어 엔트리 가져오기 실패", e);
            throw new RuntimeException("RSA 암호화 실패: 키스토어 오류", e);
        }
    }

    private byte[] decryptDekWithRSA(byte[] encryptedDek) throws Exception {
        OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                "SHA-256",
                "MGF1",
                MGF1ParameterSpec.SHA1,
                PSource.PSpecified.DEFAULT
        );

        if (encryptedDek == null || encryptedDek.length == 0) {
            throw new IllegalArgumentException("encryptedDek is null or empty");
        }

        rsaKeyStore.load(null);

        Cipher cipher = null;
        try {
            KeyStore.Entry entry = rsaKeyStore.getEntry(RSA_KEY_ALIAS, null);
            if (!(entry instanceof KeyStore.PrivateKeyEntry)) {
                throw new IllegalStateException("RSA 개인키 접근 실패 또는 유효하지 않습니다.");
            }
            java.security.PrivateKey privateKey = ((KeyStore.PrivateKeyEntry) entry).getPrivateKey();

            cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            cipher.init(Cipher.DECRYPT_MODE, privateKey, oaepParams);

            byte[] decrypted = cipher.doFinal(encryptedDek);
            return decrypted;
        } catch (InvalidKeyException ike) {
            Log.e(VIDEO_TAG, "RSA DEK 복호화 실패: 잘못된 키", ike);
            throw ike;
        } catch (BadPaddingException bpe) {
            Log.e(VIDEO_TAG, "RSA DEK 복호화 실패: 잘못된 패딩", bpe);
            throw bpe;
        } catch (IllegalBlockSizeException ibse) {
            Log.e(VIDEO_TAG, "RSA DEK 복호화 실패: 블록 크기 오류", ibse);
            throw ibse;
        } catch (NoSuchAlgorithmException | NoSuchPaddingException |
                 InvalidAlgorithmParameterException ex) {
            Log.e(VIDEO_TAG, "RSA DEK 복호화 실패: 알고리즘/파라미터 오류", ex);
            throw ex;
        } catch (Exception e) {
            Log.e(VIDEO_TAG, "RSA DEK 복호화 중 알 수 없는 오류 발생", e);
            throw e;
        }
    }

    public static void encryptFile(File inputFile, File outputFile, byte[] dek, byte[] iv) throws Exception {
        //Log.d(TAG, "Encrypting file: " + inputFile.getAbsolutePath());
        //Log.d(TAG, "Encrypting file: " + outputFile.getAbsolutePath());

        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        SecretKeySpec keySpec = new SecretKeySpec(dek, "AES");
        GCMParameterSpec gcmSpec = new GCMParameterSpec(128, iv); // 128-bit tag
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, gcmSpec);

        try (FileInputStream fis = new FileInputStream(inputFile);
             FileOutputStream fos = new FileOutputStream(outputFile);
             CipherOutputStream cos = new CipherOutputStream(fos, cipher)) {

            byte[] buffer = new byte[16384];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                cos.write(buffer, 0, bytesRead);
            }
            cos.flush();
        } catch (IOException e) {
            //Log.e(TAG, "❌ 파일 IO 예외", e);
            throw e;
        } catch (Exception e) {
            //Log.e(TAG, "❌ 일반 예외 발생", e);
            throw e;
        }
    }

    public static void decryptFile(File inputFile, File outputFile, byte[] dek, byte[] iv) throws Exception {
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        SecretKeySpec keySpec = new SecretKeySpec(dek, "AES");
        GCMParameterSpec gcmSpec = new GCMParameterSpec(128, iv);
        cipher.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec);

        try (FileInputStream fis = new FileInputStream(inputFile);
             CipherInputStream cis = new CipherInputStream(fis, cipher);
             FileOutputStream fos = new FileOutputStream(outputFile)) {

            byte[] buffer = new byte[16384];
            int bytesRead;
            while ((bytesRead = cis.read(buffer)) != -1) {
                fos.write(buffer, 0, bytesRead);
            }
            fos.flush();

        } catch (IOException e) {
            //Log.e(TAG, "❌ 파일 IO 예외", e);
            throw e;
        } catch (Exception e) {
            //Log.e(TAG, "❌ 일반 예외 발생", e);
            throw e;
        }
    }

    private String generateHmac(String patientId) throws Exception {
        KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);

        if (!keyStore.containsAlias(HMAC_KEY_ALIAS)) {
            KeyGenerator keyGenerator = KeyGenerator.getInstance("HmacSHA256", "AndroidKeyStore");
            keyGenerator.init(new android.security.keystore.KeyGenParameterSpec.Builder(
                    HMAC_KEY_ALIAS,
                    android.security.keystore.KeyProperties.PURPOSE_SIGN)
                    .setDigests(android.security.keystore.KeyProperties.DIGEST_SHA256)
                    .build());
            keyGenerator.generateKey();
        }

        Key key = keyStore.getKey(HMAC_KEY_ALIAS, null);
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(key);
        byte[] hmacBytes = mac.doFinal(patientId.getBytes(StandardCharsets.UTF_8));
        return bytesToHex(hmacBytes);
    }

    // === 배터리 관련 메서드들 ===

    // === 유틸리티 메서드들 ===

    public static String safeString(String value) {
        return value != null && !value.equals("") ? value : "미입력";
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder result = new StringBuilder();
        for (byte b : bytes) {
            result.append(String.format("%02X", b));
        }
        return result.toString();
    }

    private String formatFileSize(long bytes) {
        if (bytes < 1024) return bytes + " B";
        int exp = (int) (Math.log(bytes) / Math.log(1024));
        String pre = "KMGTPE".charAt(exp - 1) + "";
        return String.format("%.1f %sB", bytes / Math.pow(1024, exp), pre);
    }

    private void logKeySecurityInfo(String alias) {
        try {
            KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
            keyStore.load(null);

            Key key = keyStore.getKey(alias, null);
            if (key == null) {
                //Log.e(VIDEO_TAG, "키를 찾을 수 없습니다: " + alias);
                return;
            }


            KeyInfo keyInfo = null;

            if (key instanceof SecretKey) {
                SecretKeyFactory factory = SecretKeyFactory.getInstance(key.getAlgorithm(), ANDROID_KEYSTORE);
                keyInfo = (KeyInfo) factory.getKeySpec((SecretKey) key, KeyInfo.class);
            } else if (key instanceof java.security.PrivateKey) {
                KeyFactory factory = KeyFactory.getInstance(key.getAlgorithm(), ANDROID_KEYSTORE);
                keyInfo = (KeyInfo) factory.getKeySpec((java.security.PrivateKey) key, KeyInfo.class);
            } else {
                //Log.e(VIDEO_TAG, "알 수 없는 키 유형입니다: " + key.getClass().getName());
                return;
            }

            //Log.i(VIDEO_TAG, "isInsideSecureHardware (TEE): " + keyInfo.isInsideSecureHardware());
            //Log.i(VIDEO_TAG, "KeySize: " + keyInfo.getKeySize());
            //Log.i(VIDEO_TAG, "isUserAuthenticationRequired: " + keyInfo.isUserAuthenticationRequired());
            //Log.i(VIDEO_TAG, "Key Origin: " + keyInfo.getOrigin());

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                try {
                    Method strongBoxMethod = KeyInfo.class.getMethod("isStrongBoxBacked");
                    boolean isStrongBox = (boolean) strongBoxMethod.invoke(keyInfo);
                    //Log.i(VIDEO_TAG, "isStrongBoxBacked: " + isStrongBox);
                } catch (NoSuchMethodException e) {
                    //Log.i(VIDEO_TAG, "isStrongBoxBacked: Not available (method missing)");
                }
            } else {
                //Log.i(VIDEO_TAG, "isStrongBoxBacked: Not supported (API < 28)");
            }

        } catch (KeyStoreException kse) {
            Log.e(VIDEO_TAG, "키 보안 정보 조회 중 KeyStore 오류", kse);
            throw new RuntimeException("키 보안 정보 조회 실패: KeyStore 오류", kse);
        } catch (NoSuchAlgorithmException nsae) {
            Log.e(VIDEO_TAG, "키 보안 정보 조회 중 알고리즘 오류", nsae);
            throw new RuntimeException("키 보안 정보 조회 실패: 알고리즘 오류", nsae);
        } catch (SecurityException se) {
            Log.e(VIDEO_TAG, "키 보안 정보 조회 중 보안 오류", se);
            throw new RuntimeException("키 보안 정보 조회 실패: 보안 오류", se);
        } catch (IOException ioe) {
            Log.e(VIDEO_TAG, "키 보안 정보 조회 중 I/O 오류", ioe);
            throw new RuntimeException("키 보안 정보 조회 실패: I/O 오류", ioe);
        } catch (Exception e) {
            Log.e(VIDEO_TAG, "키 보안 정보 조회 중 알 수 없는 오류", e);
            throw new RuntimeException("키 보안 정보 조회 실패: 알 수 없는 오류", e);
        }
    }
}
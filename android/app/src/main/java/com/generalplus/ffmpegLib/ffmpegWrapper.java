package com.generalplus.ffmpegLib;

import android.opengl.GLSurfaceView;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

import java.io.File;


public class ffmpegWrapper implements GLSurfaceView.Renderer {

    private final static String TAG = "ffmpegWrapper";
    private static Handler	m_NowViewHandler;

    public final static String LOW_LOADING_TRANSCODE_OPTIONS = "qmin=15;qmax=35;b=400000;g=15;bf=0;refs=2;weightp=simple;level=2.2;" +
                                                               "x264-params=lookahead-threads=3:subme=4:chroma_qp_offset=0";

    public final static int FFMPEG_STATUS_PLAYING			            = 0x00;
    public final static int FFMPEG_STATUS_STOPPED			            = 0x01;
    public final static int FFMPEG_STATUS_SAVESNAPSHOTCOMPLETE			= 0x02;
    public final static int FFMPEG_STATUS_SAVEVIDEOCOMPLETE			    = 0x03;
    public final static int FFMPEG_STATUS_BUFFERING			            = 0x04;

    public final static int EXTRACTOR_OK                            = 0;
    public final static int EXTRACTOR_BUSY                          = 1;
    public final static int EXTRACTOR_READFILEFAILED                = 2;
    public final static int EXTRACTOR_DECODEFAILED                  = 3;
    public final static int EXTRACTOR_NOSUCHFRAME                   = 4;

    public final static int CODEC_ID_NONE                          = 0;
    public final static int CODEC_ID_MJPEG                         = 8;
    public final static int CODEC_ID_H264                          = 28;

    public final static int CUSTOM_PACKET_VIDEO                    =0;
    public final static int CUSTOM_PACKET_AUDIO                    =1;

    private boolean captureRequested =                           false;
    private File captureFilePaht;

    public enum eFFMPEG_ERRCODE
    {
        FFMPEGPLAYER_NOERROR,				    //0
        FFMPEGPLAYER_INITMEDIAFAILED,	        //1
        FFMPEGPLAYER_MEDIAISPLAYING,	        //2
        FFMPEGPLAYER_CREATESAVESTREAMFAILED,	//3
        FFMPEGPLAYER_SAVESNAPSHOTFAILED,        //4
        FFMPEGPLAYER_SAVEVIDEOFAILED,	        //5

    };

    public enum ePlayerStatus
    {
        E_PlayerStatus_Stoped,
        E_PlayerStatus_Playing,
        E_PlayerStatus_Stoping,

    };

    public enum eDisplayScale
    {
        E_DisplayScale_Fit,
        E_DisplayScale_Fill,
        E_DisplayScale_Stretch,

    };

    public enum eEncodeContainer
    {
        E_EncodeContainer_MP4 ,
        E_EncodeContainer_AVI ,

    };

    //----------------------------------------------------------------------
    static {
        try {
            Log.i(TAG, "Trying to load ffmpeg.so ...");

            System.loadLibrary("ffmpeg");
        } catch (UnsatisfiedLinkError Ule) {
            Log.e(TAG, "Cannot load ffmpeg.so ...");
            Ule.printStackTrace();
        } finally {
        }
    }

    public void onSurfaceCreated(GL10 unused, EGLConfig config) {

        Log.e(TAG, "onSurfaceCreated ... ");
        naInitDrawFrame();
    }

    public void onDrawFrame(GL10 gl) {

        naDrawFrame();
    }

    public void onSurfaceChanged(GL10 unused, int width, int height) {

        Log.e(TAG, "onSurfaceChanged ... ");
        naSetup(width, height);
    }

    /**
     * \brief
     * 	Set The player status change notification handler.
     *
     * \param[in] ViewHandler
     *	The handler.
     *
     */
    public synchronized void SetViewHandler(Handler viewHandler) {
        if (viewHandler == null) {
            throw new IllegalArgumentException("ViewHandler must not be null");
        }
        m_NowViewHandler = viewHandler;
    }

    /**
     * \brief
     * 	Set The player status change notification.
     *
     * \param[in] i32Status
     *	The status. FFMPEG_STATUS_PLAYING => Player is playing , FFMPEG_STATUS_STOPPED => Player is stop play.
     *              FFMPEG_STATUS_SAVESNAPSHOTCOMPLETE is saving snapshot complete  , FFMPEG_STATUS_SAVEVIDEOCOMPLETE is ssaving video complete .
     *
     */
    public void StatusChange(int i32Status) {
        Handler handlerCopy;
        synchronized (this) {
            handlerCopy = m_NowViewHandler;
        }

        if (handlerCopy != null) {
            Message msg = new Message();
            msg.what = i32Status;
            handlerCopy.sendMessage(msg);
        }
    }

    /**
     * \brief
     * 	Set the streaming path and play the streaming.
     *
     * \param[in] pFileName
     *	The streaming path.
     * \param[in] pOptions
     *	The option for streaming.The option string format is "option1=argument1;option2=argument2;...".
     *  Ex: RTSP streaming over TCP "rtsp_transport=tcp".
     *
     * \return
     *	Return 0 if this function succeeded. Otherwise, other value returned.
     */
    private static native int naInitAndPlay(String pFileName, String pOptions);
    public static int initAndPlay(String pFileName, String pOptions) {
        return naInitAndPlay(pFileName, pOptions);
    }

    private static native String naGetVideoInfo(String pFileName);
    public static String getVideoInfo(String pFileName) {
        return naGetVideoInfo(pFileName);
    }

    private static native int naCustomProtocol(String VideoCodecName, String AudioCodecName, String pOptions);
    public static int customProtocol(String VideoCodecName, String AudioCodecName, String pOptions) {
        return naCustomProtocol(VideoCodecName, AudioCodecName, pOptions);
    }

    private static native int naPushCustomPacket(byte[] pbyData, int i32Size, int i32Type, long TimeStamp);
    public static int pushCustomPacket(byte[] data, int size, int type, long timestamp) {
        return naPushCustomPacket(data, size, type, timestamp);
    }

    private static native int[] naGetVideoRes();
    public static int[] getVideoRes() {
        return naGetVideoRes();
    }

    private static native int naSetup(int width, int height);
    public static int setup(int width, int height) {
        return naSetup(width, height);
    }

    private static native int naPlay();
    public static int play() {
        return naPlay();
    }

    private static native int naStop();
    public static int stop() {
        return naStop();
    }

    private static native int naPause();
    public static int pause() {
        return naPause();
    }

    private static native int naResume();
    public static int resume() {
        return naResume();
    }

    private static native int naSeek(long pos);
    public static int seek(long pos) {
        return naSeek(pos);
    }

    private static native int naSetStreaming(boolean enable);
    public static int setStreaming(boolean enable) {
        return naSetStreaming(enable);
    }

    private static native int naSetEncodeByLocalTime(boolean enable);
    public static int setEncodeByLocalTime(boolean enable) {
        return naSetEncodeByLocalTime(enable);
    }

    private static native int naSetDebugMessage(boolean enable);
    public static int setDebugMessage(boolean enable) {
        return naSetDebugMessage(enable);
    }

    private static native int naSetRepeat(boolean repeat);
    public static int setRepeat(boolean repeat) {
        return naSetRepeat(repeat);
    }

    private static native int naSetForceToTranscode(boolean enable);
    public static int setForceToTranscode(boolean enable) {
        return naSetForceToTranscode(enable);
    }

    private static native long naGetDuration();
    public static long getDuration() {
        return naGetDuration();
    }

    private static native long naGetPosition();
    public static long getPosition() {
        return naGetPosition();
    }

    private static native int naInitDrawFrame();
    public static int initDrawFrame() {
        return naInitDrawFrame();
    }

    private static native int naDrawFrame();
    public static int drawFrame() {
        return naDrawFrame();
    }

    private static native int naStatus();
    public static int getStatus() {
        return naStatus();
    }

    private static native long naGetRevSizeCnt();
    public static long getRevSizeCnt() {
        return naGetRevSizeCnt();
    }

    private static native long naGetFrameCnt();
    public static long getFrameCnt() {
        return naGetFrameCnt();
    }

    private static native int naGetStreamCodecID();
    public static int getStreamCodecID() {
        return naGetStreamCodecID();
    }

    private static native int naSaveSnapshot(String fileName);
    public static int saveSnapshot(String fileName) {
        return naSaveSnapshot(fileName);
    }

    private static native int naSaveVideo(String fileName);
    public static int saveVideo(String fileName) {
        return naSaveVideo(fileName);
    }

    private static native int naStopSaveVideo();
    public static int stopSaveVideo() {
        return naStopSaveVideo();
    }

    private static native int naExtractFrame(String videoPath, String savePath, long frameIdx);
    public static int extractFrame(String videoPath, String savePath, long frameIdx) {
        return naExtractFrame(videoPath, savePath, frameIdx);
    }

    private static native int naSetTransCodeOptions(String options);
    public static int setTransCodeOptions(String options) {
        return naSetTransCodeOptions(options);
    }

    private static native int naSetDecodeOptions(String options);
    public static int setDecodeOptions(String options) {
        return naSetDecodeOptions(options);
    }

    private static native int naSetScaleMode(int mode);
    public static int setScaleMode(int mode) {
        return naSetScaleMode(mode);
    }

    private static native int naSetCovertDecodeFrameFormat(int format);
    public static int setConvertDecodeFrameFormat(int format) {
        return naSetCovertDecodeFrameFormat(format);
    }

    private static native int naSetBufferingTime(long bufferTime);
    public static int setBufferingTime(long bufferTime) {
        if (bufferTime <= 0) {
            Log.e(TAG, "Buffer time must be greater than 0");
            return -1;
        }
        return naSetBufferingTime(bufferTime);
    }

    private static native ffDecodeFrame naGetDecodeFrame();
    public static ffDecodeFrame getDecodeFrame() {
        return naGetDecodeFrame();
    }

    // 🚨 문제된 메서드 래핑 적용
    private static native int naSetZoomInRatio(float fRatio);
    public static int setZoomInRatio(float fRatio) {
        if (fRatio <= 0.0f) {
            Log.e(TAG, "Invalid zoom ratio. Must be greater than 0");
            return -1;
        }
        return naSetZoomInRatio(fRatio);
    }
}

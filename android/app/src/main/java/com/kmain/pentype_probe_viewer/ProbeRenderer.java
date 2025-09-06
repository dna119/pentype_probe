package com.kmain.pentype_probe_viewer;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.opengl.EGL14;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;

import com.android.grafika.TextureMovieEncoder;
import com.generalplus.ffmpegLib.ffmpegWrapper;

import java.io.File;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.ShortBuffer;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import android.opengl.EGLContext;
import android.util.Log;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class ProbeRenderer implements GLSurfaceView.Renderer {
    private int width = 1280, height = 720;
    private int fboId = -1;
    private EGLContext appEglContext;  // 화면용 EGLContext
    private static final TextureMovieEncoder sVideoEncoder = new TextureMovieEncoder();
    private boolean eglReady = false;
    private final TextRenderer textRenderer;
    private final ffmpegWrapper ffmpegWrapperInstance;

    ProbeRenderer(TextRenderer textRenderer, ffmpegWrapper ffmpegWrapperInstance) {
        this.textRenderer = textRenderer;
        this.ffmpegWrapperInstance = ffmpegWrapperInstance;
    }

    public boolean isEglReady() {
        return eglReady;
    }

    public void startRecording(File outputFile) {
        if (appEglContext == null) {
            Log.e("ProbeRenderer", "EGLContext not ready — startRecording aborted");
            return;
        }

        sVideoEncoder.startRecording(new TextureMovieEncoder.EncoderConfig(
                outputFile, width, height, 6_000_000, appEglContext));
    }


    public void stopRecording(Runnable onComplete) {
        sVideoEncoder.stopRecording(onComplete);
    }

    public boolean isRecording() {
        return sVideoEncoder.isRecording();
    }

    private void createFbo() {
        int[] fbo = new int[1];
        GLES20.glGenFramebuffers(1, fbo, 0);
        fboId = fbo[0];
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        appEglContext = EGL14.eglGetCurrentContext();

        createFbo();

        ffmpegWrapperInstance.onSurfaceCreated(gl, config);
        textRenderer.onSurfaceCreated(gl, config);

        eglReady = true;
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        // 기본적인 유효성 검사
        if (width <= 0 || height <= 0) {
            // 잘못된 값이면 기본값으로 대체하거나 예외 발생
            // 여기서는 로그만 찍고 기본값 지정
            // Log.w(TAG, "Invalid surface size: " + width + "x" + height + ", using default 1x1");
            width = 1;
            height = 1;
        }

        // (선택) 상한 제한
        int MAX_SIZE = 8192; // 예시
        if (width > MAX_SIZE) width = MAX_SIZE;
        if (height > MAX_SIZE) height = MAX_SIZE;

        this.width = width;
        this.height = height;

        GLES20.glViewport(0, 0, width, height);
        ffmpegWrapperInstance.onSurfaceChanged(gl, width, height);
        textRenderer.onSurfaceChanged(gl, width, height);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        if (sVideoEncoder.isRecording()) {
            sVideoEncoder.frameAvailableSoon(() -> {
                // FBO에 렌더링
                GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fboId);
                GLES20.glViewport(0, 0, width, height);
                renderScene();
                GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
            });
        }

        // 화면에 렌더링
        GLES20.glViewport(0, 0, width, height);
        renderScene();
    }


    private void renderScene() {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);

        ffmpegWrapperInstance.onDrawFrame(null);

        GLES20.glEnable(GLES20.GL_BLEND);
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA);

        textRenderer.onDrawFrame(null);

        GLES20.glDisable(GLES20.GL_BLEND);
    }
}

class TextRenderer implements GLSurfaceView.Renderer {
    private int textureId = -1;
    private String dateTime = "Loading...";
    private String userID = "Loading...";
    private String patientInformation = "Loading...";
    private SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd  HH:mm:ss", Locale.getDefault());

    // 싱글톤 패턴
    private static TextRenderer textRenderer;

    TextRenderer() {
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        textureId = loadTextTexture(dateTime, userID, patientInformation);  // 새로운 텍스처 생성
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        String newText = dateFormat.format(new Date());

        if (!newText.equals(dateTime)) {
            updateDateTime(newText);  // 텍스트가 바뀌면 텍스처 업데이트
        }

        drawTexture(textureId);
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        GLES20.glViewport(0, 0, width, height);
    }

    public void setUserID(String newUserID) {
        // 유효성 검사
        if (newUserID == null) {
            throw new IllegalArgumentException("UserID must not be null.");
        }

        // 필요 시 길이 제한
        if (newUserID.length() > 64) { // 예: 최대 64자
            // 잘라내거나 예외 처리
            newUserID = newUserID.substring(0, 64);
        }

        // 필요 시 문자 정제
        newUserID = newUserID.trim();

        // 기존 텍스처 삭제
        if (textureId != -1) {
            int[] textures = { textureId };
            GLES20.glDeleteTextures(1, textures, 0);
        }

        userID = newUserID;
        textureId = loadTextTexture(dateTime, userID, patientInformation);
    }

    public void setPatientInformation(String newPatientInformation) {
        // 유효성 검사
        if (newPatientInformation == null) {
            throw new IllegalArgumentException("Patient information must not be null.");
        }
        // 길이 제한 (예: 256자 이내)
        if (newPatientInformation.length() > 256) {
            // 필요 시 잘라내거나 예외 처리
            newPatientInformation = newPatientInformation.substring(0, 256);
        }

        // 기존 텍스처 삭제
        if (textureId != -1) {
            int[] textures = { textureId };
            GLES20.glDeleteTextures(1, textures, 0);
        }

        patientInformation = newPatientInformation;
        textureId = loadTextTexture(dateTime, userID, patientInformation);
    }

    public void updateDateTime(String newText) {
        // 유효성 검사
        if (newText == null) {
            throw new IllegalArgumentException("DateTime text must not be null.");
        }

        // 길이 제한
        if (newText.length() > 128) {
            // 너무 길면 잘라내거나 예외 처리
            newText = newText.substring(0, 128);
        }

        // 문자 정제
        newText = newText.trim();

        // 필요하다면 날짜/시간 포맷 검증 (예시)
        // if (!newText.matches("\\d{4}-\\d{2}-\\d{2}.*")) {
        //     throw new IllegalArgumentException("Invalid date/time format");
        // }

        // 기존 텍스처 삭제
        if (textureId != -1) {
            int[] textures = { textureId };
            GLES20.glDeleteTextures(1, textures, 0);
        }

        dateTime = newText;
        textureId = loadTextTexture(dateTime, userID, patientInformation);
    }

    // 텍스트를 비트맵으로 그려서 텍스처로 변환
    private int loadTextTexture(String dateTime, String userID, String patientInformation) {
        Paint paint = new Paint();
        paint.setColor(Color.WHITE);
        paint.setTextSize(48);  // 텍스트 크기
        paint.setAntiAlias(true);
        paint.setTextAlign(Paint.Align.RIGHT);  // 텍스트 오른쪽 정렬

        // 텍스트 크기 측정
        Rect bounds = new Rect();
        paint.getTextBounds(dateTime, 0, dateTime.length(), bounds);

        // 비트맵 크기 동적 조정 (텍스트 크기에 여유를 더함)
        int bitmapWidth = (bounds.width() * 2) + 40;  // 텍스트 너비 + 여백
        int bitmapHeight = (bounds.height() * 3) + 100; // 텍스트 높이 + 여백

        // 비트맵 생성
        Bitmap bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);

        // 투명 배경 초기화
        canvas.drawColor(Color.TRANSPARENT);

        // 텍스트를 비트맵 안쪽으로 이동시켜 오른쪽 정렬 (비트맵 끝에서 텍스트 폭만큼 여백을 추가)
        canvas.drawText(userID, bitmapWidth - 20, bitmapHeight / 3 - bounds.height(), paint);  // 첫번째 줄
        canvas.drawText(patientInformation, bitmapWidth - 20, bitmapHeight / 3 + bounds.height(), paint);  // 두번째 줄
        canvas.drawText(dateTime, bitmapWidth - 20, bitmapHeight / 3 + bounds.height() * 3, paint);  // 세번째 줄


        // 텍스처 생성 및 바인딩
        int[] textureIds = new int[1];
        GLES20.glGenTextures(1, textureIds, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureIds[0]);

        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);

        // 텍스처 업로드 (GL_RGBA 및 GL_UNSIGNED_BYTE 사용)
        ByteBuffer buffer = ByteBuffer.allocateDirect(bitmapWidth * bitmapHeight * 4);
        bitmap.copyPixelsToBuffer(buffer);
        buffer.position(0);

        GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, bitmapWidth, bitmapHeight, 0,
                GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buffer);

        bitmap.recycle();
        return textureIds[0];
    }


    private void drawTexture(int textureId) {
        float[] vertices = {
                0.0f, -0.6f, 0.0f,  // 왼쪽 상단
                0.0f, -0.9f, 0.0f,  // 왼쪽 하단
                1.0f, -0.9f, 0.0f,  // 오른쪽 하단
                1.0f, -0.6f, 0.0f   // 오른쪽 상단
        };

        float[] textureCoords = {
                0.0f, 0.0f,  // 왼쪽 상단
                0.0f, 1.0f,  // 왼쪽 하단
                1.0f, 1.0f,  // 오른쪽 하단
                1.0f, 0.0f   // 오른쪽 상단
        };

        short[] drawOrder = {0, 1, 2, 0, 2, 3};

        FloatBuffer vertexBuffer = ByteBuffer
                .allocateDirect(vertices.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        vertexBuffer.put(vertices).position(0);

        FloatBuffer textureBuffer = ByteBuffer
                .allocateDirect(textureCoords.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        textureBuffer.put(textureCoords).position(0);

        ShortBuffer drawListBuffer = ByteBuffer
                .allocateDirect(drawOrder.length * 2)
                .order(ByteOrder.nativeOrder())
                .asShortBuffer();
        drawListBuffer.put(drawOrder).position(0);

        int shaderProgram = createShaderProgram();

        GLES20.glUseProgram(shaderProgram);

        int positionHandle = GLES20.glGetAttribLocation(shaderProgram, "vPosition");
        GLES20.glEnableVertexAttribArray(positionHandle);
        GLES20.glVertexAttribPointer(
                positionHandle, 3, GLES20.GL_FLOAT, false,
                0, vertexBuffer);

        int texCoordHandle = GLES20.glGetAttribLocation(shaderProgram, "aTexCoord");
        GLES20.glEnableVertexAttribArray(texCoordHandle);
        GLES20.glVertexAttribPointer(
                texCoordHandle, 2, GLES20.GL_FLOAT, false,
                0, textureBuffer);

        int textureUniform = GLES20.glGetUniformLocation(shaderProgram, "uTexture");
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
        GLES20.glUniform1i(textureUniform, 0);

        GLES20.glDrawElements(
                GLES20.GL_TRIANGLES, drawOrder.length,
                GLES20.GL_UNSIGNED_SHORT, drawListBuffer);

        GLES20.glDisableVertexAttribArray(positionHandle);
        GLES20.glDisableVertexAttribArray(texCoordHandle);
    }

    private int createShaderProgram() {
        String vertexShaderCode =
                "attribute vec4 vPosition;" +
                        "attribute vec2 aTexCoord;" +
                        "varying vec2 vTexCoord;" +
                        "void main() {" +
                        "  gl_Position = vPosition;" +
                        "  vTexCoord = aTexCoord;" +
                        "}";

        String fragmentShaderCode =
                "precision mediump float;" +
                        "uniform sampler2D uTexture;" +
                        "varying vec2 vTexCoord;" +
                        "void main() {" +
                        "  vec4 color = texture2D(uTexture, vTexCoord);" +
                        "  if (color.a < 0.1) discard;" +  // 투명도 임계값 설정
                        "  gl_FragColor = vec4(color.rgb, color.a);" +
                        "}";

        int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexShaderCode);
        int fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentShaderCode);

        int program = GLES20.glCreateProgram();
        GLES20.glAttachShader(program, vertexShader);
        GLES20.glAttachShader(program, fragmentShader);
        GLES20.glLinkProgram(program);

        return program;
    }

    private int loadShader(int type, String shaderCode) {
        int shader = GLES20.glCreateShader(type);
        GLES20.glShaderSource(shader, shaderCode);
        GLES20.glCompileShader(shader);
        return shader;
    }

}
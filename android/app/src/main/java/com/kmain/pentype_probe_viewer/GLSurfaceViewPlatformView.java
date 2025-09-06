package com.kmain.pentype_probe_viewer;

import static com.kmain.pentype_probe_viewer.StreamConstants.VIDEO_HEGIHT;
import static com.kmain.pentype_probe_viewer.StreamConstants.VIDEO_WIDTH;

import android.graphics.Bitmap;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.content.Context;
import android.util.Base64;
import android.view.View;
import android.view.ViewGroup;

import java.util.Map;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import java.io.ByteArrayOutputStream;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import android.util.Log;

import io.flutter.plugin.platform.PlatformView;

import androidx.annotation.NonNull;

import java.util.Arrays; // Arrays 클래스를 임포트
import java.nio.charset.StandardCharsets; // StandardCharsets 클래스를 임포트


class GLSurfaceViewPlatformView implements PlatformView {
    private final GLSurfaceView glSurfaceView;

    GLSurfaceViewPlatformView(Context context, Map<String, Object> params, ProbeRenderer probeRenderer) {
        glSurfaceView = new GLSurfaceView(context);
        glSurfaceView.setEGLContextClientVersion(2); // OpenGL ES 2.0
        glSurfaceView.setRenderer(probeRenderer);

        // 렌더링 크기 고정 (1280x720)
        glSurfaceView.getHolder().setFixedSize(VIDEO_WIDTH, VIDEO_HEGIHT);

        // 화면에 맞게 최대화 (Flutter에서 관리)
        ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        glSurfaceView.setLayoutParams(layoutParams);
    }

    @NonNull
    @Override
    public View getView() {
        return glSurfaceView;
    }

    @Override
    public void dispose() {
    }

    // 캡처 메서드 추가
    private Bitmap capture() {
        final int width = 1280;
        final int height = 720;

        int size = width * height;
        ByteBuffer buffer = ByteBuffer.allocateDirect(size * 4);
        buffer.order(ByteOrder.nativeOrder());

        final boolean[] captureCompleted = {false};

        glSurfaceView.queueEvent(() -> {
            GLES20.glFinish(); // 렌더링 완료 보장
            GLES20.glReadPixels(0, 0, width, height, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buffer);
            synchronized (captureCompleted) {
                captureCompleted[0] = true;
                captureCompleted.notifyAll();
            }
        });

        synchronized (captureCompleted) {
            while (!captureCompleted[0]) {
                try {
                    captureCompleted.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }

        int[] pixels = new int[size];
        buffer.asIntBuffer().get(pixels);

        // OpenGL의 기본 색상 순서를 ARGB로 변환
        for (int i = 0; i < size; i++) {
            int color = pixels[i];

            // ABGR -> ARGB 변환
            int alpha = (color >> 24) & 0xFF;
            int red = (color) & 0xFF;
            int green = (color >> 8) & 0xFF;
            int blue = (color >> 16) & 0xFF;

            pixels[i] = (alpha << 24) | (red << 16) | (green << 8) | blue;
        }

        // OpenGL Y축 데이터 뒤집기
        int[] invertedPixels = new int[size];
        for (int i = 0; i < height; i++) {
            System.arraycopy(pixels, i * width, invertedPixels, (height - 1 - i) * width, width);
        }

        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        bitmap.setPixels(invertedPixels, 0, width, 0, 0, width, height);
        return bitmap;
    }

    public long saveBitmapToEncryptedFile(File file, byte[] dek, byte[] iv) {
        Bitmap bitmap = capture();
        ByteArrayOutputStream byteStream = new ByteArrayOutputStream();

        try {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteStream);
            byte[] plainBytes = byteStream.toByteArray();

            SecretKeySpec keySpec = new SecretKeySpec(dek, "AES");
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec gcmSpec = new GCMParameterSpec(128, iv);
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, gcmSpec);

            byte[] encryptedBytes = cipher.doFinal(plainBytes);
            FileOutputStream fos = new FileOutputStream(file);
            fos.write(encryptedBytes);
            fos.flush();
            fos.close();

            // 파일 크기 반환
            return file.length();  // Byte 단위 크기

        } catch (SecurityException se) {
            // 보안 예외
            Log.e("GLSurfaceViewPlatformView", "파일 접근 권한 오류", se);
            // 필요 시 상위로 예외를 던지거나 별도 처리
        } catch (IOException ioe) {
            // 입출력 예외
            Log.e("GLSurfaceViewPlatformView", "파일 처리 중 오류", ioe);
            // 필요 시 상위로 예외를 던지거나 별도 처리
        } catch (Exception e) {
            // 예상치 못한 예외
            Log.e("GLSurfaceViewPlatformView", "알 수 없는 오류 발생", e);
            // 필요 시 상위로 예외를 던지거나 별도 처리
        }
        return -1;  // 실패 시 -1 반환
    }
}
package com.kmain.pentype_probe_viewer;

import android.content.Context;

import java.util.Map;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;


public class GLSurfaceViewFactory extends PlatformViewFactory {
    private final ProbeRenderer probeRenderer;
    private GLSurfaceViewPlatformView glSurfaceViewPlatformView;
    public GLSurfaceViewFactory(ProbeRenderer probeRenderer) {
        super(StandardMessageCodec.INSTANCE);
        this.probeRenderer = probeRenderer;
    }

    @NonNull
    public GLSurfaceViewPlatformView create(@NonNull Context context, int id, Object args) {
        Map<String, Object> params = (Map<String, Object>) args;
        glSurfaceViewPlatformView = new GLSurfaceViewPlatformView(context, params, probeRenderer);
        return glSurfaceViewPlatformView;
    }

    public GLSurfaceViewPlatformView getGLSurfaceViewPlatformView() {
        return glSurfaceViewPlatformView;
    }
}

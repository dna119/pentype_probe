/*
 * Copyright 2014 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.android.grafika.gles;

import android.opengl.Matrix;
import android.util.Log;

/**
 * Base class for a 2d object.  Includes position, scale, rotation, and flat-shaded color.
 */
public class Sprite2d {
    private static final String TAG = GlUtil.TAG;

    private Drawable2d mDrawable;
    private float mColor[];
    private int mTextureId;
    private float mAngle;
    private float mScaleX, mScaleY;
    private float mPosX, mPosY;

    private float[] mModelViewMatrix;
    private boolean mMatrixReady;

    private float[] mScratchMatrix = new float[16];

    public Sprite2d(Drawable2d drawable) {
        mDrawable = drawable;
        mColor = new float[4];
        mColor[3] = 1.0f;
        mTextureId = -1;

        mModelViewMatrix = new float[16];
        mMatrixReady = false;
    }

    /**
     * Re-computes mModelViewMatrix, based on the current values for rotation, scale, and
     * translation.
     */
    private void recomputeMatrix() {
        float[] modelView = mModelViewMatrix;

        Matrix.setIdentityM(modelView, 0);
        Matrix.translateM(modelView, 0, mPosX, mPosY, 0.0f);
        if (mAngle != 0.0f) {
            Matrix.rotateM(modelView, 0, mAngle, 0.0f, 0.0f, 1.0f);
        }
        Matrix.scaleM(modelView, 0, mScaleX, mScaleY, 1.0f);
        mMatrixReady = true;
    }

    /**
     * Returns the sprite scale along the X axis.
     */
    public float getScaleX() {
        return mScaleX;
    }

    /**
     * Returns the sprite scale along the Y axis.
     */
    public float getScaleY() {
        return mScaleY;
    }

    /**
     * Sets the sprite scale (size).
     */
    public void setScale(float scaleX, float scaleY) {
        // 유효성 검사
        if (Float.isNaN(scaleX) || Float.isInfinite(scaleX) ||
                Float.isNaN(scaleY) || Float.isInfinite(scaleY)) {
            throw new IllegalArgumentException(
                    "Invalid scale values: scaleX=" + scaleX + ", scaleY=" + scaleY
            );
        }

        // (선택) 음수나 0 방지
        if (scaleX <= 0.0f || scaleY <= 0.0f) {
            throw new IllegalArgumentException(
                    "Scale must be > 0. Provided: scaleX=" + scaleX + ", scaleY=" + scaleY
            );
        }

        mScaleX = scaleX;
        mScaleY = scaleY;
        mMatrixReady = false;
    }

    /**
     * Gets the sprite rotation angle, in degrees.
     */
    public float getRotation() {
        return mAngle;
    }

    /**
     * Sets the sprite rotation angle, in degrees.  Sprite will rotate counter-clockwise.
     */
    public void setRotation(float angle) {
        // 유효성 검사
        if (Float.isNaN(angle) || Float.isInfinite(angle)) {
            throw new IllegalArgumentException("Invalid angle value: " + angle);
        }

        // Normalize
        while (angle >= 360.0f) {
            angle -= 360.0f;
        }
        while (angle <= -360.0f) {
            angle += 360.0f;
        }

        mAngle = angle;
        mMatrixReady = false;
    }

    /**
     * Returns the position on the X axis.
     */
    public float getPositionX() {
        return mPosX;
    }

    /**
     * Returns the position on the Y axis.
     */
    public float getPositionY() {
        return mPosY;
    }

    /**
     * Sets the sprite position.
     */
    public void setPosition(float posX, float posY) {
        // NaN, Infinite 값 방지
        if (Float.isNaN(posX) || Float.isInfinite(posX) ||
                Float.isNaN(posY) || Float.isInfinite(posY)) {
            throw new IllegalArgumentException("Invalid position values: posX=" + posX + ", posY=" + posY);
        }

        // (선택) 범위를 제한하고 싶다면 clamp
        // 예: -1.0f ~ 1.0f 범위
        posX = Math.max(-1.0f, Math.min(1.0f, posX));
        posY = Math.max(-1.0f, Math.min(1.0f, posY));

        mPosX = posX;
        mPosY = posY;
        mMatrixReady = false;
    }

    /**
     * Returns the model-view matrix.
     * <p>
     * To avoid allocations, this returns internal state.  The caller must not modify it.
     */
    public float[] getModelViewMatrix() {
        if (!mMatrixReady) {
            recomputeMatrix();
        }
        return mModelViewMatrix.clone();  // 내부 배열을 복사해서 반환
    }

    /**
     * Sets color to use for flat-shaded rendering.  Has no effect on textured rendering.
     */
    public void setColor(float red, float green, float blue) {
        mColor[0] = red;
        mColor[1] = green;
        mColor[2] = blue;
    }

    /**
     * Sets texture to use for textured rendering.  Has no effect on flat-shaded rendering.
     */
    public void setTexture(int textureId) {
        if (textureId < 0) {
            throw new IllegalArgumentException("Texture ID must be >= 0. Provided: " + textureId);
        }
        mTextureId = textureId;
    }


    /**
     * Returns the color.
     * <p>
     * To avoid allocations, this returns internal state.  The caller must not modify it.
     */
    public float[] getColor() {
        return mColor.clone(); }

    /**
     * Draws the rectangle with the supplied program and projection matrix.
     */
    public void draw(FlatShadedProgram program, float[] projectionMatrix) {
        // Compute model/view/projection matrix.
        Matrix.multiplyMM(mScratchMatrix, 0, projectionMatrix, 0, getModelViewMatrix(), 0);

        program.draw(mScratchMatrix, mColor, mDrawable.getVertexArray(), 0,
                mDrawable.getVertexCount(), mDrawable.getCoordsPerVertex(),
                mDrawable.getVertexStride());
    }

    /**
     * Draws the rectangle with the supplied program and projection matrix.
     */
    public void draw(Texture2dProgram program, float[] projectionMatrix) {
        // Compute model/view/projection matrix.
        Matrix.multiplyMM(mScratchMatrix, 0, projectionMatrix, 0, getModelViewMatrix(), 0);

        program.draw(mScratchMatrix, mDrawable.getVertexArray(), 0,
                mDrawable.getVertexCount(), mDrawable.getCoordsPerVertex(),
                mDrawable.getVertexStride(), GlUtil.getIdentityMatrix(), mDrawable.getTexCoordArray(),
                mTextureId, mDrawable.getTexCoordStride());
    }

    @Override
    public String toString() {
        return "[Sprite2d pos=" + mPosX + "," + mPosY +
                " scale=" + mScaleX + "," + mScaleY + " angle=" + mAngle +
                " color={" + mColor[0] + "," + mColor[1] + "," + mColor[2] +
                "} drawable=" + mDrawable + "]";
    }
}

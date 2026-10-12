package com.hongguo.tv;

public final class UpdateInstallSession {
    private int request;
    private boolean launched;
    private boolean left;
    private boolean resumed;

    public void begin(int value) {
        if (request != 0) throw new IllegalStateException("安装器正在忙碌");
        request = value;
        launched = false;
        left = false;
    }

    public boolean launch(int value) {
        if (request != value || request == 0) return false;
        launched = true;
        return true;
    }

    public void pause() { resumed = false; if (launched) left = true; }
    public int resume() { resumed = true; return launched && left ? request : 0; }
    public boolean canReturn(int value) { return matches(value) && left && resumed; }
    public boolean matches(int value) { return value != 0 && request == value && launched; }
    public boolean complete(int value) {
        if (request != value || request == 0) return false;
        request = 0;
        launched = false;
        left = false;
        return true;
    }
}

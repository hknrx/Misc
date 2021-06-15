LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_CFLAGS += -std=c99
LOCAL_MODULE := Liquid
LOCAL_SRC_FILES := Liquid.c

include $(BUILD_SHARED_LIBRARY)

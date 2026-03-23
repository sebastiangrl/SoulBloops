/**
 * Vibración en Android vía JNI + SDL (Heaps/hlsdl suele enlazar SDL2).
 * Sin cabeceras SDL en el include path: las funciones quedan en no-op (enlazan igual).
 */
#include <jni.h>

#if defined(__ANDROID__)

#if defined(__has_include)
#if __has_include(<SDL_system.h>)
#include <SDL_system.h>
#define HXCPP_HAPTICS_SDL 1
#elif __has_include(<SDL2/SDL_system.h>)
#include <SDL2/SDL_system.h>
#define HXCPP_HAPTICS_SDL 1
#endif
#endif

#endif

#if defined(__ANDROID__) && defined(HXCPP_HAPTICS_SDL)

static JNIEnv *hx_android_env() {
	return (JNIEnv *)SDL_AndroidGetJNIEnv();
}

static jobject hx_android_activity() {
	return (jobject)SDL_AndroidGetActivity();
}

static void vibrate_one_shot(JNIEnv *env, jobject activity, jlong ms) {
	if (env == nullptr || activity == nullptr)
		return;
	jclass actCls = env->GetObjectClass(activity);
	if (actCls == nullptr)
		return;
	jmethodID getSys = env->GetMethodID(actCls, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;");
	if (getSys == nullptr)
		return;
	jstring key = env->NewStringUTF("vibrator");
	if (key == nullptr)
		return;
	jobject vibObj = env->CallObjectMethod(activity, getSys, key);
	env->DeleteLocalRef(key);
	if (vibObj == nullptr)
		return;
	jclass vibCls = env->GetObjectClass(vibObj);
	jmethodID vMs = env->GetMethodID(vibCls, "vibrate", "(J)V");
	if (vMs != nullptr)
		env->CallVoidMethod(vibObj, vMs, ms);
	env->DeleteLocalRef(vibObj);
}

static void vibrate_pattern(JNIEnv *env, jobject activity, const jlong *pat, jsize len) {
	if (env == nullptr || activity == nullptr || len < 2)
		return;
	jclass actCls = env->GetObjectClass(activity);
	if (actCls == nullptr)
		return;
	jmethodID getSys = env->GetMethodID(actCls, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;");
	if (getSys == nullptr)
		return;
	jstring key = env->NewStringUTF("vibrator");
	jobject vibObj = env->CallObjectMethod(activity, getSys, key);
	env->DeleteLocalRef(key);
	if (vibObj == nullptr)
		return;
	jclass vibCls = env->GetObjectClass(vibObj);
	jmethodID vPat = env->GetMethodID(vibCls, "vibrate", "([JI)V");
	if (vPat == nullptr) {
		env->DeleteLocalRef(vibObj);
		return;
	}
	jlongArray arr = env->NewLongArray(len);
	if (arr == nullptr) {
		env->DeleteLocalRef(vibObj);
		return;
	}
	env->SetLongArrayRegion(arr, 0, len, pat);
	env->CallVoidMethod(vibObj, vPat, arr, -1);
	env->DeleteLocalRef(arr);
	env->DeleteLocalRef(vibObj);
}

extern "C" void hxcpp_android_haptics_place() {
	JNIEnv *env = hx_android_env();
	jobject act = hx_android_activity();
	vibrate_one_shot(env, act, 10);
}

extern "C" void hxcpp_android_haptics_clear_single() {
	JNIEnv *env = hx_android_env();
	jobject act = hx_android_activity();
	vibrate_one_shot(env, act, 22);
}

extern "C" void hxcpp_android_haptics_clear_combo() {
	JNIEnv *env = hx_android_env();
	jobject act = hx_android_activity();
	static const jlong pat[] = {0, 15, 35, 20, 40, 25};
	vibrate_pattern(env, act, pat, (jsize)(sizeof(pat) / sizeof(pat[0])));
}

#else

extern "C" void hxcpp_android_haptics_place() {}
extern "C" void hxcpp_android_haptics_clear_single() {}
extern "C" void hxcpp_android_haptics_clear_combo() {}

#endif

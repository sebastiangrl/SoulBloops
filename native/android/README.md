# Vibración Android (hxcpp + SDL)

## Permiso

En el `AndroidManifest.xml` de tu app:

```xml
<uses-permission android:name="android.permission.VIBRATE" />
```

## Cómo funciona

`hxcpp_android_haptics.cpp` usa **JNI** y `SDL_AndroidGetJNIEnv` / `SDL_AndroidGetActivity()` (SDL2). Es el mismo enfoque que muchos juegos Heaps con **hlsdl** en Android.

- Si el compilador encuentra `SDL_system.h` o `SDL2/SDL_system.h`, se define `HXCPP_HAPTICS_SDL` y la vibración es real.
- Si no (build sin SDL en el include path), el `.cpp` enlaza **stubs vacíos**: no rompe el link, pero no vibrará hasta que añadas las cabeceras SDL al NDK.

## Include SDL (NDK)

En tu `Application.mk`, flags del módulo nativo o `build.xml` de hxcpp, añade el directorio de includes de SDL2, por ejemplo:

```
-I$(SDL_ROOT)/include
```

(o la ruta que use tu plantilla Heaps / HashLink-port a cpp).

## Build Haxe

Ejemplo (ajusta rutas y libs):

```bash
haxe -cp src -main Main -lib heaps -cpp bin/cpp -D android -lib hxcpp
```

Define `-D android` para activar las llamadas JNI en [Haptics.hx](../../src/game/Haptics.hx) (ver [build.hxml](../../build.hxml)).

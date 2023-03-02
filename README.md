# Demo of packaging a JCEF app with Conveyor

## What is this?

CEF is the Chromium Embedded Framework. It lets you use Chrome/Chromium as a library.

JCEF is the Java CEF, a binding of CEF into Java.

JCEF Maven is a JAR of JCEF that can be integrated as a normal JVM dependency. It downloads and "installs" CEF on the fly to a cache directory.

Conveyor is a packaging tool that makes it convenient to ship desktop apps. It supports many types of app but has special support for JVM apps.
It can code sign and notarize apps for macOS and Windows from any platform, including Linux.

This repository shows how to ship an app that use JCEF Maven with Conveyor.

## Caveats

1. Currently only working on macOS.
2. You must build with `build.sh` which works around various bugs and limits in Conveyor, mostly related to weirdness in how JCEF is distributed.

Windows/Linux will hopefully come soon.

## Initializing JCEF

You need a bit of boilerplate code when you initialize JCEF. Look at `Main.kt` for this section:

```kotlin
val appDir: File = run {
    val macFrameworksDir: String? = System.getProperty("app.dir.mac.frameworks")
    if (macFrameworksDir != null) {
        File(macFrameworksDir).also { check(it.resolve("jcef Helper.app").exists()) }
    } else {
        File("./jcef-bundle")
    }
}

val builder = CefAppBuilder()
builder.setInstallDir(appDir)
```

When run outside of a packaged app, this will initialize JCEF in the normal way. It'll download the JCEF native binaries for your
platform. When run inside a packaged app, it'll find the pre-extracted location using a system property.

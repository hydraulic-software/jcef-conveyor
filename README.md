# Demo of packaging a JCEF app with Conveyor

## What is this?

CEF is the Chromium Embedded Framework. It lets you use Chrome/Chromium as a library.

JCEF is the Java CEF, a binding of CEF into Java.

JCEF Maven is a JAR of JCEF that can be integrated as a normal JVM dependency. It downloads and "installs" CEF on the fly to a cache directory.

Conveyor is a packaging tool that makes it convenient to ship desktop apps. It supports many types of app but has special support for JVM apps.
It can code sign and notarize apps for macOS and Windows from any platform, including Linux.

This repository shows how to ship an app that use JCEF Maven with Conveyor.

## Caveats

1. Currently the app only works on macOS and Windows.
2. You must build on UNIX (this is because the `from-maven.conf` doesn't work on Windows yet, not any fundamental incompatibility, you could provide the classpath separately).
3. You must build with `build.sh` which works around various bugs and limits in Conveyor, mostly related to weirdness in how JCEF is distributed.

Linux support and Windows building will hopefully come soon.

## Initializing JCEF

You need a bit of boilerplate code when you initialize JCEF. Look at `Main.kt` for this section:

```kotlin
val jcefDir: File = run {
    val appDir: String? = System.getProperty("app.dir")
    if (appDir != null) {
        // Packaged with Conveyor
        val os = System.getProperty("os.name").lowercase()
        if (os.startsWith("mac")) {
            File(appDir).resolve("../Frameworks").also { check(it.resolve("jcef Helper.app").exists()) }
        } else if (os.startsWith("windows")) {
            File(appDir).resolve("jcef").also { check(it.resolve("jcef.dll").exists()) }
        } else {
            TODO("Linux")
        }
    } else {
        // Dev mode.
        File("./jcef-bundle")
    }
}

val builder = CefAppBuilder()
builder.setInstallDir(jcefDir)
```

When run outside of a packaged app, this will initialize JCEF in the normal way. It'll download the JCEF native binaries for your
platform. When run inside a packaged app, it'll find the pre-extracted location using a system property.

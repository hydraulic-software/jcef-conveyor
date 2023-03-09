# Demo of packaging a JCEF app with Conveyor

## What is this?

CEF is the Chromium Embedded Framework. It lets you use Chrome/Chromium as a library.

JCEF is the Java CEF, a binding of CEF into Java.

JCEF Maven is a JAR of JCEF that can be integrated as a normal JVM dependency. It downloads and "installs" CEF on the fly to a cache directory.

Conveyor is a packaging tool that makes it convenient to ship desktop apps. It supports many types of app but has special support for JVM apps.
It can code sign and notarize apps for macOS and Windows from any platform, including Linux.

This repository shows how to ship an app that use JCEF Maven with Conveyor.

## Initializing JCEF

You need a bit of boilerplate code when you initialize JCEF. Look at `Main.kt` for this section:

```kotlin
val jcefDir: File = run {
    val appDir: String? = System.getProperty("app.dir")
    if (appDir != null) {
        // Packaged with Conveyor
        val os = System.getProperty("os.name").lowercase()
        if (os.startsWith("mac")) {
            File(appDir).resolve("../Frameworks").normalize().also { check(it.resolve("jcef Helper.app").exists()) }
        } else if (os.startsWith("windows")) {
            File(appDir).resolve("jcef").also { check(it.resolve("jcef.dll").exists()) }
        } else {
            File(appDir).resolve("jcef").also { check(it.resolve("libjcef.so").exists()) }
        }
    } else {
        // Dev mode.
        File("./jcef-bundle")
    }
}

val builder = CefAppBuilder()
builder.setInstallDir(jcefDir)
```

**IMPORTANT:** You must normalize the path on macOS as Chrome will throw lots of errors and you'll get corrupted rendering if there is a .. in the install dir. 

When run outside of a packaged app, this will initialize JCEF in the normal way. It'll download the JCEF native binaries for your
platform. When run inside a packaged app it'll find the pre-extracted location using a system property.

## Tricks used in conveyor.conf

JCEF requires some fairly sophisticated config. It requires at least Conveyor 7.2. Pay attention to these parts:

1. The JCEF natives are extracted from a tarball that is itself inside a jar file. This is done by exploiting the fact that Conveyor can be pointed at files inside zips using the `zip:` protocol scheme, and additionally, that archives are extracted by default when used as inputs.
2. We specify extra Mac metadata that makes Chrome work better.
3. JCEF accesses internal Java APIs. We whitelist those using JVM options in the `build.gradle.kts` file, and this is propagated to Conveyor by the Gradle plugin. This is optional because Conveyor would auto-detect these for us, but doing so explicitly suppresses the warning that's generated when it does.
4. On Windows the JCEF natives are placed in a subdirectroy of the app dir called `jcef`, this keeps it separated from the main app JARs and avoids problems. 
5. JCEF Maven expects a file called `install.lock` to exist in the natives dir, but the tarball doesn't contain it. We create it using an input definition.

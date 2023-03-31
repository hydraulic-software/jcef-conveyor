/**
 * Apache 2 licensed. Feel free to copy into your codebase.
 */

package conveyor;

import me.friwi.jcefmaven.CefAppBuilder;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class JCefSetup {
    public static CefAppBuilder builder() {
        Path jcefDir = getJcefDir();
        CefAppBuilder builder = new CefAppBuilder();
        builder.setInstallDir(jcefDir.toFile());
        return builder;
    }

    private static Path getJcefDir() {
        String appDir = System.getProperty("app.dir");
        if (appDir == null) {
            // Dev mode
            return Paths.get("./jcef-bundle");
        }

        // Packaged with Conveyor
        String os = System.getProperty("os.name").toLowerCase();
        Path appDirPath = Paths.get(appDir);
        if (os.startsWith("mac")) {
            Path jcefDir = appDirPath.resolve("../Frameworks").normalize();
            if (!Files.exists(jcefDir.resolve("jcef Helper.app"))) {
                throw new IllegalStateException("jcef Helper.app not found");
            }
            return jcefDir;
        } else if (os.startsWith("windows")) {
            Path jcefDir = appDirPath.resolve("jcef");
            if (!Files.exists(jcefDir.resolve("jcef.dll"))) {
                throw new IllegalStateException("jcef.dll not found");
            }
            return jcefDir;
        } else {
            Path jcefDir = appDirPath.resolve("jcef");
            if (!Files.exists(jcefDir.resolve("libjcef.so"))) {
                throw new IllegalStateException("libjcef.so not found");
            }
            return jcefDir;
        }
    }
}

///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS info.picocli:picocli:4.6.3
//DEPS 'com.fasterxml.jackson.core:jackson-databind:2.18.3'

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Parameters;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.concurrent.Callable;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.json.JsonReadFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;

@Command(name = "sync", mixinStandardHelpOptions = true, version = "sync 0.1", description = "Reads the manifest file and creates symlink")
class sync implements Runnable {

    public static void main(String... args) {
        int exitCode = new CommandLine(new sync()).execute(args);
        System.exit(exitCode);
    }

    // Path to home directory
    Path homePath = Path.of(System.getProperty("user.home"));

    File pathToManifest = new File(homePath.toString() + "/dots1/manifest.jsonc");

    @Override
    public void run() { // your business logic goes here...
        try {
            // Create json object mapper
            JsonFactory factory = JsonFactory.builder().enable(JsonReadFeature.ALLOW_JAVA_COMMENTS)
                    .enable(JsonReadFeature.ALLOW_TRAILING_COMMA).build();
            ObjectMapper mapper = new ObjectMapper(factory);

            System.out.println(pathToManifest.toString());

            // fetch fields from manifest as an Jackson Array node
            ArrayNode nodes = (ArrayNode) mapper.readTree(pathToManifest);

            for (var node : nodes) {

                String sourcePath = node.get("source").toString().replace("\"", "");
                String targetPath = node.get("target").toString().replace("\"", "");

                String fullTargetPath = homePath + "/" + targetPath;

                System.out.println(fullTargetPath);

                Path targetFilePath = Path.of(fullTargetPath);

                if (!Files.exists(Path.of(sourcePath))) {
                    System.out.println("File not found: " + sourcePath);
                    continue;
                }

                if (Files.exists(targetFilePath) && !Files.isSymbolicLink(targetFilePath)) {
                    // create backup of the existing target file
                    Files.move(targetFilePath, Path.of(fullTargetPath + ".bak"),
                            StandardCopyOption.REPLACE_EXISTING);

                    System.out.println("deleted and created: " + targetPath);
                    Files.createSymbolicLink(targetFilePath, Path.of(sourcePath));

                    continue;
                }

                Files.createSymbolicLink(targetFilePath, Path.of(sourcePath));

            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }

    }
}

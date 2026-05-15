///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS info.picocli:picocli:4.7.7
//DEPS 'com.fasterxml.jackson.core:jackson-databind:2.18.3'

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Parameters;

import java.io.File;
import java.nio.file.FileAlreadyExistsException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.json.JsonReadFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

@Command(name = "dots", mixinStandardHelpOptions = true, version = "dots 0.1", description = "Script for maintaining dotsfile", subcommands = {
        Dots.Add.class,
        Dots.Sync.class
})
class Dots implements Runnable {
    public static void main(String... args) {
        int exitCode = new CommandLine(new Dots()).execute(args);
        System.exit(exitCode);
    }

    // Path to home directory
    Path homePath = Path.of(System.getProperty("user.home"));

    @Override
    public void run() {
        new CommandLine(this).usage(System.out);
    }

    // -- subcommand: add
    @Command(name = "add", mixinStandardHelpOptions = true, version = "save 0.1", description = "Save a given file to the dotfiles repo")
    static class Add extends DotsOption implements Runnable {

        @Parameters(index = "0", description = "Path to The file to save in the dot files", defaultValue = "World!")
        private File file;

        /*
         * Target Path: path of the file we are trying to save in the dotfile
         *
         * Source Path: path of the target file in the dotfiles directory
         */

        @Override
        public void run() {
            try {
                Path fileAbsolutePath = Path.of(file.getAbsolutePath()).normalize();
                Path targetPath = getHomePath().relativize(fileAbsolutePath);

                String source = getHomePath() + "/dotfiles/" + targetPath.toString().trim();
                String target = fileAbsolutePath.toString().trim();

                Path sourcePath = Path.of(source);

                System.out.println(String.format("Source = %s | Target = %s", source, target));

                if (Files.exists(sourcePath.normalize())) {
                    System.out.println(
                            "cannot add " + fileAbsolutePath.getFileName().toString()
                                    + ": file already in dotfiles repo");
                } else if (!Files.isRegularFile(fileAbsolutePath)) {
                    System.out.println(
                            "cannot add " + fileAbsolutePath.getFileName().toString() + ": file is not a regular file");
                } else {
                    // create parent directories
                    Files.createDirectories(sourcePath.normalize().getParent());

                    // move the target file to the source
                    Files.move(fileAbsolutePath, sourcePath, StandardCopyOption.REPLACE_EXISTING);

                    // // create a symlink of source file to target
                    Files.createSymbolicLink(fileAbsolutePath, sourcePath);

                    addPathToManifest(sourcePath, targetPath, getHomePath().toString());

                    System.out.printf(
                            "\n\nsuccessfully saved %s. A symlink has been created in "
                                    + fileAbsolutePath.getParent().toString(),
                            targetPath.getFileName().toString());

                }

            } catch (FileAlreadyExistsException e) {
                System.out.println("File: " + e.getFile() + " already exist");
            } catch (NoSuchFileException e) {
                System.out.println("No such file: " + e.getFile());
            } catch (Exception e) {
                System.out.println(e.getMessage());
            }

        }
    }

    // subcommand: sync
    @Command(name = "sync", mixinStandardHelpOptions = true, version = "sync 0.1", description = "Reads the manifest file and creates symlink")
    static class Sync extends DotsOption implements Runnable {
        @Override
        public void run() { // your business logic goes here...
            try {
                // Create json object mapper
                JsonFactory factory = JsonFactory.builder().enable(JsonReadFeature.ALLOW_JAVA_COMMENTS)
                        .enable(JsonReadFeature.ALLOW_TRAILING_COMMA).build();
                ObjectMapper mapper = new ObjectMapper(factory);

                // fetch fields from manifest as an Jackson Array node
                ArrayNode nodes = (ArrayNode) mapper.readTree(getManifestPath().toFile());

                for (var node : nodes) {

                    String sourcePath = node.get("source").toString().replace("\"", "");
                    String targetPath = node.get("target").toString().replace("\"", "");

                    String fullTargetPath = getHomePath() + "/" + targetPath;

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

    // ------------------Helper class----------------------------------
    static class DotsOption {
        // Path to home directory
        private Path homePath = Path.of(System.getProperty("user.home"));
        private Path pathToManifest = Path.of(homePath.toString() + "/dotfiles/manifest.jsonc");

        public Path getHomePath() {
            return this.homePath;
        }

        public Path getManifestPath() {
            return this.pathToManifest;
        }

        void addPathToManifest(Path sourcePath, Path targetPath, String homePath) throws Exception {

            JsonFactory factory = JsonFactory.builder().enable(JsonReadFeature.ALLOW_JAVA_COMMENTS)
                    .enable(JsonReadFeature.ALLOW_TRAILING_COMMA).build();
            ObjectMapper mapper = new ObjectMapper(factory);

            ObjectNode node = mapper.createObjectNode();

            node.put("source", sourcePath.toString().trim());
            node.put("target", targetPath.toString().trim());
            ArrayNode array;

            if (!Files.exists(pathToManifest)) {
                Files.createFile(pathToManifest);
                array = mapper.createArrayNode();
            } else {
                array = (ArrayNode) mapper.readTree(pathToManifest.toFile());
            }
            array.add(node);
            mapper.writerWithDefaultPrettyPrinter().writeValue(pathToManifest.toFile(), array);

        }
    }
}
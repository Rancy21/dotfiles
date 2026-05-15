///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS info.picocli:picocli:4.7.7
//DEPS 'com.fasterxml.jackson.core:jackson-databind:2.18.3'

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Parameters;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
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

@Command(name = "add", mixinStandardHelpOptions = true, version = "save 0.1", description = "Save a given file to the dotfiles repo")
class add implements Runnable {

    @Parameters(index = "0", description = "Path to The file to save in the dot files", defaultValue = "World!")
    private File file;

    // Path to home directory
    Path homePath = Path.of(System.getProperty("user.home"));

    public static void main(String... args) {

        int exitCode = new CommandLine(new add()).execute(args);
        System.exit(exitCode);
    }

    /*
     * Target Path: path of the file we are trying to save in the dotfile
     *
     * Source Path: path of the target file in the dotfiles directory
     */

    @Override
    public void run() {
        try {
            Path fileAbsolutePath = Path.of(file.getAbsolutePath()).normalize();
            Path targetPath = homePath.relativize(fileAbsolutePath);

            String source = homePath + "/dots1/" + targetPath.toString().trim();
            String target = fileAbsolutePath.toString().trim();

            Path sourcePath = Path.of(source);

            System.out.println(String.format("Source = %s | Target = %s", source, target));

            if (Files.exists(sourcePath.normalize())) {
                System.out.println(
                        "cannot add " + fileAbsolutePath.getFileName().toString() + ": file already in dotfiles repo");
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

                addPathToManifest(sourcePath, targetPath);

                System.out.printf("\n\nsuccessfully saved %s. A symlink has created in the parent directory",
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

    static void addPathToManifest(Path sourcePath, Path targetPath, String homePath) throws Exception {

        JsonFactory factory = JsonFactory.builder().enable(JsonReadFeature.ALLOW_JAVA_COMMENTS)
                .enable(JsonReadFeature.ALLOW_TRAILING_COMMA).build();
        ObjectMapper mapper = new ObjectMapper(factory);

        Path manifesPath = Path.of("/home/larryck/dots1/manifest.jsonc");

        ObjectNode node = mapper.createObjectNode();

        node.put("source", sourcePath.toString().trim());
        node.put("target", targetPath.toString().trim());
        ArrayNode array;

        if (!Files.exists(manifesPath)) {
            Files.createFile(manifesPath);
            array = mapper.createArrayNode();
        } else {
            array = (ArrayNode) mapper.readTree(manifesPath.toFile());
        }
        array.add(node);
        mapper.writerWithDefaultPrettyPrinter().writeValue(manifesPath.toFile(), array);

    }

}

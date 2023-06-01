package com.koosar.sqlSplitter;

import static java.util.stream.Collectors.joining;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

@Command(name = "splitter", mixinStandardHelpOptions = true, version = "splitter 1.0", description = "split raw sql file into 3 files (schema, constraint and data)...")
public class App implements Runnable {

    private static final String TABLE_FILENAME = "schema.%s.sql";

    private static final String CONSTRAINT_FILENAME = "constraint.%s.sql";

    private static final String DATA_FILENAME = "data.%s.sql";

    private static final String FILE_HEADER = "--liquibase formatted sql";

    private static final Map<String, String> ATTRIBUT_SANITIZER = new HashMap<String, String>() {

        {
            put("numeric\\(0\\)", "numeric");
        }
    };

    @Parameters(index = "0", description = "the file to split.")
    private String file;

    @Option(names = { "-t", "--dbType" }, description = "postgresql, mysql, oracle, ...")
    private String type = "postgresql";

    public static void main(String... args) {
        int exitCode = new CommandLine(new App()).execute(args);
        System.exit(exitCode);
    }

    @Override
    public void run() {
        // TODO Auto-generated method stub
        final Path rawFilePath = Paths.get(file);
        final Path baseDir = rawFilePath.getParent().normalize();
        BufferedWriter dataFile = null;
        BufferedWriter schemaFile = null;
        BufferedWriter constraintFile = null;
        BufferedReader rawFile = null;
        try {
            rawFile = Files.newBufferedReader(rawFilePath);
            schemaFile = Files.newBufferedWriter(Paths.get(baseDir.toString() + File.separator + getFileName(TABLE_FILENAME, type)),
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
            constraintFile = Files.newBufferedWriter(Paths.get(baseDir.toString() + File.separator + getFileName(CONSTRAINT_FILENAME, type)),
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
            dataFile = Files.newBufferedWriter(Paths.get(baseDir.toString() + File.separator + getFileName(DATA_FILENAME, type)),
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e1) {
            e1.printStackTrace();
        }

        final Map<Keyword, BufferedWriter> writers = new EnumMap<Keyword, BufferedWriter>(Keyword.class);
        writers.put(Keyword.CREATE_TABLE, schemaFile);
        writers.put(Keyword.CREATE_INDEX, constraintFile);
        writers.put(Keyword.INSERT, dataFile);
        writers.put(Keyword.ALTER, constraintFile);

        List<Content> contents = new ArrayList<>();
        try {
            contents = extractLines(rawFile, writers);
            writeTiFile(dataFile, schemaFile, constraintFile, contents);
        } catch (IOException e) {
            e.printStackTrace();
        }

        System.out.println(String.format("Split of file %s completed!", rawFilePath.toAbsolutePath().toString()));

    }

    private String getFileName(final String template, final String dbType) {
        return String.format(template, dbType);
    }

    private void writeTiFile(BufferedWriter dataFile, BufferedWriter tableFile, BufferedWriter constraintFile, List<Content> contents)
            throws IOException {
        tableFile.write(FILE_HEADER + "\n\n");
        constraintFile.write(FILE_HEADER + "\n\n");
        dataFile.write(FILE_HEADER + "\n\n");
        contents.stream().forEach(elm -> {
            final String headers = elm.getHeaders().stream().collect(joining("\n"));
            final String body = elm.getBody().stream().collect(joining("\n"));
            final StringBuilder builder = new StringBuilder();
            builder.append(headers);
            builder.append("\n");
            builder.append(body);

            final String str = builder.toString();

            if (elm.getWriter() != null && (!str.isEmpty() || str.contains("\n"))) {
                try {
                    final BufferedWriter writer = elm.getWriter();
                    writer.write(builder.toString());
                    writer.flush();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        });

        tableFile.close();
        constraintFile.close();
        dataFile.close();
    }

    private List<Content> extractLines(BufferedReader rawFile, final Map<Keyword, BufferedWriter> writers) throws IOException {
        String line = "";
        final List<Content> contents = new ArrayList<>();
        Content content = new Content();
        while ((line = rawFile.readLine()) != null) {
            final String strim = line.trim();
            if (!strim.isEmpty() && strim.contains(FILE_HEADER)) {
                continue;
            } else if (!strim.isEmpty() && strim.startsWith("--")) {
                content.getHeaders().add(line);

            } else if (!strim.isEmpty() && !strim.startsWith("--")) {
                final Keyword action = Keyword.fromValue(line);
                if (action == Keyword.CREATE_TABLE) {
                    line = sanitizeLine(line);
                }
                content.getBody().add(line);
                content.setType(action);
                if (Objects.isNull(content.getWriter())) {
                    content.setWriter(writers.get(action));
                }
            } else if (!content.getBody().contains(("\n"))) {
                content.getBody().add("\n");
                contents.add(content);
                content = new Content();
            } else {
                continue;
            }

        }
        return contents;
    }

    private String sanitizeLine(final String line) {
        String sanitizedLine = line;
        for (Map.Entry<String, String> e : ATTRIBUT_SANITIZER.entrySet()) {
            Pattern pattern = Pattern.compile(e.getKey(), Pattern.CASE_INSENSITIVE);
            sanitizedLine = pattern.matcher(line).replaceAll(e.getValue());
        }

        return sanitizedLine;
    }

}

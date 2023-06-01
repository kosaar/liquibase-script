package com.koosar.sqlSplitter;

import java.io.BufferedWriter;
import java.util.ArrayList;
import java.util.List;

public class Content {

    private Keyword type;

    private final List<String> headers;

    private final List<String> body;

    private BufferedWriter writer;

    /**
     * @param type
     */
    Content() {
        this.type = Keyword.NONE;
        this.headers = new ArrayList<>();
        this.body = new ArrayList<>();
    }

    /**
     * @return the body
     */
    public List<String> getBody() {
        return body;
    }

    /**
     * @return the type
     */
    public Keyword getType() {
        return type;
    }

    /**
     * @param type the type to set
     */
    public void setType(Keyword type) {
        this.type = type;
    }

    /**
     * @return the headers
     */
    public List<String> getHeaders() {
        return headers;
    }

    /**
     * @return the writer
     */
    public BufferedWriter getWriter() {
        return writer;
    }

    /**
     * @param writer the writer to set
     */
    public void setWriter(BufferedWriter writer) {
        this.writer = writer;
    }

}

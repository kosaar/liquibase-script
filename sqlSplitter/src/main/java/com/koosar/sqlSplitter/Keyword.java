package com.koosar.sqlSplitter;

import java.util.Arrays;
import java.util.List;

/**
 * @author mohamed.ibrahim
 */
public enum Keyword {

    /**
     * 
     */
    NONE(Arrays.asList("none")),

    /**
     * 
     */
    CREATE_TABLE(Arrays.asList("create table")),

    /**
     * 
     */
    CREATE_INDEX(Arrays.asList("create index", "create unique index")),

    /**
     * 
     */
    INSERT(Arrays.asList("insert")),

    /**
     * 
     */
    ALTER(Arrays.asList("alter table")),

    /**
     * 
     */
    CREATE_CONSTRAINT(Arrays.asList("create constraint"));

    private final List<String> action;

    /**
     * @param acton
     */
    private Keyword(List<String> action) {
        this.action = action;
    }

    /**
     * @return the acton
     */
    public List<String> getAction() {
        return action;
    }

    /**
     * get Keyword from str.
     * @param str string to search from
     * @return Keyword current enum value
     */
    public static Keyword fromValue(final String param) {
        return Arrays.stream(values()).filter(value -> value.getAction().contains(param)).findFirst().orElse(Keyword.NONE);
    }

}

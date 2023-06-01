package com.koosar.sqlSplitter;

import static junit.framework.Assert.assertEquals;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import org.junit.Test;

import com.koosar.sqlSplitter.Keyword;

@SuppressWarnings("deprecation")
public class KeywordTest {

    @Test
    public void givenEnumMethodGetActionShouldReturnString() {

        // when
        for (Keyword value : Keyword.values()) {
            // then
            switch (value) {
                case CREATE_TABLE:
                    assertEquals("keyword create table!", Arrays.asList("create table"), value.getAction());
                    break;
                case CREATE_INDEX:
                    assertEquals("keyword create index | create unique index !", Arrays.asList("create index", "create unique index"),
                            value.getAction());
                    break;
                case INSERT:
                    assertEquals("keyword insert!", Arrays.asList("insert"), value.getAction());
                    break;
                case ALTER:
                    assertEquals("keyword alter table!", Arrays.asList("alter table"), value.getAction());
                    break;
                case CREATE_CONSTRAINT:
                    assertEquals("Keyword create constraint!", Arrays.asList("create constraint"), value.getAction());
                    break;
                default:
                    assertEquals("valeur par default!", Arrays.asList("none"), value.getAction());
            }
        }
    }

    @Test
    public void givenStringValueMethodFromValueShouldReturnEnum() {
        // given
        final String[] values = new String[] { "create table", "create index", "insert", "alter table", "create constraint", "none",
                "create unique index" };

        // when
        final Map<String, Keyword> output = new HashMap<>();
        for (String value : values) {
            output.put(value, Keyword.fromValue(value));
        }

        // then
        assertEquals(Keyword.CREATE_TABLE, output.get(values[0]));
        assertEquals(Keyword.CREATE_INDEX, output.get(values[1]));
        assertEquals(Keyword.INSERT, output.get(values[2]));
        assertEquals(Keyword.ALTER, output.get(values[3]));
        assertEquals(Keyword.CREATE_CONSTRAINT, output.get(values[4]));
        assertEquals(Keyword.NONE, output.get(values[5]));
        assertEquals(Keyword.CREATE_INDEX, output.get(values[6]));

    }

}

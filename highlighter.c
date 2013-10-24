/* PEG Markdown Highlight
 * Copyright 2011-2012 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 *
 * highlighter.c
 *
 * Test program that parses the Markdown content from stdin and outputs
 * the positions of found language elements.
 */

#include <stdio.h>
#include <string.h>
#include "pmh_parser.h"


#define READ_BUFFER_LEN 1024
char *get_contents(FILE *f)
{
    char buffer[READ_BUFFER_LEN];
    size_t content_len = 1;
    char *content = malloc(sizeof(char) * READ_BUFFER_LEN);
    content[0] = '\0';

    while (fgets(buffer, READ_BUFFER_LEN, f))
    {
        content_len += strlen(buffer);
        content = realloc(content, content_len);
        strcat(content, buffer);
    }

    return content;
}
char* name[] = {"link", "auto_link_url", "auto_link_email", "image", "code", "html", "html_entity", "emph", "strong", "list_bullet", "list_enumerator", "comment", "h1", "h2", "h3", "h4", "h5", "h6", "blockquote", "verbatim", "htmlblock", "hrule", "reference", "note", "str", "raw_list", "raw", "extra_text", "separator", "no_type", "all"};


void output_result(pmh_element *elem[], char* md_source)
{
    pmh_element *cursor;
    bool firstType = true;
    int i;
    //for (i = 0; i < pmh_NUM_LANG_TYPES; i++)
    for (i = 0; i < pmh_NUM_LANG_TYPES; i++)
    {
        cursor = elem[i];
        if (cursor == NULL)
            continue;

        /* if (!firstType) */
        /*     printf("|"); */
        /* printf("%i:", i); */
        printf("[");
        bool firstSpan = true;
        while (cursor != NULL)
        {
            if (!firstSpan)
                printf(",");
            //printf("%ld-%ld", cursor->pos, cursor->end);
            printf("{\"type_id\":%d, \"type\":\"%s\", \"start\":%ld, \"end\":%ld",
                   cursor->type, name[cursor->type], cursor->pos, cursor->end);
            printf(", \"string\":\"%.*s\"}",
                   (int)(cursor->end - cursor->pos), md_source + (int)cursor->pos);// + cursor->pos);

            cursor = cursor->next;
            firstSpan = false;
        }
        firstType = false;
        printf("]");
    }
}


int main(int argc, char * argv[])
{
    pmh_element **result;

    FILE *file = stdin;
    if (argc > 1)
        file = fopen(argv[1], "r");
    char *md_source = get_contents(file);
    pmh_markdown_to_elements(md_source, pmh_EXT_NONE, &result);
    pmh_sort_elements_by_pos(result);
    output_result(result, md_source);

    return(0);
}

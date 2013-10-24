ALL : tester testclient highlighter

BENCH=bench
TESTER=tester
MULTITHREAD_TESTER=multithread_tester
TEST_CLIENT=testclient
HIGHLIGHTER=highlighter
STYLEPARSERTESTER=styleparsertester
CFLAGS ?= -Wall -Wswitch -Wshadow -Wsign-compare -O3 -std=gnu89
OBJC_CFLAGS=-framework Foundation -framework AppKit

GREGDIR=greg
GREG=$(GREGDIR)/greg

ifdef DEBUG
	CFLAGS += -g -O0
endif
ifdef DEBUGOUT
	CFLAGS += -Dpmh_DEBUG_OUTPUT=1
endif

$(GREG):
	@echo '------- building greg'
	CC=gcc make -C $(GREGDIR)

pmh_parser_core.c : pmh_grammar.leg $(GREG)
	@echo '------- generating parser core from grammar'
	$(GREG) -o $@ $<

pmh_parser.c : pmh_parser_core.c pmh_parser_head.c pmh_parser_foot.c tools/combine_parser_files.sh
	@echo '------- combining parser code'
	./tools/combine_parser_files.sh > $@

pmh_parser.o : pmh_parser.c pmh_parser.h pmh_definitions.h
	@echo '------- building pmh_parser.o'
	$(CC) $(CFLAGS) -c -o $@ $<

ANSIEscapeHelper.o : ANSIEscapeHelper.m ANSIEscapeHelper.h
	@echo '------- building ANSIEscapeHelper.o'
	clang -Wall -O3 -c -o $@ $<

$(TESTER) : tester.m pmh_parser.o ANSIEscapeHelper.o ANSIEscapeHelper.h
	@echo '------- building tester'
	clang $(CFLAGS) $(OBJC_CFLAGS) -o $@ pmh_parser.o ANSIEscapeHelper.o $<

$(TEST_CLIENT) : testclient.m ANSIEscapeHelper.o ANSIEscapeHelper.h
	@echo '------- building testclient'
	clang $(CFLAGS) $(OBJC_CFLAGS) -o $@ ANSIEscapeHelper.o $<

$(HIGHLIGHTER) : highlighter.c pmh_parser.o
	@echo '------- building highlighter'
	$(CC) $(CFLAGS) -o $@ pmh_parser.o $<

$(MULTITHREAD_TESTER) : multithread_tester.c pmh_parser.o
	@echo '------- building multithread_tester'
	$(CC) $(CFLAGS) -o $@ pmh_parser.o $<

$(BENCH) : bench.c pmh_parser.o
	@echo '------- building bench'
	$(CC) $(CFLAGS) -o $@ pmh_parser.o $<

pmh_styleparser.o : pmh_styleparser.c pmh_styleparser.h pmh_definitions.h
	@echo '------- building pmh_styleparser.o'
	$(CC) $(CFLAGS) -c -o $@ $<

$(STYLEPARSERTESTER) : styleparsertester.c pmh_styleparser.o pmh_parser.o
	@echo '------- building styleparsertester'
	$(CC) $(CFLAGS) -o $@ pmh_styleparser.o pmh_parser.o $<

docs: pmh_parser.h pmh_definitions.h pmh_styleparser.h tools/markdown.css stylesheet_syntax.md doxygen/doxygen.cfg doxygen/doxygen.h doxygen/doxygen_footer.html example_cocoa/HGMarkdownHighlighter.h
	doxygen doxygen/doxygen.cfg
	tools/compile_markdown.sh stylesheet_syntax.md "PEG Markdown Highlight Stylesheet Syntax" > docs/html/stylesheet_syntax.html
	cp tools/markdown.css docs/html/.
	touch docs

analyze: pmh_parser.c
	clang --analyze pmh_parser.c

analyze-styleparser:
	clang --analyze pmh_styleparser.c

leak-check: $(TESTER)
	valgrind --leak-check=full --dsymutil=yes ./$(TESTER) 100 todo.md

leak-check-styleparser: $(STYLEPARSERTESTER)
	valgrind --leak-check=full --dsymutil=yes ./$(STYLEPARSERTESTER) < styles/teststyle.style

.PHONY: clean test

clean:
	rm -f pmh_parser_core.c pmh_parser.c *.o $(TESTER) $(TEST_CLIENT) $(HIGHLIGHTER) $(BENCH) $(MULTITHREAD_TESTER) $(STYLEPARSERTESTER); \
	rm -rf *.dSYM; \
	make -C $(GREGDIR) clean

distclean: clean
	make -C $(GREGDIR) spotless

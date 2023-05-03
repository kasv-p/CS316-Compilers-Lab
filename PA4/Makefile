compiler: main.c microParser.y microLexer.l tinyNew.C
	flex microLexer.l
	bison -d microParser.y
	g++ -c main.c
	g++ -o $@ main.o lex.yy.c microParser.tab.c
	# g++ tinyNew.C
dev:
	@echo "Kavali Sri Vyshnavi Devi"
	@echo "200010023@iitdh.ac.in"
clean:
	rm -f lex.yy.c microParser.tab.c microParser.tab.h compiler main.o
compiler: main.c microParser.y microLexer.l
	bison -d microParser.y
	flex microLexer.l
	gcc lex.yy.c microParser.tab.c main.c -o $@
dev:
	echo "Kavali Sri Vyshnavi Devi"
	echo "200010023@iitdh.ac.in"
clean:
	rm lex.yy.c microParser.tab.c microParser.tab.h compiler
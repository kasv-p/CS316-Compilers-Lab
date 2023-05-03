compiler: main.c microParser.y microLexer.l
	flex microLexer.l
	bison -d microParser.y
	g++ -c main.c
	g++ -o $@ main.o lex.yy.c microParser.tab.c
dev:
	echo "Kavali Sri Vyshnavi Devi"
	echo "200010023@iitdh.ac.in"
clean:
	rm lex.yy.c microParser.tab.c microParser.tab.h compiler
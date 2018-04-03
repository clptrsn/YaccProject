
go: lex.yy.c inSure.tab.c 
	gcc inSure.tab.c lex.yy.c -lfl -ly -o go 

lex.yy.c: inSure.l
	flex inSure.l

inSure.tab.c: inSure.y
	bison -dv inSure.y

clean:
	rm -f lex.yy.c 
	rm -f inSure.output
	rm -f inSure.tab.h
	rm -f inSure.tab.c
	rm -f go 


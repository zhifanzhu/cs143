/*
*  cool.y
*              Parser definition for the COOL language.
*
*/
%{
#include <iostream>
#include "cool-tree.h"
#include "stringtab.h"
#include "utilities.h"

extern char *curr_filename;


/* Locations */
#define YYLTYPE int              /* the type of locations */
#define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer
for the location of tokens */

extern int node_lineno;          /* set before constructing a tree node
to whatever you want the line number
for the tree node to be */
  
  
#define YYLLOC_DEFAULT(Current, Rhs, N)         \
Current = Rhs[1];                             \
node_lineno = Current;


#define SET_NODELOC(Current)  \
node_lineno = Current;

/* IMPORTANT NOTE ON LINE NUMBERS
*********************************
* The above definitions and macros cause every terminal in your grammar to 
* have the line number supplied by the lexer. The only task you have to
* implement for line numbers to work correctly, is to use SET_NODELOC()
* before constructing any constructs from non-terminals in your grammar.
* Example: Consider you are matching on the following very restrictive 
* (fictional) construct that matches a plus between two integer constants. 
* (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):

plus_consts	: INT_CONST '+' INT_CONST 

* where INT_CONST is a terminal for an integer constant. Now, a correct
* action for this rule that attaches the correct line number to plus_const
* would look like the following:

plus_consts	: INT_CONST '+' INT_CONST 
{
  // Set the line number of the current non-terminal:
  // ***********************************************
  // You can access the line numbers of the i'th item with @i, just
  // like you acess the value of the i'th exporession with $i.
  //
  // Here, we choose the line number of the last INT_CONST (@3) as the
  // line number of the resulting expression (@$). You are free to pick
  // any reasonable line as the line number of non-terminals. If you 
  // omit the statement @$=..., bison has default rules for deciding which 
  // line number to use. Check the manual for details if you are interested.
  @$ = @3;
  
  
  // Observe that we call SET_NODELOC(@3); this will set the global variable
  // node_lineno to @3. Since the constructor call "plus" uses the value of 
  // this global, the plus node will now have the correct line number.
  SET_NODELOC(@3);
  
  // construct the result node:
  $$ = plus(int_const($1), int_const($3));
}

*/



void yyerror(char *s);        /*  defined below; called for each parse error */
extern int yylex();           /*  the entry point to the lexer  */

/************************************************************************/
/*                DONT CHANGE ANYTHING IN THIS SECTION                  */

Program ast_root;	      /* the result of the parse  */
Classes parse_results;        /* for use in semantic analysis */
int omerrs = 0;               /* number of errors in lexing and parsing */
%}

/* A union of all the types that can be the result of parsing actions. */
%union {
  Boolean boolean;
  Symbol symbol;
  Program program;
  Class_ class_;
  Classes classes;
  Feature feature;
  Features features;
  Formal formal;
  Formals formals;
  Case case_;
  Cases cases;
  Expression expression;
  Expressions expressions;
  char *error_msg;
}

/* 
Declare the terminals; a few have types for associated lexemes.
The token ERROR is never used in the parser; thus, it is a parse
error when the lexer returns it.

The integer following token declaration is the numeric constant used
to represent that token internally.  Typically, Bison generates these
on its own, but we give explicit numbers to prevent version parity
problems (bison 1.25 and earlier start at 258, later versions -- at
257)
*/
%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol>  STR_CONST 275 INT_CONST 276 
%token <boolean> BOOL_CONST 277
%token <symbol>  TYPEID 278 OBJECTID 279 
%token ASSIGN 280 NOT 281 LE 282 ERROR 283

/*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
/**************************************************************************/

/* Complete the nonterminal list below, giving a type for the semantic
value of each non terminal. (See section 3.6 in the bison 
documentation for details). */

/* Declare types for the grammar's non-terminals. */
%type <program> program
%type <classes> class_list
%type <class_> class

/* You will want to change the following line. */
/* MyNote: %union { `Phylum` `constructor`} ; */
/* then: %type `constructor` `non-terminal` */
/* %type <features> feature_list */
/* %type <feature> feature */
/* %type <formals> formal_list */
/* %type <formal> formal */
/* %type <cases> case_list */
/* %type <case_> case */
/* %type <expressions> expression_list  /1* for  [[expr;]]+  *1/ */
/* %type <expressions> expr_list        /1* for   [ expr [[, expr]]* ]  *1/ */
%type <expression> expression

/* %type <feature>method */
/* %type <feature>attr */

/* %type <expression> expr */
/* /1* now is expr... *1/ */
/* %type <expression> assign */
/* %type <expression> static_dispatch */
/* %type <expression> dispatch */
/* %type <expression> cond */
/* %type <expression> loop */
/* %type <expression> typcase */
/* %type <expression> block */
/* /1* %type <expression> let       /2* nested let *2/ *1/ */
/* /1* %type <expression> let_body *1/ */  
/* %type <expression> plus */
/* %type <expression> sub */
/* %type <expression> mul */
/* %type <expression> divide */
/* %type <expression> neg */
/* %type <expression> lt */
/* %type <expression> eq */
/* %type <expression> leq */
/* %type <expression> comp */
/* %type <expression> object   /1* for ID *1/ */
/* %type <expression> int_const */
/* %type <expression> string_const */
/* %type <expression> new */
/* %type <expression> isvoid */
/* %type <expression> bool_const */

/* Precedence declarations go here. */


%%
/* 
Save the root of the abstract syntax tree in a global variable.
*/
program	
: class_list	{ @$ = @1; ast_root = program($1); }
;

class_list
: class			/* single class */
{ $$ = single_Classes($1); parse_results = $$; }

| class_list class	/* several classes */
{ $$ = append_Classes($1, single_Classes($2));  
    parse_results = $$; }
;

/* If no parent is specified, the class inherits from the Object class. */
class	
: CLASS TYPEID '{' expression '}' ';'
{ $$ = class_($2, idtable.add_string("Object"), nil_Features(),
    stringtable.add_string(curr_filename)); }

| CLASS TYPEID INHERITS TYPEID '{'  '}' ';'
{ $$ = class_($2, $4, nil_Features(), stringtable.add_string(curr_filename)); }
;

expression 
: OBJECTID
{ $$ = object($1); }
;
/* feature list may be empty, but no empty features in list. */
/* feature_list */
/* : feature			/1* single class *1/ */
/* { $$ = single_features($1); } */

/* | feature_list class	/1* several classes *1/ */
/* { $$ = append_features($1, single_features($2)); } */

/* | %empty        /1* empty feature list *1/ */
/* { $$ = nil_features(); } */
/* ; */

/* feature */
/* : method ';' */
/* { $$ = $1; } */

/* | attr ';' */
/* { $$ = $1; } */
/* ; */

/* method */
/* : objectid '(' formals ')' ':' typeid '{' expressions '}'  /1* methods *1/ */
/* { $$ = method($1, $3, $6, $8); } */
/* ; */

/* attr */
/* : objectid ':' typeid  /1* attrs, no init *1/ */ 
/* { $$ = attr($1, $3, no_expr()); } */

/* | OBJECTID ':' TYPEID ASSIGN expression /1* attrs *1/ */ 
/* { $$ = attr($1, $3, $5); } */
/* ; */

/* formal_list */
/* : formal			        /1* single formals *1/ */
/* { $$ = single_Formals($1); } */

/* | formal_list ',' formal	/1* several formals *1/ */
/* { $$ = append_Formals($1, single_Formals($2)); } */
/* ; */

/* formal */
/* : OBJECTID ':' TYPEID */
/* { $$ = formal($1, $3); } */
/* ; */

/* case_list */
/* : case              /1* single case *1/ */
/* { $$ = single_Cases($1); } */

/* | case_list case */
/* { $$ = append_Cases($1, single_Cases($2)); } */
/* ; */

/* case */
/* : OBJECTID ':' TYPEID DARROW expression ';' */
/* { $$ = branch($1, $3, $5); } */
/* ; */

/* expression_list     /1* expresion_list only means:  { [[expr;]]+ }  *1/ */
/* : expression */
/* { $$ = single_Expressions($1); } */

/* | expression_list expression */
/* { $$ = append_Expressions($1, single_Expressions($2)); } */
/* ; */

/* expression */
/* : expr ';' */
/* { $$ = $1 } */
/* ; */

/* expr_list */
/* : expr */ 
/* { $$ = single_Expressions($1); } */

/* | expr_list ',' expr */
/* { $$ = append_Expressions($1, $3); } */
/* ; */

/* expr */ 
/* : assign */
/* | static_dispatch */
/* | dispatch */
/* | cond */
/* | loop */
/* | block */
/* /1* | let *1/ */
/* | typcase */
/* | new */
/* | isvoid */
/* | plus */
/* | sub */
/* | divide */
/* | neg */
/* | lt */
/* | eq */
/* | leq */
/* | comp */
/* | '(' expr ')' */
/*     { $$ = $1; } */
/* | object */
/* | int_const */
/* | string_const */
/* | bool_const */
/* ; */

/* assign */
/* : OBJECTID ASSIGN expr */
/* { $$ = assign($1, $3); } */
/* ; */

/* static_dispatch */
/* : expr '@' TYPEID '.' OBJECTID '(' ')' */
/* { $$ = static_dispatch($1, $3, $5, nil_Expressions()); } */

/* | expr '@' TYPEID '.' OBJECTID '(' expr_list ')' */
/* { $$ = static_dispatch($1, $3, $5, $7); } */
/* ; */

/* dispatch */
/* : expr '.' OBJECTID '(' expr_list ')' */
/* { $$ = dispatch($1, $3, $5); } */

/* | expr '.' OBJECTID '(' ')' */
/* { $$ = dispatch($1, $3, nil_Expressions(); } */

/* | OBJECTID '(' expr_list ')' */ 
/* { $$ = dispatch( */
/*     object(stringtable.add_string("self")), $1, $3); } */

/* | OBJECTID '(' ')' */ 
/* { $$ = dispatch( */
/*     object(stringtable.add_string("self")), $1, nil_Expressions()); } */
/* ; */

/* cond */
/* : IF expr THEN expr ELSE expr FI */
/* { $$ = cond($2, $4, $6); } */
/* ; */

/* loop */
/* : WHILE expr LOOP expr POOL */
/* { $$ = loop($2, $4); } */
/* ; */

/* typcase */
/* : CASE expr OF case_list ESAC */
/* { $$ = typcase($2, $4); } */
/* ; */

/* block */
/* : '{' expression_list '}' */
/* { $$ = block($2); } */
/* ; */

/* /1* let *1/ */
/* /1* : LET OBJECTID ':' TYPEID IN let *1/ */
/* /1* { $$ = *1/ */ 

/* /1* | LET OBJECTID ':' TYPEID DARROW expr IN let *1/ */

/* /1* ; *1/ */

/* /1* let *1/ */
/* /1* : LET OBJECTID ':' TYPEID IN expr *1/ */
/* /1* { $$ = let($2, $4, no_expr, $86; } *1/ */

/* /1* | LET OBJECTID ':' TYPEID DARROW expr IN expr *1/ */
/* /1* { $$ = let($2, $4, $6, $8); } *1/ */

/* /1* | LET OBJECTID ':' TYPEID DARROW expr let_ext IN expr *1/ */
/* /1* { $$ = let($2, $4, $6, let(let_ext, ); } *1/ */
/* /1* ; *1/ */

/* new */
/* : NEW TYPEID */
/* { $$ = new_($2); } */
/* ; */

/* isvoid */
/* : ISVOID expr */
/* { $$ = isvoid($2); } */
/* ; */

/* plus */
/* : expr '+' expr */
/* { $$ = plus($1, $3); } */
/* ; */

/* sub */
/* : expr '-' expr */
/* { $$ = sub($1, $3); } */
/* ; */

/* mul */
/* : expr '*' expr */ 
/* { $$ = mul($1, $3); } */
/* ; */

/* divide */
/* : expr '/' expr */
/* { $$ = divide($1, $3); } */
/* ; */

/* neg */
/* : '~' expr */
/* { $$ = neg($2); } */
/* ; */

/* lt */
/* : expr '<' expr */
/* { $$ = lt($1, $3); } */
/* ; */

/* eq */
/* : expr '=' expr */
/* { $$ = eq($1, $3); } */
/* ; */

/* leq */
/* : expr '=' expr */
/* { $$ = leq($1, $3); } */
/* ; */

/* comp */
/* : NOT expr */
/* { $$ = neg($2); } */
/* ; */

/* object */
/* : OBJECTID */
/* { $$ = object($1); } */
/* ; */

/* int_const */
/* : INT_CONST */
/* { $$ = int_const($1); } */
/* ; */

/* string_const */
/* : STR_CONST */
/* { $$ = string_const($1); } */
/* ; */

/* bool_const */
/* : BOOL_CONST */
/* { $$ = bool_const($1); } */
/* ; */


/* end of grammar */
%%

/* This function is called automatically when Bison detects a parse error. */
void yyerror(char *s)
{
  extern int curr_lineno;
  
  cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
  << s << " at or near ";
  print_cool_token(yychar);
  cerr << endl;
  omerrs++;
  
  if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
}



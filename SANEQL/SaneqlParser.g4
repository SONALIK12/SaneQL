parser grammar SaneqlParser;

options { tokenVocab=SaneqlLexer; }

query
    : selectQuery EOF
    | statement+
    | deleteStatement
        ;


selectQuery
    : SELECT selectList fromClause whereClause? groupByClause? havingClause?
    | transactionControlStatement

            | updateStatement

    ;

selectList: (DISTINCT | ALL)? (ASTERISK | selectItem (COMMA selectItem)*)
           | IDENTIFIER COMMA percentileContFunctionCall;
selectItem: (DISTINCT | ALL | ASTERISK) | expression (AS alias=IDENTIFIER)?

    | windowFunction
    | functionCall
    | withinGroupFunction // Adjusted for WITHIN GROUP

    ;
    windowFunction
        : functionName LPAREN RPAREN OVER LPAREN orderByExpression RPAREN
        ;
        orderByExpression
            : expression (ASC | DESC)?
            ;
overClause
    : OVER LPAREN orderByExpression RPAREN
    ;

fromClause
    : FROM LPAREN SELECT fromItem (COMMA fromItem)*
    ;

fromItem
    : tableName
    | subqueryAlias=IDENTIFIER SUBQUERY_START selectQuery SUBQUERY_END
    ;

tableName
    : IDENTIFIER
    ;
columnIdentifier: IDENTIFIER (PERIOD IDENTIFIER)+;
whereClause
    : WHERE condition (AND condition)*
    ;

condition
    : expression COMPARE_OP expression
    | expression IN LPAREN selectQuery RPAREN
    | LPAREN condition RPAREN
    | NOT condition
    ;

groupByClause
    : GROUP BY groupByItem (COMMA groupByItem)*|  GROUP BY IDENTIFIER | GROUP BY columnIdentifier

    ;

groupByItem
    : expression
    ;

havingClause
    : HAVING condition (AND condition)*
    ;
orderByClause: ORDER BY orderByExpressionList;

orderByExpressionList: orderByExpression (COMMA orderByExpression)*;
expression
    : term
    |functionCall
    | aggregateFunctionCall
    | percentileContFunctionCall
    | withinGroupFunction
    | LPAREN expression RPAREN
    ;

term
    : IDENTIFIER
    | STRING
    | INTEGER
    | REAL
    | BOOLEAN
    | NULL
    | ASTERISK

    ;

functionCall
    : IDENTIFIER LPAREN (expression (COMMA expression)*)? RPAREN
    | IDENTIFIER LPAREN RPAREN
    ;

functionName
    : STRING_FUNCTION_ID
    | NUMERIC_FUNCTION_ID
    | DATE_TIME_FUNCTION_ID
    | IDENTIFIER
    | ORDER
    | BY
    ;

aggregateFunctionCall
    : COUNT LPAREN (DISTINCT? expression | ASTERISK | LPAREN ASTERISK RPAREN) RPAREN
    | (MIN | MAX | SUM | AVG) LPAREN expression RPAREN
    | COUNT LPAREN ASTERISK RPAREN // Handle COUNT(*)
    ;

percentileContFunctionCall
    : PERCENTILE_CONT LPAREN expression RPAREN WITHIN ORDER BY IDENTIFIER RPAREN
    ;


statement: selectQuery ';' ;
withinClause
    : WITHIN GROUP expression
    ;

withinFunction
    : functionName LPAREN expression COMMA expression RPAREN withinClause RPAREN
    ;
    withinGroupFunction
        : percentileContFunctionCall WITHIN GROUP LPAREN orderByExpression RPAREN // Added withinGroupFunction
        ;
ddlStatement: createTableStatement;
createTableStatement
    : CREATE TABLE tableName
      LPAREN columnDefinition (COMMA columnDefinition)* RPAREN
      SYM_SEMICOLON
    ;

columnDefinition
    : columnName dataType columnConstraints?
    ;
columnName
    : IDENTIFIER
    ;

dataType
    : INT
    | VARCHAR LPAREN INTEGER RPAREN
    | // Add more data types as needed (e.g., DECIMAL, DATE, etc.)
    ;

columnConstraints
    : PRIMARY_KEY
    | NOT NULL
    | UNIQUE
    | // Add more constraints (e.g., FOREIGN KEY, CHECK, etc.)
    ;

transactionControlStatement
    : BEGIN
    | COMMIT
    ;
updateStatement
    : UPDATE tableName SET setClause WHERE whereClause
    ;

setClause
    : SET setItem (COMMA setItem)*
    ;

setItem
    : columnName EQ expression
    ;

deleteStatement
    : DELETE FROM tableName whereClause? SYM_SEMICOLON
    ;

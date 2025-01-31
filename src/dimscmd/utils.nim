import std/[
    parseutils,
    strutils,
    macros
]

macro matchIdent*(id: string, body: untyped): untyped =
    ## Creates a case statement to match a string against
    ## other strings in style insensitive way
    let expression = nnkCall.newTree(
        bindSym("normalize"),
        id
    )
    result = nnkCaseStmt.newTree(expression)
    for node in body:
        node.expectKind(nnkCall)
        var ofBranch = nnkOfBranch.newTree()
        template normalString(node: NimNode): untyped = node.strVal.normalize().newStrLitNode()
        if node[0].kind in {nnkTupleConstr, nnkPar}: # On devel it is nnkTupleConstr, stable it is nnkPar
            for value in node[0]:
                ofBranch.add normalString(value)
        else:
            ofBranch.add normalString(node[0])
        ofBranch.add node[1]
        result.add ofBranch
        # The else branch is embedded with an of branch for some reason.
        # This moves it into the case statement.
        if node[^1].kind == nnkElse:
            result.add node[^1]

proc nextWord*(input: string, output: var string, start = 0): int =
    ## Gets the next word after `start` in the string and puts it in `output`
    result += input.parseUntil(output, Whitespace, start = start)
    result += input.skipWhitespace(start = start + result)

proc getWords*(input: string): seq[string] =
    ## Splits the input string into each word
    ## Handles multple spaces
    var i = 0
    while i < input.len:
        # - Parse token until it reaches a whitespace character
        # - skip any whitespace that follows the token
        # - repeat til the end is reached
        var newWord: string
        i += input.nextWord(newWord, start = i)
        result &= newWord

proc leafName*(input: string): string =
    ## Returns the last word in a sentence
    # Start at the final character and continue adding
    var index = len(input) - 1
    while index >= 0 and input[index] != ' ':
        result.insert($input[index], 0)
        dec index



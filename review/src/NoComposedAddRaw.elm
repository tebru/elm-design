module NoComposedAddRaw exposing (rule)

{-| Ban `Theme.Config.addRaw` called with a class string that is COMPOSED at
runtime instead of written as a literal.

The design system's CSS emitter builds its closed class inventory by SCANNING source
for class-like string literals (`codegen/generate-inventory.js` in the design package —
formerly Tailwind's JIT). A class whose name is spliced together at runtime — e.g.
`"grid-cols-" ++ String.fromInt n` — never appears as a literal, so the scanner can't
see it: the utility is silently missing on a clean build (this is the exact bug the token system kept hitting —
grid-cols, max-w, fixed heights, Structure sizes/overflow).

This rule forces every `addRaw` class to be statically scannable. The argument must be:

  - a string literal — `Config.addRaw "grid-cols-3"`, or
  - a `++` join whose every seam sits on whitespace, so each class TOKEN still
    appears whole in some literal the scanner reads —
    `Config.addRaw (base ++ " before:bg-white")`, `Config.addRaw ("skeleton " ++ extras)`.

It REJECTS a `++` that splices a class token across the seam (`"grid-cols-" ++ n`).
Bare variables and resolver calls (`addRaw (Size.widthToClass w)`) are ALLOWED — by
convention they return literal class strings from `case` arms, which the scanner finds
in the resolver; this rule targets the one statically-unambiguous break (a token
spliced at the call site). When you need a class chosen at runtime, do one of:

  - **Tokenize it**: a closed custom type whose `case` arms each return a LITERAL
    class (see `Box.gridColsClasses`, `Theme.Structure.withWidth`). The literals live
    in source, so the scanner finds them — no inventory gap, no silent break.
  - **Inline genuinely dynamic values**: `Config.setStyle` / `withBackgroundHex`
    (per-name colors, calendar geometry) — the inline-style channel needs no scan.

This rule governs the ARGUMENT; `NoAddRawOutside` governs the location (which modules
may call `addRaw` at all). `packages/` is ignored in `ReviewConfig` (the libraries
carry their own review config), so this rule governs application code only.


## Fail

    Config.addRaw ("grid-cols-" ++ String.fromInt n)

    Config.addRaw <| "grid-cols-" ++ String.fromInt n

    ("grid-cols-" ++ String.fromInt n) |> Config.addRaw

    Config.addRaw (prefix ++ suffix) -- seam is not on whitespace

    Config.addRaw (resolveClass variant)


## Success

    Config.addRaw "grid-cols-3"

    Config.addRaw (base ++ " before:bg-white") -- right operand starts with a space

    Config.addRaw ("skeleton " ++ extras) -- left operand ends with a space


## Configuration

    import NoComposedAddRaw

    config =
        [ NoComposedAddRaw.rule
            |> Review.Rule.ignoreErrorsForDirectories [ "tests/", "packages/" ]
        ]

-}

import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Node as Node exposing (Node)
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "NoComposedAddRaw" contextCreator
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


type alias Context =
    { lookupTable : ModuleNameLookupTable }


contextCreator : Rule.ContextCreator () Context
contextCreator =
    Rule.initContextCreator
        (\lookupTable () -> { lookupTable = lookupTable })
        |> Rule.withModuleNameLookupTable


expressionVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionVisitor node context =
    case Node.value node of
        Expression.Application (func :: arg :: _) ->
            checkCall context func arg

        -- `Config.addRaw <| arg` and `arg |> Config.addRaw`: an operator-applied
        -- argument is an OperatorApplication node, not an Application, so without
        -- these arms the rule's own Fail example restyled with <|/|> would pass
        -- lint and the spliced class would silently vanish from the emitted CSS.
        -- (addRaw takes the class String FIRST, so the piped/applied operand here
        -- is always the class argument — a piped Config cannot typecheck.)
        Expression.OperatorApplication "<|" _ func arg ->
            checkCall context func arg

        Expression.OperatorApplication "|>" _ arg func ->
            checkCall context func arg

        _ ->
            ( [], context )


checkCall : Context -> Node Expression -> Node Expression -> ( List (Rule.Error {}), Context )
checkCall context func arg =
    if isConfigAddRaw context.lookupTable func && not (argIsSafe arg) then
        ( [ Rule.error errorInfo (Node.range arg) ], context )

    else
        ( [], context )


isConfigAddRaw : ModuleNameLookupTable -> Node Expression -> Bool
isConfigAddRaw lookupTable node =
    case Node.value node of
        Expression.FunctionOrValue _ "addRaw" ->
            ModuleNameLookupTable.moduleNameFor lookupTable node == Just [ "Tebru", "Theme", "Config" ]

        _ ->
            False


{-| Statically scannable: a string literal, or a `++` join whose every seam lands
on whitespace (so no class token is spliced across a concatenation).
-}
argIsSafe : Node Expression -> Bool
argIsSafe node =
    case Node.value node of
        Expression.ParenthesizedExpression inner ->
            argIsSafe inner

        Expression.Literal _ ->
            True

        Expression.OperatorApplication "++" _ _ _ ->
            seamsSafe (flattenConcat node)

        _ ->
            -- Bare variables and resolver calls (`addRaw (Size.widthToClass w)`)
            -- are allowed: by convention they return LITERAL class strings from
            -- `case` arms, which the scanner finds in the resolver. This rule
            -- targets the one pattern that is statically, unambiguously broken —
            -- a class token spliced across a `++` seam at the call site.
            True


{-| Flatten a (left-associative) `++` chain into its operands, unwrapping parens.
-}
flattenConcat : Node Expression -> List (Node Expression)
flattenConcat node =
    case Node.value node of
        Expression.ParenthesizedExpression inner ->
            flattenConcat inner

        Expression.OperatorApplication "++" _ left right ->
            flattenConcat left ++ flattenConcat right

        _ ->
            [ node ]


{-| Every adjacent seam must sit on whitespace — the left operand is a literal
ending in whitespace, or the right operand is a literal beginning with it. A seam
that is not whitespace-delimited splices a class token across the concatenation,
which the scanner cannot see.
-}
seamsSafe : List (Node Expression) -> Bool
seamsSafe operands =
    case operands of
        left :: right :: rest ->
            (literalEndsWithSpace left || literalStartsWithSpace right) && seamsSafe (right :: rest)

        _ ->
            True


literalEndsWithSpace : Node Expression -> Bool
literalEndsWithSpace node =
    case Node.value node of
        Expression.Literal s ->
            lastCharIsWhitespace s

        _ ->
            False


literalStartsWithSpace : Node Expression -> Bool
literalStartsWithSpace node =
    case Node.value node of
        Expression.Literal s ->
            case String.uncons s of
                Just ( c, _ ) ->
                    isWhitespace c

                Nothing ->
                    False

        _ ->
            False


lastCharIsWhitespace : String -> Bool
lastCharIsWhitespace s =
    case String.uncons (String.right 1 s) of
        Just ( c, _ ) ->
            isWhitespace c

        Nothing ->
            False


isWhitespace : Char -> Bool
isWhitespace c =
    c == ' ' || c == '\n' || c == '\t'


errorInfo : { message : String, details : List String }
errorInfo =
    { message = "Config.addRaw builds a class string at runtime"
    , details =
        [ "The design system's CSS emitter builds its class inventory by scanning source for class-like LITERALS (codegen/generate-inventory.js). A class spliced together at runtime (e.g. \"grid-cols-\" ++ String.fromInt n) never appears as a literal, so the scanner can't see it and the utility is silently missing on a clean build."
        , ""
        , "The argument to addRaw must be statically scannable — a string literal, or a ++ join whose every seam sits on whitespace (so each class token still appears whole somewhere)."
        , ""
        , "To choose a class at runtime, do one of:"
        , ""
        , "  - Tokenize it: a closed custom type whose case arms each return a LITERAL class, e.g."
        , ""
        , "        widthClass s = case s of"
        , "            Full -> \"w-full\""
        , "            Auto -> \"w-auto\""
        , ""
        , "    The literals live in source, so the scanner finds them — no inventory gap, no silent break."
        , ""
        , "  - Inline genuinely dynamic values (per-name colors, pixel geometry) via Config.setStyle / withBackgroundHex — the inline-style channel needs no scan."
        ]
    }

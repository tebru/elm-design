module Bespoke exposing (classes)

{-| TEST FIXTURE — the bespoke hatch module of the vendored fixture app
(codegen/fixtures/app/app-tokens.js). Carries the exact class literals the
codegen tests assert on; every literal must compile in codegen/emit-css.js.
-}


classes : List String
classes =
    [ "pt-[20vh]"
    , "w-[15.5rem]"
    , "min-w-[220px]"
    , "h-[42px]"
    , "min-w-[360px]"
    , "shadow-[0_4px_14px_rgba(0,0,0,0.04)]"
    , "flex items-center gap-sm"
    , "before:content-[''] before:absolute"
    ]

{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}

{-# HLINT ignore "Use fmap" #-}
module Qasm3To2Tests where

import Ast
import Ast qualified
import Chatty
import Control.Monad
import Data.Either (fromRight)
import Data.Functor
import Debug.Trace (trace)
import Qasm2 qualified
import Qasm3.Parser qualified as Q3P
import Qasm3.Syntax
import Qasm3.Test.Arbitrary qualified as Q3A
import System.Exit (exitFailure)
import System.IO
import Test.HUnit
import Test.QuickCheck

testAstEquivalence = TestLabel "AST Equivalence" $ TestCase $ do
  genAst <- generate (Q3A.arbitraryProgramNode cfg)

  let str = pretty genAst
  let parseResult = Q3P.parseString str <&> syntaxTreeFrom
  let ast = syntaxTreeFrom genAst
  let isEquivalent = fromChattyValue Ast.NilNode parseResult == ast
  unless
    isEquivalent
    ( do
        hFlush stdout
        putStrLn ""
        putStrLn $ "Emitted source:\n" ++ str ++ "\n"
        putStrLn $ "Original AST:\n" ++ show genAst ++ "\n"
        putStrLn $ "Parsed AST:\n" ++ show parseResult ++ "\n"
        hFlush stdout
    )

  assertBool "Round-Trip AST Equivalent" (fromChattyValue Ast.NilNode parseResult == ast)

testParseExample exampleBaseName = TestLabel "Parse Examples" $ TestCase $ do
  qasmStr <- readFile $ exampleBaseName ++ ".qasm"
  astStr <- readFile $ exampleBaseName ++ ".ast"
  let expectedAst = read astStr
  let parseResult = Q3P.parseString qasmStr <&> syntaxTreeFrom
  let isEquivalent = fromChattyValue Ast.NilNode parseResult == expectedAst
  unless
    isEquivalent
    ( do
        putStrLn ""
        putStrLn $ case parseResult of
          Chatty.ChattyFailure msgs _ -> concat msgs
          Chatty.ChattyValue _ ast -> "Parsed AST:\n" ++ show ast ++ "\n\nPretty source:\n" ++ pretty ast
        hFlush stdout
    )
  assertBool "Expected AST Equivalent" isEquivalent

tests =
  TestList
    [ testParseExample "test-data/00-trivial",
      testParseExample "test-data/01-end",
      testParseExample "test-data/10-basic",
      testParseExample "openqasm-examples/adder",
      testParseExample "openqasm-examples/alignment",
      -- testParseExample "openqasm-examples/arrays",
      -- testParseExample "openqasm-examples/cphase",
      testParseExample "openqasm-examples/dd",
      -- testParseExample "openqasm-examples/defcal",
      testParseExample "openqasm-examples/gateteleport",
      -- testParseExample "openqasm-examples/inverseqft1",
      testParseExample "openqasm-examples/inverseqft2",
      testParseExample "openqasm-examples/ipe",
      testParseExample "openqasm-examples/msd",
      testParseExample "openqasm-examples/qec",
      testParseExample "openqasm-examples/qft",
      testParseExample "openqasm-examples/qpt",
      testParseExample "openqasm-examples/rb",
      -- testParseExample "openqasm-examples/rus",
      testParseExample "openqasm-examples/scqec",
      -- testParseExample "openqasm-examples/stdgates",
      -- testParseExample "openqasm-examples/t1",
      testParseExample "openqasm-examples/teleport",
      -- testParseExample "openqasm-examples/varteleport",
      testParseExample "openqasm-examples/vqe"
    ]

cfg = Q3A.defaultConfig

prop_roundTrip = forAll (Q3A.arbitraryProgramNode cfg) $
  \ast -> syntaxTreeFrom ast == syntaxTreeFrom (fromChattyValue Ast.NilNode $ Q3P.parseString (pretty ast))

main :: IO ()
main = do
  count <- runTestTT tests
  unless (failures count == 0) exitFailure

  result <- verboseCheckResult (withMaxSuccess 10000 prop_roundTrip)
  unless (isSuccess result) exitFailure

--ast =


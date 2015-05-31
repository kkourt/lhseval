I have been writing lots of Haskell code. In fact, I've been writing so much
Haskell code that in a shell script I wrote:

    awk '{ print $2 }' $ ghc-mod doc $m

instead of:

    ghc-mod doc $m | awk '{ print $2 }'

In any case, Haskell has [great
support](https://wiki.haskell.org/Literate_programming) for [literate
programming](http://en.wikipedia.org/wiki/Literate_programming) which I think is
great, so I decided to try it.

Now, for explaining code is really useful to have examples like this one:

~~~~ {eval=}
[y | x <- [1..10], let y = x +1, odd x]
~~~~

It would be good if you actually evaluate the result above to avoid potential
embarrassments.  The simplest way to do it is to fire up `ghci`, execute the
expression, and copy-paste the result.

However, coders hate copy-paste (or maybe it's just me), and ideally we would
like to avoid it. One solution is to use `lhs2Tex` which has an `\eval{}`
command. `lhs2Tex` translates only to LaTeX though, so it's not ideal for
generating html or other formats.  [Pandoc](http://pandoc.org/), on the other
hand, supports many formats for input and output (including markup), but
unfortunately does not support an eval (or similar) function for literate
Haskell files. It does support scripting, however, so it might not be too
difficult to extend it accordingly.

Let's start with the necessary modules from the Pandoc library.

\begin{code}
import qualified Text.Pandoc as TP
import Text.Pandoc.Walk (walkM)
\end{code}

To do it, we need support for evaluating Haskell code. Fortunately, there is
a module for this:

\begin{code}
import qualified Language.Haskell.Interpreter as LHI
\end{code}


And a bunch of more imports we are going to need:

\begin{code}
import Control.Applicative ((<$>))
import System.Environment (getArgs)
\end{code}

Now what we would like is given code like this:
\begin{code}
myfn :: Int -> Int
myfn x = x + 10
\end{code}

And this in the lhs file:

    ~~~~ {eval=}
    myfn 3
    ~~~~

To produce:

~~~~ {eval=}
myfn 3
~~~~

Without knowing anything about either Pandoc or LHI, the following two examples
can help to do a quick-and-dirty implementation:

- [http://johnmacfarlane.net/pandoc/scripting.html#include-files](http://johnmacfarlane.net/pandoc/scripting.html#include-files)
- [http://hub.darcs.net/jcpetruzza/hint/browse/examples/example.hs](http://hub.darcs.net/jcpetruzza/hint/browse/examples/example.hs)

You can find the source code in:
[https://github.com/kkourt/lhseval](https://github.com/kkourt/lhseval)

\begin{code}

say :: String -> LHI.Interpreter ()
say = LHI.liftIO . putStrLn

doEval :: TP.Block -> LHI.Interpreter TP.Block
doEval cb@(TP.CodeBlock (id, classes, namevals) contents) = do
    r <- LHI.eval contents
    let contents' = contents ++ " => " ++ r
    return $ TP.CodeBlock (id, classes, namevals) contents'


evalBlock :: TP.Block -> LHI.Interpreter TP.Block
evalBlock cb@(TP.CodeBlock (id, classes, namevals) contents) = do
    case lookup "eval" namevals of
        Just f -> doEval cb
        Nothing -> return cb
evalBlock x = do
    return x

evalDoc :: [String] -> TP.Pandoc -> LHI.Interpreter TP.Pandoc
evalDoc modules d = do
    -- force modules to be interpreted (otherwise using this file on itself
    -- fails)
    -- http://stackoverflow.com/questions/7134520/why-cannot-top-level-module-be-set-to-main-in-hint
    let imports = [ "*" ++ m | m <- modules]
    LHI.loadModules imports
    xs <- LHI.getLoadedModules
    -- set them as top-level modules so that all of their functions (not only
    -- the ones exported) can be accessed
    LHI.setTopLevelModules xs
    LHI.setImports ["Prelude"]
    nd <- walkM evalBlock d
    return nd

main :: IO ()
main = do
    -- modules to load
    modules <- getArgs
    docin <- TP.readNative <$> getContents
    docout <- LHI.runInterpreter (evalDoc modules docin)
    case docout of
        Left err  -> error $ "Error in evaluation:" ++ (show err)
        Right res -> putStr $ TP.writeMarkdown TP.def res
    return ()

\end{code}

TODO:

 - Add testing functionality à la Python's
   [doctest](https://docs.python.org/2/library/doctest.html)

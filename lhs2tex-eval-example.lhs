\documentclass{article}

%include polycode.fmt
%options ghci -fglasgow-exts

\begin{document}
My function:
\begin{code}
myfn :: Int -> Int
myfn x = x + 10
\end{code}

Example:
|myfn 3| $\Rightarrow$ \eval{myfn 3}
\end{document}

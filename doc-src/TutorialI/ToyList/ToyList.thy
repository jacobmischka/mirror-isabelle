theory ToyList = PreList:

text{*\noindent
HOL already has a predefined theory of lists called \isa{List} ---
\isa{ToyList} is merely a small fragment of it chosen as an example. In
contrast to what is recommended in \S\ref{sec:Basic:Theories},
\isa{ToyList} is not based on \isa{Main} but on \isa{PreList}, a
theory that contains pretty much everything but lists, thus avoiding
ambiguities caused by defining lists twice.
*}

datatype 'a list = Nil                          ("[]")
                 | Cons 'a "'a list"            (infixr "#" 65);

text{*\noindent
The datatype\index{*datatype} \isaindexbold{list} introduces two
constructors \isaindexbold{Nil} and \isaindexbold{Cons}, the
empty list and the operator that adds an element to the front of a list. For
example, the term \isa{Cons True (Cons   False Nil)} is a value of type
\isa{bool~list}, namely the list with the elements \isa{True} and
\isa{False}. Because this notation becomes unwieldy very quickly, the
datatype declaration is annotated with an alternative syntax: instead of
\isa{Nil} and \isa{Cons~$x$~$xs$} we can write
\isa{[]}\index{$HOL2list@\texttt{[]}|bold} and
\isa{$x$~\#~$xs$}\index{$HOL2list@\texttt{\#}|bold}. In fact, this
alternative syntax is the standard syntax. Thus the list \isa{Cons True
(Cons False Nil)} becomes \isa{True \# False \# []}. The annotation
\isacommand{infixr}\indexbold{*infixr} means that \isa{\#} associates to
the right, i.e.\ the term \isa{$x$ \# $y$ \# $z$} is read as \isa{$x$
\# ($y$ \# $z$)} and not as \isa{($x$ \# $y$) \# $z$}.

\begin{warn}
  Syntax annotations are a powerful but completely optional feature. You
  could drop them from theory \isa{ToyList} and go back to the identifiers
  \isa{Nil} and \isa{Cons}. However, lists are such a central datatype
  that their syntax is highly customized. We recommend that novices should
  not use syntax annotations in their own theories.
\end{warn}
Next, two functions \isa{app} and \isaindexbold{rev} are declared:
*}

consts app :: "'a list \\<Rightarrow> 'a list \\<Rightarrow> 'a list"   (infixr "@" 65)
       rev :: "'a list \\<Rightarrow> 'a list";

text{*
\noindent
In contrast to ML, Isabelle insists on explicit declarations of all functions
(keyword \isacommand{consts}).  (Apart from the declaration-before-use
restriction, the order of items in a theory file is unconstrained.) Function
\isa{app} is annotated with concrete syntax too. Instead of the prefix
syntax \isa{app~$xs$~$ys$} the infix
\isa{$xs$~\at~$ys$}\index{$HOL2list@\texttt{\at}|bold} becomes the preferred
form. Both functions are defined recursively:
*}

primrec
"[] @ ys       = ys"
"(x # xs) @ ys = x # (xs @ ys)";

primrec
"rev []        = []"
"rev (x # xs)  = (rev xs) @ (x # [])";

text{*
\noindent
The equations for \isa{app} and \isa{rev} hardly need comments:
\isa{app} appends two lists and \isa{rev} reverses a list.  The keyword
\isacommand{primrec}\index{*primrec} indicates that the recursion is of a
particularly primitive kind where each recursive call peels off a datatype
constructor from one of the arguments.  Thus the
recursion always terminates, i.e.\ the function is \bfindex{total}.

The termination requirement is absolutely essential in HOL, a logic of total
functions. If we were to drop it, inconsistencies would quickly arise: the
``definition'' $f(n) = f(n)+1$ immediately leads to $0 = 1$ by subtracting
$f(n)$ on both sides.
% However, this is a subtle issue that we cannot discuss here further.

\begin{warn}
  As we have indicated, the desire for total functions is not a gratuitously
  imposed restriction but an essential characteristic of HOL. It is only
  because of totality that reasoning in HOL is comparatively easy.  More
  generally, the philosophy in HOL is not to allow arbitrary axioms (such as
  function definitions whose totality has not been proved) because they
  quickly lead to inconsistencies. Instead, fixed constructs for introducing
  types and functions are offered (such as \isacommand{datatype} and
  \isacommand{primrec}) which are guaranteed to preserve consistency.
\end{warn}

A remark about syntax.  The textual definition of a theory follows a fixed
syntax with keywords like \isacommand{datatype} and \isacommand{end} (see
Fig.~\ref{fig:keywords} in Appendix~\ref{sec:Appendix} for a full list).
Embedded in this syntax are the types and formulae of HOL, whose syntax is
extensible, e.g.\ by new user-defined infix operators
(see~\ref{sec:infix-syntax}). To distinguish the two levels, everything
HOL-specific (terms and types) should be enclosed in
\texttt{"}\dots\texttt{"}. 
To lessen this burden, quotation marks around a single identifier can be
dropped, unless the identifier happens to be a keyword, as in
*}

consts "end" :: "'a list \\<Rightarrow> 'a"

text{*\noindent
When Isabelle prints a syntax error message, it refers to the HOL syntax as
the \bfindex{inner syntax} and the enclosing theory language as the \bfindex{outer syntax}.


\section{An introductory proof}
\label{sec:intro-proof}

Assuming you have input the declarations and definitions of \texttt{ToyList}
presented so far, we are ready to prove a few simple theorems. This will
illustrate not just the basic proof commands but also the typical proof
process.

\subsubsection*{Main goal: \texttt{rev(rev xs) = xs}}

Our goal is to show that reversing a list twice produces the original
list. The input line
*}

theorem rev_rev [simp]: "rev(rev xs) = xs";

txt{*\index{*theorem|bold}\index{*simp (attribute)|bold}
\begin{itemize}
\item
establishes a new theorem to be proved, namely \isa{rev(rev xs) = xs},
\item
gives that theorem the name \isa{rev_rev} by which it can be referred to,
\item
and tells Isabelle (via \isa{[simp]}) to use the theorem (once it has been
proved) as a simplification rule, i.e.\ all future proofs involving
simplification will replace occurrences of \isa{rev(rev xs)} by
\isa{xs}.

The name and the simplification attribute are optional.
\end{itemize}
Isabelle's response is to print
\begin{isabellepar}%
proof(prove):~step~0\isanewline
\isanewline
goal~(theorem~rev\_rev):\isanewline
rev~(rev~xs)~=~xs\isanewline
~1.~rev~(rev~xs)~=~xs
\end{isabellepar}%
The first three lines tell us that we are 0 steps into the proof of
theorem \isa{rev_rev}; for compactness reasons we rarely show these
initial lines in this tutorial. The remaining lines display the current
proof state.
Until we have finished a proof, the proof state always looks like this:
\begin{isabellepar}%
$G$\isanewline
~1.~$G\sb{1}$\isanewline
~~\vdots~~\isanewline
~$n$.~$G\sb{n}$
\end{isabellepar}%
where $G$
is the overall goal that we are trying to prove, and the numbered lines
contain the subgoals $G\sb{1}$, \dots, $G\sb{n}$ that we need to prove to
establish $G$. At \isa{step 0} there is only one subgoal, which is
identical with the overall goal.  Normally $G$ is constant and only serves as
a reminder. Hence we rarely show it in this tutorial.

Let us now get back to \isa{rev(rev xs) = xs}. Properties of recursively
defined functions are best established by induction. In this case there is
not much choice except to induct on \isa{xs}:
*}

apply(induct_tac xs);

txt{*\noindent\index{*induct_tac}%
This tells Isabelle to perform induction on variable \isa{xs}. The suffix
\isa{tac} stands for ``tactic'', a synonym for ``theorem proving function''.
By default, induction acts on the first subgoal. The new proof state contains
two subgoals, namely the base case (\isa{Nil}) and the induction step
(\isa{Cons}):
\begin{isabellepar}%
~1.~rev~(rev~[])~=~[]\isanewline
~2.~{\isasymAnd}a~list.~rev(rev~list)~=~list~{\isasymLongrightarrow}~rev(rev(a~\#~list))~=~a~\#~list%
\end{isabellepar}%

The induction step is an example of the general format of a subgoal:
\begin{isabellepar}%
~$i$.~{\indexboldpos{\isasymAnd}{$IsaAnd}}$x\sb{1}$~\dots~$x\sb{n}$.~{\it assumptions}~{\isasymLongrightarrow}~{\it conclusion}
\end{isabellepar}%
The prefix of bound variables \isasymAnd$x\sb{1}$~\dots~$x\sb{n}$ can be
ignored most of the time, or simply treated as a list of variables local to
this subgoal. Their deeper significance is explained in \S\ref{sec:PCproofs}.
The {\it assumptions} are the local assumptions for this subgoal and {\it
  conclusion} is the actual proposition to be proved. Typical proof steps
that add new assumptions are induction or case distinction. In our example
the only assumption is the induction hypothesis \isa{rev (rev list) =
  list}, where \isa{list} is a variable name chosen by Isabelle. If there
are multiple assumptions, they are enclosed in the bracket pair
\indexboldpos{\isasymlbrakk}{$Isabrl} and
\indexboldpos{\isasymrbrakk}{$Isabrr} and separated by semicolons.

%FIXME indent!
Let us try to solve both goals automatically:
*}

apply(auto);

txt{*\noindent
This command tells Isabelle to apply a proof strategy called
\isa{auto} to all subgoals. Essentially, \isa{auto} tries to
``simplify'' the subgoals.  In our case, subgoal~1 is solved completely (thanks
to the equation \isa{rev [] = []}) and disappears; the simplified version
of subgoal~2 becomes the new subgoal~1:
\begin{isabellepar}%
~1.~\dots~rev(rev~list)~=~list~{\isasymLongrightarrow}~rev(rev~list~@~a~\#~[])~=~a~\#~list
\end{isabellepar}%
In order to simplify this subgoal further, a lemma suggests itself.
*}
(*<*)
oops
(*>*)

text{*
\subsubsection*{First lemma: \texttt{rev(xs \at~ys) = (rev ys) \at~(rev xs)}}

After abandoning the above proof attempt\indexbold{abandon proof} (at the shell level type
\isacommand{oops}) we start a new proof:
*}

lemma rev_app [simp]: "rev(xs @ ys) = (rev ys) @ (rev xs)";

txt{*\noindent The keywords \isacommand{theorem}\index{*theorem} and
\isacommand{lemma}\indexbold{*lemma} are interchangable and merely indicate
the importance we attach to a proposition. In general, we use the words
\emph{theorem}\index{theorem} and \emph{lemma}\index{lemma} pretty much
interchangeably.

There are two variables that we could induct on: \isa{xs} and
\isa{ys}. Because \isa{\at} is defined by recursion on
the first argument, \isa{xs} is the correct one:
*}

apply(induct_tac xs);

txt{*\noindent
This time not even the base case is solved automatically:
*}

apply(auto);

txt{*
\begin{isabellepar}%
~1.~rev~ys~=~rev~ys~@~[]\isanewline
~2. \dots
\end{isabellepar}%
Again, we need to abandon this proof attempt and prove another simple lemma first.
In the future the step of abandoning an incomplete proof before embarking on
the proof of a lemma usually remains implicit.
*}
(*<*)
oops
(*>*)

text{*
\subsubsection*{Second lemma: \texttt{xs \at~[] = xs}}

This time the canonical proof procedure
*}

lemma app_Nil2 [simp]: "xs @ [] = xs";
apply(induct_tac xs);
apply(auto);

txt{*
\noindent
leads to the desired message \isa{No subgoals!}:
\begin{isabellepar}%
xs~@~[]~=~xs\isanewline
No~subgoals!
\end{isabellepar}%

We still need to confirm that the proof is now finished:
*}

.

text{*\noindent\indexbold{$Isar@\texttt{.}}%
As a result of that final dot, Isabelle associates the lemma
just proved with its name. Notice that in the lemma \isa{app_Nil2} (as
printed out after the final dot) the free variable \isa{xs} has been
replaced by the unknown \isa{?xs}, just as explained in
\S\ref{sec:variables}. Note that instead of instead of \isacommand{apply}
followed by a dot, you can simply write \isacommand{by}\indexbold{by},
which we do most of the time.

Going back to the proof of the first lemma
*}

lemma rev_app [simp]: "rev(xs @ ys) = (rev ys) @ (rev xs)";
apply(induct_tac xs);
apply(auto);

txt{*
\noindent
we find that this time \isa{auto} solves the base case, but the
induction step merely simplifies to
\begin{isabellepar}
~1.~{\isasymAnd}a~list.\isanewline
~~~~~~~rev~(list~@~ys)~=~rev~ys~@~rev~list~{\isasymLongrightarrow}\isanewline
~~~~~~~(rev~ys~@~rev~list)~@~a~\#~[]~=~rev~ys~@~rev~list~@~a~\#~[]
\end{isabellepar}%
Now we need to remember that \isa{\at} associates to the right, and that
\isa{\#} and \isa{\at} have the same priority (namely the \isa{65}
in their \isacommand{infixr} annotation). Thus the conclusion really is
\begin{isabellepar}%
~~~~~(rev~ys~@~rev~list)~@~(a~\#~[])~=~rev~ys~@~(rev~list~@~(a~\#~[]))%
\end{isabellepar}%
and the missing lemma is associativity of \isa{\at}.

\subsubsection*{Third lemma: \texttt{(xs \at~ys) \at~zs = xs \at~(ys \at~zs)}}

Abandoning the previous proof, the canonical proof procedure
*}


txt_raw{*\begin{comment}*}
oops
text_raw{*\end{comment}*}

lemma app_assoc [simp]: "(xs @ ys) @ zs = xs @ (ys @ zs)";
apply(induct_tac xs);
by(auto);

text{*
\noindent
succeeds without further ado.

Now we can go back and prove the first lemma
*}

lemma rev_app [simp]: "rev(xs @ ys) = (rev ys) @ (rev xs)";
apply(induct_tac xs);
by(auto);

text{*\noindent
and then solve our main theorem:
*}

theorem rev_rev [simp]: "rev(rev xs) = xs";
apply(induct_tac xs);
by(auto);

text{*\noindent
The final \isa{end} tells Isabelle to close the current theory because
we are finished with its development:
*}

end

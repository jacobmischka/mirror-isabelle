(*  Title: 	HOLCF/cprod3.thy
    ID:         $Id$
    Author: 	Franz Regensburger
    Copyright   1993 Technische Universitaet Muenchen


Class instance of  * for class pcpo

*)

Cprod3 = Cprod2 +

arities "*" :: (pcpo,pcpo)pcpo			(* Witness cprod2.ML *)

consts  
	cpair        :: "'a -> 'b -> ('a*'b)" (* continuous  pairing *)
	cfst         :: "('a*'b)->'a"
	csnd         :: "('a*'b)->'b"
	csplit       :: "('a->'b->'c)->('a*'b)->'c"

syntax	
	"@ctuple"    :: "['a, args] => 'a * 'b"		("(1<_,/ _>)")


translations 
	"<x, y, z>"   == "<x, <y, z>>"
	"<x, y>"      == "cpair`x`y"

rules 

inst_cprod_pcpo	"(UU::'a*'b) = (UU,UU)"

defs
cpair_def	"cpair  == (LAM x y.(x,y))"
cfst_def	"cfst   == (LAM p.fst(p))"
csnd_def	"csnd   == (LAM p.snd(p))"	
csplit_def	"csplit == (LAM f p.f`(cfst`p)`(csnd`p))"

end





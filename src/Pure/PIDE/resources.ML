(*  Title:      Pure/PIDE/resources.ML
    Author:     Makarius

Resources for theories and auxiliary files.
*)

signature RESOURCES =
sig
  val default_qualifier: string
  val init_session_base:
    {session_positions: (string * Properties.T) list,
     session_directories: (string * string) list,
     docs: string list,
     global_theories: (string * string) list,
     loaded_theories: string list} -> unit
  val finish_session_base: unit -> unit
  val global_theory: string -> string option
  val loaded_theory: string -> bool
  val check_session: Proof.context -> string * Position.T -> string
  val check_doc: Proof.context -> string * Position.T -> string
  val master_directory: theory -> Path.T
  val imports_of: theory -> (string * Position.T) list
  val begin_theory: Path.T -> Thy_Header.header -> theory list -> theory
  val thy_path: Path.T -> Path.T
  val theory_qualifier: string -> string
  val find_theory_file: string -> Path.T option
  val import_name: string -> Path.T -> string ->
    {node_name: Path.T, master_dir: Path.T, theory_name: string}
  val check_thy: Path.T -> string ->
   {master: Path.T * SHA1.digest, text: string, theory_pos: Position.T,
    imports: (string * Position.T) list, keywords: Thy_Header.keywords}
  val parse_files: string -> (theory -> Token.file list) parser
  val provide: Path.T * SHA1.digest -> theory -> theory
  val provide_file: Token.file -> theory -> theory
  val provide_parse_files: string -> (theory -> Token.file list * theory) parser
  val loaded_files_current: theory -> bool
  val check_path: Proof.context -> Path.T option -> string * Position.T -> Path.T
  val check_file: Proof.context -> Path.T option -> string * Position.T -> Path.T
  val check_dir: Proof.context -> Path.T option -> string * Position.T -> Path.T
end;

structure Resources: RESOURCES =
struct

(* session base *)

val default_qualifier = "Draft";

type entry = {pos: Position.T, serial: serial};

fun make_entry props : entry =
  {pos = Position.of_properties props, serial = serial ()};

val empty_session_base =
  {session_positions = []: (string * entry) list,
   session_directories = Symtab.empty: Path.T list Symtab.table,
   docs = []: (string * entry) list,
   global_theories = Symtab.empty: string Symtab.table,
   loaded_theories = Symtab.empty: unit Symtab.table};

val global_session_base =
  Synchronized.var "Sessions.base" empty_session_base;

fun init_session_base
    {session_positions, session_directories, docs, global_theories, loaded_theories} =
  Synchronized.change global_session_base
    (fn _ =>
      {session_positions = sort_by #1 (map (apsnd make_entry) session_positions),
       session_directories =
         fold_rev (fn (dir, name) => Symtab.cons_list (name, Path.explode dir))
           session_directories Symtab.empty,
       docs = sort_by #1 (map (apsnd make_entry o rpair []) docs),
       global_theories = Symtab.make global_theories,
       loaded_theories = Symtab.make_set loaded_theories});

fun finish_session_base () =
  Synchronized.change global_session_base
    (fn {global_theories, loaded_theories, ...} =>
      {session_positions = [],
       session_directories = Symtab.empty,
       docs = [],
       global_theories = global_theories,
       loaded_theories = loaded_theories});

fun get_session_base f = f (Synchronized.value global_session_base);

fun global_theory a = Symtab.lookup (get_session_base #global_theories) a;
fun loaded_theory a = Symtab.defined (get_session_base #loaded_theories) a;

fun check_name which kind markup ctxt (name, pos) =
  let val entries = get_session_base which in
    (case AList.lookup (op =) entries name of
      SOME entry => (Context_Position.report ctxt pos (markup name entry); name)
    | NONE =>
        let
          val completion_report =
            Completion.make_report (name, pos)
              (fn completed =>
                entries
                |> map #1
                |> filter completed
                |> sort_strings
                |> map (fn a => (a, (kind, a))));
        in error ("Bad " ^ kind ^ " " ^ quote name ^ Position.here pos ^ completion_report) end)
  end;

fun markup_session name {pos, serial} =
  Markup.properties
    (Position.entity_properties_of false serial pos) (Markup.entity Markup.sessionN name);

val check_session = check_name #session_positions "session" markup_session;
val check_doc = check_name #docs "documentation" (fn name => fn _ => Markup.doc name);


(* manage source files *)

type files =
 {master_dir: Path.T,  (*master directory of theory source*)
  imports: (string * Position.T) list,  (*source specification of imports*)
  provided: (Path.T * SHA1.digest) list};  (*source path, digest*)

fun make_files (master_dir, imports, provided): files =
 {master_dir = master_dir, imports = imports, provided = provided};

structure Files = Theory_Data
(
  type T = files;
  val empty = make_files (Path.current, [], []);
  fun extend _ = empty;
  fun merge _ = empty;
);

fun map_files f =
  Files.map (fn {master_dir, imports, provided} =>
    make_files (f (master_dir, imports, provided)));


val master_directory = #master_dir o Files.get;
val imports_of = #imports o Files.get;

fun begin_theory master_dir {name, imports, keywords} parents =
  Theory.begin_theory name parents
  |> map_files (fn _ => (Path.explode (Path.smart_implode master_dir), imports, []))
  |> Thy_Header.add_keywords keywords;


(* theory files *)

val thy_path = Path.ext "thy";

fun theory_qualifier theory =
  (case global_theory theory of
    SOME qualifier => qualifier
  | NONE => Long_Name.qualifier theory);

fun theory_name qualifier theory =
  if Long_Name.is_qualified theory orelse is_some (global_theory theory)
  then theory
  else Long_Name.qualify qualifier theory;

fun find_theory_file thy_name =
  let
    val thy_file = thy_path (Path.basic (Long_Name.base_name thy_name));
    val session = theory_qualifier thy_name;
    val dirs = Symtab.lookup_list (get_session_base #session_directories) session;
  in
    dirs |> get_first (fn dir =>
      let val path = Path.append dir thy_file
      in if File.is_file path then SOME path else NONE end)
  end;

fun make_theory_node node_name theory =
  {node_name = node_name, master_dir = Path.dir node_name, theory_name = theory};

fun loaded_theory_node theory =
  {node_name = Path.basic theory, master_dir = Path.current, theory_name = theory};

fun import_name qualifier dir s =
  let
    val theory = theory_name qualifier (Thy_Header.import_name s);
    fun theory_node () =
      make_theory_node (File.full_path dir (thy_path (Path.expand (Path.explode s)))) theory;
  in
    if not (Thy_Header.is_base_name s) then theory_node ()
    else if loaded_theory theory then loaded_theory_node theory
    else
      (case find_theory_file theory of
        SOME node_name => make_theory_node node_name theory
      | NONE => if Long_Name.is_qualified s then loaded_theory_node theory else theory_node ())
  end;

fun check_file dir file = File.check_file (File.full_path dir file);

fun check_thy dir thy_name =
  let
    val thy_base_name = Long_Name.base_name thy_name;
    val master_file =
      (case find_theory_file thy_name of
        SOME path => check_file Path.current path
      | NONE => check_file dir (thy_path (Path.basic thy_base_name)));
    val text = File.read master_file;

    val {name = (name, pos), imports, keywords} =
      Thy_Header.read (Path.position master_file) text;
    val _ =
      thy_base_name <> name andalso
        error ("Bad theory name " ^ quote name ^
          " for file " ^ Path.print (Path.base master_file) ^ Position.here pos);
  in
   {master = (master_file, SHA1.digest text), text = text, theory_pos = pos,
    imports = imports, keywords = keywords}
  end;


(* load files *)

fun parse_files cmd =
  Scan.ahead Parse.not_eof -- Parse.path >> (fn (tok, name) => fn thy =>
    (case Token.get_files tok of
      [] =>
        let
          val keywords = Thy_Header.get_keywords thy;
          val master_dir = master_directory thy;
          val pos = Token.pos_of tok;
          val src_paths = Keyword.command_files keywords cmd (Path.explode name);
        in map (Command.read_file master_dir pos) src_paths end
    | files => map Exn.release files));

fun provide (src_path, id) =
  map_files (fn (master_dir, imports, provided) =>
    if AList.defined (op =) provided src_path then
      error ("Duplicate use of source file: " ^ Path.print src_path)
    else (master_dir, imports, (src_path, id) :: provided));

fun provide_file (file: Token.file) = provide (#src_path file, #digest file);

fun provide_parse_files cmd =
  parse_files cmd >> (fn files => fn thy =>
    let
      val fs = files thy;
      val thy' = fold (fn {src_path, digest, ...} => provide (src_path, digest)) fs thy;
    in (fs, thy') end);

fun load_file thy src_path =
  let
    val full_path = check_file (master_directory thy) src_path;
    val text = File.read full_path;
    val id = SHA1.digest text;
  in ((full_path, id), text) end;

fun loaded_files_current thy =
  #provided (Files.get thy) |>
    forall (fn (src_path, id) =>
      (case try (load_file thy) src_path of
        NONE => false
      | SOME ((_, id'), _) => id = id'));


(* formal check *)

fun formal_check check_file ctxt opt_dir (name, pos) =
  let
    fun err msg = error (msg ^ Position.here pos);

    val _ = Context_Position.report ctxt pos Markup.language_path;
    val dir =
      (case opt_dir of
        SOME dir => dir
      | NONE => master_directory (Proof_Context.theory_of ctxt));
    val path = Path.append dir (Path.explode name) handle ERROR msg => err msg;
    val _ = Path.expand path handle ERROR msg => err msg;
    val _ = Context_Position.report ctxt pos (Markup.path (Path.smart_implode path));
    val _ = check_file path handle ERROR msg => err msg;
  in path end;

val check_path = formal_check I;
val check_file = formal_check File.check_file;
val check_dir = formal_check File.check_dir;


(* antiquotations *)

local

fun document_antiq (check: Proof.context -> Path.T option -> string * Position.T -> Path.T) =
  Args.context -- Scan.lift (Parse.position Parse.path) >> (fn (ctxt, (name, pos)) =>
    let
      val _ = check ctxt NONE (name, pos);
      val latex =
        space_explode "/" name
        |> map Latex.output_ascii
        |> space_implode (Latex.output_ascii "/" ^ "\\discretionary{}{}{}");
    in Latex.enclose_block "\\isatt{" "}" [Latex.string latex] end);

fun ML_antiq check =
  Args.context -- Scan.lift (Parse.position Parse.path) >> (fn (ctxt, (name, pos)) =>
    check ctxt (SOME Path.current) (name, pos) |> ML_Syntax.print_path);

in

val _ = Theory.setup
 (Thy_Output.antiquotation_verbatim_embedded \<^binding>\<open>session\<close>
    (Scan.lift Parse.embedded_position) check_session #>
  Thy_Output.antiquotation_verbatim_embedded \<^binding>\<open>doc\<close>
    (Scan.lift Parse.embedded_position) check_doc #>
  Thy_Output.antiquotation_raw_embedded \<^binding>\<open>path\<close> (document_antiq check_path) (K I) #>
  Thy_Output.antiquotation_raw_embedded \<^binding>\<open>file\<close> (document_antiq check_file) (K I) #>
  Thy_Output.antiquotation_raw_embedded \<^binding>\<open>dir\<close> (document_antiq check_dir) (K I) #>
  ML_Antiquotation.value_embedded \<^binding>\<open>path\<close> (ML_antiq check_path) #>
  ML_Antiquotation.value_embedded \<^binding>\<open>file\<close> (ML_antiq check_file) #>
  ML_Antiquotation.value_embedded \<^binding>\<open>dir\<close> (ML_antiq check_dir) #>
  ML_Antiquotation.value_embedded \<^binding>\<open>path_binding\<close>
    (Scan.lift (Parse.position Parse.path) >>
      (ML_Syntax.print_path_binding o Path.explode_binding)) #>
  ML_Antiquotation.value \<^binding>\<open>master_dir\<close>
    (Args.theory >> (ML_Syntax.print_path o master_directory)));

end;

end;

/*  Title:      Pure/Tools/ci_profile.scala
    Author:     Lars Hupel

Build profile for continuous integration services.
*/

package isabelle


abstract class CI_Profile extends Isabelle_Tool.Body
{

  private def print_variable(name: String): Unit =
  {
    val value = Isabelle_System.getenv_strict(name)
    println(s"""$name="$value"""")
  }

  protected def hg_id(path: Path): String =
    Isabelle_System.hg("id -i", path.file).out

  private def build(options: Options): Build.Results =
  {
    val progress = new Console_Progress(true)
    progress.interrupt_handler {
      Build.build(
        options = options,
        progress = progress,
        clean_build = true,
        verbose = true,
        max_jobs = jobs,
        dirs = include,
        select_dirs = select,
        session_groups = groups,
        all_sessions = all,
        exclude_session_groups = exclude,
        system_mode = true
      )
    }
  }


  override final def apply(args: List[String]): Unit =
  {
    List("ML_PLATFORM", "ML_HOME", "ML_SYSTEM", "ML_OPTIONS").foreach(print_variable)
    val isabelle_home = Path.explode(Isabelle_System.getenv_strict("ISABELLE_HOME"))
    println(s"Build for repository Isabelle/${hg_id(isabelle_home)}")

    val options =
      Options.init()
        .bool.update("browser_info", true)
        .string.update("document", "pdf")
        .string.update("document_variants", "document:outline=/proof,/ML")
        .int.update("parallel_proofs", 2)
        .int.update("threads", threads)

    pre_hook(args)

    val results = build(options)

    if (!results.ok) {
      println()
      println("=== FAILED SESSIONS ===")

      for (name <- results.sessions) {
        if (results.cancelled(name)) {
          println(s"Session $name: CANCELLED")
        }
        else {
          val result = results(name)
          if (!result.ok)
            println(s"Session $name: FAILED ${result.rc}")
        }
      }
    }

    post_hook(results)

    System.exit(results.rc)
  }


  /* profile */

  def threads: Int
  def jobs: Int
  def all: Boolean
  def groups: List[String]
  def exclude: List[String]
  def include: List[Path]
  def select: List[Path]

  def pre_hook(args: List[String]): Unit
  def post_hook(results: Build.Results): Unit

}
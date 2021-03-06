/*  Author:     Makarius

Main Isabelle application executable.
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <libgen.h>


static void fail(const char *msg)
{
  fprintf(stderr, "%s\n", msg);
  exit(2);
}


int main(int argc, char *argv[])
{
  char **cmd_line = NULL, *cmd = NULL, *dcmd = NULL, *bcmd = NULL, *dname = NULL, *bname = NULL;
  int i = 0;

  dcmd = strdup(argv[0]); dname = dirname(dcmd);
  bcmd = strdup(argv[0]); bname = basename(bcmd);

  cmd_line = malloc(sizeof(char *) * (argc + 1));
  if (cmd_line == NULL) fail("Failed to allocate command line");

  cmd = cmd_line[0];
  cmd = malloc(strlen(dname) + strlen(bname) + strlen("/lib/scripts/.run") + 1);
  if (cmd == NULL) fail("Failed to allocate command name");
  sprintf(cmd, "%s/lib/scripts/%s.run", dname, bname);

  for (i = 1; i < argc; i++) cmd_line[i] = argv[i];

  cmd_line[argc] = NULL;

  execvp(cmd, cmd_line);
  fprintf(stderr, "Failed to execute application script \"%s\"\n", cmd);
  exit(2);
}

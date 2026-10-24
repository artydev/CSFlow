"""Tests unitaires des nœuds : contrat de sortie normalisé.

Le contrat que ces tests verrouillent :
  - output / stdout / stderr sont STRIPPÉS (pas de '\n' final) — c'est ce qui rend
    les comparaisons de skip_if ("'{{x.output}}' != 'ROUGE'") fiables ;
  - returncode est un int ;
  - le contenu interne multiligne est conservé (\r\n normalisé pour les tests).
"""

import contextlib
import io
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from nodes.python_node import python  # noqa: E402
from nodes.shell_node import shell    # noqa: E402
from nodes.log_node import log        # noqa: E402
from engine import eval_expr           # noqa: E402


def norm(s: str) -> str:
    return (s or "").replace("\r\n", "\n").replace("\r", "\n")


class PythonNodeTests(unittest.TestCase):

    def test_output_stripped_no_trailing_newline(self):
        r = python({"code": "print('bonjour')"})
        self.assertEqual(r["status"], "ok")
        self.assertEqual(r["output"], "bonjour")

    def test_multiline_output_kept_stripped_at_ends(self):
        r = python({"code": "print('l1')\nprint('l2')"})
        self.assertEqual(norm(r["output"]), "l1\nl2")
        self.assertFalse(r["output"].endswith("\n"))

    def test_returncode_zero_and_status_ok(self):
        r = python({"code": "x = 1"})
        self.assertEqual(r["returncode"], 0)
        self.assertEqual(r["status"], "ok")

    def test_exit_code_propagated(self):
        r = python({"code": "import sys\nsys.exit(3)"})
        self.assertEqual(r["returncode"], 3)
        self.assertEqual(r["status"], "error")

    def test_stdout_stderr_combined_in_output(self):
        r = python({"code": "import sys\nprint('out')\nprint('err', file=sys.stderr)"})
        self.assertEqual(norm(r["stdout"]), "out")
        self.assertEqual(norm(r["stderr"]), "err")
        self.assertIn("out", r["output"])
        self.assertIn("err", r["output"])

    def test_missing_code_and_script_is_error(self):
        r = python({})
        self.assertEqual(r["returncode"], -1)
        self.assertEqual(r["status"], "error")

    def test_stripped_output_makes_skip_if_safe(self):
        # le contrat reliant nœud + moteur : print('ROUGE') → skip_if False quand ROUGE
        r = python({"code": "print('ROUGE')"})
        self.assertFalse(eval_expr("'{{s.output}}' != 'ROUGE'", {"s": r}))

    def test_script_file_execution(self, _tmp=None):
        # exécuter un fichier .py via le paramètre script
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "hello.py"
            p.write_text("print('since-script')", encoding="utf-8")
            r = python({"script": str(p)})
        self.assertEqual(r["output"], "since-script")
        self.assertEqual(r["returncode"], 0)


class ShellNodeTests(unittest.TestCase):

    def test_output_stripped(self):
        r = shell({"cmd": "echo bonjour"})
        self.assertEqual(r["status"], "ok")
        self.assertEqual(r["output"], "bonjour")

    def test_returncode_exit(self):
        r = shell({"cmd": "exit 3"})
        self.assertEqual(r["returncode"], 3)
        self.assertEqual(r["status"], "error")

    def test_chain_stops_on_failure(self):
        # dev_fix_tests.yaml : « && echo prêt » ne doit PAS produire « prêt » si le
        # maillon précédent échoue (portable : cmd.exe comme bash)
        r = shell({"cmd": "exit 1 && echo prêt"})
        self.assertEqual(r["returncode"], 1)
        self.assertNotIn("prêt", r["output"])

    def test_chain_reaches_echo_on_success(self):
        r = shell({"cmd": "echo prêt"})
        self.assertIn("prêt", r["output"])

    def test_invalid_forced_shell_rejected(self):
        r = shell({"cmd": "echo x", "shell": "zsh"})
        self.assertEqual(r["returncode"], -1)
        self.assertEqual(r["status"], "error")


class LogNodeTests(unittest.TestCase):

    def test_returns_message_and_status(self):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            r = log({"message": "hello", "level": "info"})
        self.assertEqual(r, {"output": "hello", "status": "ok"})

    def test_default_level_info(self):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            r = log({"message": "m"})
        self.assertEqual(r["output"], "m")


if __name__ == "__main__":
    unittest.main()

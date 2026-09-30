import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parent


@unittest.skipIf(os.name == "nt", "POSIX launcher installer")
class PosixInstallTests(unittest.TestCase):
    def test_install_twice_from_another_directory_and_run_link_with_spaces(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "bin with spaces"
            for _ in range(2):
                subprocess.run(["bash", str(REPO / "install.sh"), str(target)], cwd=tmp, check=True, capture_output=True)
            launcher = target / "transcribe"
            self.assertTrue(launcher.is_symlink())
            self.assertEqual(launcher.resolve(), REPO / "transcribe")
            result = subprocess.run([str(launcher), "--help"], cwd=tmp, check=True, capture_output=True, text=True)
            self.assertIn("Transcribe video to SRT", result.stdout)
            self.assertIn("--diarize", result.stdout)

    def test_install_preserves_existing_regular_command(self):
        with tempfile.TemporaryDirectory() as tmp:
            launcher = Path(tmp) / "transcribe"
            launcher.write_text("existing command", encoding="utf-8")
            result = subprocess.run(["bash", str(REPO / "install.sh"), tmp], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(launcher.read_text(encoding="utf-8"), "existing command")

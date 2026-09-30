"""Guards transcribe.bat's faster-whisper-xxl.exe argument order.

--output_format takes one or more values (argparse nargs='+') and greedily
swallows whatever follows it on the command line, including a trailing
positional audio path - faster-whisper-xxl's own --help warns "dont add
audio after this". transcribe.bat used to put the audio path last, which
broke every transcription on Windows once --output_format gained that
argparse arity (the exe reported the audio path as an invalid output
format). This can't be exercised by actually running the real .exe in CI
(no such binary there, and none should be downloaded for tests per
AGENTS.md), so it's checked textually: the audio variable must appear
before --output_format on every invocation line.
"""

import re
import unittest
from pathlib import Path

BAT = Path(__file__).with_name("transcribe.bat").read_text(encoding="utf-8")


class TranscribeBatArgumentOrderTests(unittest.TestCase):
    def test_audio_path_precedes_output_format_on_every_invocation(self):
        invocations = [
            line
            for line in BAT.splitlines()
            if "faster-whisper-xxl.exe" in line and "--output_format" in line
        ]
        self.assertGreaterEqual(
            len(invocations), 3, "Expected to find all three faster-whisper-xxl.exe calls."
        )
        for line in invocations:
            audio_pos = line.find('"!TEMP_AUDIO!"')
            format_pos = line.find("--output_format")
            self.assertNotEqual(audio_pos, -1, f"!TEMP_AUDIO! missing from: {line}")
            self.assertLess(
                audio_pos,
                format_pos,
                f"!TEMP_AUDIO! must come before --output_format (nargs='+' would "
                f"swallow it otherwise): {line}",
            )

    def test_exe_is_not_invoked_with_output_format_as_the_final_token(self):
        # A regex belt-and-braces check: --output_format srt must be followed
        # by nothing (end of line), never immediately by the audio path.
        for line in BAT.splitlines():
            if "faster-whisper-xxl.exe" in line and "--output_format" in line:
                self.assertIsNotNone(
                    re.search(r"--output_format\s+srt\s*$", line),
                    f"--output_format must be the last flag on the line: {line}",
                )


if __name__ == "__main__":
    unittest.main()

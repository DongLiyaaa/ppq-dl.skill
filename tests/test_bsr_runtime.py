import importlib.util
import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "bsr_runtime.py"


def load_module():
    spec = importlib.util.spec_from_file_location("bsr_runtime", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BsrRuntimeTests(unittest.TestCase):
    def test_detects_incomplete_page(self):
        mod = load_module()
        html = mod.build_test_fixture(expected_count=50, rendered_count=30, start_rank=1)
        probe = mod.probe_snapshot(html)

        self.assertEqual(probe["expectedCount"], 50)
        self.assertEqual(probe["renderedCount"], 30)
        self.assertFalse(probe["isComplete"])
        self.assertEqual(probe["firstExpectedRank"], "1")
        self.assertEqual(probe["lastExpectedRank"], "50")

    def test_extracts_ranked_items_from_rendered_rows(self):
        mod = load_module()
        html = mod.build_test_fixture(expected_count=50, rendered_count=30, start_rank=51)
        extracted = mod.extract_snapshot(html)

        self.assertEqual(extracted["count"], 30)
        self.assertEqual(extracted["firstRank"], 51)
        self.assertEqual(extracted["lastRank"], 80)
        self.assertEqual(extracted["items"][0]["asin"], "ASIN000051")
        self.assertEqual(extracted["items"][-1]["asin"], "ASIN000080")

    def test_merges_virtualized_windows_until_range_is_complete(self):
        mod = load_module()
        page_a = mod.build_test_fixture(expected_count=50, rendered_count=30, start_rank=1)
        page_b = mod.build_test_fixture(expected_count=50, rendered_count=30, start_rank=21)

        state = mod.empty_state()
        state = mod.merge_snapshot_into_state(state, mod.extract_snapshot(page_a), mod.probe_snapshot(page_a))
        self.assertEqual(state["collectedCount"], 30)
        self.assertFalse(state["isComplete"])
        self.assertEqual(state["maxCollectedRank"], 30)

        state = mod.merge_snapshot_into_state(state, mod.extract_snapshot(page_b), mod.probe_snapshot(page_b))
        self.assertEqual(state["collectedCount"], 50)
        self.assertTrue(state["isComplete"])
        self.assertEqual(state["minCollectedRank"], 1)
        self.assertEqual(state["maxCollectedRank"], 50)

    def test_outputs_fixed_probe_collect_and_export_scripts(self):
        mod = load_module()

        self.assertIn("__PPQ_BSR_STATE = null", mod.reset_script())
        self.assertIn("data-client-recs-list", mod.probe_script())
        self.assertIn("expectedCount", mod.probe_script())
        self.assertIn("__PPQ_BSR_STATE", mod.collect_script())
        self.assertIn("scrollIntoView", mod.collect_script())
        self.assertIn("window.scrollBy", mod.collect_script())
        self.assertIn("maxCollectedRank", mod.collect_script())
        self.assertIn("__PPQ_BSR_STATE", mod.export_script())


if __name__ == "__main__":
    unittest.main()

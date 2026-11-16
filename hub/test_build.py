import unittest

import build


class HubTest(unittest.TestCase):
    def test_version_comes_from_last_done_plan_item(self):
        items = [{"done": True, "id": "1-1"}, {"done": True, "id": "1-2b"}, {"done": False, "id": "1-3"}]
        self.assertEqual(build.version(items), "0.1.2b")
        self.assertEqual(build.version([{"done": False, "id": "0-1"}]), "0.0.0")

    def test_every_game_has_hub_info(self):
        games = build.load()
        self.assertEqual({g["code"] for g in games}, {p.name for p in build.GAMES.iterdir() if p.is_dir()})
        for g in games:
            self.assertTrue(g["how_to_play"], g["code"])
            self.assertRegex(g["date"], r"^\d{4}-\d{2}-\d{2}$", g["code"])

    def test_page_links_every_preview(self):
        games = build.load()
        html = build.page(games)
        for g in games:
            self.assertIn(g["title"], html)
            self.assertEqual(g["url"] in html, g["preview"], g["code"])


if __name__ == "__main__":
    unittest.main()

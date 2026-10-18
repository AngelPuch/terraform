"""Verificación de comportamiento y persistencia, sin necesitar Docker."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "app"))
from app import create_app


class TasksTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.db = str(Path(self.temp.name) / "tasks.db")
        self.client = create_app(self.db).test_client()

    def tearDown(self):
        self.temp.cleanup()

    def test_complete_crud(self):
        self.assertEqual(self.client.get("/api/tasks").json, [])
        response = self.client.post("/api/tasks", json={"title": "Exponer Terraform"})
        self.assertEqual(response.status_code, 201)
        task_id = response.json["id"]
        url = f"/api/tasks/{task_id}"
        self.assertFalse(self.client.get(url).json["done"])
        updated = self.client.put(url, json={"title": "Exposición lista", "done": True})
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.json["title"], "Exposición lista")
        self.assertTrue(updated.json["done"])
        self.assertEqual(len(self.client.get("/api/tasks").json), 1)
        self.assertEqual(self.client.delete(url).status_code, 204)
        self.assertEqual(self.client.get(url).status_code, 404)
        self.assertEqual(self.client.get("/api/tasks").json, [])

    def test_persist_across_app_instances(self):
        self.client.post("/api/tasks", json={"title": "Conservar esta tarea"})
        second = create_app(self.db).test_client()
        self.assertEqual(second.get("/api/tasks").json[0]["title"], "Conservar esta tarea")

    def test_invalid_inputs_do_not_create_records(self):
        for payload in [None, [], {"title": " "}, {"title": "a" * 121},
                        {"title": 5}, {"title": "x", "description": []},
                        {"title": "x", "description": "a" * 501},
                        {"title": "x", "done": "true"}]:
            with self.subTest(payload=payload):
                response = self.client.post("/api/tasks", json=payload)
                self.assertEqual(response.status_code, 400)
        self.assertEqual(self.client.get("/api/tasks").json, [])

    def test_missing_tasks(self):
        self.assertEqual(self.client.get("/api/tasks/999").status_code, 404)
        self.assertEqual(self.client.put("/api/tasks/999", json={"title": "x"}).status_code, 404)
        self.assertEqual(self.client.delete("/api/tasks/999").status_code, 404)

    def test_title_escaped_and_assets_served(self):
        import os
        from unittest.mock import patch
        with patch.dict(os.environ, {"APP_TITLE": "<script>alert(1)</script>"}):
            response = create_app(self.db).test_client().get("/")
        self.assertIn(b"&lt;script&gt;", response.data)
        self.assertNotIn(b"<script>alert(1)</script>", response.data)
        for path in ["/static/style.css", "/static/app.js", "/health"]:
            response = self.client.get(path)
            self.assertEqual(response.status_code, 200)
            response.close()

    def test_sql_text_is_stored_as_data(self):
        title = "'); DROP TABLE tasks; --"
        self.assertEqual(self.client.post("/api/tasks", json={"title": title}).status_code, 201)
        self.assertEqual(self.client.get("/api/tasks").json[0]["title"], title)


if __name__ == "__main__":
    unittest.main()

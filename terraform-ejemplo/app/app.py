"""CRUD de tareas para demostrar infraestructura administrada con Terraform."""
import os
import sqlite3
from contextlib import closing
from pathlib import Path

from flask import Flask, jsonify, render_template, request
from werkzeug.exceptions import HTTPException


def create_app(database_path=None):
    app = Flask(__name__)
    app.config.update(
        DATABASE=database_path or os.getenv("DB_PATH", "/data/tasks.db"),
        APP_TITLE=os.getenv("APP_TITLE", "Tareas del equipo"),
        MAX_CONTENT_LENGTH=16 * 1024,
    )
    Path(app.config["DATABASE"]).parent.mkdir(parents=True, exist_ok=True)

    def connect():
        db = sqlite3.connect(app.config["DATABASE"], timeout=10)
        db.row_factory = sqlite3.Row
        return db

    with closing(connect()) as db, db:
        db.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                done INTEGER NOT NULL DEFAULT 0 CHECK(done IN (0, 1))
            )
        """)

    def serialize(row):
        return {"id": row["id"], "title": row["title"],
                "description": row["description"], "done": bool(row["done"])}

    def read_payload():
        data = request.get_json(silent=True)
        if not isinstance(data, dict):
            return None, "Envía un objeto JSON válido."
        title = data.get("title")
        description = data.get("description", "")
        done = data.get("done", False)
        if not isinstance(title, str) or not 1 <= len(title.strip()) <= 120:
            return None, "El título debe tener entre 1 y 120 caracteres."
        if not isinstance(description, str) or len(description) > 500:
            return None, "La descripción admite hasta 500 caracteres."
        if not isinstance(done, bool):
            return None, "done debe ser true o false."
        return (title.strip(), description.strip(), int(done)), None

    @app.get("/")
    def index():
        return render_template("index.html", title=app.config["APP_TITLE"])

    @app.get("/health")
    def health():
        with closing(connect()) as db:
            db.execute("SELECT COUNT(*) FROM tasks").fetchone()
        return jsonify(status="ok")

    @app.get("/api/tasks")
    def list_tasks():
        with closing(connect()) as db:
            rows = db.execute("SELECT * FROM tasks ORDER BY id DESC").fetchall()
        return jsonify([serialize(row) for row in rows])

    @app.get("/api/tasks/<int:task_id>")
    def get_task(task_id):
        with closing(connect()) as db:
            row = db.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()
        if row is None:
            return jsonify(error="Tarea no encontrada."), 404
        return jsonify(serialize(row))

    @app.post("/api/tasks")
    def create_task():
        values, error = read_payload()
        if error:
            return jsonify(error=error), 400
        with closing(connect()) as db, db:
            cursor = db.execute(
                "INSERT INTO tasks(title, description, done) VALUES (?, ?, ?)", values
            )
            row = db.execute("SELECT * FROM tasks WHERE id = ?", (cursor.lastrowid,)).fetchone()
        return jsonify(serialize(row)), 201

    @app.put("/api/tasks/<int:task_id>")
    def update_task(task_id):
        values, error = read_payload()
        if error:
            return jsonify(error=error), 400
        with closing(connect()) as db, db:
            cursor = db.execute(
                "UPDATE tasks SET title = ?, description = ?, done = ? WHERE id = ?",
                (*values, task_id),
            )
            if cursor.rowcount == 0:
                return jsonify(error="Tarea no encontrada."), 404
            row = db.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()
        return jsonify(serialize(row))

    @app.delete("/api/tasks/<int:task_id>")
    def delete_task(task_id):
        with closing(connect()) as db, db:
            cursor = db.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
            if cursor.rowcount == 0:
                return jsonify(error="Tarea no encontrada."), 404
        return "", 204

    @app.errorhandler(HTTPException)
    def http_error(error):
        return jsonify(error=error.description), error.code

    @app.after_request
    def headers(response):
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        return response

    return app

const form = document.querySelector("#task-form");
const message = document.querySelector("#message");
const fields = {
  id: document.querySelector("#task-id"),
  title: document.querySelector("#title"),
  description: document.querySelector("#description"),
  done: document.querySelector("#done"),
};

async function api(path = "", options = {}) {
  const response = await fetch("/api/tasks" + path, {
    ...options,
    headers: { "Content-Type": "application/json" },
  });
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error || "No se pudo completar la operación.");
  }
  return response.status === 204 ? null : response.json();
}

function reset() {
  form.reset();
  fields.id.value = "";
  document.querySelector("#form-title").textContent = "Nueva tarea";
  document.querySelector("#save").textContent = "Crear tarea";
  document.querySelector("#cancel").hidden = true;
}

function button(label, style, action) {
  const element = document.createElement("button");
  element.type = "button";
  element.textContent = label;
  element.className = style;
  element.addEventListener("click", async () => {
    element.disabled = true;
    try {
      await action();
    } catch (error) {
      message.textContent = error.message;
    } finally {
      element.disabled = false;
    }
  });
  return element;
}

async function load() {
  const tasks = await api();
  const list = document.querySelector("#tasks");
  list.replaceChildren();
  document.querySelector("#count").textContent =
    `${tasks.length} tarea${tasks.length === 1 ? "" : "s"}`;

  if (!tasks.length) {
    const empty = document.createElement("p");
    empty.className = "empty";
    empty.textContent = "Todo comienza con una tarea. Crea la primera.";
    list.append(empty);
  }

  for (const task of tasks) {
    const article = document.createElement("article");
    article.className = "task" + (task.done ? " complete" : "");
    const top = document.createElement("div");
    top.className = "task-top";
    const title = document.createElement("h3");
    title.textContent = task.title;
    const status = document.createElement("span");
    status.className = "status";
    status.textContent = task.done ? "Completada" : "Pendiente";
    top.append(title, status);
    const description = document.createElement("p");
    description.textContent = task.description;
    const actions = document.createElement("div");
    actions.className = "actions";
    actions.append(
      button("Editar", "secondary", () => {
        fields.id.value = task.id;
        fields.title.value = task.title;
        fields.description.value = task.description;
        fields.done.checked = task.done;
        document.querySelector("#form-title").textContent = "Editar tarea";
        document.querySelector("#save").textContent = "Guardar cambios";
        document.querySelector("#cancel").hidden = false;
        fields.title.focus();
      }),
      button(
        task.done ? "Marcar pendiente" : "Completar",
        "secondary",
        async () => {
          await api(`/${task.id}`, {
            method: "PUT",
            body: JSON.stringify({ ...task, done: !task.done }),
          });
          if (fields.id.value === String(task.id)) reset();
          await load();
          message.textContent = "Estado actualizado.";
        },
      ),
      button("Eliminar", "danger", async () => {
        if (!window.confirm(`¿Eliminar la tarea «${task.title}»?`)) return;
        await api(`/${task.id}`, { method: "DELETE" });
        if (fields.id.value === String(task.id)) reset();
        await load();
        message.textContent = "Tarea eliminada.";
      }),
    );
    article.append(top, description, actions);
    list.append(article);
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const save = document.querySelector("#save");
  save.disabled = true;
  const id = fields.id.value;
  const payload = {
    title: fields.title.value,
    description: fields.description.value,
    done: fields.done.checked,
  };
  try {
    await api(id ? `/${id}` : "", {
      method: id ? "PUT" : "POST",
      body: JSON.stringify(payload),
    });
    reset();
    await load();
    message.textContent = id ? "Cambios guardados." : "Tarea creada.";
  } catch (error) {
    message.textContent = error.message;
  } finally {
    save.disabled = false;
  }
});

document.querySelector("#cancel").addEventListener("click", reset);
load().catch((error) => {
  message.textContent = error.message;
});

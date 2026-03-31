# Proyecto Kubernetes

Estructura actual del proyecto, lista parcial:

```text
Kubernetes/
├─ app/
│  ├─ main.py
│  └─ __init__.py
├─ venv/
├─ .gitignore
├─ Dockerfile
├─ requirements.txt
└─ README.md
```

## Notas

- `app/main.py`: API principal.
- `Dockerfile`: imagen para correr FastAPI en contenedor.
- `requirements.txt`: dependencias Python.
- `.gitignore`: ignora `venv` y archivos temporales.
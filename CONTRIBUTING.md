# Contributing to Vyana

Thank you for your interest in contributing to Vyana! This guide will help you get started.

## Development Setup

### Prerequisites

- Python 3.10+
- Flutter SDK (Latest Stable)
- Git

### Backend Setup

```bash
cd services/vyana_backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\activate

# Activate (Linux/Mac)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env with your API keys

# Run server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

### Frontend Setup

```bash
cd apps/vyana_flutter

# Get dependencies
flutter pub get

# Generate code (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run
```

## Project Structure

```
vyana/
├── apps/
│   └── vyana_flutter/       # Flutter mobile/desktop app
│       ├── lib/
│       │   ├── core/        # API client, theme, config
│       │   └── features/    # Feature modules
│       └── pubspec.yaml
├── services/
│   └── vyana_backend/       # FastAPI backend
│       ├── app/
│       │   ├── routes/      # API endpoints
│       │   ├── services/    # Business logic
│       │   └── mcp/         # MCP server
│       └── requirements.txt
└── .github/workflows/       # CI/CD
```

## Code Style

### Python (Backend)

- Use [Ruff](https://docs.astral.sh/ruff/) for linting
- Follow PEP 8 conventions
- Add docstrings to public functions
- Type hints are encouraged

### Dart (Flutter)

- Run `flutter analyze` before committing
- Follow [Effective Dart](https://dart.dev/effective-dart) guidelines
- Use Riverpod for state management
- Use GoRouter for navigation

## Testing

### Backend

```bash
cd services/vyana_backend
pytest tests/ -v
```

### Flutter

```bash
cd apps/vyana_flutter
flutter test
```

## Pull Request Process

1. **Fork** the repository
2. **Create a branch** from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Run tests** to ensure nothing is broken
5. **Commit** with clear messages
   ```bash
   git commit -m "feat: add new feature description"
   ```
6. **Push** to your fork
7. **Open a Pull Request** against `main`

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

## Environment Variables

See [.env.example](services/vyana_backend/.env.example) for required variables.

**Never commit API keys or secrets!**

## Getting Help

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

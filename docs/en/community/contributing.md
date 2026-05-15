# Contributing Guide

Thanks for contributing to Stackvo! 🎉 This guide explains the entire contribution process in detail, from forking the repository to submitting a pull request, using conventional commits, code style, opening bug reports and feature requests, to testing and CI/CD processes. It includes information about different contribution areas such as code, documentation, testing, and community support.

---

## Quick Start

### 1. Fork the Repository

```bash
# Fork: https://github.com/fahrettinaksoy/stackvo/fork

# Clone
git clone https://github.com/YOUR_USERNAME/stackvo.git
cd stackvo
```

### 2. Setup Development Environment

```bash
# Dependencies
docker --version
docker compose --version

# Install CLI
./stackvo.sh install

# Test
stackvo doctor
```

### 3. Create a Branch

```bash
# Feature branch
git checkout -b feat/my-feature

# Bugfix branch
git checkout -b fix/bug-description
```

### 4. Make Your Changes

```bash
# Code changes
nano .env

# Test
./stackvo.sh generate
./stackvo.sh up
```

### 5. Commit

Use the **Conventional Commits** format:

```bash
git commit -m "feat(mysql): add MySQL 8.1 support"
git commit -m "fix(traefik): resolve SSL certificate issue"
git commit -m "docs(readme): update installation guide"
```

**Commit Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code formatting
- `refactor`: Code refactoring
- `perf`: Performance
- `test`: Test
- `chore`: Chores

### 6. Push and Pull Request

```bash
# Push
git push origin feat/my-feature

# Create a Pull Request on GitHub
```

---

## Contribution Checklist

Before submitting a Pull Request:

- [ ] Code changes tested
- [ ] Documentation updated
- [ ] Conventional commits used
- [ ] No conflicts
- [ ] CI/CD tests passed

---

## Contribution Areas

### 1. Code Contributions

- **New Services:** PostgreSQL 16, Redis 7.2, etc.
- **New Features:** Monitoring, backup, etc.
- **Bug Fixes:** Fix bugs from issues
- **Performance:** Optimization

### 2. Documentation

- **Guides:** Write new guides
- **Examples:** Add example projects
- **Translations:** Make translations
- **Tutorials:** Create tutorials

### 3. Testing

- **Unit Tests:** Increase test coverage
- **Integration Tests:** Integration tests
- **E2E Tests:** End-to-end tests

### 4. Community

- **Issue Triage:** Categorize issues
- **Support:** Answer questions
- **Reviews:** Review PRs

---

## Project Structure

```
stackvo/
├── cli/                    # CLI commands
│   ├── stackvo.sh       # Main CLI
│   ├── commands/          # Subcommands
│   └── lib/               # Libraries
│       └── generators/    # Generator modules
├── core/                  # Core files
│   ├── compose/           # Docker Compose templates
│   ├── traefik/           # Traefik configuration
│   └── templates/         # Service templates
├── projects/              # User projects
├── .ui/                   # Web UI
│   ├── index.html         # Main page
│   └── api/               # API endpoints
├── docs/                  # Documentation
└── scripts/               # Utility scripts
```

---

## Testing

### Local Testing

```bash
# Generator test
./stackvo.sh generate

# Start services
./stackvo.sh up

# Check logs
./stackvo.sh logs

# Clean up
./stackvo.sh down
```

### CI/CD

GitHub Actions runs automatically:
- Syntax check
- Docker build
- Integration tests

---

## Code Style

### Bash

```bash
# ✅ Correct
function my_function() {
    local var="value"
    echo "$var"
}

# ❌ Incorrect
function myFunction {
    var=value
    echo $var
}
```

### Python

```python
# ✅ Correct
def my_function(param: str) -> str:
    """Docstring"""
    return param.upper()

# ❌ Incorrect
def myFunction(param):
    return param.upper()
```

---

## Bug Reports

When opening an Issue:

**Template:**
```markdown
## Bug Description
[Description]

## Steps
1. [Step 1]
2. [Step 2]

## Expected Behavior
[Expected]

## Actual Behavior
[Actual]

## Environment
- OS: Ubuntu 22.04
- Docker: 24.0.7
- Stackvo: 1.0.0

## Logs
```
[Logs]
```
```

---

## Feature Requests

When proposing a new feature:

**Template:**
```markdown
## Feature Description
[Description]

## Motivation
[Why is it necessary?]

## Proposed Solution
[How should it be implemented?]

## Alternatives
[Other solutions?]
```

---

## Recognition

Contributors:
- Listed in README.md
- Visible on GitHub contributors page
- Mentioned in Release notes

---

## Contact

For your questions:
- **GitHub Discussions:** [Join discussions](https://github.com/fahrettinaksoy/stackvo/discussions)
- **Issues:** [Ask a question](https://github.com/fahrettinaksoy/stackvo/issues/new)

---

## License

Your contributions are published under the [MIT License](https://github.com/fahrettinaksoy/stackvo/blob/main/LICENSE).

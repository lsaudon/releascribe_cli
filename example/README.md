# Example

## Usage

```sh
# Release command
releascribe_cli release
```

release-info.json

```json
{
  "changelog": [
    {
      "type": "fix",
      "description": "🐛 Corrections de bugs",
      "increment": "patch"
    },
    {
      "type": "feat",
      "description": "✨ Fonctionnalités",
      "increment": "minor"
    },
    {
      "type": "refactor",
      "description": "♻️ Refonte du code",
      "increment": "patch"
    },
    {
      "type": "perf",
      "description": "⚡️ Amélioration des performances",
      "increment": "patch"
    },
    {
      "type": "test",
      "description": "🧪 Tests",
      "increment": "patch"
    },
    {
      "type": "docs",
      "description": "📝 Documentation",
      "increment": "patch"
    },
    {
      "type": "build",
      "description": "🧱 Construction",
      "increment": "patch"
    },
    {
      "type": "ci",
      "description": "🎞️ Flux de travail",
      "increment": "patch"
    },
    {
      "type": "chore",
      "description": "🧹 Tâches",
      "increment": "patch"
    },
  ],
}
```

```sh
# Release command option
releascribe_cli release -release-info-file release-info.json
```
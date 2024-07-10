# releascribe_cli

## Overview

`releascribe` is a Dart-based CLI tool for automating software release management. It integrates with version control systems to generate changelogs, determine project versions, and apply versioning changes based on commit categories defined in a JSON file.

## Installation

Ensure Dart SDK is installed, then use Dart's package manager to install `releascribe` globally:

```sh
dart pub global activate releascribe_cli
```

## Usage

### Command Syntax

```sh
releascribe release [-r <path_to_release_info_file>]
```

### Options

- `-r, --release-info-file <path>`: Path to a JSON file defining commit categories and their semantic versioning increments and output files.

### Example

#### `release-info.json`

Create `release-info.json`:

```json
{
  "output": [
    {"path": "CHANGELOG.md", "overwrite": false},
    {"path": "release-notes.txt", "overwrite": true}
  ],
  "changelog": [
    {"type": "fix", "description": "🐛 Bug Fixes", "increment": "patch"},
    {"type": "feat", "description": "✨ Features", "increment": "minor"},
    {"type": "refactor", "description": "♻️ Code Refactoring", "increment": "patch"},
    {"type": "perf", "description": "⚡️ Performance Improvements", "increment": "patch"},
    {"type": "test", "description": "🧪 Tests", "increment": "patch"},
    {"type": "docs", "description": "📝 Documentation", "increment": "patch"},
    {"type": "build", "description": "🧱 Build System", "increment": "patch"},
    {"type": "ci", "description": "🎞️ Continuous Integration", "increment": "patch"},
    {"type": "chore", "description": "🧹 Chores", "increment": "patch"}
  ]
}
```

#### Running the Command

Generate a changelog and update versioning information:

```sh
releascribe release -r release-info.json
```

### Notes

- Ensure Dart SDK and `releascribe_cli` are correctly installed and accessible.
- Customize `release-info.json` to match your project's commit categories and versioning conventions.
# releascribe_cli

## Overview

`releascribe_cli` is a command-line interface tool written in Dart for automating software release management tasks. It integrates with version control systems, generates changelogs, determines project versions, and applies versioning changes based on commit categories defined in a JSON file.

## Installation

To use `releascribe_cli`, ensure you have Dart SDK installed. You can install `releascribe_cli` globally using Dart's package manager, `pub`:

```sh
dart pub global activate releascribe_cli
```

## Usage

### Command Syntax

```sh
releascribe_cli release [-r <path_to_release_info_file>]
```

### Options

- `-r, --release-info-file`: Path to a JSON file containing release information.
  - **Description**: Specifies a file defining commit categories and their semantic versioning increments.

### Example

#### Example `release-info.json`

Create a file named `release-info.json` with the following content:

```json
{
  "changelog": [
    {
      "type": "fix",
      "description": "🐛 Bug Fixes",
      "increment": "patch"
    },
    {
      "type": "feat",
      "description": "✨ Features",
      "increment": "minor"
    },
    {
      "type": "refactor",
      "description": "♻️ Code Refactoring",
      "increment": "patch"
    },
    {
      "type": "perf",
      "description": "⚡️ Performance Improvements",
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
      "description": "🧱 Build System",
      "increment": "patch"
    },
    {
      "type": "ci",
      "description": "🎞️ Continuous Integration",
      "increment": "patch"
    },
    {
      "type": "chore",
      "description": "🧹 Chores",
      "increment": "patch"
    }
  ]
}
```

#### Running the Command

Execute the following command in your terminal to manage software releases based on the commit categories defined in `release-info.json`:

```sh
releascribe_cli release -r release-info.json
```

- **Description**: This command generates a changelog, determines the next project version, and updates versioning information according to the commit categories specified in `release-info.json`.

### Notes

- Ensure Dart SDK and `releascribe_cli` are correctly installed and accessible in your environment.
- Customize `release-info.json` to match your project's commit categories and versioning conventions.
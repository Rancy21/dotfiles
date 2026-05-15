# dotfiles

Personal dotfiles repository with custom Java-based management script.

[![Java](https://img.shields.io/badge/Java-17+-blue.svg)](https://www.oracle.com/java/technologies/downloads/)

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [License](#license)

## Overview

This is my personal dotfiles repository managed by a custom Java-based tool. The `dots.java` script handles saving dotfiles to the repository and syncing them back to their original locations using symbolic links.

## Features

- **Save dotfiles** — Move configuration files to the repository and create symlinks
- **Sync from manifest** — Recreate all symlinks based on the manifest file
- **No compilation required** — Uses JBang to run Java source directly
- **JSON manifest** — Tracks all managed files with source and target paths

## Prerequisites

- [JBang](https://jbang.dev/) — Install via: `brew install jbang` (macOS), `sdk install jbang` (Linux), or download from [releases](https://github.com/jbangdev/jbang/releases)
- **Java 17 or higher** — Required to run the script

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles

# Ensure JBang is installed
jbang --version

# Ensure Java 17+ is available
java -version
```

## Usage

### Save a dotfile

Add a configuration file to the dotfiles repository:

```bash
jbang run scripts/dots.java add ~/.bashrc
```

This will:

1. Move the file to `~/dotfiles/.bashrc`
2. Create a symbolic link at `~/.bashrc` pointing to the repository
3. Add an entry to `manifest.jsonc`

### Sync from manifest

Recreate all symlinks based on the manifest:

```bash
jbang run scripts/dots.java sync
```

This reads `manifest.jsonc` and creates symlinks for all tracked files.

### View help

```bash
jbang run scripts/dots.java --help
```

## How It Works

1. **`add` command**: Takes a file path, moves it to the repository under `~/dotfiles/`, creates a symbolic link at the original location, and records the mapping in `manifest.jsonc`.

2. **`sync` command**: Reads the manifest and recreates all symbolic links, backing up any existing non-link files with a `.bak` extension.

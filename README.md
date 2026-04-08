# Linx · Study Dashboard for Linux

[![Build & Release](https://github.com/ometh2006/linx/actions/workflows/build.yml/badge.svg)](https://github.com/ometh2006/linx/actions/workflows/build.yml)
![Platform](https://img.shields.io/badge/Platform-Linux%20x64-orange?logo=linux)
![Language](https://img.shields.io/badge/Language-Dart%20%2F%20Flutter-blue?logo=flutter)
![License](https://img.shields.io/badge/License-MIT-green)

A fully offline, native Linux desktop app to track your academic subjects, log test results, and visualise your study performance — built with Flutter & Material 3. The Linux sibling of [AcadeMind Android](https://github.com/ometh2006/academind-kotlinv3.4-fix).

## ✨ Features

- 📚 **Subject Management** — Add, edit, and delete subjects with custom colors
- 📝 **Test Score Tracking** — Record marks for each subject with date and notes
- 📊 **Performance Analytics** — Bar charts, pie chart (grade distribution), subject breakdown
- 🏠 **Dashboard Overview** — Quick stats and recent activity
- 💾 **Offline Storage** — Data saved locally via SQLite (`~/.local/share/linx/`)
- 🌙 **Dark / Light theme** — Toggle with one click
- ⚡ **Lightweight** — Fast startup, minimal resource usage

## 🧱 Tech Stack

| | |
|---|---|
| **Framework** | Flutter 3.x (Linux desktop) |
| **Language** | Dart |
| **UI** | Material 3 |
| **Database** | SQLite via `sqflite_common_ffi` |
| **Charts** | `fl_chart` |
| **Build** | GitHub Actions → tar.gz release |

## 🚀 Getting Started

### Download (recommended)

Download the latest release from the [Releases page](https://github.com/ometh2006/linx/releases).

```bash
# Install GTK runtime (Ubuntu/Debian)
sudo apt install libgtk-3-0

# Extract and run
tar -xzf linx-linux-x64.tar.gz
./linx
```

### Build from source

**Prerequisites:** Flutter SDK, Linux build tools

```bash
# Install Linux build deps
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev

# Clone and build
git clone https://github.com/ometh2006/linx.git
cd linx
flutter config --enable-linux-desktop
flutter pub get
flutter build linux --release

# Run
./build/linux/x64/release/bundle/linx
```

## 📦 Project Structure

```
lib/
 ├── main.dart           # Entry point + navigation shell
 ├── models/             # Subject, TestScore data models
 ├── database/           # SQLite CRUD (DatabaseHelper)
 ├── screens/            # Dashboard, Subjects, Scores, Analytics
 └── theme/              # Material 3 theming + color palette
.github/workflows/
 └── build.yml           # CI/CD: build + GitHub Release
```

## 🤖 CI/CD

Push a version tag to trigger a full build and release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically:
1. Set up Flutter on Ubuntu
2. Install Linux dependencies
3. Build the release binary
4. Package as `linx-linux-x64.tar.gz`
5. Create a GitHub Release with download links

## 👤 Author

**ometh virusara** — [@ometh2006](https://github.com/ometh2006)

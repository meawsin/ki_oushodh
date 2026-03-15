#!/bin/bash
# ============================================================
# Ki Oushodh - Project Scaffold Generator
# Run this from the ROOT of your Flutter project directory.
# Usage: chmod +x scaffold.sh && ./scaffold.sh
# ============================================================

echo "🏗️  Scaffolding Ki Oushodh project structure..."

# --- CORE ---
mkdir -p lib/core/constants
mkdir -p lib/core/theme
mkdir -p lib/core/utils

# --- DATA ---
mkdir -p lib/data/local
mkdir -p lib/data/network

# --- DOMAIN ---
mkdir -p lib/domain/models

# --- FEATURES ---
mkdir -p lib/features/scanner
mkdir -p lib/features/results
mkdir -p lib/features/history
mkdir -p lib/features/settings

# --- SERVICES ---
mkdir -p lib/services

# ============================================================
# Create placeholder .dart files so the folders are tracked
# by version control (git doesn't track empty folders).
# ============================================================

# Core
touch lib/core/constants/app_constants.dart
touch lib/core/constants/app_colors.dart
touch lib/core/constants/app_typography.dart
touch lib/core/theme/app_theme.dart
touch lib/core/utils/date_utils.dart       # 30-day cleanup logic lives here

# Data
touch lib/data/local/hive_setup.dart
touch lib/data/local/preferences_service.dart
touch lib/data/network/gemini_client.dart

# Domain
touch lib/domain/models/scan_history_model.dart
touch lib/domain/models/settings_model.dart

# Features - Scanner
touch lib/features/scanner/scanner_screen.dart
touch lib/features/scanner/scanner_viewmodel.dart

# Features - Results
touch lib/features/results/results_screen.dart
touch lib/features/results/results_viewmodel.dart

# Features - History
touch lib/features/history/history_screen.dart
touch lib/features/history/history_viewmodel.dart

# Features - Settings
touch lib/features/settings/settings_screen.dart
touch lib/features/settings/settings_viewmodel.dart

# Services
touch lib/services/camera_service.dart
touch lib/services/ocr_service.dart
touch lib/services/llm_service.dart
touch lib/services/tts_service.dart
touch lib/services/storage_service.dart

echo ""
echo "✅ Scaffold complete! Folder structure:"
echo ""
find lib -type f -name "*.dart" | sort
echo ""
echo "➡️  Next step: Run 'flutter pub get' to install dependencies."
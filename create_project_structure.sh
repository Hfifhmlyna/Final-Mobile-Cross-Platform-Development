#!/bin/bash

# Script untuk membuat struktur folder project LMS EduTech SMK
# Feature-First Architecture

echo "🚀 Membuat struktur folder project EduTech SMK..."

# Membuat folder core
mkdir -p lib/core/constants
mkdir -p lib/core/router
mkdir -p lib/core/services
mkdir -p lib/core/theme
mkdir -p lib/core/utils
mkdir -p lib/core/widgets

# Membuat folder features - AUTH
mkdir -p lib/features/auth/data/models
mkdir -p lib/features/auth/data/repositories
mkdir -p lib/features/auth/presentation/pages
mkdir -p lib/features/auth/presentation/widgets
mkdir -p lib/features/auth/providers

# Membuat folder features - STUDENT
mkdir -p lib/features/student/data/models
mkdir -p lib/features/student/data/repositories
mkdir -p lib/features/student/presentation/pages
mkdir -p lib/features/student/presentation/widgets
mkdir -p lib/features/student/providers

# Membuat folder features - TEACHER
mkdir -p lib/features/teacher/data/models
mkdir -p lib/features/teacher/data/repositories
mkdir -p lib/features/teacher/presentation/pages
mkdir -p lib/features/teacher/presentation/widgets
mkdir -p lib/features/teacher/providers

# Membuat folder features - WALI KELAS
mkdir -p lib/features/wali_kelas/data/models
mkdir -p lib/features/wali_kelas/data/repositories
mkdir -p lib/features/wali_kelas/presentation/pages
mkdir -p lib/features/wali_kelas/presentation/widgets
mkdir -p lib/features/wali_kelas/providers

# Membuat folder features - BK (Bimbingan Konseling)
mkdir -p lib/features/bk/data/models
mkdir -p lib/features/bk/data/repositories
mkdir -p lib/features/bk/presentation/pages
mkdir -p lib/features/bk/presentation/widgets
mkdir -p lib/features/bk/providers

# Membuat folder features - PIKET
mkdir -p lib/features/piket/data/models
mkdir -p lib/features/piket/data/repositories
mkdir -p lib/features/piket/presentation/pages
mkdir -p lib/features/piket/presentation/widgets
mkdir -p lib/features/piket/providers

# Membuat folder features - SHARED
mkdir -p lib/features/shared/data/models
mkdir -p lib/features/shared/data/repositories
mkdir -p lib/features/shared/presentation/pages
mkdir -p lib/features/shared/presentation/widgets
mkdir -p lib/features/shared/providers

echo "✅ Struktur folder berhasil dibuat!"
echo ""
echo "📁 Struktur folder yang telah dibuat:"
echo "lib/"
echo "├── core/"
echo "│   ├── constants/"
echo "│   ├── router/"
echo "│   ├── services/"
echo "│   ├── theme/"
echo "│   ├── utils/"
echo "│   └── widgets/"
echo "└── features/"
echo "    ├── auth/"
echo "    ├── student/"
echo "    ├── teacher/"
echo "    ├── wali_kelas/"
echo "    ├── bk/"
echo "    ├── piket/"
echo "    └── shared/"
echo ""
echo "🎉 Project siap dikembangkan!"

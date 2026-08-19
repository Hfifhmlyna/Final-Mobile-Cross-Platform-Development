#!/bin/bash

# =====================================================
# deploy_web.sh
# Skrip Automated Deployment: Flutter Web -> Firebase Hosting
# Project: EduTech SMK LMS
# =====================================================

set -e  # Hentikan script jika ada error

# ---- Konfigurasi ----
PROJECT_ID="edutech-smk"           # Ganti dengan Firebase Project ID Anda
BUILD_DIR="build/web"
LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"

# Warna untuk output terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ---- Fungsi Helper ----
log_step() {
  echo -e "\n${BLUE}[STEP]${RESET} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${RESET} $1"
  exit 1
}

log_info() {
  echo -e "${CYAN}[INFO]${RESET} $1"
}

# ---- Banner ----
echo ""
echo -e "${CYAN}=================================================${RESET}"
echo -e "${CYAN}    EduTech SMK - Automated Web Deployment       ${RESET}"
echo -e "${CYAN}=================================================${RESET}"
echo -e "${CYAN}  Tanggal  : $(date '+%d-%m-%Y %H:%M:%S')${RESET}"
echo -e "${CYAN}  Project  : $PROJECT_ID${RESET}"
echo -e "${CYAN}  Log File : $LOG_FILE${RESET}"
echo -e "${CYAN}=================================================${RESET}"
echo ""

# ---- Pre-flight Checks ----
log_step "Melakukan pengecekan awal..."

# Cek Flutter tersedia
if ! command -v flutter &>/dev/null; then
  log_error "Flutter tidak ditemukan! Pastikan Flutter sudah terinstall dan ada di PATH."
fi
log_info "Flutter version: $(flutter --version --machine | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("frameworkVersion","unknown"))' 2>/dev/null || flutter --version | head -1)"

# Cek Firebase CLI tersedia
if ! command -v firebase &>/dev/null; then
  log_error "Firebase CLI tidak ditemukan! Install dengan: npm install -g firebase-tools"
fi
log_info "Firebase CLI version: $(firebase --version)"

# Cek file konfigurasi Firebase ada
if [ ! -f "firebase.json" ]; then
  log_error "File firebase.json tidak ditemukan! Jalankan 'firebase init hosting' terlebih dahulu."
fi

# Cek pubspec.yaml ada
if [ ! -f "pubspec.yaml" ]; then
  log_error "pubspec.yaml tidak ditemukan! Pastikan Anda berada di direktori root project Flutter."
fi

log_success "Pengecekan awal selesai."

# ---- Step 1: Flutter Clean ----
log_step "Membersihkan build sebelumnya..."
flutter clean >> "$LOG_FILE" 2>&1
log_success "Flutter clean selesai."

# ---- Step 2: Get Dependencies ----
log_step "Mengunduh dependensi Flutter..."
flutter pub get >> "$LOG_FILE" 2>&1
log_success "Dependensi berhasil diunduh."

# ---- Step 3: Run Tests (Opsional - comment jika perlu skip) ----
log_step "Menjalankan unit tests..."
if flutter test >> "$LOG_FILE" 2>&1; then
  log_success "Semua test berhasil."
else
  log_warn "Ada test yang gagal. Deployment tetap dilanjutkan."
fi

# ---- Step 4: Build Flutter Web Release ----
log_step "Membangun Flutter Web (Release Mode)..."
log_info "Ini mungkin membutuhkan beberapa menit..."

flutter build web \
  --release \
  --web-renderer canvaskit \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  >> "$LOG_FILE" 2>&1

# Verifikasi build berhasil
if [ ! -d "$BUILD_DIR" ]; then
  log_error "Build gagal! Direktori $BUILD_DIR tidak ditemukan. Cek $LOG_FILE untuk detail."
fi

BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
log_success "Build web berhasil. Ukuran: $BUILD_SIZE"

# ---- Step 5: Deploy Firestore Rules ----
log_step "Mendeploy Firestore Security Rules..."
if [ -f "firestore.rules" ]; then
  firebase deploy \
    --only firestore:rules \
    --project "$PROJECT_ID" \
    >> "$LOG_FILE" 2>&1
  log_success "Firestore rules berhasil dideploy."
else
  log_warn "File firestore.rules tidak ditemukan. Skip deployment rules."
fi

# ---- Step 6: Deploy ke Firebase Hosting ----
log_step "Mendeploy ke Firebase Hosting..."
firebase deploy \
  --only hosting \
  --project "$PROJECT_ID" \
  >> "$LOG_FILE" 2>&1

log_success "Deployment ke Firebase Hosting berhasil!"

# ---- Summary ----
echo ""
echo -e "${GREEN}=================================================${RESET}"
echo -e "${GREEN}    DEPLOYMENT BERHASIL!                         ${RESET}"
echo -e "${GREEN}=================================================${RESET}"
echo -e "${GREEN}  Project   : $PROJECT_ID${RESET}"
echo -e "${GREEN}  URL       : https://$PROJECT_ID.web.app${RESET}"
echo -e "${GREEN}  Ukuran    : $BUILD_SIZE${RESET}"
echo -e "${GREEN}  Selesai   : $(date '+%d-%m-%Y %H:%M:%S')${RESET}"
echo -e "${GREEN}  Log       : $LOG_FILE${RESET}"
echo -e "${GREEN}=================================================${RESET}"
echo ""

/**
 * seed_users.js — EduTech SMK
 * Jalankan: node seed_users.js
 */

const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

// Coba service-account.json dulu, fallback ke Application Default Credentials
const saPath = path.join(__dirname, "service-account.json");
if (fs.existsSync(saPath)) {
  const serviceAccount = require(saPath);
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
} else {
  // Pakai ADC (jika sudah gcloud auth application-default login)
  admin.initializeApp({
    projectId: "edutech-smk-app",
    credential: admin.credential.applicationDefault(),
  });
}

const auth = admin.auth();
const db = admin.firestore();

const users = [
  // ── ADMIN ──────────────────────────────────────────────
  {
    email: "admin@edutechsmk.com",
    password: "Admin@2025",
    nama: "Administrator",
    role: "ADMIN",
    kelasId: null,
  },

  // ── GURU MAPEL ──────────────────────────────────────────
  {
    email: "guru.ipa@edutechsmk.com",
    password: "Guru@2025",
    nama: "Budi Santoso",
    role: "GURU_MAPEL",
    kelasId: "X-TKJ-1",
  },
  {
    email: "guru.matematika@edutechsmk.com",
    password: "Guru@2025",
    nama: "Siti Rahayu",
    role: "GURU_MAPEL",
    kelasId: "X-TKJ-1",
  },
  {
    email: "guru.bindo@edutechsmk.com",
    password: "Guru@2025",
    nama: "Ahmad Fauzi",
    role: "GURU_MAPEL",
    kelasId: "XI-RPL-1",
  },

  // ── WALI KELAS ──────────────────────────────────────────
  {
    email: "wali.x.tkj1@edutechsmk.com",
    password: "Wali@2025",
    nama: "Dewi Kurniawati",
    role: "WALI_KELAS",
    kelasId: "X-TKJ-1",
  },
  {
    email: "wali.xi.rpl1@edutechsmk.com",
    password: "Wali@2025",
    nama: "Hendra Gunawan",
    role: "WALI_KELAS",
    kelasId: "XI-RPL-1",
  },

  // ── GURU BK ─────────────────────────────────────────────
  {
    email: "bk1@edutechsmk.com",
    password: "BK@2025",
    nama: "Ratna Sari",
    role: "GURU_BK",
    kelasId: null,
  },
  {
    email: "bk2@edutechsmk.com",
    password: "BK@2025",
    nama: "Joko Susilo",
    role: "GURU_BK",
    kelasId: null,
  },

  // ── GURU PIKET ──────────────────────────────────────────
  {
    email: "piket1@edutechsmk.com",
    password: "Piket@2025",
    nama: "Agus Widodo",
    role: "GURU_PIKET",
    kelasId: null,
  },
  {
    email: "piket2@edutechsmk.com",
    password: "Piket@2025",
    nama: "Rina Wati",
    role: "GURU_PIKET",
    kelasId: null,
  },

  // ── SISWA ───────────────────────────────────────────────
  {
    email: "siswa.andi@edutechsmk.com",
    password: "Siswa@2025",
    nama: "Andi Pratama",
    role: "SISWA",
    kelasId: "X-TKJ-1",
    nis: "2025001",
  },
  {
    email: "siswa.budi@edutechsmk.com",
    password: "Siswa@2025",
    nama: "Budi Cahyono",
    role: "SISWA",
    kelasId: "X-TKJ-1",
    nis: "2025002",
  },
  {
    email: "siswa.citra@edutechsmk.com",
    password: "Siswa@2025",
    nama: "Citra Dewi",
    role: "SISWA",
    kelasId: "X-TKJ-1",
    nis: "2025003",
  },
  {
    email: "siswa.doni@edutechsmk.com",
    password: "Siswa@2025",
    nama: "Doni Setiawan",
    role: "SISWA",
    kelasId: "XI-RPL-1",
    nis: "2024001",
  },
  {
    email: "siswa.eka@edutechsmk.com",
    password: "Siswa@2025",
    nama: "Eka Putri",
    role: "SISWA",
    kelasId: "XI-RPL-1",
    nis: "2024002",
  },
];

async function seedUsers() {
  console.log("🚀 Memulai seed data pengguna EduTech SMK...\n");
  let sukses = 0;
  let gagal = 0;

  for (const user of users) {
    try {
      // Cek apakah sudah ada
      let uid;
      try {
        const existing = await auth.getUserByEmail(user.email);
        uid = existing.uid;
        console.log(`⚠️  Sudah ada: ${user.email} (skip create auth)`);
      } catch {
        // Buat akun baru di Firebase Auth
        const record = await auth.createUser({
          email: user.email,
          password: user.password,
          displayName: user.nama,
        });
        uid = record.uid;
        console.log(`✅ Auth dibuat: ${user.email}`);
      }

      // Buat/update dokumen di Firestore
      await db.collection("users").doc(uid).set({
        uid,
        email: user.email,
        nama: user.nama,
        role: user.role,
        kelasId: user.kelasId || null,
        nis: user.nis || null,
        fotoUrl: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      console.log(`   📄 Firestore: ${user.role} - ${user.nama}`);
      sukses++;
    } catch (err) {
      console.error(`❌ Gagal: ${user.email} → ${err.message}`);
      gagal++;
    }
  }

  console.log(`\n✨ Selesai! ${sukses} berhasil, ${gagal} gagal.`);
  process.exit(0);
}

seedUsers();

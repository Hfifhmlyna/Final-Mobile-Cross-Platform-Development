/**
 * seed_users_rest.js — EduTech SMK
 * Pakai Firebase REST API — tidak perlu service account!
 * Jalankan: node seed_users_rest.js
 */

const https = require("https");
const http_module = require("http");

const API_KEY = "AIzaSyCDs7i04k42v69t-6jwkaUgM2ZDKwPbc84";
const PROJECT_ID = "edutech-smk-app";

// ── Data semua pengguna ──────────────────────────────────────────────────────
const USERS = [
  // ADMIN
  { email: "admin@edutechsmk.com",            password: "Admin@2025",  nama: "Administrator",   role: "ADMIN",      kelasId: null,       nis: null },
  // GURU MAPEL
  { email: "guru.ipa@edutechsmk.com",          password: "Guru@2025",   nama: "Budi Santoso",    role: "GURU_MAPEL", kelasId: "X-TKJ-1",  nis: null },
  { email: "guru.matematika@edutechsmk.com",   password: "Guru@2025",   nama: "Siti Rahayu",     role: "GURU_MAPEL", kelasId: "X-TKJ-1",  nis: null },
  { email: "guru.bindo@edutechsmk.com",        password: "Guru@2025",   nama: "Ahmad Fauzi",     role: "GURU_MAPEL", kelasId: "XI-RPL-1", nis: null },
  // WALI KELAS
  { email: "wali.x.tkj1@edutechsmk.com",      password: "Wali@2025",   nama: "Dewi Kurniawati", role: "WALI_KELAS", kelasId: "X-TKJ-1",  nis: null },
  { email: "wali.xi.rpl1@edutechsmk.com",     password: "Wali@2025",   nama: "Hendra Gunawan",  role: "WALI_KELAS", kelasId: "XI-RPL-1", nis: null },
  // GURU BK
  { email: "bk1@edutechsmk.com",              password: "BK@2025",     nama: "Ratna Sari",      role: "GURU_BK",    kelasId: null,       nis: null },
  { email: "bk2@edutechsmk.com",              password: "BK@2025",     nama: "Joko Susilo",     role: "GURU_BK",    kelasId: null,       nis: null },
  // GURU PIKET
  { email: "piket1@edutechsmk.com",           password: "Piket@2025",  nama: "Agus Widodo",     role: "GURU_PIKET", kelasId: null,       nis: null },
  { email: "piket2@edutechsmk.com",           password: "Piket@2025",  nama: "Rina Wati",       role: "GURU_PIKET", kelasId: null,       nis: null },
  // SISWA
  { email: "siswa.andi@edutechsmk.com",       password: "Siswa@2025",  nama: "Andi Pratama",    role: "SISWA",      kelasId: "X-TKJ-1",  nis: "2025001" },
  { email: "siswa.budi@edutechsmk.com",       password: "Siswa@2025",  nama: "Budi Cahyono",    role: "SISWA",      kelasId: "X-TKJ-1",  nis: "2025002" },
  { email: "siswa.citra@edutechsmk.com",      password: "Siswa@2025",  nama: "Citra Dewi",      role: "SISWA",      kelasId: "X-TKJ-1",  nis: "2025003" },
  { email: "siswa.doni@edutechsmk.com",       password: "Siswa@2025",  nama: "Doni Setiawan",   role: "SISWA",      kelasId: "XI-RPL-1", nis: "2024001" },
  { email: "siswa.eka@edutechsmk.com",        password: "Siswa@2025",  nama: "Eka Putri",       role: "SISWA",      kelasId: "XI-RPL-1", nis: "2024002" },
];

// ── Helper HTTP request ──────────────────────────────────────────────────────
function httpRequest(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

// Daftar akun baru via Firebase Auth REST
async function signUp(email, password, displayName) {
  const res = await httpRequest(
    {
      hostname: "identitytoolkit.googleapis.com",
      path: `/v1/accounts:signUp?key=${API_KEY}`,
      method: "POST",
      headers: { "Content-Type": "application/json" },
    },
    { email, password, displayName, returnSecureToken: true }
  );
  return res;
}

// Tulis dokumen Firestore via REST API (pakai ID token user itu sendiri)
async function writeFirestore(uid, idToken, data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (v === null) fields[k] = { nullValue: null };
    else if (typeof v === "string") fields[k] = { stringValue: v };
    else if (typeof v === "boolean") fields[k] = { booleanValue: v };
    else if (typeof v === "number") fields[k] = { integerValue: `${v}` };
  }
  fields.createdAt = { timestampValue: new Date().toISOString() };

  const res = await httpRequest(
    {
      hostname: "firestore.googleapis.com",
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`,
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
    },
    { fields }
  );
  return res;
}

// ── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log("🚀 EduTech SMK — Seed Data Pengguna\n");
  let ok = 0, fail = 0;

  for (const u of USERS) {
    process.stdout.write(`  [${u.role.padEnd(12)}] ${u.email} ... `);
    try {
      const signUpRes = await signUp(u.email, u.password, u.nama);
      if (signUpRes.status !== 200) {
        // Mungkin sudah ada — coba login untuk dapat idToken
        const loginRes = await httpRequest(
          {
            hostname: "identitytoolkit.googleapis.com",
            path: `/v1/accounts:signInWithPassword?key=${API_KEY}`,
            method: "POST",
            headers: { "Content-Type": "application/json" },
          },
          { email: u.email, password: u.password, returnSecureToken: true }
        );
        if (loginRes.status !== 200) {
          console.log(`❌ ${signUpRes.body.error?.message || "gagal"}`);
          fail++;
          continue;
        }
        const { localId, idToken } = loginRes.body;
        await writeFirestore(localId, idToken, {
          uid: localId, email: u.email, nama: u.nama,
          role: u.role, kelasId: u.kelasId, nis: u.nis, fotoUrl: null,
        });
        console.log("✅ (sudah ada, Firestore diupdate)");
      } else {
        const { localId, idToken } = signUpRes.body;
        const fsRes = await writeFirestore(localId, idToken, {
          uid: localId, email: u.email, nama: u.nama,
          role: u.role, kelasId: u.kelasId, nis: u.nis, fotoUrl: null,
        });
        if (fsRes.status === 200) {
          console.log("✅ dibuat");
          ok++;
        } else {
          console.log(`⚠️  Auth OK, Firestore: ${fsRes.body.error?.message || fsRes.status}`);
          ok++;
        }
      }
    } catch (e) {
      console.log(`❌ ${e.message}`);
      fail++;
    }
  }

  console.log(`\n✨ Selesai: ${ok} berhasil, ${fail} gagal\n`);
  console.log("📋 DAFTAR AKUN LENGKAP:");
  console.log("═══════════════════════════════════════════════════════════");
  const groups = {};
  for (const u of USERS) {
    if (!groups[u.role]) groups[u.role] = [];
    groups[u.role].push(u);
  }
  for (const [role, list] of Object.entries(groups)) {
    console.log(`\n  ${role}`);
    for (const u of list) {
      console.log(`    Email   : ${u.email}`);
      console.log(`    Password: ${u.password}`);
      if (u.nama) console.log(`    Nama    : ${u.nama}`);
      if (u.kelasId) console.log(`    Kelas   : ${u.kelasId}`);
      if (u.nis) console.log(`    NIS     : ${u.nis}`);
      console.log();
    }
  }
}

main().catch(console.error);

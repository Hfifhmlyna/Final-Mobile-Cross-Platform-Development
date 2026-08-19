/**
 * seed_content.js — EduTech SMK
 * Tambah data sample: assignment, presensi, nilai
 * Jalankan: node seed_content.js
 */

const https = require("https");

const API_KEY = "AIzaSyCDs7i04k42v69t-6jwkaUgM2ZDKwPbc84";
const PROJECT = "edutech-smk-app";

function req(opt, body) {
  return new Promise((res, rej) => {
    const r = https.request(opt, resp => {
      let d = "";
      resp.on("data", c => (d += c));
      resp.on("end", () => {
        try { res({ s: resp.statusCode, b: JSON.parse(d) }); }
        catch { res({ s: resp.statusCode, b: d }); }
      });
    });
    r.on("error", rej);
    if (body) r.write(JSON.stringify(body));
    r.end();
  });
}

// Helper: tulis dokumen Firestore ke koleksi tertentu
async function addDoc(token, collection, data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (v === null) fields[k] = { nullValue: null };
    else if (typeof v === "string") fields[k] = { stringValue: v };
    else if (typeof v === "boolean") fields[k] = { booleanValue: v };
    else if (typeof v === "number") fields[k] = { doubleValue: v };
    else if (v instanceof Date) fields[k] = { timestampValue: v.toISOString() };
  }
  return req({
    hostname: "firestore.googleapis.com",
    path: `/v1/projects/${PROJECT}/databases/(default)/documents/${collection}`,
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
  }, { fields });
}

async function main() {
  // Login sebagai guru IPA
  const loginGuru = await req({
    hostname: "identitytoolkit.googleapis.com",
    path: `/v1/accounts:signInWithPassword?key=${API_KEY}`,
    method: "POST", headers: { "Content-Type": "application/json" },
  }, { email: "guru.ipa@edutechsmk.com", password: "Guru@2025", returnSecureToken: true });

  const guruToken = loginGuru.b.idToken;
  const guruId = loginGuru.b.localId;
  console.log("✅ Login guru berhasil");

  const now = new Date();
  const nextWeek = new Date(Date.now() + 7 * 86400000);
  const twoWeeks = new Date(Date.now() + 14 * 86400000);
  const yesterday = new Date(Date.now() - 86400000);

  // ── ASSIGNMENTS (Materi + Tugas) ──────────────────────────────────────────
  console.log("\n📚 Membuat assignments...");
  const assignments = [
    { title: "Materi 1: Pengenalan IPA", description: "Pengantar materi IPA kelas X semester 1", mapel: "IPA", kelasId: "X-TKJ-1", teacherId: guruId, dueDate: twoWeeks, createdAt: yesterday, pdfUrl: null, videoUrl: null },
    { title: "Tugas 1: Rangkuman Bab 1", description: "Buat rangkuman bab 1 tentang besaran dan satuan. Kumpulkan dalam format PDF.", mapel: "IPA", kelasId: "X-TKJ-1", teacherId: guruId, dueDate: nextWeek, createdAt: now, pdfUrl: null, videoUrl: null },
    { title: "Tugas 2: Soal Latihan Fisika", description: "Kerjakan soal latihan halaman 25-30. Foto hasil pekerjaan dan kumpulkan.", mapel: "IPA", kelasId: "X-TKJ-1", teacherId: guruId, dueDate: twoWeeks, createdAt: now, pdfUrl: null, videoUrl: null },
  ];

  for (const a of assignments) {
    const r = await addDoc(guruToken, "assignments", a);
    console.log(r.s === 200 ? `  ✅ ${a.title}` : `  ❌ ${a.title}: ${r.s}`);
  }

  // ── GRADES (Nilai) ────────────────────────────────────────────────────────
  console.log("\n📊 Membuat data nilai...");
  const siswaList = [
    { id: null, nama: "Andi Pratama", nis: "2025001" },
    { id: null, nama: "Budi Cahyono", nis: "2025002" },
    { id: null, nama: "Citra Dewi", nis: "2025003" },
  ];

  // Login sebagai admin untuk dapat UID siswa
  const loginAdmin = await req({
    hostname: "identitytoolkit.googleapis.com",
    path: `/v1/accounts:signInWithPassword?key=${API_KEY}`,
    method: "POST", headers: { "Content-Type": "application/json" },
  }, { email: "admin@edutechsmk.com", password: "Admin@2025", returnSecureToken: true });
  const adminToken = loginAdmin.b.idToken;

  // Ambil UID siswa dari Firestore
  const usersSnap = await req({
    hostname: "firestore.googleapis.com",
    path: `/v1/projects/${PROJECT}/databases/(default)/documents/users`,
    method: "GET", headers: { Authorization: `Bearer ${adminToken}` },
  });

  for (const doc of usersSnap.b.documents || []) {
    const role = doc.fields?.role?.stringValue;
    const nama = doc.fields?.nama?.stringValue;
    const uid = doc.name.split("/").pop();
    const s = siswaList.find(s => s.nama === nama);
    if (s) s.id = uid;
  }

  const mapels = ["IPA", "Matematika", "Bahasa Indonesia"];
  for (const siswa of siswaList) {
    if (!siswa.id) { console.log(`  ⚠️ UID tidak ditemukan: ${siswa.nama}`); continue; }
    for (const mapel of mapels) {
      const nilai = Math.floor(Math.random() * 25) + 70; // 70-95
      const r = await addDoc(guruToken, "grades", {
        studentId: siswa.id, studentName: siswa.nama,
        kelasId: "X-TKJ-1", mapel, nilai,
        teacherId: guruId, createdAt: now,
      });
      process.stdout.write(r.s === 200 ? "." : "x");
    }
  }
  console.log(" ✅ nilai dibuat");

  // ── ATTENDANCE (Presensi 5 hari terakhir) ─────────────────────────────────
  console.log("\n📋 Membuat data presensi...");
  const statuses = ["HADIR", "HADIR", "HADIR", "HADIR", "SAKIT"]; // mostly hadir
  let attCount = 0;

  for (let day = 0; day < 5; day++) {
    const tanggal = new Date(Date.now() - day * 86400000);
    if (tanggal.getDay() === 0 || tanggal.getDay() === 6) continue; // skip weekend

    for (let i = 0; i < siswaList.length; i++) {
      const siswa = siswaList[i];
      if (!siswa.id) continue;
      const status = statuses[(i + day) % statuses.length];
      const r = await addDoc(guruToken, "attendance", {
        studentId: siswa.id, studentName: siswa.nama,
        kelasId: "X-TKJ-1", status,
        keterangan: status === "SAKIT" ? "Sakit demam" : null,
        timestamp: tanggal, recordedBy: guruId,
      });
      if (r.s === 200) attCount++;
    }
  }
  console.log(`  ✅ ${attCount} record presensi dibuat`);

  // ── PIKET LOG ─────────────────────────────────────────────────────────────
  console.log("\n📖 Membuat buku piket...");
  const loginPiket = await req({
    hostname: "identitytoolkit.googleapis.com",
    path: `/v1/accounts:signInWithPassword?key=${API_KEY}`,
    method: "POST", headers: { "Content-Type": "application/json" },
  }, { email: "piket1@edutechsmk.com", password: "Piket@2025", returnSecureToken: true });
  const piketToken = loginPiket.b.idToken;
  const piketId = loginPiket.b.localId;

  await addDoc(piketToken, "piket_logs", {
    teacherId: piketId, date: now.toISOString().split("T")[0],
    catatan: "Hari berjalan lancar. Tidak ada kejadian luar biasa. Semua siswa hadir tepat waktu.",
    createdAt: now,
  });
  console.log("  ✅ Buku piket hari ini");

  console.log("\n🎉 Semua data sample berhasil ditambahkan!");
  console.log("   → Dashboard siswa kini menampilkan materi, tugas, nilai, dan presensi");
}

main().catch(console.error);

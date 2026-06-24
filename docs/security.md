# Security — Kebijakan & Operasional (Ditulis oleh CTO)

Pemilik: security@oasis.io
Penulis: CTO (Chief Technology Officer)
Terakhir diperbarui: 2026-06-24

Ringkasan

Dokumen ini menetapkan kebijakan keamanan produksi untuk OASIS dan menjelaskan persyaratan operasional yang harus dipenuhi sebelum sistem dianggap layak produksi. Semua tim engineering dan operasi wajib mematuhi kebijakan ini; setiap pengecualian harus didokumentasikan dan disetujui oleh tim keamanan dan CTO.

Prinsip Utama

1. Defense in Depth: lapis-lapis kontrol (network, platform, aplikasi, data).
2. Least Privilege: akses diberikan berdasarkan kebutuhan bisnis dan direview secara rutin.
3. Fail Secure: ketika sistem mengalami kegagalan, perilaku default harus melindungi data dan menolak akses yang tidak terotorisasi.
4. Auditable & Observable: semua tindakan sensitif harus dapat diaudit dan dipantau.
5. Automate Security: gunakan pipeline, policy-as-code, dan pemeriksaan otomatis untuk konsistensi.

1. Manajemen Rahasia & Kunci

- Semua rahasia (database credentials, API keys, TLS private keys) harus disimpan di secret manager terpusat (Vault, AWS Secrets Manager, atau Azure Key Vault).
- Rahasia tidak boleh disimpan di repositori kode, file konfigurasi plaintext, atau image kontainer.
- Rotasi kunci:
  - Kunci akses jangka panjang: rotasi tahunan.
  - Kunci layanan sensitif (DB superuser, signing keys): rotasi setiap 90 hari.
- Akses rahasia melalui role-based access control; gunakan pendekatan "just-in-time" atau "credential brokering" bila memungkinkan.
- Audit: semua pembacaan atau perubahan rahasia tercatat dengan user identity, timestamp, dan alasan akses.

Contoh akses teraman (tanpa kredensial):
- Aplikasi membaca rahasia via Vault AppRole/PKI atau cloud IAM role; operator mengubah rahasia melalui pipeline yang menulis ke Vault.

2. Identitas & Akses (IAM)

- Gunakan prinsip least-privilege untuk semua identitas: manusia, layanan, pipeline.
- Manajemen role:
  - Pisahkan role untuk pengembangan, staging, dan produksi.
  - Operator hanya mendapatkan akses produksi saat on-call atau melalui escalated session.
- MFA: wajib untuk semua akun dengan akses ke produksi (SSO + MFA hardware/TOTP).
- Review akses: audit list akses setiap 30 hari dan lakukan recertification untuk akses tinggi.

3. Otorisasi Aplikasi (AuthZ)

- Model otorisasi kami adalah RBAC berpola resource-level dengan kontrol tenant-aware.
- Gateway melakukan coarse-grained checks (route-level), layanan bertanggung jawab melakukan fine-grained authorization.
- Use-case:
  - Periksa scope/role pada token: token harus memiliki klaim `tenant_id` dan `roles`.
  - Resource owner checks dilakukan di layanan yang memiliki otoritas data.

4. Otentikasi & Manajemen Token

- Otentikasi central: auth-service yang mengeluarkan JWT short-lived (akses) dan refresh token.
- Refresh token rotation dan revocation lists harus diterapkan.
- Kunci signing JWT harus dikelola oleh KMS; gunakan JWKS untuk distribusi publik key (rotasi dengan overlap window).

5. Jaringan & Perimeter

- Pisahkan jaringan dengan VPC/subnet: kontrol akses antar-layanan dengan security group/NSG.
- Database hanya dapat diakses dari subnet internal atau melalui bastion/privatelink.
- Enforce egress rules: hanya domain/port yang diperlukan yang diizinkan.
- Use VPC endpoints / private links untuk akses ke storage dan managed services.

6. Enkripsi

- Transit: TLS 1.2+ (prefer TLS1.3), strong cipher suites. HSTS untuk publik.
- Rest: Enkripsi dengan KMS-managed keys (AES-256-GCM). Data paling sensitif di-encrypt di aplikasi sebelum persistence bila perlu.
- Key management: KMS atau Vault; kunci root tidak pernah digunakan langsung — gunakan envelope encryption.

7. Rantai Pasokan Perangkat Lunak (Software Supply Chain)

- Semua image container harus dibangun di CI yang tepercaya, dipindai untuk kerentanan (SCA) dan ditandatangani (cosign/notation).
- Gunakan immutable tags and provenance: setiap image menyimpan metadata build (commit sha, build id).
- Dependabot / Renovate untuk dependensi; high-severity vulnerabilities diselesaikan sesuai SLA (48 jam untuk P0/P1).

8. CI/CD & Gates Keamanan

- Pipeline harus menyertakan pemeriksaan keamanan: SAST, dependency scan, container image scan, dan infrastructure-as-code security checks.
- Kebijakan merge: branch yang menyentuh infrastruktur atau rahasia memerlukan setidaknya 2 approver termasuk security owner.
- Promosi image ke lingkungan berikutnya harus melalui automated tests, scanning, dan approvals.

9. Observability & Auditing Keamanan

- Audit logging:
  - Semua akses administratif ke infra dan rahasia harus diaudit.
  - Database melakukan audit logging untuk operasi sensitif (DDL, perubahan permission).
- SIEM: logs dikumpulkan ke ELK/managed SIEM dengan aturan korelasi untuk deteksi ancaman.
- Alerting: abnormal auth behavior (login luar biasa, pembacaan rahasia massal) harus memicu P0/P1 sesuai eskalasi.

10. Penanganan Insiden Keamanan

- Runbook insiden wajib tersedia dan diuji setidaknya setahun sekali.
- Langkah pertama (first 30 minutes):
  1. Identifikasi cakupan insiden dan isolasi komponen terpengaruh.
  2. Revokasi kunci/credential yang dikompromikan (rotate immediately).
  3. Aktifkan mitigasi network (blokir IP, isolate subnet).
  4. Kumpulkan artefak forensik (logs, snapshots) dan simpan di lokasi aman.
- Post-mortem: root cause analysis, mitigations, timeline, dan lessons learned; laporkan ke CTO dan keamanan.

11. Pengujian Keamanan

- SAST/DAST: otomatis setiap PR dan nightly full-run.
- Pentest: eksternal/independent penetration testing minimal tiap tahun atau setelah perubahan arsitektural besar.
- Chaos & resilience testing: uji pemulihan terhadap skenario ancaman seperti credential loss atau data corruption.

12. Kepatuhan & Sertifikasi

- Kebijakan ini mendukung kepatuhan SOC2, GDPR, dan persyaratan HIPAA saat diaktifkan untuk tenant tertentu.
- Data-privacy: implementasikan data minimization dan right-to-erasure workflow yang dapat diaudit.

13. Pendidikan & Proses

- Semua engineer wajib mengikuti onboarding security training (secure coding, incident response) dan refresher setiap tahun.
- Security champions: satu per tim engineering untuk membantu penerapan kebijakan.

14. Tes & Validasi Produksi

- Sebelum perubahan ke produksi, jalankan: automated security scans, smoke tests, dan review konfigurasi jaringan/secret access.
- Checklist pra-produksi: kunci tidak hard-coded, secret access path valid, SAST/Dependency scan lulus, dan approval security owner.

15. Metadata & Kontak

- Maintainers: security@oasis.io
- CTO contact: cto@oasis.io
- On-call security: sec-oncall@oasis.io

Penutup

Kepatuhan terhadap kebijakan ini adalah prasyarat operasi produksi untuk OASIS. Dokumen ini merupakan sumber kebenaran untuk kebijakan keamanan — setiap pengecualian harus terdokumentasi dengan jelas dan disetujui oleh security@oasis.io dan CTO.

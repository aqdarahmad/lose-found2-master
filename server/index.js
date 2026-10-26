// Lost & Found web server: serves the Flutter web build and the REST API (Postgres/Neon).
import express from "express";
import helmet from "helmet";
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";
import { api } from "./routes.js";
import { initDb, dbEnabled } from "./db.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const WEB_DIR = path.resolve(__dirname, "..", "build", "web");
const PORT = process.env.PORT || 5000;

const app = express();
app.set("trust proxy", 1);
app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }));
app.use(express.json({ limit: "100kb" }));

app.get("/api/health", (_req, res) => res.json({ ok: true, db: dbEnabled }));
app.use("/api", api);
app.use("/api", (_req, res) => res.status(404).json({ error: "Not found." }));

if (fs.existsSync(WEB_DIR)) {
  app.use(express.static(WEB_DIR, { maxAge: "1h", index: false }));
  app.get(/^\/(?!api\/).*/, (_req, res) => res.sendFile(path.join(WEB_DIR, "index.html")));
} else {
  app.get("/", (_req, res) => res.status(503).send("Flutter web build not found. Run: flutter build web --release"));
}

await initDb().catch((e) => console.error("DB init failed:", e.message));
app.listen(PORT, () => console.log(`Lost & Found server on :${PORT} (db: ${dbEnabled})`));

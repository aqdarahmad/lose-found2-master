import { Router } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import crypto from "node:crypto";
import rateLimit from "express-rate-limit";
import { pool, dbEnabled, DEFAULT_AVATAR } from "./db.js";

const JWT_SECRET =
  process.env.JWT_SECRET ||
  (process.env.DATABASE_URL
    ? crypto.createHash("sha256").update("lost-found:" + process.env.DATABASE_URL).digest("hex")
    : "");

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const isHttpUrl = (s) => s === "" || /^https?:\/\/\S{1,1000}$/i.test(s);
const str = (v) => (typeof v === "string" ? v.trim() : "");
const toId = (v) => (/^\d{1,9}$/.test(String(v)) ? Number(v) : null);

const userJson = (r) => ({
  id: String(r.id),
  email: r.email,
  username: r.username,
  bio: r.bio,
  avatarURL: r.avatar_url,
  createdAt: r.created_at,
});

const sign = (u) => jwt.sign({ id: u.id }, JWT_SECRET, { expiresIn: "30d" });

function requireAuth(req, res, next) {
  if (!dbEnabled || !JWT_SECRET) return res.status(500).json({ error: "Server is not configured (DATABASE_URL missing)." });
  const h = req.headers.authorization || "";
  try {
    req.userId = jwt.verify(h.startsWith("Bearer ") ? h.slice(7) : "", JWT_SECRET).id;
    next();
  } catch {
    res.status(401).json({ error: "Please sign in again." });
  }
}

const wrap = (fn) => (req, res) =>
  Promise.resolve(fn(req, res)).catch((e) => {
    console.error(req.method, req.path, e.message);
    res.status(500).json({ error: "Something went wrong." });
  });

export const api = Router();

api.use(
  "/auth",
  rateLimit({ windowMs: 15 * 60 * 1000, limit: 60, standardHeaders: true, legacyHeaders: false, message: { error: "Too many attempts, try again later." } }),
);

// ---------------- auth
api.post("/auth/signup", wrap(async (req, res) => {
  if (!dbEnabled || !JWT_SECRET) return res.status(500).json({ error: "Server is not configured (DATABASE_URL missing)." });
  const email = str(req.body?.email).toLowerCase();
  const username = str(req.body?.username);
  const password = String(req.body?.password || "");
  if (!EMAIL_RE.test(email)) return res.status(400).json({ error: "The email address is badly formatted." });
  if (username.length < 2 || username.length > 30) return res.status(400).json({ error: "Username must be 2-30 characters." });
  if (password.length < 6) return res.status(400).json({ error: "The password provided is too weak (min 6 characters)." });
  const hash = await bcrypt.hash(password, 10);
  try {
    const r = await pool.query(
      "INSERT INTO lf_users (email, username, password_hash) VALUES ($1,$2,$3) RETURNING *",
      [email, username, hash],
    );
    res.status(201).json({ token: sign(r.rows[0]), user: userJson(r.rows[0]) });
  } catch (e) {
    if (e.code === "23505") return res.status(409).json({ error: "An account already exists for that email." });
    throw e;
  }
}));

api.post("/auth/login", wrap(async (req, res) => {
  if (!dbEnabled || !JWT_SECRET) return res.status(500).json({ error: "Server is not configured (DATABASE_URL missing)." });
  const r = await pool.query("SELECT * FROM lf_users WHERE email=$1", [str(req.body?.email).toLowerCase()]);
  const u = r.rows[0];
  if (!u || !(await bcrypt.compare(String(req.body?.password || ""), u.password_hash)))
    return res.status(401).json({ error: "Invalid email or password." });
  res.json({ token: sign(u), user: userJson(u) });
}));

api.put("/auth/password", requireAuth, wrap(async (req, res) => {
  const { currentPassword, newPassword } = req.body || {};
  if (String(newPassword || "").length < 6) return res.status(400).json({ error: "New password must be at least 6 characters." });
  const r = await pool.query("SELECT password_hash FROM lf_users WHERE id=$1", [req.userId]);
  if (!r.rows[0] || !(await bcrypt.compare(String(currentPassword || ""), r.rows[0].password_hash)))
    return res.status(400).json({ error: "Current password is incorrect." });
  await pool.query("UPDATE lf_users SET password_hash=$1 WHERE id=$2", [await bcrypt.hash(String(newPassword), 10), req.userId]);
  res.json({ ok: true });
}));

// ---------------- users
api.get("/users", requireAuth, wrap(async (_req, res) => {
  const r = await pool.query("SELECT id, username, avatar_url FROM lf_users ORDER BY username LIMIT 500");
  res.json(r.rows.map((u) => ({ id: String(u.id), username: u.username, avatarURL: u.avatar_url })));
}));

api.get("/users/me", requireAuth, wrap(async (req, res) => {
  const r = await pool.query("SELECT * FROM lf_users WHERE id=$1", [req.userId]);
  if (!r.rows[0]) return res.status(401).json({ error: "Please sign in again." });
  res.json(userJson(r.rows[0]));
}));

api.put("/users/me", requireAuth, wrap(async (req, res) => {
  const username = str(req.body?.username);
  const bio = str(req.body?.bio).slice(0, 300);
  const avatar = str(req.body?.avatarURL) || DEFAULT_AVATAR;
  if (username.length < 2 || username.length > 30) return res.status(400).json({ error: "Username must be 2-30 characters." });
  if (!isHttpUrl(avatar)) return res.status(400).json({ error: "Avatar must be a valid http(s) link." });
  const r = await pool.query(
    "UPDATE lf_users SET username=$1, bio=$2, avatar_url=$3 WHERE id=$4 RETURNING *",
    [username, bio, avatar, req.userId],
  );
  res.json(userJson(r.rows[0]));
}));

api.delete("/users/me", requireAuth, wrap(async (req, res) => {
  await pool.query("DELETE FROM lf_users WHERE id=$1", [req.userId]);
  res.json({ ok: true });
}));

api.get("/users/:id", requireAuth, wrap(async (req, res) => {
  const id = toId(req.params.id);
  const r = id && (await pool.query("SELECT * FROM lf_users WHERE id=$1", [id]));
  if (!r || !r.rows[0]) return res.status(404).json({ error: "User not found." });
  const u = userJson(r.rows[0]);
  delete u.email;
  res.json(u);
}));

// ---------------- posts
const POST_SELECT = `
  SELECT p.id, p.description, p.image_url, p.is_resolved, p.created_at,
         u.id AS author_id, u.username, u.avatar_url,
         (SELECT count(*) FROM lf_likes l WHERE l.post_id = p.id)::int AS like_count,
         EXISTS (SELECT 1 FROM lf_likes l WHERE l.post_id = p.id AND l.user_id = $1) AS liked,
         EXISTS (SELECT 1 FROM lf_saved_posts s WHERE s.post_id = p.id AND s.user_id = $1) AS saved
  FROM lf_posts p JOIN lf_users u ON u.id = p.author_id`;

const postJson = (r) => ({
  id: String(r.id),
  description: r.description,
  imageURL: r.image_url,
  isResolved: r.is_resolved,
  createdAt: r.created_at,
  author: { id: String(r.author_id), username: r.username, avatarURL: r.avatar_url },
  likeCount: r.like_count,
  liked: r.liked,
  saved: r.saved,
});

api.get("/posts", requireAuth, wrap(async (req, res) => {
  const wantsAuthor = req.query.authorId !== undefined;
  const authorId = wantsAuthor ? toId(req.query.authorId) : null;
  if (wantsAuthor && !authorId) return res.json([]);
  const r = authorId
    ? await pool.query(`${POST_SELECT} WHERE p.author_id=$2 ORDER BY p.created_at DESC LIMIT 200`, [req.userId, authorId])
    : await pool.query(`${POST_SELECT} ORDER BY p.created_at DESC LIMIT 200`, [req.userId]);
  res.json(r.rows.map(postJson));
}));

api.get("/posts/saved", requireAuth, wrap(async (req, res) => {
  const r = await pool.query(
    `${POST_SELECT} JOIN lf_saved_posts sp ON sp.post_id = p.id AND sp.user_id = $1 ORDER BY sp.saved_at DESC LIMIT 200`,
    [req.userId],
  );
  res.json(r.rows.map(postJson));
}));

async function getPost(userId, id) {
  const r = await pool.query(`${POST_SELECT} WHERE p.id=$2`, [userId, id]);
  return r.rows[0] ? postJson(r.rows[0]) : null;
}

api.post("/posts", requireAuth, wrap(async (req, res) => {
  const description = str(req.body?.description);
  const imageURL = str(req.body?.imageURL);
  if (!description || description.length > 2000) return res.status(400).json({ error: "Description is required (max 2000 characters)." });
  if (!isHttpUrl(imageURL)) return res.status(400).json({ error: "Image must be a valid http(s) link." });
  const r = await pool.query(
    "INSERT INTO lf_posts (author_id, description, image_url) VALUES ($1,$2,$3) RETURNING id",
    [req.userId, description, imageURL],
  );
  res.status(201).json(await getPost(req.userId, r.rows[0].id));
}));

api.put("/posts/:id", requireAuth, wrap(async (req, res) => {
  const id = toId(req.params.id);
  const description = str(req.body?.description);
  const imageURL = str(req.body?.imageURL);
  if (!id) return res.status(404).json({ error: "Post not found." });
  if (!description || description.length > 2000) return res.status(400).json({ error: "Description is required (max 2000 characters)." });
  if (!isHttpUrl(imageURL)) return res.status(400).json({ error: "Image must be a valid http(s) link." });
  const r = await pool.query(
    "UPDATE lf_posts SET description=$1, image_url=$2, is_resolved=$3 WHERE id=$4 AND author_id=$5 RETURNING id",
    [description, imageURL, req.body?.isResolved === true, id, req.userId],
  );
  if (!r.rowCount) return res.status(404).json({ error: "Post not found." });
  res.json(await getPost(req.userId, id));
}));

api.delete("/posts/:id", requireAuth, wrap(async (req, res) => {
  const id = toId(req.params.id);
  const r = id ? await pool.query("DELETE FROM lf_posts WHERE id=$1 AND author_id=$2", [id, req.userId]) : { rowCount: 0 };
  if (!r.rowCount) return res.status(404).json({ error: "Post not found." });
  res.json({ ok: true });
}));

// like / save toggles (idempotent)
const toggle = (table, col, insert) =>
  wrap(async (req, res) => {
    const id = toId(req.params.id);
    if (!id) return res.status(404).json({ error: "Post not found." });
    if (insert) {
      await pool.query(`INSERT INTO ${table} (post_id, user_id) SELECT $1, $2 WHERE EXISTS (SELECT 1 FROM lf_posts WHERE id=$1) ON CONFLICT DO NOTHING`, [id, req.userId]);
    } else {
      await pool.query(`DELETE FROM ${table} WHERE post_id=$1 AND user_id=$2`, [id, req.userId]);
    }
    const p = await getPost(req.userId, id);
    if (!p) return res.status(404).json({ error: "Post not found." });
    res.json(p);
  });
api.post("/posts/:id/like", requireAuth, toggle("lf_likes", "post_id", true));
api.delete("/posts/:id/like", requireAuth, toggle("lf_likes", "post_id", false));
api.post("/posts/:id/save", requireAuth, toggle("lf_saved_posts", "post_id", true));
api.delete("/posts/:id/save", requireAuth, toggle("lf_saved_posts", "post_id", false));

// ---------------- comments
api.get("/posts/:id/comments", requireAuth, wrap(async (req, res) => {
  const id = toId(req.params.id);
  const r = id
    ? await pool.query(
        `SELECT c.id, c.text, c.created_at, u.id AS author_id, u.username, u.avatar_url
         FROM lf_comments c JOIN lf_users u ON u.id = c.author_id
         WHERE c.post_id=$1 ORDER BY c.created_at DESC LIMIT 300`,
        [id],
      )
    : { rows: [] };
  res.json(
    r.rows.map((c) => ({
      id: String(c.id),
      text: c.text,
      createdAt: c.created_at,
      author: { id: String(c.author_id), username: c.username, avatarURL: c.avatar_url },
    })),
  );
}));

api.post("/posts/:id/comments", requireAuth, wrap(async (req, res) => {
  const id = toId(req.params.id);
  const text = str(req.body?.text);
  if (!id || !text || text.length > 1000) return res.status(400).json({ error: "Comment is required (max 1000 characters)." });
  const r = await pool.query(
    "INSERT INTO lf_comments (post_id, author_id, text) SELECT $1,$2,$3 WHERE EXISTS (SELECT 1 FROM lf_posts WHERE id=$1) RETURNING id",
    [id, req.userId, text],
  );
  if (!r.rowCount) return res.status(404).json({ error: "Post not found." });
  res.status(201).json({ ok: true });
}));

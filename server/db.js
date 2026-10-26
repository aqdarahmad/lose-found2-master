import pg from "pg";

const DATABASE_URL = process.env.DATABASE_URL || "";
export const dbEnabled = Boolean(DATABASE_URL);
const isLocal = /localhost|127\.0\.0\.1|\/tmp/.test(DATABASE_URL);

export const pool = dbEnabled
  ? new pg.Pool({
      connectionString: DATABASE_URL,
      ssl: isLocal ? false : { rejectUnauthorized: false },
      max: 5,
    })
  : null;

export const DEFAULT_AVATAR =
  "https://media.istockphoto.com/id/1337144146/vector/default-avatar-profile-icon-vector.jpg?s=612x612&w=0&k=20&c=BIbFwuv7FxTWvh5S3vB6bkT0Qv8Vn8N5Ffseq84ClGI=";

export async function initDb() {
  if (!pool) return;
  await pool.query(`
    CREATE TABLE IF NOT EXISTS lf_users (
      id SERIAL PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      username TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      avatar_url TEXT NOT NULL DEFAULT '${DEFAULT_AVATAR}',
      password_hash TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    CREATE TABLE IF NOT EXISTS lf_posts (
      id SERIAL PRIMARY KEY,
      author_id INT NOT NULL REFERENCES lf_users(id) ON DELETE CASCADE,
      description TEXT NOT NULL DEFAULT '',
      image_url TEXT NOT NULL DEFAULT '',
      is_resolved BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    CREATE INDEX IF NOT EXISTS lf_posts_author_idx ON lf_posts(author_id);
    CREATE INDEX IF NOT EXISTS lf_posts_created_idx ON lf_posts(created_at DESC);
    CREATE TABLE IF NOT EXISTS lf_likes (
      post_id INT NOT NULL REFERENCES lf_posts(id) ON DELETE CASCADE,
      user_id INT NOT NULL REFERENCES lf_users(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      PRIMARY KEY (post_id, user_id)
    );
    CREATE TABLE IF NOT EXISTS lf_comments (
      id SERIAL PRIMARY KEY,
      post_id INT NOT NULL REFERENCES lf_posts(id) ON DELETE CASCADE,
      author_id INT NOT NULL REFERENCES lf_users(id) ON DELETE CASCADE,
      text TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    CREATE INDEX IF NOT EXISTS lf_comments_post_idx ON lf_comments(post_id);
    CREATE TABLE IF NOT EXISTS lf_saved_posts (
      user_id INT NOT NULL REFERENCES lf_users(id) ON DELETE CASCADE,
      post_id INT NOT NULL REFERENCES lf_posts(id) ON DELETE CASCADE,
      saved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      PRIMARY KEY (user_id, post_id)
    );
  `);
}

-- Add topic description for admin-managed reviews/summaries
ALTER TABLE "topics" ADD COLUMN IF NOT EXISTS "description" TEXT NOT NULL DEFAULT '';

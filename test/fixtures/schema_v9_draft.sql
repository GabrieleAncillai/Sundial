-- Draft v9 schema from feat/product-experience.
-- Kept as a migration fixture; do not edit.

CREATE TABLE "completion_records" ("entry_id" TEXT NOT NULL REFERENCES entry_records (id), "date_key" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("entry_id", "date_key"));

CREATE TABLE "entry_records" ("id" TEXT NOT NULL, "space_id" TEXT NOT NULL REFERENCES space_records (id), "space_unit_id" TEXT NULL REFERENCES space_unit_records (id), "project_id" TEXT NULL REFERENCES project_records (id), "title" TEXT NOT NULL, "notes" TEXT NOT NULL DEFAULT '', "kind" TEXT NOT NULL, "date_key" INTEGER NULL, "end_date_key" INTEGER NULL, "start_minute" INTEGER NULL, "end_minute" INTEGER NULL, "time_zone" TEXT NULL, "start_at" INTEGER NULL, "end_at" INTEGER NULL, "all_day" INTEGER NOT NULL DEFAULT 0 CHECK ("all_day" IN (0, 1)), "status" TEXT NOT NULL, "recurrence_json" TEXT NULL, "priority" INTEGER NOT NULL DEFAULT 0, "estimated_minutes" INTEGER NULL, "sort_order" INTEGER NOT NULL DEFAULT 0, "source" TEXT NULL, "external_id" TEXT NULL, "read_only" INTEGER NOT NULL DEFAULT 0 CHECK ("read_only" IN (0, 1)), "last_completed_at" INTEGER NULL, "repeat_after_completion_days" INTEGER NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "entry_tag_records" ("entry_id" TEXT NOT NULL REFERENCES entry_records (id), "tag_id" TEXT NOT NULL REFERENCES tag_records (id), PRIMARY KEY ("entry_id", "tag_id"));

CREATE TABLE "gadget_records" ("id" TEXT NOT NULL, "space_unit_id" TEXT NOT NULL REFERENCES space_unit_records (id), "name" TEXT NOT NULL, "category" TEXT NOT NULL DEFAULT '', "icon" TEXT NOT NULL DEFAULT '', "interval_days" INTEGER NOT NULL, "last_serviced_at" INTEGER NULL, "notes" TEXT NOT NULL DEFAULT '', "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "habit_check_records" ("habit_id" TEXT NOT NULL REFERENCES habit_records (id), "date_key" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("habit_id", "date_key"));

CREATE TABLE "habit_records" ("id" TEXT NOT NULL, "space_unit_id" TEXT NULL REFERENCES space_unit_records (id), "name" TEXT NOT NULL, "icon" TEXT NOT NULL DEFAULT '', "color" INTEGER NOT NULL, "weekdays" TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7', "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "home_item_records" ("id" TEXT NOT NULL, "space_unit_id" TEXT NULL REFERENCES space_unit_records (id), "name" TEXT NOT NULL, "category" TEXT NOT NULL DEFAULT '', "location" TEXT NOT NULL DEFAULT '', "quantity" REAL NOT NULL DEFAULT 0.0, "reorder_level" REAL NULL, "unit" TEXT NOT NULL DEFAULT '', "notes" TEXT NOT NULL DEFAULT '', "last_purchased_at" INTEGER NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "home_purchase_records" ("id" TEXT NOT NULL, "home_item_id" TEXT NOT NULL REFERENCES home_item_records (id), "shopping_item_id" TEXT NULL REFERENCES shopping_item_records (id), "quantity" REAL NOT NULL, "note" TEXT NOT NULL DEFAULT '', "purchased_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "identity_records" ("id" INTEGER NOT NULL, "device_id" TEXT NOT NULL, "device_name" TEXT NOT NULL, "username" TEXT NOT NULL, "pin_salt" TEXT NOT NULL, "pin_hash" TEXT NOT NULL, "certificate_pem" TEXT NOT NULL, "private_key_pem" TEXT NOT NULL, "mcp_token" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "paired_device_records" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "username" TEXT NOT NULL, "certificate_fingerprint" TEXT NOT NULL, "shared_key" TEXT NOT NULL, "host" TEXT NOT NULL DEFAULT '', "port" INTEGER NOT NULL DEFAULT 0, "last_seen_at" INTEGER NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "project_records" ("id" TEXT NOT NULL, "space_id" TEXT NOT NULL REFERENCES space_records (id), "space_unit_id" TEXT NOT NULL REFERENCES space_unit_records (id), "name" TEXT NOT NULL, "description" TEXT NOT NULL DEFAULT '', "icon" TEXT NOT NULL DEFAULT '', "image_path" TEXT NULL, "color" INTEGER NOT NULL, "position" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "reminder_records" ("id" TEXT NOT NULL, "entry_id" TEXT NOT NULL REFERENCES entry_records (id), "offset_minutes" INTEGER NOT NULL, "time_minute" INTEGER NULL, "enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), PRIMARY KEY ("id"));

CREATE TABLE "remote_snapshot_records" ("device_id" TEXT NOT NULL, "device_name" TEXT NOT NULL, "fetched_at" INTEGER NOT NULL, "payload_json" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("device_id"));

CREATE TABLE "setting_records" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));

CREATE TABLE "shift_checklist_completion_records" ("item_id" TEXT NOT NULL REFERENCES shift_checklist_item_records (id), "date_key" INTEGER NOT NULL, "slot_key" TEXT NOT NULL DEFAULT '', "created_at" INTEGER NOT NULL, PRIMARY KEY ("item_id", "date_key", "slot_key"));

CREATE TABLE "shift_checklist_item_records" ("id" TEXT NOT NULL, "pattern_id" TEXT NOT NULL REFERENCES shift_pattern_records (id), "label" TEXT NOT NULL, "day_index" INTEGER NULL, "position" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));

CREATE TABLE "shift_exception_records" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "pattern_id" TEXT NOT NULL REFERENCES shift_pattern_records (id), "date_key" INTEGER NOT NULL, "type" TEXT NOT NULL, "start_minute" INTEGER NULL, "end_minute" INTEGER NULL, "note" TEXT NOT NULL DEFAULT '');

CREATE TABLE "shift_pattern_records" ("id" TEXT NOT NULL, "space_id" TEXT NOT NULL REFERENCES space_records (id), "space_unit_id" TEXT NULL REFERENCES space_unit_records (id), "name" TEXT NOT NULL, "time_zone" TEXT NOT NULL DEFAULT 'UTC', "cycle_days" INTEGER NOT NULL, "anchor_date_key" INTEGER NOT NULL, "commute_minutes" INTEGER NULL, "wind_down_minutes" INTEGER NULL, "enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "shift_pattern_tag_records" ("pattern_id" TEXT NOT NULL REFERENCES shift_pattern_records (id), "tag_id" TEXT NOT NULL REFERENCES tag_records (id), PRIMARY KEY ("pattern_id", "tag_id"));

CREATE TABLE "shift_slot_records" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "pattern_id" TEXT NOT NULL REFERENCES shift_pattern_records (id), "day_index" INTEGER NOT NULL, "label" TEXT NOT NULL DEFAULT '', "start_minute" INTEGER NOT NULL, "end_minute" INTEGER NOT NULL);

CREATE TABLE "shopping_item_records" ("id" TEXT NOT NULL, "space_unit_id" TEXT NULL REFERENCES space_unit_records (id), "name" TEXT NOT NULL, "quantity" REAL NOT NULL DEFAULT 1.0, "unit" TEXT NOT NULL DEFAULT '', "checked" INTEGER NOT NULL DEFAULT 0 CHECK ("checked" IN (0, 1)), "note" TEXT NOT NULL DEFAULT '', "home_item_id" TEXT NULL REFERENCES home_item_records (id), "position" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "space_records" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "color" INTEGER NOT NULL, "position" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "space_unit_records" ("id" TEXT NOT NULL, "space_id" TEXT NOT NULL REFERENCES space_records (id), "name" TEXT NOT NULL, "kind" TEXT NOT NULL, "icon" TEXT NOT NULL DEFAULT '', "image_path" TEXT NULL, "color" INTEGER NOT NULL, "position" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "tag_records" ("id" TEXT NOT NULL, "space_id" TEXT NULL REFERENCES space_records (id), "name" TEXT NOT NULL, "color" INTEGER NOT NULL, "icon" TEXT NOT NULL DEFAULT '', "position" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "task_session_records" ("id" TEXT NOT NULL, "entry_id" TEXT NOT NULL REFERENCES entry_records (id), "started_at" INTEGER NOT NULL, "ended_at" INTEGER NULL, "note" TEXT NOT NULL DEFAULT '', "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

PRAGMA user_version = 9;

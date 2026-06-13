CREATE TABLE IF NOT EXISTS "activity_types"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "name" varchar not null,
  "is_negative" boolean,
  "theme" varchar not null,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer
);

CREATE TABLE IF NOT EXISTS "activities"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "name" varchar not null,
  "activity_type_id" text not null,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  foreign key("activity_type_id") references "activity_types"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "activity_on_day"(
  "activity_id" text not null,
  "date" date not null,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  primary key("activity_id", "date"),
  foreign key("activity_id") references "activities"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "project_categories"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "name" varchar not null,
  "color_scheme" varchar not null,
  "order" integer,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer
);

CREATE TABLE IF NOT EXISTS "projects"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "name" varchar not null,
  "description" text,
  "project_category_id" text,
  "order" integer,
  "active" boolean not null,
  "completed_at" integer,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  foreign key("project_category_id") references "project_categories"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "general_projects"(
  "project_id" text primary key not null,
  "project_category_id" text not null,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  foreign key("project_category_id") references "project_categories"("id") on delete cascade,
  foreign key("project_id") references "projects"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "objectives"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "name" varchar not null,
  "description" text,
  "project_id" text,
  "order" integer,
  "completed_at" integer,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  foreign key("project_id") references "projects"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "tasks"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "name" varchar not null,
  "description" text,
  "completed_at" integer,
  "objective_id" text,
  "order" integer,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  foreign key("objective_id") references "objectives"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "people"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "firstname" varchar not null,
  "lastname" varchar,
  "dob" date,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer
);

CREATE TABLE IF NOT EXISTS "people_groups"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "name" varchar not null,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer
);

CREATE TABLE IF NOT EXISTS "person_in_group"(
  "person_id" text not null,
  "people_group_id" text not null,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  primary key("person_id", "people_group_id"),
  foreign key("person_id") references "people"("id") on delete cascade,
  foreign key("people_group_id") references "people_groups"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "events"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "project_id" text,
  "name" varchar not null,
  "start_datetime" datetime not null,
  "end_datetime" datetime not null,
  "after_notes" text,
  "before_notes" text,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  foreign key("project_id") references "projects"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "person_at_event"(
  "person_id" text not null,
  "event_id" text not null,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  primary key("person_id", "event_id"),
  foreign key("person_id") references "people"("id") on delete cascade,
  foreign key("event_id") references "events"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "project_on_day"(
  "project_id" text not null,
  "date" date not null,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  primary key("project_id", "date"),
  foreign key("project_id") references "projects"("id") on delete cascade
);

CREATE TABLE IF NOT EXISTS "to_do_list_project"(
  "id" text primary key not null default (lower(hex(randomblob(16)))),
  "to_do_list_project_id" text,
  "created_at" integer default (unixepoch()),
  "updated_at" integer default (unixepoch()),
  "deleted_at" integer,
  foreign key("to_do_list_project_id") references "projects"("id") on delete cascade
);

-- Triggers: set updated_at = now() on UPDATE, but only when the caller did not
-- explicitly change updated_at (WHEN condition). This lets the sync engine's
-- LWW upserts (which always set updated_at to the incoming timestamp) pass
-- through untouched while plain user UPDATEs get a fresh timestamp automatically.

CREATE TRIGGER IF NOT EXISTS "activity_types_updated_at"
AFTER UPDATE ON "activity_types" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "activity_types" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "activities_updated_at"
AFTER UPDATE ON "activities" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "activities" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "activity_on_day_updated_at"
AFTER UPDATE ON "activity_on_day" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "activity_on_day" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "project_categories_updated_at"
AFTER UPDATE ON "project_categories" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "project_categories" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "projects_updated_at"
AFTER UPDATE ON "projects" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "projects" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "general_projects_updated_at"
AFTER UPDATE ON "general_projects" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "general_projects" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "objectives_updated_at"
AFTER UPDATE ON "objectives" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "objectives" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "tasks_updated_at"
AFTER UPDATE ON "tasks" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "tasks" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "people_updated_at"
AFTER UPDATE ON "people" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "people" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "people_groups_updated_at"
AFTER UPDATE ON "people_groups" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "people_groups" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "person_in_group_updated_at"
AFTER UPDATE ON "person_in_group" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "person_in_group" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "events_updated_at"
AFTER UPDATE ON "events" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "events" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "person_at_event_updated_at"
AFTER UPDATE ON "person_at_event" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "person_at_event" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "project_on_day_updated_at"
AFTER UPDATE ON "project_on_day" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "project_on_day" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

CREATE TRIGGER IF NOT EXISTS "to_do_list_project_updated_at"
AFTER UPDATE ON "to_do_list_project" FOR EACH ROW
WHEN NEW."updated_at" = OLD."updated_at"
BEGIN
  UPDATE "to_do_list_project" SET "updated_at" = unixepoch() WHERE rowid = NEW.rowid;
END;

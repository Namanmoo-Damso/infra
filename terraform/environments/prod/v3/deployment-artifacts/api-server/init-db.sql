-- ============================================================================
-- PostgreSQL initialization script for ops-api
-- ============================================================================
-- This script automatically runs when the DB container starts fresh.
-- It includes:
-- 1. pg_trgm extension for text similarity search
-- 2. Complete database schema from all Prisma migrations
-- 3. All tables, indexes, and foreign key constraints
-- ============================================================================

-- Enable required PostgreSQL extensions
-- 현재 사용중인 확장 프로그램 설치
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector;

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- ============================================================================
-- TABLES
-- ============================================================================

-- CreateTable: users
CREATE TABLE "users" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "identity" TEXT NOT NULL,
    "display_name" TEXT,
    "user_type" TEXT,
    "email" TEXT,
    "nickname" TEXT,
    "profile_image_url" TEXT,
    "kakao_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable: devices
CREATE TABLE "devices" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID,
    "platform" TEXT NOT NULL,
    "apns_token" TEXT,
    "voip_token" TEXT,
    "supports_callkit" BOOLEAN NOT NULL DEFAULT true,
    "env" TEXT NOT NULL DEFAULT 'prod',
    "last_seen" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "devices_pkey" PRIMARY KEY ("id")
);

-- CreateTable: organizations
CREATE TABLE "organizations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organizations_pkey" PRIMARY KEY ("id")
);

-- CreateTable: guardians
CREATE TABLE "guardians" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "guardians_pkey" PRIMARY KEY ("id")
);

-- CreateTable: wards
CREATE TABLE "wards" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "phone_number" TEXT NOT NULL,
    "guardian_id" UUID,
    "organization_id" UUID,
    "ai_persona" TEXT DEFAULT '다미',
    "weekly_call_count" INTEGER NOT NULL DEFAULT 3,
    "call_duration_minutes" INTEGER NOT NULL DEFAULT 15,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "wards_pkey" PRIMARY KEY ("id")
);

-- CreateTable: rooms
CREATE TABLE "rooms" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "room_name" TEXT NOT NULL,
    "meta" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rooms_pkey" PRIMARY KEY ("id")
);

-- CreateEnum: IndexingStatus (RAG 인덱싱 상태)
CREATE TYPE "IndexingStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');

-- CreateTable: calls
CREATE TABLE "calls" (
    "call_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "caller_user_id" UUID,
    "callee_user_id" UUID,
    "caller_identity" TEXT NOT NULL,
    "callee_identity" TEXT NOT NULL,
    "room_name" TEXT NOT NULL,
    "state" TEXT NOT NULL DEFAULT 'ringing',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "answered_at" TIMESTAMP(3),
    "ended_at" TIMESTAMP(3),
    -- RAG 인덱싱 관련 필드
    "indexing_status" "IndexingStatus" NOT NULL DEFAULT 'PENDING',
    "indexing_error" VARCHAR(4000),
    "indexing_attempts" INTEGER NOT NULL DEFAULT 0,
    "indexed_at" TIMESTAMP(3),

    CONSTRAINT "calls_pkey" PRIMARY KEY ("call_id")
);

-- CreateTable: room_members
CREATE TABLE "room_members" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "room_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'viewer',
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "room_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable: call_summaries (ward_id nullable per migration 20260106142439)
CREATE TABLE "call_summaries" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "call_id" UUID NOT NULL,
    "ward_id" UUID,
    "summary" TEXT,
    "mood" TEXT,
    "mood_score" DECIMAL(3,2),
    "tags" TEXT[],
    "health_keywords" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "call_summaries_pkey" PRIMARY KEY ("id")
);

-- CreateTable: health_alerts
CREATE TABLE "health_alerts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "ward_id" UUID NOT NULL,
    "guardian_id" UUID NOT NULL,
    "alert_type" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "health_alerts_pkey" PRIMARY KEY ("id")
);

-- CreateTable: notification_settings
CREATE TABLE "notification_settings" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "call_reminder" BOOLEAN NOT NULL DEFAULT true,
    "call_complete" BOOLEAN NOT NULL DEFAULT true,
    "health_alert" BOOLEAN NOT NULL DEFAULT true,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable: refresh_tokens
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable: guardian_ward_registrations
CREATE TABLE "guardian_ward_registrations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "guardian_id" UUID NOT NULL,
    "ward_email" TEXT NOT NULL,
    "ward_phone_number" TEXT NOT NULL,
    "linked_ward_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Ward Basic Info
    "ward_name" TEXT,
    "relation" TEXT,
    "birth_date" TEXT,
    "gender" TEXT,
    "address" TEXT,
    -- AI Care Info
    "medical_conditions" TEXT,
    "medications" TEXT,

    CONSTRAINT "guardian_ward_registrations_pkey" PRIMARY KEY ("id")
);

-- CreateTable: call_schedules
CREATE TABLE "call_schedules" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "ward_id" UUID NOT NULL,
    "day_of_week" INTEGER NOT NULL,
    "scheduled_time" TIME NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_called_at" TIMESTAMP(3),
    "reminder_sent_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "call_schedules_pkey" PRIMARY KEY ("id")
);

-- CreateTable: call_slot_configs (전역 슬롯 설정)
CREATE TABLE "call_slot_configs" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "slot_duration_minutes" INTEGER NOT NULL DEFAULT 10,
    "max_call_duration_minutes" INTEGER NOT NULL DEFAULT 8,
    "max_capacity_per_slot" INTEGER NOT NULL DEFAULT 40,
    "max_concurrent_calls" INTEGER NOT NULL DEFAULT 50,
    "valid_minutes" INTEGER[] NOT NULL DEFAULT ARRAY[0, 10, 20, 30, 40, 50],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "call_slot_configs_pkey" PRIMARY KEY ("id")
);

-- CreateTable: call_schedule_groups (슬롯 기반 스케줄)
CREATE TABLE "call_schedule_groups" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "registration_id" UUID,
    "ward_id" UUID,
    "slot_start_hour" INTEGER NOT NULL,
    "slot_start_minute" INTEGER NOT NULL,
    "weekdays" INTEGER[],
    "is_enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "call_schedule_groups_pkey" PRIMARY KEY ("id")
);

-- [Migration Reference] If you need to migrate existing data from the removed organization_ward_details table:
-- INSERT INTO "organization_wards" (id, diseases, medication, emergency_contact, notes)
-- SELECT organization_ward_id, diseases, medication, guardian, notes
-- FROM "organization_ward_details"
-- ON CONFLICT (id) DO UPDATE SET
--   diseases = EXCLUDED.diseases,
--   medication = EXCLUDED.medication,
--   emergency_contact = EXCLUDED.emergency_contact,
--   notes = EXCLUDED.notes;

-- CreateTable: organization_wards (consolidated - includes fields from organization_ward_details)
CREATE TABLE "organization_wards" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "uploaded_by_admin_id" UUID,
    "email" TEXT NOT NULL,
    "phone_number" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "birth_date" DATE,
    "address" TEXT,
    "gender" TEXT,
    "ward_type" TEXT,
    -- Merged from organization_ward_details
    "emergency_contact" TEXT,
    "diseases" TEXT[] NOT NULL DEFAULT ARRAY[]::text[],
    "medication" TEXT,
    "notes" TEXT,
    -- Status fields
    "is_registered" BOOLEAN NOT NULL DEFAULT false,
    "ward_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organization_wards_pkey" PRIMARY KEY ("id")
);

-- CreateTable: ward_locations
CREATE TABLE "ward_locations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "ward_id" UUID NOT NULL,
    "latitude" DECIMAL(10,8) NOT NULL,
    "longitude" DECIMAL(11,8) NOT NULL,
    "accuracy" DECIMAL(6,2),
    "recorded_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ward_locations_pkey" PRIMARY KEY ("id")
);

-- CreateTable: ward_current_locations
CREATE TABLE "ward_current_locations" (
    "ward_id" UUID NOT NULL,
    "latitude" DECIMAL(10,8) NOT NULL,
    "longitude" DECIMAL(11,8) NOT NULL,
    "accuracy" DECIMAL(6,2),
    "status" TEXT NOT NULL DEFAULT 'normal',
    "last_updated" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ward_current_locations_pkey" PRIMARY KEY ("ward_id")
);

-- CreateTable: emergency_agencies
CREATE TABLE "emergency_agencies" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "phone_number" TEXT NOT NULL,
    "latitude" DECIMAL(10,8) NOT NULL,
    "longitude" DECIMAL(11,8) NOT NULL,
    "address" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "emergency_agencies_pkey" PRIMARY KEY ("id")
);

-- CreateTable: emergencies
CREATE TABLE "emergencies" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "ward_id" UUID,
    "type" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "latitude" DECIMAL(10,8),
    "longitude" DECIMAL(11,8),
    "message" TEXT,
    "guardian_notified" BOOLEAN NOT NULL DEFAULT false,
    "resolved_at" TIMESTAMP(3),
    "resolved_by" UUID,
    "resolution_note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "emergencies_pkey" PRIMARY KEY ("id")
);

-- CreateTable: emergency_contacts
CREATE TABLE "emergency_contacts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "emergency_id" UUID NOT NULL,
    "agency_id" UUID,
    "distance_km" DECIMAL(6,2),
    "contacted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "response_status" TEXT NOT NULL DEFAULT 'pending',

    CONSTRAINT "emergency_contacts_pkey" PRIMARY KEY ("id")
);

-- CreateTable: admins
CREATE TABLE "admins" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" TEXT NOT NULL,
    "name" TEXT,
    "provider" TEXT NOT NULL,
    "provider_id" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'viewer',
    "organization_id" UUID,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Staff scheduling fields
    "team" TEXT,
    "job_title" TEXT,
    "phone_number" TEXT,
    "max_capacity" INTEGER NOT NULL DEFAULT 20,

    CONSTRAINT "admins_pkey" PRIMARY KEY ("id")
);

-- CreateTable: admin_permissions
CREATE TABLE "admin_permissions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "admin_id" UUID NOT NULL,
    "permission" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "admin_permissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable: admin_refresh_tokens
CREATE TABLE "admin_refresh_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "admin_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "admin_refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable: transcripts (from migration 20260102141924)
CREATE TABLE "transcripts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "call_id" UUID NOT NULL,
    "room_name" TEXT NOT NULL,
    "speaker_id" TEXT NOT NULL,
    "speaker_type" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "audio_features" JSONB,

    CONSTRAINT "transcripts_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "transcripts_speaker_type_check" CHECK ("speaker_type" IN ('user', 'agent')),
    CONSTRAINT "transcripts_text_not_empty_check" CHECK (LENGTH(TRIM("text")) > 0)
);

-- CreateTable: conversation_vectors_parent (RAG Parent storage - full context + dense summary)
CREATE TABLE "conversation_vectors_parent" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "ward_id" UUID NOT NULL,
    "call_id" UUID NOT NULL,
    "parent_text" TEXT NOT NULL,                   -- 원본 대화 또는 기존 요약본
    "summary_text" TEXT,                           -- LLM이 생성한 고밀도 상세 요약본 (Dense Summary)
    "metadata" JSONB,                              -- { speakers, topics, keywords, sentiment, indexVersion, etc. }
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "conversation_vectors_parent_pkey" PRIMARY KEY ("id")
);

-- CreateTable: conversation_vectors_child (RAG Child storage - searchable chunks with contextual headers)
CREATE TABLE "conversation_vectors_child" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "parent_id" UUID NOT NULL,
    "ward_id" UUID NOT NULL,
    "call_id" UUID NOT NULL,
    "child_text" TEXT NOT NULL,                    -- 헤더가 포함된 검색용 청크 (header + content)
    "chunk_header" TEXT,                           -- 문맥 헤더 [날짜 | 주제 | 키워드] 형식
    "embedding" vector(1024),                      -- Bedrock Titan V2 (1024 dimensions)
    "offset_start" INTEGER NOT NULL,
    "offset_end" INTEGER NOT NULL,
    "metadata" JSONB,                              -- { chunkIndex, header, contentLength, keywords, etc. }
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Full-Text Search: Generated Column for hybrid search (Vector + FTS)
    -- chunk_header gets weight 'A' (highest priority for dates/relations)
    -- child_text gets weight 'C' (normal content)
    "fts_tokens" tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', COALESCE("chunk_header", '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE("child_text", '')), 'C')
    ) STORED,

    CONSTRAINT "conversation_vectors_child_pkey" PRIMARY KEY ("id")
);

-- CreateTable: care_alert_events (케어 알림 이벤트 로그)
CREATE TABLE "care_alert_events" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "ward_id" UUID NOT NULL,
    "alert_type" TEXT NOT NULL,
    "severity" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "raw_payload" JSONB NOT NULL,
    "acknowledged" BOOLEAN NOT NULL DEFAULT false,
    "acknowledged_at" TIMESTAMP(3),
    "acknowledged_by" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Agent 연동 필드
    "call_id" UUID,
    "room_name" TEXT,
    "agent_response" TEXT,
    "source" TEXT NOT NULL DEFAULT 'ios',

    CONSTRAINT "care_alert_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable: emotion_summaries (감정 10분 집계)
CREATE TABLE "emotion_summaries" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "ward_id" UUID NOT NULL,
    "period_start" TIMESTAMPTZ NOT NULL,
    "period_end" TIMESTAMPTZ NOT NULL,
    "total_samples" INTEGER NOT NULL,
    "emotion_distribution" JSONB NOT NULL,
    "average_confidence" DECIMAL(4, 3) NOT NULL,
    "negative_ratio" DECIMAL(4, 3) NOT NULL,
    "dominant_emotion" VARCHAR(20) NOT NULL,
    "created_at" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "emotion_summaries_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "emotion_summaries_ward_id_period_start_key" UNIQUE ("ward_id", "period_start")
);

-- CreateTable: staff (직원 - 단순 배정용, 인증 없음)
CREATE TABLE "staff" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "phone_number" TEXT,
    "team" TEXT,
    "job_title" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_pkey" PRIMARY KEY ("id")
);

-- CreateTable: ward_assignments (직원-대상자 배정)
CREATE TABLE "ward_assignments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "staff_id" UUID NOT NULL,
    "organization_ward_id" UUID NOT NULL,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ward_assignments_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "ward_assignments_staff_id_organization_ward_id_key" UNIQUE ("staff_id", "organization_ward_id")
);

-- CreateTable: organization_settings (기관 설정)
CREATE TABLE "organization_settings" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "preferred_start_time" TEXT NOT NULL DEFAULT '09:00',
    "preferred_end_time" TEXT NOT NULL DEFAULT '18:00',
    "max_retries" INTEGER NOT NULL DEFAULT 3,
    "retry_interval" INTEGER NOT NULL DEFAULT 30,
    "risk_sensitivity" INTEGER NOT NULL DEFAULT 2,
    "health_check" BOOLEAN NOT NULL DEFAULT true,
    "meal_check" BOOLEAN NOT NULL DEFAULT true,
    "medication_check" BOOLEAN NOT NULL DEFAULT true,
    "sleep_check" BOOLEAN NOT NULL DEFAULT false,
    "mood_check" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organization_settings_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "organization_settings_organization_id_key" UNIQUE ("organization_id")
);

-- CreateTable: bulletins (공지사항)
CREATE TABLE "bulletins" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "author_id" UUID NOT NULL,
    "is_pinned" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bulletins_pkey" PRIMARY KEY ("id")
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Users indexes
CREATE UNIQUE INDEX "users_identity_key" ON "users"("identity");
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
CREATE UNIQUE INDEX "users_kakao_id_key" ON "users"("kakao_id");
CREATE INDEX "users_email_idx" ON "users"("email");
CREATE INDEX "users_kakao_id_idx" ON "users"("kakao_id");
CREATE INDEX "users_user_type_idx" ON "users"("user_type");

-- Devices indexes
CREATE UNIQUE INDEX "devices_apns_token_key" ON "devices"("apns_token");
CREATE UNIQUE INDEX "devices_voip_token_key" ON "devices"("voip_token");
CREATE INDEX "devices_user_id_idx" ON "devices"("user_id");
CREATE INDEX "devices_env_idx" ON "devices"("env");

-- Guardians indexes
CREATE UNIQUE INDEX "guardians_user_id_key" ON "guardians"("user_id");
CREATE INDEX "guardians_user_id_idx" ON "guardians"("user_id");

-- Wards indexes
CREATE UNIQUE INDEX "wards_user_id_key" ON "wards"("user_id");
CREATE INDEX "wards_user_id_idx" ON "wards"("user_id");
CREATE INDEX "wards_guardian_id_idx" ON "wards"("guardian_id");
CREATE INDEX "wards_organization_id_idx" ON "wards"("organization_id");

-- Rooms indexes
CREATE UNIQUE INDEX "rooms_room_name_key" ON "rooms"("room_name");

-- Calls indexes
CREATE INDEX "calls_callee_identity_state_idx" ON "calls"("callee_identity", "state");
CREATE INDEX "calls_room_name_idx" ON "calls"("room_name");
CREATE INDEX "calls_indexing_status_idx" ON "calls"("indexing_status");

-- Room members indexes
CREATE INDEX "room_members_room_id_idx" ON "room_members"("room_id");
CREATE UNIQUE INDEX "room_members_room_id_user_id_key" ON "room_members"("room_id", "user_id");

-- Call summaries indexes
CREATE INDEX "call_summaries_call_id_idx" ON "call_summaries"("call_id");
CREATE INDEX "call_summaries_ward_id_idx" ON "call_summaries"("ward_id");
CREATE INDEX "call_summaries_created_at_idx" ON "call_summaries"("created_at");

-- Health alerts indexes
CREATE INDEX "health_alerts_guardian_id_idx" ON "health_alerts"("guardian_id");
CREATE INDEX "health_alerts_ward_id_idx" ON "health_alerts"("ward_id");
CREATE INDEX "health_alerts_is_read_idx" ON "health_alerts"("is_read");

-- Notification settings indexes
CREATE UNIQUE INDEX "notification_settings_user_id_key" ON "notification_settings"("user_id");
CREATE INDEX "notification_settings_user_id_idx" ON "notification_settings"("user_id");

-- Refresh tokens indexes
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");
CREATE INDEX "refresh_tokens_expires_at_idx" ON "refresh_tokens"("expires_at");
CREATE INDEX "refresh_tokens_token_hash_idx" ON "refresh_tokens"("token_hash");

-- Guardian ward registrations indexes
CREATE INDEX "guardian_ward_registrations_guardian_id_idx" ON "guardian_ward_registrations"("guardian_id");
CREATE INDEX "guardian_ward_registrations_ward_email_idx" ON "guardian_ward_registrations"("ward_email");
CREATE INDEX "guardian_ward_registrations_linked_ward_id_idx" ON "guardian_ward_registrations"("linked_ward_id");

-- Call schedules indexes
CREATE INDEX "call_schedules_ward_id_idx" ON "call_schedules"("ward_id");
CREATE INDEX "call_schedules_day_of_week_idx" ON "call_schedules"("day_of_week");
CREATE INDEX "call_schedules_is_active_idx" ON "call_schedules"("is_active");

-- Call schedule groups indexes
CREATE INDEX "call_schedule_groups_registration_id_idx" ON "call_schedule_groups"("registration_id");
CREATE INDEX "call_schedule_groups_ward_id_idx" ON "call_schedule_groups"("ward_id");
CREATE INDEX "call_schedule_groups_is_enabled_idx" ON "call_schedule_groups"("is_enabled");
CREATE INDEX "call_schedule_groups_slot_start_hour_slot_start_minute_idx" ON "call_schedule_groups"("slot_start_hour", "slot_start_minute");
CREATE UNIQUE INDEX "call_schedule_groups_ward_id_slot_start_hour_slot_start_minut_key" ON "call_schedule_groups"("ward_id", "slot_start_hour", "slot_start_minute");

-- Organization wards indexes
CREATE INDEX "organization_wards_organization_id_idx" ON "organization_wards"("organization_id");
CREATE INDEX "organization_wards_email_idx" ON "organization_wards"("email");
CREATE INDEX "organization_wards_is_registered_idx" ON "organization_wards"("is_registered");
CREATE INDEX "organization_wards_uploaded_by_admin_id_idx" ON "organization_wards"("uploaded_by_admin_id");
CREATE INDEX "organization_wards_organization_id_is_registered_ward_id_idx" ON "organization_wards"("organization_id", "is_registered", "ward_id");
CREATE UNIQUE INDEX "organization_wards_organization_id_email_key" ON "organization_wards"("organization_id", "email");

-- Organization wards GIN indexes for text search (requires pg_trgm extension)
CREATE INDEX "organization_wards_name_trgm_idx" ON "organization_wards" USING GIN ("name" gin_trgm_ops);
CREATE INDEX "organization_wards_address_trgm_idx" ON "organization_wards" USING GIN ("address" gin_trgm_ops);
CREATE INDEX "organization_wards_email_trgm_idx" ON "organization_wards" USING GIN ("email" gin_trgm_ops);
CREATE INDEX "organization_wards_phone_trgm_idx" ON "organization_wards" USING GIN ("phone_number" gin_trgm_ops);

-- Ward locations indexes
CREATE INDEX "ward_locations_ward_id_idx" ON "ward_locations"("ward_id");
CREATE INDEX "ward_locations_recorded_at_idx" ON "ward_locations"("recorded_at");
CREATE INDEX "ward_locations_ward_id_recorded_at_idx" ON "ward_locations"("ward_id", "recorded_at" DESC);

-- Ward current locations indexes
CREATE INDEX "ward_current_locations_status_idx" ON "ward_current_locations"("status");

-- Emergency agencies indexes
CREATE INDEX "emergency_agencies_type_idx" ON "emergency_agencies"("type");
CREATE INDEX "emergency_agencies_is_active_idx" ON "emergency_agencies"("is_active");

-- Emergencies indexes
CREATE INDEX "emergencies_ward_id_idx" ON "emergencies"("ward_id");
CREATE INDEX "emergencies_status_idx" ON "emergencies"("status");
CREATE INDEX "emergencies_created_at_idx" ON "emergencies"("created_at" DESC);

-- Emergency contacts indexes
CREATE INDEX "emergency_contacts_emergency_id_idx" ON "emergency_contacts"("emergency_id");
CREATE INDEX "emergency_contacts_agency_id_idx" ON "emergency_contacts"("agency_id");

-- Admins indexes
CREATE UNIQUE INDEX "admins_email_key" ON "admins"("email");
CREATE INDEX "admins_email_idx" ON "admins"("email");
CREATE INDEX "admins_provider_provider_id_idx" ON "admins"("provider", "provider_id");
CREATE INDEX "admins_role_idx" ON "admins"("role");
CREATE INDEX "admins_organization_id_idx" ON "admins"("organization_id");
CREATE UNIQUE INDEX "admins_provider_provider_id_key" ON "admins"("provider", "provider_id");

-- Admin permissions indexes
CREATE INDEX "admin_permissions_admin_id_idx" ON "admin_permissions"("admin_id");
CREATE UNIQUE INDEX "admin_permissions_admin_id_permission_key" ON "admin_permissions"("admin_id", "permission");

-- Admin refresh tokens indexes
CREATE UNIQUE INDEX "admin_refresh_tokens_token_hash_key" ON "admin_refresh_tokens"("token_hash");
CREATE INDEX "admin_refresh_tokens_admin_id_idx" ON "admin_refresh_tokens"("admin_id");
CREATE INDEX "admin_refresh_tokens_token_hash_idx" ON "admin_refresh_tokens"("token_hash");

-- Transcripts indexes
CREATE INDEX "transcripts_call_id_idx" ON "transcripts"("call_id");
CREATE INDEX "transcripts_room_name_idx" ON "transcripts"("room_name");
CREATE INDEX "transcripts_timestamp_idx" ON "transcripts"("timestamp");
CREATE INDEX "transcripts_speaker_id_speaker_type_idx" ON "transcripts"("speaker_id", "speaker_type");

-- Conversation vectors parent indexes (RAG)
CREATE INDEX "conversation_vectors_parent_ward_id_idx" ON "conversation_vectors_parent"("ward_id");
CREATE INDEX "conversation_vectors_parent_call_id_idx" ON "conversation_vectors_parent"("call_id");
CREATE INDEX "conversation_vectors_parent_created_at_idx" ON "conversation_vectors_parent"("created_at");
CREATE INDEX "conversation_vectors_parent_ward_id_created_at_idx" ON "conversation_vectors_parent"("ward_id", "created_at" DESC);

-- Conversation vectors child indexes (RAG)
CREATE INDEX "conversation_vectors_child_parent_id_idx" ON "conversation_vectors_child"("parent_id");
CREATE INDEX "conversation_vectors_child_ward_id_idx" ON "conversation_vectors_child"("ward_id");
CREATE INDEX "conversation_vectors_child_call_id_idx" ON "conversation_vectors_child"("call_id");
CREATE INDEX "conversation_vectors_child_created_at_idx" ON "conversation_vectors_child"("created_at");
CREATE INDEX "conversation_vectors_child_ward_id_created_at_idx" ON "conversation_vectors_child"("ward_id", "created_at" DESC);
-- HNSW index for fast vector similarity search (m=16, ef_construction=64)
CREATE INDEX "conversation_vectors_child_embedding_idx" ON "conversation_vectors_child" USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);
-- GIN index for Full-Text Search (hybrid search support)
CREATE INDEX "conversation_vectors_child_fts_tokens_idx" ON "conversation_vectors_child" USING GIN ("fts_tokens");

-- Care alert events indexes
CREATE INDEX "care_alert_events_ward_id_timestamp_idx" ON "care_alert_events"("ward_id", "timestamp" DESC);
CREATE INDEX "care_alert_events_alert_type_idx" ON "care_alert_events"("alert_type");
CREATE INDEX "care_alert_events_severity_idx" ON "care_alert_events"("severity");
CREATE INDEX "care_alert_events_acknowledged_idx" ON "care_alert_events"("acknowledged");
CREATE INDEX "care_alert_events_ward_id_alert_type_timestamp_idx" ON "care_alert_events"("ward_id", "alert_type", "timestamp");
CREATE INDEX "care_alert_events_call_id_idx" ON "care_alert_events"("call_id");

-- Emotion summaries indexes
CREATE INDEX "emotion_summaries_ward_id_period_start_idx" ON "emotion_summaries"("ward_id", "period_start" DESC);

-- Staff indexes
CREATE INDEX "staff_organization_id_idx" ON "staff"("organization_id");
CREATE INDEX "staff_organization_id_is_active_idx" ON "staff"("organization_id", "is_active");

-- Ward assignments indexes
CREATE INDEX "ward_assignments_staff_id_idx" ON "ward_assignments"("staff_id");
CREATE INDEX "ward_assignments_organization_ward_id_idx" ON "ward_assignments"("organization_ward_id");
CREATE INDEX "ward_assignments_staff_id_is_active_idx" ON "ward_assignments"("staff_id", "is_active");

-- ============================================================================
-- FOREIGN KEYS
-- ============================================================================

ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "guardians" ADD CONSTRAINT "guardians_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "wards" ADD CONSTRAINT "wards_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "wards" ADD CONSTRAINT "wards_guardian_id_fkey" FOREIGN KEY ("guardian_id") REFERENCES "guardians"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "wards" ADD CONSTRAINT "wards_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "calls" ADD CONSTRAINT "calls_caller_user_id_fkey" FOREIGN KEY ("caller_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "calls" ADD CONSTRAINT "calls_callee_user_id_fkey" FOREIGN KEY ("callee_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "room_members" ADD CONSTRAINT "room_members_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "rooms"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "room_members" ADD CONSTRAINT "room_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "call_summaries" ADD CONSTRAINT "call_summaries_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "calls"("call_id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "call_summaries" ADD CONSTRAINT "call_summaries_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "health_alerts" ADD CONSTRAINT "health_alerts_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "health_alerts" ADD CONSTRAINT "health_alerts_guardian_id_fkey" FOREIGN KEY ("guardian_id") REFERENCES "guardians"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "notification_settings" ADD CONSTRAINT "notification_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "guardian_ward_registrations" ADD CONSTRAINT "guardian_ward_registrations_guardian_id_fkey" FOREIGN KEY ("guardian_id") REFERENCES "guardians"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "guardian_ward_registrations" ADD CONSTRAINT "guardian_ward_registrations_linked_ward_id_fkey" FOREIGN KEY ("linked_ward_id") REFERENCES "wards"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "call_schedules" ADD CONSTRAINT "call_schedules_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "call_schedule_groups" ADD CONSTRAINT "call_schedule_groups_registration_id_fkey" FOREIGN KEY ("registration_id") REFERENCES "guardian_ward_registrations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "call_schedule_groups" ADD CONSTRAINT "call_schedule_groups_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "organization_wards" ADD CONSTRAINT "organization_wards_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "organization_wards" ADD CONSTRAINT "organization_wards_uploaded_by_admin_id_fkey" FOREIGN KEY ("uploaded_by_admin_id") REFERENCES "admins"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "organization_wards" ADD CONSTRAINT "organization_wards_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "ward_locations" ADD CONSTRAINT "ward_locations_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ward_current_locations" ADD CONSTRAINT "ward_current_locations_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "emergencies" ADD CONSTRAINT "emergencies_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "emergencies" ADD CONSTRAINT "emergencies_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "emergency_contacts" ADD CONSTRAINT "emergency_contacts_emergency_id_fkey" FOREIGN KEY ("emergency_id") REFERENCES "emergencies"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "emergency_contacts" ADD CONSTRAINT "emergency_contacts_agency_id_fkey" FOREIGN KEY ("agency_id") REFERENCES "emergency_agencies"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "admins" ADD CONSTRAINT "admins_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "admin_permissions" ADD CONSTRAINT "admin_permissions_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "admins"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "admin_refresh_tokens" ADD CONSTRAINT "admin_refresh_tokens_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "admins"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "transcripts" ADD CONSTRAINT "transcripts_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "calls"("call_id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "conversation_vectors_parent" ADD CONSTRAINT "conversation_vectors_parent_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "conversation_vectors_parent" ADD CONSTRAINT "conversation_vectors_parent_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "calls"("call_id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "conversation_vectors_child" ADD CONSTRAINT "conversation_vectors_child_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "conversation_vectors_parent"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "conversation_vectors_child" ADD CONSTRAINT "conversation_vectors_child_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "conversation_vectors_child" ADD CONSTRAINT "conversation_vectors_child_call_id_fkey" FOREIGN KEY ("call_id") REFERENCES "calls"("call_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Care alert events foreign keys
ALTER TABLE "care_alert_events" ADD CONSTRAINT "care_alert_events_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Emotion summaries foreign keys
ALTER TABLE "emotion_summaries" ADD CONSTRAINT "emotion_summaries_ward_id_fkey" FOREIGN KEY ("ward_id") REFERENCES "wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Staff foreign keys
ALTER TABLE "staff" ADD CONSTRAINT "staff_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Ward assignments foreign keys
ALTER TABLE "ward_assignments" ADD CONSTRAINT "ward_assignments_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "staff"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ward_assignments" ADD CONSTRAINT "ward_assignments_organization_ward_id_fkey" FOREIGN KEY ("organization_ward_id") REFERENCES "organization_wards"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Organization settings foreign keys
ALTER TABLE "organization_settings" ADD CONSTRAINT "organization_settings_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Bulletins indexes
CREATE INDEX "bulletins_organization_id_idx" ON "bulletins"("organization_id");
CREATE INDEX "bulletins_created_at_idx" ON "bulletins"("created_at" DESC);

-- Bulletins foreign keys
ALTER TABLE "bulletins" ADD CONSTRAINT "bulletins_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "bulletins" ADD CONSTRAINT "bulletins_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "admins"("id") ON DELETE CASCADE ON UPDATE CASCADE;

create extension if not exists "wrappers" with schema "extensions";

drop extension if exists "pg_net";

drop trigger if exists "canonical_verticals_read_only" on "public"."canonical_verticals";
DROP POLICY IF EXISTS "canonical_verticals_read_authenticated_v1" on "public"."canonical_verticals";
DROP POLICY IF EXISTS "group_capability_grants_read_authenticated_v1" on "public"."group_capability_grants";
DROP POLICY IF EXISTS "specialty_governance_group_members_read_authenticated_v1" on "public"."specialty_governance_group_members";
DROP POLICY IF EXISTS "specialty_governance_groups_read_authenticated_v1" on "public"."specialty_governance_groups";
DROP POLICY IF EXISTS "specialty_types_read_authenticated_v1" on "public"."specialty_types";
DROP POLICY IF EXISTS "vcs_read_authenticated_v1" on "public"."vertical_canonical_specialties";

revoke delete on table "public"."canonical_verticals" from "anon";

revoke insert on table "public"."canonical_verticals" from "anon";

revoke update on table "public"."canonical_verticals" from "anon";

revoke delete on table "public"."canonical_verticals" from "authenticated";

revoke insert on table "public"."canonical_verticals" from "authenticated";

revoke update on table "public"."canonical_verticals" from "authenticated";

revoke delete on table "public"."specialty_types" from "anon";

revoke insert on table "public"."specialty_types" from "anon";

revoke update on table "public"."specialty_types" from "anon";

revoke delete on table "public"."specialty_types" from "authenticated";

revoke insert on table "public"."specialty_types" from "authenticated";

revoke update on table "public"."specialty_types" from "authenticated";

revoke delete on table "public"."vertical_canonical_specialties" from "anon";

revoke insert on table "public"."vertical_canonical_specialties" from "anon";

revoke update on table "public"."vertical_canonical_specialties" from "anon";

revoke delete on table "public"."vertical_canonical_specialties" from "authenticated";

revoke insert on table "public"."vertical_canonical_specialties" from "authenticated";

revoke update on table "public"."vertical_canonical_specialties" from "authenticated";

alter table "public"."specialty_governance_group_members" drop constraint IF EXISTS "specialty_governance_group_members_group_fkey";

alter table "public"."specialty_governance_group_members" drop constraint IF EXISTS "specialty_governance_group_members_specialty_fkey";

alter table "public"."vertical_canonical_specialties" drop constraint IF EXISTS "fk_vcs_vertical";
drop index if exists "public"."vertical_canonical_specialties_one_default_per_vertical";
create table if not exists "public"."_backup_specialty_vertical_overlays" (
    "specialty_code" text,
    "vertical_code" text,
    "created_at" timestamp with time zone,
    "created_by" uuid
      );
create table if not exists "public"."_backup_vertical_canonical_specialties" (
    "vertical_code" text,
    "specialty_code" text,
    "is_default" boolean
      );
create table if not exists "public"."account_deletion_requests" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "status" text not null default 'pending'::text,
    "reason" text,
    "hard_delete" boolean not null default false,
    "requested_at" timestamp with time zone not null default now(),
    "confirmed_at" timestamp with time zone
      );


alter table "public"."account_deletion_requests" enable row level security;
create table if not exists "public"."app_settings" (
    "key" text not null,
    "value" jsonb not null,
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."app_settings" enable row level security;
create table if not exists "public"."arts_culture_event_context_profiles" (
    "arts_culture_event_id" uuid not null,
    "best_at_sunset" boolean,
    "rainy_day_indoor" boolean,
    "photo_friendly" boolean,
    "kid_friendly" boolean,
    "accessibility_tags" jsonb,
    "story_snippet" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."arts_culture_event_context_profiles" enable row level security;
create table if not exists "public"."arts_culture_events" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "title" text not null,
    "description" text,
    "event_type" text,
    "tags" jsonb not null default '[]'::jsonb,
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "kids_mode_safe" boolean not null default true,
    "seasonal_category" text,
    "info_url" text,
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."arts_culture_events" enable row level security;
create table if not exists "public"."badges" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "name" text not null,
    "description" text,
    "badge_type" text default 'trust'::text,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."badges" enable row level security;
create table if not exists "public"."bids" (
    "id" uuid not null default gen_random_uuid(),
    "rfq_id" uuid not null,
    "vendor_id" uuid not null,
    "price_total" numeric not null,
    "price_unit" numeric,
    "currency" text default 'USD'::text,
    "notes" text,
    "status" text not null default 'pending'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "vertical_code" text not null
      );


alter table "public"."bids" enable row level security;
create table if not exists "public"."billing_customers" (
    "user_id" uuid not null,
    "stripe_customer_id" text not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."billing_customers" enable row level security;
create table if not exists "public"."bulk_offer_analytics" (
    "id" uuid not null default gen_random_uuid(),
    "offer_id" uuid not null,
    "vendor_user_id" uuid not null,
    "impressions" integer not null default 0,
    "clicks" integer not null default 0,
    "saves" integer not null default 0,
    "bids_count" integer not null default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."bulk_offer_analytics" enable row level security;
create table if not exists "public"."bulk_offers" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "created_by" uuid not null,
    "category" text not null,
    "title" text not null,
    "description" text,
    "min_quantity" numeric,
    "unit" text,
    "price_per_unit" numeric(12,2),
    "currency" text default 'USD'::text,
    "delivery_radius_miles" integer default 50,
    "is_delivery_available" boolean default true,
    "pickup_only" boolean default false,
    "is_active" boolean default true,
    "starts_at" timestamp with time zone,
    "ends_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "vertical_code" text not null
      );


alter table "public"."bulk_offers" enable row level security;
create table if not exists "public"."capabilities" (
    "capability_key" text not null,
    "description" text,
    "default_allowed" boolean not null default false,
    "created_at" timestamp with time zone not null default now()
      );
create table if not exists "public"."community_nature_spots" (
    "id" uuid not null default gen_random_uuid(),
    "created_by" uuid not null,
    "spot_type" text not null,
    "name" text not null,
    "description" text,
    "latitude" double precision not null,
    "longitude" double precision not null,
    "provider_id" uuid,
    "landmark_id" uuid,
    "season_tags" jsonb not null default '[]'::jsonb,
    "kids_mode_safe" boolean not null default true,
    "status" text not null default 'pending'::text,
    "moderator_id" uuid,
    "moderated_at" timestamp with time zone,
    "rejection_reason" text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."community_nature_spots" enable row level security;
create table if not exists "public"."community_programs" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "title" text not null,
    "description" text,
    "audience" text,
    "is_free" boolean not null default false,
    "kids_mode_safe" boolean not null default true,
    "community_tags" jsonb not null default '[]'::jsonb,
    "seasonal_category" text,
    "starts_at" timestamp with time zone,
    "ends_at" timestamp with time zone,
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."community_programs" enable row level security;
create table if not exists "public"."community_specialty_registry" (
    "id" uuid not null default gen_random_uuid(),
    "slug" text not null,
    "display_name" text not null,
    "parent_group" text not null,
    "applies_to" text not null,
    "is_kids_safe" boolean not null default false,
    "allows_commerce" boolean not null default true,
    "allows_ads" boolean not null default false,
    "map_icon_key" text not null,
    "filter_group" text not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."community_specialty_registry" enable row level security;
create table if not exists "public"."compliance_overlays" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "label" text not null,
    "description" text
      );


alter table "public"."compliance_overlays" enable row level security;
create table if not exists "public"."construction_safety_incidents" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "reported_by" uuid not null,
    "occurred_at" timestamp with time zone not null,
    "created_at" timestamp with time zone not null default now(),
    "incident_type" text not null,
    "severity" text default 'low'::text,
    "description" text,
    "status" text default 'logged'::text
      );


alter table "public"."construction_safety_incidents" enable row level security;
create table if not exists "public"."conversation_participants" (
    "conversation_id" uuid not null,
    "user_id" uuid not null,
    "role_in_conversation" text,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."conversation_participants" enable row level security;
create table if not exists "public"."conversations" (
    "id" uuid not null default gen_random_uuid(),
    "created_by" uuid not null,
    "rfq_id" uuid,
    "bid_id" uuid,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."conversations" enable row level security;
create table if not exists "public"."donations" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "donor_user_id" uuid,
    "amount_cents" integer not null,
    "currency" text not null default 'usd'::text,
    "stripe_payment_intent_id" text,
    "stripe_checkout_session_id" text,
    "stripe_customer_id" text,
    "message" text,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now())
      );


alter table "public"."donations" enable row level security;
create table if not exists "public"."education_field_trips" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "landmark_id" uuid,
    "title" text not null,
    "description" text,
    "audience" text,
    "grade_bands" jsonb not null default '[]'::jsonb,
    "subject_tags" jsonb not null default '[]'::jsonb,
    "is_free" boolean not null default false,
    "max_students" integer,
    "requires_waiver" boolean not null default false,
    "kids_mode_safe" boolean not null default true,
    "info_url" text,
    "contact_email" text,
    "contact_phone" text,
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."education_field_trips" enable row level security;
create table if not exists "public"."event_analytics_daily" (
    "id" uuid not null default gen_random_uuid(),
    "event_id" uuid,
    "stat_date" date not null,
    "registrations_count" integer default 0,
    "check_ins_count" integer default 0,
    "volunteer_signups_count" integer default 0,
    "created_at" timestamp with time zone default now(),
    "vendor_user_id" uuid
      );


alter table "public"."event_analytics_daily" enable row level security;
create table if not exists "public"."event_badges" (
    "id" uuid not null default gen_random_uuid(),
    "event_id" uuid,
    "badge_id" uuid,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."event_badges" enable row level security;
create table if not exists "public"."event_context_profiles" (
    "event_id" uuid not null,
    "accessibility_tags" jsonb,
    "weather_impact_note" text,
    "family_friendly" boolean,
    "first_timer_friendly" boolean,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."event_context_profiles" enable row level security;
create table if not exists "public"."event_registrations" (
    "id" uuid not null default gen_random_uuid(),
    "created_at" timestamp with time zone default now(),
    "event_id" uuid not null,
    "user_id" uuid not null,
    "role" text not null,
    "kids_mode" boolean default false,
    "parental_approval" boolean default false,
    "status" text not null default 'pending'::text
      );


alter table "public"."event_registrations" enable row level security;
create table if not exists "public"."event_specialties" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "label" text not null,
    "category" text not null,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."event_specialties" enable row level security;
create table if not exists "public"."event_specialty_links" (
    "event_id" uuid not null,
    "event_specialty_id" uuid not null
      );


alter table "public"."event_specialty_links" enable row level security;
create table if not exists "public"."events" (
    "id" uuid not null default gen_random_uuid(),
    "created_at" timestamp with time zone default now(),
    "created_by" uuid not null,
    "host_vendor_id" uuid,
    "host_institution_id" uuid,
    "title" text not null,
    "description" text,
    "event_type" text not null,
    "start_time" timestamp with time zone not null,
    "end_time" timestamp with time zone not null,
    "location_lat" numeric,
    "location_lng" numeric,
    "is_kids_safe" boolean default false,
    "max_participants" integer,
    "season_tags" text[],
    "holiday_tags" text[],
    "cultural_tags" text[],
    "status" text not null default 'draft'::text,
    "moderation_status" text not null default 'pending_review'::text,
    "seasonal_category" text,
    "kids_mode_safe" boolean default true,
    "community_tags" jsonb default '[]'::jsonb,
    "event_vertical" text not null,
    "is_volunteer" boolean default false,
    "is_large_scale_volunteer" boolean default false,
    "requires_institutional_partner" boolean default false
      );


alter table "public"."events" enable row level security;
create table if not exists "public"."experience_context_profiles" (
    "experience_id" uuid not null,
    "difficulty_level" text,
    "first_timer_friendly" boolean,
    "surface_type" text,
    "incline_description" text,
    "recommended_footwear" text,
    "seasonal_pack_tags" text[],
    "leave_no_trace_tips" text,
    "weather_impact_note" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."experience_context_profiles" enable row level security;
create table if not exists "public"."experience_kids_mode_overlays" (
    "experience_code" text not null,
    "kids_code" text not null
      );
create table if not exists "public"."experience_requests" (
    "id" uuid not null default gen_random_uuid(),
    "experience_id" uuid not null,
    "institution_user_id" uuid not null,
    "preferred_dates" text,
    "group_size" integer,
    "notes" text,
    "status" text not null default 'pending'::text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."experience_requests" enable row level security;
create table if not exists "public"."experience_types" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "label" text not null,
    "requires_waiver" boolean not null default false,
    "kids_allowed" boolean not null default true,
    "insurance_required" boolean not null default false,
    "seasonal_lockable" boolean not null default false
      );
create table if not exists "public"."experiences" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "title" text not null,
    "description" text,
    "min_age" integer,
    "max_age" integer,
    "season" text,
    "is_kids_safe" boolean not null default true,
    "status" text not null default 'draft'::text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "created_by" uuid,
    "requires_adult_supervision" boolean not null default true,
    "teen_visible" boolean not null default true
      );


alter table "public"."experiences" enable row level security;
create table if not exists "public"."feed_comments" (
    "id" uuid not null default gen_random_uuid(),
    "feed_id" uuid,
    "user_id" uuid,
    "content" text not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."feed_comments" enable row level security;
create table if not exists "public"."feed_items" (
    "id" uuid not null default gen_random_uuid(),
    "author_id" uuid not null,
    "author_role" text,
    "author_tier" text,
    "content" text not null,
    "media" jsonb,
    "feed_type" text,
    "visibility_scope" text default 'public'::text,
    "is_kids_safe" boolean default false,
    "requires_premium" boolean default false,
    "requires_premium_plus" boolean default false,
    "location" jsonb,
    "related_vendor_id" uuid,
    "related_institution_id" uuid,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."feed_items" enable row level security;
create table if not exists "public"."feed_likes" (
    "feed_id" uuid not null,
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."feed_likes" enable row level security;
create table if not exists "public"."institution_applications" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "org_name" text not null,
    "org_website" text,
    "contact_name" text,
    "contact_email" text,
    "phone" text,
    "location_city" text,
    "location_state" text,
    "location_country" text,
    "description" text,
    "metadata" jsonb not null default '{}'::jsonb,
    "status" text not null default 'draft'::text,
    "moderation_id" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "decided_at" timestamp with time zone,
    "decided_by" uuid
      );


alter table "public"."institution_applications" enable row level security;
create table if not exists "public"."institution_specialties" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "label" text not null,
    "category" text not null,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."institution_specialties" enable row level security;
create table if not exists "public"."kids_mode_overlays" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "label" text not null
      );


alter table "public"."kids_mode_overlays" enable row level security;
create table if not exists "public"."kv_store_5bb94edf" (
    "key" text not null,
    "value" jsonb not null
      );


alter table "public"."kv_store_5bb94edf" enable row level security;
create table if not exists "public"."kv_store_80d2ab6d" (
    "key" text not null,
    "value" jsonb not null
      );


alter table "public"."kv_store_80d2ab6d" enable row level security;
create table if not exists "public"."kv_store_9ca868c2" (
    "key" text not null,
    "value" jsonb not null
      );


alter table "public"."kv_store_9ca868c2" enable row level security;
create table if not exists "public"."kv_store_d3ca0863" (
    "key" text not null,
    "value" jsonb not null
      );


alter table "public"."kv_store_d3ca0863" enable row level security;
create table if not exists "public"."kv_store_f009e61d" (
    "key" text not null,
    "value" jsonb not null
      );


alter table "public"."kv_store_f009e61d" enable row level security;
create table if not exists "public"."kv_store_fabed9c2" (
    "key" text not null,
    "value" jsonb not null
      );


alter table "public"."kv_store_fabed9c2" enable row level security;
create table if not exists "public"."landmark_badges" (
    "id" uuid not null default gen_random_uuid(),
    "landmark_id" uuid,
    "badge_id" uuid,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."landmark_badges" enable row level security;
create table if not exists "public"."landmark_specialties" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "label" text not null,
    "category" text not null,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."landmark_specialties" enable row level security;
create table if not exists "public"."landmark_specialty_links" (
    "landmark_id" uuid not null,
    "landmark_specialty_id" uuid not null
      );


alter table "public"."landmark_specialty_links" enable row level security;
create table if not exists "public"."landmark_types" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "label" text not null
      );
create table if not exists "public"."landmarks" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "landmark_type" text not null,
    "lat" double precision not null,
    "lng" double precision not null,
    "is_kid_safe" boolean not null default true,
    "is_published" boolean not null default false,
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "moderation_status" text not null default 'pending_review'::text,
    "seasonal_category" text,
    "kids_mode_safe" boolean default true,
    "community_tags" jsonb default '[]'::jsonb,
    "is_kids_safe_zone" boolean not null default false,
    "kids_safe_zone_type" text,
    "community_focus_tags" jsonb not null default '[]'::jsonb,
    "is_education_landmark" boolean not null default false,
    "education_landmark_type" text,
    "education_subject_tags" jsonb not null default '[]'::jsonb,
    "education_field_trip_ready" boolean not null default false,
    "education_requires_waiver" boolean not null default false,
    "education_kids_mode_safe" boolean not null default true,
    "is_arts_culture_landmark" boolean not null default false,
    "arts_culture_landmark_type" text,
    "arts_culture_story" text,
    "arts_culture_kids_mode_safe" boolean not null default true,
    "landmark_vertical" text
      );


alter table "public"."landmarks" enable row level security;
create table if not exists "public"."location_checkins" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid,
    "landmark_id" uuid,
    "created_by" uuid not null,
    "image_url" text not null,
    "caption" text,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."location_checkins" enable row level security;
create table if not exists "public"."market_session_locks" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "entity_type" text not null,
    "entity_id" uuid not null,
    "acquired_at" timestamp with time zone not null default now(),
    "expires_at" timestamp with time zone not null
      );


alter table "public"."market_session_locks" enable row level security;
create table if not exists "public"."messages" (
    "id" uuid not null default gen_random_uuid(),
    "conversation_id" uuid not null,
    "sender_id" uuid not null,
    "content" text not null,
    "attachments" jsonb,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."messages" enable row level security;
create table if not exists "public"."moderation_queue" (
    "id" uuid not null default gen_random_uuid(),
    "entity_type" text not null,
    "entity_id" uuid not null,
    "submitted_by" uuid not null,
    "status" text not null default 'pending'::text,
    "reason" text,
    "created_at" timestamp with time zone not null default now(),
    "reviewed_at" timestamp with time zone,
    "reviewed_by" uuid
      );


alter table "public"."moderation_queue" enable row level security;
create table if not exists "public"."notifications" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "type" text not null,
    "title" text not null,
    "body" text not null,
    "data" jsonb,
    "delivery_channel" text[] not null default ARRAY['push'::text],
    "delivered" boolean not null default false,
    "delivered_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."notifications" enable row level security;
create table if not exists "public"."password_history" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "pw_fingerprint" text not null,
    "rotated_at" timestamp with time zone not null default now()
      );


alter table "public"."password_history" enable row level security;
create table if not exists "public"."provider_badges" (
    "provider_id" uuid not null,
    "badge_id" uuid not null,
    "granted_by" uuid,
    "granted_at" timestamp with time zone default now(),
    "visible_publicly" boolean not null default false
      );


alter table "public"."provider_badges" enable row level security;
create table if not exists "public"."provider_compliance_overlays" (
    "provider_id" uuid not null,
    "compliance_code" text not null
      );


alter table "public"."provider_compliance_overlays" enable row level security;
create table if not exists "public"."provider_context_profiles" (
    "provider_id" uuid not null,
    "established_year" integer,
    "community_impact_summary" text,
    "volunteer_events_hosted" integer,
    "food_donated_lbs" numeric,
    "school_partnerships_count" integer,
    "accessibility_tags" jsonb,
    "weather_notes" jsonb,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."provider_context_profiles" enable row level security;
create table if not exists "public"."provider_employees" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "full_name" text,
    "role_title" text,
    "email" text,
    "phone" text,
    "is_public" boolean not null default false,
    "notes" text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."provider_employees" enable row level security;
create table if not exists "public"."provider_impact_snapshots" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "snapshot_date" date not null,
    "period_start" date not null,
    "period_end" date not null,
    "total_orders" integer,
    "total_revenue" numeric,
    "community_donations" numeric,
    "events_hosted" integer,
    "volunteers_involved" integer,
    "impact_score" numeric,
    "metrics" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."provider_impact_snapshots" enable row level security;
create table if not exists "public"."provider_institution_specialties" (
    "provider_id" uuid not null,
    "institution_specialty_id" uuid not null
      );


alter table "public"."provider_institution_specialties" enable row level security;
create table if not exists "public"."provider_kids_mode_overlays" (
    "provider_id" uuid not null,
    "kids_code" text not null
      );


alter table "public"."provider_kids_mode_overlays" enable row level security;
create table if not exists "public"."provider_media" (
    "id" uuid not null default gen_random_uuid(),
    "provider_id" uuid not null,
    "media_type" text not null default 'image'::text,
    "role" text not null default 'hero'::text,
    "url" text not null,
    "alt_text" text,
    "sort_order" integer default 0,
    "created_at" timestamp with time zone default now(),
    "is_public" boolean not null default true
      );


alter table "public"."provider_media" enable row level security;
create table if not exists "public"."provider_memberships" (
    "provider_id" uuid not null,
    "user_id" uuid not null,
    "membership_role" text not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."provider_memberships" enable row level security;
create table if not exists "public"."provider_specialties" (
    "provider_id" uuid not null,
    "specialty_id" uuid not null
      );


alter table "public"."provider_specialties" enable row level security;
create table if not exists "public"."provider_vendor_specialties" (
    "provider_id" uuid not null,
    "vendor_specialty_id" uuid not null
      );


alter table "public"."provider_vendor_specialties" enable row level security;
create table if not exists "public"."providers" (
    "id" uuid not null default gen_random_uuid(),
    "owner_user_id" uuid,
    "vertical" text not null,
    "provider_type" text not null default 'vendor'::text,
    "specialty" text not null,
    "name" text not null,
    "slug" text,
    "short_description" text,
    "full_description" text,
    "lat" double precision not null,
    "lng" double precision not null,
    "city" text,
    "state" text,
    "country" text default 'US'::text,
    "postal_code" text,
    "is_active" boolean not null default true,
    "is_verified" boolean not null default false,
    "verification_level" text default 'unverified'::text,
    "engagement_score" numeric default 0,
    "last_shown_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "subscription_tier" text default 'free'::text,
    "is_discoverable" boolean not null default false,
    "is_claimed" boolean not null default false,
    "payment_provider_customer_id" text,
    "subscription_status" text default 'inactive'::text,
    "seasonal_theme" text,
    "community_tags" jsonb default '[]'::jsonb,
    "kids_mode_safe" boolean default true,
    "is_community_org" boolean not null default false,
    "community_focus_tags" jsonb not null default '[]'::jsonb,
    "community_trust_score" numeric(5,2) not null default 0,
    "community_trust_tier" text not null default 'unrated'::text,
    "community_featured_weight" integer not null default 0,
    "last_community_reviewed_at" timestamp with time zone,
    "is_education_site" boolean not null default false,
    "education_site_type" text,
    "education_subject_tags" jsonb not null default '[]'::jsonb,
    "education_grade_bands" jsonb not null default '[]'::jsonb,
    "education_field_trip_ready" boolean not null default false,
    "education_field_trip_contact_email" text,
    "education_field_trip_contact_phone" text,
    "education_field_trip_notes" text,
    "education_kids_mode_safe" boolean not null default true,
    "education_safety_level" text,
    "is_arts_culture_site" boolean not null default false,
    "arts_culture_type" text,
    "arts_culture_tags" jsonb not null default '[]'::jsonb,
    "arts_culture_kids_mode_safe" boolean not null default true,
    "arts_culture_accessibility" jsonb not null default '[]'::jsonb,
    "arts_culture_seasonal_relevance" jsonb not null default '[]'::jsonb,
    "arts_culture_story" text,
    "established_year" integer,
    "community_impact_summary" text,
    "volunteer_events_hosted" integer,
    "food_donated_lbs" numeric,
    "school_partnerships_count" integer,
    "accessibility_tags" jsonb,
    "weather_notes" jsonb,
    "primary_vertical" text,
    "is_seed_provider" boolean not null default false,
    "is_founding_member" boolean not null default false
      );


alter table "public"."providers" enable row level security;
create table if not exists "public"."rfqs" (
    "id" uuid not null default gen_random_uuid(),
    "institution_id" uuid not null,
    "title" text not null,
    "description" text,
    "category" text,
    "quantity" numeric,
    "unit" text,
    "delivery_start_date" date,
    "delivery_end_date" date,
    "status" text not null default 'open'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "vertical_code" text not null
      );


alter table "public"."rfqs" enable row level security;
create table if not exists "public"."seasonal_content_analytics_daily" (
    "content_type" text not null,
    "content_id" uuid not null,
    "date" date not null,
    "views" integer not null default 0,
    "saves" integer not null default 0,
    "completions" integer not null default 0
      );


alter table "public"."seasonal_content_analytics_daily" enable row level security;
create table if not exists "public"."seasonal_crafts" (
    "id" uuid not null default gen_random_uuid(),
    "month" integer not null,
    "title" text not null,
    "craft_type" text not null,
    "difficulty" text not null,
    "requires_parent" boolean not null default false,
    "is_kids_safe" boolean not null default true,
    "description" text,
    "materials" jsonb,
    "steps" jsonb,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."seasonal_crafts" enable row level security;
create table if not exists "public"."seasonal_produce" (
    "id" uuid not null default gen_random_uuid(),
    "month" integer not null,
    "title" text not null,
    "short_label" text not null,
    "description" text,
    "items" jsonb not null,
    "is_kids_safe" boolean not null default true,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."seasonal_produce" enable row level security;
create table if not exists "public"."seasonal_recipes" (
    "id" uuid not null default gen_random_uuid(),
    "month" integer not null,
    "title" text not null,
    "short_label" text not null,
    "description" text,
    "ingredients" jsonb not null,
    "steps" jsonb not null,
    "is_kids_safe" boolean not null default false,
    "premium_plus_only" boolean not null default true,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."seasonal_recipes" enable row level security;
create table if not exists "public"."seasonal_seeds" (
    "id" uuid not null default gen_random_uuid(),
    "month" integer not null,
    "title" text not null,
    "short_label" text not null,
    "description" text,
    "items" jsonb not null,
    "is_kids_safe" boolean not null default true,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."seasonal_seeds" enable row level security;
create table if not exists "public"."specialty_compliance_overlays" (
    "specialty_code" text not null,
    "compliance_code" text not null
      );


alter table "public"."specialty_compliance_overlays" enable row level security;
create table if not exists "public"."specialty_kids_mode_overlays" (
    "specialty_code" text not null,
    "kids_code" text not null
      );


alter table "public"."specialty_kids_mode_overlays" enable row level security;
create table if not exists "public"."specialty_vertical_overlays" (
    "specialty_code" text not null,
    "vertical_code" text not null,
    "created_at" timestamp with time zone not null default now(),
    "created_by" uuid
      );


alter table "public"."specialty_vertical_overlays" enable row level security;
create table if not exists "public"."specialty_vertical_overlays_bak" (
    "specialty_code" text,
    "vertical_code" text,
    "created_at" timestamp with time zone,
    "created_by" uuid
      );
create table if not exists "public"."specialty_vertical_overlays_v1" (
    "id" uuid not null default gen_random_uuid(),
    "specialty_code" text not null,
    "vertical_group" text not null,
    "is_primary" boolean not null default false,
    "is_enabled" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );
create table if not exists "public"."user_admin_actions" (
    "id" uuid not null default gen_random_uuid(),
    "admin_id" uuid not null,
    "target_user_id" uuid not null,
    "action_type" text not null,
    "details" jsonb,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."user_admin_actions" enable row level security;
create table if not exists "public"."user_consents" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "consent_type" text not null,
    "status" text not null,
    "source" text not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."user_consents" enable row level security;
create table if not exists "public"."user_devices" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "platform" text not null,
    "device_token" text not null,
    "push_enabled" boolean not null default true,
    "last_seen_at" timestamp with time zone not null default now(),
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."user_devices" enable row level security;
create table if not exists "public"."user_password_history" (
    "user_id" uuid not null,
    "pw_fingerprint" text not null,
    "changed_at" timestamp with time zone not null default now()
      );


alter table "public"."user_password_history" enable row level security;
create table if not exists "public"."user_tier_memberships" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "tier" text not null,
    "started_at" timestamp with time zone not null default now(),
    "ends_at" timestamp with time zone not null,
    "auto_renew" boolean not null default false,
    "status" text not null default 'active'::text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."user_tier_memberships" enable row level security;
create table if not exists "public"."user_tiers" (
    "user_id" uuid not null,
    "role" text not null,
    "tier" text not null,
    "updated_at" timestamp with time zone not null default now(),
    "feature_flags" jsonb not null default '{}'::jsonb,
    "account_status" text not null default 'active'::text,
    "subscription_tier" text,
    "subscription_status" text,
    "payment_provider_customer_id" text,
    "subscription_source" text
      );


alter table "public"."user_tiers" enable row level security;
create table if not exists "public"."vendor_analytics_advanced_daily" (
    "vendor_id" uuid not null,
    "owner_user_id" uuid not null,
    "analytics_date" date not null,
    "bulk_inquiries" integer not null default 0,
    "bulk_orders" integer not null default 0,
    "bid_invites" integer not null default 0,
    "bids_submitted" integer not null default 0,
    "bids_won" integer not null default 0,
    "total_revenue" numeric(12,2) not null default 0,
    "avg_order_value" numeric(12,2) not null default 0,
    "conversion_rate" numeric(5,2) not null default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."vendor_analytics_advanced_daily" enable row level security;
create table if not exists "public"."vendor_analytics_basic_daily" (
    "vendor_id" uuid not null,
    "owner_user_id" uuid not null,
    "analytics_date" date not null,
    "profile_views" integer not null default 0,
    "directory_clicks" integer not null default 0,
    "experience_views" integer not null default 0,
    "favorites_added" integer not null default 0,
    "saves_to_list" integer not null default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."vendor_analytics_basic_daily" enable row level security;
create table if not exists "public"."vendor_analytics_daily" (
    "id" uuid not null default gen_random_uuid(),
    "vendor_id" uuid not null,
    "day" date not null,
    "impressions" integer not null default 0,
    "clicks" integer not null default 0,
    "saves" integer not null default 0,
    "rfq_views" integer not null default 0,
    "bid_views" integer not null default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."vendor_analytics_daily" enable row level security;
create table if not exists "public"."vendor_applications" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "org_name" text not null,
    "org_website" text,
    "contact_name" text,
    "contact_email" text,
    "phone" text,
    "location_city" text,
    "location_state" text,
    "location_country" text,
    "description" text,
    "metadata" jsonb not null default '{}'::jsonb,
    "status" text not null default 'draft'::text,
    "moderation_id" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "decided_at" timestamp with time zone,
    "decided_by" uuid
      );


alter table "public"."vendor_applications" enable row level security;
create table if not exists "public"."vendor_media" (
    "id" uuid not null default gen_random_uuid(),
    "owner_user_id" uuid not null,
    "storage_bucket" text not null,
    "storage_path" text not null,
    "media_type" text not null,
    "visibility" text not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."vendor_media" enable row level security;
create table if not exists "public"."vendor_specialties" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "label" text not null,
    "category" text not null,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."vendor_specialties" enable row level security;
create table if not exists "public"."vertical_canonical_specialties_bak" (
    "vertical_code" text,
    "specialty_code" text,
    "is_default" boolean
      );
create table if not exists "public"."vertical_capability_defaults" (
    "vertical_code" text not null,
    "capability_key" text not null,
    "is_allowed" boolean not null,
    "created_at" timestamp with time zone not null default now()
      );
create table if not exists "public"."vertical_conditions" (
    "vertical_code" text not null,
    "allow_kids_mode" boolean not null default true,
    "allow_experiences" boolean not null default true,
    "allow_volunteering" boolean not null default true,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."vertical_conditions" enable row level security;
create table if not exists "public"."vertical_market_requirements" (
    "vertical_code" text not null,
    "market_code" text not null,
    "required_badge_codes" text[],
    "require_verified_provider" boolean not null default false,
    "enabled" boolean not null default true,
    "notes" text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );
create table if not exists "public"."weather_snapshots" (
    "id" uuid not null default gen_random_uuid(),
    "vertical" text not null,
    "scope_type" text not null,
    "provider_id" uuid,
    "region_code" text,
    "label" text,
    "summary" text,
    "temp_f" numeric,
    "condition_code" text,
    "risk_level" text,
    "risk_flags" jsonb default '[]'::jsonb,
    "seasonal_phase" text,
    "guidance_text" text,
    "valid_from" timestamp with time zone not null default now(),
    "valid_to" timestamp with time zone,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."weather_snapshots" enable row level security;

alter table "public"."canonical_verticals" drop column if exists "created_at";

alter table "public"."canonical_verticals" drop column if exists "updated_at";

alter table "public"."group_capability_grants" disable row level security;

alter table "public"."specialty_capabilities" alter column "default_allowed" set default false;

alter table "public"."specialty_governance_group_members" disable row level security;

alter table "public"."specialty_governance_groups" drop column if exists "updated_at";

alter table "public"."specialty_governance_groups" alter column "description" drop default;

alter table "public"."specialty_governance_groups" alter column "description" drop not null;

alter table "public"."specialty_governance_groups" disable row level security;

alter table "public"."specialty_types" drop column if exists "created_at";

alter table "public"."specialty_types" drop column if exists "description";

alter table "public"."specialty_types" drop column if exists "updated_at";

alter table "public"."specialty_types" add column "default_visibility" boolean not null default true;

alter table "public"."specialty_types" add column "id" uuid not null default gen_random_uuid();

alter table "public"."specialty_types" add column "kids_allowed" boolean not null default true;

alter table "public"."specialty_types" add column "requires_compliance" boolean not null default true;

alter table "public"."specialty_types" add column "vertical_code" text;
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='specialty_types'
      and column_name='vertical_group'
  ) then
    alter table public.specialty_types alter column vertical_group set not null;
  else
    raise notice 'remote_schema: skipping SET NOT NULL (missing column) public.specialty_types.vertical_group';
  end if;
end $$;
alter table "public"."vertical_canonical_specialties" drop column if exists "created_at";

alter table "public"."vertical_canonical_specialties" drop column if exists "updated_at";

alter table "public"."vertical_canonical_specialties" alter column "is_default" set default false;

alter table "public"."vertical_canonical_specialties" alter column "is_default" drop not null;

alter table "public"."vertical_policy" alter column "allowed_roles" set default ARRAY['individual'::text, 'vendor'::text, 'institution'::text, 'admin'::text];
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='vertical_policy'
      and column_name='allowed_roles'
  ) then
    alter table public.specialty_types alter column vertical_group set not null;
  else
    raise notice 'remote_schema: skipping SET NOT NULL (missing column) public.vertical_policy.allowed_roles';
  end if;
end $$;
CREATE UNIQUE INDEX account_deletion_requests_pkey ON public.account_deletion_requests USING btree (id);

CREATE UNIQUE INDEX app_settings_pkey ON public.app_settings USING btree (key);

CREATE UNIQUE INDEX arts_culture_event_context_profiles_pkey ON public.arts_culture_event_context_profiles USING btree (arts_culture_event_id);

CREATE UNIQUE INDEX arts_culture_events_pkey ON public.arts_culture_events USING btree (id);

CREATE UNIQUE INDEX badges_code_key ON public.badges USING btree (code);

CREATE UNIQUE INDEX badges_pkey ON public.badges USING btree (id);

CREATE UNIQUE INDEX bids_pkey ON public.bids USING btree (id);

CREATE UNIQUE INDEX billing_customers_pkey ON public.billing_customers USING btree (user_id);

CREATE UNIQUE INDEX billing_customers_stripe_customer_id_key ON public.billing_customers USING btree (stripe_customer_id);

CREATE UNIQUE INDEX bulk_offer_analytics_pkey ON public.bulk_offer_analytics USING btree (id);

CREATE UNIQUE INDEX bulk_offers_pkey ON public.bulk_offers USING btree (id);

CREATE UNIQUE INDEX capabilities_pkey ON public.capabilities USING btree (capability_key);

CREATE UNIQUE INDEX community_nature_spots_pkey ON public.community_nature_spots USING btree (id);

CREATE UNIQUE INDEX community_programs_pkey ON public.community_programs USING btree (id);

CREATE UNIQUE INDEX community_specialty_registry_pkey ON public.community_specialty_registry USING btree (id);

CREATE UNIQUE INDEX community_specialty_registry_slug_key ON public.community_specialty_registry USING btree (slug);

CREATE UNIQUE INDEX compliance_overlays_code_key ON public.compliance_overlays USING btree (code);

CREATE UNIQUE INDEX compliance_overlays_pkey ON public.compliance_overlays USING btree (id);

CREATE UNIQUE INDEX construction_safety_incidents_pkey ON public.construction_safety_incidents USING btree (id);

CREATE UNIQUE INDEX conversation_participants_pkey ON public.conversation_participants USING btree (conversation_id, user_id);

CREATE UNIQUE INDEX conversations_pkey ON public.conversations USING btree (id);

CREATE UNIQUE INDEX donations_pkey ON public.donations USING btree (id);

CREATE UNIQUE INDEX education_field_trips_pkey ON public.education_field_trips USING btree (id);

CREATE UNIQUE INDEX event_analytics_daily_event_id_stat_date_key ON public.event_analytics_daily USING btree (event_id, stat_date);

CREATE UNIQUE INDEX event_analytics_daily_pkey ON public.event_analytics_daily USING btree (id);

CREATE UNIQUE INDEX event_badges_event_id_badge_id_key ON public.event_badges USING btree (event_id, badge_id);

CREATE UNIQUE INDEX event_badges_pkey ON public.event_badges USING btree (id);

CREATE UNIQUE INDEX event_context_profiles_event_id_uq ON public.event_context_profiles USING btree (event_id);

CREATE UNIQUE INDEX event_context_profiles_pkey ON public.event_context_profiles USING btree (event_id);

CREATE UNIQUE INDEX event_registrations_pkey ON public.event_registrations USING btree (id);

CREATE UNIQUE INDEX event_specialties_code_key ON public.event_specialties USING btree (code);

CREATE UNIQUE INDEX event_specialties_pkey ON public.event_specialties USING btree (id);

CREATE UNIQUE INDEX event_specialty_links_pkey ON public.event_specialty_links USING btree (event_id, event_specialty_id);

CREATE UNIQUE INDEX events_pkey ON public.events USING btree (id);

CREATE UNIQUE INDEX experience_context_profiles_pkey ON public.experience_context_profiles USING btree (experience_id);

CREATE UNIQUE INDEX experience_kids_mode_overlays_pkey ON public.experience_kids_mode_overlays USING btree (experience_code, kids_code);

CREATE UNIQUE INDEX experience_requests_pkey ON public.experience_requests USING btree (id);

CREATE UNIQUE INDEX experience_types_code_key ON public.experience_types USING btree (code);

CREATE UNIQUE INDEX experience_types_pkey ON public.experience_types USING btree (id);

CREATE UNIQUE INDEX experiences_pkey ON public.experiences USING btree (id);

CREATE UNIQUE INDEX feed_comments_pkey ON public.feed_comments USING btree (id);

CREATE UNIQUE INDEX feed_items_pkey ON public.feed_items USING btree (id);

CREATE UNIQUE INDEX feed_likes_pkey ON public.feed_likes USING btree (feed_id, user_id);

CREATE INDEX idx_bulk_offer_analytics_offer ON public.bulk_offer_analytics USING btree (offer_id);

CREATE INDEX idx_bulk_offer_analytics_vendor ON public.bulk_offer_analytics USING btree (vendor_user_id);

CREATE INDEX idx_donations_donor_user_id ON public.donations USING btree (donor_user_id);

CREATE INDEX idx_donations_provider_id ON public.donations USING btree (provider_id);

CREATE INDEX idx_provider_badges_badge ON public.provider_badges USING btree (badge_id);

CREATE INDEX idx_provider_badges_provider ON public.provider_badges USING btree (provider_id);

CREATE INDEX idx_provider_media_provider ON public.provider_media USING btree (provider_id, role);

CREATE INDEX idx_providers_active_verified ON public.providers USING btree (is_active, is_verified);

CREATE INDEX idx_providers_geo ON public.providers USING btree (lat, lng);

CREATE INDEX idx_providers_vertical_specialty ON public.providers USING btree (vertical, specialty);

CREATE INDEX idx_seasonal_crafts_month ON public.seasonal_crafts USING btree (month) WHERE (is_active = true);

CREATE INDEX idx_seasonal_produce_month ON public.seasonal_produce USING btree (month) WHERE (is_active = true);

CREATE INDEX idx_seasonal_recipes_month ON public.seasonal_recipes USING btree (month) WHERE (is_active = true);

CREATE INDEX idx_seasonal_seeds_month ON public.seasonal_seeds USING btree (month) WHERE (is_active = true);

CREATE INDEX idx_user_tier_memberships_user_status ON public.user_tier_memberships USING btree (user_id, status, ends_at);

CREATE INDEX idx_weather_snapshots_vertical ON public.weather_snapshots USING btree (vertical, scope_type, region_code, valid_from DESC);

CREATE UNIQUE INDEX institution_applications_pkey ON public.institution_applications USING btree (id);

CREATE UNIQUE INDEX institution_specialties_code_key ON public.institution_specialties USING btree (code);

CREATE UNIQUE INDEX institution_specialties_pkey ON public.institution_specialties USING btree (id);

CREATE UNIQUE INDEX kids_mode_overlays_code_key ON public.kids_mode_overlays USING btree (code);

CREATE UNIQUE INDEX kids_mode_overlays_pkey ON public.kids_mode_overlays USING btree (id);

CREATE INDEX kv_store_5bb94edf_key_idx ON public.kv_store_5bb94edf USING btree (key text_pattern_ops);

CREATE UNIQUE INDEX kv_store_5bb94edf_pkey ON public.kv_store_5bb94edf USING btree (key);

CREATE INDEX kv_store_80d2ab6d_key_idx ON public.kv_store_80d2ab6d USING btree (key text_pattern_ops);

CREATE UNIQUE INDEX kv_store_80d2ab6d_pkey ON public.kv_store_80d2ab6d USING btree (key);

CREATE INDEX kv_store_9ca868c2_key_idx ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx1 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx10 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx11 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx12 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx13 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx14 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx15 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx16 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx17 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx18 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx19 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx2 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx20 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx21 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx22 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx23 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx24 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx25 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx26 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx27 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx28 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx29 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx3 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx30 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx31 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx32 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx33 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx34 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx35 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx36 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx37 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx38 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx39 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx4 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx40 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx5 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx6 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx7 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx8 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_9ca868c2_key_idx9 ON public.kv_store_9ca868c2 USING btree (key text_pattern_ops);

CREATE UNIQUE INDEX kv_store_9ca868c2_pkey ON public.kv_store_9ca868c2 USING btree (key);

CREATE INDEX kv_store_d3ca0863_key_idx ON public.kv_store_d3ca0863 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_d3ca0863_key_idx1 ON public.kv_store_d3ca0863 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_d3ca0863_key_idx2 ON public.kv_store_d3ca0863 USING btree (key text_pattern_ops);

CREATE UNIQUE INDEX kv_store_d3ca0863_pkey ON public.kv_store_d3ca0863 USING btree (key);

CREATE INDEX kv_store_f009e61d_key_idx ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx1 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx10 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx100 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx101 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx102 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx103 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx104 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx105 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx106 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx107 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx108 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx109 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx11 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx110 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx111 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx112 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx113 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx114 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx115 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx116 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx117 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx118 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx119 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx12 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx120 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx121 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx122 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx123 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx124 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx125 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx126 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx127 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx128 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx129 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx13 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx130 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx131 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx132 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx133 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx134 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx135 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx136 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx137 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx138 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx139 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx14 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx140 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx141 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx142 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx143 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx144 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx145 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx146 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx147 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx148 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx149 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx15 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx150 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx151 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx152 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx16 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx17 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx18 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx19 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx2 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx20 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx21 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx22 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx23 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx24 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx25 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx26 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx27 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx28 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx29 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx3 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx30 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx31 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx32 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx33 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx34 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx35 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx36 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx37 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx38 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx39 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx4 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx40 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx41 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx42 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx43 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx44 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx45 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx46 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx47 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx48 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx49 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx5 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx50 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx51 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx52 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx53 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx54 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx55 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx56 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx57 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx58 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx59 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx6 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx60 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx61 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx62 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx63 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx64 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx65 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx66 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx67 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx68 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx69 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx7 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx70 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx71 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx72 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx73 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx74 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx75 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx76 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx77 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx78 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx79 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx8 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx80 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx81 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx82 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx83 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx84 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx85 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx86 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx87 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx88 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx89 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx9 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx90 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx91 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx92 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx93 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx94 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx95 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx96 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx97 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx98 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE INDEX kv_store_f009e61d_key_idx99 ON public.kv_store_f009e61d USING btree (key text_pattern_ops);

CREATE UNIQUE INDEX kv_store_f009e61d_pkey ON public.kv_store_f009e61d USING btree (key);

CREATE INDEX kv_store_fabed9c2_key_idx ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx1 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx10 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx11 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx12 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx2 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx3 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx4 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx5 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx6 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx7 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx8 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE INDEX kv_store_fabed9c2_key_idx9 ON public.kv_store_fabed9c2 USING btree (key text_pattern_ops);

CREATE UNIQUE INDEX kv_store_fabed9c2_pkey ON public.kv_store_fabed9c2 USING btree (key);

CREATE UNIQUE INDEX landmark_badges_landmark_id_badge_id_key ON public.landmark_badges USING btree (landmark_id, badge_id);

CREATE UNIQUE INDEX landmark_badges_pkey ON public.landmark_badges USING btree (id);

CREATE UNIQUE INDEX landmark_specialties_code_key ON public.landmark_specialties USING btree (code);

CREATE UNIQUE INDEX landmark_specialties_pkey ON public.landmark_specialties USING btree (id);

CREATE UNIQUE INDEX landmark_specialty_links_pkey ON public.landmark_specialty_links USING btree (landmark_id, landmark_specialty_id);

CREATE UNIQUE INDEX landmark_types_code_key ON public.landmark_types USING btree (code);

CREATE UNIQUE INDEX landmark_types_pkey ON public.landmark_types USING btree (id);

CREATE UNIQUE INDEX landmarks_pkey ON public.landmarks USING btree (id);

CREATE UNIQUE INDEX landmarks_unique_test_anchor ON public.landmarks USING btree (name, landmark_vertical);

CREATE UNIQUE INDEX location_checkins_pkey ON public.location_checkins USING btree (id);

CREATE UNIQUE INDEX market_session_locks_pkey ON public.market_session_locks USING btree (id);

CREATE UNIQUE INDEX messages_pkey ON public.messages USING btree (id);

CREATE UNIQUE INDEX moderation_queue_pkey ON public.moderation_queue USING btree (id);

CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id);

CREATE INDEX notifications_user_id_idx ON public.notifications USING btree (user_id, delivered);

CREATE UNIQUE INDEX password_history_pkey ON public.password_history USING btree (id);

CREATE UNIQUE INDEX password_history_user_id_pw_fingerprint_key ON public.password_history USING btree (user_id, pw_fingerprint);

CREATE UNIQUE INDEX provider_badges_pkey ON public.provider_badges USING btree (provider_id, badge_id);

CREATE UNIQUE INDEX provider_compliance_overlays_pkey ON public.provider_compliance_overlays USING btree (provider_id, compliance_code);

CREATE UNIQUE INDEX provider_context_profiles_pkey ON public.provider_context_profiles USING btree (provider_id);

CREATE UNIQUE INDEX provider_employees_pkey ON public.provider_employees USING btree (id);

CREATE UNIQUE INDEX provider_impact_snapshots_pkey ON public.provider_impact_snapshots USING btree (id);

CREATE UNIQUE INDEX provider_institution_specialties_pkey ON public.provider_institution_specialties USING btree (provider_id, institution_specialty_id);

CREATE UNIQUE INDEX provider_kids_mode_overlays_pkey ON public.provider_kids_mode_overlays USING btree (provider_id, kids_code);

CREATE UNIQUE INDEX provider_media_pkey ON public.provider_media USING btree (id);

CREATE UNIQUE INDEX provider_memberships_pkey ON public.provider_memberships USING btree (provider_id, user_id);

CREATE UNIQUE INDEX provider_specialties_pkey ON public.provider_specialties USING btree (provider_id, specialty_id);

CREATE UNIQUE INDEX provider_vendor_specialties_pkey ON public.provider_vendor_specialties USING btree (provider_id, vendor_specialty_id);

CREATE UNIQUE INDEX providers_payment_provider_customer_id_key ON public.providers USING btree (payment_provider_customer_id);

CREATE UNIQUE INDEX providers_pkey ON public.providers USING btree (id);

CREATE UNIQUE INDEX providers_slug_key ON public.providers USING btree (slug);

CREATE UNIQUE INDEX rfqs_pkey ON public.rfqs USING btree (id);

CREATE UNIQUE INDEX seasonal_content_analytics_daily_pkey ON public.seasonal_content_analytics_daily USING btree (content_type, content_id, date);

CREATE UNIQUE INDEX seasonal_crafts_pkey ON public.seasonal_crafts USING btree (id);

CREATE UNIQUE INDEX seasonal_produce_pkey ON public.seasonal_produce USING btree (id);

CREATE UNIQUE INDEX seasonal_recipes_pkey ON public.seasonal_recipes USING btree (id);

CREATE UNIQUE INDEX seasonal_seeds_pkey ON public.seasonal_seeds USING btree (id);

CREATE UNIQUE INDEX specialty_compliance_overlays_pkey ON public.specialty_compliance_overlays USING btree (specialty_code, compliance_code);

CREATE UNIQUE INDEX specialty_kids_mode_overlays_pkey ON public.specialty_kids_mode_overlays USING btree (specialty_code, kids_code);

CREATE UNIQUE INDEX specialty_types_code_key ON public.specialty_types USING btree (code);

CREATE UNIQUE INDEX specialty_vertical_overlays_code_group_key ON public.specialty_vertical_overlays_v1 USING btree (specialty_code, vertical_group);

CREATE UNIQUE INDEX specialty_vertical_overlays_pkey ON public.specialty_vertical_overlays USING btree (specialty_code, vertical_code);

CREATE UNIQUE INDEX specialty_vertical_overlays_uq ON public.specialty_vertical_overlays USING btree (vertical_code, specialty_code);

CREATE UNIQUE INDEX specialty_vertical_overlays_v1_pkey ON public.specialty_vertical_overlays_v1 USING btree (id);

CREATE UNIQUE INDEX user_admin_actions_pkey ON public.user_admin_actions USING btree (id);

CREATE UNIQUE INDEX user_consents_pkey ON public.user_consents USING btree (id);

CREATE INDEX user_consents_user_id_consent_type_idx ON public.user_consents USING btree (user_id, consent_type);

CREATE INDEX user_consents_user_id_consent_type_idx1 ON public.user_consents USING btree (user_id, consent_type);

CREATE UNIQUE INDEX user_devices_pkey ON public.user_devices USING btree (id);

CREATE INDEX user_devices_platform_idx ON public.user_devices USING btree (platform);

CREATE INDEX user_devices_user_id_idx ON public.user_devices USING btree (user_id);

CREATE INDEX user_password_history_user_id_changed_at_idx ON public.user_password_history USING btree (user_id, changed_at);

CREATE UNIQUE INDEX user_tier_memberships_pkey ON public.user_tier_memberships USING btree (id);

CREATE UNIQUE INDEX user_tiers_pkey ON public.user_tiers USING btree (user_id);

CREATE UNIQUE INDEX vendor_analytics_advanced_daily_pkey ON public.vendor_analytics_advanced_daily USING btree (vendor_id, analytics_date);

CREATE UNIQUE INDEX vendor_analytics_basic_daily_pkey ON public.vendor_analytics_basic_daily USING btree (vendor_id, analytics_date);

CREATE UNIQUE INDEX vendor_analytics_daily_pkey ON public.vendor_analytics_daily USING btree (id);

CREATE UNIQUE INDEX vendor_analytics_daily_vendor_day_idx ON public.vendor_analytics_daily USING btree (vendor_id, day);

CREATE UNIQUE INDEX vendor_applications_pkey ON public.vendor_applications USING btree (id);

CREATE INDEX vendor_applications_user_idx ON public.vendor_applications USING btree (user_id);

CREATE UNIQUE INDEX vendor_media_pkey ON public.vendor_media USING btree (id);

CREATE UNIQUE INDEX vendor_specialties_code_key ON public.vendor_specialties USING btree (code);

CREATE UNIQUE INDEX vendor_specialties_pkey ON public.vendor_specialties USING btree (id);

CREATE UNIQUE INDEX vertical_canonical_specialties_uq ON public.vertical_canonical_specialties USING btree (vertical_code, specialty_code);

CREATE UNIQUE INDEX vertical_capability_defaults_pkey ON public.vertical_capability_defaults USING btree (vertical_code, capability_key);

CREATE UNIQUE INDEX vertical_conditions_pkey ON public.vertical_conditions USING btree (vertical_code);

CREATE UNIQUE INDEX vertical_market_requirements_pkey ON public.vertical_market_requirements USING btree (vertical_code, market_code);

CREATE UNIQUE INDEX weather_snapshots_pkey ON public.weather_snapshots USING btree (id);

CREATE UNIQUE INDEX specialty_types_pkey ON public.specialty_types USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS vertical_canonical_specialties_one_default_per_vertical ON public.vertical_canonical_specialties (vertical_code) WHERE (is_default IS TRUE);

alter table "public"."account_deletion_requests" add constraint "account_deletion_requests_pkey" PRIMARY KEY using index "account_deletion_requests_pkey";

alter table "public"."app_settings" add constraint "app_settings_pkey" PRIMARY KEY using index "app_settings_pkey";

alter table "public"."arts_culture_event_context_profiles" add constraint "arts_culture_event_context_profiles_pkey" PRIMARY KEY using index "arts_culture_event_context_profiles_pkey";

alter table "public"."arts_culture_events" add constraint "arts_culture_events_pkey" PRIMARY KEY using index "arts_culture_events_pkey";

alter table "public"."badges" add constraint "badges_pkey" PRIMARY KEY using index "badges_pkey";

alter table "public"."bids" add constraint "bids_pkey" PRIMARY KEY using index "bids_pkey";

alter table "public"."billing_customers" add constraint "billing_customers_pkey" PRIMARY KEY using index "billing_customers_pkey";

alter table "public"."bulk_offer_analytics" add constraint "bulk_offer_analytics_pkey" PRIMARY KEY using index "bulk_offer_analytics_pkey";

alter table "public"."bulk_offers" add constraint "bulk_offers_pkey" PRIMARY KEY using index "bulk_offers_pkey";

alter table "public"."capabilities" add constraint "capabilities_pkey" PRIMARY KEY using index "capabilities_pkey";

alter table "public"."community_nature_spots" add constraint "community_nature_spots_pkey" PRIMARY KEY using index "community_nature_spots_pkey";

alter table "public"."community_programs" add constraint "community_programs_pkey" PRIMARY KEY using index "community_programs_pkey";

alter table "public"."community_specialty_registry" add constraint "community_specialty_registry_pkey" PRIMARY KEY using index "community_specialty_registry_pkey";

alter table "public"."compliance_overlays" add constraint "compliance_overlays_pkey" PRIMARY KEY using index "compliance_overlays_pkey";

alter table "public"."construction_safety_incidents" add constraint "construction_safety_incidents_pkey" PRIMARY KEY using index "construction_safety_incidents_pkey";

alter table "public"."conversation_participants" add constraint "conversation_participants_pkey" PRIMARY KEY using index "conversation_participants_pkey";

alter table "public"."conversations" add constraint "conversations_pkey" PRIMARY KEY using index "conversations_pkey";

alter table "public"."donations" add constraint "donations_pkey" PRIMARY KEY using index "donations_pkey";

alter table "public"."education_field_trips" add constraint "education_field_trips_pkey" PRIMARY KEY using index "education_field_trips_pkey";

alter table "public"."event_analytics_daily" add constraint "event_analytics_daily_pkey" PRIMARY KEY using index "event_analytics_daily_pkey";

alter table "public"."event_badges" add constraint "event_badges_pkey" PRIMARY KEY using index "event_badges_pkey";

alter table "public"."event_context_profiles" add constraint "event_context_profiles_pkey" PRIMARY KEY using index "event_context_profiles_pkey";

alter table "public"."event_registrations" add constraint "event_registrations_pkey" PRIMARY KEY using index "event_registrations_pkey";

alter table "public"."event_specialties" add constraint "event_specialties_pkey" PRIMARY KEY using index "event_specialties_pkey";

alter table "public"."event_specialty_links" add constraint "event_specialty_links_pkey" PRIMARY KEY using index "event_specialty_links_pkey";

alter table "public"."events" add constraint "events_pkey" PRIMARY KEY using index "events_pkey";

alter table "public"."experience_context_profiles" add constraint "experience_context_profiles_pkey" PRIMARY KEY using index "experience_context_profiles_pkey";

alter table "public"."experience_kids_mode_overlays" add constraint "experience_kids_mode_overlays_pkey" PRIMARY KEY using index "experience_kids_mode_overlays_pkey";

alter table "public"."experience_requests" add constraint "experience_requests_pkey" PRIMARY KEY using index "experience_requests_pkey";

alter table "public"."experience_types" add constraint "experience_types_pkey" PRIMARY KEY using index "experience_types_pkey";

alter table "public"."experiences" add constraint "experiences_pkey" PRIMARY KEY using index "experiences_pkey";

alter table "public"."feed_comments" add constraint "feed_comments_pkey" PRIMARY KEY using index "feed_comments_pkey";

alter table "public"."feed_items" add constraint "feed_items_pkey" PRIMARY KEY using index "feed_items_pkey";

alter table "public"."feed_likes" add constraint "feed_likes_pkey" PRIMARY KEY using index "feed_likes_pkey";

alter table "public"."institution_applications" add constraint "institution_applications_pkey" PRIMARY KEY using index "institution_applications_pkey";

alter table "public"."institution_specialties" add constraint "institution_specialties_pkey" PRIMARY KEY using index "institution_specialties_pkey";

alter table "public"."kids_mode_overlays" add constraint "kids_mode_overlays_pkey" PRIMARY KEY using index "kids_mode_overlays_pkey";

alter table "public"."kv_store_5bb94edf" add constraint "kv_store_5bb94edf_pkey" PRIMARY KEY using index "kv_store_5bb94edf_pkey";

alter table "public"."kv_store_80d2ab6d" add constraint "kv_store_80d2ab6d_pkey" PRIMARY KEY using index "kv_store_80d2ab6d_pkey";

alter table "public"."kv_store_9ca868c2" add constraint "kv_store_9ca868c2_pkey" PRIMARY KEY using index "kv_store_9ca868c2_pkey";

alter table "public"."kv_store_d3ca0863" add constraint "kv_store_d3ca0863_pkey" PRIMARY KEY using index "kv_store_d3ca0863_pkey";

alter table "public"."kv_store_f009e61d" add constraint "kv_store_f009e61d_pkey" PRIMARY KEY using index "kv_store_f009e61d_pkey";

alter table "public"."kv_store_fabed9c2" add constraint "kv_store_fabed9c2_pkey" PRIMARY KEY using index "kv_store_fabed9c2_pkey";

alter table "public"."landmark_badges" add constraint "landmark_badges_pkey" PRIMARY KEY using index "landmark_badges_pkey";

alter table "public"."landmark_specialties" add constraint "landmark_specialties_pkey" PRIMARY KEY using index "landmark_specialties_pkey";

alter table "public"."landmark_specialty_links" add constraint "landmark_specialty_links_pkey" PRIMARY KEY using index "landmark_specialty_links_pkey";

alter table "public"."landmark_types" add constraint "landmark_types_pkey" PRIMARY KEY using index "landmark_types_pkey";

alter table "public"."landmarks" add constraint "landmarks_pkey" PRIMARY KEY using index "landmarks_pkey";

alter table "public"."location_checkins" add constraint "location_checkins_pkey" PRIMARY KEY using index "location_checkins_pkey";

alter table "public"."market_session_locks" add constraint "market_session_locks_pkey" PRIMARY KEY using index "market_session_locks_pkey";

alter table "public"."messages" add constraint "messages_pkey" PRIMARY KEY using index "messages_pkey";

alter table "public"."moderation_queue" add constraint "moderation_queue_pkey" PRIMARY KEY using index "moderation_queue_pkey";

alter table "public"."notifications" add constraint "notifications_pkey" PRIMARY KEY using index "notifications_pkey";

alter table "public"."password_history" add constraint "password_history_pkey" PRIMARY KEY using index "password_history_pkey";

alter table "public"."provider_badges" add constraint "provider_badges_pkey" PRIMARY KEY using index "provider_badges_pkey";

alter table "public"."provider_compliance_overlays" add constraint "provider_compliance_overlays_pkey" PRIMARY KEY using index "provider_compliance_overlays_pkey";

alter table "public"."provider_context_profiles" add constraint "provider_context_profiles_pkey" PRIMARY KEY using index "provider_context_profiles_pkey";

alter table "public"."provider_employees" add constraint "provider_employees_pkey" PRIMARY KEY using index "provider_employees_pkey";

alter table "public"."provider_impact_snapshots" add constraint "provider_impact_snapshots_pkey" PRIMARY KEY using index "provider_impact_snapshots_pkey";

alter table "public"."provider_institution_specialties" add constraint "provider_institution_specialties_pkey" PRIMARY KEY using index "provider_institution_specialties_pkey";

alter table "public"."provider_kids_mode_overlays" add constraint "provider_kids_mode_overlays_pkey" PRIMARY KEY using index "provider_kids_mode_overlays_pkey";

alter table "public"."provider_media" add constraint "provider_media_pkey" PRIMARY KEY using index "provider_media_pkey";

alter table "public"."provider_memberships" add constraint "provider_memberships_pkey" PRIMARY KEY using index "provider_memberships_pkey";

alter table "public"."provider_specialties" add constraint "provider_specialties_pkey" PRIMARY KEY using index "provider_specialties_pkey";

alter table "public"."provider_vendor_specialties" add constraint "provider_vendor_specialties_pkey" PRIMARY KEY using index "provider_vendor_specialties_pkey";

alter table "public"."providers" add constraint "providers_pkey" PRIMARY KEY using index "providers_pkey";

alter table "public"."rfqs" add constraint "rfqs_pkey" PRIMARY KEY using index "rfqs_pkey";

alter table "public"."seasonal_content_analytics_daily" add constraint "seasonal_content_analytics_daily_pkey" PRIMARY KEY using index "seasonal_content_analytics_daily_pkey";

alter table "public"."seasonal_crafts" add constraint "seasonal_crafts_pkey" PRIMARY KEY using index "seasonal_crafts_pkey";

alter table "public"."seasonal_produce" add constraint "seasonal_produce_pkey" PRIMARY KEY using index "seasonal_produce_pkey";

alter table "public"."seasonal_recipes" add constraint "seasonal_recipes_pkey" PRIMARY KEY using index "seasonal_recipes_pkey";

alter table "public"."seasonal_seeds" add constraint "seasonal_seeds_pkey" PRIMARY KEY using index "seasonal_seeds_pkey";

alter table "public"."specialty_compliance_overlays" add constraint "specialty_compliance_overlays_pkey" PRIMARY KEY using index "specialty_compliance_overlays_pkey";

alter table "public"."specialty_kids_mode_overlays" add constraint "specialty_kids_mode_overlays_pkey" PRIMARY KEY using index "specialty_kids_mode_overlays_pkey";

alter table "public"."specialty_vertical_overlays" add constraint "specialty_vertical_overlays_pkey" PRIMARY KEY using index "specialty_vertical_overlays_pkey";

alter table "public"."specialty_vertical_overlays_v1" add constraint "specialty_vertical_overlays_v1_pkey" PRIMARY KEY using index "specialty_vertical_overlays_v1_pkey";

alter table "public"."user_admin_actions" add constraint "user_admin_actions_pkey" PRIMARY KEY using index "user_admin_actions_pkey";

alter table "public"."user_consents" add constraint "user_consents_pkey" PRIMARY KEY using index "user_consents_pkey";

alter table "public"."user_devices" add constraint "user_devices_pkey" PRIMARY KEY using index "user_devices_pkey";

alter table "public"."user_tier_memberships" add constraint "user_tier_memberships_pkey" PRIMARY KEY using index "user_tier_memberships_pkey";

alter table "public"."user_tiers" add constraint "user_tiers_pkey" PRIMARY KEY using index "user_tiers_pkey";

alter table "public"."vendor_analytics_advanced_daily" add constraint "vendor_analytics_advanced_daily_pkey" PRIMARY KEY using index "vendor_analytics_advanced_daily_pkey";

alter table "public"."vendor_analytics_basic_daily" add constraint "vendor_analytics_basic_daily_pkey" PRIMARY KEY using index "vendor_analytics_basic_daily_pkey";

alter table "public"."vendor_analytics_daily" add constraint "vendor_analytics_daily_pkey" PRIMARY KEY using index "vendor_analytics_daily_pkey";

alter table "public"."vendor_applications" add constraint "vendor_applications_pkey" PRIMARY KEY using index "vendor_applications_pkey";

alter table "public"."vendor_media" add constraint "vendor_media_pkey" PRIMARY KEY using index "vendor_media_pkey";

alter table "public"."vendor_specialties" add constraint "vendor_specialties_pkey" PRIMARY KEY using index "vendor_specialties_pkey";

alter table "public"."vertical_capability_defaults" add constraint "vertical_capability_defaults_pkey" PRIMARY KEY using index "vertical_capability_defaults_pkey";

alter table "public"."vertical_conditions" add constraint "vertical_conditions_pkey" PRIMARY KEY using index "vertical_conditions_pkey";

alter table "public"."vertical_market_requirements" add constraint "vertical_market_requirements_pkey" PRIMARY KEY using index "vertical_market_requirements_pkey";

alter table "public"."weather_snapshots" add constraint "weather_snapshots_pkey" PRIMARY KEY using index "weather_snapshots_pkey";

alter table "public"."specialty_types" add constraint "specialty_types_pkey" PRIMARY KEY using index "specialty_types_pkey";

alter table "public"."account_deletion_requests" add constraint "account_deletion_requests_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text]))) not valid;

alter table "public"."account_deletion_requests" validate constraint "account_deletion_requests_status_check";

alter table "public"."account_deletion_requests" add constraint "account_deletion_requests_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."account_deletion_requests" validate constraint "account_deletion_requests_user_id_fkey";

alter table "public"."arts_culture_event_context_profiles" add constraint "arts_culture_event_context_profiles_arts_culture_event_id_fkey" FOREIGN KEY (arts_culture_event_id) REFERENCES public.arts_culture_events(id) ON DELETE CASCADE not valid;

alter table "public"."arts_culture_event_context_profiles" validate constraint "arts_culture_event_context_profiles_arts_culture_event_id_fkey";

alter table "public"."arts_culture_events" add constraint "arts_culture_events_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."arts_culture_events" validate constraint "arts_culture_events_provider_id_fkey";

alter table "public"."badges" add constraint "badges_code_key" UNIQUE using index "badges_code_key";

alter table "public"."bids" add constraint "bids_rfq_id_fkey" FOREIGN KEY (rfq_id) REFERENCES public.rfqs(id) ON DELETE CASCADE not valid;

alter table "public"."bids" validate constraint "bids_rfq_id_fkey";

alter table "public"."bids" add constraint "bids_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text, 'withdrawn'::text]))) not valid;

alter table "public"."bids" validate constraint "bids_status_check";

alter table "public"."bids" add constraint "bids_vendor_id_fkey" FOREIGN KEY (vendor_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."bids" validate constraint "bids_vendor_id_fkey";

alter table "public"."bids" add constraint "bids_vertical_code_fkey" FOREIGN KEY (vertical_code) REFERENCES public.canonical_verticals(vertical_code) not valid;

alter table "public"."bids" validate constraint "bids_vertical_code_fkey";

alter table "public"."billing_customers" add constraint "billing_customers_stripe_customer_id_key" UNIQUE using index "billing_customers_stripe_customer_id_key";

alter table "public"."billing_customers" add constraint "billing_customers_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."billing_customers" validate constraint "billing_customers_user_id_fkey";

alter table "public"."bulk_offer_analytics" add constraint "bulk_offer_analytics_offer_id_fkey" FOREIGN KEY (offer_id) REFERENCES public.bulk_offers(id) ON DELETE CASCADE not valid;

alter table "public"."bulk_offer_analytics" validate constraint "bulk_offer_analytics_offer_id_fkey";

alter table "public"."bulk_offer_analytics" add constraint "bulk_offer_analytics_vendor_user_id_fkey" FOREIGN KEY (vendor_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."bulk_offer_analytics" validate constraint "bulk_offer_analytics_vendor_user_id_fkey";

alter table "public"."bulk_offers" add constraint "bulk_offers_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) not valid;

alter table "public"."bulk_offers" validate constraint "bulk_offers_created_by_fkey";

alter table "public"."bulk_offers" add constraint "bulk_offers_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."bulk_offers" validate constraint "bulk_offers_provider_id_fkey";

alter table "public"."bulk_offers" add constraint "bulk_offers_vertical_code_fkey" FOREIGN KEY (vertical_code) REFERENCES public.canonical_verticals(vertical_code) not valid;

alter table "public"."bulk_offers" validate constraint "bulk_offers_vertical_code_fkey";

alter table "public"."canonical_verticals" add constraint "canonical_verticals_default_specialty_fkey" FOREIGN KEY (default_specialty) REFERENCES public.specialty_types(code) not valid;

alter table "public"."canonical_verticals" validate constraint "canonical_verticals_default_specialty_fkey";

alter table "public"."community_nature_spots" add constraint "community_nature_spots_landmark_id_fkey" FOREIGN KEY (landmark_id) REFERENCES public.landmarks(id) not valid;

alter table "public"."community_nature_spots" validate constraint "community_nature_spots_landmark_id_fkey";

alter table "public"."community_nature_spots" add constraint "community_nature_spots_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) not valid;

alter table "public"."community_nature_spots" validate constraint "community_nature_spots_provider_id_fkey";

alter table "public"."community_programs" add constraint "community_programs_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."community_programs" validate constraint "community_programs_provider_id_fkey";

alter table "public"."community_specialty_registry" add constraint "community_specialty_registry_slug_key" UNIQUE using index "community_specialty_registry_slug_key";

alter table "public"."compliance_overlays" add constraint "compliance_overlays_code_key" UNIQUE using index "compliance_overlays_code_key";

alter table "public"."construction_safety_incidents" add constraint "construction_safety_incidents_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) not valid;

alter table "public"."construction_safety_incidents" validate constraint "construction_safety_incidents_provider_id_fkey";

alter table "public"."construction_safety_incidents" add constraint "construction_safety_incidents_reported_by_fkey" FOREIGN KEY (reported_by) REFERENCES auth.users(id) not valid;

alter table "public"."construction_safety_incidents" validate constraint "construction_safety_incidents_reported_by_fkey";

alter table "public"."construction_safety_incidents" add constraint "construction_safety_incidents_severity_check" CHECK ((severity = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text]))) not valid;

alter table "public"."construction_safety_incidents" validate constraint "construction_safety_incidents_severity_check";

alter table "public"."construction_safety_incidents" add constraint "construction_safety_incidents_status_check" CHECK ((status = ANY (ARRAY['logged'::text, 'investigating'::text, 'resolved'::text]))) not valid;

alter table "public"."construction_safety_incidents" validate constraint "construction_safety_incidents_status_check";

alter table "public"."conversation_participants" add constraint "conversation_participants_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE not valid;

alter table "public"."conversation_participants" validate constraint "conversation_participants_conversation_id_fkey";

alter table "public"."conversation_participants" add constraint "conversation_participants_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."conversation_participants" validate constraint "conversation_participants_user_id_fkey";

alter table "public"."conversations" add constraint "conversations_bid_id_fkey" FOREIGN KEY (bid_id) REFERENCES public.bids(id) ON DELETE SET NULL not valid;

alter table "public"."conversations" validate constraint "conversations_bid_id_fkey";

alter table "public"."conversations" add constraint "conversations_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."conversations" validate constraint "conversations_created_by_fkey";

alter table "public"."conversations" add constraint "conversations_rfq_id_fkey" FOREIGN KEY (rfq_id) REFERENCES public.rfqs(id) ON DELETE SET NULL not valid;

alter table "public"."conversations" validate constraint "conversations_rfq_id_fkey";

alter table "public"."donations" add constraint "donations_amount_cents_check" CHECK ((amount_cents > 0)) not valid;

alter table "public"."donations" validate constraint "donations_amount_cents_check";

alter table "public"."donations" add constraint "donations_donor_user_id_fkey" FOREIGN KEY (donor_user_id) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."donations" validate constraint "donations_donor_user_id_fkey";

alter table "public"."donations" add constraint "donations_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."donations" validate constraint "donations_provider_id_fkey";

alter table "public"."education_field_trips" add constraint "education_field_trips_landmark_id_fkey" FOREIGN KEY (landmark_id) REFERENCES public.landmarks(id) not valid;

alter table "public"."education_field_trips" validate constraint "education_field_trips_landmark_id_fkey";

alter table "public"."education_field_trips" add constraint "education_field_trips_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."education_field_trips" validate constraint "education_field_trips_provider_id_fkey";

alter table "public"."event_analytics_daily" add constraint "event_analytics_daily_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;

alter table "public"."event_analytics_daily" validate constraint "event_analytics_daily_event_id_fkey";

alter table "public"."event_analytics_daily" add constraint "event_analytics_daily_event_id_stat_date_key" UNIQUE using index "event_analytics_daily_event_id_stat_date_key";

alter table "public"."event_analytics_daily" add constraint "event_analytics_daily_vendor_user_id_fkey" FOREIGN KEY (vendor_user_id) REFERENCES auth.users(id) not valid;

alter table "public"."event_analytics_daily" validate constraint "event_analytics_daily_vendor_user_id_fkey";

alter table "public"."event_badges" add constraint "event_badges_badge_id_fkey" FOREIGN KEY (badge_id) REFERENCES public.badges(id) ON DELETE CASCADE not valid;

alter table "public"."event_badges" validate constraint "event_badges_badge_id_fkey";

alter table "public"."event_badges" add constraint "event_badges_event_id_badge_id_key" UNIQUE using index "event_badges_event_id_badge_id_key";

alter table "public"."event_badges" add constraint "event_badges_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;

alter table "public"."event_badges" validate constraint "event_badges_event_id_fkey";

alter table "public"."event_context_profiles" add constraint "event_context_profiles_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;

alter table "public"."event_context_profiles" validate constraint "event_context_profiles_event_id_fkey";

alter table "public"."event_registrations" add constraint "event_registrations_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;

alter table "public"."event_registrations" validate constraint "event_registrations_event_id_fkey";

alter table "public"."event_registrations" add constraint "event_registrations_role_check" CHECK ((role = ANY (ARRAY['volunteer'::text, 'student'::text, 'attendee'::text, 'chaperone'::text]))) not valid;

alter table "public"."event_registrations" validate constraint "event_registrations_role_check";

alter table "public"."event_registrations" add constraint "event_registrations_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'cancelled'::text]))) not valid;

alter table "public"."event_registrations" validate constraint "event_registrations_status_check";

alter table "public"."event_registrations" add constraint "event_registrations_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."event_registrations" validate constraint "event_registrations_user_id_fkey";

alter table "public"."event_specialties" add constraint "event_specialties_code_key" UNIQUE using index "event_specialties_code_key";

alter table "public"."event_specialty_links" add constraint "event_specialty_links_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;

alter table "public"."event_specialty_links" validate constraint "event_specialty_links_event_id_fkey";

alter table "public"."event_specialty_links" add constraint "event_specialty_links_event_specialty_id_fkey" FOREIGN KEY (event_specialty_id) REFERENCES public.event_specialties(id) ON DELETE CASCADE not valid;

alter table "public"."event_specialty_links" validate constraint "event_specialty_links_event_specialty_id_fkey";

alter table "public"."events" add constraint "events_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) not valid;

alter table "public"."events" validate constraint "events_created_by_fkey";

alter table "public"."events" add constraint "events_event_type_check" CHECK ((event_type = ANY (ARRAY['volunteer'::text, 'field_trip'::text, 'educational'::text, 'community'::text, 'seasonal'::text, 'holiday'::text]))) not valid;

alter table "public"."events" validate constraint "events_event_type_check";

alter table "public"."events" add constraint "events_large_scale_requires_host_institution" CHECK ((NOT ((event_type = 'volunteer'::text) AND (COALESCE(is_large_scale_volunteer, false) = true) AND (COALESCE(requires_institutional_partner, false) = true) AND (host_institution_id IS NULL)))) not valid;

alter table "public"."events" validate constraint "events_large_scale_requires_host_institution";

alter table "public"."events" add constraint "events_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text, 'cancelled'::text]))) not valid;

alter table "public"."events" validate constraint "events_status_check";

alter table "public"."experience_context_profiles" add constraint "experience_context_profiles_difficulty_level_check" CHECK ((difficulty_level = ANY (ARRAY['easy'::text, 'moderate'::text, 'challenging'::text, 'high_adventure'::text]))) not valid;

alter table "public"."experience_context_profiles" validate constraint "experience_context_profiles_difficulty_level_check";

alter table "public"."experience_context_profiles" add constraint "experience_context_profiles_experience_id_fkey" FOREIGN KEY (experience_id) REFERENCES public.experiences(id) ON DELETE CASCADE not valid;

alter table "public"."experience_context_profiles" validate constraint "experience_context_profiles_experience_id_fkey";

alter table "public"."experience_kids_mode_overlays" add constraint "experience_kids_mode_overlays_experience_code_fkey" FOREIGN KEY (experience_code) REFERENCES public.experience_types(code) ON DELETE CASCADE not valid;

alter table "public"."experience_kids_mode_overlays" validate constraint "experience_kids_mode_overlays_experience_code_fkey";

alter table "public"."experience_kids_mode_overlays" add constraint "experience_kids_mode_overlays_kids_code_fkey" FOREIGN KEY (kids_code) REFERENCES public.kids_mode_overlays(code) ON DELETE CASCADE not valid;

alter table "public"."experience_kids_mode_overlays" validate constraint "experience_kids_mode_overlays_kids_code_fkey";

alter table "public"."experience_requests" add constraint "experience_requests_experience_id_fkey" FOREIGN KEY (experience_id) REFERENCES public.experiences(id) ON DELETE CASCADE not valid;

alter table "public"."experience_requests" validate constraint "experience_requests_experience_id_fkey";

alter table "public"."experience_requests" add constraint "experience_requests_institution_user_id_fkey" FOREIGN KEY (institution_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."experience_requests" validate constraint "experience_requests_institution_user_id_fkey";

alter table "public"."experience_types" add constraint "experience_types_code_key" UNIQUE using index "experience_types_code_key";

alter table "public"."experiences" add constraint "experiences_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."experiences" validate constraint "experiences_provider_id_fkey";

alter table "public"."feed_comments" add constraint "feed_comments_feed_id_fkey" FOREIGN KEY (feed_id) REFERENCES public.feed_items(id) ON DELETE CASCADE not valid;

alter table "public"."feed_comments" validate constraint "feed_comments_feed_id_fkey";

alter table "public"."feed_comments" add constraint "feed_comments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."feed_comments" validate constraint "feed_comments_user_id_fkey";

alter table "public"."feed_items" add constraint "feed_items_author_id_fkey" FOREIGN KEY (author_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."feed_items" validate constraint "feed_items_author_id_fkey";

alter table "public"."feed_items" add constraint "feed_items_author_role_check" CHECK ((author_role = ANY (ARRAY['vendor'::text, 'institution'::text, 'community'::text]))) not valid;

alter table "public"."feed_items" validate constraint "feed_items_author_role_check";

alter table "public"."feed_likes" add constraint "feed_likes_feed_id_fkey" FOREIGN KEY (feed_id) REFERENCES public.feed_items(id) ON DELETE CASCADE not valid;

alter table "public"."feed_likes" validate constraint "feed_likes_feed_id_fkey";

alter table "public"."feed_likes" add constraint "feed_likes_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."feed_likes" validate constraint "feed_likes_user_id_fkey";

alter table "public"."institution_applications" add constraint "institution_applications_decided_by_fkey" FOREIGN KEY (decided_by) REFERENCES auth.users(id) not valid;

alter table "public"."institution_applications" validate constraint "institution_applications_decided_by_fkey";

alter table "public"."institution_applications" add constraint "institution_applications_moderation_id_fkey" FOREIGN KEY (moderation_id) REFERENCES public.moderation_queue(id) not valid;

alter table "public"."institution_applications" validate constraint "institution_applications_moderation_id_fkey";

alter table "public"."institution_applications" add constraint "institution_applications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."institution_applications" validate constraint "institution_applications_user_id_fkey";

alter table "public"."institution_specialties" add constraint "institution_specialties_code_key" UNIQUE using index "institution_specialties_code_key";

alter table "public"."kids_mode_overlays" add constraint "kids_mode_overlays_code_key" UNIQUE using index "kids_mode_overlays_code_key";

alter table "public"."landmark_badges" add constraint "landmark_badges_badge_id_fkey" FOREIGN KEY (badge_id) REFERENCES public.badges(id) ON DELETE CASCADE not valid;

alter table "public"."landmark_badges" validate constraint "landmark_badges_badge_id_fkey";

alter table "public"."landmark_badges" add constraint "landmark_badges_landmark_id_badge_id_key" UNIQUE using index "landmark_badges_landmark_id_badge_id_key";

alter table "public"."landmark_badges" add constraint "landmark_badges_landmark_id_fkey" FOREIGN KEY (landmark_id) REFERENCES public.landmarks(id) ON DELETE CASCADE not valid;

alter table "public"."landmark_badges" validate constraint "landmark_badges_landmark_id_fkey";

alter table "public"."landmark_specialties" add constraint "landmark_specialties_code_key" UNIQUE using index "landmark_specialties_code_key";

alter table "public"."landmark_specialty_links" add constraint "landmark_specialty_links_landmark_id_fkey" FOREIGN KEY (landmark_id) REFERENCES public.landmarks(id) ON DELETE CASCADE not valid;

alter table "public"."landmark_specialty_links" validate constraint "landmark_specialty_links_landmark_id_fkey";

alter table "public"."landmark_specialty_links" add constraint "landmark_specialty_links_landmark_specialty_id_fkey" FOREIGN KEY (landmark_specialty_id) REFERENCES public.landmark_specialties(id) ON DELETE CASCADE not valid;

alter table "public"."landmark_specialty_links" validate constraint "landmark_specialty_links_landmark_specialty_id_fkey";

alter table "public"."landmark_types" add constraint "landmark_types_code_key" UNIQUE using index "landmark_types_code_key";

alter table "public"."landmarks" add constraint "landmarks_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) not valid;

alter table "public"."landmarks" validate constraint "landmarks_created_by_fkey";

alter table "public"."landmarks" add constraint "landmarks_landmark_type_check" CHECK ((landmark_type = ANY (ARRAY['historical'::text, 'cultural'::text, 'educational'::text, 'religious'::text, 'natural'::text, 'infrastructure'::text]))) not valid;

alter table "public"."landmarks" validate constraint "landmarks_landmark_type_check";

alter table "public"."landmarks" add constraint "landmarks_unique_test_anchor" UNIQUE using index "landmarks_unique_test_anchor";

alter table "public"."landmarks" add constraint "landmarks_vertical_fkey" FOREIGN KEY (landmark_vertical) REFERENCES public.canonical_verticals(vertical_code) not valid;

alter table "public"."landmarks" validate constraint "landmarks_vertical_fkey";

alter table "public"."location_checkins" add constraint "location_checkins_landmark_id_fkey" FOREIGN KEY (landmark_id) REFERENCES public.landmarks(id) not valid;

alter table "public"."location_checkins" validate constraint "location_checkins_landmark_id_fkey";

alter table "public"."location_checkins" add constraint "location_checkins_one_target_chk" CHECK ((((provider_id IS NOT NULL) AND (landmark_id IS NULL)) OR ((provider_id IS NULL) AND (landmark_id IS NOT NULL)))) not valid;

alter table "public"."location_checkins" validate constraint "location_checkins_one_target_chk";

alter table "public"."location_checkins" add constraint "location_checkins_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) not valid;

alter table "public"."location_checkins" validate constraint "location_checkins_provider_id_fkey";

alter table "public"."market_session_locks" add constraint "market_session_locks_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."market_session_locks" validate constraint "market_session_locks_user_id_fkey";

alter table "public"."messages" add constraint "messages_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "messages_conversation_id_fkey";

alter table "public"."messages" add constraint "messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "messages_sender_id_fkey";

alter table "public"."moderation_queue" add constraint "moderation_queue_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) not valid;

alter table "public"."moderation_queue" validate constraint "moderation_queue_reviewed_by_fkey";

alter table "public"."moderation_queue" add constraint "moderation_queue_submitted_by_fkey" FOREIGN KEY (submitted_by) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."moderation_queue" validate constraint "moderation_queue_submitted_by_fkey";

alter table "public"."notifications" add constraint "notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."notifications" validate constraint "notifications_user_id_fkey";

alter table "public"."password_history" add constraint "password_history_user_id_pw_fingerprint_key" UNIQUE using index "password_history_user_id_pw_fingerprint_key";

alter table "public"."provider_badges" add constraint "provider_badges_badge_id_fkey" FOREIGN KEY (badge_id) REFERENCES public.badges(id) ON DELETE CASCADE not valid;

alter table "public"."provider_badges" validate constraint "provider_badges_badge_id_fkey";

alter table "public"."provider_badges" add constraint "provider_badges_granted_by_fkey" FOREIGN KEY (granted_by) REFERENCES auth.users(id) not valid;

alter table "public"."provider_badges" validate constraint "provider_badges_granted_by_fkey";

alter table "public"."provider_badges" add constraint "provider_badges_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_badges" validate constraint "provider_badges_provider_id_fkey";

alter table "public"."provider_compliance_overlays" add constraint "provider_compliance_overlays_compliance_code_fkey" FOREIGN KEY (compliance_code) REFERENCES public.compliance_overlays(code) not valid;

alter table "public"."provider_compliance_overlays" validate constraint "provider_compliance_overlays_compliance_code_fkey";

alter table "public"."provider_compliance_overlays" add constraint "provider_compliance_overlays_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_compliance_overlays" validate constraint "provider_compliance_overlays_provider_id_fkey";

alter table "public"."provider_context_profiles" add constraint "provider_context_profiles_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_context_profiles" validate constraint "provider_context_profiles_provider_id_fkey";

alter table "public"."provider_employees" add constraint "provider_employees_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_employees" validate constraint "provider_employees_provider_id_fkey";

alter table "public"."provider_impact_snapshots" add constraint "provider_impact_snapshots_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_impact_snapshots" validate constraint "provider_impact_snapshots_provider_id_fkey";

alter table "public"."provider_institution_specialties" add constraint "provider_institution_specialties_institution_specialty_id_fkey" FOREIGN KEY (institution_specialty_id) REFERENCES public.institution_specialties(id) ON DELETE CASCADE not valid;

alter table "public"."provider_institution_specialties" validate constraint "provider_institution_specialties_institution_specialty_id_fkey";

alter table "public"."provider_institution_specialties" add constraint "provider_institution_specialties_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_institution_specialties" validate constraint "provider_institution_specialties_provider_id_fkey";

alter table "public"."provider_kids_mode_overlays" add constraint "provider_kids_mode_overlays_kids_code_fkey" FOREIGN KEY (kids_code) REFERENCES public.kids_mode_overlays(code) not valid;

alter table "public"."provider_kids_mode_overlays" validate constraint "provider_kids_mode_overlays_kids_code_fkey";

alter table "public"."provider_kids_mode_overlays" add constraint "provider_kids_mode_overlays_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_kids_mode_overlays" validate constraint "provider_kids_mode_overlays_provider_id_fkey";

alter table "public"."provider_media" add constraint "provider_media_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_media" validate constraint "provider_media_provider_id_fkey";

alter table "public"."provider_memberships" add constraint "provider_memberships_membership_role_check" CHECK ((membership_role = ANY (ARRAY['owner'::text, 'admin'::text, 'manager'::text, 'staff'::text, 'viewer'::text]))) not valid;

alter table "public"."provider_memberships" validate constraint "provider_memberships_membership_role_check";

alter table "public"."provider_specialties" add constraint "provider_specialties_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_specialties" validate constraint "provider_specialties_provider_id_fkey";

alter table "public"."provider_specialties" add constraint "provider_specialties_specialty_id_fkey" FOREIGN KEY (specialty_id) REFERENCES public.community_specialty_registry(id) ON DELETE CASCADE not valid;

alter table "public"."provider_specialties" validate constraint "provider_specialties_specialty_id_fkey";

alter table "public"."provider_vendor_specialties" add constraint "provider_vendor_specialties_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."provider_vendor_specialties" validate constraint "provider_vendor_specialties_provider_id_fkey";

alter table "public"."provider_vendor_specialties" add constraint "provider_vendor_specialties_vendor_specialty_id_fkey" FOREIGN KEY (vendor_specialty_id) REFERENCES public.vendor_specialties(id) ON DELETE CASCADE not valid;

alter table "public"."provider_vendor_specialties" validate constraint "provider_vendor_specialties_vendor_specialty_id_fkey";

alter table "public"."providers" add constraint "providers_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES auth.users(id) not valid;

alter table "public"."providers" validate constraint "providers_owner_user_id_fkey";

alter table "public"."providers" add constraint "providers_payment_provider_customer_id_key" UNIQUE using index "providers_payment_provider_customer_id_key";

alter table "public"."providers" add constraint "providers_primary_vertical_fkey" FOREIGN KEY (primary_vertical) REFERENCES public.canonical_verticals(vertical_code) not valid;

alter table "public"."providers" validate constraint "providers_primary_vertical_fkey";

alter table "public"."providers" add constraint "providers_primary_vertical_not_blank_chk" CHECK (((primary_vertical IS NULL) OR (btrim(primary_vertical) <> ''::text))) not valid;

alter table "public"."providers" validate constraint "providers_primary_vertical_not_blank_chk";

alter table "public"."providers" add constraint "providers_sanctuary_agriculture_only" CHECK (((specialty <> 'sanctuary'::text) OR (primary_vertical = 'AGRICULTURE_FOOD'::text))) not valid;

alter table "public"."providers" validate constraint "providers_sanctuary_agriculture_only";

alter table "public"."providers" add constraint "providers_slug_key" UNIQUE using index "providers_slug_key";

alter table "public"."providers" add constraint "providers_specialty_fkey" FOREIGN KEY (specialty) REFERENCES public.specialty_types(code) not valid;

alter table "public"."providers" validate constraint "providers_specialty_fkey";

alter table "public"."providers" add constraint "providers_specialty_not_blank_chk" CHECK (((specialty IS NULL) OR (btrim(specialty) <> ''::text))) not valid;

alter table "public"."providers" validate constraint "providers_specialty_not_blank_chk";

alter table "public"."providers" add constraint "providers_subscription_status_check" CHECK ((subscription_status = ANY (ARRAY['inactive'::text, 'trialing'::text, 'active'::text, 'past_due'::text, 'canceled'::text]))) not valid;

alter table "public"."providers" validate constraint "providers_subscription_status_check";

alter table "public"."providers" add constraint "providers_subscription_tier_check" CHECK ((subscription_tier = ANY (ARRAY['free'::text, 'premium'::text, 'premium_plus'::text]))) not valid;

alter table "public"."providers" validate constraint "providers_subscription_tier_check";

alter table "public"."providers" add constraint "providers_vertical_check" CHECK (((primary_vertical IS NOT NULL) AND (vertical IS NOT NULL) AND (vertical = primary_vertical))) not valid;

alter table "public"."providers" validate constraint "providers_vertical_check";

alter table "public"."providers" add constraint "providers_vertical_fkey" FOREIGN KEY (vertical) REFERENCES public.canonical_verticals(vertical_code) not valid;

alter table "public"."providers" validate constraint "providers_vertical_fkey";

alter table "public"."providers" add constraint "providers_vertical_matches_primary_vertical" CHECK ((vertical = primary_vertical)) not valid;

alter table "public"."providers" validate constraint "providers_vertical_matches_primary_vertical";

alter table "public"."providers" add constraint "providers_vertical_not_blank_chk" CHECK (((vertical IS NULL) OR (btrim(vertical) <> ''::text))) not valid;

alter table "public"."providers" validate constraint "providers_vertical_not_blank_chk";

alter table "public"."rfqs" add constraint "rfqs_institution_id_fkey" FOREIGN KEY (institution_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."rfqs" validate constraint "rfqs_institution_id_fkey";

alter table "public"."rfqs" add constraint "rfqs_status_check" CHECK ((status = ANY (ARRAY['open'::text, 'closed'::text, 'cancelled'::text]))) not valid;

alter table "public"."rfqs" validate constraint "rfqs_status_check";

alter table "public"."rfqs" add constraint "rfqs_vertical_code_fkey" FOREIGN KEY (vertical_code) REFERENCES public.canonical_verticals(vertical_code) not valid;

alter table "public"."rfqs" validate constraint "rfqs_vertical_code_fkey";

alter table "public"."seasonal_content_analytics_daily" add constraint "seasonal_content_analytics_daily_content_type_check" CHECK ((content_type = ANY (ARRAY['produce'::text, 'seeds'::text, 'craft'::text, 'recipe'::text]))) not valid;

alter table "public"."seasonal_content_analytics_daily" validate constraint "seasonal_content_analytics_daily_content_type_check";

alter table "public"."seasonal_crafts" add constraint "seasonal_crafts_craft_type_check" CHECK ((craft_type = ANY (ARRAY['indoor'::text, 'outdoor'::text]))) not valid;

alter table "public"."seasonal_crafts" validate constraint "seasonal_crafts_craft_type_check";

alter table "public"."seasonal_crafts" add constraint "seasonal_crafts_difficulty_check" CHECK ((difficulty = ANY (ARRAY['very_easy'::text, 'easy'::text, 'medium'::text, 'advanced'::text]))) not valid;

alter table "public"."seasonal_crafts" validate constraint "seasonal_crafts_difficulty_check";

alter table "public"."seasonal_crafts" add constraint "seasonal_crafts_month_check" CHECK (((month >= 1) AND (month <= 12))) not valid;

alter table "public"."seasonal_crafts" validate constraint "seasonal_crafts_month_check";

alter table "public"."seasonal_produce" add constraint "seasonal_produce_month_check" CHECK (((month >= 1) AND (month <= 12))) not valid;

alter table "public"."seasonal_produce" validate constraint "seasonal_produce_month_check";

alter table "public"."seasonal_recipes" add constraint "seasonal_recipes_month_check" CHECK (((month >= 1) AND (month <= 12))) not valid;

alter table "public"."seasonal_recipes" validate constraint "seasonal_recipes_month_check";

alter table "public"."seasonal_seeds" add constraint "seasonal_seeds_month_check" CHECK (((month >= 1) AND (month <= 12))) not valid;

alter table "public"."seasonal_seeds" validate constraint "seasonal_seeds_month_check";

alter table "public"."specialty_compliance_overlays" add constraint "specialty_compliance_overlays_compliance_code_fkey" FOREIGN KEY (compliance_code) REFERENCES public.compliance_overlays(code) ON DELETE CASCADE not valid;

alter table "public"."specialty_compliance_overlays" validate constraint "specialty_compliance_overlays_compliance_code_fkey";

alter table "public"."specialty_compliance_overlays" add constraint "specialty_compliance_overlays_specialty_code_fkey" FOREIGN KEY (specialty_code) REFERENCES public.specialty_types(code) ON DELETE CASCADE not valid;

alter table "public"."specialty_compliance_overlays" validate constraint "specialty_compliance_overlays_specialty_code_fkey";

alter table "public"."specialty_governance_group_members" add constraint "specialty_governance_group_members_group_key_fkey" FOREIGN KEY (group_key) REFERENCES public.specialty_governance_groups(group_key) ON DELETE CASCADE not valid;

alter table "public"."specialty_governance_group_members" validate constraint "specialty_governance_group_members_group_key_fkey";

alter table "public"."specialty_governance_group_members" add constraint "specialty_governance_group_members_specialty_not_blank_chk" CHECK ((NULLIF(btrim(specialty_code), ''::text) IS NOT NULL)) not valid;

alter table "public"."specialty_governance_group_members" validate constraint "specialty_governance_group_members_specialty_not_blank_chk";

alter table "public"."specialty_kids_mode_overlays" add constraint "specialty_kids_mode_overlays_kids_code_fkey" FOREIGN KEY (kids_code) REFERENCES public.kids_mode_overlays(code) ON DELETE CASCADE not valid;

alter table "public"."specialty_kids_mode_overlays" validate constraint "specialty_kids_mode_overlays_kids_code_fkey";

alter table "public"."specialty_kids_mode_overlays" add constraint "specialty_kids_mode_overlays_specialty_code_fkey" FOREIGN KEY (specialty_code) REFERENCES public.specialty_types(code) ON DELETE CASCADE not valid;

alter table "public"."specialty_kids_mode_overlays" validate constraint "specialty_kids_mode_overlays_specialty_code_fkey";

alter table "public"."specialty_types" add constraint "specialty_types_code_key" UNIQUE using index "specialty_types_code_key";

alter table "public"."specialty_vertical_overlays" add constraint "specialty_vertical_overlays_specialty_fk" FOREIGN KEY (specialty_code) REFERENCES public.specialty_types(code) ON DELETE CASCADE not valid;

alter table "public"."specialty_vertical_overlays" validate constraint "specialty_vertical_overlays_specialty_fk";

alter table "public"."specialty_vertical_overlays" add constraint "specialty_vertical_overlays_specialty_fkey" FOREIGN KEY (specialty_code) REFERENCES public.specialty_types(code) ON DELETE CASCADE not valid;

alter table "public"."specialty_vertical_overlays" validate constraint "specialty_vertical_overlays_specialty_fkey";

alter table "public"."specialty_vertical_overlays" add constraint "specialty_vertical_overlays_vertical_fk" FOREIGN KEY (vertical_code) REFERENCES public.canonical_verticals(vertical_code) ON DELETE CASCADE not valid;

alter table "public"."specialty_vertical_overlays" validate constraint "specialty_vertical_overlays_vertical_fk";

alter table "public"."specialty_vertical_overlays" add constraint "specialty_vertical_overlays_vertical_fkey" FOREIGN KEY (vertical_code) REFERENCES public.canonical_verticals(vertical_code) ON DELETE CASCADE not valid;

alter table "public"."specialty_vertical_overlays" validate constraint "specialty_vertical_overlays_vertical_fkey";

alter table "public"."specialty_vertical_overlays_v1" add constraint "specialty_vertical_overlays_v1_specialty_code_fkey" FOREIGN KEY (specialty_code) REFERENCES public.specialty_types(code) ON DELETE CASCADE not valid;

alter table "public"."specialty_vertical_overlays_v1" validate constraint "specialty_vertical_overlays_v1_specialty_code_fkey";

alter table "public"."user_admin_actions" add constraint "user_admin_actions_admin_id_fkey" FOREIGN KEY (admin_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_admin_actions" validate constraint "user_admin_actions_admin_id_fkey";

alter table "public"."user_admin_actions" add constraint "user_admin_actions_target_user_id_fkey" FOREIGN KEY (target_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_admin_actions" validate constraint "user_admin_actions_target_user_id_fkey";

alter table "public"."user_consents" add constraint "user_consents_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_consents" validate constraint "user_consents_user_id_fkey";

alter table "public"."user_devices" add constraint "user_devices_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_devices" validate constraint "user_devices_user_id_fkey";

alter table "public"."user_tier_memberships" add constraint "user_tier_memberships_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'canceled'::text, 'expired'::text]))) not valid;

alter table "public"."user_tier_memberships" validate constraint "user_tier_memberships_status_check";

alter table "public"."user_tier_memberships" add constraint "user_tier_memberships_tier_check" CHECK ((tier = ANY (ARRAY['premium'::text, 'premium_plus'::text]))) not valid;

alter table "public"."user_tier_memberships" validate constraint "user_tier_memberships_tier_check";

alter table "public"."user_tiers" add constraint "user_tiers_account_status_chk" CHECK ((account_status = ANY (ARRAY['active'::text, 'suspended'::text, 'soft_deleted'::text]))) not valid;

alter table "public"."user_tiers" validate constraint "user_tiers_account_status_chk";

alter table "public"."user_tiers" add constraint "user_tiers_role_check" CHECK ((role = ANY (ARRAY['vendor'::text, 'institution'::text, 'community'::text, 'admin'::text]))) not valid;

alter table "public"."user_tiers" validate constraint "user_tiers_role_check";

alter table "public"."user_tiers" add constraint "user_tiers_tier_check" CHECK ((tier = ANY (ARRAY['free'::text, 'premium'::text, 'premium_plus'::text]))) not valid;

alter table "public"."user_tiers" validate constraint "user_tiers_tier_check";

alter table "public"."user_tiers" add constraint "user_tiers_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_tiers" validate constraint "user_tiers_user_id_fkey";

alter table "public"."vendor_analytics_advanced_daily" add constraint "vendor_analytics_advanced_daily_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."vendor_analytics_advanced_daily" validate constraint "vendor_analytics_advanced_daily_owner_user_id_fkey";

alter table "public"."vendor_analytics_basic_daily" add constraint "vendor_analytics_basic_daily_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."vendor_analytics_basic_daily" validate constraint "vendor_analytics_basic_daily_owner_user_id_fkey";

alter table "public"."vendor_analytics_daily" add constraint "vendor_analytics_daily_vendor_id_fkey" FOREIGN KEY (vendor_id) REFERENCES public.providers(id) not valid;

alter table "public"."vendor_analytics_daily" validate constraint "vendor_analytics_daily_vendor_id_fkey";

alter table "public"."vendor_applications" add constraint "vendor_applications_decided_by_fkey" FOREIGN KEY (decided_by) REFERENCES auth.users(id) not valid;

alter table "public"."vendor_applications" validate constraint "vendor_applications_decided_by_fkey";

alter table "public"."vendor_applications" add constraint "vendor_applications_moderation_id_fkey" FOREIGN KEY (moderation_id) REFERENCES public.moderation_queue(id) not valid;

alter table "public"."vendor_applications" validate constraint "vendor_applications_moderation_id_fkey";

alter table "public"."vendor_applications" add constraint "vendor_applications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."vendor_applications" validate constraint "vendor_applications_user_id_fkey";

alter table "public"."vendor_media" add constraint "vendor_media_media_type_check" CHECK ((media_type = ANY (ARRAY['image'::text, 'video'::text, 'document'::text]))) not valid;

alter table "public"."vendor_media" validate constraint "vendor_media_media_type_check";

alter table "public"."vendor_media" add constraint "vendor_media_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."vendor_media" validate constraint "vendor_media_owner_user_id_fkey";

alter table "public"."vendor_media" add constraint "vendor_media_visibility_check" CHECK ((visibility = ANY (ARRAY['public'::text, 'protected'::text]))) not valid;

alter table "public"."vendor_media" validate constraint "vendor_media_visibility_check";

alter table "public"."vendor_specialties" add constraint "vendor_specialties_code_key" UNIQUE using index "vendor_specialties_code_key";

alter table "public"."vertical_capability_defaults" add constraint "vertical_capability_defaults_capability_key_fkey" FOREIGN KEY (capability_key) REFERENCES public.capabilities(capability_key) ON DELETE CASCADE not valid;

alter table "public"."vertical_capability_defaults" validate constraint "vertical_capability_defaults_capability_key_fkey";

alter table "public"."vertical_capability_defaults" add constraint "vertical_capability_defaults_vertical_code_fkey" FOREIGN KEY (vertical_code) REFERENCES public.canonical_verticals(vertical_code) ON DELETE CASCADE not valid;

alter table "public"."vertical_capability_defaults" validate constraint "vertical_capability_defaults_vertical_code_fkey";

alter table "public"."vertical_conditions" add constraint "vertical_conditions_vertical_code_fkey" FOREIGN KEY (vertical_code) REFERENCES public.canonical_verticals(vertical_code) ON DELETE CASCADE not valid;

alter table "public"."vertical_conditions" validate constraint "vertical_conditions_vertical_code_fkey";

alter table "public"."vertical_market_requirements" add constraint "vertical_market_requirements_vertical_code_fkey" FOREIGN KEY (vertical_code) REFERENCES public.canonical_verticals(vertical_code) ON UPDATE CASCADE ON DELETE RESTRICT not valid;

alter table "public"."vertical_market_requirements" validate constraint "vertical_market_requirements_vertical_code_fkey";

alter table "public"."weather_snapshots" add constraint "weather_snapshots_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.providers(id) ON DELETE CASCADE not valid;

alter table "public"."weather_snapshots" validate constraint "weather_snapshots_provider_id_fkey";

alter table "public"."weather_snapshots" add constraint "weather_snapshots_risk_level_check" CHECK ((risk_level = ANY (ARRAY['low'::text, 'moderate'::text, 'high'::text, 'extreme'::text]))) not valid;

alter table "public"."weather_snapshots" validate constraint "weather_snapshots_risk_level_check";

alter table "public"."weather_snapshots" add constraint "weather_snapshots_scope_type_check" CHECK ((scope_type = ANY (ARRAY['global'::text, 'region'::text, 'provider'::text, 'institution'::text, 'experience'::text, 'event'::text]))) not valid;

alter table "public"."weather_snapshots" validate constraint "weather_snapshots_scope_type_check";

alter table "public"."weather_snapshots" add constraint "weather_snapshots_vertical_check" CHECK ((vertical = ANY (ARRAY['community'::text, 'education'::text, 'construction'::text, 'arts_culture'::text, 'experiences'::text]))) not valid;

alter table "public"."weather_snapshots" validate constraint "weather_snapshots_vertical_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public._admin_grant_badges_for_provider_internal(p_provider_id uuid, p_badge_codes text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  -- NO is_admin() check here on purpose
  perform public.admin_grant_badges_to_provider(p_provider_id, p_badge_codes);
end;
$function$
;

CREATE OR REPLACE FUNCTION public._admin_grant_default_badges_for_provider_internal(p_provider_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_specialty text;
begin
  select specialty
  into v_specialty
  from public.providers
  where id = p_provider_id;

  if v_specialty is null then
    raise exception 'Provider not found';
  end if;

  -- Always grant VERIFIED_VENDOR
  perform public.admin_grant_badges_to_provider(
    p_provider_id,
    array['VERIFIED_VENDOR']
  );

  -- Specialty-based auto badge
  perform public.admin_grant_badges_to_provider(
    p_provider_id,
    array[upper(replace(v_specialty, ' ', '_'))]
  );

end;
$function$
;

CREATE OR REPLACE FUNCTION public._admin_moderate_submission_internal(moderation_id uuid, new_status text, decision_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  rec record;
  new_mod_status text;
  entity_title text;
begin
  -- 1) Load moderation record
  select *
  into rec
  from public.moderation_queue
  where id = moderation_id
    and status = 'pending';

  if not found then
    raise exception 'Moderation item not found or not pending';
  end if;

  -- 2) Normalize status
  if new_status in ('approved', 'auto_approved') then
    new_mod_status := 'approved';
  elsif new_status = 'rejected' then
    new_mod_status := 'rejected';
  else
    new_mod_status := 'pending_review';
  end if;

  -- 3) Update underlying entity + capture a title
  if rec.entity_type = 'event' then
    update public.events
    set moderation_status = new_mod_status
    where id = rec.entity_id;

    select title
    into entity_title
    from public.events
    where id = rec.entity_id;

  elsif rec.entity_type = 'landmark' then
    update public.landmarks
    set moderation_status = new_mod_status
    where id = rec.entity_id;

    select name
    into entity_title
    from public.landmarks
    where id = rec.entity_id;

  elsif rec.entity_type = 'vendor_application' then
    update public.vendor_applications
    set status     = new_mod_status,
        decided_at = now(),
        decided_by = auth.uid()
    where id = rec.entity_id;

    select org_name
    into entity_title
    from public.vendor_applications
    where id = rec.entity_id;

  elsif rec.entity_type = 'institution_application' then
    update public.institution_applications
    set status     = new_mod_status,
        decided_at = now(),
        decided_by = auth.uid()
    where id = rec.entity_id;

    select org_name
    into entity_title
    from public.institution_applications
    where id = rec.entity_id;
  end if;

  -- 4) Update moderation_queue
  update public.moderation_queue
  set status       = new_status,
      reason       = decision_reason,
      reviewed_at  = now(),
      reviewed_by  = auth.uid()
  where id = moderation_id;

  -- 5) Notifications (reuse your existing helpers)
  if new_status in ('approved', 'auto_approved') then
    perform public.notify_submission_approved(
      rec.submitted_by,
      rec.entity_type,
      rec.entity_id,
      coalesce(entity_title, rec.entity_type)
    );
  elsif new_status = 'rejected' then
    perform public.notify_submission_rejected(
      rec.submitted_by,
      rec.entity_type,
      rec.entity_id,
      coalesce(entity_title, rec.entity_type),
      decision_reason
    );
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION public._capability_allowed_for_provider(p_provider_id uuid, p_capability_key text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(
    -- 1) Specialty override wins
    (select g.is_allowed
       from public.providers p
       join public.specialty_capability_grants g
         on g.specialty_code = p.specialty
      where p.id = p_provider_id
        and g.capability_key = p_capability_key),

    -- 2) Vertical default
    (select d.is_allowed
       from public.providers p
       join public.vertical_capability_defaults d
         on d.vertical_code = coalesce(p.primary_vertical, p.vertical)
      where p.id = p_provider_id
        and d.capability_key = p_capability_key),

    -- 3) Capability default
    (select c.default_allowed
       from public.capabilities c
      where c.capability_key = p_capability_key),

    false
  );
$function$
;

CREATE OR REPLACE FUNCTION public._event_vertical_matches_vendor(p_vendor_id uuid, p_event_vertical text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  select exists (
    select 1
    from public.providers p
    where p.id = p_vendor_id
      and p_event_vertical = coalesce(p.primary_vertical, p.vertical)
  );
$function$
;

CREATE OR REPLACE FUNCTION public._is_owned_provider_with_specialty(p_provider_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.providers p
    where p.id = p_provider_id
      and p.owner_user_id = auth.uid()
      and nullif(btrim(p.specialty), '') is not null
  );
$function$
;

CREATE OR REPLACE FUNCTION public._is_sanctuary_specialty(p_specialty_code text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
      from public.sanctuary_specialties s
     where s.specialty_code = p_specialty_code
  );
$function$
;

CREATE OR REPLACE FUNCTION public._owns_host_vendor(p_vendor_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  select exists (
    select 1
    from public.providers p
    where p.id = p_vendor_id
      and p.owner_user_id = auth.uid()
  );
$function$
;

CREATE OR REPLACE FUNCTION public._owns_verified_host_vendor(p_vendor_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  select exists (
    select 1
    from public.providers p
    where p.id = p_vendor_id
      and p.owner_user_id = auth.uid()
      and coalesce(p.is_verified,false) = true
  );
$function$
;

CREATE OR REPLACE FUNCTION public._provider_effective_vertical(p_vendor_id uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(p.primary_vertical, p.vertical)
  from public.providers p
  where p.id = p_vendor_id;
$function$
;

CREATE OR REPLACE FUNCTION public._provider_has_capability(p_provider_id uuid, p_capability_key text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    public._is_owned_provider_with_specialty(p_provider_id)
    and public._specialty_capability_allowed(public._provider_specialty(p_provider_id), p_capability_key);
$function$
;

CREATE OR REPLACE FUNCTION public._provider_is_verified(p_vendor_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce((select p.is_verified from public.providers p where p.id = p_vendor_id), false);
$function$
;

CREATE OR REPLACE FUNCTION public._provider_owned(p_vendor_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.providers p
    where p.id = p_vendor_id
      and p.owner_user_id = auth.uid()
  );
$function$
;

CREATE OR REPLACE FUNCTION public._provider_specialty(p_provider_id uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select nullif(btrim(p.specialty), '')
  from public.providers p
  where p.id = p_provider_id;
$function$
;

CREATE OR REPLACE FUNCTION public._provider_specialty_code(p_vendor_id uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select p.specialty
  from public.providers p
  where p.id = p_vendor_id;
$function$
;

CREATE OR REPLACE FUNCTION public._touch_vertical_market_requirements_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.account_mode()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce(
    (select nullif(ut.feature_flags->>'mode','')
     from public.user_tiers ut
     where ut.user_id = auth.uid()
     limit 1),
    'adult'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.account_mode(uid uuid)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce(ut.feature_flags->>'account_mode', 'adult')
  from public.user_tiers ut
  where ut.user_id = uid
$function$
;

create or replace view "public"."admin_compliance_registry_v1" as  SELECT id,
    code AS compliance_code,
    label AS compliance_label,
    description
   FROM public.compliance_overlays
  ORDER BY code;


create or replace view "public"."admin_experience_governance_v1" as  SELECT et.code AS experience_code,
    et.label AS experience_label,
    et.requires_waiver,
    et.kids_allowed,
    et.insurance_required,
    et.seasonal_lockable,
    COALESCE(array_agg(DISTINCT ek.kids_code) FILTER (WHERE (ek.kids_code IS NOT NULL)), '{}'::text[]) AS kids_mode_codes
   FROM (public.experience_types et
     LEFT JOIN public.experience_kids_mode_overlays ek ON ((ek.experience_code = et.code)))
  GROUP BY et.code, et.label, et.requires_waiver, et.kids_allowed, et.insurance_required, et.seasonal_lockable;


CREATE OR REPLACE FUNCTION public.admin_get_user_accounts()
 RETURNS SETOF public.admin_user_accounts
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
  select *
  from public.admin_user_accounts
  where public.is_admin();
$function$
;

CREATE OR REPLACE FUNCTION public.admin_grant_badges_to_provider(p_provider_id uuid, p_badge_codes text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_code text;
  v_badge_id uuid;
begin
  -- Only admins may call this
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  foreach v_code in array p_badge_codes loop
    -- Find badge by code
    select id into v_badge_id
    from public.badges
    where code = v_code
    limit 1;

    -- If badge not found, skip
    if v_badge_id is null then
      continue;
    end if;

    -- Avoid duplicates
    insert into public.provider_badges (provider_id, badge_id, granted_by, granted_at)
    values (p_provider_id, v_badge_id, auth.uid(), now())
    on conflict (provider_id, badge_id) do nothing;
  end loop;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_moderate_submission(moderation_id uuid, new_status text, decision_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_admin_id uuid;
  v_entity_type text;
  v_entity_id uuid;
  v_applicant_user_id uuid;
BEGIN
  -- ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ Admin check
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT auth.uid() INTO v_admin_id;

  -- ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ Lock moderation row
  SELECT entity_type, entity_id
  INTO v_entity_type, v_entity_id
  FROM public.moderation_queue
  WHERE id = moderation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Moderation record not found';
  END IF;

  -- ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ Apply status change by entity type
  IF v_entity_type = 'event' THEN
    UPDATE public.events
    SET moderation_status = new_status
    WHERE id = v_entity_id;

  ELSIF v_entity_type = 'landmark' THEN
    UPDATE public.landmarks
    SET moderation_status = new_status
    WHERE id = v_entity_id;

  ELSIF v_entity_type = 'vendor_application' THEN
    IF new_status = 'approved' THEN
      SELECT applicant_user_id
      INTO v_applicant_user_id
      FROM public.vendor_applications
      WHERE id = v_entity_id
      FOR UPDATE;

      INSERT INTO public.providers (name, provider_type, owner_user_id)
      SELECT
        company_name,
        'vendor',
        v_applicant_user_id
      FROM public.vendor_applications
      WHERE id = v_entity_id;
    END IF;

    UPDATE public.vendor_applications
    SET moderation_status = new_status
    WHERE id = v_entity_id;

  ELSIF v_entity_type = 'institution_application' THEN
    IF new_status = 'approved' THEN
      SELECT applicant_user_id
      INTO v_applicant_user_id
      FROM public.institution_applications
      WHERE id = v_entity_id
      FOR UPDATE;

      INSERT INTO public.providers (name, provider_type, owner_user_id)
      SELECT
        institution_name,
        'institution',
        v_applicant_user_id
      FROM public.institution_applications
      WHERE id = v_entity_id;
    END IF;

    UPDATE public.institution_applications
    SET moderation_status = new_status
    WHERE id = v_entity_id;

  ELSE
    RAISE EXCEPTION 'Unsupported entity_type: %', v_entity_type;
  END IF;

  -- ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ Update moderation queue
  UPDATE public.moderation_queue
  SET
    status      = new_status,
    reason      = decision_reason,
    reviewed_at = now(),
    reviewed_by = v_admin_id
  WHERE id = moderation_id;

  -- ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ Notifications
  IF new_status = 'approved' THEN
    PERFORM public.notify_submission_approved(moderation_id);
  ELSIF new_status = 'rejected' THEN
    PERFORM public.notify_submission_rejected(moderation_id);
  END IF;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_set_account_status(target_user uuid, new_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  old_status text;
begin
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  select account_status
  into old_status
  from public.user_tiers
  where user_id = target_user
  limit 1;

  update public.user_tiers
  set account_status = new_status
  where user_id = target_user;

  insert into public.user_admin_actions (
    admin_id,
    target_user_id,
    action_type,
    details
  ) values (
    auth.uid(),
    target_user,
    'set_account_status',
    jsonb_build_object(
      'old_status', old_status,
      'new_status', new_status
    )
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_set_role_tier(target_user uuid, new_role text, new_tier text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  old_role text;
  old_tier text;
begin
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  select role, tier
  into old_role, old_tier
  from public.user_tiers
  where user_id = target_user
  limit 1;

  update public.user_tiers
  set role = new_role,
      tier = new_tier
  where user_id = target_user;

  insert into public.user_admin_actions (
    admin_id,
    target_user_id,
    action_type,
    details
  ) values (
    auth.uid(),
    target_user,
    'set_role_tier',
    jsonb_build_object(
      'old_role', old_role,
      'new_role', new_role,
      'old_tier', old_tier,
      'new_tier', new_tier
    )
  );
end;
$function$
;

create or replace view "public"."admin_specialty_governance_v1" as  SELECT st.code AS specialty_code,
    st.label AS specialty_label,
    st.vertical_group,
    st.requires_compliance,
    st.kids_allowed,
    st.default_visibility,
    COALESCE(array_agg(DISTINCT sco.compliance_code) FILTER (WHERE (sco.compliance_code IS NOT NULL)), '{}'::text[]) AS compliance_codes,
    COALESCE(array_agg(DISTINCT sk.kids_code) FILTER (WHERE (sk.kids_code IS NOT NULL)), '{}'::text[]) AS kids_mode_codes
   FROM ((public.specialty_types st
     LEFT JOIN public.specialty_compliance_overlays sco ON ((sco.specialty_code = st.code)))
     LEFT JOIN public.specialty_kids_mode_overlays sk ON ((sk.specialty_code = st.code)))
  GROUP BY st.code, st.label, st.vertical_group, st.requires_compliance, st.kids_allowed, st.default_visibility;


CREATE OR REPLACE FUNCTION public.admin_update_feature_flags(target_user uuid, new_flags jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  old_flags jsonb;
begin
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  select feature_flags
  into old_flags
  from public.user_tiers
  where user_id = target_user
  limit 1;

  update public.user_tiers
  set feature_flags = new_flags
  where user_id = target_user;

  insert into public.user_admin_actions (
    admin_id,
    target_user_id,
    action_type,
    details
  ) values (
    auth.uid(),
    target_user,
    'update_feature_flags',
    jsonb_build_object(
      'old_flags', old_flags,
      'new_flags', new_flags
    )
  );
end;
$function$
;

create or replace view "public"."admin_user_accounts" as  SELECT u.id AS user_id,
    u.email,
    ut.role,
    ut.tier,
    ut.account_status,
    ut.feature_flags,
    adr.status AS deletion_status,
    adr.requested_at AS deletion_requested_at
   FROM ((auth.users u
     LEFT JOIN public.user_tiers ut ON ((ut.user_id = u.id)))
     LEFT JOIN public.account_deletion_requests adr ON (((adr.user_id = u.id) AND (adr.status = ANY (ARRAY['pending'::text, 'in_progress'::text])))));


create or replace view "public"."adult_volunteer_events_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    event_vertical,
    is_volunteer,
    is_large_scale_volunteer,
    requires_institutional_partner
   FROM public.events e
  WHERE ((status = 'published'::text) AND (moderation_status = 'approved'::text) AND (COALESCE(is_volunteer, false) = true));


CREATE OR REPLACE FUNCTION public.apply_provider_governance_from_specialty(p_provider_id uuid, p_specialty_code text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  DELETE FROM public.provider_compliance_overlays
  WHERE provider_id = p_provider_id;

  DELETE FROM public.provider_kids_mode_overlays
  WHERE provider_id = p_provider_id;

  INSERT INTO public.provider_compliance_overlays (provider_id, compliance_code)
  SELECT
    p_provider_id,
    sco.compliance_code
  FROM public.specialty_compliance_overlays sco
  WHERE sco.specialty_code = p_specialty_code;

  INSERT INTO public.provider_kids_mode_overlays (provider_id, kids_code)
  SELECT
    p_provider_id,
    sk.kids_code
  FROM public.specialty_kids_mode_overlays sk
  WHERE sk.specialty_code = p_specialty_code;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.apply_subscription_features(p_user_id uuid, p_role text, p_tier text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_flags jsonb;
BEGIN
  -- Base: everything off
  v_flags := jsonb_build_object(
    'is_kids_mode',               'false',
    'can_use_bid_marketplace',    'false',
    'can_use_bulk_marketplace',   'false',
    'can_view_basic_analytics',   'false',
    'can_view_advanced_analytics','false'
  );

  IF p_role = 'vendor' OR p_role = 'institution' THEN

    IF p_tier = 'free' THEN
      -- Free: basic analytics only
      v_flags := v_flags
        || jsonb_build_object(
          'can_view_basic_analytics', 'true'
        );

    ELSIF p_tier = 'premium' THEN
      -- Premium: inherits free + bulk marketplace
      v_flags := v_flags
        || jsonb_build_object(
          'can_view_basic_analytics', 'true',
          'can_use_bulk_marketplace', 'true'
        );

    ELSIF p_tier = 'premium_plus' THEN
      -- Premium Plus: inherits premium + bids + advanced analytics
      v_flags := v_flags
        || jsonb_build_object(
          'can_view_basic_analytics',   'true',
          'can_use_bulk_marketplace',   'true',
          'can_use_bid_marketplace',    'true',
          'can_view_advanced_analytics','true'
        );
    END IF;

  ELSIF p_role = 'admin' THEN
    -- Admin: everything true
    v_flags := jsonb_build_object(
      'is_kids_mode',               'false',
      'can_use_bid_marketplace',    'true',
      'can_use_bulk_marketplace',   'true',
      'can_view_basic_analytics',   'true',
      'can_view_advanced_analytics','true'
    );
  END IF;

  UPDATE public.user_tiers ut
  SET
    tier          = p_tier,
    feature_flags = v_flags,
    updated_at    = now()
  WHERE ut.user_id = p_user_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.approve_vendor_application(p_application_id uuid, p_provider_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_user uuid;
  v_provider_id uuid;
begin
  if not public.is_rooted_admin() then
    raise exception 'Admin required';
  end if;

  execute 'select user_id from public.vendor_applications where id = $1'
    into v_user
    using p_application_id;

  if v_user is null then
    raise exception 'Application not found';
  end if;

  -- Determine provider id
  if p_provider_id is not null then
    v_provider_id := p_provider_id;
  else
    if to_regclass('public.providers') is null then
      raise exception 'providers table not found; pass p_provider_id to approve_vendor_application()';
    end if;

    -- require providers.id exists
    if not exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='id'
    ) then
      raise exception 'providers.id column not found; pass p_provider_id';
    end if;

    v_provider_id := gen_random_uuid();

    if exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='owner_user_id'
    ) then
      execute 'insert into public.providers (id, owner_user_id) values ($1, $2)'
      using v_provider_id, v_user;
    elsif exists(
      select 1 from information_schema.columns
      where table_schema='public' and table_name='providers' and column_name='created_by'
    ) then
      execute 'insert into public.providers (id, created_by) values ($1, $2)'
      using v_provider_id, v_user;
    else
      raise exception 'providers has no owner_user_id/created_by column; pass p_provider_id';
    end if;
  end if;

  -- Membership: make applicant the owner
  insert into public.provider_memberships (provider_id, user_id, membership_role)
  values (v_provider_id, v_user, 'owner')
  on conflict (provider_id, user_id) do update
    set membership_role = excluded.membership_role;

  -- Mark application decided if those columns exist (your schema has decided_at/decided_by)
  if exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='status'
  ) then
    execute 'update public.vendor_applications set status = ''approved'' where id = $1'
      using p_application_id;
  end if;

  if exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='decided_at'
  ) then
    execute 'update public.vendor_applications set decided_at = now() where id = $1'
      using p_application_id;
  end if;

  if exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='decided_by'
  ) then
    execute 'update public.vendor_applications set decided_by = auth.uid() where id = $1'
      using p_application_id;
  end if;

  return v_provider_id;
end;
$function$
;

create or replace view "public"."arts_culture_events_discovery_v1" as  SELECT ace.id,
    ace.provider_id,
    ace.title,
    ace.description,
    ace.event_type,
    ace.tags,
    ace.start_date,
    ace.end_date,
    ace.kids_mode_safe,
    ace.seasonal_category,
    ace.info_url,
    ace.created_by,
    ace.created_at,
    ace.updated_at,
    ctx.best_at_sunset,
    ctx.rainy_day_indoor,
    ctx.photo_friendly,
    ctx.kid_friendly,
    ctx.accessibility_tags,
    ctx.story_snippet
   FROM (public.arts_culture_events ace
     LEFT JOIN public.arts_culture_event_context_profiles ctx ON ((ctx.arts_culture_event_id = ace.id)));


create or replace view "public"."arts_culture_events_v1" as  SELECT id,
    provider_id,
    title,
    description,
    event_type,
    tags,
    start_date,
    end_date,
    kids_mode_safe,
    seasonal_category,
    info_url,
    created_by,
    created_at,
    updated_at,
    COALESCE(tags, '[]'::jsonb) AS tags_normalized,
    COALESCE(kids_mode_safe, true) AS kids_mode_safe_normalized
   FROM public.arts_culture_events ace;


create or replace view "public"."arts_culture_landmarks_v1" as  SELECT id,
    name,
    description,
    landmark_type,
    lat,
    lng,
    is_kid_safe,
    is_published,
    created_by,
    created_at,
    updated_at,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    is_kids_safe_zone,
    kids_safe_zone_type,
    community_focus_tags,
    is_education_landmark,
    education_landmark_type,
    education_subject_tags,
    education_field_trip_ready,
    education_requires_waiver,
    education_kids_mode_safe,
    is_arts_culture_landmark,
    arts_culture_landmark_type,
    arts_culture_story,
    arts_culture_kids_mode_safe,
    COALESCE(arts_culture_kids_mode_safe, true) AS kids_mode_safe_normalized
   FROM public.landmarks l
  WHERE (COALESCE(is_arts_culture_landmark, false) = true);


create or replace view "public"."arts_culture_providers_discovery_v1" as  SELECT p.id,
    p.owner_user_id,
    p.vertical,
    p.provider_type,
    p.specialty,
    p.name,
    p.slug,
    p.short_description,
    p.full_description,
    p.lat,
    p.lng,
    p.city,
    p.state,
    p.country,
    p.postal_code,
    p.is_active,
    p.is_verified,
    p.verification_level,
    p.engagement_score,
    p.last_shown_at,
    p.created_at,
    p.updated_at,
    p.subscription_tier,
    p.is_discoverable,
    p.is_claimed,
    p.payment_provider_customer_id,
    p.subscription_status,
    p.seasonal_theme,
    p.community_tags,
    p.kids_mode_safe,
    p.is_community_org,
    p.community_focus_tags,
    p.community_trust_score,
    p.community_trust_tier,
    p.community_featured_weight,
    p.last_community_reviewed_at,
    p.is_education_site,
    p.education_site_type,
    p.education_subject_tags,
    p.education_grade_bands,
    p.education_field_trip_ready,
    p.education_field_trip_contact_email,
    p.education_field_trip_contact_phone,
    p.education_field_trip_notes,
    p.education_kids_mode_safe,
    p.education_safety_level,
    p.is_arts_culture_site,
    p.arts_culture_type,
    p.arts_culture_tags,
    p.arts_culture_kids_mode_safe,
    p.arts_culture_accessibility,
    p.arts_culture_seasonal_relevance,
    p.arts_culture_story,
    p.established_year,
    p.community_impact_summary,
    p.volunteer_events_hosted,
    p.food_donated_lbs,
    p.school_partnerships_count,
    p.accessibility_tags,
    p.weather_notes,
    ctx.established_year AS ctx_established_year,
    ctx.community_impact_summary AS ctx_community_impact_summary,
    ctx.volunteer_events_hosted AS ctx_volunteer_events_hosted,
    ctx.food_donated_lbs AS ctx_food_donated_lbs,
    ctx.school_partnerships_count AS ctx_school_partnerships_count,
    ctx.accessibility_tags AS ctx_accessibility_tags,
    ctx.weather_notes AS ctx_weather_notes
   FROM (public.providers p
     LEFT JOIN public.provider_context_profiles ctx ON ((ctx.provider_id = p.id)))
  WHERE ((COALESCE(p.is_arts_culture_site, false) = true) AND (COALESCE(p.is_active, true) = true) AND (COALESCE(p.is_discoverable, true) = true));


create or replace view "public"."arts_culture_sites_v1" as  SELECT id,
    owner_user_id,
    vertical,
    provider_type,
    specialty,
    name,
    slug,
    short_description,
    full_description,
    lat,
    lng,
    city,
    state,
    country,
    postal_code,
    is_active,
    is_verified,
    verification_level,
    engagement_score,
    last_shown_at,
    created_at,
    updated_at,
    subscription_tier,
    is_discoverable,
    is_claimed,
    payment_provider_customer_id,
    subscription_status,
    seasonal_theme,
    community_tags,
    kids_mode_safe,
    is_community_org,
    community_focus_tags,
    community_trust_score,
    community_trust_tier,
    community_featured_weight,
    last_community_reviewed_at,
    is_education_site,
    education_site_type,
    education_subject_tags,
    education_grade_bands,
    education_field_trip_ready,
    education_field_trip_contact_email,
    education_field_trip_contact_phone,
    education_field_trip_notes,
    education_kids_mode_safe,
    education_safety_level,
    is_arts_culture_site,
    arts_culture_type,
    arts_culture_tags,
    arts_culture_kids_mode_safe,
    arts_culture_accessibility,
    arts_culture_seasonal_relevance,
    arts_culture_story,
    COALESCE(arts_culture_tags, '[]'::jsonb) AS arts_culture_tags_normalized,
    COALESCE(arts_culture_kids_mode_safe, true) AS kids_mode_safe_normalized,
    COALESCE(arts_culture_accessibility, '[]'::jsonb) AS accessibility_normalized,
    COALESCE(arts_culture_seasonal_relevance, '[]'::jsonb) AS seasonal_relevance_normalized
   FROM public.providers p
  WHERE (COALESCE(is_arts_culture_site, false) = true);


CREATE OR REPLACE FUNCTION public.assign_founding_agriculture_vendor_v1()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  existing_founders integer;
BEGIN
  -- Skip seed/system providers entirely
  IF COALESCE(NEW.is_seed_provider, false) THEN
    RETURN NEW;
  END IF;

  -- Only care about the Agriculture vertical
  IF NEW.primary_vertical IS DISTINCT FROM 'AGRICULTURE_FOOD' THEN
    RETURN NEW;
  END IF;

  -- Count current founding vendors in Agriculture
  SELECT COUNT(*)
  INTO existing_founders
  FROM public.providers
  WHERE primary_vertical = 'AGRICULTURE_FOOD'
    AND is_founding_member = true;

  -- If fewer than 3, grant founding status
  IF existing_founders < 3 THEN
    NEW.is_founding_member := true;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.backfill_founder_vendor_badges()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  rec record;
  v_badge_id uuid;
begin
  -- Find FOUNDER_VENDOR badge id
  select id into v_badge_id
  from badges
  where code = 'FOUNDER_VENDOR'
  limit 1;

  if v_badge_id is null then
    raise exception 'FOUNDER_VENDOR badge not found in badges table';
  end if;

  -- For each founder vendor, grant badge to all their providers
  for rec in
    select ut.user_id
    from user_tiers ut
    where ut.role = 'vendor'
      and ut.feature_flags->>'founder_vendor' = 'true'
  loop
    insert into provider_badges (provider_id, badge_id, granted_by, granted_at)
    select p.id, v_badge_id, auth.uid(), now()
    from providers p
    where p.owner_user_id = rec.user_id
    on conflict (provider_id, badge_id) do nothing;
  end loop;
end;
$function$
;

create or replace view "public"."bids_market_v1" as  SELECT b.id,
    b.rfq_id,
    b.vendor_id,
    b.price_total,
    b.price_unit,
    b.currency,
    b.notes,
    b.status AS bid_status,
    b.vertical_code,
    r.institution_id,
    r.title AS rfq_title,
    r.description AS rfq_description,
    r.category AS rfq_category,
    r.quantity AS rfq_quantity,
    r.unit AS rfq_unit,
    r.delivery_start_date,
    r.delivery_end_date,
    r.status AS rfq_status,
    r.vertical_code AS rfq_vertical_code,
    b.created_at AS bid_created_at,
    b.updated_at AS bid_updated_at
   FROM (public.bids b
     JOIN public.rfqs r ON ((r.id = b.rfq_id)))
  WHERE (r.status = ANY (ARRAY['open'::text, 'awarded'::text]));


CREATE OR REPLACE FUNCTION public.block_mass_overlay_seed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  -- allow service_role
  if current_setting('request.jwt.claim.role', true) = 'service_role' then
    return new;
  end if;

  -- block large inserts from normal contexts
  raise exception 'Overlay mapping writes are locked (service_role only).';
end;
$function$
;

CREATE OR REPLACE FUNCTION public.can_submit_vendor_application(p_user uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
  v_ok boolean := false;
begin
  if p_user is null then
    return false;
  end if;

  if to_regclass('public.entity_flags') is not null then
    select exists (
      select 1
      from public.entity_flags ef
      where ef.entity_id = p_user
        and ef.flag_key in ('age_band_vendor_allowed','age_band_18_5_plus','is_18_5_plus')
        and ef.flag_value = true
        and (ef.expires_at is null or ef.expires_at > now())
    ) into v_ok;

    if v_ok then
      return true;
    end if;
  end if;

  return false;
end;
$function$
;

create or replace view "public"."canonical_vertical_defaults_v1" as  SELECT vertical_code,
    label AS vertical_label,
    ( SELECT o.specialty_code
           FROM public.specialty_vertical_overlays o
          WHERE (o.vertical_code = v.vertical_code)
          ORDER BY o.specialty_code
         LIMIT 1) AS default_specialty
   FROM public.canonical_verticals v;


create or replace view "public"."community_kids_safe_zones_v1" as  SELECT id,
    name,
    description,
    landmark_type,
    lat,
    lng,
    is_kid_safe,
    is_published,
    created_by,
    created_at,
    updated_at,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    is_kids_safe_zone,
    kids_safe_zone_type,
    community_focus_tags,
    COALESCE(kids_mode_safe, true) AS kids_mode_safe_normalized,
    COALESCE(community_focus_tags, '[]'::jsonb) AS community_focus_tags_normalized
   FROM public.landmarks l
  WHERE (COALESCE(is_kids_safe_zone, false) = true);


create or replace view "public"."community_landmarks_kidsafe_v1" as  SELECT id,
    name,
    description,
    landmark_type,
    lat,
    lng,
    is_kid_safe,
    is_published,
    created_by,
    created_at,
    updated_at,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    COALESCE(kids_mode_safe, true) AS kids_mode_safe_normalized,
    COALESCE(community_tags, '[]'::jsonb) AS community_tags_normalized
   FROM public.landmarks l;


create or replace view "public"."community_nature_spots_v1" as  SELECT id,
    created_by,
    spot_type,
    name,
    description,
    latitude,
    longitude,
    provider_id,
    landmark_id,
    season_tags,
    kids_mode_safe,
    status,
    moderator_id,
    moderated_at,
    rejection_reason,
    created_at,
    updated_at,
    COALESCE(season_tags, '[]'::jsonb) AS season_tags_normalized,
    COALESCE(kids_mode_safe, true) AS kids_mode_safe_normalized
   FROM public.community_nature_spots s
  WHERE (status = 'approved'::text);


create or replace view "public"."community_programs_v1" as  SELECT id,
    provider_id,
    title,
    description,
    audience,
    is_free,
    kids_mode_safe,
    community_tags,
    seasonal_category,
    starts_at,
    ends_at,
    created_by,
    created_at,
    updated_at,
    COALESCE(kids_mode_safe, true) AS kids_mode_safe_normalized,
    COALESCE(community_tags, '[]'::jsonb) AS community_tags_normalized
   FROM public.community_programs cp;


create or replace view "public"."community_providers_discovery_v1" as  SELECT p.id,
    p.owner_user_id,
    p.vertical,
    p.provider_type,
    p.specialty,
    p.name,
    p.slug,
    p.short_description,
    p.full_description,
    p.lat,
    p.lng,
    p.city,
    p.state,
    p.country,
    p.postal_code,
    p.is_active,
    p.is_verified,
    p.verification_level,
    p.engagement_score,
    p.last_shown_at,
    p.created_at,
    p.updated_at,
    p.subscription_tier,
    p.is_discoverable,
    p.is_claimed,
    p.payment_provider_customer_id,
    p.subscription_status,
    p.seasonal_theme,
    p.community_tags,
    p.kids_mode_safe,
    p.is_community_org,
    p.community_focus_tags,
    p.community_trust_score,
    p.community_trust_tier,
    p.community_featured_weight,
    p.last_community_reviewed_at,
    p.is_education_site,
    p.education_site_type,
    p.education_subject_tags,
    p.education_grade_bands,
    p.education_field_trip_ready,
    p.education_field_trip_contact_email,
    p.education_field_trip_contact_phone,
    p.education_field_trip_notes,
    p.education_kids_mode_safe,
    p.education_safety_level,
    p.is_arts_culture_site,
    p.arts_culture_type,
    p.arts_culture_tags,
    p.arts_culture_kids_mode_safe,
    p.arts_culture_accessibility,
    p.arts_culture_seasonal_relevance,
    p.arts_culture_story,
    p.established_year,
    p.community_impact_summary,
    p.volunteer_events_hosted,
    p.food_donated_lbs,
    p.school_partnerships_count,
    p.accessibility_tags,
    p.weather_notes,
    ctx.established_year AS ctx_established_year,
    ctx.community_impact_summary AS ctx_community_impact_summary,
    ctx.volunteer_events_hosted AS ctx_volunteer_events_hosted,
    ctx.food_donated_lbs AS ctx_food_donated_lbs,
    ctx.school_partnerships_count AS ctx_school_partnerships_count,
    ctx.accessibility_tags AS ctx_accessibility_tags,
    ctx.weather_notes AS ctx_weather_notes
   FROM (public.providers p
     LEFT JOIN public.provider_context_profiles ctx ON ((ctx.provider_id = p.id)))
  WHERE (((p.vertical = 'community'::text) OR (COALESCE(p.is_community_org, false) = true)) AND (COALESCE(p.is_active, true) = true) AND (COALESCE(p.is_discoverable, true) = true));


create or replace view "public"."community_seasonal_events_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    COALESCE(kids_mode_safe, true) AS kids_mode_safe_normalized,
    COALESCE(community_tags, '[]'::jsonb) AS community_tags_normalized
   FROM public.events e;


create or replace view "public"."community_trusted_providers_v1" as  SELECT id,
    owner_user_id,
    vertical,
    provider_type,
    specialty,
    name,
    slug,
    short_description,
    full_description,
    lat,
    lng,
    city,
    state,
    country,
    postal_code,
    is_active,
    is_verified,
    verification_level,
    engagement_score,
    last_shown_at,
    created_at,
    updated_at,
    subscription_tier,
    is_discoverable,
    is_claimed,
    payment_provider_customer_id,
    subscription_status,
    seasonal_theme,
    community_tags,
    kids_mode_safe,
    is_community_org,
    community_focus_tags,
    community_trust_score,
    community_trust_tier,
    community_featured_weight,
    last_community_reviewed_at,
    COALESCE(community_trust_score, (0)::numeric) AS community_trust_score_normalized,
    COALESCE(community_featured_weight, 0) AS community_featured_weight_normalized,
    COALESCE(community_focus_tags, '[]'::jsonb) AS community_focus_tags_normalized
   FROM public.providers p
  WHERE (COALESCE(is_community_org, false) = true);


create or replace view "public"."community_volunteer_opportunities_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    kids_mode_safe_normalized,
    community_tags_normalized
   FROM public.community_seasonal_events_v1
  WHERE (community_tags_normalized ? 'volunteer'::text);


create or replace view "public"."construction_safety_summary_v1" as  SELECT p.id AS provider_id,
    p.name,
    count(s.*) AS total_incidents,
    max(s.occurred_at) AS last_incident_at,
        CASE
            WHEN (max(s.occurred_at) IS NULL) THEN NULL::integer
            ELSE (floor((EXTRACT(epoch FROM (now() - max(s.occurred_at))) / (86400)::numeric)))::integer
        END AS days_since_last_incident,
    count(*) FILTER (WHERE (s.severity = 'high'::text)) AS high_severity_incidents
   FROM (public.providers p
     LEFT JOIN public.construction_safety_incidents s ON ((s.provider_id = p.id)))
  WHERE (p.vertical = 'construction'::text)
  GROUP BY p.id, p.name;


CREATE OR REPLACE FUNCTION public.current_season()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  SELECT CASE
    WHEN EXTRACT(MONTH FROM CURRENT_DATE) IN (12, 1, 2) THEN 'winter'
    WHEN EXTRACT(MONTH FROM CURRENT_DATE) IN (3, 4, 5)  THEN 'spring'
    WHEN EXTRACT(MONTH FROM CURRENT_DATE) IN (6, 7, 8)  THEN 'summer'
    ELSE 'fall'
  END;
$function$
;

CREATE OR REPLACE FUNCTION public.current_season(p_date date DEFAULT CURRENT_DATE)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when extract(month from p_date) in (12, 1, 2)  then 'winter'
    when extract(month from p_date) in (3, 4, 5)   then 'spring'
    when extract(month from p_date) in (6, 7, 8)   then 'summer'
    when extract(month from p_date) in (9, 10, 11) then 'fall'
  end;
$function$
;

CREATE OR REPLACE FUNCTION public.current_user_has_feature(p_flag text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.has_feature(auth.uid(), p_flag);
$function$
;

CREATE OR REPLACE FUNCTION public.current_user_role()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select ut.role::text
  from public.user_tiers ut
  where ut.user_id = auth.uid()
  limit 1;
$function$
;

CREATE OR REPLACE FUNCTION public.discover_providers(in_user_lat double precision, in_user_lng double precision, in_radius_miles integer DEFAULT 50, in_specialty text DEFAULT NULL::text, in_limit integer DEFAULT 8, in_verified_only boolean DEFAULT true)
 RETURNS SETOF public.discovery_providers
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
    effective_radius integer;
    effective_limit  integer;
begin
    -- 1) Enforce GEO radius cap (50 miles max)
    if in_radius_miles is null or in_radius_miles <= 0 then
        effective_radius := 50;
    elsif in_radius_miles > 50 then
        effective_radius := 50;
    else
        effective_radius := in_radius_miles;
    end if;

    -- 2) Enforce global result limits (6ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“8 only)
    if in_limit is null or in_limit < 6 then
        effective_limit := 6;
    elsif in_limit > 8 then
        effective_limit := 8;
    else
        effective_limit := in_limit;
    end if;

    -- 3) Core query against your discovery view
    return query
    select *
    from public.discovery_providers dp
    where
        distance_miles(in_user_lat, in_user_lng, dp.lat, dp.lng) <= effective_radius
        and (in_specialty is null or dp.specialty = in_specialty)
        and (not in_verified_only or dp.is_verified = true)
    order by
        dp.last_shown_at nulls first,
        dp.engagement_score desc nulls last,
        dp.created_at asc
    limit effective_limit;
end;
$function$
;

create or replace view "public"."discovery_providers" as  SELECT id,
    name,
    specialty,
    city,
    state,
    lat,
    lng,
    is_verified,
    engagement_score,
    last_shown_at,
    created_at
   FROM public.providers
  WHERE (is_active = true);


CREATE OR REPLACE FUNCTION public.distance_miles(lat1 double precision, lng1 double precision, lat2 double precision, lng2 double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE
AS $function$
    -- Haversine great-circle distance in miles
    select 3958.8 * acos(
        least(
            1.0,
            cos(radians($1)) * cos(radians($3)) * cos(radians($4) - radians($2))
          + sin(radians($1)) * sin(radians($3))
        )
    );
$function$
;

create or replace view "public"."education_field_trips_v1" as  SELECT id,
    provider_id,
    landmark_id,
    title,
    description,
    audience,
    grade_bands,
    subject_tags,
    is_free,
    max_students,
    requires_waiver,
    kids_mode_safe,
    info_url,
    contact_email,
    contact_phone,
    created_by,
    created_at,
    updated_at,
    COALESCE(grade_bands, '[]'::jsonb) AS grade_bands_normalized,
    COALESCE(subject_tags, '[]'::jsonb) AS subject_tags_normalized,
    COALESCE(kids_mode_safe, true) AS kids_mode_safe_normalized
   FROM public.education_field_trips eft;


create or replace view "public"."education_landmarks_v1" as  SELECT id,
    name,
    description,
    landmark_type,
    lat,
    lng,
    is_kid_safe,
    is_published,
    created_by,
    created_at,
    updated_at,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    is_kids_safe_zone,
    kids_safe_zone_type,
    community_focus_tags,
    is_education_landmark,
    education_landmark_type,
    education_subject_tags,
    education_field_trip_ready,
    education_requires_waiver,
    education_kids_mode_safe,
    COALESCE(education_subject_tags, '[]'::jsonb) AS education_subject_tags_normalized,
    COALESCE(education_field_trip_ready, false) AS education_field_trip_ready_normalized,
    COALESCE(education_kids_mode_safe, true) AS education_kids_mode_safe_normalized
   FROM public.landmarks l
  WHERE (COALESCE(is_education_landmark, false) = true);


create or replace view "public"."education_providers_discovery_v1" as  SELECT p.id,
    p.owner_user_id,
    p.vertical,
    p.provider_type,
    p.specialty,
    p.name,
    p.slug,
    p.short_description,
    p.full_description,
    p.lat,
    p.lng,
    p.city,
    p.state,
    p.country,
    p.postal_code,
    p.is_active,
    p.is_verified,
    p.verification_level,
    p.engagement_score,
    p.last_shown_at,
    p.created_at,
    p.updated_at,
    p.subscription_tier,
    p.is_discoverable,
    p.is_claimed,
    p.payment_provider_customer_id,
    p.subscription_status,
    p.seasonal_theme,
    p.community_tags,
    p.kids_mode_safe,
    p.is_community_org,
    p.community_focus_tags,
    p.community_trust_score,
    p.community_trust_tier,
    p.community_featured_weight,
    p.last_community_reviewed_at,
    p.is_education_site,
    p.education_site_type,
    p.education_subject_tags,
    p.education_grade_bands,
    p.education_field_trip_ready,
    p.education_field_trip_contact_email,
    p.education_field_trip_contact_phone,
    p.education_field_trip_notes,
    p.education_kids_mode_safe,
    p.education_safety_level,
    p.is_arts_culture_site,
    p.arts_culture_type,
    p.arts_culture_tags,
    p.arts_culture_kids_mode_safe,
    p.arts_culture_accessibility,
    p.arts_culture_seasonal_relevance,
    p.arts_culture_story,
    p.established_year,
    p.community_impact_summary,
    p.volunteer_events_hosted,
    p.food_donated_lbs,
    p.school_partnerships_count,
    p.accessibility_tags,
    p.weather_notes,
    ctx.established_year AS ctx_established_year,
    ctx.community_impact_summary AS ctx_community_impact_summary,
    ctx.volunteer_events_hosted AS ctx_volunteer_events_hosted,
    ctx.food_donated_lbs AS ctx_food_donated_lbs,
    ctx.school_partnerships_count AS ctx_school_partnerships_count,
    ctx.accessibility_tags AS ctx_accessibility_tags,
    ctx.weather_notes AS ctx_weather_notes
   FROM (public.providers p
     LEFT JOIN public.provider_context_profiles ctx ON ((ctx.provider_id = p.id)))
  WHERE ((COALESCE(p.is_education_site, false) = true) AND (COALESCE(p.is_active, true) = true) AND (COALESCE(p.is_discoverable, true) = true));


create or replace view "public"."education_sites_v1" as  SELECT id,
    owner_user_id,
    vertical,
    provider_type,
    specialty,
    name,
    slug,
    short_description,
    full_description,
    lat,
    lng,
    city,
    state,
    country,
    postal_code,
    is_active,
    is_verified,
    verification_level,
    engagement_score,
    last_shown_at,
    created_at,
    updated_at,
    subscription_tier,
    is_discoverable,
    is_claimed,
    payment_provider_customer_id,
    subscription_status,
    seasonal_theme,
    community_tags,
    kids_mode_safe,
    is_community_org,
    community_focus_tags,
    community_trust_score,
    community_trust_tier,
    community_featured_weight,
    last_community_reviewed_at,
    is_education_site,
    education_site_type,
    education_subject_tags,
    education_grade_bands,
    education_field_trip_ready,
    education_field_trip_contact_email,
    education_field_trip_contact_phone,
    education_field_trip_notes,
    education_kids_mode_safe,
    education_safety_level,
    COALESCE(education_subject_tags, '[]'::jsonb) AS education_subject_tags_normalized,
    COALESCE(education_grade_bands, '[]'::jsonb) AS education_grade_bands_normalized,
    COALESCE(education_kids_mode_safe, true) AS education_kids_mode_safe_normalized,
    COALESCE(education_field_trip_ready, false) AS education_field_trip_ready_normalized
   FROM public.providers p
  WHERE (COALESCE(is_education_site, false) = true);


CREATE OR REPLACE FUNCTION public.enforce_bulk_offer_vertical_f()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_primary   text;
  v_specialty text;
  allowed     boolean;
BEGIN
  -- Look up the provider
  SELECT p.primary_vertical, p.specialty
  INTO   v_primary, v_specialty
  FROM   public.providers p
  WHERE  p.id = NEW.vendor_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Provider % not found for bulk_offer %',
      NEW.vendor_id, NEW.id;
  END IF;

  IF v_primary IS NULL THEN
    RAISE EXCEPTION 'Provider % has no primary_vertical set',
      NEW.vendor_id;
  END IF;

  -- If UI / app forgot to set a vertical_code, default to primary
  IF NEW.vertical_code IS NULL THEN
    NEW.vertical_code := v_primary;
  END IF;

  -- If it matches primary vertical, weÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢re good
  IF NEW.vertical_code = v_primary THEN
    RETURN NEW;
  END IF;

  -- Otherwise, only allow if thereÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢s a specialty overlay
  SELECT EXISTS (
    SELECT 1
    FROM public.vertical_specialty_effective_v1 vse
    WHERE vse.specialty_code = v_specialty
      AND vse.vertical_code  = NEW.vertical_code
  ) INTO allowed;

  IF NOT allowed THEN
    RAISE EXCEPTION
      'Bulk offer vertical % not allowed for provider % (primary %, specialty %)',
      NEW.vertical_code, NEW.vendor_id, v_primary, v_specialty;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_max_3_founders()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF (
    SELECT COUNT(*) 
    FROM public.provider_badges pb
    JOIN public.badges b ON b.id = pb.badge_id
    WHERE b.code = 'FOUNDER_VENDOR'
  ) >= 3 THEN
    RAISE EXCEPTION 'Maximum of 3 founding vendors already reached';
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_membership_expirations()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  -- Mark any past-due memberships as expired
  update public.user_tier_memberships
  set status     = 'expired',
      updated_at = now()
  where status = 'active'
    and ends_at < now();
end;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_rfq_vertical()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  inst_vertical text;
BEGIN
  -- 1) Look up the institution's primary vertical
  --    We treat rfqs.institution_id as the *user id* that owns providers.
  SELECT p.primary_vertical
  INTO inst_vertical
  FROM public.providers p
  WHERE p.owner_user_id = NEW.institution_id
    AND p.primary_vertical IS NOT NULL
  ORDER BY p.created_at DESC
  LIMIT 1;

  -- 2) If we still don't have one, hard stop.
  IF inst_vertical IS NULL THEN
    RAISE EXCEPTION
      'Institution % has no primary vertical defined ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“ RFQ cannot be saved.',
      NEW.institution_id
      USING ERRCODE = 'P0001';
  END IF;

  -- 3) If RFQ has no vertical_code, auto-fill it from institution.
  IF NEW.vertical_code IS NULL THEN
    NEW.vertical_code := inst_vertical;

  -- 4) If RFQ.vertical_code conflicts with institution primary vertical, stop.
  ELSIF NEW.vertical_code <> inst_vertical THEN
    RAISE EXCEPTION
      'RFQ vertical % does not match institution primary vertical %',
      NEW.vertical_code, inst_vertical
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$function$
;

create or replace view "public"."event_specialties_v1" as  SELECT eb.event_id,
    b.code AS badge_code,
    b.name AS badge_name,
    b.description AS badge_description,
    b.badge_type,
        CASE
            WHEN ((b.badge_type = 'event_specialty'::text) AND (b.code = ANY (ARRAY['festival'::text, 'farmers_market_event'::text, 'holiday_village'::text, 'popup_market'::text]))) THEN 'festivals_and_markets'::text
            WHEN ((b.badge_type = 'event_specialty'::text) AND (b.code = ANY (ARRAY['workshop'::text, 'educational_class'::text, 'farm_tour'::text, 'tasting_event'::text]))) THEN 'education_and_experiences'::text
            WHEN ((b.badge_type = 'event_specialty'::text) AND (b.code = ANY (ARRAY['volunteer_event'::text, 'community_service_day'::text]))) THEN 'volunteering'::text
            WHEN ((b.badge_type = 'event_specialty'::text) AND (b.code = 'seasonal_pick_your_own'::text)) THEN 'seasonal_pick_your_own'::text
            ELSE 'other'::text
        END AS legend_group
   FROM (public.event_badges eb
     JOIN public.badges b ON ((b.id = eb.badge_id)));


create or replace view "public"."events_discovery_v1" as  SELECT e.id,
    e.created_at,
    e.created_by,
    e.host_vendor_id,
    e.host_institution_id,
    e.title,
    e.description,
    e.event_type,
    e.start_time,
    e.end_time,
    e.location_lat,
    e.location_lng,
    e.is_kids_safe,
    e.max_participants,
    e.season_tags,
    e.holiday_tags,
    e.cultural_tags,
    e.status,
    e.moderation_status,
    e.seasonal_category,
    e.kids_mode_safe,
    e.community_tags,
    ctx.accessibility_tags,
    ctx.weather_impact_note,
    ctx.family_friendly,
    ctx.first_timer_friendly
   FROM (public.events e
     LEFT JOIN public.event_context_profiles ctx ON ((ctx.event_id = e.id)))
  WHERE (COALESCE(e.moderation_status, 'approved'::text) <> 'rejected'::text);


create or replace view "public"."events_public_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status
   FROM public.events
  WHERE ((COALESCE(moderation_status, 'approved'::text) <> 'rejected'::text) AND (status = 'published'::text));


create or replace view "public"."experience_bids_v1" as  SELECT b.id,
    b.rfq_id,
    b.vendor_id,
    b.price_total,
    b.price_unit,
    b.currency,
    b.notes,
    b.status,
    b.created_at,
    b.updated_at,
    r.institution_id,
    r.title AS rfq_title,
    r.category AS rfq_category,
    r.delivery_start_date,
    r.delivery_end_date,
    vp.name AS vendor_name
   FROM ((public.bids b
     JOIN public.rfqs r ON ((r.id = b.rfq_id)))
     JOIN public.providers vp ON ((vp.id = b.vendor_id)))
  WHERE (r.category = 'experience'::text);


create or replace view "public"."experience_governance_profile_v1" as  SELECT et.code AS experience_code,
    et.label AS experience_label,
    et.requires_waiver,
    et.kids_allowed,
    et.insurance_required,
    et.seasonal_lockable,
    COALESCE(array_agg(DISTINCT ek.kids_code) FILTER (WHERE (ek.kids_code IS NOT NULL)), '{}'::text[]) AS kids_mode_codes
   FROM (public.experience_types et
     LEFT JOIN public.experience_kids_mode_overlays ek ON ((ek.experience_code = et.code)))
  GROUP BY et.code, et.label, et.requires_waiver, et.kids_allowed, et.insurance_required, et.seasonal_lockable;


create or replace view "public"."experience_rfqs_v1" as  SELECT r.id,
    r.institution_id,
    r.title,
    r.description,
    r.category,
    r.quantity,
    r.unit,
    r.delivery_start_date,
    r.delivery_end_date,
    r.status,
    r.created_at,
    r.updated_at,
    p.name AS institution_name,
    p.specialty AS institution_specialty,
    p.city,
    p.state,
    p.country
   FROM (public.rfqs r
     JOIN public.providers p ON ((p.id = r.institution_id)))
  WHERE (r.category = 'experience'::text);


create or replace view "public"."experiences_discovery_v1" as  SELECT e.id,
    e.provider_id,
    e.title,
    e.description,
    e.min_age,
    e.max_age,
    e.season,
    e.is_kids_safe,
    e.status,
    e.created_at,
    e.updated_at,
    e.created_by,
    e.requires_adult_supervision,
    e.teen_visible,
    c.difficulty_level,
    c.first_timer_friendly,
    c.surface_type,
    c.incline_description,
    c.recommended_footwear,
    c.seasonal_pack_tags,
    c.leave_no_trace_tips,
    c.weather_impact_note
   FROM (public.experiences e
     LEFT JOIN public.experience_context_profiles c ON ((c.experience_id = e.id)));


create or replace view "public"."founding_partners_v1" as  WITH ordered AS (
         SELECT p.id AS provider_id,
            p.name,
            p.provider_type,
            p.created_at,
            row_number() OVER (ORDER BY p.created_at) AS founding_rank
           FROM public.providers p
          WHERE (p.provider_type = ANY (ARRAY['vendor'::text, 'institution'::text]))
        )
 SELECT provider_id,
    name,
    provider_type,
    created_at,
    founding_rank
   FROM ordered
  WHERE (founding_rank <= 10);


CREATE OR REPLACE FUNCTION public.get_market_required_badges(p_vertical_code text, p_market_code text)
 RETURNS text[]
 LANGUAGE sql
 STABLE
AS $function$
  SELECT r.required_badge_codes
  FROM public.vertical_market_requirements r
  WHERE r.vertical_code = p_vertical_code
    AND r.market_code = p_market_code
    AND r.enabled = true
  LIMIT 1;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_role_and_tier()
 RETURNS TABLE(role text, tier text, feature_flags jsonb)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
  select
    ut.role,
    ut.tier,
    ut.feature_flags
  from public.user_tiers ut
  where ut.user_id = auth.uid()
  limit 1;
$function$
;

CREATE OR REPLACE FUNCTION public.grant_default_badges_for_provider(p_provider_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_specialty     text;
  v_is_verified   boolean;
  v_provider_type text;
  v_badge_code    text;
  v_badge_id      uuid;
begin
  -- Load provider info
  select specialty, is_verified, provider_type
  into v_specialty, v_is_verified, v_provider_type
  from providers
  where id = p_provider_id;

  if not found then
    raise exception 'Provider % not found', p_provider_id;
  end if;

  ----------------------------------------------------------------------
  -- 1) Baseline ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œlistedÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â badges (applies to seeded and unverified)
  ----------------------------------------------------------------------
  if v_provider_type = 'vendor' then
    v_badge_code := 'LISTED_VENDOR';
  elsif v_provider_type = 'institution' then
    v_badge_code := 'LISTED_INSTITUTION';
  else
    v_badge_code := null;
  end if;

  if v_badge_code is not null then
    select id
    into v_badge_id
    from badges
    where code = v_badge_code
    limit 1;

    if v_badge_id is not null then
      insert into provider_badges (provider_id, badge_id, granted_by, granted_at)
      select p_provider_id, v_badge_id, auth.uid(), now()
      where not exists (
        select 1
        from provider_badges pb
        where pb.provider_id = p_provider_id
          and pb.badge_id    = v_badge_id
      );
    end if;
  end if;

  ----------------------------------------------------------------------
  -- 2) Verified badges (only when is_verified = true)
  ----------------------------------------------------------------------
  if v_is_verified then
    -- Verified vendor/institution badge
    if v_provider_type = 'vendor' then
      v_badge_code := 'VERIFIED_VENDOR';
    elsif v_provider_type = 'institution' then
      v_badge_code := 'VERIFIED_INSTITUTION';
    else
      v_badge_code := null;
    end if;

    if v_badge_code is not null then
      v_badge_id := null;

      select id
      into v_badge_id
      from badges
      where code = v_badge_code
      limit 1;

      if v_badge_id is not null then
        insert into provider_badges (provider_id, badge_id, granted_by, granted_at)
        select p_provider_id, v_badge_id, auth.uid(), now()
        where not exists (
          select 1
          from provider_badges pb
          where pb.provider_id = p_provider_id
            and pb.badge_id    = v_badge_id
        );
      end if;
    end if;
  end if;

  ----------------------------------------------------------------------
  -- 3) Specialty-based badge (example: farm)
  ----------------------------------------------------------------------
  if v_specialty is not null and v_specialty ilike '%farm%' then
    v_badge_code := 'LOCAL_FARM';
    v_badge_id := null;

    select id
    into v_badge_id
    from badges
    where code = v_badge_code
    limit 1;

    if v_badge_id is not null then
      insert into provider_badges (provider_id, badge_id, granted_by, granted_at)
      select p_provider_id, v_badge_id, auth.uid(), now()
      where not exists (
        select 1
        from provider_badges pb
        where pb.provider_id = p_provider_id
          and pb.badge_id    = v_badge_id
      );
    end if;
  end if;

end;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.user_tiers (user_id, role, tier)
  values (new.id, 'community', 'free')
  on conflict (user_id) do nothing;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.has_feature(p_user_id uuid, p_flag text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    coalesce(
      (feature_flags ->> p_flag)::boolean,
      false
    )
  from public.user_tiers
  where user_id = p_user_id
  limit 1;
$function$
;

create or replace view "public"."institution_large_scale_volunteer_events_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    event_vertical,
    is_volunteer,
    is_large_scale_volunteer,
    requires_institutional_partner
   FROM public.events e
  WHERE ((is_volunteer = true) AND (is_large_scale_volunteer = true) AND (requires_institutional_partner = true) AND (status = 'published'::text) AND (moderation_status = 'approved'::text));


create or replace view "public"."institution_volunteer_summary_v1" as  SELECT e.host_institution_id AS institution_id,
    count(DISTINCT e.id) AS volunteer_events_count,
    count(er.id) AS volunteer_signups_count
   FROM (public.events e
     LEFT JOIN public.event_registrations er ON ((er.event_id = e.id)))
  WHERE ((e.host_institution_id IS NOT NULL) AND (e.event_type = ANY (ARRAY['volunteer'::text, 'volunteer_event'::text])) AND (e.status = 'published'::text) AND (e.moderation_status = 'approved'::text))
  GROUP BY e.host_institution_id;


create or replace view "public"."institutions" as  SELECT id,
    owner_user_id,
    vertical,
    provider_type,
    specialty,
    name,
    slug,
    short_description,
    full_description,
    lat,
    lng,
    city,
    state,
    country,
    postal_code,
    is_active,
    is_verified,
    verification_level,
    engagement_score,
    last_shown_at,
    created_at,
    updated_at,
    subscription_tier,
    is_discoverable,
    is_claimed,
    payment_provider_customer_id,
    subscription_status,
    seasonal_theme,
    community_tags,
    kids_mode_safe,
    is_community_org,
    community_focus_tags,
    community_trust_score,
    community_trust_tier,
    community_featured_weight,
    last_community_reviewed_at,
    is_education_site,
    education_site_type,
    education_subject_tags,
    education_grade_bands,
    education_field_trip_ready,
    education_field_trip_contact_email,
    education_field_trip_contact_phone,
    education_field_trip_notes,
    education_kids_mode_safe,
    education_safety_level,
    is_arts_culture_site,
    arts_culture_type,
    arts_culture_tags,
    arts_culture_kids_mode_safe,
    arts_culture_accessibility,
    arts_culture_seasonal_relevance,
    arts_culture_story,
    established_year,
    community_impact_summary,
    volunteer_events_hosted,
    food_donated_lbs,
    school_partnerships_count,
    accessibility_tags,
    weather_notes
   FROM public.providers p
  WHERE (provider_type = 'institution'::text);


CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case
    when auth.uid() is null then false
    else public.is_admin(auth.uid()::uuid)
  end;
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin(p_user uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = p_user
      and ut.role = 'admin'
      and ut.account_status = 'active'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin_user(target_user uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  select exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = target_user
      and ut.role = 'admin'
      and ut.account_status = 'active'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_kids_account()
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.user_tiers ut
    where ut.user_id = auth.uid()
      and ut.role = 'community'
      and coalesce(ut.feature_flags->>'kids_mode_enabled', 'false') = 'true'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_kids_mode(uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce(
    nullif( (ut.feature_flags->>'is_kids_mode')::text, '' )::boolean,
    (ut.feature_flags->'is_kids_mode')::boolean,
    false
  )
  from public.user_tiers ut
  where ut.user_id = uid
$function$
;

CREATE OR REPLACE FUNCTION public.is_rooted_admin()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
  v_is_admin boolean := false;
begin
  if auth.uid() is null then
    return false;
  end if;

  if to_regclass('public.user_tiers') is null then
    return false;
  end if;

  -- Prefer user_id column if present
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='user_tiers' and column_name='user_id'
  ) then
    select exists(
      select 1 from public.user_tiers ut
      where ut.user_id = auth.uid()
        and ut.role = 'admin'
    ) into v_is_admin;
    return coalesce(v_is_admin,false);
  end if;

  -- Fallback to id column if present
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='user_tiers' and column_name='id'
  ) then
    select exists(
      select 1 from public.user_tiers ut
      where ut.id = auth.uid()
        and ut.role = 'admin'
    ) into v_is_admin;
    return coalesce(v_is_admin,false);
  end if;

  return false;
end;
$function$
;

create or replace view "public"."justice_institutions" as  SELECT pb.provider_id
   FROM (public.provider_badges pb
     JOIN public.badges b ON ((b.id = pb.badge_id)))
  WHERE (b.code = ANY (ARRAY['correctional_facility'::text, 'juvenile_detention'::text, 'probation_parole_office'::text, 'court_system'::text, 'justice_system_partner'::text]));


CREATE OR REPLACE FUNCTION public.kids_mode_enabled()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  SELECT COALESCE(
    (
      SELECT (value->>'enabled')::boolean
      FROM public.app_settings
      WHERE key = 'kids_mode'
    ),
    false
  );
$function$
;

create or replace view "public"."kids_safe_events_v1" as  SELECT e.id,
    e.created_at,
    e.created_by,
    e.host_vendor_id,
    e.host_institution_id,
    e.title,
    e.description,
    e.event_type,
    e.start_time,
    e.end_time,
    e.location_lat,
    e.location_lng,
    e.is_kids_safe,
    e.max_participants,
    e.season_tags,
    e.holiday_tags,
    e.cultural_tags,
    e.status,
    e.moderation_status,
    p.name AS provider_name,
    p.provider_type,
    p.specialty
   FROM (public.events e
     JOIN public.providers p ON ((p.id = COALESCE(e.host_vendor_id, e.host_institution_id))))
  WHERE ((e.is_kids_safe = true) AND (e.moderation_status = 'approved'::text));


create or replace view "public"."landmark_specialties_v1" as  SELECT lb.landmark_id,
    b.code AS badge_code,
    b.name AS badge_name,
    b.description AS badge_description,
    b.badge_type,
        CASE
            WHEN ((b.badge_type = 'landmark_specialty'::text) AND (b.code = ANY (ARRAY['historic_site'::text, 'agricultural_heritage_site'::text, 'mill_industrial_heritage'::text]))) THEN 'heritage'::text
            WHEN ((b.badge_type = 'landmark_specialty'::text) AND (b.code = ANY (ARRAY['environmental_preserve'::text, 'trailhead'::text, 'orchard_trail'::text, 'educational_garden'::text, 'pollinator_garden'::text, 'waterway_river_access'::text, 'scenic_overlook'::text]))) THEN 'nature_and_trails'::text
            ELSE 'other'::text
        END AS legend_group
   FROM (public.landmark_badges lb
     JOIN public.badges b ON ((b.id = lb.badge_id)));


create or replace view "public"."landmarks_public_kids_v1" as  SELECT id,
    name,
    description,
    landmark_type,
    lat,
    lng,
    is_kid_safe,
    is_published,
    created_by,
    created_at,
    updated_at,
    moderation_status
   FROM public.landmarks
  WHERE ((moderation_status = 'approved'::text) AND (is_kid_safe = true));


create or replace view "public"."landmarks_public_v1" as  SELECT id,
    name,
    description,
    landmark_type,
    lat,
    lng,
    is_kid_safe,
    is_published,
    created_by,
    created_at,
    updated_at,
    moderation_status
   FROM public.landmarks
  WHERE (moderation_status = 'approved'::text);


create or replace view "public"."large_scale_volunteer_events_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    event_vertical,
    is_volunteer,
    is_large_scale_volunteer,
    requires_institutional_partner
   FROM public.events e
  WHERE ((is_volunteer = true) AND (is_large_scale_volunteer = true) AND (status = 'published'::text) AND (moderation_status = 'approved'::text));


create or replace view "public"."live_feed" as  SELECT f.id,
    f.author_id,
    f.author_role,
    f.author_tier,
    f.content,
    f.media,
    f.feed_type,
    f.visibility_scope,
    f.is_kids_safe,
    f.requires_premium,
    f.requires_premium_plus,
    f.location,
    f.related_vendor_id,
    f.related_institution_id,
    f.created_at,
    ut.role AS user_role,
    ut.tier AS user_tier
   FROM (public.feed_items f
     LEFT JOIN public.user_tiers ut ON ((ut.user_id = f.author_id)));


CREATE OR REPLACE FUNCTION public.log_seasonal_content_view(_content_type text, _content_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  INSERT INTO public.seasonal_content_analytics_daily (content_type, content_id, date, views)
  VALUES (_content_type, _content_id, CURRENT_DATE, 1)
  ON CONFLICT (content_type, content_id, date)
  DO UPDATE SET views = public.seasonal_content_analytics_daily.views + 1;
END;
$function$
;

create or replace view "public"."market_coverage_v1" as  SELECT vertical_code,
    label AS vertical_label,
    (EXISTS ( SELECT 1
           FROM public.rfqs r
          WHERE (r.vertical_code = v.vertical_code))) AS has_rfqs,
    (EXISTS ( SELECT 1
           FROM public.bids b
          WHERE (b.vertical_code = v.vertical_code))) AS has_bids,
    (EXISTS ( SELECT 1
           FROM public.bulk_offers bo
          WHERE (bo.vertical_code = v.vertical_code))) AS has_bulk_offers,
    (EXISTS ( SELECT 1
           FROM public.events e
          WHERE (e.event_vertical = v.vertical_code))) AS has_events
   FROM public.canonical_verticals v
  ORDER BY sort_order, vertical_code;


create or replace view "public"."market_rfqs_v1" as  SELECT id,
    institution_id,
    vertical_code,
    title,
    description,
    category,
    quantity,
    unit,
    delivery_start_date,
    delivery_end_date,
    status,
    created_at,
    updated_at
   FROM public.rfqs r;


CREATE OR REPLACE FUNCTION public.maybe_apply_founder_vendor_promo(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_role           text;
  v_tier           text;
  v_flags          jsonb;
  v_founder_count  integer;
begin
  -- Load current role/tier/flags
  select role, tier, coalesce(feature_flags, '{}'::jsonb)
  into v_role, v_tier, v_flags
  from user_tiers
  where user_id = p_user_id;

  if not found then
    raise exception 'user_tiers row not found for user %', p_user_id;
  end if;

  -- Only apply to vendors
  if v_role <> 'vendor' then
    return;
  end if;

  -- Count how many vendors already have this founder promo
  select count(*)
  into v_founder_count
  from user_tiers
  where role = 'vendor'
    and feature_flags->>'founder_vendor' = 'true';

  -- If already 3 or more, do nothing
  if v_founder_count >= 3 then
    return;
  end if;

  -- Apply lifetime premium + discount
  update user_tiers
  set tier = 'premium',
      feature_flags = v_flags
        || jsonb_build_object(
             'founder_vendor', 'true',
             'lifetime_premium', 'true',
             'premium_plus_discount_pct', '50'
           ),
      updated_at = now()
  where user_id = p_user_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_submission_approved(target_user uuid, entity_type text, entity_id uuid, entity_title text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  insert into public.notifications (
    user_id,
    type,
    title,
    body,
    data,
    delivery_channel
  )
  values (
    target_user,
    'submission_approved',
    'Your submission was approved',
    format('Your %s "%s" is now live on ROOTED.', entity_type, entity_title),
    jsonb_build_object(
      'entity_type', entity_type,
      'entity_id', entity_id
    ),
    array['push']
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_submission_rejected(target_user uuid, entity_type text, entity_id uuid, entity_title text, rejection_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  insert into public.notifications (
    user_id,
    type,
    title,
    body,
    data,
    delivery_channel
  )
  values (
    target_user,
    'submission_rejected',
    'Your submission was not approved',
    format(
      'Your %s "%s" was not approved. Reason: %s',
      entity_type,
      entity_title,
      rejection_reason
    ),
    jsonb_build_object(
      'entity_type', entity_type,
      'entity_id', entity_id
    ),
    array['push']
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.overlay_upsert_service_role_only(p_vertical_code text, p_specialty_code text, p_is_discovery_allowed boolean DEFAULT NULL::boolean, p_is_events_allowed boolean DEFAULT NULL::boolean, p_is_market_allowed boolean DEFAULT NULL::boolean, p_requires_licensed boolean DEFAULT NULL::boolean, p_requires_insured boolean DEFAULT NULL::boolean, p_kids_mode_visibility text DEFAULT NULL::text, p_teens_mode_visibility text DEFAULT NULL::text, p_ads_allowed boolean DEFAULT NULL::boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF COALESCE(auth.role(), '') <> 'service_role' THEN
    RAISE EXCEPTION 'service_role only';
  END IF;

  INSERT INTO public.specialty_vertical_overlays (
    vertical_code,
    specialty_code,
    is_discovery_allowed,
    is_events_allowed,
    is_market_allowed,
    requires_licensed,
    requires_insured,
    kids_mode_visibility,
    teens_mode_visibility,
    ads_allowed,
    created_at,
    created_by
  )
  VALUES (
    p_vertical_code,
    p_specialty_code,
    p_is_discovery_allowed,
    p_is_events_allowed,
    p_is_market_allowed,
    p_requires_licensed,
    p_requires_insured,
    p_kids_mode_visibility,
    p_teens_mode_visibility,
    p_ads_allowed,
    now(),
    NULL
  )
  ON CONFLICT (vertical_code, specialty_code) DO UPDATE SET
    is_discovery_allowed  = COALESCE(EXCLUDED.is_discovery_allowed,  specialty_vertical_overlays.is_discovery_allowed),
    is_events_allowed     = COALESCE(EXCLUDED.is_events_allowed,     specialty_vertical_overlays.is_events_allowed),
    is_market_allowed     = COALESCE(EXCLUDED.is_market_allowed,     specialty_vertical_overlays.is_market_allowed),
    requires_licensed     = COALESCE(EXCLUDED.requires_licensed,     specialty_vertical_overlays.requires_licensed),
    requires_insured      = COALESCE(EXCLUDED.requires_insured,      specialty_vertical_overlays.requires_insured),
    kids_mode_visibility  = COALESCE(EXCLUDED.kids_mode_visibility,  specialty_vertical_overlays.kids_mode_visibility),
    teens_mode_visibility = COALESCE(EXCLUDED.teens_mode_visibility, specialty_vertical_overlays.teens_mode_visibility),
    ads_allowed           = COALESCE(EXCLUDED.ads_allowed,           specialty_vertical_overlays.ads_allowed);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.password_fingerprint(p_plain text)
 RETURNS text
 LANGUAGE sql
AS $function$
  select encode(
           digest(
             p_plain || current_setting('app.password_salt', true),
             'sha256'
           ),
           'hex'
         );
$function$
;

CREATE OR REPLACE FUNCTION public.password_reuse_allowed(p_user_id uuid, p_new_pw_fingerprint text)
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  -- True = allowed, False = reject (was used in last 90 days)
  select not exists (
    select 1
    from public.password_history ph
    where ph.user_id = p_user_id
      and ph.pw_fingerprint = p_new_pw_fingerprint
      and ph.rotated_at >= now() - interval '90 days'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.prevent_more_than_three_founders()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.badge_id = (
    SELECT id FROM public.badges WHERE code = 'FOUNDER_VENDOR'
  ) THEN
    IF (SELECT COUNT(*) 
        FROM public.provider_badges pb
        JOIN public.badges b ON b.id = pb.badge_id
        WHERE b.code = 'FOUNDER_VENDOR') >= 3 THEN
      RAISE EXCEPTION 'Founder vendor limit reached (max 3).';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.provider_has_badge(p_provider_id uuid, p_badge_code text)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  select exists (
    select 1
    from public.provider_badges pb
    join public.badges b on b.id = pb.badge_id
    where pb.provider_id = p_provider_id
      and b.code = p_badge_code
  );
$function$
;

create or replace view "public"."provider_impact_latest" as  SELECT DISTINCT ON (provider_id) provider_id,
    snapshot_date,
    period_start,
    period_end,
    total_orders,
    total_revenue,
    community_donations,
    events_hosted,
    volunteers_involved,
    impact_score,
    metrics
   FROM public.provider_impact_snapshots
  ORDER BY provider_id, snapshot_date DESC;


CREATE OR REPLACE FUNCTION public.provider_is_market_compliant(p_provider_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  select
    public.provider_has_badge(p_provider_id, 'INSURED')
    and public.provider_has_badge(p_provider_id, 'LICENSED');
$function$
;

CREATE OR REPLACE FUNCTION public.provider_is_market_compliant_for_vertical(p_provider_id uuid, p_vertical_code text, p_market_code text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
DECLARE
  required_codes text[];
  require_verified boolean;
BEGIN
  -- If this provider is sanctuary/nonprofit, treat as not compliant for markets
  -- (you already RESTRICTIVE-block bulk_offers via sanctuary_providers, but keep it explicit here)
  IF EXISTS (
    SELECT 1 FROM public.sanctuary_providers sp
    WHERE sp.provider_id = p_provider_id
  ) THEN
    RETURN false;
  END IF;

  SELECT r.required_badge_codes, r.require_verified_provider
    INTO required_codes, require_verified
  FROM public.vertical_market_requirements r
  WHERE r.vertical_code = p_vertical_code
    AND r.market_code = p_market_code
    AND r.enabled = true
  LIMIT 1;

  -- Legacy-safe fallback: if no rule configured, use your existing global function
  IF required_codes IS NULL AND require_verified IS NULL THEN
    RETURN public.provider_is_market_compliant(p_provider_id);
  END IF;

  -- Optional verified requirement per vertical/market
  IF COALESCE(require_verified, false) THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.providers p
      WHERE p.id = p_provider_id
        AND COALESCE(p.is_verified, false) = true
    ) THEN
      RETURN false;
    END IF;
  END IF;

  -- If required badge list is NULL or empty, treat as "no badge requirement"
  IF required_codes IS NULL OR array_length(required_codes, 1) IS NULL THEN
    RETURN true;
  END IF;

  -- Must have ALL required badge codes
  RETURN NOT EXISTS (
    SELECT 1
    FROM unnest(required_codes) AS req(code)
    WHERE NOT EXISTS (
      SELECT 1
      FROM public.provider_badges pb
      JOIN public.badges b ON b.id = pb.badge_id
      WHERE pb.provider_id = p_provider_id
        AND b.code = req.code
    )
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.provider_is_sanctuary(p_provider_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.providers p
    where p.id = p_provider_id
      and (
        p.specialty = 'sanctuary'
        or exists (
          select 1
          from public.provider_badges pb
          join public.badges b on b.id = pb.badge_id
          where pb.provider_id = p.id
            and b.code in ('SANCTUARY_VENDOR','NONPROFIT_VENDOR')
        )
      )
  );
$function$
;

create or replace view "public"."provider_password_rotation_v1" as  SELECT ut.user_id,
    max(ph.rotated_at) AS last_rotated_at,
    (max(ph.rotated_at) + '365 days'::interval) AS must_rotate_by
   FROM (public.user_tiers ut
     LEFT JOIN public.password_history ph ON ((ph.user_id = ut.user_id)))
  WHERE (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text]))
  GROUP BY ut.user_id;


create or replace view "public"."provider_signup_specialties_v1" as  SELECT st.code AS specialty_code,
    st.label AS specialty_label,
    st.vertical_code AS primary_vertical,
    st.kids_allowed,
    st.requires_compliance,
    vcs.is_default
   FROM (public.specialty_types st
     LEFT JOIN public.vertical_canonical_specialties vcs ON (((vcs.specialty_code = st.code) AND (vcs.vertical_code = st.vertical_code))))
  ORDER BY st.vertical_code, st.label;


create or replace view "public"."provider_specialties_v1" as  SELECT pb.provider_id,
    b.code AS badge_code,
    b.name AS badge_name,
    b.description AS badge_description,
    b.badge_type,
        CASE
            WHEN ((b.badge_type = 'vendor_specialty'::text) AND (b.code = ANY (ARRAY['farm_general'::text, 'produce_farm'::text, 'dairy_farm'::text, 'poultry_farm'::text, 'livestock_farm'::text, 'organic_farm'::text, 'hydroponic_vertical_farm'::text, 'orchard'::text, 'apiary_honey'::text, 'mushroom_farm'::text, 'csa'::text, 'greenhouse_nursery'::text, 'community_garden'::text]))) THEN 'food_and_farms'::text
            WHEN ((b.badge_type = 'vendor_specialty'::text) AND (b.code = ANY (ARRAY['bakery'::text, 'bread_bakery'::text, 'pastry_shop'::text, 'butcher'::text, 'fishmonger'::text, 'cheese_creamery'::text, 'chocolate_maker'::text, 'jam_preserves'::text, 'pickle_fermentation'::text, 'spice_herb_producer'::text, 'coffee_roaster'::text, 'tea_blender'::text]))) THEN 'food_makers'::text
            WHEN ((b.badge_type = 'vendor_specialty'::text) AND (b.code = ANY (ARRAY['farmers_market'::text, 'farm_stand'::text, 'public_market'::text, 'food_coop'::text, 'specialty_grocery'::text, 'ethnic_food_market'::text, 'bulk_foods_store'::text]))) THEN 'retail_food_access'::text
            WHEN ((b.badge_type = 'vendor_specialty'::text) AND (b.code = ANY (ARRAY['food_truck'::text, 'mobile_coffee_cart'::text, 'popup_kitchen'::text, 'festival_food_vendor'::text]))) THEN 'mobile_food'::text
            WHEN ((b.badge_type = 'institution_tag'::text) AND (b.code = ANY (ARRAY['public_school'::text, 'private_school'::text, 'charter_school'::text, 'university_college'::text, 'trade_technical_school'::text, 'community_learning_center'::text, 'library'::text, 'museum'::text, 'cultural_center'::text, 'nature_center'::text, 'environmental_education_center'::text]))) THEN 'education_and_community'::text
            WHEN ((b.badge_type = 'institution_tag'::text) AND (b.code = ANY (ARRAY['community_wellness_center'::text, 'food_pantry'::text, 'community_fridge'::text, 'nutrition_education_center'::text, 'senior_community_center'::text, 'youth_center'::text]))) THEN 'community_health'::text
            WHEN ((b.badge_type = 'institution_tag'::text) AND (b.code = ANY (ARRAY['town_hall'::text, 'community_center'::text, 'recreation_center'::text, 'public_park'::text, 'public_square_plaza'::text]))) THEN 'civic_spaces'::text
            WHEN ((b.badge_type = 'institution_tag'::text) AND (b.code = ANY (ARRAY['correctional_facility'::text, 'juvenile_detention'::text, 'probation_parole_office'::text, 'court_system'::text, 'justice_system_partner'::text]))) THEN 'justice_system'::text
            WHEN (b.badge_type = 'sanctuary_tag'::text) THEN 'sanctuaries'::text
            ELSE 'other'::text
        END AS legend_group
   FROM (public.provider_badges pb
     JOIN public.badges b ON ((b.id = pb.badge_id)));


create or replace view "public"."providers_discovery_v1" as  SELECT p.id AS provider_id,
    p.owner_user_id,
    p.vertical,
    p.provider_type,
    p.specialty,
    p.name,
    p.slug,
    p.short_description,
    p.full_description,
    p.lat,
    p.lng,
    p.city,
    p.state,
    p.country,
    p.postal_code,
    p.is_active,
    p.is_verified,
    p.verification_level,
    p.engagement_score,
    p.last_shown_at,
    p.created_at,
    p.updated_at,
    p.subscription_tier,
    p.is_discoverable,
    p.is_claimed,
    ut.role,
    ut.tier,
    ut.account_status
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = p.owner_user_id)))
  WHERE ((p.is_active = true) AND (p.is_discoverable = true) AND (ut.account_status = 'active'::text) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text])));


CREATE OR REPLACE FUNCTION public.providers_enforce_specialty_vertical_match()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- If either side is NULL, don't enforce
  IF NEW.specialty IS NULL OR NEW.primary_vertical IS NULL THEN
    RETURN NEW;
  END IF;

  -- Enforce against canonical table ONLY
  IF NOT EXISTS (
    SELECT 1
    FROM public.vertical_canonical_specialties vcs
    WHERE vcs.specialty_code = NEW.specialty
      AND vcs.vertical_code  = NEW.primary_vertical
  ) THEN
    RAISE EXCEPTION
      USING MESSAGE = format(
        'Provider specialty %s is not allowed in vertical %s',
        NEW.specialty,
        NEW.primary_vertical
      );
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.providers_set_vertical_and_normalize()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Normalize specialty to match specialty_types.code
  IF NEW.specialty IS NOT NULL THEN
    NEW.specialty := upper(NEW.specialty);
  END IF;

  -- If primary_vertical is missing, infer from specialty_types
  IF (NEW.primary_vertical IS NULL OR NEW.primary_vertical = '')
     AND NEW.specialty IS NOT NULL THEN
    SELECT st.vertical_code
    INTO NEW.primary_vertical
    FROM public.specialty_types st
    WHERE st.code = NEW.specialty;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.prune_location_checkins()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.provider_id is not null then
    delete from public.location_checkins
    where provider_id = new.provider_id
      and id not in (
        select id
        from public.location_checkins
        where provider_id = new.provider_id
        order by created_at desc
        limit 10
      );
  elsif new.landmark_id is not null then
    delete from public.location_checkins
    where landmark_id = new.landmark_id
      and id not in (
        select id
        from public.location_checkins
        where landmark_id = new.landmark_id
        order by created_at desc
        limit 10
      );
  end if;

  return new;
end;
$function$
;

create or replace view "public"."public_info_events_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    event_vertical,
    is_volunteer,
    is_large_scale_volunteer,
    requires_institutional_partner
   FROM public.events e
  WHERE ((status = 'published'::text) AND (moderation_status = 'approved'::text) AND (COALESCE(is_volunteer, false) = false) AND ((max_participants IS NULL) OR (max_participants <= 0)));


CREATE OR REPLACE FUNCTION public.record_password_change(p_user_id uuid, p_new_pw_fingerprint text)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  insert into public.password_history (user_id, pw_fingerprint, rotated_at)
  values (p_user_id, p_new_pw_fingerprint, now());
$function$
;

CREATE OR REPLACE FUNCTION public.rfqs_set_vertical_from_provider()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_vertical_code text;
BEGIN
  -- If vertical_code already set, trust it (still FK-checked)
  IF NEW.vertical_code IS NOT NULL THEN
    RETURN NEW;
  END IF;

  -- Look up the provider's primary_vertical
  SELECT p.primary_vertical
  INTO v_vertical_code
  FROM public.providers p
  WHERE p.id = NEW.provider_id;  -- ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â CHANGE provider_id IF YOUR COLUMN IS NAMED DIFFERENTLY

  -- If we found one, assign it
  IF v_vertical_code IS NOT NULL THEN
    NEW.vertical_code := v_vertical_code;
  END IF;

  RETURN NEW;
END;
$function$
;

create or replace view "public"."sanctuary_providers" as  SELECT pb.provider_id
   FROM (public.provider_badges pb
     JOIN public.badges b ON ((b.id = pb.badge_id)))
  WHERE (b.code = ANY (ARRAY['animal_sanctuary'::text, 'farm_animal_rescue'::text, 'wildlife_rehabilitation'::text, 'environmental_conservation_site'::text]));


create or replace view "public"."sanctuary_volunteer_events_v1" as  SELECT e.id,
    e.created_at,
    e.created_by,
    e.host_vendor_id,
    e.host_institution_id,
    e.title,
    e.description,
    e.event_type,
    e.start_time,
    e.end_time,
    e.location_lat,
    e.location_lng,
    e.is_kids_safe,
    e.max_participants,
    e.season_tags,
    e.holiday_tags,
    e.cultural_tags,
    e.status,
    e.moderation_status,
    p.name AS provider_name,
    p.provider_type,
    p.specialty
   FROM (public.events e
     JOIN public.providers p ON ((p.id = COALESCE(e.host_vendor_id, e.host_institution_id))))
  WHERE ((e.event_type = 'volunteer'::text) AND (public.provider_is_sanctuary(p.id) = true));


create or replace view "public"."seasonal_current_month_v1" as  SELECT (EXTRACT(month FROM (now() AT TIME ZONE 'UTC'::text)))::integer AS month_number;


create or replace view "public"."seasonal_featured_providers" as  SELECT id AS provider_id,
    public.current_season(CURRENT_DATE) AS season,
    specialty,
    provider_type,
    engagement_score,
    last_shown_at,
    ((COALESCE(engagement_score, (0)::numeric) + (
        CASE
            WHEN ((public.current_season(CURRENT_DATE) = ANY (ARRAY['summer'::text, 'fall'::text])) AND (specialty = ANY (ARRAY['Farms'::text, 'Markets'::text, 'Orchards'::text, 'Farm Stand'::text]))) THEN 20
            WHEN ((public.current_season(CURRENT_DATE) = 'winter'::text) AND (specialty = ANY (ARRAY['Bakeries'::text, 'Restaurants'::text]))) THEN 15
            WHEN ((public.current_season(CURRENT_DATE) = 'spring'::text) AND (specialty = ANY (ARRAY['Honey Farms & Apiaries'::text, 'Dairies'::text, 'Community Staples'::text]))) THEN 10
            ELSE 0
        END)::numeric) + (
        CASE
            WHEN (last_shown_at IS NULL) THEN 5
            WHEN (last_shown_at < (now() - '30 days'::interval)) THEN 3
            ELSE 0
        END)::numeric) AS seasonal_score
   FROM public.providers p
  WHERE ((provider_type = 'vendor'::text) AND (is_active = true) AND (is_discoverable = true));


create or replace view "public"."seasonal_featured_providers_v1" as  SELECT provider_id,
    owner_user_id,
    vertical,
    provider_type,
    specialty,
    name,
    slug,
    short_description,
    full_description,
    lat,
    lng,
    city,
    state,
    country,
    postal_code,
    is_active,
    is_verified,
    verification_level,
    engagement_score,
    last_shown_at,
    created_at,
    updated_at,
    subscription_tier,
    is_discoverable,
    is_claimed,
    role,
    tier,
    account_status,
        CASE
            WHEN ((public.current_season(CURRENT_DATE) = 'spring'::text) AND (specialty = ANY (ARRAY['Farms'::text, 'Honey Farms & Apiaries'::text, 'Orchards'::text, 'Markets'::text, 'Dairies'::text]))) THEN 10
            WHEN ((public.current_season(CURRENT_DATE) = 'summer'::text) AND (specialty = ANY (ARRAY['Farms'::text, 'Markets'::text, 'Food Trucks'::text, 'Honey Farms & Apiaries'::text, 'Restaurants'::text]))) THEN 10
            WHEN ((public.current_season(CURRENT_DATE) = 'fall'::text) AND (specialty = ANY (ARRAY['Farms'::text, 'Orchards'::text, 'Markets'::text, 'Bakeries'::text, 'Community Staples'::text]))) THEN 10
            WHEN ((public.current_season(CURRENT_DATE) = 'winter'::text) AND (specialty = ANY (ARRAY['Bakeries'::text, 'Community Staples'::text, 'Restaurants'::text, 'Markets'::text]))) THEN 10
            ELSE 1
        END AS seasonal_score
   FROM public.providers_discovery_v1 pd;


create or replace view "public"."seasonal_produce_current_v1" as  SELECT p.id,
    p.month,
    p.title,
    p.short_label,
    p.description,
    p.items,
    p.is_kids_safe,
    p.is_active,
    p.created_at
   FROM public.seasonal_produce p,
    public.seasonal_current_month_v1 cm
  WHERE ((p.is_active = true) AND (p.month = cm.month_number));


create or replace view "public"."seasonal_recipes_current_v1" as  SELECT r.id,
    r.month,
    r.title,
    r.short_label,
    r.description,
    r.ingredients,
    r.steps,
    r.is_kids_safe,
    r.premium_plus_only,
    r.is_active,
    r.created_at
   FROM public.seasonal_recipes r,
    public.seasonal_current_month_v1 cm
  WHERE ((r.is_active = true) AND (r.month = cm.month_number) AND (r.premium_plus_only = true));


create or replace view "public"."seasonal_seeds_current_v1" as  SELECT s.id,
    s.month,
    s.title,
    s.short_label,
    s.description,
    s.items,
    s.is_kids_safe,
    s.is_active,
    s.created_at
   FROM public.seasonal_seeds s,
    public.seasonal_current_month_v1 cm
  WHERE ((s.is_active = true) AND (s.month = cm.month_number));


CREATE OR REPLACE FUNCTION public.set_arts_culture_events_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_bulk_offer_vertical()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.vertical_code IS NULL THEN
    SELECT p.primary_vertical INTO NEW.vertical_code
    FROM public.providers p
    WHERE p.id = NEW.provider_id;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_community_nature_spots_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_community_programs_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_education_field_trips_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_experiences_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_my_role_and_tier(p_role text, p_tier text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  -- optional safety checks on inputs
  if p_role not in ('community','vendor','institution','admin') then
    raise exception 'invalid role';
  end if;

  if p_tier not in ('free','premium','premium_plus') then
    raise exception 'invalid tier';
  end if;

  update public.user_tiers
  set role = p_role,
      tier = p_tier,
      updated_at = now()
  where user_id = auth.uid();
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_my_role_and_tier(p_role text, p_tier text, p_is_kids_mode boolean DEFAULT false)
 RETURNS public.user_tiers
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_feature_flags jsonb;
  v_user_id uuid;
  v_result public.user_tiers;
begin
  -- Get the currently authenticated user
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'No authenticated user found';
  end if;

  -- Build feature_flags based on role + tier
  if p_role in ('vendor', 'institution') then
    if p_tier = 'free' then
      v_feature_flags := jsonb_build_object(
        'can_use_bulk_marketplace', false,
        'can_use_bid_marketplace',  false,
        'can_view_basic_analytics', false,
        'can_view_advanced_analytics', false,
        'is_kids_mode', false
      );
    elsif p_tier = 'premium' then
      v_feature_flags := jsonb_build_object(
        'can_use_bulk_marketplace', true,
        'can_use_bid_marketplace',  true,
        'can_view_basic_analytics', true,
        'can_view_advanced_analytics', false,
        'is_kids_mode', false
      );
    elsif p_tier = 'premium_plus' then
      v_feature_flags := jsonb_build_object(
        'can_use_bulk_marketplace', true,
        'can_use_bid_marketplace',  true,
        'can_view_basic_analytics', true,
        'can_view_advanced_analytics', true,
        'is_kids_mode', false
      );
    else
      raise exception 'Invalid tier for vendor/institution: %', p_tier;
    end if;

  elsif p_role = 'community' then
    v_feature_flags := jsonb_build_object(
      'can_use_bulk_marketplace', false,
      'can_use_bid_marketplace',  false,
      'can_view_basic_analytics', false,
      'can_view_advanced_analytics', false,
      'is_kids_mode', p_is_kids_mode
    );
  else
    raise exception 'Invalid role: %', p_role;
  end if;

  -- UPSERT and store the returned row safely
  insert into public.user_tiers (user_id, role, tier, feature_flags)
  values (v_user_id, p_role, p_tier, v_feature_flags)
  on conflict (user_id) do update
    set role          = excluded.role,
        tier          = excluded.tier,
        feature_flags = excluded.feature_flags,
        updated_at    = now()
  returning * into v_result;

  return v_result;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$
;

create or replace view "public"."specialty_governance_profile_v1" as  SELECT st.code AS specialty_code,
    st.label AS specialty_label,
    st.vertical_group,
    st.requires_compliance,
    st.kids_allowed,
    st.default_visibility,
    COALESCE(array_agg(DISTINCT sco.compliance_code) FILTER (WHERE (sco.compliance_code IS NOT NULL)), '{}'::text[]) AS compliance_codes,
    COALESCE(array_agg(DISTINCT sk.kids_code) FILTER (WHERE (sk.kids_code IS NOT NULL)), '{}'::text[]) AS kids_mode_codes
   FROM ((public.specialty_types st
     LEFT JOIN public.specialty_compliance_overlays sco ON ((sco.specialty_code = st.code)))
     LEFT JOIN public.specialty_kids_mode_overlays sk ON ((sk.specialty_code = st.code)))
  GROUP BY st.code, st.label, st.vertical_group, st.requires_compliance, st.kids_allowed, st.default_visibility;


CREATE OR REPLACE FUNCTION public.submit_institution_application(p_org_name text, p_org_website text, p_contact_name text, p_contact_email text, p_phone text, p_location_city text, p_location_state text, p_location_country text, p_description text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_app_id uuid;
  v_mod_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.institution_applications (
    user_id,
    org_name,
    org_website,
    contact_name,
    contact_email,
    phone,
    location_city,
    location_state,
    location_country,
    description,
    metadata,
    status
  )
  values (
    auth.uid(),
    p_org_name,
    p_org_website,
    p_contact_name,
    p_contact_email,
    p_phone,
    p_location_city,
    p_location_state,
    p_location_country,
    p_description,
    coalesce(p_metadata, '{}'::jsonb),
    'pending'
  )
  returning id into v_app_id;

  insert into public.moderation_queue (
    entity_type,
    entity_id,
    submitted_by,
    status,
    reason,
    created_at
  )
  values (
    'institution_application',
    v_app_id,
    auth.uid(),
    'pending',
    null,
    now()
  )
  returning id into v_mod_id;

  update public.institution_applications
  set moderation_id = v_mod_id
  where id = v_app_id;

  return v_app_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_vendor_application(p_application_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_user_id_col text := 'user_id';
  v_has_status boolean;
  v_has_submitted_at boolean;
  v_status text;
  v_user uuid;
begin
  -- ensure the row exists & belongs to caller
  execute 'select user_id from public.vendor_applications where id = $1'
    into v_user
    using p_application_id;

  if v_user is null then
    raise exception 'Application not found';
  end if;

  if v_user <> auth.uid() then
    raise exception 'Not your application';
  end if;

  if not public.can_submit_vendor_application(v_user) then
    raise exception 'Vendor submission blocked: age-band gate not satisfied (requires engine flag).';
  end if;

  select exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='status'
  ) into v_has_status;

  select exists(
    select 1 from information_schema.columns
    where table_schema='public' and table_name='vendor_applications' and column_name='submitted_at'
  ) into v_has_submitted_at;

  if v_has_status then
    execute 'select status from public.vendor_applications where id = $1'
      into v_status
      using p_application_id;

    if v_status not in ('draft','needs_info') then
      raise exception 'Only draft/needs_info applications can be submitted';
    end if;

    if v_has_submitted_at then
      execute 'update public.vendor_applications set status = ''submitted'', submitted_at = now() where id = $1'
        using p_application_id;
    else
      execute 'update public.vendor_applications set status = ''submitted'' where id = $1'
        using p_application_id;
    end if;
  else
    -- no status column: only stamp submitted_at if available
    if v_has_submitted_at then
      execute 'update public.vendor_applications set submitted_at = now() where id = $1'
        using p_application_id;
    else
      raise exception 'vendor_applications missing status/submitted_at; cannot submit safely';
    end if;
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_vendor_application(p_org_name text, p_org_website text, p_contact_name text, p_contact_email text, p_phone text, p_location_city text, p_location_state text, p_location_country text, p_description text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_app_id uuid;
  v_mod_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- 1) Application row
  insert into public.vendor_applications (
    user_id,
    org_name,
    org_website,
    contact_name,
    contact_email,
    phone,
    location_city,
    location_state,
    location_country,
    description,
    metadata,
    status
  )
  values (
    auth.uid(),
    p_org_name,
    p_org_website,
    p_contact_name,
    p_contact_email,
    p_phone,
    p_location_city,
    p_location_state,
    p_location_country,
    p_description,
    coalesce(p_metadata, '{}'::jsonb),
    'pending'
  )
  returning id into v_app_id;

  -- 2) Moderation queue row
  insert into public.moderation_queue (
    entity_type,
    entity_id,
    submitted_by,
    status,
    reason,
    created_at
  )
  values (
    'vendor_application',
    v_app_id,
    auth.uid(),
    'pending',
    null,
    now()
  )
  returning id into v_mod_id;

  -- 3) Link back to application
  update public.vendor_applications
  set moderation_id = v_mod_id
  where id = v_app_id;

  return v_app_id;
end;
$function$
;

create or replace view "public"."teen_events_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    event_vertical,
    is_volunteer,
    is_large_scale_volunteer,
    requires_institutional_partner
   FROM public.events e
  WHERE ((status = 'published'::text) AND (moderation_status = 'approved'::text) AND (COALESCE(is_volunteer, false) = false) AND (event_type = 'community'::text) AND ((COALESCE(community_tags, '[]'::jsonb) ?| ARRAY['festival'::text, 'family'::text, 'family_friendly'::text, 'community_festival'::text]) OR (COALESCE(holiday_tags, ARRAY[]::text[]) && ARRAY['festival'::text, 'holiday'::text, 'parade'::text, 'market'::text]) OR (COALESCE(cultural_tags, ARRAY[]::text[]) && ARRAY['festival'::text, 'cultural_festival'::text, 'community'::text])));


create or replace view "public"."teen_volunteer_events_v1" as  SELECT e.id,
    e.created_at,
    e.created_by,
    e.host_vendor_id,
    e.host_institution_id,
    e.title,
    e.description,
    e.event_type,
    e.start_time,
    e.end_time,
    e.location_lat,
    e.location_lng,
    e.is_kids_safe,
    e.max_participants,
    e.season_tags,
    e.holiday_tags,
    e.cultural_tags,
    e.status,
    e.moderation_status,
    e.seasonal_category,
    e.kids_mode_safe,
    e.community_tags,
    e.event_vertical,
    e.is_volunteer,
    e.is_large_scale_volunteer,
    e.requires_institutional_partner
   FROM (public.events e
     JOIN public.providers p ON ((p.id = e.host_vendor_id)))
  WHERE ((e.status = 'published'::text) AND (e.moderation_status = 'approved'::text) AND (e.event_type = 'volunteer'::text) AND (COALESCE(e.is_volunteer, false) = true) AND (lower(COALESCE(p.specialty, ''::text)) = ANY (ARRAY['farm'::text, 'sanctuary'::text])));


CREATE OR REPLACE FUNCTION public.tg_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$
;

create or replace view "public"."user_tier_membership_status_v1" as  SELECT ut.user_id,
    ut.role,
    ut.tier,
    m.id AS membership_id,
    m.started_at,
    m.ends_at,
    m.status,
    m.auto_renew,
    (GREATEST((0)::numeric, floor((EXTRACT(epoch FROM (m.ends_at - now())) / (86400)::numeric))))::integer AS days_left
   FROM (public.user_tiers ut
     LEFT JOIN LATERAL ( SELECT m_1.id,
            m_1.user_id,
            m_1.tier,
            m_1.started_at,
            m_1.ends_at,
            m_1.auto_renew,
            m_1.status,
            m_1.created_at,
            m_1.updated_at
           FROM public.user_tier_memberships m_1
          WHERE ((m_1.user_id = ut.user_id) AND (m_1.status = 'active'::text))
          ORDER BY m_1.ends_at DESC
         LIMIT 1) m ON (true));


create or replace view "public"."user_tier_memberships_expiring_soon_v1" as  SELECT user_id,
    role,
    tier,
    membership_id,
    started_at,
    ends_at,
    auto_renew,
    days_left
   FROM public.user_tier_membership_status_v1 s
  WHERE ((tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])) AND ((days_left >= 0) AND (days_left <= 30)) AND (membership_id IS NOT NULL));


create or replace view "public"."vendor_experience_analytics_daily_v1" as  SELECT b.vendor_id AS provider_id,
    (date_trunc('day'::text, b.created_at))::date AS day,
    count(*) AS quotes_submitted,
    count(*) FILTER (WHERE (b.status = 'accepted'::text)) AS quotes_accepted,
    sum(b.price_total) FILTER (WHERE (b.status = 'accepted'::text)) AS accepted_revenue,
    sum(b.price_total) AS quoted_revenue
   FROM (public.bids b
     JOIN public.rfqs r ON ((r.id = b.rfq_id)))
  WHERE (r.category = 'experience'::text)
  GROUP BY b.vendor_id, (date_trunc('day'::text, b.created_at));


CREATE OR REPLACE FUNCTION public.vendor_experience_analytics_for_current_user()
 RETURNS TABLE(provider_id uuid, day date, quotes_submitted integer, quotes_accepted integer, accepted_revenue numeric, quoted_revenue numeric)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    v.provider_id,
    v.day,
    v.quotes_submitted,
    v.quotes_accepted,
    v.accepted_revenue,
    v.quoted_revenue
  from public.vendor_experience_analytics_daily_v1 v
  join public.providers p
    on p.id = v.provider_id
  join public.user_tiers ut
    on ut.user_id = p.owner_user_id
  where
    p.owner_user_id = auth.uid()
    and ut.role = 'vendor'
    and (
      ut.feature_flags ->> 'can_view_advanced_analytics'
    )::boolean = true;
$function$
;

create or replace view "public"."vendor_experience_analytics_v1" as  SELECT b.vendor_id,
    b.owner_user_id,
    b.analytics_date,
    b.profile_views,
    b.directory_clicks,
    b.experience_views,
    b.favorites_added,
    b.saves_to_list,
    a.bulk_inquiries,
    a.bulk_orders,
    a.bid_invites,
    a.bids_submitted,
    a.bids_won,
    a.total_revenue,
    a.avg_order_value,
    a.conversion_rate,
    d.impressions,
    d.clicks,
    d.saves,
    d.rfq_views,
    d.bid_views
   FROM ((public.vendor_analytics_basic_daily b
     LEFT JOIN public.vendor_analytics_advanced_daily a ON (((a.vendor_id = b.vendor_id) AND (a.owner_user_id = b.owner_user_id) AND (a.analytics_date = b.analytics_date))))
     LEFT JOIN public.vendor_analytics_daily d ON (((d.vendor_id = b.vendor_id) AND (d.day = b.analytics_date))));


CREATE OR REPLACE FUNCTION public.vendor_is_market_compliant_for_vertical(p_user_id uuid, p_vertical_code text, p_market_code text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.providers p
    WHERE p.owner_user_id = p_user_id
      AND (p.vertical = p_vertical_code OR p.primary_vertical = p_vertical_code)
      AND public.provider_is_market_compliant_for_vertical(p.id, p_vertical_code, p_market_code) = true
  );
$function$
;

create or replace view "public"."vendor_volunteer_summary_v1" as  SELECT e.host_vendor_id AS vendor_id,
    count(DISTINCT e.id) AS volunteer_events_count,
    count(er.id) AS volunteer_signups_count
   FROM (public.events e
     LEFT JOIN public.event_registrations er ON ((er.event_id = e.id)))
  WHERE ((e.host_vendor_id IS NOT NULL) AND (e.event_type = ANY (ARRAY['volunteer'::text, 'volunteer_event'::text])) AND (e.status = 'published'::text) AND (e.moderation_status = 'approved'::text))
  GROUP BY e.host_vendor_id;


create or replace view "public"."vertical_canonical_landmarks_v1" as  SELECT l.id AS landmark_id,
    l.name,
    l.description,
    l.landmark_vertical,
    cv.label AS vertical_label,
    l.lat,
    l.lng,
    l.is_kid_safe,
    l.kids_mode_safe,
    l.is_published,
    l.community_focus_tags
   FROM (public.landmarks l
     JOIN public.canonical_verticals cv ON ((cv.vertical_code = l.landmark_vertical)));


create or replace view "public"."vertical_conditions_v1" as  SELECT cv.vertical_code,
    cv.label,
    vc.allow_kids_mode,
    vc.allow_experiences,
    vc.allow_volunteering,
    vc.is_active
   FROM (public.canonical_verticals cv
     LEFT JOIN public.vertical_conditions vc ON ((vc.vertical_code = cv.vertical_code)));


create or replace view "public"."vertical_enrichment_matrix_v1" as  SELECT vertical_code,
    label AS vertical_label,
    (EXISTS ( SELECT 1
           FROM public.providers p
          WHERE (p.vertical = v.vertical_code))) AS has_provider,
    (EXISTS ( SELECT 1
           FROM public.landmarks l
          WHERE (l.landmark_vertical = v.vertical_code))) AS has_landmark,
    (EXISTS ( SELECT 1
           FROM public.specialty_vertical_overlays s
          WHERE (s.vertical_code = v.vertical_code))) AS has_specialties
   FROM public.canonical_verticals v;


create or replace view "public"."vertical_landmarks_v1" as  SELECT cv.vertical_code,
    cv.label AS vertical_label,
    l.id AS landmark_id,
    l.name AS landmark_name,
    l.description,
    l.landmark_type,
    l.lat,
    l.lng,
    l.is_kid_safe,
    l.kids_mode_safe,
    l.is_published,
    l.moderation_status,
    l.landmark_vertical,
    l.community_focus_tags,
    l.seasonal_category
   FROM (public.canonical_verticals cv
     LEFT JOIN public.landmarks l ON ((l.landmark_vertical = cv.vertical_code)))
  ORDER BY cv.sort_order, cv.vertical_code;


create or replace view "public"."vertical_provider_counts_v1" as  SELECT cv.vertical_code,
    cv.label AS vertical_label,
    count(*) AS total_providers,
    count(*) FILTER (WHERE p.is_discoverable) AS discoverable_providers
   FROM (public.canonical_verticals cv
     LEFT JOIN public.providers p ON ((p.primary_vertical = cv.vertical_code)))
  GROUP BY cv.vertical_code, cv.label
  ORDER BY cv.sort_order, cv.vertical_code;


CREATE OR REPLACE FUNCTION public.vertical_role_allowed(p_vertical text)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  select public.current_user_role() = any(vp.allowed_roles)
  from public.vertical_policy vp
  where vp.vertical_code = p_vertical;
$function$
;

create or replace view "public"."vertical_specialties_v1" as  SELECT vcs.vertical_code,
    st.code AS specialty_code,
    st.label AS specialty_label,
    true AS is_default_for_vertical
   FROM (public.vertical_canonical_specialties vcs
     JOIN public.specialty_types st ON ((st.code = vcs.specialty_code)))
UNION ALL
 SELECT svo.vertical_code,
    st.code AS specialty_code,
    st.label AS specialty_label,
    false AS is_default_for_vertical
   FROM (public.specialty_vertical_overlays svo
     JOIN public.specialty_types st ON ((st.code = svo.specialty_code)));


create or replace view "public"."vertical_specialty_effective_v1" as  SELECT vcs.vertical_code,
    st.code AS specialty_code,
    st.label AS specialty_label,
    true AS is_default_for_vertical
   FROM (public.vertical_canonical_specialties vcs
     JOIN public.specialty_types st ON ((st.code = vcs.specialty_code)))
UNION
 SELECT svo.vertical_code,
    st.code AS specialty_code,
    st.label AS specialty_label,
    false AS is_default_for_vertical
   FROM (public.specialty_vertical_overlays svo
     JOIN public.specialty_types st ON ((st.code = svo.specialty_code)));


create or replace view "public"."volunteer_events_v1" as  SELECT id,
    created_at,
    created_by,
    host_vendor_id,
    host_institution_id,
    title,
    description,
    event_type,
    start_time,
    end_time,
    location_lat,
    location_lng,
    is_kids_safe,
    max_participants,
    season_tags,
    holiday_tags,
    cultural_tags,
    status,
    moderation_status,
    seasonal_category,
    kids_mode_safe,
    community_tags,
    event_vertical,
    is_volunteer,
    is_large_scale_volunteer,
    requires_institutional_partner
   FROM public.events e
  WHERE ((is_volunteer = true) AND (status = 'published'::text) AND (moderation_status = 'approved'::text));


create or replace view "public"."volunteer_role_summary_v1" as  SELECT er.role,
    count(DISTINCT er.user_id) AS unique_users,
    count(er.id) AS total_signups
   FROM (public.event_registrations er
     JOIN public.events e ON ((e.id = er.event_id)))
  WHERE ((e.event_type = ANY (ARRAY['volunteer'::text, 'volunteer_event'::text])) AND (e.status = 'published'::text) AND (e.moderation_status = 'approved'::text))
  GROUP BY er.role;


CREATE OR REPLACE FUNCTION public._specialty_capability_allowed(p_specialty_code text, p_capability_key text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(
    (select ec.is_allowed
       from public.specialty_effective_capabilities_v1 ec
      where ec.specialty_code = p_specialty_code
        and ec.capability_key = p_capability_key),
    false
  );
$function$
;

create or replace view "public"."agriculture_rfqs_v1" as  SELECT id,
    institution_id,
    vertical_code,
    title,
    description,
    category,
    quantity,
    unit,
    delivery_start_date,
    delivery_end_date,
    status,
    created_at,
    updated_at
   FROM public.market_rfqs_v1
  WHERE (vertical_code = 'AGRICULTURE_FOOD'::text);


create or replace view "public"."arts_culture_rfqs_v1" as  SELECT id,
    institution_id,
    vertical_code,
    title,
    description,
    category,
    quantity,
    unit,
    delivery_start_date,
    delivery_end_date,
    status,
    created_at,
    updated_at
   FROM public.market_rfqs_v1
  WHERE (vertical_code = 'ARTS_CULTURE_HERITAGE'::text);


create or replace view "public"."community_rfqs_v1" as  SELECT id,
    institution_id,
    vertical_code,
    title,
    description,
    category,
    quantity,
    unit,
    delivery_start_date,
    delivery_end_date,
    status,
    created_at,
    updated_at
   FROM public.market_rfqs_v1
  WHERE (vertical_code = 'COMMUNITY_SERVICES'::text);


create or replace view "public"."construction_rfqs_v1" as  SELECT id,
    institution_id,
    vertical_code,
    title,
    description,
    category,
    quantity,
    unit,
    delivery_start_date,
    delivery_end_date,
    status,
    created_at,
    updated_at
   FROM public.market_rfqs_v1
  WHERE (vertical_code = 'CONSTRUCTION_BUILT_ENVIRONMENT'::text);


create or replace view "public"."education_rfqs_v1" as  SELECT id,
    institution_id,
    vertical_code,
    title,
    description,
    category,
    quantity,
    unit,
    delivery_start_date,
    delivery_end_date,
    status,
    created_at,
    updated_at
   FROM public.market_rfqs_v1
  WHERE (vertical_code = 'EDUCATION_WORKFORCE'::text);


create or replace view "public"."experiences_rfqs_v1" as  SELECT id,
    institution_id,
    vertical_code,
    title,
    description,
    category,
    quantity,
    unit,
    delivery_start_date,
    delivery_end_date,
    status,
    created_at,
    updated_at
   FROM public.market_rfqs_v1
  WHERE (vertical_code = 'EXPERIENCES_RECREATION_TOURISM'::text);


create or replace view "public"."provider_flags_v1" as  SELECT id AS provider_id,
    (EXISTS ( SELECT 1
           FROM public.sanctuary_providers s
          WHERE (s.provider_id = p.id))) AS is_sanctuary,
    (EXISTS ( SELECT 1
           FROM public.justice_institutions j
          WHERE (j.provider_id = p.id))) AS is_justice_institution
   FROM public.providers p;


create or replace view "public"."provider_vertical_profile_v1" as  SELECT p.id AS provider_id,
    p.name,
    p.vertical AS ui_vertical,
    p.primary_vertical,
    cv.label AS primary_vertical_label,
    p.specialty,
    st.label AS specialty_label,
    vse.is_default_for_vertical,
    p.city,
    p.state,
    p.country,
    p.lat,
    p.lng,
    p.is_active,
    p.is_discoverable,
    p.subscription_tier,
    p.subscription_status
   FROM (((public.providers p
     LEFT JOIN public.canonical_verticals cv ON ((cv.vertical_code = p.primary_vertical)))
     LEFT JOIN public.vertical_specialty_effective_v1 vse ON (((vse.vertical_code = p.primary_vertical) AND (vse.specialty_code = p.specialty))))
     LEFT JOIN public.specialty_types st ON ((st.code = p.specialty)));


create or replace view "public"."seasonal_crafts_current_v1" as  SELECT c.id,
    c.month,
    c.title,
    c.craft_type,
    c.difficulty,
    c.requires_parent,
    c.is_kids_safe,
    c.description,
    c.materials,
    c.steps,
    c.is_active,
    c.created_at
   FROM public.seasonal_crafts c,
    public.seasonal_current_month_v1 cm
  WHERE ((c.is_active = true) AND (c.month = cm.month_number));


create or replace view "public"."specialty_effective_groups_v1" as  WITH base AS (
         SELECT DISTINCT vs.specialty_code,
            vs.specialty_label,
            vs.vertical_code
           FROM public.vertical_specialties_v1 vs
        ), grp AS (
         SELECT b.specialty_code,
                CASE
                    WHEN (EXISTS ( SELECT 1
                       FROM public.sanctuary_specialties s
                      WHERE (s.specialty_code = b.specialty_code))) THEN 'SANCTUARY_RESCUE'::text
                    ELSE 'STANDARD_VENDOR'::text
                END AS group_key
           FROM base b
        )
 SELECT specialty_code,
    group_key
   FROM grp;


create or replace view "public"."vertical_profile_v1" as  SELECT vertical_code,
    label AS vertical_label,
    ( SELECT p.id
           FROM public.providers p
          WHERE (p.primary_vertical = cv.vertical_code)
          ORDER BY p.created_at
         LIMIT 1) AS default_provider_id,
    ( SELECT p.name
           FROM public.providers p
          WHERE (p.primary_vertical = cv.vertical_code)
          ORDER BY p.created_at
         LIMIT 1) AS default_provider_name,
    ( SELECT l.id
           FROM public.landmarks l
          WHERE (l.landmark_vertical = cv.vertical_code)
          ORDER BY l.created_at
         LIMIT 1) AS default_landmark_id,
    ( SELECT l.name
           FROM public.landmarks l
          WHERE (l.landmark_vertical = cv.vertical_code)
          ORDER BY l.created_at
         LIMIT 1) AS default_landmark_name,
    COALESCE(( SELECT array_agg(vse.specialty_code ORDER BY vse.specialty_code) AS array_agg
           FROM public.vertical_specialty_effective_v1 vse
          WHERE (vse.vertical_code = cv.vertical_code)), ARRAY[]::text[]) AS specialties
   FROM public.canonical_verticals cv
  ORDER BY vertical_code;


create or replace view "public"."vertical_specialty_coverage_v1" as  SELECT vertical_code,
    count(*) FILTER (WHERE is_default_for_vertical) AS default_specialty_count,
    count(*) AS total_specialty_count
   FROM public.vertical_specialty_effective_v1 vse
  GROUP BY vertical_code
  ORDER BY vertical_code;


create or replace view "public"."vertical_status_v1" as  SELECT vertical_code,
    vertical_label,
    (default_provider_id IS NOT NULL) AS has_provider_anchor,
    (default_landmark_id IS NOT NULL) AS has_landmark_anchor,
    (( SELECT count(*) AS count
           FROM public.vertical_specialty_effective_v1 vse
          WHERE (vse.vertical_code = vp.vertical_code)) >= 1) AS has_specialties
   FROM public.vertical_profile_v1 vp
  ORDER BY vertical_code;


create or replace view "public"."specialty_effective_capabilities_v1" as  WITH s AS (
         SELECT DISTINCT vertical_specialties_v1.specialty_code
           FROM public.vertical_specialties_v1
        ), g AS (
         SELECT s_1.specialty_code,
            eg.group_key
           FROM (s s_1
             JOIN public.specialty_effective_groups_v1 eg USING (specialty_code))
        ), c AS (
         SELECT specialty_capabilities.capability_key,
            specialty_capabilities.default_allowed
           FROM public.specialty_capabilities
        ), explicit AS (
         SELECT specialty_capability_grants.specialty_code,
            specialty_capability_grants.capability_key,
            specialty_capability_grants.is_allowed
           FROM public.specialty_capability_grants
        ), grouped AS (
         SELECT g.specialty_code,
            gg.capability_key,
            gg.is_allowed
           FROM (g
             JOIN public.group_capability_grants gg ON ((gg.group_key = g.group_key)))
        )
 SELECT s.specialty_code,
    c.capability_key,
    COALESCE(explicit.is_allowed, grouped.is_allowed, c.default_allowed, false) AS is_allowed,
        CASE
            WHEN (explicit.is_allowed IS NOT NULL) THEN 'SPECIALTY_OVERRIDE'::text
            WHEN (grouped.is_allowed IS NOT NULL) THEN 'GROUP_RULE'::text
            ELSE 'CAPABILITY_DEFAULT'::text
        END AS source
   FROM (((s
     CROSS JOIN c)
     LEFT JOIN explicit ON (((explicit.specialty_code = s.specialty_code) AND (explicit.capability_key = c.capability_key))))
     LEFT JOIN grouped ON (((grouped.specialty_code = s.specialty_code) AND (grouped.capability_key = c.capability_key))));


grant delete on table "public"."_backup_specialty_vertical_overlays" to "anon";

grant insert on table "public"."_backup_specialty_vertical_overlays" to "anon";

grant references on table "public"."_backup_specialty_vertical_overlays" to "anon";

grant select on table "public"."_backup_specialty_vertical_overlays" to "anon";

grant trigger on table "public"."_backup_specialty_vertical_overlays" to "anon";

grant truncate on table "public"."_backup_specialty_vertical_overlays" to "anon";

grant update on table "public"."_backup_specialty_vertical_overlays" to "anon";

grant delete on table "public"."_backup_specialty_vertical_overlays" to "authenticated";

grant insert on table "public"."_backup_specialty_vertical_overlays" to "authenticated";

grant references on table "public"."_backup_specialty_vertical_overlays" to "authenticated";

grant select on table "public"."_backup_specialty_vertical_overlays" to "authenticated";

grant trigger on table "public"."_backup_specialty_vertical_overlays" to "authenticated";

grant truncate on table "public"."_backup_specialty_vertical_overlays" to "authenticated";

grant update on table "public"."_backup_specialty_vertical_overlays" to "authenticated";

grant delete on table "public"."_backup_specialty_vertical_overlays" to "service_role";

grant insert on table "public"."_backup_specialty_vertical_overlays" to "service_role";

grant references on table "public"."_backup_specialty_vertical_overlays" to "service_role";

grant select on table "public"."_backup_specialty_vertical_overlays" to "service_role";

grant trigger on table "public"."_backup_specialty_vertical_overlays" to "service_role";

grant truncate on table "public"."_backup_specialty_vertical_overlays" to "service_role";

grant update on table "public"."_backup_specialty_vertical_overlays" to "service_role";

grant delete on table "public"."_backup_vertical_canonical_specialties" to "anon";

grant insert on table "public"."_backup_vertical_canonical_specialties" to "anon";

grant references on table "public"."_backup_vertical_canonical_specialties" to "anon";

grant select on table "public"."_backup_vertical_canonical_specialties" to "anon";

grant trigger on table "public"."_backup_vertical_canonical_specialties" to "anon";

grant truncate on table "public"."_backup_vertical_canonical_specialties" to "anon";

grant update on table "public"."_backup_vertical_canonical_specialties" to "anon";

grant delete on table "public"."_backup_vertical_canonical_specialties" to "authenticated";

grant insert on table "public"."_backup_vertical_canonical_specialties" to "authenticated";

grant references on table "public"."_backup_vertical_canonical_specialties" to "authenticated";

grant select on table "public"."_backup_vertical_canonical_specialties" to "authenticated";

grant trigger on table "public"."_backup_vertical_canonical_specialties" to "authenticated";

grant truncate on table "public"."_backup_vertical_canonical_specialties" to "authenticated";

grant update on table "public"."_backup_vertical_canonical_specialties" to "authenticated";

grant delete on table "public"."_backup_vertical_canonical_specialties" to "service_role";

grant insert on table "public"."_backup_vertical_canonical_specialties" to "service_role";

grant references on table "public"."_backup_vertical_canonical_specialties" to "service_role";

grant select on table "public"."_backup_vertical_canonical_specialties" to "service_role";

grant trigger on table "public"."_backup_vertical_canonical_specialties" to "service_role";

grant truncate on table "public"."_backup_vertical_canonical_specialties" to "service_role";

grant update on table "public"."_backup_vertical_canonical_specialties" to "service_role";

grant delete on table "public"."account_deletion_requests" to "anon";

grant insert on table "public"."account_deletion_requests" to "anon";

grant references on table "public"."account_deletion_requests" to "anon";

grant select on table "public"."account_deletion_requests" to "anon";

grant trigger on table "public"."account_deletion_requests" to "anon";

grant truncate on table "public"."account_deletion_requests" to "anon";

grant update on table "public"."account_deletion_requests" to "anon";

grant delete on table "public"."account_deletion_requests" to "authenticated";

grant insert on table "public"."account_deletion_requests" to "authenticated";

grant references on table "public"."account_deletion_requests" to "authenticated";

grant select on table "public"."account_deletion_requests" to "authenticated";

grant trigger on table "public"."account_deletion_requests" to "authenticated";

grant truncate on table "public"."account_deletion_requests" to "authenticated";

grant update on table "public"."account_deletion_requests" to "authenticated";

grant delete on table "public"."account_deletion_requests" to "service_role";

grant insert on table "public"."account_deletion_requests" to "service_role";

grant references on table "public"."account_deletion_requests" to "service_role";

grant select on table "public"."account_deletion_requests" to "service_role";

grant trigger on table "public"."account_deletion_requests" to "service_role";

grant truncate on table "public"."account_deletion_requests" to "service_role";

grant update on table "public"."account_deletion_requests" to "service_role";

grant references on table "public"."app_settings" to "anon";

grant select on table "public"."app_settings" to "anon";

grant trigger on table "public"."app_settings" to "anon";

grant truncate on table "public"."app_settings" to "anon";

grant references on table "public"."app_settings" to "authenticated";

grant select on table "public"."app_settings" to "authenticated";

grant trigger on table "public"."app_settings" to "authenticated";

grant truncate on table "public"."app_settings" to "authenticated";

grant delete on table "public"."app_settings" to "service_role";

grant insert on table "public"."app_settings" to "service_role";

grant references on table "public"."app_settings" to "service_role";

grant select on table "public"."app_settings" to "service_role";

grant trigger on table "public"."app_settings" to "service_role";

grant truncate on table "public"."app_settings" to "service_role";

grant update on table "public"."app_settings" to "service_role";

grant delete on table "public"."arts_culture_event_context_profiles" to "anon";

grant insert on table "public"."arts_culture_event_context_profiles" to "anon";

grant references on table "public"."arts_culture_event_context_profiles" to "anon";

grant select on table "public"."arts_culture_event_context_profiles" to "anon";

grant trigger on table "public"."arts_culture_event_context_profiles" to "anon";

grant truncate on table "public"."arts_culture_event_context_profiles" to "anon";

grant update on table "public"."arts_culture_event_context_profiles" to "anon";

grant delete on table "public"."arts_culture_event_context_profiles" to "authenticated";

grant insert on table "public"."arts_culture_event_context_profiles" to "authenticated";

grant references on table "public"."arts_culture_event_context_profiles" to "authenticated";

grant select on table "public"."arts_culture_event_context_profiles" to "authenticated";

grant trigger on table "public"."arts_culture_event_context_profiles" to "authenticated";

grant truncate on table "public"."arts_culture_event_context_profiles" to "authenticated";

grant update on table "public"."arts_culture_event_context_profiles" to "authenticated";

grant delete on table "public"."arts_culture_event_context_profiles" to "service_role";

grant insert on table "public"."arts_culture_event_context_profiles" to "service_role";

grant references on table "public"."arts_culture_event_context_profiles" to "service_role";

grant select on table "public"."arts_culture_event_context_profiles" to "service_role";

grant trigger on table "public"."arts_culture_event_context_profiles" to "service_role";

grant truncate on table "public"."arts_culture_event_context_profiles" to "service_role";

grant update on table "public"."arts_culture_event_context_profiles" to "service_role";

grant delete on table "public"."arts_culture_events" to "anon";

grant insert on table "public"."arts_culture_events" to "anon";

grant references on table "public"."arts_culture_events" to "anon";

grant select on table "public"."arts_culture_events" to "anon";

grant trigger on table "public"."arts_culture_events" to "anon";

grant truncate on table "public"."arts_culture_events" to "anon";

grant update on table "public"."arts_culture_events" to "anon";

grant delete on table "public"."arts_culture_events" to "authenticated";

grant insert on table "public"."arts_culture_events" to "authenticated";

grant references on table "public"."arts_culture_events" to "authenticated";

grant select on table "public"."arts_culture_events" to "authenticated";

grant trigger on table "public"."arts_culture_events" to "authenticated";

grant truncate on table "public"."arts_culture_events" to "authenticated";

grant update on table "public"."arts_culture_events" to "authenticated";

grant delete on table "public"."arts_culture_events" to "service_role";

grant insert on table "public"."arts_culture_events" to "service_role";

grant references on table "public"."arts_culture_events" to "service_role";

grant select on table "public"."arts_culture_events" to "service_role";

grant trigger on table "public"."arts_culture_events" to "service_role";

grant truncate on table "public"."arts_culture_events" to "service_role";

grant update on table "public"."arts_culture_events" to "service_role";

grant delete on table "public"."badges" to "anon";

grant insert on table "public"."badges" to "anon";

grant references on table "public"."badges" to "anon";

grant select on table "public"."badges" to "anon";

grant trigger on table "public"."badges" to "anon";

grant truncate on table "public"."badges" to "anon";

grant update on table "public"."badges" to "anon";

grant delete on table "public"."badges" to "authenticated";

grant insert on table "public"."badges" to "authenticated";

grant references on table "public"."badges" to "authenticated";

grant select on table "public"."badges" to "authenticated";

grant trigger on table "public"."badges" to "authenticated";

grant truncate on table "public"."badges" to "authenticated";

grant update on table "public"."badges" to "authenticated";

grant delete on table "public"."badges" to "service_role";

grant insert on table "public"."badges" to "service_role";

grant references on table "public"."badges" to "service_role";

grant select on table "public"."badges" to "service_role";

grant trigger on table "public"."badges" to "service_role";

grant truncate on table "public"."badges" to "service_role";

grant update on table "public"."badges" to "service_role";

grant delete on table "public"."bids" to "anon";

grant insert on table "public"."bids" to "anon";

grant references on table "public"."bids" to "anon";

grant select on table "public"."bids" to "anon";

grant trigger on table "public"."bids" to "anon";

grant truncate on table "public"."bids" to "anon";

grant update on table "public"."bids" to "anon";

grant delete on table "public"."bids" to "authenticated";

grant insert on table "public"."bids" to "authenticated";

grant references on table "public"."bids" to "authenticated";

grant select on table "public"."bids" to "authenticated";

grant trigger on table "public"."bids" to "authenticated";

grant truncate on table "public"."bids" to "authenticated";

grant update on table "public"."bids" to "authenticated";

grant delete on table "public"."bids" to "service_role";

grant insert on table "public"."bids" to "service_role";

grant references on table "public"."bids" to "service_role";

grant select on table "public"."bids" to "service_role";

grant trigger on table "public"."bids" to "service_role";

grant truncate on table "public"."bids" to "service_role";

grant update on table "public"."bids" to "service_role";

grant delete on table "public"."billing_customers" to "anon";

grant insert on table "public"."billing_customers" to "anon";

grant references on table "public"."billing_customers" to "anon";

grant select on table "public"."billing_customers" to "anon";

grant trigger on table "public"."billing_customers" to "anon";

grant truncate on table "public"."billing_customers" to "anon";

grant update on table "public"."billing_customers" to "anon";

grant delete on table "public"."billing_customers" to "authenticated";

grant insert on table "public"."billing_customers" to "authenticated";

grant references on table "public"."billing_customers" to "authenticated";

grant select on table "public"."billing_customers" to "authenticated";

grant trigger on table "public"."billing_customers" to "authenticated";

grant truncate on table "public"."billing_customers" to "authenticated";

grant update on table "public"."billing_customers" to "authenticated";

grant delete on table "public"."billing_customers" to "service_role";

grant insert on table "public"."billing_customers" to "service_role";

grant references on table "public"."billing_customers" to "service_role";

grant select on table "public"."billing_customers" to "service_role";

grant trigger on table "public"."billing_customers" to "service_role";

grant truncate on table "public"."billing_customers" to "service_role";

grant update on table "public"."billing_customers" to "service_role";

grant delete on table "public"."bulk_offer_analytics" to "anon";

grant insert on table "public"."bulk_offer_analytics" to "anon";

grant references on table "public"."bulk_offer_analytics" to "anon";

grant select on table "public"."bulk_offer_analytics" to "anon";

grant trigger on table "public"."bulk_offer_analytics" to "anon";

grant truncate on table "public"."bulk_offer_analytics" to "anon";

grant update on table "public"."bulk_offer_analytics" to "anon";

grant delete on table "public"."bulk_offer_analytics" to "authenticated";

grant insert on table "public"."bulk_offer_analytics" to "authenticated";

grant references on table "public"."bulk_offer_analytics" to "authenticated";

grant select on table "public"."bulk_offer_analytics" to "authenticated";

grant trigger on table "public"."bulk_offer_analytics" to "authenticated";

grant truncate on table "public"."bulk_offer_analytics" to "authenticated";

grant update on table "public"."bulk_offer_analytics" to "authenticated";

grant delete on table "public"."bulk_offer_analytics" to "service_role";

grant insert on table "public"."bulk_offer_analytics" to "service_role";

grant references on table "public"."bulk_offer_analytics" to "service_role";

grant select on table "public"."bulk_offer_analytics" to "service_role";

grant trigger on table "public"."bulk_offer_analytics" to "service_role";

grant truncate on table "public"."bulk_offer_analytics" to "service_role";

grant update on table "public"."bulk_offer_analytics" to "service_role";

grant delete on table "public"."bulk_offers" to "anon";

grant insert on table "public"."bulk_offers" to "anon";

grant references on table "public"."bulk_offers" to "anon";

grant select on table "public"."bulk_offers" to "anon";

grant trigger on table "public"."bulk_offers" to "anon";

grant truncate on table "public"."bulk_offers" to "anon";

grant update on table "public"."bulk_offers" to "anon";

grant delete on table "public"."bulk_offers" to "authenticated";

grant insert on table "public"."bulk_offers" to "authenticated";

grant references on table "public"."bulk_offers" to "authenticated";

grant select on table "public"."bulk_offers" to "authenticated";

grant trigger on table "public"."bulk_offers" to "authenticated";

grant truncate on table "public"."bulk_offers" to "authenticated";

grant update on table "public"."bulk_offers" to "authenticated";

grant delete on table "public"."bulk_offers" to "service_role";

grant insert on table "public"."bulk_offers" to "service_role";

grant references on table "public"."bulk_offers" to "service_role";

grant select on table "public"."bulk_offers" to "service_role";

grant trigger on table "public"."bulk_offers" to "service_role";

grant truncate on table "public"."bulk_offers" to "service_role";

grant update on table "public"."bulk_offers" to "service_role";

grant delete on table "public"."capabilities" to "anon";

grant insert on table "public"."capabilities" to "anon";

grant references on table "public"."capabilities" to "anon";

grant select on table "public"."capabilities" to "anon";

grant trigger on table "public"."capabilities" to "anon";

grant truncate on table "public"."capabilities" to "anon";

grant update on table "public"."capabilities" to "anon";

grant delete on table "public"."capabilities" to "authenticated";

grant insert on table "public"."capabilities" to "authenticated";

grant references on table "public"."capabilities" to "authenticated";

grant select on table "public"."capabilities" to "authenticated";

grant trigger on table "public"."capabilities" to "authenticated";

grant truncate on table "public"."capabilities" to "authenticated";

grant update on table "public"."capabilities" to "authenticated";

grant delete on table "public"."capabilities" to "service_role";

grant insert on table "public"."capabilities" to "service_role";

grant references on table "public"."capabilities" to "service_role";

grant select on table "public"."capabilities" to "service_role";

grant trigger on table "public"."capabilities" to "service_role";

grant truncate on table "public"."capabilities" to "service_role";

grant update on table "public"."capabilities" to "service_role";

grant delete on table "public"."community_nature_spots" to "anon";

grant insert on table "public"."community_nature_spots" to "anon";

grant references on table "public"."community_nature_spots" to "anon";

grant select on table "public"."community_nature_spots" to "anon";

grant trigger on table "public"."community_nature_spots" to "anon";

grant truncate on table "public"."community_nature_spots" to "anon";

grant update on table "public"."community_nature_spots" to "anon";

grant delete on table "public"."community_nature_spots" to "authenticated";

grant insert on table "public"."community_nature_spots" to "authenticated";

grant references on table "public"."community_nature_spots" to "authenticated";

grant select on table "public"."community_nature_spots" to "authenticated";

grant trigger on table "public"."community_nature_spots" to "authenticated";

grant truncate on table "public"."community_nature_spots" to "authenticated";

grant update on table "public"."community_nature_spots" to "authenticated";

grant delete on table "public"."community_nature_spots" to "service_role";

grant insert on table "public"."community_nature_spots" to "service_role";

grant references on table "public"."community_nature_spots" to "service_role";

grant select on table "public"."community_nature_spots" to "service_role";

grant trigger on table "public"."community_nature_spots" to "service_role";

grant truncate on table "public"."community_nature_spots" to "service_role";

grant update on table "public"."community_nature_spots" to "service_role";

grant delete on table "public"."community_programs" to "anon";

grant insert on table "public"."community_programs" to "anon";

grant references on table "public"."community_programs" to "anon";

grant select on table "public"."community_programs" to "anon";

grant trigger on table "public"."community_programs" to "anon";

grant truncate on table "public"."community_programs" to "anon";

grant update on table "public"."community_programs" to "anon";

grant delete on table "public"."community_programs" to "authenticated";

grant insert on table "public"."community_programs" to "authenticated";

grant references on table "public"."community_programs" to "authenticated";

grant select on table "public"."community_programs" to "authenticated";

grant trigger on table "public"."community_programs" to "authenticated";

grant truncate on table "public"."community_programs" to "authenticated";

grant update on table "public"."community_programs" to "authenticated";

grant delete on table "public"."community_programs" to "service_role";

grant insert on table "public"."community_programs" to "service_role";

grant references on table "public"."community_programs" to "service_role";

grant select on table "public"."community_programs" to "service_role";

grant trigger on table "public"."community_programs" to "service_role";

grant truncate on table "public"."community_programs" to "service_role";

grant update on table "public"."community_programs" to "service_role";

grant delete on table "public"."community_specialty_registry" to "anon";

grant insert on table "public"."community_specialty_registry" to "anon";

grant references on table "public"."community_specialty_registry" to "anon";

grant select on table "public"."community_specialty_registry" to "anon";

grant trigger on table "public"."community_specialty_registry" to "anon";

grant truncate on table "public"."community_specialty_registry" to "anon";

grant update on table "public"."community_specialty_registry" to "anon";

grant delete on table "public"."community_specialty_registry" to "authenticated";

grant insert on table "public"."community_specialty_registry" to "authenticated";

grant references on table "public"."community_specialty_registry" to "authenticated";

grant select on table "public"."community_specialty_registry" to "authenticated";

grant trigger on table "public"."community_specialty_registry" to "authenticated";

grant truncate on table "public"."community_specialty_registry" to "authenticated";

grant update on table "public"."community_specialty_registry" to "authenticated";

grant delete on table "public"."community_specialty_registry" to "service_role";

grant insert on table "public"."community_specialty_registry" to "service_role";

grant references on table "public"."community_specialty_registry" to "service_role";

grant select on table "public"."community_specialty_registry" to "service_role";

grant trigger on table "public"."community_specialty_registry" to "service_role";

grant truncate on table "public"."community_specialty_registry" to "service_role";

grant update on table "public"."community_specialty_registry" to "service_role";

grant references on table "public"."compliance_overlays" to "anon";

grant select on table "public"."compliance_overlays" to "anon";

grant trigger on table "public"."compliance_overlays" to "anon";

grant truncate on table "public"."compliance_overlays" to "anon";

grant references on table "public"."compliance_overlays" to "authenticated";

grant select on table "public"."compliance_overlays" to "authenticated";

grant trigger on table "public"."compliance_overlays" to "authenticated";

grant truncate on table "public"."compliance_overlays" to "authenticated";

grant delete on table "public"."compliance_overlays" to "service_role";

grant insert on table "public"."compliance_overlays" to "service_role";

grant references on table "public"."compliance_overlays" to "service_role";

grant select on table "public"."compliance_overlays" to "service_role";

grant trigger on table "public"."compliance_overlays" to "service_role";

grant truncate on table "public"."compliance_overlays" to "service_role";

grant update on table "public"."compliance_overlays" to "service_role";

grant delete on table "public"."construction_safety_incidents" to "anon";

grant insert on table "public"."construction_safety_incidents" to "anon";

grant references on table "public"."construction_safety_incidents" to "anon";

grant select on table "public"."construction_safety_incidents" to "anon";

grant trigger on table "public"."construction_safety_incidents" to "anon";

grant truncate on table "public"."construction_safety_incidents" to "anon";

grant update on table "public"."construction_safety_incidents" to "anon";

grant delete on table "public"."construction_safety_incidents" to "authenticated";

grant insert on table "public"."construction_safety_incidents" to "authenticated";

grant references on table "public"."construction_safety_incidents" to "authenticated";

grant select on table "public"."construction_safety_incidents" to "authenticated";

grant trigger on table "public"."construction_safety_incidents" to "authenticated";

grant truncate on table "public"."construction_safety_incidents" to "authenticated";

grant update on table "public"."construction_safety_incidents" to "authenticated";

grant delete on table "public"."construction_safety_incidents" to "service_role";

grant insert on table "public"."construction_safety_incidents" to "service_role";

grant references on table "public"."construction_safety_incidents" to "service_role";

grant select on table "public"."construction_safety_incidents" to "service_role";

grant trigger on table "public"."construction_safety_incidents" to "service_role";

grant truncate on table "public"."construction_safety_incidents" to "service_role";

grant update on table "public"."construction_safety_incidents" to "service_role";

grant delete on table "public"."conversation_participants" to "anon";

grant insert on table "public"."conversation_participants" to "anon";

grant references on table "public"."conversation_participants" to "anon";

grant select on table "public"."conversation_participants" to "anon";

grant trigger on table "public"."conversation_participants" to "anon";

grant truncate on table "public"."conversation_participants" to "anon";

grant update on table "public"."conversation_participants" to "anon";

grant delete on table "public"."conversation_participants" to "authenticated";

grant insert on table "public"."conversation_participants" to "authenticated";

grant references on table "public"."conversation_participants" to "authenticated";

grant select on table "public"."conversation_participants" to "authenticated";

grant trigger on table "public"."conversation_participants" to "authenticated";

grant truncate on table "public"."conversation_participants" to "authenticated";

grant update on table "public"."conversation_participants" to "authenticated";

grant delete on table "public"."conversation_participants" to "service_role";

grant insert on table "public"."conversation_participants" to "service_role";

grant references on table "public"."conversation_participants" to "service_role";

grant select on table "public"."conversation_participants" to "service_role";

grant trigger on table "public"."conversation_participants" to "service_role";

grant truncate on table "public"."conversation_participants" to "service_role";

grant update on table "public"."conversation_participants" to "service_role";

grant delete on table "public"."conversations" to "anon";

grant insert on table "public"."conversations" to "anon";

grant references on table "public"."conversations" to "anon";

grant select on table "public"."conversations" to "anon";

grant trigger on table "public"."conversations" to "anon";

grant truncate on table "public"."conversations" to "anon";

grant update on table "public"."conversations" to "anon";

grant delete on table "public"."conversations" to "authenticated";

grant insert on table "public"."conversations" to "authenticated";

grant references on table "public"."conversations" to "authenticated";

grant select on table "public"."conversations" to "authenticated";

grant trigger on table "public"."conversations" to "authenticated";

grant truncate on table "public"."conversations" to "authenticated";

grant update on table "public"."conversations" to "authenticated";

grant delete on table "public"."conversations" to "service_role";

grant insert on table "public"."conversations" to "service_role";

grant references on table "public"."conversations" to "service_role";

grant select on table "public"."conversations" to "service_role";

grant trigger on table "public"."conversations" to "service_role";

grant truncate on table "public"."conversations" to "service_role";

grant update on table "public"."conversations" to "service_role";

grant delete on table "public"."donations" to "anon";

grant insert on table "public"."donations" to "anon";

grant references on table "public"."donations" to "anon";

grant select on table "public"."donations" to "anon";

grant trigger on table "public"."donations" to "anon";

grant truncate on table "public"."donations" to "anon";

grant update on table "public"."donations" to "anon";

grant delete on table "public"."donations" to "authenticated";

grant insert on table "public"."donations" to "authenticated";

grant references on table "public"."donations" to "authenticated";

grant select on table "public"."donations" to "authenticated";

grant trigger on table "public"."donations" to "authenticated";

grant truncate on table "public"."donations" to "authenticated";

grant update on table "public"."donations" to "authenticated";

grant delete on table "public"."donations" to "service_role";

grant insert on table "public"."donations" to "service_role";

grant references on table "public"."donations" to "service_role";

grant select on table "public"."donations" to "service_role";

grant trigger on table "public"."donations" to "service_role";

grant truncate on table "public"."donations" to "service_role";

grant update on table "public"."donations" to "service_role";

grant delete on table "public"."education_field_trips" to "anon";

grant insert on table "public"."education_field_trips" to "anon";

grant references on table "public"."education_field_trips" to "anon";

grant select on table "public"."education_field_trips" to "anon";

grant trigger on table "public"."education_field_trips" to "anon";

grant truncate on table "public"."education_field_trips" to "anon";

grant update on table "public"."education_field_trips" to "anon";

grant delete on table "public"."education_field_trips" to "authenticated";

grant insert on table "public"."education_field_trips" to "authenticated";

grant references on table "public"."education_field_trips" to "authenticated";

grant select on table "public"."education_field_trips" to "authenticated";

grant trigger on table "public"."education_field_trips" to "authenticated";

grant truncate on table "public"."education_field_trips" to "authenticated";

grant update on table "public"."education_field_trips" to "authenticated";

grant delete on table "public"."education_field_trips" to "service_role";

grant insert on table "public"."education_field_trips" to "service_role";

grant references on table "public"."education_field_trips" to "service_role";

grant select on table "public"."education_field_trips" to "service_role";

grant trigger on table "public"."education_field_trips" to "service_role";

grant truncate on table "public"."education_field_trips" to "service_role";

grant update on table "public"."education_field_trips" to "service_role";

grant delete on table "public"."event_analytics_daily" to "anon";

grant insert on table "public"."event_analytics_daily" to "anon";

grant references on table "public"."event_analytics_daily" to "anon";

grant select on table "public"."event_analytics_daily" to "anon";

grant trigger on table "public"."event_analytics_daily" to "anon";

grant truncate on table "public"."event_analytics_daily" to "anon";

grant update on table "public"."event_analytics_daily" to "anon";

grant delete on table "public"."event_analytics_daily" to "authenticated";

grant insert on table "public"."event_analytics_daily" to "authenticated";

grant references on table "public"."event_analytics_daily" to "authenticated";

grant select on table "public"."event_analytics_daily" to "authenticated";

grant trigger on table "public"."event_analytics_daily" to "authenticated";

grant truncate on table "public"."event_analytics_daily" to "authenticated";

grant update on table "public"."event_analytics_daily" to "authenticated";

grant delete on table "public"."event_analytics_daily" to "service_role";

grant insert on table "public"."event_analytics_daily" to "service_role";

grant references on table "public"."event_analytics_daily" to "service_role";

grant select on table "public"."event_analytics_daily" to "service_role";

grant trigger on table "public"."event_analytics_daily" to "service_role";

grant truncate on table "public"."event_analytics_daily" to "service_role";

grant update on table "public"."event_analytics_daily" to "service_role";

grant delete on table "public"."event_badges" to "anon";

grant insert on table "public"."event_badges" to "anon";

grant references on table "public"."event_badges" to "anon";

grant select on table "public"."event_badges" to "anon";

grant trigger on table "public"."event_badges" to "anon";

grant truncate on table "public"."event_badges" to "anon";

grant update on table "public"."event_badges" to "anon";

grant delete on table "public"."event_badges" to "authenticated";

grant insert on table "public"."event_badges" to "authenticated";

grant references on table "public"."event_badges" to "authenticated";

grant select on table "public"."event_badges" to "authenticated";

grant trigger on table "public"."event_badges" to "authenticated";

grant truncate on table "public"."event_badges" to "authenticated";

grant update on table "public"."event_badges" to "authenticated";

grant delete on table "public"."event_badges" to "service_role";

grant insert on table "public"."event_badges" to "service_role";

grant references on table "public"."event_badges" to "service_role";

grant select on table "public"."event_badges" to "service_role";

grant trigger on table "public"."event_badges" to "service_role";

grant truncate on table "public"."event_badges" to "service_role";

grant update on table "public"."event_badges" to "service_role";

grant delete on table "public"."event_context_profiles" to "anon";

grant insert on table "public"."event_context_profiles" to "anon";

grant references on table "public"."event_context_profiles" to "anon";

grant select on table "public"."event_context_profiles" to "anon";

grant trigger on table "public"."event_context_profiles" to "anon";

grant truncate on table "public"."event_context_profiles" to "anon";

grant update on table "public"."event_context_profiles" to "anon";

grant delete on table "public"."event_context_profiles" to "authenticated";

grant insert on table "public"."event_context_profiles" to "authenticated";

grant references on table "public"."event_context_profiles" to "authenticated";

grant select on table "public"."event_context_profiles" to "authenticated";

grant trigger on table "public"."event_context_profiles" to "authenticated";

grant truncate on table "public"."event_context_profiles" to "authenticated";

grant update on table "public"."event_context_profiles" to "authenticated";

grant delete on table "public"."event_context_profiles" to "service_role";

grant insert on table "public"."event_context_profiles" to "service_role";

grant references on table "public"."event_context_profiles" to "service_role";

grant select on table "public"."event_context_profiles" to "service_role";

grant trigger on table "public"."event_context_profiles" to "service_role";

grant truncate on table "public"."event_context_profiles" to "service_role";

grant update on table "public"."event_context_profiles" to "service_role";

grant delete on table "public"."event_registrations" to "anon";

grant insert on table "public"."event_registrations" to "anon";

grant references on table "public"."event_registrations" to "anon";

grant select on table "public"."event_registrations" to "anon";

grant trigger on table "public"."event_registrations" to "anon";

grant truncate on table "public"."event_registrations" to "anon";

grant update on table "public"."event_registrations" to "anon";

grant delete on table "public"."event_registrations" to "authenticated";

grant insert on table "public"."event_registrations" to "authenticated";

grant references on table "public"."event_registrations" to "authenticated";

grant select on table "public"."event_registrations" to "authenticated";

grant trigger on table "public"."event_registrations" to "authenticated";

grant truncate on table "public"."event_registrations" to "authenticated";

grant update on table "public"."event_registrations" to "authenticated";

grant delete on table "public"."event_registrations" to "service_role";

grant insert on table "public"."event_registrations" to "service_role";

grant references on table "public"."event_registrations" to "service_role";

grant select on table "public"."event_registrations" to "service_role";

grant trigger on table "public"."event_registrations" to "service_role";

grant truncate on table "public"."event_registrations" to "service_role";

grant update on table "public"."event_registrations" to "service_role";

grant delete on table "public"."event_specialties" to "anon";

grant insert on table "public"."event_specialties" to "anon";

grant references on table "public"."event_specialties" to "anon";

grant select on table "public"."event_specialties" to "anon";

grant trigger on table "public"."event_specialties" to "anon";

grant truncate on table "public"."event_specialties" to "anon";

grant update on table "public"."event_specialties" to "anon";

grant delete on table "public"."event_specialties" to "authenticated";

grant insert on table "public"."event_specialties" to "authenticated";

grant references on table "public"."event_specialties" to "authenticated";

grant select on table "public"."event_specialties" to "authenticated";

grant trigger on table "public"."event_specialties" to "authenticated";

grant truncate on table "public"."event_specialties" to "authenticated";

grant update on table "public"."event_specialties" to "authenticated";

grant delete on table "public"."event_specialties" to "service_role";

grant insert on table "public"."event_specialties" to "service_role";

grant references on table "public"."event_specialties" to "service_role";

grant select on table "public"."event_specialties" to "service_role";

grant trigger on table "public"."event_specialties" to "service_role";

grant truncate on table "public"."event_specialties" to "service_role";

grant update on table "public"."event_specialties" to "service_role";

grant delete on table "public"."event_specialty_links" to "anon";

grant insert on table "public"."event_specialty_links" to "anon";

grant references on table "public"."event_specialty_links" to "anon";

grant select on table "public"."event_specialty_links" to "anon";

grant trigger on table "public"."event_specialty_links" to "anon";

grant truncate on table "public"."event_specialty_links" to "anon";

grant update on table "public"."event_specialty_links" to "anon";

grant delete on table "public"."event_specialty_links" to "authenticated";

grant insert on table "public"."event_specialty_links" to "authenticated";

grant references on table "public"."event_specialty_links" to "authenticated";

grant select on table "public"."event_specialty_links" to "authenticated";

grant trigger on table "public"."event_specialty_links" to "authenticated";

grant truncate on table "public"."event_specialty_links" to "authenticated";

grant update on table "public"."event_specialty_links" to "authenticated";

grant delete on table "public"."event_specialty_links" to "service_role";

grant insert on table "public"."event_specialty_links" to "service_role";

grant references on table "public"."event_specialty_links" to "service_role";

grant select on table "public"."event_specialty_links" to "service_role";

grant trigger on table "public"."event_specialty_links" to "service_role";

grant truncate on table "public"."event_specialty_links" to "service_role";

grant update on table "public"."event_specialty_links" to "service_role";

grant delete on table "public"."events" to "anon";

grant insert on table "public"."events" to "anon";

grant references on table "public"."events" to "anon";

grant select on table "public"."events" to "anon";

grant trigger on table "public"."events" to "anon";

grant truncate on table "public"."events" to "anon";

grant update on table "public"."events" to "anon";

grant delete on table "public"."events" to "authenticated";

grant insert on table "public"."events" to "authenticated";

grant references on table "public"."events" to "authenticated";

grant select on table "public"."events" to "authenticated";

grant trigger on table "public"."events" to "authenticated";

grant truncate on table "public"."events" to "authenticated";

grant update on table "public"."events" to "authenticated";

grant delete on table "public"."events" to "service_role";

grant insert on table "public"."events" to "service_role";

grant references on table "public"."events" to "service_role";

grant select on table "public"."events" to "service_role";

grant trigger on table "public"."events" to "service_role";

grant truncate on table "public"."events" to "service_role";

grant update on table "public"."events" to "service_role";

grant delete on table "public"."experience_context_profiles" to "anon";

grant insert on table "public"."experience_context_profiles" to "anon";

grant references on table "public"."experience_context_profiles" to "anon";

grant select on table "public"."experience_context_profiles" to "anon";

grant trigger on table "public"."experience_context_profiles" to "anon";

grant truncate on table "public"."experience_context_profiles" to "anon";

grant update on table "public"."experience_context_profiles" to "anon";

grant delete on table "public"."experience_context_profiles" to "authenticated";

grant insert on table "public"."experience_context_profiles" to "authenticated";

grant references on table "public"."experience_context_profiles" to "authenticated";

grant select on table "public"."experience_context_profiles" to "authenticated";

grant trigger on table "public"."experience_context_profiles" to "authenticated";

grant truncate on table "public"."experience_context_profiles" to "authenticated";

grant update on table "public"."experience_context_profiles" to "authenticated";

grant delete on table "public"."experience_context_profiles" to "service_role";

grant insert on table "public"."experience_context_profiles" to "service_role";

grant references on table "public"."experience_context_profiles" to "service_role";

grant select on table "public"."experience_context_profiles" to "service_role";

grant trigger on table "public"."experience_context_profiles" to "service_role";

grant truncate on table "public"."experience_context_profiles" to "service_role";

grant update on table "public"."experience_context_profiles" to "service_role";

grant references on table "public"."experience_kids_mode_overlays" to "anon";

grant select on table "public"."experience_kids_mode_overlays" to "anon";

grant trigger on table "public"."experience_kids_mode_overlays" to "anon";

grant truncate on table "public"."experience_kids_mode_overlays" to "anon";

grant references on table "public"."experience_kids_mode_overlays" to "authenticated";

grant select on table "public"."experience_kids_mode_overlays" to "authenticated";

grant trigger on table "public"."experience_kids_mode_overlays" to "authenticated";

grant truncate on table "public"."experience_kids_mode_overlays" to "authenticated";

grant delete on table "public"."experience_kids_mode_overlays" to "service_role";

grant insert on table "public"."experience_kids_mode_overlays" to "service_role";

grant references on table "public"."experience_kids_mode_overlays" to "service_role";

grant select on table "public"."experience_kids_mode_overlays" to "service_role";

grant trigger on table "public"."experience_kids_mode_overlays" to "service_role";

grant truncate on table "public"."experience_kids_mode_overlays" to "service_role";

grant update on table "public"."experience_kids_mode_overlays" to "service_role";

grant delete on table "public"."experience_requests" to "anon";

grant insert on table "public"."experience_requests" to "anon";

grant references on table "public"."experience_requests" to "anon";

grant select on table "public"."experience_requests" to "anon";

grant trigger on table "public"."experience_requests" to "anon";

grant truncate on table "public"."experience_requests" to "anon";

grant update on table "public"."experience_requests" to "anon";

grant delete on table "public"."experience_requests" to "authenticated";

grant insert on table "public"."experience_requests" to "authenticated";

grant references on table "public"."experience_requests" to "authenticated";

grant select on table "public"."experience_requests" to "authenticated";

grant trigger on table "public"."experience_requests" to "authenticated";

grant truncate on table "public"."experience_requests" to "authenticated";

grant update on table "public"."experience_requests" to "authenticated";

grant delete on table "public"."experience_requests" to "service_role";

grant insert on table "public"."experience_requests" to "service_role";

grant references on table "public"."experience_requests" to "service_role";

grant select on table "public"."experience_requests" to "service_role";

grant trigger on table "public"."experience_requests" to "service_role";

grant truncate on table "public"."experience_requests" to "service_role";

grant update on table "public"."experience_requests" to "service_role";

grant references on table "public"."experience_types" to "anon";

grant select on table "public"."experience_types" to "anon";

grant trigger on table "public"."experience_types" to "anon";

grant truncate on table "public"."experience_types" to "anon";

grant references on table "public"."experience_types" to "authenticated";

grant select on table "public"."experience_types" to "authenticated";

grant trigger on table "public"."experience_types" to "authenticated";

grant truncate on table "public"."experience_types" to "authenticated";

grant delete on table "public"."experience_types" to "service_role";

grant insert on table "public"."experience_types" to "service_role";

grant references on table "public"."experience_types" to "service_role";

grant select on table "public"."experience_types" to "service_role";

grant trigger on table "public"."experience_types" to "service_role";

grant truncate on table "public"."experience_types" to "service_role";

grant update on table "public"."experience_types" to "service_role";

grant delete on table "public"."experiences" to "anon";

grant insert on table "public"."experiences" to "anon";

grant references on table "public"."experiences" to "anon";

grant select on table "public"."experiences" to "anon";

grant trigger on table "public"."experiences" to "anon";

grant truncate on table "public"."experiences" to "anon";

grant update on table "public"."experiences" to "anon";

grant delete on table "public"."experiences" to "authenticated";

grant insert on table "public"."experiences" to "authenticated";

grant references on table "public"."experiences" to "authenticated";

grant select on table "public"."experiences" to "authenticated";

grant trigger on table "public"."experiences" to "authenticated";

grant truncate on table "public"."experiences" to "authenticated";

grant update on table "public"."experiences" to "authenticated";

grant delete on table "public"."experiences" to "service_role";

grant insert on table "public"."experiences" to "service_role";

grant references on table "public"."experiences" to "service_role";

grant select on table "public"."experiences" to "service_role";

grant trigger on table "public"."experiences" to "service_role";

grant truncate on table "public"."experiences" to "service_role";

grant update on table "public"."experiences" to "service_role";

grant delete on table "public"."feed_comments" to "anon";

grant insert on table "public"."feed_comments" to "anon";

grant references on table "public"."feed_comments" to "anon";

grant select on table "public"."feed_comments" to "anon";

grant trigger on table "public"."feed_comments" to "anon";

grant truncate on table "public"."feed_comments" to "anon";

grant update on table "public"."feed_comments" to "anon";

grant delete on table "public"."feed_comments" to "authenticated";

grant insert on table "public"."feed_comments" to "authenticated";

grant references on table "public"."feed_comments" to "authenticated";

grant select on table "public"."feed_comments" to "authenticated";

grant trigger on table "public"."feed_comments" to "authenticated";

grant truncate on table "public"."feed_comments" to "authenticated";

grant update on table "public"."feed_comments" to "authenticated";

grant delete on table "public"."feed_comments" to "service_role";

grant insert on table "public"."feed_comments" to "service_role";

grant references on table "public"."feed_comments" to "service_role";

grant select on table "public"."feed_comments" to "service_role";

grant trigger on table "public"."feed_comments" to "service_role";

grant truncate on table "public"."feed_comments" to "service_role";

grant update on table "public"."feed_comments" to "service_role";

grant delete on table "public"."feed_items" to "anon";

grant insert on table "public"."feed_items" to "anon";

grant references on table "public"."feed_items" to "anon";

grant select on table "public"."feed_items" to "anon";

grant trigger on table "public"."feed_items" to "anon";

grant truncate on table "public"."feed_items" to "anon";

grant update on table "public"."feed_items" to "anon";

grant delete on table "public"."feed_items" to "authenticated";

grant insert on table "public"."feed_items" to "authenticated";

grant references on table "public"."feed_items" to "authenticated";

grant select on table "public"."feed_items" to "authenticated";

grant trigger on table "public"."feed_items" to "authenticated";

grant truncate on table "public"."feed_items" to "authenticated";

grant update on table "public"."feed_items" to "authenticated";

grant delete on table "public"."feed_items" to "service_role";

grant insert on table "public"."feed_items" to "service_role";

grant references on table "public"."feed_items" to "service_role";

grant select on table "public"."feed_items" to "service_role";

grant trigger on table "public"."feed_items" to "service_role";

grant truncate on table "public"."feed_items" to "service_role";

grant update on table "public"."feed_items" to "service_role";

grant delete on table "public"."feed_likes" to "anon";

grant insert on table "public"."feed_likes" to "anon";

grant references on table "public"."feed_likes" to "anon";

grant select on table "public"."feed_likes" to "anon";

grant trigger on table "public"."feed_likes" to "anon";

grant truncate on table "public"."feed_likes" to "anon";

grant update on table "public"."feed_likes" to "anon";

grant delete on table "public"."feed_likes" to "authenticated";

grant insert on table "public"."feed_likes" to "authenticated";

grant references on table "public"."feed_likes" to "authenticated";

grant select on table "public"."feed_likes" to "authenticated";

grant trigger on table "public"."feed_likes" to "authenticated";

grant truncate on table "public"."feed_likes" to "authenticated";

grant update on table "public"."feed_likes" to "authenticated";

grant delete on table "public"."feed_likes" to "service_role";

grant insert on table "public"."feed_likes" to "service_role";

grant references on table "public"."feed_likes" to "service_role";

grant select on table "public"."feed_likes" to "service_role";

grant trigger on table "public"."feed_likes" to "service_role";

grant truncate on table "public"."feed_likes" to "service_role";

grant update on table "public"."feed_likes" to "service_role";

grant delete on table "public"."institution_applications" to "anon";

grant insert on table "public"."institution_applications" to "anon";

grant references on table "public"."institution_applications" to "anon";

grant select on table "public"."institution_applications" to "anon";

grant trigger on table "public"."institution_applications" to "anon";

grant truncate on table "public"."institution_applications" to "anon";

grant update on table "public"."institution_applications" to "anon";

grant delete on table "public"."institution_applications" to "authenticated";

grant insert on table "public"."institution_applications" to "authenticated";

grant references on table "public"."institution_applications" to "authenticated";

grant select on table "public"."institution_applications" to "authenticated";

grant trigger on table "public"."institution_applications" to "authenticated";

grant truncate on table "public"."institution_applications" to "authenticated";

grant update on table "public"."institution_applications" to "authenticated";

grant delete on table "public"."institution_applications" to "service_role";

grant insert on table "public"."institution_applications" to "service_role";

grant references on table "public"."institution_applications" to "service_role";

grant select on table "public"."institution_applications" to "service_role";

grant trigger on table "public"."institution_applications" to "service_role";

grant truncate on table "public"."institution_applications" to "service_role";

grant update on table "public"."institution_applications" to "service_role";

grant delete on table "public"."institution_specialties" to "anon";

grant insert on table "public"."institution_specialties" to "anon";

grant references on table "public"."institution_specialties" to "anon";

grant select on table "public"."institution_specialties" to "anon";

grant trigger on table "public"."institution_specialties" to "anon";

grant truncate on table "public"."institution_specialties" to "anon";

grant update on table "public"."institution_specialties" to "anon";

grant delete on table "public"."institution_specialties" to "authenticated";

grant insert on table "public"."institution_specialties" to "authenticated";

grant references on table "public"."institution_specialties" to "authenticated";

grant select on table "public"."institution_specialties" to "authenticated";

grant trigger on table "public"."institution_specialties" to "authenticated";

grant truncate on table "public"."institution_specialties" to "authenticated";

grant update on table "public"."institution_specialties" to "authenticated";

grant delete on table "public"."institution_specialties" to "service_role";

grant insert on table "public"."institution_specialties" to "service_role";

grant references on table "public"."institution_specialties" to "service_role";

grant select on table "public"."institution_specialties" to "service_role";

grant trigger on table "public"."institution_specialties" to "service_role";

grant truncate on table "public"."institution_specialties" to "service_role";

grant update on table "public"."institution_specialties" to "service_role";

grant references on table "public"."kids_mode_overlays" to "anon";

grant select on table "public"."kids_mode_overlays" to "anon";

grant trigger on table "public"."kids_mode_overlays" to "anon";

grant truncate on table "public"."kids_mode_overlays" to "anon";

grant references on table "public"."kids_mode_overlays" to "authenticated";

grant select on table "public"."kids_mode_overlays" to "authenticated";

grant trigger on table "public"."kids_mode_overlays" to "authenticated";

grant truncate on table "public"."kids_mode_overlays" to "authenticated";

grant delete on table "public"."kids_mode_overlays" to "service_role";

grant insert on table "public"."kids_mode_overlays" to "service_role";

grant references on table "public"."kids_mode_overlays" to "service_role";

grant select on table "public"."kids_mode_overlays" to "service_role";

grant trigger on table "public"."kids_mode_overlays" to "service_role";

grant truncate on table "public"."kids_mode_overlays" to "service_role";

grant update on table "public"."kids_mode_overlays" to "service_role";

grant delete on table "public"."kv_store_5bb94edf" to "anon";

grant insert on table "public"."kv_store_5bb94edf" to "anon";

grant references on table "public"."kv_store_5bb94edf" to "anon";

grant select on table "public"."kv_store_5bb94edf" to "anon";

grant trigger on table "public"."kv_store_5bb94edf" to "anon";

grant truncate on table "public"."kv_store_5bb94edf" to "anon";

grant update on table "public"."kv_store_5bb94edf" to "anon";

grant delete on table "public"."kv_store_5bb94edf" to "authenticated";

grant insert on table "public"."kv_store_5bb94edf" to "authenticated";

grant references on table "public"."kv_store_5bb94edf" to "authenticated";

grant select on table "public"."kv_store_5bb94edf" to "authenticated";

grant trigger on table "public"."kv_store_5bb94edf" to "authenticated";

grant truncate on table "public"."kv_store_5bb94edf" to "authenticated";

grant update on table "public"."kv_store_5bb94edf" to "authenticated";

grant delete on table "public"."kv_store_5bb94edf" to "service_role";

grant insert on table "public"."kv_store_5bb94edf" to "service_role";

grant references on table "public"."kv_store_5bb94edf" to "service_role";

grant select on table "public"."kv_store_5bb94edf" to "service_role";

grant trigger on table "public"."kv_store_5bb94edf" to "service_role";

grant truncate on table "public"."kv_store_5bb94edf" to "service_role";

grant update on table "public"."kv_store_5bb94edf" to "service_role";

grant delete on table "public"."kv_store_80d2ab6d" to "anon";

grant insert on table "public"."kv_store_80d2ab6d" to "anon";

grant references on table "public"."kv_store_80d2ab6d" to "anon";

grant select on table "public"."kv_store_80d2ab6d" to "anon";

grant trigger on table "public"."kv_store_80d2ab6d" to "anon";

grant truncate on table "public"."kv_store_80d2ab6d" to "anon";

grant update on table "public"."kv_store_80d2ab6d" to "anon";

grant delete on table "public"."kv_store_80d2ab6d" to "authenticated";

grant insert on table "public"."kv_store_80d2ab6d" to "authenticated";

grant references on table "public"."kv_store_80d2ab6d" to "authenticated";

grant select on table "public"."kv_store_80d2ab6d" to "authenticated";

grant trigger on table "public"."kv_store_80d2ab6d" to "authenticated";

grant truncate on table "public"."kv_store_80d2ab6d" to "authenticated";

grant update on table "public"."kv_store_80d2ab6d" to "authenticated";

grant delete on table "public"."kv_store_80d2ab6d" to "service_role";

grant insert on table "public"."kv_store_80d2ab6d" to "service_role";

grant references on table "public"."kv_store_80d2ab6d" to "service_role";

grant select on table "public"."kv_store_80d2ab6d" to "service_role";

grant trigger on table "public"."kv_store_80d2ab6d" to "service_role";

grant truncate on table "public"."kv_store_80d2ab6d" to "service_role";

grant update on table "public"."kv_store_80d2ab6d" to "service_role";

grant delete on table "public"."kv_store_9ca868c2" to "anon";

grant insert on table "public"."kv_store_9ca868c2" to "anon";

grant references on table "public"."kv_store_9ca868c2" to "anon";

grant select on table "public"."kv_store_9ca868c2" to "anon";

grant trigger on table "public"."kv_store_9ca868c2" to "anon";

grant truncate on table "public"."kv_store_9ca868c2" to "anon";

grant update on table "public"."kv_store_9ca868c2" to "anon";

grant delete on table "public"."kv_store_9ca868c2" to "authenticated";

grant insert on table "public"."kv_store_9ca868c2" to "authenticated";

grant references on table "public"."kv_store_9ca868c2" to "authenticated";

grant select on table "public"."kv_store_9ca868c2" to "authenticated";

grant trigger on table "public"."kv_store_9ca868c2" to "authenticated";

grant truncate on table "public"."kv_store_9ca868c2" to "authenticated";

grant update on table "public"."kv_store_9ca868c2" to "authenticated";

grant delete on table "public"."kv_store_9ca868c2" to "service_role";

grant insert on table "public"."kv_store_9ca868c2" to "service_role";

grant references on table "public"."kv_store_9ca868c2" to "service_role";

grant select on table "public"."kv_store_9ca868c2" to "service_role";

grant trigger on table "public"."kv_store_9ca868c2" to "service_role";

grant truncate on table "public"."kv_store_9ca868c2" to "service_role";

grant update on table "public"."kv_store_9ca868c2" to "service_role";

grant delete on table "public"."kv_store_d3ca0863" to "anon";

grant insert on table "public"."kv_store_d3ca0863" to "anon";

grant references on table "public"."kv_store_d3ca0863" to "anon";

grant select on table "public"."kv_store_d3ca0863" to "anon";

grant trigger on table "public"."kv_store_d3ca0863" to "anon";

grant truncate on table "public"."kv_store_d3ca0863" to "anon";

grant update on table "public"."kv_store_d3ca0863" to "anon";

grant delete on table "public"."kv_store_d3ca0863" to "authenticated";

grant insert on table "public"."kv_store_d3ca0863" to "authenticated";

grant references on table "public"."kv_store_d3ca0863" to "authenticated";

grant select on table "public"."kv_store_d3ca0863" to "authenticated";

grant trigger on table "public"."kv_store_d3ca0863" to "authenticated";

grant truncate on table "public"."kv_store_d3ca0863" to "authenticated";

grant update on table "public"."kv_store_d3ca0863" to "authenticated";

grant delete on table "public"."kv_store_d3ca0863" to "service_role";

grant insert on table "public"."kv_store_d3ca0863" to "service_role";

grant references on table "public"."kv_store_d3ca0863" to "service_role";

grant select on table "public"."kv_store_d3ca0863" to "service_role";

grant trigger on table "public"."kv_store_d3ca0863" to "service_role";

grant truncate on table "public"."kv_store_d3ca0863" to "service_role";

grant update on table "public"."kv_store_d3ca0863" to "service_role";

grant delete on table "public"."kv_store_f009e61d" to "anon";

grant insert on table "public"."kv_store_f009e61d" to "anon";

grant references on table "public"."kv_store_f009e61d" to "anon";

grant select on table "public"."kv_store_f009e61d" to "anon";

grant trigger on table "public"."kv_store_f009e61d" to "anon";

grant truncate on table "public"."kv_store_f009e61d" to "anon";

grant update on table "public"."kv_store_f009e61d" to "anon";

grant delete on table "public"."kv_store_f009e61d" to "authenticated";

grant insert on table "public"."kv_store_f009e61d" to "authenticated";

grant references on table "public"."kv_store_f009e61d" to "authenticated";

grant select on table "public"."kv_store_f009e61d" to "authenticated";

grant trigger on table "public"."kv_store_f009e61d" to "authenticated";

grant truncate on table "public"."kv_store_f009e61d" to "authenticated";

grant update on table "public"."kv_store_f009e61d" to "authenticated";

grant delete on table "public"."kv_store_f009e61d" to "service_role";

grant insert on table "public"."kv_store_f009e61d" to "service_role";

grant references on table "public"."kv_store_f009e61d" to "service_role";

grant select on table "public"."kv_store_f009e61d" to "service_role";

grant trigger on table "public"."kv_store_f009e61d" to "service_role";

grant truncate on table "public"."kv_store_f009e61d" to "service_role";

grant update on table "public"."kv_store_f009e61d" to "service_role";

grant delete on table "public"."kv_store_fabed9c2" to "anon";

grant insert on table "public"."kv_store_fabed9c2" to "anon";

grant references on table "public"."kv_store_fabed9c2" to "anon";

grant select on table "public"."kv_store_fabed9c2" to "anon";

grant trigger on table "public"."kv_store_fabed9c2" to "anon";

grant truncate on table "public"."kv_store_fabed9c2" to "anon";

grant update on table "public"."kv_store_fabed9c2" to "anon";

grant delete on table "public"."kv_store_fabed9c2" to "authenticated";

grant insert on table "public"."kv_store_fabed9c2" to "authenticated";

grant references on table "public"."kv_store_fabed9c2" to "authenticated";

grant select on table "public"."kv_store_fabed9c2" to "authenticated";

grant trigger on table "public"."kv_store_fabed9c2" to "authenticated";

grant truncate on table "public"."kv_store_fabed9c2" to "authenticated";

grant update on table "public"."kv_store_fabed9c2" to "authenticated";

grant delete on table "public"."kv_store_fabed9c2" to "service_role";

grant insert on table "public"."kv_store_fabed9c2" to "service_role";

grant references on table "public"."kv_store_fabed9c2" to "service_role";

grant select on table "public"."kv_store_fabed9c2" to "service_role";

grant trigger on table "public"."kv_store_fabed9c2" to "service_role";

grant truncate on table "public"."kv_store_fabed9c2" to "service_role";

grant update on table "public"."kv_store_fabed9c2" to "service_role";

grant delete on table "public"."landmark_badges" to "anon";

grant insert on table "public"."landmark_badges" to "anon";

grant references on table "public"."landmark_badges" to "anon";

grant select on table "public"."landmark_badges" to "anon";

grant trigger on table "public"."landmark_badges" to "anon";

grant truncate on table "public"."landmark_badges" to "anon";

grant update on table "public"."landmark_badges" to "anon";

grant delete on table "public"."landmark_badges" to "authenticated";

grant insert on table "public"."landmark_badges" to "authenticated";

grant references on table "public"."landmark_badges" to "authenticated";

grant select on table "public"."landmark_badges" to "authenticated";

grant trigger on table "public"."landmark_badges" to "authenticated";

grant truncate on table "public"."landmark_badges" to "authenticated";

grant update on table "public"."landmark_badges" to "authenticated";

grant delete on table "public"."landmark_badges" to "service_role";

grant insert on table "public"."landmark_badges" to "service_role";

grant references on table "public"."landmark_badges" to "service_role";

grant select on table "public"."landmark_badges" to "service_role";

grant trigger on table "public"."landmark_badges" to "service_role";

grant truncate on table "public"."landmark_badges" to "service_role";

grant update on table "public"."landmark_badges" to "service_role";

grant delete on table "public"."landmark_specialties" to "anon";

grant insert on table "public"."landmark_specialties" to "anon";

grant references on table "public"."landmark_specialties" to "anon";

grant select on table "public"."landmark_specialties" to "anon";

grant trigger on table "public"."landmark_specialties" to "anon";

grant truncate on table "public"."landmark_specialties" to "anon";

grant update on table "public"."landmark_specialties" to "anon";

grant delete on table "public"."landmark_specialties" to "authenticated";

grant insert on table "public"."landmark_specialties" to "authenticated";

grant references on table "public"."landmark_specialties" to "authenticated";

grant select on table "public"."landmark_specialties" to "authenticated";

grant trigger on table "public"."landmark_specialties" to "authenticated";

grant truncate on table "public"."landmark_specialties" to "authenticated";

grant update on table "public"."landmark_specialties" to "authenticated";

grant delete on table "public"."landmark_specialties" to "service_role";

grant insert on table "public"."landmark_specialties" to "service_role";

grant references on table "public"."landmark_specialties" to "service_role";

grant select on table "public"."landmark_specialties" to "service_role";

grant trigger on table "public"."landmark_specialties" to "service_role";

grant truncate on table "public"."landmark_specialties" to "service_role";

grant update on table "public"."landmark_specialties" to "service_role";

grant delete on table "public"."landmark_specialty_links" to "anon";

grant insert on table "public"."landmark_specialty_links" to "anon";

grant references on table "public"."landmark_specialty_links" to "anon";

grant select on table "public"."landmark_specialty_links" to "anon";

grant trigger on table "public"."landmark_specialty_links" to "anon";

grant truncate on table "public"."landmark_specialty_links" to "anon";

grant update on table "public"."landmark_specialty_links" to "anon";

grant delete on table "public"."landmark_specialty_links" to "authenticated";

grant insert on table "public"."landmark_specialty_links" to "authenticated";

grant references on table "public"."landmark_specialty_links" to "authenticated";

grant select on table "public"."landmark_specialty_links" to "authenticated";

grant trigger on table "public"."landmark_specialty_links" to "authenticated";

grant truncate on table "public"."landmark_specialty_links" to "authenticated";

grant update on table "public"."landmark_specialty_links" to "authenticated";

grant delete on table "public"."landmark_specialty_links" to "service_role";

grant insert on table "public"."landmark_specialty_links" to "service_role";

grant references on table "public"."landmark_specialty_links" to "service_role";

grant select on table "public"."landmark_specialty_links" to "service_role";

grant trigger on table "public"."landmark_specialty_links" to "service_role";

grant truncate on table "public"."landmark_specialty_links" to "service_role";

grant update on table "public"."landmark_specialty_links" to "service_role";

grant references on table "public"."landmark_types" to "anon";

grant select on table "public"."landmark_types" to "anon";

grant trigger on table "public"."landmark_types" to "anon";

grant truncate on table "public"."landmark_types" to "anon";

grant references on table "public"."landmark_types" to "authenticated";

grant select on table "public"."landmark_types" to "authenticated";

grant trigger on table "public"."landmark_types" to "authenticated";

grant truncate on table "public"."landmark_types" to "authenticated";

grant delete on table "public"."landmark_types" to "service_role";

grant insert on table "public"."landmark_types" to "service_role";

grant references on table "public"."landmark_types" to "service_role";

grant select on table "public"."landmark_types" to "service_role";

grant trigger on table "public"."landmark_types" to "service_role";

grant truncate on table "public"."landmark_types" to "service_role";

grant update on table "public"."landmark_types" to "service_role";

grant delete on table "public"."landmarks" to "anon";

grant insert on table "public"."landmarks" to "anon";

grant references on table "public"."landmarks" to "anon";

grant select on table "public"."landmarks" to "anon";

grant trigger on table "public"."landmarks" to "anon";

grant truncate on table "public"."landmarks" to "anon";

grant update on table "public"."landmarks" to "anon";

grant delete on table "public"."landmarks" to "authenticated";

grant insert on table "public"."landmarks" to "authenticated";

grant references on table "public"."landmarks" to "authenticated";

grant select on table "public"."landmarks" to "authenticated";

grant trigger on table "public"."landmarks" to "authenticated";

grant truncate on table "public"."landmarks" to "authenticated";

grant update on table "public"."landmarks" to "authenticated";

grant delete on table "public"."landmarks" to "service_role";

grant insert on table "public"."landmarks" to "service_role";

grant references on table "public"."landmarks" to "service_role";

grant select on table "public"."landmarks" to "service_role";

grant trigger on table "public"."landmarks" to "service_role";

grant truncate on table "public"."landmarks" to "service_role";

grant update on table "public"."landmarks" to "service_role";

grant delete on table "public"."location_checkins" to "anon";

grant insert on table "public"."location_checkins" to "anon";

grant references on table "public"."location_checkins" to "anon";

grant select on table "public"."location_checkins" to "anon";

grant trigger on table "public"."location_checkins" to "anon";

grant truncate on table "public"."location_checkins" to "anon";

grant update on table "public"."location_checkins" to "anon";

grant delete on table "public"."location_checkins" to "authenticated";

grant insert on table "public"."location_checkins" to "authenticated";

grant references on table "public"."location_checkins" to "authenticated";

grant select on table "public"."location_checkins" to "authenticated";

grant trigger on table "public"."location_checkins" to "authenticated";

grant truncate on table "public"."location_checkins" to "authenticated";

grant update on table "public"."location_checkins" to "authenticated";

grant delete on table "public"."location_checkins" to "service_role";

grant insert on table "public"."location_checkins" to "service_role";

grant references on table "public"."location_checkins" to "service_role";

grant select on table "public"."location_checkins" to "service_role";

grant trigger on table "public"."location_checkins" to "service_role";

grant truncate on table "public"."location_checkins" to "service_role";

grant update on table "public"."location_checkins" to "service_role";

grant delete on table "public"."market_session_locks" to "anon";

grant insert on table "public"."market_session_locks" to "anon";

grant references on table "public"."market_session_locks" to "anon";

grant select on table "public"."market_session_locks" to "anon";

grant trigger on table "public"."market_session_locks" to "anon";

grant truncate on table "public"."market_session_locks" to "anon";

grant update on table "public"."market_session_locks" to "anon";

grant delete on table "public"."market_session_locks" to "authenticated";

grant insert on table "public"."market_session_locks" to "authenticated";

grant references on table "public"."market_session_locks" to "authenticated";

grant select on table "public"."market_session_locks" to "authenticated";

grant trigger on table "public"."market_session_locks" to "authenticated";

grant truncate on table "public"."market_session_locks" to "authenticated";

grant update on table "public"."market_session_locks" to "authenticated";

grant delete on table "public"."market_session_locks" to "service_role";

grant insert on table "public"."market_session_locks" to "service_role";

grant references on table "public"."market_session_locks" to "service_role";

grant select on table "public"."market_session_locks" to "service_role";

grant trigger on table "public"."market_session_locks" to "service_role";

grant truncate on table "public"."market_session_locks" to "service_role";

grant update on table "public"."market_session_locks" to "service_role";

grant delete on table "public"."messages" to "anon";

grant insert on table "public"."messages" to "anon";

grant references on table "public"."messages" to "anon";

grant select on table "public"."messages" to "anon";

grant trigger on table "public"."messages" to "anon";

grant truncate on table "public"."messages" to "anon";

grant update on table "public"."messages" to "anon";

grant delete on table "public"."messages" to "authenticated";

grant insert on table "public"."messages" to "authenticated";

grant references on table "public"."messages" to "authenticated";

grant select on table "public"."messages" to "authenticated";

grant trigger on table "public"."messages" to "authenticated";

grant truncate on table "public"."messages" to "authenticated";

grant update on table "public"."messages" to "authenticated";

grant delete on table "public"."messages" to "service_role";

grant insert on table "public"."messages" to "service_role";

grant references on table "public"."messages" to "service_role";

grant select on table "public"."messages" to "service_role";

grant trigger on table "public"."messages" to "service_role";

grant truncate on table "public"."messages" to "service_role";

grant update on table "public"."messages" to "service_role";

grant delete on table "public"."moderation_queue" to "anon";

grant insert on table "public"."moderation_queue" to "anon";

grant references on table "public"."moderation_queue" to "anon";

grant select on table "public"."moderation_queue" to "anon";

grant trigger on table "public"."moderation_queue" to "anon";

grant truncate on table "public"."moderation_queue" to "anon";

grant update on table "public"."moderation_queue" to "anon";

grant delete on table "public"."moderation_queue" to "authenticated";

grant insert on table "public"."moderation_queue" to "authenticated";

grant references on table "public"."moderation_queue" to "authenticated";

grant select on table "public"."moderation_queue" to "authenticated";

grant trigger on table "public"."moderation_queue" to "authenticated";

grant truncate on table "public"."moderation_queue" to "authenticated";

grant update on table "public"."moderation_queue" to "authenticated";

grant delete on table "public"."moderation_queue" to "service_role";

grant insert on table "public"."moderation_queue" to "service_role";

grant references on table "public"."moderation_queue" to "service_role";

grant select on table "public"."moderation_queue" to "service_role";

grant trigger on table "public"."moderation_queue" to "service_role";

grant truncate on table "public"."moderation_queue" to "service_role";

grant update on table "public"."moderation_queue" to "service_role";

grant delete on table "public"."notifications" to "anon";

grant insert on table "public"."notifications" to "anon";

grant references on table "public"."notifications" to "anon";

grant select on table "public"."notifications" to "anon";

grant trigger on table "public"."notifications" to "anon";

grant truncate on table "public"."notifications" to "anon";

grant update on table "public"."notifications" to "anon";

grant delete on table "public"."notifications" to "authenticated";

grant insert on table "public"."notifications" to "authenticated";

grant references on table "public"."notifications" to "authenticated";

grant select on table "public"."notifications" to "authenticated";

grant trigger on table "public"."notifications" to "authenticated";

grant truncate on table "public"."notifications" to "authenticated";

grant update on table "public"."notifications" to "authenticated";

grant delete on table "public"."notifications" to "service_role";

grant insert on table "public"."notifications" to "service_role";

grant references on table "public"."notifications" to "service_role";

grant select on table "public"."notifications" to "service_role";

grant trigger on table "public"."notifications" to "service_role";

grant truncate on table "public"."notifications" to "service_role";

grant update on table "public"."notifications" to "service_role";

grant delete on table "public"."password_history" to "service_role";

grant insert on table "public"."password_history" to "service_role";

grant references on table "public"."password_history" to "service_role";

grant select on table "public"."password_history" to "service_role";

grant trigger on table "public"."password_history" to "service_role";

grant truncate on table "public"."password_history" to "service_role";

grant update on table "public"."password_history" to "service_role";

grant delete on table "public"."provider_badges" to "anon";

grant insert on table "public"."provider_badges" to "anon";

grant references on table "public"."provider_badges" to "anon";

grant select on table "public"."provider_badges" to "anon";

grant trigger on table "public"."provider_badges" to "anon";

grant truncate on table "public"."provider_badges" to "anon";

grant update on table "public"."provider_badges" to "anon";

grant delete on table "public"."provider_badges" to "authenticated";

grant insert on table "public"."provider_badges" to "authenticated";

grant references on table "public"."provider_badges" to "authenticated";

grant select on table "public"."provider_badges" to "authenticated";

grant trigger on table "public"."provider_badges" to "authenticated";

grant truncate on table "public"."provider_badges" to "authenticated";

grant update on table "public"."provider_badges" to "authenticated";

grant delete on table "public"."provider_badges" to "service_role";

grant insert on table "public"."provider_badges" to "service_role";

grant references on table "public"."provider_badges" to "service_role";

grant select on table "public"."provider_badges" to "service_role";

grant trigger on table "public"."provider_badges" to "service_role";

grant truncate on table "public"."provider_badges" to "service_role";

grant update on table "public"."provider_badges" to "service_role";

grant references on table "public"."provider_compliance_overlays" to "anon";

grant select on table "public"."provider_compliance_overlays" to "anon";

grant trigger on table "public"."provider_compliance_overlays" to "anon";

grant truncate on table "public"."provider_compliance_overlays" to "anon";

grant references on table "public"."provider_compliance_overlays" to "authenticated";

grant select on table "public"."provider_compliance_overlays" to "authenticated";

grant trigger on table "public"."provider_compliance_overlays" to "authenticated";

grant truncate on table "public"."provider_compliance_overlays" to "authenticated";

grant delete on table "public"."provider_compliance_overlays" to "service_role";

grant insert on table "public"."provider_compliance_overlays" to "service_role";

grant references on table "public"."provider_compliance_overlays" to "service_role";

grant select on table "public"."provider_compliance_overlays" to "service_role";

grant trigger on table "public"."provider_compliance_overlays" to "service_role";

grant truncate on table "public"."provider_compliance_overlays" to "service_role";

grant update on table "public"."provider_compliance_overlays" to "service_role";

grant delete on table "public"."provider_context_profiles" to "anon";

grant insert on table "public"."provider_context_profiles" to "anon";

grant references on table "public"."provider_context_profiles" to "anon";

grant select on table "public"."provider_context_profiles" to "anon";

grant trigger on table "public"."provider_context_profiles" to "anon";

grant truncate on table "public"."provider_context_profiles" to "anon";

grant update on table "public"."provider_context_profiles" to "anon";

grant delete on table "public"."provider_context_profiles" to "authenticated";

grant insert on table "public"."provider_context_profiles" to "authenticated";

grant references on table "public"."provider_context_profiles" to "authenticated";

grant select on table "public"."provider_context_profiles" to "authenticated";

grant trigger on table "public"."provider_context_profiles" to "authenticated";

grant truncate on table "public"."provider_context_profiles" to "authenticated";

grant update on table "public"."provider_context_profiles" to "authenticated";

grant delete on table "public"."provider_context_profiles" to "service_role";

grant insert on table "public"."provider_context_profiles" to "service_role";

grant references on table "public"."provider_context_profiles" to "service_role";

grant select on table "public"."provider_context_profiles" to "service_role";

grant trigger on table "public"."provider_context_profiles" to "service_role";

grant truncate on table "public"."provider_context_profiles" to "service_role";

grant update on table "public"."provider_context_profiles" to "service_role";

grant delete on table "public"."provider_employees" to "anon";

grant insert on table "public"."provider_employees" to "anon";

grant references on table "public"."provider_employees" to "anon";

grant select on table "public"."provider_employees" to "anon";

grant trigger on table "public"."provider_employees" to "anon";

grant truncate on table "public"."provider_employees" to "anon";

grant update on table "public"."provider_employees" to "anon";

grant delete on table "public"."provider_employees" to "authenticated";

grant insert on table "public"."provider_employees" to "authenticated";

grant references on table "public"."provider_employees" to "authenticated";

grant select on table "public"."provider_employees" to "authenticated";

grant trigger on table "public"."provider_employees" to "authenticated";

grant truncate on table "public"."provider_employees" to "authenticated";

grant update on table "public"."provider_employees" to "authenticated";

grant delete on table "public"."provider_employees" to "service_role";

grant insert on table "public"."provider_employees" to "service_role";

grant references on table "public"."provider_employees" to "service_role";

grant select on table "public"."provider_employees" to "service_role";

grant trigger on table "public"."provider_employees" to "service_role";

grant truncate on table "public"."provider_employees" to "service_role";

grant update on table "public"."provider_employees" to "service_role";

grant delete on table "public"."provider_impact_snapshots" to "anon";

grant insert on table "public"."provider_impact_snapshots" to "anon";

grant references on table "public"."provider_impact_snapshots" to "anon";

grant select on table "public"."provider_impact_snapshots" to "anon";

grant trigger on table "public"."provider_impact_snapshots" to "anon";

grant truncate on table "public"."provider_impact_snapshots" to "anon";

grant update on table "public"."provider_impact_snapshots" to "anon";

grant delete on table "public"."provider_impact_snapshots" to "authenticated";

grant insert on table "public"."provider_impact_snapshots" to "authenticated";

grant references on table "public"."provider_impact_snapshots" to "authenticated";

grant select on table "public"."provider_impact_snapshots" to "authenticated";

grant trigger on table "public"."provider_impact_snapshots" to "authenticated";

grant truncate on table "public"."provider_impact_snapshots" to "authenticated";

grant update on table "public"."provider_impact_snapshots" to "authenticated";

grant delete on table "public"."provider_impact_snapshots" to "service_role";

grant insert on table "public"."provider_impact_snapshots" to "service_role";

grant references on table "public"."provider_impact_snapshots" to "service_role";

grant select on table "public"."provider_impact_snapshots" to "service_role";

grant trigger on table "public"."provider_impact_snapshots" to "service_role";

grant truncate on table "public"."provider_impact_snapshots" to "service_role";

grant update on table "public"."provider_impact_snapshots" to "service_role";

grant delete on table "public"."provider_institution_specialties" to "anon";

grant insert on table "public"."provider_institution_specialties" to "anon";

grant references on table "public"."provider_institution_specialties" to "anon";

grant select on table "public"."provider_institution_specialties" to "anon";

grant trigger on table "public"."provider_institution_specialties" to "anon";

grant truncate on table "public"."provider_institution_specialties" to "anon";

grant update on table "public"."provider_institution_specialties" to "anon";

grant delete on table "public"."provider_institution_specialties" to "authenticated";

grant insert on table "public"."provider_institution_specialties" to "authenticated";

grant references on table "public"."provider_institution_specialties" to "authenticated";

grant select on table "public"."provider_institution_specialties" to "authenticated";

grant trigger on table "public"."provider_institution_specialties" to "authenticated";

grant truncate on table "public"."provider_institution_specialties" to "authenticated";

grant update on table "public"."provider_institution_specialties" to "authenticated";

grant delete on table "public"."provider_institution_specialties" to "service_role";

grant insert on table "public"."provider_institution_specialties" to "service_role";

grant references on table "public"."provider_institution_specialties" to "service_role";

grant select on table "public"."provider_institution_specialties" to "service_role";

grant trigger on table "public"."provider_institution_specialties" to "service_role";

grant truncate on table "public"."provider_institution_specialties" to "service_role";

grant update on table "public"."provider_institution_specialties" to "service_role";

grant references on table "public"."provider_kids_mode_overlays" to "anon";

grant select on table "public"."provider_kids_mode_overlays" to "anon";

grant trigger on table "public"."provider_kids_mode_overlays" to "anon";

grant truncate on table "public"."provider_kids_mode_overlays" to "anon";

grant references on table "public"."provider_kids_mode_overlays" to "authenticated";

grant select on table "public"."provider_kids_mode_overlays" to "authenticated";

grant trigger on table "public"."provider_kids_mode_overlays" to "authenticated";

grant truncate on table "public"."provider_kids_mode_overlays" to "authenticated";

grant delete on table "public"."provider_kids_mode_overlays" to "service_role";

grant insert on table "public"."provider_kids_mode_overlays" to "service_role";

grant references on table "public"."provider_kids_mode_overlays" to "service_role";

grant select on table "public"."provider_kids_mode_overlays" to "service_role";

grant trigger on table "public"."provider_kids_mode_overlays" to "service_role";

grant truncate on table "public"."provider_kids_mode_overlays" to "service_role";

grant update on table "public"."provider_kids_mode_overlays" to "service_role";

grant delete on table "public"."provider_media" to "anon";

grant insert on table "public"."provider_media" to "anon";

grant references on table "public"."provider_media" to "anon";

grant select on table "public"."provider_media" to "anon";

grant trigger on table "public"."provider_media" to "anon";

grant truncate on table "public"."provider_media" to "anon";

grant update on table "public"."provider_media" to "anon";

grant delete on table "public"."provider_media" to "authenticated";

grant insert on table "public"."provider_media" to "authenticated";

grant references on table "public"."provider_media" to "authenticated";

grant select on table "public"."provider_media" to "authenticated";

grant trigger on table "public"."provider_media" to "authenticated";

grant truncate on table "public"."provider_media" to "authenticated";

grant update on table "public"."provider_media" to "authenticated";

grant delete on table "public"."provider_media" to "service_role";

grant insert on table "public"."provider_media" to "service_role";

grant references on table "public"."provider_media" to "service_role";

grant select on table "public"."provider_media" to "service_role";

grant trigger on table "public"."provider_media" to "service_role";

grant truncate on table "public"."provider_media" to "service_role";

grant update on table "public"."provider_media" to "service_role";

grant delete on table "public"."provider_memberships" to "anon";

grant insert on table "public"."provider_memberships" to "anon";

grant references on table "public"."provider_memberships" to "anon";

grant select on table "public"."provider_memberships" to "anon";

grant trigger on table "public"."provider_memberships" to "anon";

grant truncate on table "public"."provider_memberships" to "anon";

grant update on table "public"."provider_memberships" to "anon";

grant delete on table "public"."provider_memberships" to "authenticated";

grant insert on table "public"."provider_memberships" to "authenticated";

grant references on table "public"."provider_memberships" to "authenticated";

grant select on table "public"."provider_memberships" to "authenticated";

grant trigger on table "public"."provider_memberships" to "authenticated";

grant truncate on table "public"."provider_memberships" to "authenticated";

grant update on table "public"."provider_memberships" to "authenticated";

grant delete on table "public"."provider_memberships" to "service_role";

grant insert on table "public"."provider_memberships" to "service_role";

grant references on table "public"."provider_memberships" to "service_role";

grant select on table "public"."provider_memberships" to "service_role";

grant trigger on table "public"."provider_memberships" to "service_role";

grant truncate on table "public"."provider_memberships" to "service_role";

grant update on table "public"."provider_memberships" to "service_role";

grant delete on table "public"."provider_specialties" to "anon";

grant insert on table "public"."provider_specialties" to "anon";

grant references on table "public"."provider_specialties" to "anon";

grant select on table "public"."provider_specialties" to "anon";

grant trigger on table "public"."provider_specialties" to "anon";

grant truncate on table "public"."provider_specialties" to "anon";

grant update on table "public"."provider_specialties" to "anon";

grant delete on table "public"."provider_specialties" to "authenticated";

grant insert on table "public"."provider_specialties" to "authenticated";

grant references on table "public"."provider_specialties" to "authenticated";

grant select on table "public"."provider_specialties" to "authenticated";

grant trigger on table "public"."provider_specialties" to "authenticated";

grant truncate on table "public"."provider_specialties" to "authenticated";

grant update on table "public"."provider_specialties" to "authenticated";

grant delete on table "public"."provider_specialties" to "service_role";

grant insert on table "public"."provider_specialties" to "service_role";

grant references on table "public"."provider_specialties" to "service_role";

grant select on table "public"."provider_specialties" to "service_role";

grant trigger on table "public"."provider_specialties" to "service_role";

grant truncate on table "public"."provider_specialties" to "service_role";

grant update on table "public"."provider_specialties" to "service_role";

grant delete on table "public"."provider_vendor_specialties" to "anon";

grant insert on table "public"."provider_vendor_specialties" to "anon";

grant references on table "public"."provider_vendor_specialties" to "anon";

grant select on table "public"."provider_vendor_specialties" to "anon";

grant trigger on table "public"."provider_vendor_specialties" to "anon";

grant truncate on table "public"."provider_vendor_specialties" to "anon";

grant update on table "public"."provider_vendor_specialties" to "anon";

grant delete on table "public"."provider_vendor_specialties" to "authenticated";

grant insert on table "public"."provider_vendor_specialties" to "authenticated";

grant references on table "public"."provider_vendor_specialties" to "authenticated";

grant select on table "public"."provider_vendor_specialties" to "authenticated";

grant trigger on table "public"."provider_vendor_specialties" to "authenticated";

grant truncate on table "public"."provider_vendor_specialties" to "authenticated";

grant update on table "public"."provider_vendor_specialties" to "authenticated";

grant delete on table "public"."provider_vendor_specialties" to "service_role";

grant insert on table "public"."provider_vendor_specialties" to "service_role";

grant references on table "public"."provider_vendor_specialties" to "service_role";

grant select on table "public"."provider_vendor_specialties" to "service_role";

grant trigger on table "public"."provider_vendor_specialties" to "service_role";

grant truncate on table "public"."provider_vendor_specialties" to "service_role";

grant update on table "public"."provider_vendor_specialties" to "service_role";

grant delete on table "public"."providers" to "anon";

grant insert on table "public"."providers" to "anon";

grant references on table "public"."providers" to "anon";

grant select on table "public"."providers" to "anon";

grant trigger on table "public"."providers" to "anon";

grant truncate on table "public"."providers" to "anon";

grant update on table "public"."providers" to "anon";

grant delete on table "public"."providers" to "authenticated";

grant insert on table "public"."providers" to "authenticated";

grant references on table "public"."providers" to "authenticated";

grant select on table "public"."providers" to "authenticated";

grant trigger on table "public"."providers" to "authenticated";

grant truncate on table "public"."providers" to "authenticated";

grant update on table "public"."providers" to "authenticated";

grant delete on table "public"."providers" to "service_role";

grant insert on table "public"."providers" to "service_role";

grant references on table "public"."providers" to "service_role";

grant select on table "public"."providers" to "service_role";

grant trigger on table "public"."providers" to "service_role";

grant truncate on table "public"."providers" to "service_role";

grant update on table "public"."providers" to "service_role";

grant delete on table "public"."rfqs" to "anon";

grant insert on table "public"."rfqs" to "anon";

grant references on table "public"."rfqs" to "anon";

grant select on table "public"."rfqs" to "anon";

grant trigger on table "public"."rfqs" to "anon";

grant truncate on table "public"."rfqs" to "anon";

grant update on table "public"."rfqs" to "anon";

grant delete on table "public"."rfqs" to "authenticated";

grant insert on table "public"."rfqs" to "authenticated";

grant references on table "public"."rfqs" to "authenticated";

grant select on table "public"."rfqs" to "authenticated";

grant trigger on table "public"."rfqs" to "authenticated";

grant truncate on table "public"."rfqs" to "authenticated";

grant update on table "public"."rfqs" to "authenticated";

grant delete on table "public"."rfqs" to "service_role";

grant insert on table "public"."rfqs" to "service_role";

grant references on table "public"."rfqs" to "service_role";

grant select on table "public"."rfqs" to "service_role";

grant trigger on table "public"."rfqs" to "service_role";

grant truncate on table "public"."rfqs" to "service_role";

grant update on table "public"."rfqs" to "service_role";

grant delete on table "public"."seasonal_content_analytics_daily" to "anon";

grant insert on table "public"."seasonal_content_analytics_daily" to "anon";

grant references on table "public"."seasonal_content_analytics_daily" to "anon";

grant select on table "public"."seasonal_content_analytics_daily" to "anon";

grant trigger on table "public"."seasonal_content_analytics_daily" to "anon";

grant truncate on table "public"."seasonal_content_analytics_daily" to "anon";

grant update on table "public"."seasonal_content_analytics_daily" to "anon";

grant delete on table "public"."seasonal_content_analytics_daily" to "authenticated";

grant insert on table "public"."seasonal_content_analytics_daily" to "authenticated";

grant references on table "public"."seasonal_content_analytics_daily" to "authenticated";

grant select on table "public"."seasonal_content_analytics_daily" to "authenticated";

grant trigger on table "public"."seasonal_content_analytics_daily" to "authenticated";

grant truncate on table "public"."seasonal_content_analytics_daily" to "authenticated";

grant update on table "public"."seasonal_content_analytics_daily" to "authenticated";

grant delete on table "public"."seasonal_content_analytics_daily" to "service_role";

grant insert on table "public"."seasonal_content_analytics_daily" to "service_role";

grant references on table "public"."seasonal_content_analytics_daily" to "service_role";

grant select on table "public"."seasonal_content_analytics_daily" to "service_role";

grant trigger on table "public"."seasonal_content_analytics_daily" to "service_role";

grant truncate on table "public"."seasonal_content_analytics_daily" to "service_role";

grant update on table "public"."seasonal_content_analytics_daily" to "service_role";

grant delete on table "public"."seasonal_crafts" to "anon";

grant insert on table "public"."seasonal_crafts" to "anon";

grant references on table "public"."seasonal_crafts" to "anon";

grant select on table "public"."seasonal_crafts" to "anon";

grant trigger on table "public"."seasonal_crafts" to "anon";

grant truncate on table "public"."seasonal_crafts" to "anon";

grant update on table "public"."seasonal_crafts" to "anon";

grant delete on table "public"."seasonal_crafts" to "authenticated";

grant insert on table "public"."seasonal_crafts" to "authenticated";

grant references on table "public"."seasonal_crafts" to "authenticated";

grant select on table "public"."seasonal_crafts" to "authenticated";

grant trigger on table "public"."seasonal_crafts" to "authenticated";

grant truncate on table "public"."seasonal_crafts" to "authenticated";

grant update on table "public"."seasonal_crafts" to "authenticated";

grant delete on table "public"."seasonal_crafts" to "service_role";

grant insert on table "public"."seasonal_crafts" to "service_role";

grant references on table "public"."seasonal_crafts" to "service_role";

grant select on table "public"."seasonal_crafts" to "service_role";

grant trigger on table "public"."seasonal_crafts" to "service_role";

grant truncate on table "public"."seasonal_crafts" to "service_role";

grant update on table "public"."seasonal_crafts" to "service_role";

grant delete on table "public"."seasonal_produce" to "anon";

grant insert on table "public"."seasonal_produce" to "anon";

grant references on table "public"."seasonal_produce" to "anon";

grant select on table "public"."seasonal_produce" to "anon";

grant trigger on table "public"."seasonal_produce" to "anon";

grant truncate on table "public"."seasonal_produce" to "anon";

grant update on table "public"."seasonal_produce" to "anon";

grant delete on table "public"."seasonal_produce" to "authenticated";

grant insert on table "public"."seasonal_produce" to "authenticated";

grant references on table "public"."seasonal_produce" to "authenticated";

grant select on table "public"."seasonal_produce" to "authenticated";

grant trigger on table "public"."seasonal_produce" to "authenticated";

grant truncate on table "public"."seasonal_produce" to "authenticated";

grant update on table "public"."seasonal_produce" to "authenticated";

grant delete on table "public"."seasonal_produce" to "service_role";

grant insert on table "public"."seasonal_produce" to "service_role";

grant references on table "public"."seasonal_produce" to "service_role";

grant select on table "public"."seasonal_produce" to "service_role";

grant trigger on table "public"."seasonal_produce" to "service_role";

grant truncate on table "public"."seasonal_produce" to "service_role";

grant update on table "public"."seasonal_produce" to "service_role";

grant delete on table "public"."seasonal_recipes" to "anon";

grant insert on table "public"."seasonal_recipes" to "anon";

grant references on table "public"."seasonal_recipes" to "anon";

grant select on table "public"."seasonal_recipes" to "anon";

grant trigger on table "public"."seasonal_recipes" to "anon";

grant truncate on table "public"."seasonal_recipes" to "anon";

grant update on table "public"."seasonal_recipes" to "anon";

grant delete on table "public"."seasonal_recipes" to "authenticated";

grant insert on table "public"."seasonal_recipes" to "authenticated";

grant references on table "public"."seasonal_recipes" to "authenticated";

grant select on table "public"."seasonal_recipes" to "authenticated";

grant trigger on table "public"."seasonal_recipes" to "authenticated";

grant truncate on table "public"."seasonal_recipes" to "authenticated";

grant update on table "public"."seasonal_recipes" to "authenticated";

grant delete on table "public"."seasonal_recipes" to "service_role";

grant insert on table "public"."seasonal_recipes" to "service_role";

grant references on table "public"."seasonal_recipes" to "service_role";

grant select on table "public"."seasonal_recipes" to "service_role";

grant trigger on table "public"."seasonal_recipes" to "service_role";

grant truncate on table "public"."seasonal_recipes" to "service_role";

grant update on table "public"."seasonal_recipes" to "service_role";

grant delete on table "public"."seasonal_seeds" to "anon";

grant insert on table "public"."seasonal_seeds" to "anon";

grant references on table "public"."seasonal_seeds" to "anon";

grant select on table "public"."seasonal_seeds" to "anon";

grant trigger on table "public"."seasonal_seeds" to "anon";

grant truncate on table "public"."seasonal_seeds" to "anon";

grant update on table "public"."seasonal_seeds" to "anon";

grant delete on table "public"."seasonal_seeds" to "authenticated";

grant insert on table "public"."seasonal_seeds" to "authenticated";

grant references on table "public"."seasonal_seeds" to "authenticated";

grant select on table "public"."seasonal_seeds" to "authenticated";

grant trigger on table "public"."seasonal_seeds" to "authenticated";

grant truncate on table "public"."seasonal_seeds" to "authenticated";

grant update on table "public"."seasonal_seeds" to "authenticated";

grant delete on table "public"."seasonal_seeds" to "service_role";

grant insert on table "public"."seasonal_seeds" to "service_role";

grant references on table "public"."seasonal_seeds" to "service_role";

grant select on table "public"."seasonal_seeds" to "service_role";

grant trigger on table "public"."seasonal_seeds" to "service_role";

grant truncate on table "public"."seasonal_seeds" to "service_role";

grant update on table "public"."seasonal_seeds" to "service_role";

grant references on table "public"."specialty_compliance_overlays" to "anon";

grant select on table "public"."specialty_compliance_overlays" to "anon";

grant trigger on table "public"."specialty_compliance_overlays" to "anon";

grant truncate on table "public"."specialty_compliance_overlays" to "anon";

grant references on table "public"."specialty_compliance_overlays" to "authenticated";

grant select on table "public"."specialty_compliance_overlays" to "authenticated";

grant trigger on table "public"."specialty_compliance_overlays" to "authenticated";

grant truncate on table "public"."specialty_compliance_overlays" to "authenticated";

grant delete on table "public"."specialty_compliance_overlays" to "service_role";

grant insert on table "public"."specialty_compliance_overlays" to "service_role";

grant references on table "public"."specialty_compliance_overlays" to "service_role";

grant select on table "public"."specialty_compliance_overlays" to "service_role";

grant trigger on table "public"."specialty_compliance_overlays" to "service_role";

grant truncate on table "public"."specialty_compliance_overlays" to "service_role";

grant update on table "public"."specialty_compliance_overlays" to "service_role";

grant references on table "public"."specialty_kids_mode_overlays" to "anon";

grant select on table "public"."specialty_kids_mode_overlays" to "anon";

grant trigger on table "public"."specialty_kids_mode_overlays" to "anon";

grant truncate on table "public"."specialty_kids_mode_overlays" to "anon";

grant references on table "public"."specialty_kids_mode_overlays" to "authenticated";

grant select on table "public"."specialty_kids_mode_overlays" to "authenticated";

grant trigger on table "public"."specialty_kids_mode_overlays" to "authenticated";

grant truncate on table "public"."specialty_kids_mode_overlays" to "authenticated";

grant delete on table "public"."specialty_kids_mode_overlays" to "service_role";

grant insert on table "public"."specialty_kids_mode_overlays" to "service_role";

grant references on table "public"."specialty_kids_mode_overlays" to "service_role";

grant select on table "public"."specialty_kids_mode_overlays" to "service_role";

grant trigger on table "public"."specialty_kids_mode_overlays" to "service_role";

grant truncate on table "public"."specialty_kids_mode_overlays" to "service_role";

grant update on table "public"."specialty_kids_mode_overlays" to "service_role";

grant references on table "public"."specialty_vertical_overlays" to "anon";

grant select on table "public"."specialty_vertical_overlays" to "anon";

grant trigger on table "public"."specialty_vertical_overlays" to "anon";

grant truncate on table "public"."specialty_vertical_overlays" to "anon";

grant references on table "public"."specialty_vertical_overlays" to "authenticated";

grant select on table "public"."specialty_vertical_overlays" to "authenticated";

grant trigger on table "public"."specialty_vertical_overlays" to "authenticated";

grant truncate on table "public"."specialty_vertical_overlays" to "authenticated";

grant delete on table "public"."specialty_vertical_overlays" to "service_role";

grant insert on table "public"."specialty_vertical_overlays" to "service_role";

grant references on table "public"."specialty_vertical_overlays" to "service_role";

grant select on table "public"."specialty_vertical_overlays" to "service_role";

grant trigger on table "public"."specialty_vertical_overlays" to "service_role";

grant truncate on table "public"."specialty_vertical_overlays" to "service_role";

grant update on table "public"."specialty_vertical_overlays" to "service_role";

grant delete on table "public"."specialty_vertical_overlays_bak" to "anon";

grant insert on table "public"."specialty_vertical_overlays_bak" to "anon";

grant references on table "public"."specialty_vertical_overlays_bak" to "anon";

grant select on table "public"."specialty_vertical_overlays_bak" to "anon";

grant trigger on table "public"."specialty_vertical_overlays_bak" to "anon";

grant truncate on table "public"."specialty_vertical_overlays_bak" to "anon";

grant update on table "public"."specialty_vertical_overlays_bak" to "anon";

grant delete on table "public"."specialty_vertical_overlays_bak" to "authenticated";

grant insert on table "public"."specialty_vertical_overlays_bak" to "authenticated";

grant references on table "public"."specialty_vertical_overlays_bak" to "authenticated";

grant select on table "public"."specialty_vertical_overlays_bak" to "authenticated";

grant trigger on table "public"."specialty_vertical_overlays_bak" to "authenticated";

grant truncate on table "public"."specialty_vertical_overlays_bak" to "authenticated";

grant update on table "public"."specialty_vertical_overlays_bak" to "authenticated";

grant delete on table "public"."specialty_vertical_overlays_bak" to "service_role";

grant insert on table "public"."specialty_vertical_overlays_bak" to "service_role";

grant references on table "public"."specialty_vertical_overlays_bak" to "service_role";

grant select on table "public"."specialty_vertical_overlays_bak" to "service_role";

grant trigger on table "public"."specialty_vertical_overlays_bak" to "service_role";

grant truncate on table "public"."specialty_vertical_overlays_bak" to "service_role";

grant update on table "public"."specialty_vertical_overlays_bak" to "service_role";

grant delete on table "public"."specialty_vertical_overlays_v1" to "anon";

grant insert on table "public"."specialty_vertical_overlays_v1" to "anon";

grant references on table "public"."specialty_vertical_overlays_v1" to "anon";

grant select on table "public"."specialty_vertical_overlays_v1" to "anon";

grant trigger on table "public"."specialty_vertical_overlays_v1" to "anon";

grant truncate on table "public"."specialty_vertical_overlays_v1" to "anon";

grant update on table "public"."specialty_vertical_overlays_v1" to "anon";

grant delete on table "public"."specialty_vertical_overlays_v1" to "authenticated";

grant insert on table "public"."specialty_vertical_overlays_v1" to "authenticated";

grant references on table "public"."specialty_vertical_overlays_v1" to "authenticated";

grant select on table "public"."specialty_vertical_overlays_v1" to "authenticated";

grant trigger on table "public"."specialty_vertical_overlays_v1" to "authenticated";

grant truncate on table "public"."specialty_vertical_overlays_v1" to "authenticated";

grant update on table "public"."specialty_vertical_overlays_v1" to "authenticated";

grant delete on table "public"."specialty_vertical_overlays_v1" to "service_role";

grant insert on table "public"."specialty_vertical_overlays_v1" to "service_role";

grant references on table "public"."specialty_vertical_overlays_v1" to "service_role";

grant select on table "public"."specialty_vertical_overlays_v1" to "service_role";

grant trigger on table "public"."specialty_vertical_overlays_v1" to "service_role";

grant truncate on table "public"."specialty_vertical_overlays_v1" to "service_role";

grant update on table "public"."specialty_vertical_overlays_v1" to "service_role";

grant delete on table "public"."user_admin_actions" to "anon";

grant insert on table "public"."user_admin_actions" to "anon";

grant references on table "public"."user_admin_actions" to "anon";

grant select on table "public"."user_admin_actions" to "anon";

grant trigger on table "public"."user_admin_actions" to "anon";

grant truncate on table "public"."user_admin_actions" to "anon";

grant update on table "public"."user_admin_actions" to "anon";

grant delete on table "public"."user_admin_actions" to "authenticated";

grant insert on table "public"."user_admin_actions" to "authenticated";

grant references on table "public"."user_admin_actions" to "authenticated";

grant select on table "public"."user_admin_actions" to "authenticated";

grant trigger on table "public"."user_admin_actions" to "authenticated";

grant truncate on table "public"."user_admin_actions" to "authenticated";

grant update on table "public"."user_admin_actions" to "authenticated";

grant delete on table "public"."user_admin_actions" to "service_role";

grant insert on table "public"."user_admin_actions" to "service_role";

grant references on table "public"."user_admin_actions" to "service_role";

grant select on table "public"."user_admin_actions" to "service_role";

grant trigger on table "public"."user_admin_actions" to "service_role";

grant truncate on table "public"."user_admin_actions" to "service_role";

grant update on table "public"."user_admin_actions" to "service_role";

grant delete on table "public"."user_consents" to "anon";

grant insert on table "public"."user_consents" to "anon";

grant references on table "public"."user_consents" to "anon";

grant select on table "public"."user_consents" to "anon";

grant trigger on table "public"."user_consents" to "anon";

grant truncate on table "public"."user_consents" to "anon";

grant update on table "public"."user_consents" to "anon";

grant delete on table "public"."user_consents" to "authenticated";

grant insert on table "public"."user_consents" to "authenticated";

grant references on table "public"."user_consents" to "authenticated";

grant select on table "public"."user_consents" to "authenticated";

grant trigger on table "public"."user_consents" to "authenticated";

grant truncate on table "public"."user_consents" to "authenticated";

grant update on table "public"."user_consents" to "authenticated";

grant delete on table "public"."user_consents" to "service_role";

grant insert on table "public"."user_consents" to "service_role";

grant references on table "public"."user_consents" to "service_role";

grant select on table "public"."user_consents" to "service_role";

grant trigger on table "public"."user_consents" to "service_role";

grant truncate on table "public"."user_consents" to "service_role";

grant update on table "public"."user_consents" to "service_role";

grant delete on table "public"."user_devices" to "anon";

grant insert on table "public"."user_devices" to "anon";

grant references on table "public"."user_devices" to "anon";

grant select on table "public"."user_devices" to "anon";

grant trigger on table "public"."user_devices" to "anon";

grant truncate on table "public"."user_devices" to "anon";

grant update on table "public"."user_devices" to "anon";

grant delete on table "public"."user_devices" to "authenticated";

grant insert on table "public"."user_devices" to "authenticated";

grant references on table "public"."user_devices" to "authenticated";

grant select on table "public"."user_devices" to "authenticated";

grant trigger on table "public"."user_devices" to "authenticated";

grant truncate on table "public"."user_devices" to "authenticated";

grant update on table "public"."user_devices" to "authenticated";

grant delete on table "public"."user_devices" to "service_role";

grant insert on table "public"."user_devices" to "service_role";

grant references on table "public"."user_devices" to "service_role";

grant select on table "public"."user_devices" to "service_role";

grant trigger on table "public"."user_devices" to "service_role";

grant truncate on table "public"."user_devices" to "service_role";

grant update on table "public"."user_devices" to "service_role";

grant delete on table "public"."user_password_history" to "service_role";

grant insert on table "public"."user_password_history" to "service_role";

grant references on table "public"."user_password_history" to "service_role";

grant select on table "public"."user_password_history" to "service_role";

grant trigger on table "public"."user_password_history" to "service_role";

grant truncate on table "public"."user_password_history" to "service_role";

grant update on table "public"."user_password_history" to "service_role";

grant delete on table "public"."user_tier_memberships" to "service_role";

grant insert on table "public"."user_tier_memberships" to "service_role";

grant references on table "public"."user_tier_memberships" to "service_role";

grant select on table "public"."user_tier_memberships" to "service_role";

grant trigger on table "public"."user_tier_memberships" to "service_role";

grant truncate on table "public"."user_tier_memberships" to "service_role";

grant update on table "public"."user_tier_memberships" to "service_role";

grant delete on table "public"."user_tiers" to "anon";

grant insert on table "public"."user_tiers" to "anon";

grant references on table "public"."user_tiers" to "anon";

grant select on table "public"."user_tiers" to "anon";

grant trigger on table "public"."user_tiers" to "anon";

grant truncate on table "public"."user_tiers" to "anon";

grant update on table "public"."user_tiers" to "anon";

grant delete on table "public"."user_tiers" to "authenticated";

grant insert on table "public"."user_tiers" to "authenticated";

grant references on table "public"."user_tiers" to "authenticated";

grant select on table "public"."user_tiers" to "authenticated";

grant trigger on table "public"."user_tiers" to "authenticated";

grant truncate on table "public"."user_tiers" to "authenticated";

grant update on table "public"."user_tiers" to "authenticated";

grant delete on table "public"."user_tiers" to "service_role";

grant insert on table "public"."user_tiers" to "service_role";

grant references on table "public"."user_tiers" to "service_role";

grant select on table "public"."user_tiers" to "service_role";

grant trigger on table "public"."user_tiers" to "service_role";

grant truncate on table "public"."user_tiers" to "service_role";

grant update on table "public"."user_tiers" to "service_role";

grant delete on table "public"."vendor_analytics_advanced_daily" to "anon";

grant insert on table "public"."vendor_analytics_advanced_daily" to "anon";

grant references on table "public"."vendor_analytics_advanced_daily" to "anon";

grant select on table "public"."vendor_analytics_advanced_daily" to "anon";

grant trigger on table "public"."vendor_analytics_advanced_daily" to "anon";

grant truncate on table "public"."vendor_analytics_advanced_daily" to "anon";

grant update on table "public"."vendor_analytics_advanced_daily" to "anon";

grant delete on table "public"."vendor_analytics_advanced_daily" to "authenticated";

grant insert on table "public"."vendor_analytics_advanced_daily" to "authenticated";

grant references on table "public"."vendor_analytics_advanced_daily" to "authenticated";

grant select on table "public"."vendor_analytics_advanced_daily" to "authenticated";

grant trigger on table "public"."vendor_analytics_advanced_daily" to "authenticated";

grant truncate on table "public"."vendor_analytics_advanced_daily" to "authenticated";

grant update on table "public"."vendor_analytics_advanced_daily" to "authenticated";

grant delete on table "public"."vendor_analytics_advanced_daily" to "service_role";

grant insert on table "public"."vendor_analytics_advanced_daily" to "service_role";

grant references on table "public"."vendor_analytics_advanced_daily" to "service_role";

grant select on table "public"."vendor_analytics_advanced_daily" to "service_role";

grant trigger on table "public"."vendor_analytics_advanced_daily" to "service_role";

grant truncate on table "public"."vendor_analytics_advanced_daily" to "service_role";

grant update on table "public"."vendor_analytics_advanced_daily" to "service_role";

grant delete on table "public"."vendor_analytics_basic_daily" to "anon";

grant insert on table "public"."vendor_analytics_basic_daily" to "anon";

grant references on table "public"."vendor_analytics_basic_daily" to "anon";

grant select on table "public"."vendor_analytics_basic_daily" to "anon";

grant trigger on table "public"."vendor_analytics_basic_daily" to "anon";

grant truncate on table "public"."vendor_analytics_basic_daily" to "anon";

grant update on table "public"."vendor_analytics_basic_daily" to "anon";

grant delete on table "public"."vendor_analytics_basic_daily" to "authenticated";

grant insert on table "public"."vendor_analytics_basic_daily" to "authenticated";

grant references on table "public"."vendor_analytics_basic_daily" to "authenticated";

grant select on table "public"."vendor_analytics_basic_daily" to "authenticated";

grant trigger on table "public"."vendor_analytics_basic_daily" to "authenticated";

grant truncate on table "public"."vendor_analytics_basic_daily" to "authenticated";

grant update on table "public"."vendor_analytics_basic_daily" to "authenticated";

grant delete on table "public"."vendor_analytics_basic_daily" to "service_role";

grant insert on table "public"."vendor_analytics_basic_daily" to "service_role";

grant references on table "public"."vendor_analytics_basic_daily" to "service_role";

grant select on table "public"."vendor_analytics_basic_daily" to "service_role";

grant trigger on table "public"."vendor_analytics_basic_daily" to "service_role";

grant truncate on table "public"."vendor_analytics_basic_daily" to "service_role";

grant update on table "public"."vendor_analytics_basic_daily" to "service_role";

grant delete on table "public"."vendor_analytics_daily" to "anon";

grant insert on table "public"."vendor_analytics_daily" to "anon";

grant references on table "public"."vendor_analytics_daily" to "anon";

grant select on table "public"."vendor_analytics_daily" to "anon";

grant trigger on table "public"."vendor_analytics_daily" to "anon";

grant truncate on table "public"."vendor_analytics_daily" to "anon";

grant update on table "public"."vendor_analytics_daily" to "anon";

grant delete on table "public"."vendor_analytics_daily" to "authenticated";

grant insert on table "public"."vendor_analytics_daily" to "authenticated";

grant references on table "public"."vendor_analytics_daily" to "authenticated";

grant select on table "public"."vendor_analytics_daily" to "authenticated";

grant trigger on table "public"."vendor_analytics_daily" to "authenticated";

grant truncate on table "public"."vendor_analytics_daily" to "authenticated";

grant update on table "public"."vendor_analytics_daily" to "authenticated";

grant delete on table "public"."vendor_analytics_daily" to "service_role";

grant insert on table "public"."vendor_analytics_daily" to "service_role";

grant references on table "public"."vendor_analytics_daily" to "service_role";

grant select on table "public"."vendor_analytics_daily" to "service_role";

grant trigger on table "public"."vendor_analytics_daily" to "service_role";

grant truncate on table "public"."vendor_analytics_daily" to "service_role";

grant update on table "public"."vendor_analytics_daily" to "service_role";

grant delete on table "public"."vendor_applications" to "anon";

grant insert on table "public"."vendor_applications" to "anon";

grant references on table "public"."vendor_applications" to "anon";

grant select on table "public"."vendor_applications" to "anon";

grant trigger on table "public"."vendor_applications" to "anon";

grant truncate on table "public"."vendor_applications" to "anon";

grant update on table "public"."vendor_applications" to "anon";

grant delete on table "public"."vendor_applications" to "authenticated";

grant insert on table "public"."vendor_applications" to "authenticated";

grant references on table "public"."vendor_applications" to "authenticated";

grant select on table "public"."vendor_applications" to "authenticated";

grant trigger on table "public"."vendor_applications" to "authenticated";

grant truncate on table "public"."vendor_applications" to "authenticated";

grant update on table "public"."vendor_applications" to "authenticated";

grant delete on table "public"."vendor_applications" to "service_role";

grant insert on table "public"."vendor_applications" to "service_role";

grant references on table "public"."vendor_applications" to "service_role";

grant select on table "public"."vendor_applications" to "service_role";

grant trigger on table "public"."vendor_applications" to "service_role";

grant truncate on table "public"."vendor_applications" to "service_role";

grant update on table "public"."vendor_applications" to "service_role";

grant delete on table "public"."vendor_media" to "anon";

grant insert on table "public"."vendor_media" to "anon";

grant references on table "public"."vendor_media" to "anon";

grant select on table "public"."vendor_media" to "anon";

grant trigger on table "public"."vendor_media" to "anon";

grant truncate on table "public"."vendor_media" to "anon";

grant update on table "public"."vendor_media" to "anon";

grant delete on table "public"."vendor_media" to "authenticated";

grant insert on table "public"."vendor_media" to "authenticated";

grant references on table "public"."vendor_media" to "authenticated";

grant select on table "public"."vendor_media" to "authenticated";

grant trigger on table "public"."vendor_media" to "authenticated";

grant truncate on table "public"."vendor_media" to "authenticated";

grant update on table "public"."vendor_media" to "authenticated";

grant delete on table "public"."vendor_media" to "service_role";

grant insert on table "public"."vendor_media" to "service_role";

grant references on table "public"."vendor_media" to "service_role";

grant select on table "public"."vendor_media" to "service_role";

grant trigger on table "public"."vendor_media" to "service_role";

grant truncate on table "public"."vendor_media" to "service_role";

grant update on table "public"."vendor_media" to "service_role";

grant delete on table "public"."vendor_specialties" to "anon";

grant insert on table "public"."vendor_specialties" to "anon";

grant references on table "public"."vendor_specialties" to "anon";

grant select on table "public"."vendor_specialties" to "anon";

grant trigger on table "public"."vendor_specialties" to "anon";

grant truncate on table "public"."vendor_specialties" to "anon";

grant update on table "public"."vendor_specialties" to "anon";

grant delete on table "public"."vendor_specialties" to "authenticated";

grant insert on table "public"."vendor_specialties" to "authenticated";

grant references on table "public"."vendor_specialties" to "authenticated";

grant select on table "public"."vendor_specialties" to "authenticated";

grant trigger on table "public"."vendor_specialties" to "authenticated";

grant truncate on table "public"."vendor_specialties" to "authenticated";

grant update on table "public"."vendor_specialties" to "authenticated";

grant delete on table "public"."vendor_specialties" to "service_role";

grant insert on table "public"."vendor_specialties" to "service_role";

grant references on table "public"."vendor_specialties" to "service_role";

grant select on table "public"."vendor_specialties" to "service_role";

grant trigger on table "public"."vendor_specialties" to "service_role";

grant truncate on table "public"."vendor_specialties" to "service_role";

grant update on table "public"."vendor_specialties" to "service_role";

grant delete on table "public"."vertical_canonical_specialties_bak" to "anon";

grant insert on table "public"."vertical_canonical_specialties_bak" to "anon";

grant references on table "public"."vertical_canonical_specialties_bak" to "anon";

grant select on table "public"."vertical_canonical_specialties_bak" to "anon";

grant trigger on table "public"."vertical_canonical_specialties_bak" to "anon";

grant truncate on table "public"."vertical_canonical_specialties_bak" to "anon";

grant update on table "public"."vertical_canonical_specialties_bak" to "anon";

grant delete on table "public"."vertical_canonical_specialties_bak" to "authenticated";

grant insert on table "public"."vertical_canonical_specialties_bak" to "authenticated";

grant references on table "public"."vertical_canonical_specialties_bak" to "authenticated";

grant select on table "public"."vertical_canonical_specialties_bak" to "authenticated";

grant trigger on table "public"."vertical_canonical_specialties_bak" to "authenticated";

grant truncate on table "public"."vertical_canonical_specialties_bak" to "authenticated";

grant update on table "public"."vertical_canonical_specialties_bak" to "authenticated";

grant delete on table "public"."vertical_canonical_specialties_bak" to "service_role";

grant insert on table "public"."vertical_canonical_specialties_bak" to "service_role";

grant references on table "public"."vertical_canonical_specialties_bak" to "service_role";

grant select on table "public"."vertical_canonical_specialties_bak" to "service_role";

grant trigger on table "public"."vertical_canonical_specialties_bak" to "service_role";

grant truncate on table "public"."vertical_canonical_specialties_bak" to "service_role";

grant update on table "public"."vertical_canonical_specialties_bak" to "service_role";

grant delete on table "public"."vertical_capability_defaults" to "anon";

grant insert on table "public"."vertical_capability_defaults" to "anon";

grant references on table "public"."vertical_capability_defaults" to "anon";

grant select on table "public"."vertical_capability_defaults" to "anon";

grant trigger on table "public"."vertical_capability_defaults" to "anon";

grant truncate on table "public"."vertical_capability_defaults" to "anon";

grant update on table "public"."vertical_capability_defaults" to "anon";

grant delete on table "public"."vertical_capability_defaults" to "authenticated";

grant insert on table "public"."vertical_capability_defaults" to "authenticated";

grant references on table "public"."vertical_capability_defaults" to "authenticated";

grant select on table "public"."vertical_capability_defaults" to "authenticated";

grant trigger on table "public"."vertical_capability_defaults" to "authenticated";

grant truncate on table "public"."vertical_capability_defaults" to "authenticated";

grant update on table "public"."vertical_capability_defaults" to "authenticated";

grant delete on table "public"."vertical_capability_defaults" to "service_role";

grant insert on table "public"."vertical_capability_defaults" to "service_role";

grant references on table "public"."vertical_capability_defaults" to "service_role";

grant select on table "public"."vertical_capability_defaults" to "service_role";

grant trigger on table "public"."vertical_capability_defaults" to "service_role";

grant truncate on table "public"."vertical_capability_defaults" to "service_role";

grant update on table "public"."vertical_capability_defaults" to "service_role";

grant references on table "public"."vertical_conditions" to "anon";

grant select on table "public"."vertical_conditions" to "anon";

grant trigger on table "public"."vertical_conditions" to "anon";

grant truncate on table "public"."vertical_conditions" to "anon";

grant references on table "public"."vertical_conditions" to "authenticated";

grant select on table "public"."vertical_conditions" to "authenticated";

grant trigger on table "public"."vertical_conditions" to "authenticated";

grant truncate on table "public"."vertical_conditions" to "authenticated";

grant delete on table "public"."vertical_conditions" to "service_role";

grant insert on table "public"."vertical_conditions" to "service_role";

grant references on table "public"."vertical_conditions" to "service_role";

grant select on table "public"."vertical_conditions" to "service_role";

grant trigger on table "public"."vertical_conditions" to "service_role";

grant truncate on table "public"."vertical_conditions" to "service_role";

grant update on table "public"."vertical_conditions" to "service_role";

grant delete on table "public"."vertical_market_requirements" to "anon";

grant insert on table "public"."vertical_market_requirements" to "anon";

grant references on table "public"."vertical_market_requirements" to "anon";

grant select on table "public"."vertical_market_requirements" to "anon";

grant trigger on table "public"."vertical_market_requirements" to "anon";

grant truncate on table "public"."vertical_market_requirements" to "anon";

grant update on table "public"."vertical_market_requirements" to "anon";

grant delete on table "public"."vertical_market_requirements" to "authenticated";

grant insert on table "public"."vertical_market_requirements" to "authenticated";

grant references on table "public"."vertical_market_requirements" to "authenticated";

grant select on table "public"."vertical_market_requirements" to "authenticated";

grant trigger on table "public"."vertical_market_requirements" to "authenticated";

grant truncate on table "public"."vertical_market_requirements" to "authenticated";

grant update on table "public"."vertical_market_requirements" to "authenticated";

grant delete on table "public"."vertical_market_requirements" to "service_role";

grant insert on table "public"."vertical_market_requirements" to "service_role";

grant references on table "public"."vertical_market_requirements" to "service_role";

grant select on table "public"."vertical_market_requirements" to "service_role";

grant trigger on table "public"."vertical_market_requirements" to "service_role";

grant truncate on table "public"."vertical_market_requirements" to "service_role";

grant update on table "public"."vertical_market_requirements" to "service_role";

grant delete on table "public"."weather_snapshots" to "anon";

grant insert on table "public"."weather_snapshots" to "anon";

grant references on table "public"."weather_snapshots" to "anon";

grant select on table "public"."weather_snapshots" to "anon";

grant trigger on table "public"."weather_snapshots" to "anon";

grant truncate on table "public"."weather_snapshots" to "anon";

grant update on table "public"."weather_snapshots" to "anon";

grant delete on table "public"."weather_snapshots" to "authenticated";

grant insert on table "public"."weather_snapshots" to "authenticated";

grant references on table "public"."weather_snapshots" to "authenticated";

grant select on table "public"."weather_snapshots" to "authenticated";

grant trigger on table "public"."weather_snapshots" to "authenticated";

grant truncate on table "public"."weather_snapshots" to "authenticated";

grant update on table "public"."weather_snapshots" to "authenticated";

grant delete on table "public"."weather_snapshots" to "service_role";

grant insert on table "public"."weather_snapshots" to "service_role";

grant references on table "public"."weather_snapshots" to "service_role";

grant select on table "public"."weather_snapshots" to "service_role";

grant trigger on table "public"."weather_snapshots" to "service_role";

grant truncate on table "public"."weather_snapshots" to "service_role";

grant update on table "public"."weather_snapshots" to "service_role";


  create policy "admin_can_manage_all_deletion_requests"
  on "public"."account_deletion_requests"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))));



  create policy "user_can_create_own_deletion_request"
  on "public"."account_deletion_requests"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = user_id));



  create policy "user_can_view_own_deletion_request"
  on "public"."account_deletion_requests"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



  create policy "App settings readable to authenticated"
  on "public"."app_settings"
  as permissive
  for select
  to authenticated
using (true);



  create policy "arts_culture_event_context_profiles_read_all"
  on "public"."arts_culture_event_context_profiles"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "arts_culture_event_context_profiles_write_service_role"
  on "public"."arts_culture_event_context_profiles"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Arts & Culture event owners can delete"
  on "public"."arts_culture_events"
  as permissive
  for delete
  to public
using ((auth.uid() = created_by));



  create policy "Arts & Culture event owners can insert"
  on "public"."arts_culture_events"
  as permissive
  for insert
  to public
with check ((auth.uid() = created_by));



  create policy "Arts & Culture event owners can update"
  on "public"."arts_culture_events"
  as permissive
  for update
  to public
using ((auth.uid() = created_by))
with check ((auth.uid() = created_by));



  create policy "Arts & Culture events readable by all"
  on "public"."arts_culture_events"
  as permissive
  for select
  to public
using (true);



  create policy "admin_can_read_all_badges"
  on "public"."badges"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "badges_admin_all_access"
  on "public"."badges"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "badges_public_read"
  on "public"."badges"
  as permissive
  for select
  to public
using (true);



  create policy "bids_admin_all_access"
  on "public"."bids"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "bids_insert_premium_plus_compliant_provider_required_v1"
  on "public"."bids"
  as permissive
  for insert
  to authenticated
with check (((vendor_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = 'premium_plus'::text) AND (ut.account_status = 'active'::text)))) AND (EXISTS ( SELECT 1
   FROM public.rfqs r
  WHERE ((r.id = bids.rfq_id) AND (r.status = 'open'::text) AND (r.vertical_code = bids.vertical_code)))) AND (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.owner_user_id = auth.uid()) AND (p.vertical = bids.vertical_code) AND (NOT (EXISTS ( SELECT 1
           FROM public.sanctuary_providers sp
          WHERE (sp.provider_id = p.id)))) AND public.provider_is_market_compliant(p.id))))));



  create policy "bids_institution_select_on_own_rfqs"
  on "public"."bids"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.rfqs r
  WHERE ((r.id = bids.rfq_id) AND (r.institution_id = auth.uid())))));



  create policy "bids_require_vertical_compliance_insert_v1"
  on "public"."bids"
  as restrictive
  for insert
  to authenticated
with check (((vendor_id = auth.uid()) AND public.vendor_is_market_compliant_for_vertical(auth.uid(), vertical_code, 'bids'::text)));



  create policy "bids_vendor_delete_own"
  on "public"."bids"
  as permissive
  for delete
  to authenticated
using ((vendor_id = auth.uid()));



  create policy "bids_vendor_select_own"
  on "public"."bids"
  as permissive
  for select
  to authenticated
using ((vendor_id = auth.uid()));



  create policy "bids_vendor_update_own"
  on "public"."bids"
  as permissive
  for update
  to authenticated
using ((vendor_id = auth.uid()))
with check ((vendor_id = auth.uid()));



  create policy "Service role manages billing_customers"
  on "public"."billing_customers"
  as permissive
  for all
  to authenticated
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "User can view own billing row"
  on "public"."billing_customers"
  as permissive
  for select
  to authenticated
using ((user_id = auth.uid()));



  create policy "admin_can_read_all_bulk_offer_analytics"
  on "public"."bulk_offer_analytics"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "bulk_offer_analytics_admin_can_read_all"
  on "public"."bulk_offer_analytics"
  as permissive
  for select
  to authenticated
using (public.is_admin());



  create policy "bulk_offer_analytics_premium_plus_vendor_can_read_own"
  on "public"."bulk_offer_analytics"
  as permissive
  for select
  to authenticated
using (((public.current_user_has_feature('can_view_advanced_analytics'::text) = true) AND (vendor_user_id = auth.uid())));



  create policy "bulk_offer_analytics_system_can_write"
  on "public"."bulk_offer_analytics"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "premium_plus vendors read own bulk analytics"
  on "public"."bulk_offer_analytics"
  as permissive
  for select
  to authenticated
using (((vendor_user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = 'premium_plus'::text))))));



  create policy "system can insert analytics"
  on "public"."bulk_offer_analytics"
  as permissive
  for insert
  to public
with check (true);



  create policy "vendors_premium_read_own_bulk_analytics"
  on "public"."bulk_offer_analytics"
  as permissive
  for select
  to authenticated
using (((vendor_user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])))))));



  create policy "bulk_offers_deny_sanctuary_providers"
  on "public"."bulk_offers"
  as restrictive
  for all
  to public
using ((NOT (EXISTS ( SELECT 1
   FROM public.sanctuary_providers sp
  WHERE (sp.provider_id = bulk_offers.provider_id)))))
with check ((NOT (EXISTS ( SELECT 1
   FROM public.sanctuary_providers sp
  WHERE (sp.provider_id = bulk_offers.provider_id)))));



  create policy "bulk_offers_public_read_active"
  on "public"."bulk_offers"
  as permissive
  for select
  to public
using ((is_active = true));



  create policy "bulk_offers_require_vertical_compliance_insert_v1"
  on "public"."bulk_offers"
  as restrictive
  for insert
  to authenticated
with check (public.provider_is_market_compliant_for_vertical(provider_id, vertical_code, 'bulk_offers'::text));



  create policy "bulk_offers_require_vertical_compliance_update_v1"
  on "public"."bulk_offers"
  as restrictive
  for update
  to authenticated
with check (public.provider_is_market_compliant_for_vertical(provider_id, vertical_code, 'bulk_offers'::text));



  create policy "bulk_offers_vendor_delete_premium_only_v1"
  on "public"."bulk_offers"
  as permissive
  for delete
  to authenticated
using (((created_by = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])))))));



  create policy "bulk_offers_vendor_insert_premium_and_compliant_v1"
  on "public"."bulk_offers"
  as permissive
  for insert
  to authenticated
with check (((created_by = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])) AND (ut.account_status = 'active'::text)))) AND (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = bulk_offers.provider_id) AND (p.owner_user_id = auth.uid())))) AND public.provider_is_market_compliant(provider_id)));



  create policy "bulk_offers_vendor_read_own_v1"
  on "public"."bulk_offers"
  as permissive
  for select
  to authenticated
using ((created_by = auth.uid()));



  create policy "bulk_offers_vendor_update_premium_only_v1"
  on "public"."bulk_offers"
  as permissive
  for update
  to authenticated
using (((created_by = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])))))))
with check (((created_by = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text]))))) AND (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = bulk_offers.provider_id) AND (p.owner_user_id = auth.uid()))))));



  create policy "Read canonical_verticals"
  on "public"."canonical_verticals"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "canonical_verticals_read"
  on "public"."canonical_verticals"
  as permissive
  for select
  to public
using (true);



  create policy "canonical_verticals_read_all"
  on "public"."canonical_verticals"
  as permissive
  for select
  to public
using (true);



  create policy "canonical_verticals_select_all"
  on "public"."canonical_verticals"
  as permissive
  for select
  to public
using (true);



  create policy "canonical_verticals_service_write"
  on "public"."canonical_verticals"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "canonical_verticals_write"
  on "public"."canonical_verticals"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "Community can submit nature spots"
  on "public"."community_nature_spots"
  as permissive
  for insert
  to public
with check ((auth.uid() = created_by));



  create policy "Creators can delete their pending spots"
  on "public"."community_nature_spots"
  as permissive
  for delete
  to public
using (((auth.uid() = created_by) AND (status = 'pending'::text)));



  create policy "Creators can update their pending spots"
  on "public"."community_nature_spots"
  as permissive
  for update
  to public
using (((auth.uid() = created_by) AND (status = 'pending'::text)))
with check ((auth.uid() = created_by));



  create policy "Public can read approved community spots"
  on "public"."community_nature_spots"
  as permissive
  for select
  to public
using ((status = 'approved'::text));



  create policy "Community program owners can delete"
  on "public"."community_programs"
  as permissive
  for delete
  to public
using ((auth.uid() = created_by));



  create policy "Community program owners can insert"
  on "public"."community_programs"
  as permissive
  for insert
  to public
with check ((auth.uid() = created_by));



  create policy "Community program owners can update"
  on "public"."community_programs"
  as permissive
  for update
  to public
using ((auth.uid() = created_by))
with check ((auth.uid() = created_by));



  create policy "Community programs are readable to all"
  on "public"."community_programs"
  as permissive
  for select
  to public
using (true);



  create policy "community_specialty_registry_read_all"
  on "public"."community_specialty_registry"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "community_specialty_registry_write_service_role"
  on "public"."community_specialty_registry"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "compliance_overlays_read_all"
  on "public"."compliance_overlays"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "compliance_overlays_write_service_role"
  on "public"."compliance_overlays"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "construction_safety_incidents_read_all"
  on "public"."construction_safety_incidents"
  as permissive
  for select
  to authenticated
using (true);



  create policy "construction_safety_incidents_write_service_role"
  on "public"."construction_safety_incidents"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Only vendors/institutions can join conversations"
  on "public"."conversation_participants"
  as permissive
  for insert
  to public
with check (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text])))))));



  create policy "User can see own conversation participations"
  on "public"."conversation_participants"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "Vendor/institution sees their own conversation participations"
  on "public"."conversation_participants"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text])))))));



  create policy "Conversation visible only to vendor/institution participants"
  on "public"."conversations"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text]))))) AND (EXISTS ( SELECT 1
   FROM public.conversation_participants cp
  WHERE ((cp.conversation_id = conversations.id) AND (cp.user_id = auth.uid()))))));



  create policy "Conversation visible to participants only"
  on "public"."conversations"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.conversation_participants cp
  WHERE ((cp.conversation_id = conversations.id) AND (cp.user_id = auth.uid())))));



  create policy "Only vendors/institutions can create conversations"
  on "public"."conversations"
  as permissive
  for insert
  to public
with check (((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text]))))) AND (created_by = auth.uid())));



  create policy "donations_read_all"
  on "public"."donations"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "donations_write_service_role"
  on "public"."donations"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Education field trips owners can delete"
  on "public"."education_field_trips"
  as permissive
  for delete
  to public
using ((auth.uid() = created_by));



  create policy "Education field trips owners can insert"
  on "public"."education_field_trips"
  as permissive
  for insert
  to public
with check ((auth.uid() = created_by));



  create policy "Education field trips owners can update"
  on "public"."education_field_trips"
  as permissive
  for update
  to public
using ((auth.uid() = created_by))
with check ((auth.uid() = created_by));



  create policy "Education field trips readable to all"
  on "public"."education_field_trips"
  as permissive
  for select
  to public
using (true);



  create policy "Admin read all event analytics"
  on "public"."event_analytics_daily"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "Read own event analytics"
  on "public"."event_analytics_daily"
  as permissive
  for select
  to public
using ((vendor_user_id = auth.uid()));



  create policy "Public read event badges"
  on "public"."event_badges"
  as permissive
  for select
  to public
using (true);



  create policy "event_context_profiles_read_all"
  on "public"."event_context_profiles"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "event_context_profiles_write_service_role"
  on "public"."event_context_profiles"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "event_reg_insert_v1"
  on "public"."event_registrations"
  as permissive
  for insert
  to authenticated
with check (((user_id = auth.uid()) AND (role = ANY (ARRAY['volunteer'::text, 'attendee'::text])) AND ((COALESCE(kids_mode, false) = false) OR (COALESCE(parental_approval, false) = true)) AND (EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_registrations.event_id) AND (e.status = 'published'::text) AND (e.moderation_status = 'approved'::text))))));



  create policy "event_registrations_admin_all_access"
  on "public"."event_registrations"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))))
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))));



  create policy "host can approve registrations"
  on "public"."event_registrations"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_registrations.event_id) AND (e.created_by = auth.uid())))));



  create policy "hosts can view registrations for their events"
  on "public"."event_registrations"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM (public.events e
     JOIN public.user_tiers ut ON ((ut.user_id = auth.uid())))
  WHERE ((e.id = event_registrations.event_id) AND (e.created_by = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text, 'admin'::text])) AND (ut.account_status = 'active'::text)))));



  create policy "users can view their registrations"
  on "public"."event_registrations"
  as permissive
  for select
  to authenticated
using ((user_id = auth.uid()));



  create policy "Admin manage event_specialties"
  on "public"."event_specialties"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "Public read event_specialties"
  on "public"."event_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "Admin manage event_specialty_links"
  on "public"."event_specialty_links"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "Public read event_specialty_links"
  on "public"."event_specialty_links"
  as permissive
  for select
  to public
using (true);



  create policy "events_admin_all_access"
  on "public"."events"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))))
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))));



  create policy "events_delete_owner_v1"
  on "public"."events"
  as permissive
  for delete
  to authenticated
using ((created_by = auth.uid()));



  create policy "events_host_insert_v4"
  on "public"."events"
  as permissive
  for insert
  to authenticated
with check (((created_by = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.account_status = 'active'::text) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text]))))) AND ((EXISTS ( SELECT 1
   FROM public.user_tiers ut2
  WHERE ((ut2.user_id = auth.uid()) AND (ut2.role = 'institution'::text) AND (ut2.account_status = 'active'::text)))) OR (EXISTS ( SELECT 1
   FROM ((public.providers p
     JOIN public.provider_badges pb ON ((pb.provider_id = p.id)))
     JOIN public.badges b ON ((b.id = pb.badge_id)))
  WHERE ((p.id = events.host_vendor_id) AND (p.owner_user_id = auth.uid()) AND (b.code = ANY (ARRAY['verified'::text, 'VERIFIED_VENDOR'::text])))))) AND ((NOT (EXISTS ( SELECT 1
   FROM public.providers p2
  WHERE ((p2.id = events.host_vendor_id) AND ((p2.specialty = 'sanctuary'::text) OR (EXISTS ( SELECT 1
           FROM (public.provider_badges pb2
             JOIN public.badges b2 ON ((b2.id = pb2.badge_id)))
          WHERE ((pb2.provider_id = p2.id) AND (b2.code = ANY (ARRAY['SANCTUARY_VENDOR'::text, 'NONPROFIT_VENDOR'::text])))))))))) OR (event_type = 'volunteer'::text)) AND ((COALESCE(is_large_scale_volunteer, false) = false) OR ((is_large_scale_volunteer = true) AND (COALESCE(requires_institutional_partner, false) = true) AND (host_institution_id IS NOT NULL) AND (event_type = 'volunteer'::text)))));



  create policy "events_host_vendor_delete_v6"
  on "public"."events"
  as permissive
  for delete
  to authenticated
using (((created_by = auth.uid()) AND (host_vendor_id IS NOT NULL) AND public._provider_owned(host_vendor_id) AND public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_events'::text)));



  create policy "events_host_vendor_delete_v7"
  on "public"."events"
  as permissive
  for delete
  to authenticated
using (((created_by = auth.uid()) AND (host_vendor_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = events.host_vendor_id) AND (p.owner_user_id = auth.uid()) AND (NULLIF(btrim(p.specialty), ''::text) IS NOT NULL))))));



  create policy "events_host_vendor_insert_v6"
  on "public"."events"
  as permissive
  for insert
  to authenticated
with check (((created_by = auth.uid()) AND (host_vendor_id IS NOT NULL) AND public._provider_owned(host_vendor_id) AND (event_vertical = public._provider_effective_vertical(host_vendor_id)) AND public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_events'::text) AND ((COALESCE(is_volunteer, false) = false) OR public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_volunteer_events'::text)) AND ((public._specialty_is_sanctuary(public._provider_specialty_code(host_vendor_id)) = false) OR (COALESCE(is_volunteer, false) = true)) AND (((public._provider_is_verified(host_vendor_id) = false) AND (COALESCE(status, ''::text) = 'draft'::text)) OR ((public._provider_is_verified(host_vendor_id) = true) AND ((COALESCE(status, ''::text) <> 'published'::text) OR ((COALESCE(status, ''::text) = 'published'::text) AND (COALESCE(moderation_status, ''::text) = 'approved'::text))))) AND ((COALESCE(is_large_scale_volunteer, false) = false) OR public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_large_scale_volunteer'::text))));



  create policy "events_host_vendor_insert_v7"
  on "public"."events"
  as permissive
  for insert
  to authenticated
with check (((created_by = auth.uid()) AND (host_vendor_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = events.host_vendor_id) AND (p.owner_user_id = auth.uid()) AND (events.event_vertical = COALESCE(p.primary_vertical, p.vertical)) AND (NULLIF(btrim(p.specialty), ''::text) IS NOT NULL) AND ((NOT public._is_sanctuary_specialty(p.specialty)) OR (COALESCE(events.is_volunteer, false) = true)) AND (((COALESCE(events.is_volunteer, false) = true) AND public._specialty_capability_allowed(p.specialty, 'EVENT_VOLUNTEER'::text)) OR ((COALESCE(events.is_volunteer, false) = false) AND public._specialty_capability_allowed(p.specialty, 'EVENT_NON_VOLUNTEER'::text)))))) AND ((COALESCE(status, ''::text) <> 'published'::text) OR ((COALESCE(status, ''::text) = 'published'::text) AND (COALESCE(moderation_status, ''::text) = 'approved'::text)))));



  create policy "events_host_vendor_update_v6"
  on "public"."events"
  as permissive
  for update
  to authenticated
using (((created_by = auth.uid()) AND (host_vendor_id IS NOT NULL) AND public._provider_owned(host_vendor_id)))
with check (((created_by = auth.uid()) AND (host_vendor_id IS NOT NULL) AND public._provider_owned(host_vendor_id) AND (event_vertical = public._provider_effective_vertical(host_vendor_id)) AND public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_events'::text) AND ((COALESCE(is_volunteer, false) = false) OR public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_volunteer_events'::text)) AND ((public._specialty_is_sanctuary(public._provider_specialty_code(host_vendor_id)) = false) OR (COALESCE(is_volunteer, false) = true)) AND (((public._provider_is_verified(host_vendor_id) = false) AND (COALESCE(status, ''::text) = 'draft'::text)) OR ((public._provider_is_verified(host_vendor_id) = true) AND ((COALESCE(status, ''::text) <> 'published'::text) OR ((COALESCE(status, ''::text) = 'published'::text) AND (COALESCE(moderation_status, ''::text) = 'approved'::text))))) AND ((COALESCE(is_large_scale_volunteer, false) = false) OR public._specialty_has_capability(public._provider_specialty_code(host_vendor_id), 'can_host_large_scale_volunteer'::text))));



  create policy "events_host_vendor_update_v7"
  on "public"."events"
  as permissive
  for update
  to authenticated
using (((created_by = auth.uid()) AND (host_vendor_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = events.host_vendor_id) AND (p.owner_user_id = auth.uid()))))))
with check (((created_by = auth.uid()) AND (host_vendor_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = events.host_vendor_id) AND (p.owner_user_id = auth.uid()) AND (events.event_vertical = COALESCE(p.primary_vertical, p.vertical)) AND (NULLIF(btrim(p.specialty), ''::text) IS NOT NULL) AND ((NOT public._is_sanctuary_specialty(p.specialty)) OR (COALESCE(events.is_volunteer, false) = true)) AND (((COALESCE(events.is_volunteer, false) = true) AND public._specialty_capability_allowed(p.specialty, 'EVENT_VOLUNTEER'::text)) OR ((COALESCE(events.is_volunteer, false) = false) AND public._specialty_capability_allowed(p.specialty, 'EVENT_NON_VOLUNTEER'::text)))))) AND ((COALESCE(status, ''::text) <> 'published'::text) OR ((COALESCE(status, ''::text) = 'published'::text) AND (COALESCE(moderation_status, ''::text) = 'approved'::text)))));



  create policy "events_public_read_published_approved_v1"
  on "public"."events"
  as permissive
  for select
  to public
using (((status = 'published'::text) AND (moderation_status = 'approved'::text)));



  create policy "events_read_published_approved_v1"
  on "public"."events"
  as permissive
  for select
  to anon, authenticated
using (((status = 'published'::text) AND (moderation_status = 'approved'::text)));



  create policy "events_service_role_manage_v1"
  on "public"."events"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "events_update_owner_v1"
  on "public"."events"
  as permissive
  for update
  to authenticated
using ((created_by = auth.uid()))
with check ((created_by = auth.uid()));



  create policy "sanctuary_vendors_update_volunteer_only"
  on "public"."events"
  as permissive
  for update
  to authenticated
using (true)
with check (((NOT (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = events.host_vendor_id) AND ((p.specialty = 'sanctuary'::text) OR (EXISTS ( SELECT 1
           FROM (public.provider_badges pb
             JOIN public.badges b ON ((b.id = pb.badge_id)))
          WHERE ((pb.provider_id = p.id) AND (b.code = ANY (ARRAY['SANCTUARY_VENDOR'::text, 'NONPROFIT_VENDOR'::text])))))))))) OR (event_type = 'volunteer'::text)));



  create policy "experience_context_profiles_read_all"
  on "public"."experience_context_profiles"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "experience_context_profiles_write_service_role"
  on "public"."experience_context_profiles"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Institutions create their own requests"
  on "public"."experience_requests"
  as permissive
  for insert
  to authenticated
with check (((institution_user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'institution'::text) AND (ut.account_status = 'active'::text))))));



  create policy "Providers see requests for their experiences"
  on "public"."experience_requests"
  as permissive
  for select
  to authenticated
using (((EXISTS ( SELECT 1
   FROM (public.experiences e
     JOIN public.providers p ON ((p.id = e.provider_id)))
  WHERE ((e.id = experience_requests.experience_id) AND (p.owner_user_id = auth.uid())))) OR public.is_admin()));



  create policy "Providers/admin update experience_requests"
  on "public"."experience_requests"
  as permissive
  for update
  to authenticated
using (((EXISTS ( SELECT 1
   FROM (public.experiences e
     JOIN public.providers p ON ((p.id = e.provider_id)))
  WHERE ((e.id = experience_requests.experience_id) AND (p.owner_user_id = auth.uid())))) OR public.is_admin()))
with check (((EXISTS ( SELECT 1
   FROM (public.experiences e
     JOIN public.providers p ON ((p.id = e.provider_id)))
  WHERE ((e.id = experience_requests.experience_id) AND (p.owner_user_id = auth.uid())))) OR public.is_admin()));



  create policy "Providers manage own experiences"
  on "public"."experiences"
  as permissive
  for all
  to authenticated
using (((EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = experiences.provider_id) AND (p.owner_user_id = auth.uid())))) OR public.is_admin()))
with check (((EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = experiences.provider_id) AND (p.owner_user_id = auth.uid())))) OR public.is_admin()));



  create policy "Public read published experiences"
  on "public"."experiences"
  as permissive
  for select
  to anon, authenticated
using ((status = 'published'::text));



  create policy "experiences_non_kids_read_v1"
  on "public"."experiences"
  as permissive
  for select
  to public
using ((NOT public.is_kids_account()));



  create policy "feed_comments_admin_read_only"
  on "public"."feed_comments"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))));



  create policy "Feed is visible to authenticated users"
  on "public"."feed_items"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "feed_items_admin_all_access"
  on "public"."feed_items"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))))
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))));



  create policy "feed_items_delete_own_only"
  on "public"."feed_items"
  as permissive
  for delete
  to authenticated
using ((author_id = auth.uid()));



  create policy "feed_items_insert_own_only"
  on "public"."feed_items"
  as permissive
  for insert
  to authenticated
with check ((author_id = auth.uid()));



  create policy "feed_items_update_own_only"
  on "public"."feed_items"
  as permissive
  for update
  to authenticated
using ((author_id = auth.uid()))
with check ((author_id = auth.uid()));



  create policy "feed_likes_admin_all_access"
  on "public"."feed_likes"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))))
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))));



  create policy "feed_likes_delete_own_only"
  on "public"."feed_likes"
  as permissive
  for delete
  to authenticated
using ((user_id = auth.uid()));



  create policy "feed_likes_insert_own_only"
  on "public"."feed_likes"
  as permissive
  for insert
  to authenticated
with check ((user_id = auth.uid()));



  create policy "feed_likes_select_authenticated"
  on "public"."feed_likes"
  as permissive
  for select
  to authenticated
using (true);



  create policy "institution_apps_admin_all"
  on "public"."institution_applications"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "institution_apps_user_insert_own"
  on "public"."institution_applications"
  as permissive
  for insert
  to authenticated
with check ((user_id = auth.uid()));



  create policy "institution_apps_user_select_own"
  on "public"."institution_applications"
  as permissive
  for select
  to authenticated
using (((user_id = auth.uid()) OR public.is_admin()));



  create policy "Admin manage institution_specialties"
  on "public"."institution_specialties"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "Public read institution_specialties"
  on "public"."institution_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "kids_mode_overlays_read_all"
  on "public"."kids_mode_overlays"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "kids_mode_overlays_write_service_role"
  on "public"."kids_mode_overlays"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Public read landmark badges"
  on "public"."landmark_badges"
  as permissive
  for select
  to public
using (true);



  create policy "Admin manage landmark_specialties"
  on "public"."landmark_specialties"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "Public read landmark_specialties"
  on "public"."landmark_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "Admin manage landmark_specialty_links"
  on "public"."landmark_specialty_links"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "Public read landmark_specialty_links"
  on "public"."landmark_specialty_links"
  as permissive
  for select
  to public
using (true);



  create policy "admin_controls_kids_safe_and_publish"
  on "public"."landmarks"
  as permissive
  for update
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "anyone can view published landmarks"
  on "public"."landmarks"
  as permissive
  for select
  to public
using ((is_published = true));



  create policy "landmarks_read_all_v1"
  on "public"."landmarks"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "landmarks_service_role_manage_v1"
  on "public"."landmarks"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "owners or admins can delete landmarks"
  on "public"."landmarks"
  as permissive
  for delete
  to authenticated
using (((created_by = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text))))));



  create policy "owners or admins can update landmarks"
  on "public"."landmarks"
  as permissive
  for update
  to authenticated
using (((created_by = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text))))));



  create policy "users_can_submit_landmarks"
  on "public"."landmarks"
  as permissive
  for insert
  to public
with check (((created_by = auth.uid()) AND (is_kid_safe = false) AND (moderation_status = 'pending'::text) AND (is_published = false)));



  create policy "users_can_update_own_landmarks"
  on "public"."landmarks"
  as permissive
  for update
  to public
using ((created_by = auth.uid()))
with check (((created_by = auth.uid()) AND (is_kid_safe = false) AND (moderation_status = 'pending'::text)));



  create policy "vendors institutions admins can create landmarks"
  on "public"."landmarks"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text, 'admin'::text])) AND (ut.account_status = 'active'::text)))));



  create policy "Location check-ins readable by all"
  on "public"."location_checkins"
  as permissive
  for select
  to public
using (true);



  create policy "Vendors and institutions can create check-ins"
  on "public"."location_checkins"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text]))))));



  create policy "Vendors and institutions can delete own check-ins"
  on "public"."location_checkins"
  as permissive
  for delete
  to public
using (((auth.uid() = created_by) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text])))))));



  create policy "Vendors and institutions can update own check-ins"
  on "public"."location_checkins"
  as permissive
  for update
  to public
using (((auth.uid() = created_by) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text])))))))
with check (((auth.uid() = created_by) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text])))))));



  create policy "market_session_locks_self_v1"
  on "public"."market_session_locks"
  as permissive
  for all
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "Messages visible only to vendor/institution participants"
  on "public"."messages"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text]))))) AND (EXISTS ( SELECT 1
   FROM public.conversation_participants cp
  WHERE ((cp.conversation_id = messages.conversation_id) AND (cp.user_id = auth.uid()))))));



  create policy "Messages visible to conversation participants only"
  on "public"."messages"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.conversation_participants cp
  WHERE ((cp.conversation_id = messages.conversation_id) AND (cp.user_id = auth.uid())))));



  create policy "Only participants can send messages"
  on "public"."messages"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.conversation_participants cp
  WHERE ((cp.conversation_id = messages.conversation_id) AND (cp.user_id = auth.uid())))));



  create policy "Only vendor/institution participants can send messages"
  on "public"."messages"
  as permissive
  for insert
  to public
with check (((sender_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text])))))));



  create policy "Only admins can read moderation queue"
  on "public"."moderation_queue"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "Only admins can update moderation queue"
  on "public"."moderation_queue"
  as permissive
  for update
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "System can insert moderation items"
  on "public"."moderation_queue"
  as permissive
  for insert
  to public
with check ((auth.uid() IS NOT NULL));



  create policy "admin_can_read_all_moderation_queue"
  on "public"."moderation_queue"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "Only admins can update delivery state"
  on "public"."notifications"
  as permissive
  for update
  to public
using (public.is_admin());



  create policy "System can insert notifications"
  on "public"."notifications"
  as permissive
  for insert
  to public
with check ((auth.uid() IS NOT NULL));



  create policy "Users can read own notifications"
  on "public"."notifications"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) OR public.is_admin()));



  create policy "admin_can_read_all_notifications"
  on "public"."notifications"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "Enable read access for all users"
  on "public"."provider_badges"
  as permissive
  for select
  to public
using (true);



  create policy "Public read provider badges"
  on "public"."provider_badges"
  as permissive
  for select
  to public
using (true);



  create policy "admin_can_read_all_provider_badges"
  on "public"."provider_badges"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "provider_badges_admin_all_access"
  on "public"."provider_badges"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "provider_badges_admin_insert_only"
  on "public"."provider_badges"
  as permissive
  for insert
  to authenticated
with check (public.is_admin());



  create policy "provider_compliance_overlays_read_all"
  on "public"."provider_compliance_overlays"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "provider_compliance_overlays_write_service_role"
  on "public"."provider_compliance_overlays"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "provider_ctx_owner_update"
  on "public"."provider_context_profiles"
  as permissive
  for all
  to public
using ((public.is_admin() OR (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = provider_context_profiles.provider_id) AND (p.owner_user_id = auth.uid()))))))
with check ((public.is_admin() OR (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = provider_context_profiles.provider_id) AND (p.owner_user_id = auth.uid()))))));



  create policy "provider_employees_owner_admin_modify"
  on "public"."provider_employees"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = auth.uid())))
  WHERE ((p.id = provider_employees.provider_id) AND ((p.owner_user_id = auth.uid()) OR (ut.role = 'admin'::text))))))
with check ((EXISTS ( SELECT 1
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = auth.uid())))
  WHERE ((p.id = provider_employees.provider_id) AND ((p.owner_user_id = auth.uid()) OR (ut.role = 'admin'::text))))));



  create policy "provider_employees_owner_admin_select"
  on "public"."provider_employees"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = auth.uid())))
  WHERE ((p.id = provider_employees.provider_id) AND ((p.owner_user_id = auth.uid()) OR (ut.role = 'admin'::text))))));



  create policy "admin_can_all_provider_impacts"
  on "public"."provider_impact_snapshots"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "admin_full_read_provider_impact"
  on "public"."provider_impact_snapshots"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))));



  create policy "system_can_insert_provider_impact"
  on "public"."provider_impact_snapshots"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admin manage provider_institution_specialties"
  on "public"."provider_institution_specialties"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "Public read provider_institution_specialties"
  on "public"."provider_institution_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "provider_kids_mode_overlays_read_all"
  on "public"."provider_kids_mode_overlays"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "provider_kids_mode_overlays_write_service_role"
  on "public"."provider_kids_mode_overlays"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Anyone can view media for active providers"
  on "public"."provider_media"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = provider_media.provider_id) AND (p.is_active = true)))));



  create policy "Enable insert for authenticated users only"
  on "public"."provider_media"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "Enable read access for all users"
  on "public"."provider_media"
  as permissive
  for select
  to public
using (true);



  create policy "Only active vendors can insert media"
  on "public"."provider_media"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.account_status = 'active'::text)))));



  create policy "Only active vendors can insert provider media"
  on "public"."provider_media"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = p.owner_user_id)))
  WHERE ((p.id = provider_media.provider_id) AND (ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.account_status = 'active'::text)))));



  create policy "Vendors delete their own media"
  on "public"."provider_media"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = p.owner_user_id)))
  WHERE ((p.id = provider_media.provider_id) AND (ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.account_status = 'active'::text)))));



  create policy "Vendors manage their own media"
  on "public"."provider_media"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = p.owner_user_id)))
  WHERE ((p.id = provider_media.provider_id) AND (ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.account_status = 'active'::text)))));



  create policy "active vendors can insert provider media"
  on "public"."provider_media"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = p.owner_user_id)))
  WHERE ((p.id = provider_media.provider_id) AND (p.owner_user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.account_status = 'active'::text)))));



  create policy "public can view provider media"
  on "public"."provider_media"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = provider_media.provider_id) AND (p.is_active = true)))));



  create policy "vendors can delete their own provider media"
  on "public"."provider_media"
  as permissive
  for delete
  to authenticated
using ((provider_id IN ( SELECT providers.id
   FROM public.providers
  WHERE (providers.owner_user_id = auth.uid()))));



  create policy "vendors can update their own provider media"
  on "public"."provider_media"
  as permissive
  for update
  to authenticated
using ((provider_id IN ( SELECT providers.id
   FROM public.providers
  WHERE (providers.owner_user_id = auth.uid()))));



  create policy "provider_memberships_select_self"
  on "public"."provider_memberships"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) OR public.is_rooted_admin()));



  create policy "provider_specialties_read_all"
  on "public"."provider_specialties"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "provider_specialties_write_service_role"
  on "public"."provider_specialties"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Admin manage provider_vendor_specialties"
  on "public"."provider_vendor_specialties"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "Public read provider_vendor_specialties"
  on "public"."provider_vendor_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "Admin can read all billing data"
  on "public"."providers"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "Enable insert for authenticated users only"
  on "public"."providers"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "Enable read access for all users"
  on "public"."providers"
  as permissive
  for select
  to public
using (true);



  create policy "Provider owner can read own billing status"
  on "public"."providers"
  as permissive
  for select
  to public
using ((owner_user_id = auth.uid()));



  create policy "Provider owner can update own provider"
  on "public"."providers"
  as permissive
  for update
  to public
using ((owner_user_id = auth.uid()))
with check ((owner_user_id = auth.uid()));



  create policy "Provider owner can view own provider"
  on "public"."providers"
  as permissive
  for select
  to public
using ((owner_user_id = auth.uid()));



  create policy "Public can view active, discoverable providers"
  on "public"."providers"
  as permissive
  for select
  to public
using (((is_discoverable = true) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = providers.owner_user_id) AND (ut.account_status = 'active'::text))))));



  create policy "Public can view discoverable providers"
  on "public"."providers"
  as permissive
  for select
  to public
using ((is_discoverable = true));



  create policy "providers_owner_manage_v1"
  on "public"."providers"
  as permissive
  for all
  to authenticated
using ((owner_user_id = auth.uid()))
with check ((owner_user_id = auth.uid()));



  create policy "providers_read_all_v1"
  on "public"."providers"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "providers_service_role_manage_v1"
  on "public"."providers"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Authenticated users can view open RFQs"
  on "public"."rfqs"
  as permissive
  for select
  to public
using (((status = 'open'::text) AND (auth.role() = 'authenticated'::text)));



  create policy "Institution can manage own RFQs"
  on "public"."rfqs"
  as permissive
  for all
  to public
using ((institution_id = auth.uid()))
with check ((institution_id = auth.uid()));



  create policy "bulk-capable users can see rfqs"
  on "public"."rfqs"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text, 'admin'::text])) AND (((ut.feature_flags ->> 'can_use_bulk_marketplace'::text))::boolean = true)))));



  create policy "institutions manage own rfqs"
  on "public"."rfqs"
  as permissive
  for all
  to public
using (((institution_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'institution'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])))))))
with check (((institution_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'institution'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])))))));



  create policy "institutions with bulk access can create rfqs"
  on "public"."rfqs"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'institution'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])) AND (((ut.feature_flags ->> 'can_use_bulk_marketplace'::text))::boolean = true)))));



  create policy "rfqs_admin_all_access"
  on "public"."rfqs"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))))
with check ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text)))));



  create policy "rfqs_insert_institution_or_admin_only"
  on "public"."rfqs"
  as permissive
  for insert
  to authenticated
with check (((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['institution'::text, 'admin'::text]))))) AND (EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = rfqs.institution_id) AND (p.owner_user_id = auth.uid()))))));



  create policy "rfqs_institution_crud_own"
  on "public"."rfqs"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = rfqs.institution_id) AND (p.owner_user_id = auth.uid())))))
with check ((EXISTS ( SELECT 1
   FROM public.providers p
  WHERE ((p.id = rfqs.institution_id) AND (p.owner_user_id = auth.uid())))));



  create policy "vendors read open rfqs"
  on "public"."rfqs"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text)))) AND (status = 'open'::text)));



  create policy "seasonal_content_analytics_daily_read_all"
  on "public"."seasonal_content_analytics_daily"
  as permissive
  for select
  to service_role
using (true);



  create policy "seasonal_content_analytics_daily_write_service_role"
  on "public"."seasonal_content_analytics_daily"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "seasonal_crafts_read_all"
  on "public"."seasonal_crafts"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "seasonal_crafts_write_service_role"
  on "public"."seasonal_crafts"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "seasonal_produce_read_all"
  on "public"."seasonal_produce"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "seasonal_produce_write_service_role"
  on "public"."seasonal_produce"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "seasonal_recipes_read_all"
  on "public"."seasonal_recipes"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "seasonal_recipes_write_service_role"
  on "public"."seasonal_recipes"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "seasonal_seeds_read_all"
  on "public"."seasonal_seeds"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "seasonal_seeds_write_service_role"
  on "public"."seasonal_seeds"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "specialty_compliance_overlays_read_all"
  on "public"."specialty_compliance_overlays"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "specialty_compliance_overlays_write_service_role"
  on "public"."specialty_compliance_overlays"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "specialty_kids_mode_overlays_read_all"
  on "public"."specialty_kids_mode_overlays"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "specialty_kids_mode_overlays_write_service_role"
  on "public"."specialty_kids_mode_overlays"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Read specialty_types"
  on "public"."specialty_types"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "Service role manage specialty_types"
  on "public"."specialty_types"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "specialty_types_read_all"
  on "public"."specialty_types"
  as permissive
  for select
  to public
using (true);



  create policy "specialty_types_select_all"
  on "public"."specialty_types"
  as permissive
  for select
  to public
using (true);



  create policy "specialty_types_service_write"
  on "public"."specialty_types"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "Read specialty_vertical_overlays"
  on "public"."specialty_vertical_overlays"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "Service role manage specialty_vertical_overlays"
  on "public"."specialty_vertical_overlays"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "overlay_specialties_read_all"
  on "public"."specialty_vertical_overlays"
  as permissive
  for select
  to public
using (true);



  create policy "specialty_vertical_overlays_read"
  on "public"."specialty_vertical_overlays"
  as permissive
  for select
  to public
using (true);



  create policy "specialty_vertical_overlays_select_all"
  on "public"."specialty_vertical_overlays"
  as permissive
  for select
  to public
using (true);



  create policy "specialty_vertical_overlays_service_write"
  on "public"."specialty_vertical_overlays"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "specialty_vertical_overlays_write"
  on "public"."specialty_vertical_overlays"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "svo_admin_write"
  on "public"."specialty_vertical_overlays"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "svo_read"
  on "public"."specialty_vertical_overlays"
  as permissive
  for select
  to public
using (true);



  create policy "Only admins can insert admin actions"
  on "public"."user_admin_actions"
  as permissive
  for insert
  to public
with check (public.is_admin());



  create policy "Only admins can read admin actions"
  on "public"."user_admin_actions"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "admin_can_read_all_user_admin_actions"
  on "public"."user_admin_actions"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "Users manage their own consents"
  on "public"."user_consents"
  as permissive
  for all
  to public
using (((user_id = auth.uid()) OR public.is_admin()))
with check (((user_id = auth.uid()) OR public.is_admin()));



  create policy "Users manage their own devices"
  on "public"."user_devices"
  as permissive
  for all
  to public
using (((user_id = auth.uid()) OR public.is_admin()))
with check (((user_id = auth.uid()) OR public.is_admin()));



  create policy "Users can see their own active tier"
  on "public"."user_tiers"
  as permissive
  for select
  to public
using (((auth.uid() = user_id) AND (account_status = 'active'::text)));



  create policy "admin full control user_tiers"
  on "public"."user_tiers"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "user can read own tier"
  on "public"."user_tiers"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) OR public.is_admin()));



  create policy "user can update own tier flags"
  on "public"."user_tiers"
  as permissive
  for update
  to public
using (((user_id = auth.uid()) OR public.is_admin()))
with check (((user_id = auth.uid()) OR public.is_admin()));



  create policy "user_tiers: system can insert"
  on "public"."user_tiers"
  as permissive
  for insert
  to public
with check (true);



  create policy "user_tiers: user can read own row"
  on "public"."user_tiers"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "user_tiers: user can update own row"
  on "public"."user_tiers"
  as permissive
  for update
  to public
using ((user_id = auth.uid()))
with check ((user_id = auth.uid()));



  create policy "user_tiers_select_own_v1"
  on "public"."user_tiers"
  as permissive
  for select
  to authenticated
using ((user_id = auth.uid()));



  create policy "user_tiers_self_select_v1"
  on "public"."user_tiers"
  as permissive
  for select
  to authenticated
using ((user_id = auth.uid()));



  create policy "admin_can_read_all_vendor_analytics_advanced_daily"
  on "public"."vendor_analytics_advanced_daily"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "admin_can_view_all_advanced_analytics"
  on "public"."vendor_analytics_advanced_daily"
  as permissive
  for select
  to authenticated
using (public.is_admin());



  create policy "premium_plus_only_advanced_analytics"
  on "public"."vendor_analytics_advanced_daily"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text])) AND (ut.tier = 'premium_plus'::text)))));



  create policy "premium_plus_vendor_can_view_own_advanced_analytics"
  on "public"."vendor_analytics_advanced_daily"
  as permissive
  for select
  to authenticated
using (((owner_user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.account_status = 'active'::text) AND (ut.tier = 'premium_plus'::text) AND (((ut.feature_flags ->> 'can_view_advanced_analytics'::text))::boolean = true))))));



  create policy "vendors_premium_plus_read_advanced_analytics"
  on "public"."vendor_analytics_advanced_daily"
  as permissive
  for select
  to authenticated
using (((vendor_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = 'premium_plus'::text))))));



  create policy "admin_can_read_all_vendor_analytics_basic_daily"
  on "public"."vendor_analytics_basic_daily"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "admin_can_view_all_basic_analytics"
  on "public"."vendor_analytics_basic_daily"
  as permissive
  for select
  to authenticated
using (public.is_admin());



  create policy "premium_vendors_can_view_basic_analytics"
  on "public"."vendor_analytics_basic_daily"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text]))))));



  create policy "vendor_can_view_own_basic_analytics"
  on "public"."vendor_analytics_basic_daily"
  as permissive
  for select
  to authenticated
using (((owner_user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.account_status = 'active'::text) AND (((ut.feature_flags ->> 'can_view_basic_analytics'::text))::boolean = true))))));



  create policy "vendors_premium_read_basic_analytics"
  on "public"."vendor_analytics_basic_daily"
  as permissive
  for select
  to authenticated
using (((vendor_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])))))));



  create policy "admin can read all vendor analytics"
  on "public"."vendor_analytics_daily"
  as permissive
  for select
  to authenticated
using (public.is_admin());



  create policy "admin_can_read_all_vendor_analytics_daily"
  on "public"."vendor_analytics_daily"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "premium_plus vendors read own analytics"
  on "public"."vendor_analytics_daily"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM (public.providers p
     JOIN public.user_tiers ut ON ((ut.user_id = p.owner_user_id)))
  WHERE ((p.id = vendor_analytics_daily.vendor_id) AND (ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = 'premium_plus'::text) AND (ut.account_status = 'active'::text) AND ((ut.feature_flags ->> 'can_view_advanced_analytics'::text) = 'true'::text)))));



  create policy "system can write vendor analytics"
  on "public"."vendor_analytics_daily"
  as permissive
  for insert
  to public
with check ((auth.uid() IS NULL));



  create policy "vendors_premium_read_daily_analytics"
  on "public"."vendor_analytics_daily"
  as permissive
  for select
  to authenticated
using (((vendor_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.tier = ANY (ARRAY['premium'::text, 'premium_plus'::text])))))));



  create policy "vendor_applications_admin_review"
  on "public"."vendor_applications"
  as permissive
  for update
  to public
using (public.is_rooted_admin())
with check (public.is_rooted_admin());



  create policy "vendor_applications_insert_self"
  on "public"."vendor_applications"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "vendor_applications_select_self"
  on "public"."vendor_applications"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) OR public.is_rooted_admin()));



  create policy "vendor_applications_update_self"
  on "public"."vendor_applications"
  as permissive
  for update
  to public
using (((user_id = auth.uid()) AND ((NOT (EXISTS ( SELECT 1
   FROM information_schema.columns
  WHERE (((columns.table_schema)::name = 'public'::name) AND ((columns.table_name)::name = 'vendor_applications'::name) AND ((columns.column_name)::name = 'status'::name))))) OR (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'needs_info'::text])))))
with check ((user_id = auth.uid()));



  create policy "vendor_apps_admin_all"
  on "public"."vendor_applications"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "vendor_apps_user_insert_own"
  on "public"."vendor_applications"
  as permissive
  for insert
  to authenticated
with check ((user_id = auth.uid()));



  create policy "vendor_apps_user_select_own"
  on "public"."vendor_applications"
  as permissive
  for select
  to authenticated
using (((user_id = auth.uid()) OR public.is_admin()));



  create policy "Owner or admin can delete vendor media"
  on "public"."vendor_media"
  as permissive
  for delete
  to authenticated
using (((owner_user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text))))));



  create policy "Owner or admin can update vendor media"
  on "public"."vendor_media"
  as permissive
  for update
  to authenticated
using (((owner_user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text))))))
with check (((owner_user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text))))));



  create policy "Owners can delete their own media"
  on "public"."vendor_media"
  as permissive
  for delete
  to authenticated
using ((owner_user_id = auth.uid()));



  create policy "Owners can update their own media"
  on "public"."vendor_media"
  as permissive
  for update
  to authenticated
using ((owner_user_id = auth.uid()))
with check ((owner_user_id = auth.uid()));



  create policy "Owners can view their own media"
  on "public"."vendor_media"
  as permissive
  for select
  to authenticated
using ((owner_user_id = auth.uid()));



  create policy "Public can view public vendor media"
  on "public"."vendor_media"
  as permissive
  for select
  to public
using ((visibility = 'public'::text));



  create policy "Read vendor media by visibility and ownership"
  on "public"."vendor_media"
  as permissive
  for select
  to authenticated
using (((visibility = 'public'::text) OR (owner_user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text))))));



  create policy "Vendors and admins can insert media"
  on "public"."vendor_media"
  as permissive
  for insert
  to authenticated
with check (((EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'vendor'::text) AND (ut.account_status = 'active'::text)))) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text))))));



  create policy "Admin manage vendor_specialties"
  on "public"."vendor_specialties"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "Public read vendor_specialties"
  on "public"."vendor_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "Read vertical_canonical_specialties"
  on "public"."vertical_canonical_specialties"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "Service role manage vertical_canonical_specialties"
  on "public"."vertical_canonical_specialties"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "vcs_admin_write"
  on "public"."vertical_canonical_specialties"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "vcs_read"
  on "public"."vertical_canonical_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "vertical_canonical_specialties_read"
  on "public"."vertical_canonical_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "vertical_canonical_specialties_select_all"
  on "public"."vertical_canonical_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "vertical_canonical_specialties_service_write"
  on "public"."vertical_canonical_specialties"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "vertical_canonical_specialties_write"
  on "public"."vertical_canonical_specialties"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "vertical_specialties_read_all"
  on "public"."vertical_canonical_specialties"
  as permissive
  for select
  to public
using (true);



  create policy "vertical_conditions_read"
  on "public"."vertical_conditions"
  as permissive
  for select
  to public
using (true);



  create policy "vertical_conditions_write"
  on "public"."vertical_conditions"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "weather_snapshots_read_all"
  on "public"."weather_snapshots"
  as permissive
  for select
  to service_role
using (true);



  create policy "weather_snapshots_write_service_role"
  on "public"."weather_snapshots"
  as permissive
  for all
  to service_role
using (true)
with check (true);


CREATE TRIGGER trg_arts_culture_events_set_updated_at BEFORE UPDATE ON public.arts_culture_events FOR EACH ROW EXECUTE FUNCTION public.set_arts_culture_events_updated_at();

CREATE TRIGGER trg_bulk_offers_set_vertical BEFORE INSERT ON public.bulk_offers FOR EACH ROW EXECUTE FUNCTION public.set_bulk_offer_vertical();

CREATE TRIGGER trg_community_nature_spots_set_updated_at BEFORE UPDATE ON public.community_nature_spots FOR EACH ROW EXECUTE FUNCTION public.set_community_nature_spots_updated_at();

CREATE TRIGGER trg_community_programs_set_updated_at BEFORE UPDATE ON public.community_programs FOR EACH ROW EXECUTE FUNCTION public.set_community_programs_updated_at();

CREATE TRIGGER trg_education_field_trips_set_updated_at BEFORE UPDATE ON public.education_field_trips FOR EACH ROW EXECUTE FUNCTION public.set_education_field_trips_updated_at();

CREATE TRIGGER trg_experiences_set_updated_at BEFORE UPDATE ON public.experiences FOR EACH ROW EXECUTE FUNCTION public.set_experiences_updated_at();

CREATE TRIGGER trg_prune_location_checkins AFTER INSERT ON public.location_checkins FOR EACH ROW EXECUTE FUNCTION public.prune_location_checkins();

CREATE TRIGGER founder_badge_limit BEFORE INSERT ON public.provider_badges FOR EACH ROW EXECUTE FUNCTION public.prevent_more_than_three_founders();

CREATE TRIGGER lock_max_3_founders BEFORE INSERT ON public.provider_badges FOR EACH ROW EXECUTE FUNCTION public.enforce_max_3_founders();

CREATE TRIGGER providers_set_vertical_and_normalize_trg BEFORE INSERT OR UPDATE ON public.providers FOR EACH ROW EXECUTE FUNCTION public.providers_set_vertical_and_normalize();

CREATE TRIGGER trg_assign_founding_agriculture_vendor BEFORE INSERT ON public.providers FOR EACH ROW EXECUTE FUNCTION public.assign_founding_agriculture_vendor_v1();

CREATE TRIGGER trg_providers_specialty_vertical_match BEFORE INSERT OR UPDATE ON public.providers FOR EACH ROW EXECUTE FUNCTION public.providers_enforce_specialty_vertical_match();

CREATE TRIGGER trg_providers_updated_at BEFORE UPDATE ON public.providers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_enforce_rfq_vertical BEFORE INSERT OR UPDATE ON public.rfqs FOR EACH ROW EXECUTE FUNCTION public.enforce_rfq_vertical();

CREATE TRIGGER trg_rfqs_set_vertical_from_provider BEFORE INSERT OR UPDATE ON public.rfqs FOR EACH ROW EXECUTE FUNCTION public.rfqs_set_vertical_from_provider();

CREATE TRIGGER trg_block_overlay_seed BEFORE INSERT OR DELETE OR UPDATE ON public.specialty_vertical_overlays FOR EACH STATEMENT EXECUTE FUNCTION public.block_mass_overlay_seed();

CREATE TRIGGER trg_vendor_applications_set_updated_at BEFORE UPDATE ON public.vendor_applications FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

CREATE TRIGGER trg_touch_vertical_market_requirements BEFORE UPDATE ON public.vertical_market_requirements FOR EACH ROW EXECUTE FUNCTION public._touch_vertical_market_requirements_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


  create policy "Authenticated can upload to rooted-public-media"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'rooted-public-media'::text));



  create policy "Owner or admin can delete private media"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'rooted-private-media'::text) AND ((owner = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))));



  create policy "Owner or admin can insert private media"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'rooted-private-media'::text) AND ((owner = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))));



  create policy "Owner or admin can read private media"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'rooted-private-media'::text) AND ((owner = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))));



  create policy "Owner or admin can update private media"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'rooted-private-media'::text) AND ((owner = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))))
with check (((bucket_id = 'rooted-private-media'::text) AND ((owner = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))));



  create policy "Public read for rooted-public-media"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'rooted-public-media'::text));



  create policy "owner_or_admin_delete_private_media"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'rooted-private-media'::text) AND ((split_part(name, '/'::text, 1) = (auth.uid())::text) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))));



  create policy "owner_or_admin_insert_private_media"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'rooted-private-media'::text) AND ((split_part(name, '/'::text, 1) = (auth.uid())::text) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))));



  create policy "owner_or_admin_read_private_media"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'rooted-private-media'::text) AND ((split_part(name, '/'::text, 1) = (auth.uid())::text) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))));



  create policy "owner_or_admin_update_private_media"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'rooted-private-media'::text) AND ((split_part(name, '/'::text, 1) = (auth.uid())::text) OR (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.role = 'admin'::text) AND (ut.account_status = 'active'::text)))))));



  create policy "owners_delete_own_public_media"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'rooted-public-media'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text)));



  create policy "owners_update_own_public_media"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'rooted-public-media'::text) AND (split_part(name, '/'::text, 1) = (auth.uid())::text)));



  create policy "public can read rooted-public-media"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'rooted-public-media'::text));



  create policy "vendors_and_admins_upload_public_media"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'rooted-public-media'::text) AND (EXISTS ( SELECT 1
   FROM public.user_tiers ut
  WHERE ((ut.user_id = auth.uid()) AND (ut.account_status = 'active'::text) AND (ut.role = ANY (ARRAY['vendor'::text, 'institution'::text, 'admin'::text])))))));




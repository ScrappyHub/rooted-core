-- ROOTED: PURGE-STRAY-DO-DELIMITERS-AND-SEMICOLONS-STEP-1R (canonical)
-- ROOTED: ENSURE-DO-CLOSE-DELIMITER-AFTER-END-STEP-1Q (canonical)
-- ROOTED: AUTO-FIX-DO-OPENERS-STEP-1J2C (canonical)
BEGIN;

-- ============================================================
-- Cleanup duplicate password-rotation gate policies
-- Keep: pwdrot_gate_v1
-- Drop: truncated legacy deny_write_if_password_rotation_* policies
-- Safe: does not error if policy missing
-- ============================================================

-- ROOTED: AUTO-FIX-DO-DOLLAR-QUOTE (canonical)
do $do$
BEGIN
  -- community_spot_submissions: drop legacy truncated gate if present
  BEGIN
    DROP POLICY community_spot_submissions_deny_write_if_password_rotation_requ
      ON public.community_spot_submissions;
  EXCEPTION WHEN undefined_object THEN
    NULL;
  END;

  -- conversation_participants: drop legacy truncated gate if present
  BEGIN
    DROP POLICY conversation_participants_deny_write_if_password_rotation_requi
      ON public.conversation_participants;
  EXCEPTION WHEN undefined_object THEN
    NULL;
  END;
END;
$do$;

COMMIT;
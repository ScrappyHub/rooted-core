import Stripe from "npm:stripe@17.4.0";
import { createClient } from "jsr:@supabase/supabase-js@2";

// ============================================================
// ROOTED — Canonical Stripe Webhook (Subscriptions Only)
// 1) Verify Stripe signature using RAW body
// 2) Normalize event into minimal fields
// 3) Resolve user_id via billing_customers(stripe_customer_id)
// 4) Ingest idempotently via public.service_stripe_ingest_event_v1(...)
// 5) NO direct writes to user_tiers / providers / donations
//
// Env:
// - STRIPE_SECRET_KEY (secret)
// - STRIPE_WEBHOOK_SIGNING_SECRET (secret)
// - SERVICE_ROLE_KEY (secret)
// - SUPABASE_URL is runtime-provided
// ============================================================

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const STRIPE_WEBHOOK_SIGNING_SECRET = Deno.env.get("STRIPE_WEBHOOK_SIGNING_SECRET") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";

if (!STRIPE_SECRET_KEY || !STRIPE_WEBHOOK_SIGNING_SECRET || !SERVICE_ROLE_KEY || !SUPABASE_URL) {
  console.error("Missing env vars for stripe-webhook.");
}

const stripe = new Stripe(STRIPE_SECRET_KEY, { apiVersion: "2024-06-20" });

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

function resp(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function safeJsonb(input: unknown): unknown {
  return JSON.parse(JSON.stringify(input));
}

type Normalized = {
  stripe_customer_id: string | null;
  stripe_subscription_id: string | null;
  stripe_price_id: string | null;
  subscription_status: string | null;
};

function normalizeStripeEvent(event: Stripe.Event): Normalized {
  let stripe_customer_id: string | null = null;
  let stripe_subscription_id: string | null = null;
  let stripe_price_id: string | null = null;
  let subscription_status: string | null = null;

  if (event.type.startsWith("customer.subscription.")) {
    const sub = event.data.object as Stripe.Subscription;

    stripe_subscription_id = sub.id ?? null;
    stripe_customer_id = typeof sub.customer === "string" ? sub.customer : sub.customer?.id ?? null;
    subscription_status = (sub.status as string) ?? null;

    const firstItem = sub.items?.data?.[0];
    stripe_price_id = firstItem?.price?.id ?? null;
  }

  if (event.type === "invoice.paid" || event.type === "invoice.payment_failed") {
    const inv = event.data.object as Stripe.Invoice;

    stripe_customer_id = stripe_customer_id ?? ((inv.customer as string) ?? null);

    const subId =
      typeof inv.subscription === "string"
        ? inv.subscription
        : (inv.subscription as Stripe.Subscription | null)?.id ?? null;
    stripe_subscription_id = stripe_subscription_id ?? subId;

    const line = inv.lines?.data?.[0] as any;
    const priceId =
      line?.price?.id ??
      line?.pricing?.price_details?.price ??
      line?.price_id ??
      null;
    stripe_price_id = stripe_price_id ?? (typeof priceId === "string" ? priceId : null);

    subscription_status = subscription_status ?? (event.type === "invoice.paid" ? "active" : "past_due");
  }

  return { stripe_customer_id, stripe_subscription_id, stripe_price_id, subscription_status };
}

export default async function handler(req: Request): Promise<Response> {
  if (req.method !== "POST") return resp(405, { error: "method not allowed" });

  const signature = req.headers.get("stripe-signature");
  if (!signature) return resp(400, { error: "missing stripe-signature" });

  let event: Stripe.Event;
  try {
    const rawBody = await req.text();
    event = await stripe.webhooks.constructEventAsync(rawBody, signature, STRIPE_WEBHOOK_SIGNING_SECRET);
  } catch (err) {
    console.error("[Stripe Webhook] Signature verification failed:", err);
    return resp(400, { error: "invalid signature" });
  }

  const allowed = new Set<string>([
    "customer.subscription.created",
    "customer.subscription.updated",
    "customer.subscription.deleted",
    "invoice.paid",
    "invoice.payment_failed",
  ]);

  if (!allowed.has(event.type)) {
    return resp(200, { ok: true, ignored: true, event_id: event.id, event_type: event.type });
  }

  const norm = normalizeStripeEvent(event);

  if (!norm.stripe_customer_id || !norm.stripe_price_id || !norm.subscription_status) {
    return resp(200, { ok: true, ignored: true, reason: "missing canonical fields", event_id: event.id, event_type: event.type, ...norm });
  }

  const { data: bc, error: bcErr } = await supabase
    .from("billing_customers")
    .select("user_id")
    .eq("stripe_customer_id", norm.stripe_customer_id)
    .maybeSingle();

  if (bcErr) {
    console.error("[Stripe Webhook] billing_customers lookup failed:", bcErr);
    return resp(500, { error: "billing_customers lookup failed", event_id: event.id });
  }

  if (!bc?.user_id) {
    return resp(200, { ok: true, ignored: true, reason: "unknown stripe_customer_id", event_id: event.id, stripe_customer_id: norm.stripe_customer_id });
  }

  const { error: rpcErr } = await supabase.rpc("service_stripe_ingest_event_v1", {
    p_event_id: event.id,
    p_event_type: event.type,
    p_stripe_customer_id: norm.stripe_customer_id,
    p_subscription_status: norm.subscription_status,
    p_stripe_price_id: norm.stripe_price_id,
    p_user_id: bc.user_id,
    p_stripe_subscription_id: norm.stripe_subscription_id,
    p_payload: safeJsonb(event),
  });

  if (rpcErr) {
    console.error("[Stripe Webhook] service_stripe_ingest_event_v1 failed:", rpcErr);
    return resp(500, { error: "rpc failed", event_id: event.id });
  }

  return resp(200, { ok: true, event_id: event.id, event_type: event.type });
}

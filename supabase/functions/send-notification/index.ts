import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.6";

// Type definition for our payload
interface RequestPayload {
  type: 'new_recording' | 'publisher_added' | 'day_schedule';
  data: Record<string, string | number>;
}

// --- Deno-native Google OAuth2 JWT helper ---

function base64urlEncode(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function encodeJSON(obj: unknown): string {
  return base64urlEncode(new TextEncoder().encode(JSON.stringify(obj)));
}

async function getGoogleAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = encodeJSON({ alg: 'RS256', typ: 'JWT' });
  const claim = encodeJSON({
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  });

  const signingInput = `${header}.${claim}`;

  // Fix PEM key formatting
  const pemKey = serviceAccount.private_key
    .replace(/\\n/g, '\n')
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');

  const keyBuffer = Uint8Array.from(atob(pemKey), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBuffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const jwt = `${signingInput}.${base64urlEncode(new Uint8Array(signature))}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

// --- Main handler ---

serve(async (req) => {
  try {
    const { type, data } = (await req.json()) as RequestPayload;

    // Initialize Supabase Client to get FCM tokens
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Prepare Notification Content
    // Islamic Month Mapping
    const ISLAMIC_MONTHS = [
      "", "محرم", "صفر", "ربيع الأول", "ربيع الثاني", "جمادي الأول", "جمادي الثاني",
      "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
    ];

    const getMonthName = (m: any) => {
      const idx = typeof m === 'string' ? parseInt(m) : (typeof m === 'number' ? m : 0);
      return ISLAMIC_MONTHS[idx] || "الشهر الهجري";
    };

    let title = "تحديث جديد";
    let body = "لديك إشعار جديد من تطبيق صوت صلاه";
    let targetTokens: string[] = [];

    if (type === "day_schedule") {
      const dayNum = data.dayNumber ?? "";
      const monthName = getMonthName(data.month);
      title = `جدول صلوات اليوم ${dayNum} ${monthName}`;
      body = "تم تحديث جدول أئمة المسجد لليوم، اضغط للتفاصيل.";

      const { data: tokensList } = await supabase
        .from('fcm_tokens')
        .select('token');
      if (tokensList) targetTokens = tokensList.map((t) => t.token);

    } else if (type === "new_recording") {
      const dayNum = data.dayNumber ?? "";
      const monthName = getMonthName(data.month);
      const salah = data.salah ?? "تلاوة";
      title = `${salah} - يوم ${dayNum} ${monthName}`;
      body = `تم رفع تلاوة جديدة بصوت الشيخ ${data.shikh ?? "غير معروف"}`;

      const { data: tokensList } = await supabase
        .from('fcm_tokens')
        .select('token');
      if (tokensList) targetTokens = tokensList.map((t) => t.token);

    } else if (type === "publisher_added") {
      title = "تمت إضافتك كناشر";
      body = "يمكنك الآن رفع التلاوات للمسجد الخاص بك.";

      const { data: users } = await supabase
        .from('profiles')
        .select('id')
        .eq('email', data.publisherEmail)
        .single();

      if (users) {
        const { data: tokensList } = await supabase
          .from('fcm_tokens')
          .select('token')
          .eq('user_id', users.id);
        if (tokensList) targetTokens = tokensList.map((t) => t.token);
      }

    } else if (type === 'day_schedule') {
      title = "جدول شيوخ اليوم 📋";
      body = `تم نشر جدول شيوخ يوم ${data.dayNumber}`;

      const { data: tokensList } = await supabase
        .from('fcm_tokens')
        .select('token');
      if (tokensList) targetTokens = tokensList.map((t) => t.token);

    } else {
      return new Response(JSON.stringify({ error: "Invalid type" }), { status: 400 });
    }

    if (targetTokens.length === 0) {
      return new Response(JSON.stringify({ message: "No tokens to send to" }), { status: 200 });
    }

    // Get Firebase service account and OAuth2 token
    const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountStr) {
      throw new Error("Missing FIREBASE_SERVICE_ACCOUNT secret.");
    }
    const serviceAccount = JSON.parse(serviceAccountStr);
    const accessToken = await getGoogleAccessToken(serviceAccount);

    // Send FCM messages via HTTP v1 API
    let successCount = 0;
    for (const token of targetTokens) {
      const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
      const fcmBody = {
        message: {
          token: token,
          notification: { title, body },
          data: {
            type: type,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
      };

      const res = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmBody),
      });

      if (res.ok) {
        successCount++;
      } else {
        console.error("FCM Send Error:", await res.text());
      }
    }

    return new Response(
      JSON.stringify({ message: `Successfully sent ${successCount} notifications` }),
      { headers: { "Content-Type": "application/json" }, status: 200 },
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";
    return new Response(JSON.stringify({ error: errorMessage }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    });
  }
});

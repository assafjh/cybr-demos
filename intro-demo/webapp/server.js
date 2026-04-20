import express from "express";
import path from "path";
import { fileURLToPath } from "url";

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function now() {
  return new Date().toISOString();
}

function mask(s, keep = 6) {
  if (!s) return "";
  if (s.length <= keep * 2) return "***";
  return `${s.slice(0, keep)}...${s.slice(-keep)}`;
}

function must(v, name) {
  if (!v) throw new Error(`Missing env var: ${name}`);
}

// =====================
// ENV
// =====================
const REGION = process.env.REGION;
const COGNITO_DOMAIN = process.env.COGNITO_DOMAIN;

const IDP_TOKEN_URL =
  process.env.IDP_TOKEN_URL ||
  (REGION && COGNITO_DOMAIN
    ? `https://${COGNITO_DOMAIN}.auth.${REGION}.amazoncognito.com/oauth2/token`
    : undefined);

const IDP_CLIENT_ID = process.env.IDP_CLIENT_ID;
const IDP_CLIENT_SECRET = process.env.IDP_CLIENT_SECRET;
const IDP_SCOPE = process.env.IDP_SCOPE || "";

const CONJUR_BASE_URL = process.env.CONJUR_BASE_URL; // includes /api
const CONJUR_ACCOUNT = process.env.CONJUR_ACCOUNT || "conjur";
const CONJUR_AUTHN_ID = process.env.CONJUR_AUTHN_ID;
const CONJUR_LOGIN = process.env.CONJUR_LOGIN;

const SECRET_ALLOWED_ID = process.env.SECRET_ALLOWED_ID;
const SECRET_DENIED_ID = process.env.SECRET_DENIED_ID;

const PORT = process.env.PORT || 3000;

// =====================
// Startup sanity
// =====================
try {
  must(CONJUR_BASE_URL, "CONJUR_BASE_URL");
  must(CONJUR_AUTHN_ID, "CONJUR_AUTHN_ID");
  must(CONJUR_LOGIN, "CONJUR_LOGIN");
  must(SECRET_ALLOWED_ID, "SECRET_ALLOWED_ID");
  must(SECRET_DENIED_ID, "SECRET_DENIED_ID");
  must(IDP_TOKEN_URL, "IDP_TOKEN_URL");
  must(IDP_CLIENT_ID, "IDP_CLIENT_ID");
  must(IDP_CLIENT_SECRET, "IDP_CLIENT_SECRET");
} catch (e) {
  console.error(`[${now()}] [BOOT] ${e.message}`);
  process.exit(1);
}

console.log(`[${now()}] [BOOT] Starting demo server`);
console.log(`[${now()}] [BOOT] IDP_TOKEN_URL=${IDP_TOKEN_URL}`);
console.log(`[${now()}] [BOOT] IDP_CLIENT_ID=${mask(IDP_CLIENT_ID)}`);
console.log(`[${now()}] [BOOT] IDP_SCOPE=${IDP_SCOPE || "(none)"}`);
console.log(`[${now()}] [BOOT] CONJUR_BASE_URL=${CONJUR_BASE_URL}`);
console.log(`[${now()}] [BOOT] CONJUR_AUTHN_ID=${CONJUR_AUTHN_ID}`);
console.log(`[${now()}] [BOOT] CONJUR_LOGIN=${CONJUR_LOGIN}`);
console.log(`[${now()}] [BOOT] SECRET_ALLOWED_ID=${SECRET_ALLOWED_ID}`);
console.log(`[${now()}] [BOOT] SECRET_DENIED_ID=${SECRET_DENIED_ID}`);

// =====================
// Helpers
// =====================
function decodeJwt(jwt) {
  try {
    const [, payload] = jwt.split(".");
    const decoded = Buffer.from(
      payload.replace(/-/g, "+").replace(/_/g, "/"),
      "base64"
    ).toString("utf8");
    return JSON.parse(decoded);
  } catch (e) {
    return {};
  }
}

function tryParseJson(text) {
  const t = String(text || "").trim();
  if (!t) return null;
  try {
    return JSON.parse(t);
  } catch {
    return null;
  }
}

// =====================
// Cognito → JWT
// =====================
async function getJwtFromIdp() {
  const params = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: IDP_CLIENT_ID,
    client_secret: IDP_CLIENT_SECRET,
  });
  if (IDP_SCOPE) params.set("scope", IDP_SCOPE);

  const resp = await fetch(IDP_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params,
  });

  const bodyText = await resp.text();
  if (!resp.ok) {
    throw new Error(`Cognito token failed: ${resp.status} ${bodyText.slice(0, 200)}`);
  }

  const data = JSON.parse(bodyText);
  if (!data.access_token) throw new Error("No access_token from IdP");
  return data.access_token;
}

// =====================
// Conjur authn
// =====================
async function conjurAuthenticate(jwt) {
  const url = `${CONJUR_BASE_URL}/authn-jwt/${encodeURIComponent(
    CONJUR_AUTHN_ID
  )}/${encodeURIComponent(CONJUR_ACCOUNT)}/authenticate`;

  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Accept-Encoding": "base64",
    },
    body: new URLSearchParams({
      jwt,
      login: CONJUR_LOGIN,
    }),
  });

  const tokenText = await resp.text();
  if (!resp.ok || !tokenText) {
    throw new Error(`Conjur authn failed: ${resp.status}`);
  }

  return tokenText.trim();
}

// =====================
// Conjur secrets (The Fixed Logic)
// =====================
function conjurSecretEndpoint(identifier) {
  return `${CONJUR_BASE_URL}/secrets/${encodeURIComponent(
    CONJUR_ACCOUNT
  )}/variable/${encodeURIComponent(identifier)}`;
}

async function conjurGetSecret(tokenB64, identifier) {
  const resp = await fetch(conjurSecretEndpoint(identifier), {
    method: "GET",
    headers: {
      Authorization: `Token token="${tokenB64}"`,
    },
  });

  // קריאת התשובה הגולמית (בין אם הצלחה ובין אם שגיאה)
  const bodyText = await resp.text().catch(() => "");
  
  // נסיון לפרסר JSON (עבור שגיאות קונז'ור כמו CONJ00076E)
  const jsonBody = tryParseJson(bodyText);

  // SaaS returns 404/403 for permission denied (Concealment)
  if (resp.status === 403 || resp.status === 404) {
    return { 
      denied: true, 
      status: resp.status, 
      // מעבירים את השגיאה המקורית כדי שה-Frontend יציג אותה בלוג
      rawError: jsonBody || bodyText 
    };
  }

  if (!resp.ok) {
    throw new Error(`Secret fetch failed: ${resp.status}`);
  }

  return {
    allowed: true,
    secretValue: bodyText.trim(),
  };
}

// =====================
// API Route (Single, Clean Version)
// =====================
app.post("/api/access", async (req, res) => {
  const scenario = String(req.body?.scenario || "").toLowerCase();
  const identifier = scenario === "allowed" ? SECRET_ALLOWED_ID : SECRET_DENIED_ID;

  try {
    // 1. Get Identity (AWS Cognito)
    const jwt = await getJwtFromIdp();
    const claims = decodeJwt(jwt);

    // Extraction of dynamic metadata from JWT
    const workload = claims.app_id || claims.workload || claims.client_id || "unknown";
    const issuer = claims.iss || "AWS Cognito (OIDC)";

    // 2. Authenticate to Conjur
    const conjurToken = await conjurAuthenticate(jwt);

    // 3. Retrieve Real Secret
    const result = await conjurGetSecret(conjurToken, identifier);

    // Build Dynamic Metadata Response
    const baseResponse = {
      identity_token: { 
        issuer: `${issuer}`, 
        jwt,
        method: `authn-jwt/${CONJUR_AUTHN_ID}` 
      },
      workload_id: workload,
      secret_name: identifier,
      conjur: {
        authn_method: "Identity-based JWT Challenge",
        endpoint: CONJUR_BASE_URL.replace("/api", ""),
        service: CONJUR_AUTHN_ID,
      },
      audit: {
        enforced_by: "CyberArk Conjur",
        timestamp: now(),
      },
    };

    if (result.denied) {
      return res.json({
        result: "denied",
        ...baseResponse,
        error: { 
          backend_status: result.status,
          details: result.rawError 
        },
      });
    }

    const secretValue = result.secretValue;
    const parsedJson = tryParseJson(secretValue);

    return res.json({
      result: "allowed",
      ...baseResponse,
      payload: parsedJson ? parsedJson : { "secret_value": secretValue }
    });

  } catch (e) {
    console.error(`[${now()}] ERROR: ${e.message}`);
    return res.status(500).json({ result: "error", message: "Service Unavailable" });
  }
});

// Static UI
app.use("/", express.static(path.join(__dirname, "public")));

app.listen(PORT, () =>
  console.log(`[${now()}] [BOOT] Listening on http://localhost:${PORT}`)
);
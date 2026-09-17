#!/usr/bin/env bash
# Write lab ES256 JWKs to .secrets/ (gitignored). Run before first apply.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export OUT="$HERE/.secrets"
mkdir -p "$OUT"
chmod 700 "$OUT"

node --input-type=module <<'JS'
import { generateKeyPairSync, createHash } from "node:crypto";
import { writeFileSync } from "node:fs";

const outDir = process.env.OUT;
function b64url(buf) {
  return Buffer.from(buf).toString("base64url");
}
function write(name) {
  const { privateKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
  const jwk = privateKey.export({ format: "jwk" });
  jwk.alg = "ES256";
  jwk.use = "sig";
  const thumb = createHash("sha256")
    .update(JSON.stringify({ crv: jwk.crv, kty: jwk.kty, x: jwk.x, y: jwk.y }))
    .digest();
  jwk.kid = b64url(thumb);
  const path = `${outDir}/${name}.jwk.json`;
  writeFileSync(path, JSON.stringify(jwk), { mode: 0o600 });
  console.log(path);
}
write("issuer");
write("govbr");
JS

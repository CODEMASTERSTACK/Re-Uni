# R2 profile picture upload and display – CORS

You may see:

- **"Upload failed: ClientException: Failed to fetch"** when uploading (PUT to the pre-signed URL).
- **"HTTP request failed, statusCode: 0"** when loading the image from the **public URL** (`pub-...r2.dev`) after upload (e.g. `Image.network(publicUrl)`).

Both are usually due to **CORS** on the R2 bucket. The bucket must allow your app’s origin for **PUT** (upload) and **GET** (display).

---

## 1. Add CORS to your R2 bucket

Without CORS, the browser blocks cross-origin requests to R2 (upload and/or loading the image).

1. In the **Cloudflare Dashboard**, go to **R2 object storage** → select your bucket (e.g. `unidate-profile-images`).
2. Open **Settings**.
3. Under **CORS Policy**, choose **Add CORS policy**.
4. Use the **JSON** tab and paste a policy like this (adjust origins to match your app):

```json
[
  {
    "AllowedOrigins": [
      "http://localhost:3000",
      "http://localhost:5173",
      "http://localhost:55926",
      "http://localhost:58633",
      "https://re-uni.vercel.app"
    ],
    "AllowedMethods": ["GET", "PUT"],
    "AllowedHeaders": ["Content-Type", "x-amz-checksum-crc32"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

5. **Save**.

**Notes:**

- **AllowedOrigins** must include every origin your app runs from:
  - Local: `http://localhost:<port>` (Flutter web uses random ports; add the port you see in the browser, or add several common ones as above).
  - Production: `https://re-uni.vercel.app` (or your real app URL).
- **AllowedMethods** must include **PUT** for uploads and **GET** for loading images (e.g. `Image.network(publicUrl)`). Use `["GET", "PUT"]`.
- **AllowedHeaders** must include **Content-Type** (the client sends this). Include **x-amz-checksum-crc32** if the pre-signed URL includes checksum params.
- CORS changes can take up to ~30 seconds to apply.

---

## 2. "HTTP request failed, statusCode: 0" on the public URL

If the **upload** succeeds but you see **statusCode: 0** when loading the image from the public URL (`https://pub-...r2.dev/.../0.webp`), the **GET** request to display the image is being blocked or failing.

- Ensure your CORS policy includes **GET** in **AllowedMethods** (see the JSON above).
- Ensure **AllowedOrigins** includes the exact origin your app runs from (e.g. `http://localhost:58633`, `https://re-uni.vercel.app`). Origin must match exactly (including port).
- If the bucket uses a **custom domain** for public access, CORS applies to that domain; the policy is on the bucket and applies to both the R2 API and the public endpoint.

## 3. If upload still fails

- **Check the browser Network tab**: Inspect the request to the R2 URL (pre-signed or public). If it’s blocked as "CORS error", add the exact request **Origin** to **AllowedOrigins** (e.g. `http://localhost:60123`).
- **Check the pre-signed URL**: If the URL has `x-amz-checksum-crc32` in the query string, the client may need to send that checksum header; the backend may need to generate URLs without checksum for simple browser PUTs (see `api/get-upload-url.js`).

---

## 4. Summary

- **"Failed to fetch"** (upload) or **"HTTP request failed, statusCode: 0"** (loading the image) are usually due to **missing or wrong CORS** on the bucket.
- Add a CORS policy that allows **GET** and **PUT**, your app’s **origins** (localhost + production), and **Content-Type** (and **x-amz-checksum-crc32** if required).
- After saving, wait a short time and try again.

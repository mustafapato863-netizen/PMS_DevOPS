# Vercel Deployment Guide (Frontend SPA)

This guide documents the procedures for deploying the React static Single-Page Application (SPA) on **Vercel**.

---

## 1. Deployment Model & Strategy

Vercel provides edge-native CDN hosting for compiled frontend assets. When commits are pushed to the frontend repository, Vercel automatically runs compilation scripts and distributes the compiled HTML, JS, and CSS globally.

```
[GitHub Repo: PMS-Frontend] ──(Webhook Trigger)──> [Vercel CDN]
                                                          │
                                                    (npm run build)
                                                          │
                                                          v
                                                 [Compiled Dist Folder]
                                                (Edge-distributed assets)
```

---

## 2. Prerequisites
- A Vercel account connected to your GitHub workspace.
- A running, publicly accessible FastAPI backend endpoint (e.g., hosted on Railway).

---

## 3. In-Repository Requirements
Vercel compiles the React bundle in the cloud, so `PMS-Frontend` must contain:
- `vercel.json` — Redirects routes (rewrites all sub-paths `/.*` to `index.html`) to support client-side React Router routing.
- `package.json` — Declares frontend build scripts.
- `vite.config.ts` — Compiles and bundles code.

---

## 4. Provisioning & Setup

1. **Import Project:** Go to the Vercel dashboard, click **Add New** -> **Project**, and import the `PMS-Frontend` repository.
2. **Build Settings:**
   * **Framework Preset:** Vite
   * **Build Command:** `npm run build`
   * **Output Directory:** `dist`
3. **Configure Environment Variables:** Add the following variables under the deployment config:
   * `VITE_API_BASE_URL` — The URL of the FastAPI backend (e.g., `https://pms-backend.railway.app`).
   * `VITE_SOCKET_URL` — The WebSocket Socket.IO URL of the backend (e.g., `https://pms-backend.railway.app`).
4. **Deploy:** Click **Deploy**. Vercel compiles the files and deploys the static application, assigning a production HTTPS URL.

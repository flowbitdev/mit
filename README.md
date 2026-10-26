# render-linux-desktop

A small Debian XFCE desktop with Chromium, TigerVNC, noVNC, and websockify for deployment as a Render Docker Web Service.

## Important security and persistence notes

This exposes a browser-based remote desktop on a public URL. Use a strong `VNC_PASSWORD`, do not reuse a personal password, and treat the service as an internet-facing computer. VNC authentication is the protection used by the noVNC connection; Render provides HTTPS at the public URL.

This version intentionally uses **no persistent disk**. Chromium, extensions, downloads, and desktop files work while the instance is running, but they can disappear after a restart, redeploy, or free-plan sleep. Do not store important data in the desktop. Do not scale this service to multiple instances.

The default VNC password in the image is intentionally rejected at startup. Set `VNC_PASSWORD` in Render before deploying. VNC passwords are limited to the first eight characters by the VNC protocol, so make the first eight characters strong and unique.

## Run locally

```bash
docker build -t render-linux-desktop .
docker run --rm -it \
  -p 10000:10000 \
  -e VNC_PASSWORD='replace-with-a-strong-password' \
  -e START_CHROMIUM=true \
  -v "$PWD/data:/var/data" \
  render-linux-desktop
```

Open <http://localhost:10000/>. The landing page redirects to noVNC. For a different desktop size, set `VNC_GEOMETRY`, for example `1600x900`.

## Deploy on Render

1. Create a GitHub repository named `render-linux-desktop` and push these files.
2. In Render, choose **New → Blueprint**, connect the repository, and let Render read `render.yaml`. This creates a free web service with no disk and automatically generates `VNC_PASSWORD`.
3. Open the service's **Environment** page and copy the generated `VNC_PASSWORD`. You need it when noVNC prompts for the VNC password.
4. Deploy. Render forwards the public HTTPS URL to the container's `$PORT`; the startup script listens on `0.0.0.0:$PORT` through websockify.
5. Open `https://YOUR-SERVICE.onrender.com/` and paste the generated password into the noVNC prompt.

Alternatively, choose **New → Web Service**, select **Docker**, connect the repository, and manually add `VNC_PASSWORD` as a secret environment variable. Do not add a persistent disk for this setup.

## Configuration

- `VNC_PASSWORD`: required at runtime; use a strong value.
- `VNC_GEOMETRY`: default `1366x768`.
- `START_CHROMIUM`: default `true`; set `false` to start only XFCE.
- `PORT`: supplied by Render, defaulting to `10000` in this image.

The included `render.yaml` generates the password automatically. Render Blueprint `generateValue: true` creates a random secret; the first eight characters are the effective VNC password because of the VNC protocol limit.

## Architecture

`websockify → TigerVNC (:1 / TCP 5901) → XFCE (:1) → Chromium`

The Chromium launch deliberately does not use kiosk mode, so normal browser controls remain available and Chrome Web Store pages can be used from the remote desktop.

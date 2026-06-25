# SkillPlay — GCP VM par SSH se direct deploy

Cloud Run / Terraform **nahi** chahiye. Ek GCP Compute Engine VM par SSH karke sab chalao.

> **Note:** Repo kahi bhi ho sakta hai — `~/SkillsPlay`, `/opt/skillplay`, etc.  
> Neeche `cd` apne actual folder se replace karo. `ls ~` se folder ka naam check karo.

## Architecture (VM par)

```
GCP VM (e2-medium)
├── Docker
│   ├── postgres    (database — auto ban jati hai)
│   ├── redis
│   ├── sandbox     (sirf internal — public nahi)
│   └── backend     (port 3000 — public)
```

---

## Step 1: GCP VM banao

### Console se (easy)

1. https://console.cloud.google.com/compute/instances
2. **Create Instance**
3. Name: `skillplay-vm`
4. Region: `asia-south1` (Mumbai)
5. Machine: `e2-medium` (2 vCPU, 4 GB RAM)
6. Boot disk: Ubuntu 22.04, 30 GB
7. Firewall: ✅ Allow HTTP, ✅ Allow HTTPS (optional)
8. **Create**

### gcloud se

```bash
gcloud compute instances create skillplay-vm \
  --zone=asia-south1-a \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=30GB \
  --tags=skillplay

# API port 3000 kholo
gcloud compute firewall-rules create skillplay-api \
  --allow=tcp:3000 \
  --target-tags=skillplay \
  --description="SkillPlay API"
```

---

## Step 2: SSH karo

```powershell
# Windows PowerShell
gcloud compute ssh skillplay-vm --zone=asia-south1-a
```

Ya Console → VM → **SSH** button

---

## Step 3: Code VM par lao

### Option A — Git clone (recommended)

```bash
# VM par (SSH ke andar)
sudo mkdir -p /opt/skillplay
sudo chown $USER:$USER /opt/skillplay
git clone https://github.com/YOUR_USER/skillplay.git /opt/skillplay
cd /opt/skillplay
```

### Option B — Apne PC se upload (SCP)

```powershell
# Apne Windows PC se (project folder se)
gcloud compute scp --recurse c:\skillplay skillplay-vm:/opt/skillplay --zone=asia-south1-a
```

Phir SSH:
```bash
cd /opt/skillplay
```

---

## Step 4: Install + Start (VM par yeh commands)

```bash
# Apna repo path — tumhare case mein:
cd ~/SkillsPlay

# Ya jahan clone hua ho, wahan cd karo:
# cd ~/skillplay
# cd /opt/skillplay

# Scripts executable banao
chmod +x gcp/vm/*.sh

# Docker install + env file generate
bash gcp/vm/install.sh

# Sab services start (database auto create)
bash gcp/vm/start.sh

# Pehli baar — demo data + admin user
bash gcp/vm/seed.sh
```

**Bas itna.** 🎉

---

## Step 5: Test karo

VM ka external IP lo:
```bash
curl -4 ifconfig.me
```

Browser ya phone se:
```
http://VM_EXTERNAL_IP:3000/health
```

Response: `{"status":"ok","service":"skillplay-api",...}`

### Flutter connect

```powershell
flutter run --dart-define=API_URL=http://VM_EXTERNAL_IP:3000 --dart-define=WS_URL=http://VM_EXTERNAL_IP:3000
```

---

## Files ka kaam

| File | Kahan chalao | Kya karta hai |
|------|--------------|---------------|
| `docker-compose.vm.yml` | VM | Postgres + Redis + Sandbox + Backend |
| `gcp/vm/generate-env.sh` | VM | Random password & JWT secrets |
| `gcp/vm/install.sh` | VM | Docker install |
| `gcp/vm/start.sh` | VM | `docker compose up --build` |
| `gcp/vm/seed.sh` | VM | Database tables + demo users |
| `gcp/vm/update.sh` | VM | Code pull + redeploy |

---

## VM restart par auto-start (SSH bar bar nahi)

**Ek baar** yeh chalao — uske baad VM reboot hone par backend **khud** start hoga:

```bash
cd ~/SkillsPlay
bash gcp/vm/enable-autostart.sh
```

`docker-compose.vm.yml` mein already `restart: unless-stopped` hai — container crash ho to bhi restart.  
Systemd service VM **reboot** par sab uthata hai.

Check (optional):
```bash
sudo systemctl status skillplay
curl http://localhost:3000/health
```

---

## Flutter APK — bina domain, sirf VM IP

Tumhara external IP (screenshot se): **`35.200.216.188`**

### 1. GCP Firewall — port 3000 khula ho

Console → **VPC network** → **Firewall** → Create rule:
- Direction: Ingress
- Target: All instances (ya apni VM)
- Source: `0.0.0.0/0`
- Protocol: **TCP 3000**

Ya phone browser se test: `http://35.200.216.188:3000/health`  
`{"status":"ok"}` aana chahiye.

### 2. APK build (apne Windows PC par)

```powershell
cd c:\skillplay\frontend
.\build-apk.ps1 -ApiIp "35.200.216.188"
```

APK milega: `frontend\build\app\outputs\flutter-apk\app-release.apk`

### 3. Manual build command

```powershell
flutter build apk --release `
  --dart-define=API_URL=http://35.200.216.188:3000 `
  --dart-define=WS_URL=http://35.200.216.188:3000
```

> Android par HTTP (HTTPS nahi) ke liye `usesCleartextTraffic` already enable hai.

### IP badle to?

Naya APK build karo same command se naye IP ke saath. Domain ki zaroorat nahi.

---

## Roz SSH ki zaroorat nahi

| Kaam | Kab |
|------|-----|
| `install.sh` + `start.sh` + `seed.sh` | **Sirf ek baar** |
| `enable-autostart.sh` | **Sirf ek baar** |
| SSH / `start.sh` dubara | Sirf code update par (`bash gcp/vm/update.sh`) |
| VM band / restart | Kuch nahi — backend apne aap chalega |

## Optional — kabhi SSH karna ho (logs / update)

```bash
cd ~/SkillsPlay

# Status dekho
docker compose -f docker-compose.vm.yml ps

# Logs
docker compose -f docker-compose.vm.yml logs -f backend

# Restart
docker compose -f docker-compose.vm.yml restart backend

# Code update + rebuild
bash gcp/vm/update.sh
```

---

## Windows se ek script (optional)

Apne PC se VM par code bhejo + SSH commands:

```powershell
cd c:\skillplay\gcp\scripts
.\vm-upload.ps1 -VmName skillplay-vm -Zone asia-south1-a
```

(Yeh script `vm-upload.ps1` banayi gayi hai)

---

## Security tips

1. `gcp/vm/.env` mein strong passwords — `generate-env.sh` use karo
2. Postgres port (5432) public mat kholo — compose mein already internal hai
3. Sandbox port (4001) public mat kholo
4. Production mein `CORS_ORIGIN` apna domain set karo:
   ```
   CORS_ORIGIN=https://your-app.com
   ```
5. Optional: nginx + SSL (Let's Encrypt) port 443 par

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `permission denied` docker | `sudo usermod -aG docker $USER` then re-login SSH |
| Port 3000 nahi khul raha | GCP firewall rule `skillplay-api` check karo |
| Backend crash | `docker compose logs backend` |
| DB connection error | `docker compose ps` — postgres healthy hona chahiye |
| Out of memory | VM upgrade karo `e2-standard-2` |

---

## Cost

| VM | ~Monthly |
|----|----------|
| e2-medium (Mumbai) | ~$25–30 USD |
| e2-small (testing) | ~$12–15 USD |

Cloud SQL alag nahi — database VM ke andar Postgres container mein hai.

---

## Cloud Run wale files?

| Use case | Files |
|----------|-------|
| **SSH + VM (yeh guide)** | `docker-compose.vm.yml` + `gcp/vm/*.sh` |
| Cloud Run + managed SQL | `gcp/terraform/` + `deploy.ps1` |

Dono alag hain — VM par sirf `gcp/vm/` wali files chahiye.

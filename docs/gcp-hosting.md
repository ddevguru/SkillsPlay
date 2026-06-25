# SkillPlay — GCP Hosting Guide (Hindi + English)

Poora backend + sandbox + PostgreSQL database **ek command** se GCP par deploy karo.

## Kya banega automatically?

| Resource | GCP Service | Auto? |
|----------|-------------|-------|
| PostgreSQL database | Cloud SQL | ✅ Terraform |
| Database `skillplay` + user | Cloud SQL | ✅ Terraform |
| Passwords & JWT secrets | Secret Manager | ✅ Terraform |
| Backend API | Cloud Run | ✅ Cloud Build |
| Code Sandbox | Cloud Run (private) | ✅ Cloud Build |
| Docker images | Artifact Registry | ✅ Terraform + Build |

Redis optional hai — bina Redis ke bhi app chalegi (thoda slow cache).

---

## Pehle yeh install karo (ek baar)

1. **Google Cloud account** + billing enabled project  
   https://console.cloud.google.com

2. **Google Cloud SDK (gcloud)**  
   https://cloud.google.com/sdk/docs/install

3. **Terraform**  
   https://developer.hashicorp.com/terraform/install

4. Login:
```powershell
gcloud auth login
gcloud auth application-default login
```

---

## Deploy — Windows (PowerShell)

```powershell
cd c:\skillplay\gcp\scripts

# Pehli baar — database + backend + sandbox sab deploy
.\deploy.ps1 -ProjectId "YOUR_GCP_PROJECT_ID" -Region "asia-south1" -RunSeed

# Dubara sirf code update (infra skip)
.\deploy.ps1 -ProjectId "YOUR_GCP_PROJECT_ID" -SkipTerraform
```

**`YOUR_GCP_PROJECT_ID`** = GCP Console → project dropdown se ID (e.g. `skillplay-prod-123`)

### Region suggestions (India)

| Region | Code |
|--------|------|
| Mumbai | `asia-south1` |
| Delhi | `asia-south2` |

---

## Deploy — Linux / Mac / Git Bash

```bash
chmod +x gcp/scripts/deploy.sh
./gcp/scripts/deploy.sh YOUR_GCP_PROJECT_ID asia-south1
```

---

## Deploy ke baad kya milega?

Script end par print karega:

```
API URL:     https://skillplay-api-xxxxx.asia-south1.run.app
Health:      https://skillplay-api-xxxxx.asia-south1.run.app/health
```

### Flutter app connect karo

```powershell
cd frontend
flutter run -d chrome `
  --dart-define=API_URL=https://skillplay-api-xxxxx.asia-south1.run.app `
  --dart-define=WS_URL=https://skillplay-api-xxxxx.asia-south1.run.app
```

### Admin panel

`admin/.env`:
```
VITE_API_URL=https://skillplay-api-xxxxx.asia-south1.run.app
```

### Demo login (seed ke baad)

| Email | Password |
|-------|----------|
| admin@skillplay.dev | Admin123! |
| demo@skillplay.dev | Demo1234! |

---

## Files ka structure

```
gcp/
├── terraform/           # Database + secrets + Cloud Run config
│   ├── cloud_sql.tf     # PostgreSQL auto-create
│   ├── cloud_run.tf     # API + sandbox services
│   ├── secrets.tf       # JWT + DB password
│   └── terraform.tfvars.example
├── cloudbuild.yaml      # Docker build + deploy
└── scripts/
    ├── deploy.ps1       # Windows one-click
    └── deploy.sh        # Linux/Mac one-click
```

---

## Step-by-step (manual samajhna ho to)

### Step 1: Terraform — database banao

```powershell
cd gcp\terraform
copy terraform.tfvars.example terraform.tfvars
# terraform.tfvars mein project_id edit karo

terraform init
terraform apply
```

Yeh create karega:
- Cloud SQL PostgreSQL instance (`skillplay-pg`)
- Database `skillplay`
- User `skillplay` + random password (Secret Manager mein)
- Artifact Registry repo
- Secret Manager (JWT, DATABASE_URL)

### Step 2: Cloud Build — images + deploy

```powershell
cd c:\skillplay

$PROJECT = "YOUR_PROJECT_ID"
$REGION = "asia-south1"
$SQL = gcloud sql instances describe skillplay-pg --format="value(connectionName)"

gcloud builds submit . --config=gcp/cloudbuild.yaml `
  --substitutions="_REGION=$REGION,_CLOUDSQL_CONNECTION=$SQL,_SANDBOX_URL=https://placeholder,_CORS_ORIGIN=*"
```

### Step 3: Database seed (pehli baar)

```powershell
gcloud run jobs execute skillplay-seed --region=asia-south1 --wait
```

---

## Sandbox GCP par kaise kaam karta hai?

```
Flutter → Backend (public Cloud Run)
              ↓ (private call + identity token)
         Sandbox (no public access)
```

- Sandbox URL public nahi hai (`--no-allow-unauthenticated`)
- Backend automatically GCP identity token bhejta hai (`SANDBOX_USE_IDENTITY=true`)
- Local dev mein: `SANDBOX_URL=http://localhost:4001` (token ki zaroorat nahi)

---

## Cost estimate (starter)

| Service | ~Monthly (USD) |
|---------|----------------|
| Cloud SQL db-f1-micro | ~$7–10 |
| Cloud Run API (low traffic) | ~$0–5 |
| Cloud Run Sandbox | ~$0–5 |
| Secret Manager | < $1 |
| **Total** | **~$10–20/mo** |

Free tier credits se pehle mahine sasta ho sakta hai.

---

## Common errors

| Error | Fix |
|-------|-----|
| `Billing not enabled` | GCP Console → Billing link karo |
| `Permission denied` | `gcloud auth login` + project Owner/Editor role |
| `API can't reach sandbox` | Sandbox deploy hone ke baad dubara `deploy.ps1` chalao |
| `Cloud SQL connection failed` | 2–3 min wait karo — SQL instance boot ho raha hai |
| `terraform: command not found` | Terraform install karo |
| Health check fail | `gcloud run services logs read skillplay-api --region=asia-south1` |

---

## Logs dekhna

```powershell
# Backend logs
gcloud run services logs read skillplay-api --region=asia-south1 --limit=50

# Sandbox logs
gcloud run services logs read skillplay-sandbox --region=asia-south1 --limit=50
```

---

## Sab delete karna ho to

```powershell
cd gcp\terraform
terraform destroy
```

⚠️ Database bhi delete ho jayega.

---

## CORS update (Flutter web domain)

`gcp\terraform\terraform.tfvars`:
```
cors_origin = "https://your-app.web.app,https://your-admin.com"
```

Phir:
```powershell
terraform apply
gcloud run services update skillplay-api --region=asia-south1 --update-env-vars CORS_ORIGIN="https://..."
```

---

## Quick checklist

- [ ] GCP project + billing
- [ ] `gcloud auth login`
- [ ] `.\deploy.ps1 -ProjectId "xxx" -RunSeed`
- [ ] `curl API_URL/health` → `{"status":"ok"}`
- [ ] Flutter with `API_URL` dart-define
- [ ] Login test with demo account

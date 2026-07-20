# دليل رفع واستضافة نظام PMS Dashboard
# Production Deployment & Hosting Guide

هذا الدليل الشامل يوضح الخطوات التفصيلية لرفع واستضافة **نظام PMS Dashboard** على السيرفرات الإنتاجية (Production Servers) أو منصات الاستضافة السحابية (Cloud Hosting).

---

## 📋 نظرة عامة على بنية النظام (Architecture Overview)

يتكون النظام من 4 مكونات رئيسية:
1. **الواجهة الأمامية (Frontend):** مشروع React + Vite + TypeScript (يتم تجميعه إلى أصل ملفات استاتيكية في `dist/`).
2. **الخلفية (Backend API):** تطبيق FastAPI + Python 3.11 مع دعم WebSockets و REST APIs.
3. **قاعدة البيانات (Database):** PostgreSQL (إصدار 15 أو أحدث) مع Alembic لإدارة الترحيلات (Migrations).
4. **التخزين المؤقت والرسائل (Cache & Queue):** Redis 7+.

---

## 🛠️ خيارات الاستضافة المتاحة (Hosting Options)

المشروع جاهز ومعد لدعم 3 طرق استضافة مختلفة حسب بنيتكم التحتية:

---

### 🟢 الخيار الأول: الاستضافة باستخدام Docker Compose (الموصى به للـ VPS)

هذا الخيار هو الأسهل والأسرع، حيث يتم تشغيل جميع الخدمات (Backend, Frontend/Nginx, Postgres, Redis, Monitoring) بأمر واحد داخل سيرفر VPS (مثل Hetzner, DigitalOcean, AWS EC2, Linode, Contabo).

#### 1. متطلبات السيرفر (Server Prerequisites)
- نظام تشغيل: **Ubuntu 22.04 LTS** أو **Ubuntu 24.04 LTS**.
- المواصفات الأقل موصى بها: **2 CPU Cores, 4GB RAM, 40GB SSD**.
- التثبيتات الأساسية على السيرفر:
  ```bash
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y docker.io docker-compose-plugin git certbot python3-certbot-nginx
  sudo systemctl enable --now docker
  ```

#### 2. خطوة رفع الكود وتهيئة البيئة
```bash
# 1. استخراج أو استنساب الملفات في السيرفر
mkdir -p /var/www/pms-dashboard
cd /var/www/pms-dashboard

# 2. إنشاء ملف المتغيرات البيئية من النموذج
cp DevOps/.env.example DevOps/.env

# 3. تعديل المتغيرات البيئية السرية (تحديد كلمة سر قاعدة البيانات ورمز الـ JWT)
nano DevOps/.env
```

تأكد من تعديل المفاتيح التالية داخل `DevOps/.env`:
```env
APP_ENV=production
POSTGRES_PASSWORD=YourSecurePassword123!
REDIS_PASSWORD=YourSecureRedisPassword123!
JWT_SECRET=YourSuperSecretJWTKeyMin32CharsLength!
CORS_ORIGINS=https://your-domain.com,http://your-domain.com
```

#### 3. تشغيل النظام عبر Docker
```bash
# تشغيل جميع الحاويات في الخلفية
docker compose -f DevOps/compose/docker-compose.prod.yml up -d --build

# التحقق من حالة الحاويات
docker compose -f DevOps/compose/docker-compose.prod.yml ps

# متابعة السجلات (Logs)
docker compose -f DevOps/compose/docker-compose.prod.yml logs -f web
```

---

### 🟡 الخيار الثاني: الاستضافة التقليدية المباشرة (Classic VPS / Ubuntu Setup)

في هذا الخيار يتم تشغيل الباك إند عبر `uvicorn/gunicorn` كـ Service في النظام، واستضافة الفرونت إند عبر سيرفر `Nginx` المباشر.

#### 1. تهيئة قاعدة البيانات PostgreSQL و Redis
```bash
sudo apt install -y postgresql postgresql-contrib redis-server

# إنشاء قاعدة البيانات والمستخدم
sudo -u postgres psql -c "CREATE DATABASE \"PMS_Sys\";"
sudo -u postgres psql -c "CREATE USER pmsuser WITH PASSWORD 'YourSecurePassword123!';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"PMS_Sys\" TO pmsuser;"
```

#### 2. تهيئة وتشغيل Backend (FastAPI)
```bash
cd /var/www/pms-dashboard/Backend

# إنشاء بيئة وهمية وتثبيت المتطلبات
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# تنفيذ ترحيلات قاعدة البيانات (Database Migrations)
alembic upgrade head

# إنشاء ملف خدمة Systemd للباك إند
sudo nano /etc/systemd/system/pms-backend.service
```

محتوى ملف `pms-backend.service`:
```ini
[Unit]
Description=PMS Dashboard FastAPI Backend Service
After=network.target postgresql.service redis.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/pms-dashboard/Backend
Environment="PATH=/var/www/pms-dashboard/Backend/.venv/bin"
Environment="DATABASE_URL=postgresql://pmsuser:YourSecurePassword123!@localhost:5432/PMS_Sys"
Environment="REDIS_URL=redis://localhost:6379/0"
Environment="JWT_SECRET=YourSuperSecretJWTKeyMin32CharsLength!"
Environment="APP_ENV=production"
Environment="PORT=7860"
ExecStart=/var/www/pms-dashboard/Backend/.venv/bin/uvicorn app:app --host 127.0.0.1 --port 7860 --workers 4

Restart=always

[Install]
WantedBy=multi-user.target
```

تفعيل وتشغيل الخدمة:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now pms-backend
sudo systemctl status pms-backend
```

#### 3. تجميع واستضافة Frontend (React Static Build)
```bash
cd /var/www/pms-dashboard/Frontend

# تجميع أصول الإنتاج
npm install
npm run build
```
سيتم توليد المخرجات الجاهزة للاستضافة داخل المجلد: `/var/www/pms-dashboard/Frontend/dist`

#### 4. إعداد Nginx
قم بنسخ الإعدادات إلى Nginx:
```bash
sudo nano /etc/nginx/sites-available/pms.conf
```
محتوى الملف:
```nginx
server {
    listen 80;
    server_name your-domain.com; # استبدل بدومين سيرفرك أو الـ IP

    client_max_body_size 25m;

    # استضافة واجهة الموظفين والداشبورد (Frontend SPA)
    location / {
        root /var/www/pms-dashboard/Frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # توجيه طلبات الـ API إلى FastAPI
    location /api/ {
        proxy_pass http://127.0.0.1:7860/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # توجيه طلبات WebSockets
    location /socket.io/ {
        proxy_pass http://127.0.0.1:7860/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

ربط الخدمة وإعادة تشغيل Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/pms.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

### 🔵 الخيار الثالث: الاستضافة السحابية (Cloud PaaS Deployment)

إذا كنت ترغب في تقسيم الاستضافة بدون الحاجة لـ VPS:
1. **Frontend (Vercel / Netlify / Cloudflare Pages):**
   - قم بربط مجلد `Frontend` باسم المستودع.
   - اضبط إعدادات البناء:
     - **Build Command:** `npm run build`
     - **Output Directory:** `dist`
   - اضيف المتغير البيئي: `VITE_API_BASE_URL=https://your-backend-api.onrender.com`
2. **Backend (Render / Railway / Fly.io / HuggingFace Spaces):**
   - اختر رفع عبر `Dockerfile` الموجود في `Backend/Dockerfile`.
   - قم بربط قاعدة البيانات السحابية (PostgreSQL من Supabase أو Render PostgreSQL).
   - اضبط المتغيرات البيئية (`DATABASE_URL`, `JWT_SECRET`, `CORS_ORIGINS`).

---

## 🔒 ربط الدومين وتفعيل شهادة الأمان (SSL / HTTPS)

لتفعيل شفرة الأمان مجاناً عن طريق **Let's Encrypt**:
```bash
sudo certbot --nginx -d your-domain.com
```
سيقوم Certbot بتلقائياً بتوجيه حركة المرور إلى HTTPS وتجديد الشهادة دورياً.

---

## 💾 النسخ الاحتياطي والصيانة (Backup & Maintenance)

### 1. عمل نسخة احتياطية من قاعدة البيانات
```bash
# لـ Docker Compose:
docker exec -t pms_postgres_db_prod pg_dump -U postgres PMS_Sys > backup_$(date +%Y%m%d).sql

# لـ VPS العادي:
pg_dump -U pmsuser PMS_Sys > backup_$(date +%Y%m%d).sql
```

### 2. استعادة النسخة الاحتياطية
```bash
# لـ Docker Compose:
cat backup_20260720.sql | docker exec -i pms_postgres_db_prod psql -U postgres -d PMS_Sys
```

---

## ✅ ملخص فحوصات الجاهزية للرفع (Pre-Flight Checklist)

- [x] تجميع الواجهة الأمامية `Frontend/dist` بنجاح دون أي أخطاء.
- [x] إعداد ملفات Docker و Docker Compose الإنتاجية (`DevOps/compose/docker-compose.prod.yml`).
- [x] تجهيز ملف إعدادات Nginx المباشر مع دعم التوجيه للشبكات والـ SPA (`DevOps/nginx/sites/pms.conf`).
- [x] تجهيز التنسيق الموحد للمتغيرات البيئية (`DevOps/.env.example`).
- [x] حزم ملف التجميع الشامل للرفع وتسليمه في `Handover/Project_Handover.zip`.

# دليل النظام الشامل - لوحة تحكم إدارة الأداء (PMS Dashboard)

هذا المستند يقدم دليلاً كاملاً ومبسطاً لبنية النظام، طريقة تشغيله، وأبرز مكوناته لتسهيل عملية التسليم والتهيئة (Handover).

---

## 1. نظرة عامة على النظام (System Overview)
النظام عبارة عن منصة سحابية لإدارة وتقييم الأداء الشهري للفرق والموظفين (Performance Management System). يتيح النظام لمديري الأداء والمديرين التنفيذيين متابعة مؤشرات الأداء الرئيسية (KPIs)، وإعداد التقارير الدورية التفاعلية، وتوليد تقارير العروض التقديمية (PowerPoint) المصممة بدقة 16:9 بشكل مباشر وتلقائي.

---

## 2. الهيكل البرمجي وبنية النظام (Architecture)
ينقسم المشروع إلى قسمين رئيسيين:

### أ. الواجهة الأمامية (Frontend)
*   **التقنيات الأساسية:** React.js, TypeScript, Vite.
*   **التنسيق والتصميم (CSS):** Vanilla CSS مخصص بالكامل وممزوج بـ TailwindCSS لتوفير واجهات مرنة وحديثة تتماشى مع الهوية البصرية لشركات الفئة الأولى (مثل Stripe و Linear).
*   **إدارة الحالة (State Management):** Zustand (خفيف الوزن وسريع).
*   **جلب البيانات والـ API:** TanStack React Query (للكاش وتوفير سرعة فائقة في مزامنة البيانات).
*   **الرسوم البيانية:** Recharts (تفاعلية وسريعة الاستجابة).

### ب. الواجهة الخلفية (Backend)
*   **التقنيات الأساسية:** Python, FastAPI.
*   **قاعدة البيانات:** SQLAlchemy كمحرك لقواعد البيانات (ORM) مع SQLite للتطوير المحلي ودعم كامل لـ PostgreSQL للإنتاج.
*   **إدارة الترحيل (Database Migrations):** Alembic.
*   **الاتصال اللحظي:** WebSockets عبر Socket.io لمزامنة التغييرات والتحميلات لحظياً.
*   **التحكم والتخزين المؤقت:** Redis (مع آلية fallback للعمل محلياً في الذاكرة دون الحاجة لـ Redis في بيئة التطوير).

---

## 3. أبرز المميزات البرمجية (Key Features)

1.  **إدارة الفرق (Team Management):**
    *   تقسيم الفرق إلى فرق موظفين (Employee Levels) ووحدات إدارية (Management Units).
    *   معالج إعداد ورفع البيانات المكون من خطوات (Onboarding Wizard) لإدخال وتهيئة ومطابقة أعمدة البيانات وتعريف الـ KPIs للفرق الجديدة.
2.  **منشئ التقارير التفاعلي (Monthly Performance Report Builder):**
    *   **تحديد النطاق (Scope):** اختيار الفترة والمنطقة والفرق المستهدفة.
    *   **قوالب القصص الجاهزة (Story Templates):** اختيار قالب أداء تنفيذي يقوم بإنشاء هيكل عرض تقديمي متكامل فوراً.
    *   **لوحة بناء تفاعلية (16:9 Canvas):** دعم السحب والإفلات لإعادة ترتيب العناصر، وتغيير الإعدادات ديناميكياً لكل Block (KPIs, Score Trends, Narratives, Tables).
3.  **التعليق التحليلي الذكي (System Analysis):**
    *   توليد سرد تحليلي تلقائي بناءً على البيانات الفعلية المسترجعة من الـ API بدلاً من النصوص الوهمية.
4.  **تصدير العروض التقديمية (PPTX Export):**
    *   تصدير التقارير كملفات PowerPoint متوافقة بالكامل وتطابق التنسيق المطور بدقة 16:9.

---

## 4. كيفية تشغيل المشروع محلياً (How to Run Locally)

### متطلبات التشغيل (Prerequisites)
*   Node.js (الإصدار 18 فما فوق).
*   Python (الإصدار 3.10 أو 3.11).

---

### أولاً: تشغيل الباك إند (Backend Setup)
1.  انتقل إلى مجلد الباك إند:
    ```bash
    cd Backend
    ```
2.  قم بإنشاء البيئة الافتراضية وتفعيلها:
    ```bash
    python -m venv .venv
    # لتفعيلها على Windows:
    .\.venv\Scripts\activate
    ```
3.  قم بتثبيت الحزم البرمجية:
    ```bash
    pip install -r requirements.txt
    ```
4.  قم بتشغيل خادم التطوير (Uvicorn) على البورت 8000:
    ```bash
    uvicorn app:app --reload --port 8000
    ```

---

### ثانياً: تشغيل الفرونت إند (Frontend Setup)
1.  انتقل إلى مجلد الفرونت إند:
    ```bash
    cd Frontend
    ```
2.  قم بتثبيت حزم الـ Node:
    ```bash
    npm install
    ```
3.  قم بتشغيل خادم التطوير:
    ```bash
    npm run dev
    ```
4.  افتح المتصفح على الرابط الموضح في التيرمنال (غالباً `http://localhost:5173`).

---

## 5. إدارة قاعدة البيانات والـ Migrations
تتم إدارة التغييرات في الجداول عبر Alembic:
*   لإنشاء ترحيل جديد بعد تعديل الـ Models:
    ```bash
    alembic revision --autogenerate -m "description_of_changes"
    ```
*   لتحديث قاعدة البيانات لأحدث إصدار:
    ```bash
    alembic upgrade head
    ```

---

## 6. مسارات الملفات الهامة في الكود (Important Code Paths)

### Frontend:
*   `Frontend/src/store/reportBuilderStore.ts` - إدارة حالة منشئ التقارير بالكامل.
*   `Frontend/src/components/reports/builder/Step3Builder.tsx` - لوحة التصميم والـ Canvas والشرائح.
*   `Frontend/src/components/reports/builder/BlockRenderer.tsx` - المسؤول عن رسم الـ Charts والـ Tables وتوزيع البيانات التفاعلية داخل الـ Canvas.
*   `Frontend/src/components/reports/builder/ContentLibraryModal.tsx` - نافذة اختيار وإضافة البلوكات الجديدة.

### Backend:
*   `Backend/services/report_service.py` - منطق جلب خيارات الفترات، توليد المعاينات، وحساب المتوسطات والـ KPIs للتقارير.
*   `Backend/api/routers/reports.py` - واجهات برمجة التطبيقات (API Endpoints) الخاصة بالتقارير وتصديرها.

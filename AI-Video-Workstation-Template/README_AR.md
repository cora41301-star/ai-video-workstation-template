# AI Video Workstation — قالب جهاز إنتاج الفيديو والبرمجة

قالب قابل للنسخ لكل مستخدم GitHub. يجهّز تلقائيًا جهاز Ubuntu بواجهة XFCE مع Chrome وClaude Desktop وClaude Code وHyperFrames Studio وFFmpeg وyt-dlp. **لا يتضمن حسابات أو بيانات دخول أو فيديوهات مستخدمين آخرين**.

## أسهل طريقة للمستخدم النهائي

1. افتح **رابط القالب** الذي يعطيك إياه صاحب المشروع.
2. اضغط **Use this template → Create a new repository**. اختر **Owner: حسابك أنت**، و**Visibility: Private**. هذا مهم لتكون الملفات والبيئة وفوترة Codespaces في حسابك أنت.
3. افتح المستودع الجديد: **Code → Codespaces → Create codespace**. اختر جهازًا **4-core / 16GB** إذا عرض GitHub الخيارات وكان متاحًا لك.
4. سيتم التثبيت تلقائيًا عند أول إنشاء. سيظهر `START_HERE_AR.md` مع الإرشادات.
5. افتح `DESKTOP_ACCESS.md` ثم **PORTS → 6080 → Open in Browser**. أبقِ المنفذ **Private**.
6. سجل الدخول في Claude بحسابك المدفوع، وفي HyperFrames بحسابك إن احتجت. ابدأ العمل.

هذا المسار موثق في [GitHub: Setting up a template repository for Codespaces](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/setting-up-your-repository/setting-up-a-template-repository-for-github-codespaces).

## خطوات النشر لصاحب القالب (مرة واحدة فقط)

1. أضف ملفات هذا القالب إلى **مستودع نظيف منفصل** (ولا تنشر محتويات المنزل `~/.claude` أو مفاتيح GitHub أو الفيديوهات الحالية).
2. في إعدادات المستودع **Settings → General → Template repository** فعّل خيار جعله قالبًا، إذا كان متاحًا في حسابك.
3. جرّبه في **مستودع جديد يملكه حساب اختبار آخر**؛ لا تستخدم بيئة عملك الشخصية لتجربة التسليم.
4. اختبر تشغيل برامج الواجهة، وتسجيل الدخول، وإيقاف الجهاز وإعادة تشغيله، وتقرير `scripts/verify.sh`.
5. أعطِ المستخدم **رابط المستودع النموذجي فقط**؛ لا ترسل له رابط noVNC القديم ولا كلمة مروره.

يمكنك إبقاء القالب **Private** ومشاركة الوصول إلى المستودع مع مستخدم محدد حسب صلاحيات GitHub، أو نشره Public **فقط بعد مراجعة خلوه من البيانات الخاصة**. لا تنشر المستودع الشخصي `cloud-workstation-test` قبل مراجعة كل الملفات وسجل Git.

## ما الذي يحصل تلقائيًا؟

- ملف `.devcontainer/devcontainer.json` يطلب حدًا أدنى 4 CPU و16GB RAM ويسجل منفذ 6080.
- `scripts/install.sh`: تثبيت البرامج الرسمية والإضافة الرسمية لـHyperFrames عبر Claude Code، وإنشاء الاختصارات وكلمة مرور VNC عشوائية محلية.
- `scripts/start-desktop.sh`: إعادة تشغيل واجهة XFCE وnoVNC عند تشغيل Codespace مجددًا.
- `DESKTOP_ACCESS.md`: ملف محلي **مستبعد من Git** يعرض كلمة مرور سطح المكتب وطريقة الوصول.
- `scripts/verify.sh`: تقرير وجود الأدوات.
- `scripts/stop-desktop.sh`: إيقاف الواجهة الرسومية فقط **ولا يوقف Codespace نفسه**.

**المنافذ:** لا يمكن فرض `Private` عن طريق ملف devcontainer القياسي. GitHub يجعل المنافذ الجديدة **Private افتراضيًا**، وعلى المستخدم التحقق قبل الدخول. المنفذ العام يسمح لمن يمتلك الرابط بالوصول دون تسجيل GitHub. راجع [GitHub: Forwarding ports](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace).

## القيود والتكاليف

- GitHub Codespaces ليس VPS دائمًا؛ يتوقف بعد الخمول، وتستنزف الحصة المجانية مع تشغيل CPU والتخزين.
- بناء جهاز 4-core من حساب GitHub Free يعطي تقريبًا 30 ساعة حسابية فقط شهريًا عند افتراض حصة 120 core-hours وعدم استهلاكها مسبقًا. وتوجد حصة تخزين منفصلة.
- **Claude Code** لا يصبح مجانيًا عند استخدام Codespaces؛ يحتاج حساب Claude مؤهلًا أو خيار API مدفوعًا.
- **HyperFrames Studio** له خطة مجانية، وقد تحتاج خدماته المدفوعة إلى اشتراك منفصل.
- ميزات Claude Cowork قد تحتاج KVM ومساحة إضافية وغير مناسبة لضمان عملها على هذا القالب.
- البرامج الرسومية على Codespaces عبر VNC قد تكون أبطأ من جهاز Windows فعلي؛ لا تفترض توفر GPU.
- إذا فشلت إحدى تنزيلات البرامج الاختيارية، قد يكتمل إعداد سطح المكتب مع تحذير في التقرير. تحقق قبل تسليم الجهاز.

## التحقق الإداري

من Terminal داخل الجهاز:

```bash
bash scripts/verify.sh
bash scripts/start-desktop.sh
```

للاطلاع على سجل التثبيت:

```bash
tail -n 60 "$HOME/.cache/ai-video-workstation/install.log"
```

إن احتجت إعادة تشغيل التثبيت بعد إصلاح اتصال مستودعات Ubuntu:

```bash
bash scripts/install.sh
```

**لا تضع بيانات الاعتماد في هذه السكربتات.** تكفي ملفات القالب للإنشاء من الصفر.

## المصادر الرسمية

- [GitHub Codespaces template](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/setting-up-your-repository/setting-up-a-template-repository-for-github-codespaces)
- [GitHub Codespaces included usage](https://docs.github.com/en/codespaces/troubleshooting/troubleshooting-included-usage)
- [Claude Desktop Linux](https://support.claude.com/en/articles/10065433-install-claude-desktop)
- [HyperFrames Studio](https://hyperframes.studio/)
- [HyperFrames Claude Code Plugin](https://github.com/heygen-com/hyperframes/blob/main/docs/guides/plugins.mdx)
- [yt-dlp official repository](https://github.com/yt-dlp/yt-dlp)

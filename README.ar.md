# aiXplainKit

يُمكِّن aiXplainKit مبرمجي Swift من إضافة وظائف الذكاء الاصطناعي إلى برامجهم بسهولة.

## نظرة عامة

aiXplainKit هو حزمة تطوير برمجيات (SDK) لـ [منصة aiXplain](https://aixplain.com/). باستخدام aiXplainKit، يمكن للمطورين بسرعة وسهولة:

- [اكتشاف](https://aixplain.com/platform/discovery/) كتالوج aiXplain المتنامي باستمرار الذي يضم أكثر من 35,000 نموذج ذكاء اصطناعي جاهز للاستخدام والاستفادة منها.
- [تصميم](https://aixplain.com/platform/studio/) خطوط معالجة مخصصة خاصة بهم وتشغيلها.


## إعداد مفتاح API
قبل أن تتمكن من استخدام SDK الخاص بـ aiXplain، ستحتاج إلى الحصول على مفتاح API من منصتنا. للاطلاع على التفاصيل، راجع [دليل مفتاح API للفريق<MISSING>](<doc:TeamAPIKeyGuide>).

بمجرد حصولك على مفتاح API، ستحتاج إلى إضافته كمتغير بيئة على نظامك.

```swift
AiXplainKit.shared.keyManager.TEAM_API_KEY = "<Your Key>"
```

بدلاً من ذلك، يمكنك تعيين مفتاح API كمتغير بيئة في Xcode. يُبقي هذا النهج مفتاح API منفصلاً عن الكود الخاص بك، مما قد يكون مفيداً من حيث الأمان وقابلية النقل. اطّلع على كيفية القيام بذلك في ``APIKeyManager``

## المواضيع

### الأساسيات

- [TeamAPIKeyGuide]()
- [Pipeline]()



<!-- ملاحظات الترجمة: [أُبقي على aiXplainKit كاسم علامة تجارية دون ترجمة] | [أُبقي على Swift كاسم لغة برمجة] | [أُبقي على API وSDK كمصطلحات تقنية عالمية] | [kept EN: Xcode — اسم منتج Apple] | [kept EN: APIKeyManager — اسم فئة برمجية] | [kept EN: TEAM_API_KEY — اسم متغير برمجي] | [تُرجم pipeline إلى خطوط معالجة حسب المسرد المعتمد] -->
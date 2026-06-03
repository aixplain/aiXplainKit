# ``aiXplainKit``

تُمكِّن aiXplainKit مبرمجي Swift من إضافة دوال الذكاء الاصطناعي إلى برمجياتهم بسهولة.

## نظرة عامة

aiXplainKit هي حزمة تطوير برمجيات (SDK) لمنصة [aiXplain](https://aixplain.com/). باستخدام aiXplainKit، يمكن للمطورين بسرعة وسهولة:

- [اكتشاف](https://aixplain.com/platform/discovery/) كتالوج aiXplain المتنامي باستمرار الذي يضم أكثر من 35,000 نموذج ذكاء اصطناعي جاهز للاستخدام والاستفادة منها.
- [تصميم](https://aixplain.com/platform/studio/) خطوط معالجة مخصصة خاصة بهم وتشغيلها.


## إعداد مفتاح API
قبل أن تتمكن من استخدام حزمة SDK الخاصة بـ aiXplain، ستحتاج إلى الحصول على مفتاح API من منصتنا. للتفاصيل راجع [دليل مفتاح API للفريق<MISSING>](<doc:TeamAPIKeyGuide>).

بمجرد الحصول على مفتاح API، ستحتاج إلى إضافة هذا المفتاح كمتغير بيئة في نظامك.

```swift
AiXplainKit.shared.keyManager.TEAM_API_KEY = "<Your Key>"
```

بدلاً من ذلك، يمكنك تعيين مفتاح API كمتغير بيئة في Xcode. يحافظ هذا النهج على فصل مفتاح API عن الشيفرة البرمجية، مما قد يكون مفيدًا من حيث الأمان وقابلية النقل. اطّلع على كيفية القيام بذلك في ``APIKeyManager``

## المواضيع

### الأساسيات
- <doc:TeamAPIKeyGuide>
- <doc:PipelineEssential>
- <doc:DiscoverEssential>

### درس تعليمي
- <doc:aiXplain101>


<!-- ملاحظات الترجمة: [models→النماذج حسب المسرد] | [pipelines→خطوط معالجة حسب المسرد] | [Tutorial→درس تعليمي حسب المسرد] | [kept EN: aiXplainKit, SDK, API, Swift, Xcode, APIKeyManager — brand/tech terms] -->
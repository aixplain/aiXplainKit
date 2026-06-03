# أساسيات النماذج

تعرَّف على كيفية استخدام كتالوج aiXplain المتنامي باستمرار الذي يضم أكثر من 35,000 نموذج ذكاء اصطناعي جاهز للاستخدام، يمكن توظيفها في مهام متنوعة مثل الترجمة، والتعرف على الكلام، والتشكيل، وتحليل المشاعر، وغير ذلك الكثير.

## نظرة عامة

يمكن الوصول إلى كتالوج جميع النماذج المتاحة على aiXplain وتصفّحه [من هنا](https://platform.aixplain.com/discovery/models). يمكن الاطلاع على تفاصيل كل نموذج بالنقر على بطاقة النموذج. يمكن العثور على معرّف النموذج في عنوان URL أو أسفل اسم النموذج.

بمجرد توفر معرّف النموذج المطلوب، يمكن استخدامه لإنشاء كائن `Model` من `ModelFactory`.

```swift
from aixplain.factories import ModelFactory
let model = ModelProvider().get("<MODEL_ID>") 
```

### تشغيل

تتيح لك حزمة aixplain SDK تشغيل نماذج تعلم الآلة.

```python
let output = model.run("This is a sample text") # You can use a URL or a file path on your local machine
```

<!-- ملاحظات الترجمة: أُبقي على أسماء العلامات التجارية (aiXplain, SDK) بالإنجليزية وفق التعليمات | أُبقي على أسماء الفئات والدوال (Model, ModelFactory, ModelProvider) داخل الشيفرة وخارجها كما هي | kept EN: SDK — brand/technology name | kept EN: URL — technical acronym -->
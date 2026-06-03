# أساسيات خطوط المعالجة
تعلّم كيفية استخدام خطوط المعالجة


## نظرة عامة

 [Design](https://aixplain.com/platform/studio/) هي أداة بناء خطوط معالجة الذكاء الاصطناعي بدون كود من aiXplain، تُسرّع تطوير الذكاء الاصطناعي من خلال توفير تجربة سلسة لبناء أنظمة ذكاء اصطناعي معقدة ونشرها في غضون دقائق. يمكنك زيارة منصتنا وتصميم خط المعالجة المخصص الخاص بك [من هنا](https://platform.aixplain.com/studio).

#### الاستكشاف
يمكن الوصول إلى كتالوج جميع خطوط المعالجة الخاصة بك على aiXplain وتصفّحه [من هنا](https://platform.aixplain.com/dashboard/pipelines). يمكن الاطلاع على تفاصيل خط المعالجة بالنقر على بطاقته. يمكن العثور على معرّف خط المعالجة من عنوان URL أو أسفل اسم خط المعالجة (بشكل مشابه للنماذج).

بمجرد توفر معرّف خط المعالجة المطلوب، يمكن استخدامه لإنشاء كائن `Pipeline` من `PipelineProvider`.
```swift
import AiXplainKit
pipeline = PipelineProvider().get("<PIPELINE_ID>") 
```

### التشغيل
تتيح لك AiXplainKit تشغيل خطوط المعالجة بشكل غير متزامن.

```swift
let result = try await pipeline.run("This is a sample text")
```


بالنسبة لخطوط المعالجة متعددة المدخلات، يمكنك تحديد قاموس كمدخل حيث تكون المفاتيح هي أسماء تسميات عقدة المدخل والقيم هي المحتوى المقابل لها:

```swift
let result = try await pipeline.run({ 
    "Input 1": "This is a sample text to input node 1.",
    "Input 2": "This is a sample text to input node 2."
})
```

<!-- ملاحظات الترجمة: [Pipeline→خط معالجة حسب المسرد المعتمد] | [kept EN: Design — اسم أداة/ميزة على المنصة] | [kept EN: PipelineProvider, Pipeline — أسماء فئات برمجية] | [kept EN: AiXplainKit — اسم مكتبة] | [kept EN: aiXplain — اسم علامة تجارية] | [Run→التشغيل حسب المسرد] | [Async→غير متزامن حسب المسرد] -->
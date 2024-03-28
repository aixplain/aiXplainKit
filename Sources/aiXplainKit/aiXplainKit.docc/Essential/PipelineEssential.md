# Pipelines Essentials



## Overview

 [Design](https://aixplain.com/platform/studio/) is aiXplain’s no-code AI pipeline builder tool that accelerates AI development by providing a seamless experience to build complex AI systems and deploy them within minutes. You can visit our platform and design your own custom pipeline [here](https://platform.aixplain.com/studio).

#### Explore
The catalog of all your pipelines on aiXplain can be accessed and browsed [here](https://platform.aixplain.com/dashboard/pipelines). Details of the pipeline can be found by clicking on the pipeline card. Pipeline ID can be found from the URL or below the pipeline name (similar to models).

Once the Pipeline ID of the desired pipeline is available, it can be used to create a `Pipeline` object from the `PipelineProvider`. 
```swift
import AiXplainKit
pipeline = PipelineProvider().get("<PIPELINE_ID>") 
```

### Run
The AiXplainKit allows you to run pipelines asynchronously.

```swift
let result = try await pipeline.run("This is a sample text")
```


For multi-input pipelines, you can specify as input a dictionary where the keys are the label names of the input node and values are their corresponding content:

```swift
let result = try await pipeline.run({ 
    "Input 1": "This is a sample text to input node 1.",
    "Input 2": "This is a sample text to input node 2."
})
```

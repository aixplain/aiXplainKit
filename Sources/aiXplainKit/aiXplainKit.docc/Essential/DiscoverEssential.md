# Models Essential
Learn how to use aiXplain's ever-expanding catalog of 35,000+ ready-to-use AI models that can be used for various tasks like Translation, Speech Recognition, Diacritization, Sentiment Analysis, and much more.

## Overview

The catalog of all available models on aiXplain can be accessed and browsed [here](https://platform.aixplain.com/discovery/models). Details of each model can be found by clicking on the model card. Model ID can be found on the URL or below the model name.

Once the Model ID of the desired model is available, it can be used to create a `Model` object from the `ModelFactory`.

```swift
from aixplain.factories import ModelFactory
let model = ModelProvider().get("<MODEL_ID>") 
```

### Run
The aixplain SDK allows you to run machine learning models.

```python
let output = model.run("This is a sample text") # You can use a URL or a file path on your local machine
```

# aiXplainKit

aiXplainKit enables Swift programmers to add AI functions to their software with ease.

## Overview

aiXplainKit is a software development kit (SDK) for the [aiXplain](https://aixplain.com/) platform. With aiXplainKit, developers can quickly and easily:

- [Discover](https://aixplain.com/platform/discovery/) aiXplain’s ever-expanding catalog of 35,000+ ready-to-use AI models and utilize them.
- [Design](https://aixplain.com/platform/studio/) their own custom pipelines and run them.


## API Key Setup
Before you can use the aixplain SDK, you'll need to obtain an API key from our platform. For details refer this [Team API Key Guide<MISSING>](<doc:TeamAPIKeyGuide>).

Once you get the API key, you'll  need to add this API key as an environment variable on your system.

```swift
AiXplainKit.shared.keyManager.TEAM_API_KEY = "<Your Key>"
```

Alternatively, you can set the API key as an environment variable in Xcode. This approach keeps your API key separate from your code, which can be beneficial for security and portability. Check on how to do this on the ``APIKeyManager``

## Topics

### Essential

- [TeamAPIKeyGuide]()
- [Pipeline]()



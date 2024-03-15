# Team API Key Guide

Learn how to create and use API keys.

## How to get your keys

 [Sign up](https://platform.aixplain.com/register) or [login](https://platform.aixplain.com/login) for an account on aiXplain. Then from the Dashboard, navigate to the [Integrations](https://platform.aixplain.com/account/integrations).

![Dashboard photo](NavigateAPIKey)

### Creating a New API Key
On the **Integrations** page, you can find the **Create a team access key** button on the top right corner. You can create a new key by clicking that button, then specifiying a label and an (optional) expiry date.

### Manage API Keys
On the **Integrations** page, you can view all the existing Team API keys. You can also delete keys on this page.

### Setting the keys

An example of how to use the `APIKeyManager` to retrieve and set API keys.

To set the API keys using Xcode environment variables, follow these steps:

1. In Xcode, select your project in the Project Navigator.
2. Select your target, then click the "Info" tab.
3. Under the "Configurations" section, click the "+" button in the bottom-left corner.
4. In the newly added row, set the "Name" to the desired API key name (e.g., "TEAM_API_KEY") and the "Value" to your API key.
5. Repeat step 4 for each API key you need to set.

With the environment variables set, the `APIKeyManager` will automatically load and use the API keys from the corresponding environment variables.

You can also set the API keys directly in code if needed:

```swift
AiXplainKit.shared.keyManager.TEAM_API_KEY = "<Your Key>"
```

### Classes
- ``APIKeyManager``

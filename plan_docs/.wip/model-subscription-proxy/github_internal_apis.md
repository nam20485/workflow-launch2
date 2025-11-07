# From support thread

- api.individual.githubcopilot.com/chat/completions does not appear to encounter rate limits, in contrast with Roo Code does have rate limits.

## Roo Code uses the VS Code SDK and does not explicitly define the API Endpoint.

Intercepted Requests: intercepted requests show Roo Code (or VS Code Copilot integration) is indeed calling endpoints under api.githubcopilot.com, specifically:
- copilot-proxy.githubusercontent.com/v2/token (likely for authentication)
- api.githubcopilot.com/chat/completions
- api.githubcopilot.com/embeddings
- api.githubcopilot.com/v1/chat/completions

## Roo Code is using:
- api.githubcopilot.com endpoints, including /chat/completions and /v1/chat/completions

"API limit reached" for both Roo Code and Github Co-pilot suggests the rate limiting is tied to this standard endpoint, regardless of which client is making the request.

## We need to determine if:
- /chat/completions and /v1/chat/completions have any differences in rate limits or functionality.

Roo Code needs to determine if there are advanced options for the SDK to specify a custom API endpoint for professional and or Enterprise Co-Pilot Customers.

## Steps to reproduce
Custom extension uses api.individual.githubcopilot.com/chat/completions instead of default VSCode SDK like Roo Code.

###
Relevant API REQUEST output
- https://copilot-proxy.githubusercontent.com/v2/token (likely for authentication)
- https://api.githubcopilot.com/chat/completions
- https://api.githubcopilot.com/embeddings
- https://api.githubcopilot.com/v1/chat/completions
- https://api.individual.githubcopilot.com/chat/completions

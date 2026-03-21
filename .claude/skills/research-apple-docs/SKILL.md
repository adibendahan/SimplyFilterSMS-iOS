---
name: research-apple-docs
description: Research Apple developer documentation using the local cupertino MCP server. Starts the server, runs queries, then kills the server when done.
license: MIT
metadata:
  author: SimplyFilterSMS
  version: "1.0"
---

Research Apple developer documentation for the given topic.

**Input**: The argument after `/research-apple-docs` is the topic or question to research.

**Steps**

1. **Start the cupertino server**

   ```bash
   cupertino serve
   ```

   Run in background. Note the process ID from the output.

2. **Run research queries**

   Use the `mcp__cupertino__*` tools to research the topic:
   - `mcp__cupertino__search` — search across all Apple docs
   - `mcp__cupertino__search_symbols` — search for specific APIs/symbols
   - `mcp__cupertino__read_document` — read a specific doc page
   - `mcp__cupertino__list_frameworks` — list available frameworks
   - `mcp__cupertino__list_samples` — find sample code

   Run as many queries as needed to thoroughly answer the question.

3. **Kill the server**

   ```bash
   kill <PID>
   ```

4. **Report findings**

   Summarize what you found, including relevant API names, framework references, and any limitations or caveats.

**Guardrails**
- Always kill the server when done — never leave it running.
- If the server fails to start, report the error and stop.

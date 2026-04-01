---
name: agent-best-practices
description: Audit and proofread a Snowflake Cortex Agent's configuration (instructions, orchestration, tool descriptions, tool resources, profile) against a comprehensive best-practices checklist. Use when the user asks to review, audit, proofread, or improve an agent.
---

# Cortex Agent Best Practices Audit

## How to Use
1. Run `DESCRIBE AGENT <fully_qualified_agent_name>` to get the full agent_spec
2. If the spec is truncated, extract it in chunks using `SUBSTR($7, <offset>, 1000)` from `TABLE(RESULT_SCAN(LAST_QUERY_ID()))`
3. Evaluate every section of the agent_spec against ALL 22 checks below
4. Report findings in a table grouped by severity: Critical / High / Nice-to-have

---

## The 22-Point Checklist

### Correctness & Hygiene
1. **Typos & Spelling** — Scan all instruction text, profile display_name, tool names, and tool_resources for misspellings (e.g., "seach" → "search", "downtream" → "downstream", "VIES" → "VIEW")
2. **Orphan/Placeholder Text** — Look for dangling strings like a bare `url` on its own line, leftover TODO markers, or incomplete sentences ending with "..."
3. **Valid Tool Resource References** — Verify that semantic_view names, search_service names, and warehouse fields are non-empty and plausibly correct (no obvious typos in object names)
4. **Formatting Consistency** — Check for double spaces, inconsistent newlines, mixed bullet styles, or broken markdown

### Instruction Architecture
5. **No Cross-Layer Duplication** — Response instructions should own FORMATTING. Orchestration instructions should own ROUTING/LOGIC. Tool descriptions should own CAPABILITY SCOPE. Flag any rule that appears in more than one layer.
6. **Guardrails Positioned First** — Off-topic refusal, scope boundaries, and safety rules should appear at the TOP of orchestration instructions, not buried in the middle or end
7. **Consolidated "Do Not" Rules** — All negative constraints ("Do not speculate", "Do not suggest", etc.) should live in ONE authoritative list, not scattered across response, orchestration, and tool descriptions

### Audience & Domain Context
8. **Audience Definition Present** — Orchestration instructions should explicitly name the agent's primary users (e.g., "sales representatives, sales managers, and revenue operations teams") and state what those users value most (e.g., "fast, accurate, data-driven insights"). Without audience context, the agent cannot calibrate tone, depth, or what counts as a useful answer.
9. **Domain Context Present** — Instructions should name the specific business domain, data domains, or organization so the agent understands its world (e.g., "This catalog contains assets spanning bookings, sales, finance...")
10. **Numbers-in-Context Rule** — Orchestration or response instructions should require the agent to contextualize every metric it surfaces. Instead of reporting "win rate is 67%", the agent should say "win rate for Enterprise Suite is 67% based on 2 wins out of 3 closed deals." Raw numbers without denominator/sample context are data, not insight.

### Behavioral Controls
11. **Result Count Cap** — Instructions should explicitly limit how many results are displayed (e.g., "Return at most 5 results unless the user requests more")
12. **Explicit Tool Priority** — Orchestration should state the tool selection order clearly (e.g., "Always use Analyst first for quantitative questions; only use Search after obtaining relevant record identifiers from Analyst results")
13. **Keyword Signal Lists** — Orchestration instructions should list trigger words that map to each tool. Quantitative signals (win rate, average, total, revenue, count) → Analyst tool. Qualitative signals (concerns, objections, discussed, mentioned, conversation) → Search tool. Signal lists reduce routing errors significantly.
14. **Sequential Multi-Tool Pattern** — For questions that filter unstructured data by structured criteria (e.g., "sentiment in lost deals"), orchestration instructions must enforce the query-then-search pattern: first query Analyst to identify relevant records, then pass those identifiers into the Search query. Generic search without structured pre-filtering returns imprecise results.
15. **Empty-Results Handling** — If a structured query returns no data, the agent should report that gap honestly and NOT silently fall back to searching unstructured data (unless the question also has qualitative aspects). Empty results are meaningful signals about data coverage.
16. **Graceful Edge Cases** — Check for explicit handling of: no results found, ambiguous queries, multiple possible interpretations. Each should have template phrasing the agent can use.

### Response Quality
17. **Response Format Guidance** — Response instructions must specify structure: lead with a direct answer to the question first, then supporting details. Specify prose over bullet points; conversational responses outperform lists for human readability and trust.
18. **Concrete Citation Format** — Response instructions should require specific citations, not vague ones. "In the TechCorp discovery call" is verifiable; "according to the data" is not. Concrete citations enable users to verify claims and expose hallucinations.
19. **Number Formatting Rules** — Response instructions should standardize number display (e.g., express deal values in thousands with a K suffix: $90,000 → 90K; round percentages to whole numbers unless precision is explicitly requested).
20. **Data Limitation Transparency** — Response instructions should require the agent to flag small sample sizes. When synthesizing fewer than three data points, the agent must note this explicitly (e.g., "based on two closed Enterprise deals" rather than "Enterprise deals typically…"). This prevents overconfident generalizations from thin data.

### Infrastructure & Robustness
21. **Pinned Orchestration Model** — `models.orchestration` should be a specific model name, not `"auto"`, for deterministic behavior. Flag `"auto"` as a risk.
22. **Tuned max_results** — Check the `max_results` value on search tools. Values below 5 may be too restrictive; values above 10 may flood context. Recommend 5-6 for most catalog use cases.

---

## Output Format

Present findings grouped by severity:

**Critical** — Will cause incorrect behavior, silent failures, or broken tool calls (e.g., typo in tool_resource name, no guardrails, missing tool priority)

**High** — Will cause poor user experience or unreliable responses (e.g., no audience definition, no data limitation transparency, missing citation format, no sequential multi-tool pattern)

**Nice-to-have** — Polish and robustness improvements (e.g., keyword signal lists, number formatting rules, result count cap)

If all 22 checks pass, confirm: "All 22 best-practice checks passed."

---

## Instruction Layer Quick-Reference

Use this table to decide where a rule belongs before writing or auditing instructions.

| Layer | Owns | Does NOT own |
|---|---|---|
| **Orchestration instructions** | Tool selection logic, keyword signals, sequential patterns, scope boundaries, guardrails, audience definition | Output formatting, citation style, number formatting |
| **Response instructions** | Output format, tone, citation style, number formatting, data limitation transparency | Routing logic, tool selection, guardrails |
| **Tool descriptions** | What data the tool contains, when it is appropriate to use | Formatting rules, routing hierarchies that span multiple tools |

---

## Iteration Loop (Trace-Driven Improvement)

After testing the agent, use this loop to fix issues systematically:

1. **Identify symptom** — What did the agent do wrong? (wrong tool, bad format, speculation, vague citation)
2. **Diagnose the layer** — Wrong tool selection → fix orchestration. Poor response format → fix response instructions. Scope violation or speculation → fix boundary rules in orchestration.
3. **Write a specific fix** — Vague instructions produce inconsistent behavior. The fix should describe a pattern, state a rationale, and include an example.
4. **Retest and verify via trace** — Confirm the planning span reflects the intended tool call sequence, and the response generation span reflects the format rules.
5. **Document the pattern** — Keep a log of issues and fixes. Over time this becomes a reusable library of instruction patterns for your use cases.

---

## Semantic View Quality Checks (Bonus)

If the agent uses a Cortex Analyst tool backed by a semantic view, also verify:

- **Synonyms defined** on all key dimensions (customer name, sales stage, sales rep, product line). Without synonyms, natural language queries using alternate terminology will fail silently.
- **Custom measures present** for any KPI that requires a formula (e.g., win rate = SUM(CASE WHEN win_status = true THEN 1 ELSE 0 END) / COUNT(*)). Default aggregations on raw columns are not sufficient.
- **Sample values enabled** on the semantic view so Cortex Analyst can infer data ranges and value formats.
- **AI-generated descriptions enabled** on tables and columns to reduce ambiguity in query planning.

---

## Additional Notes
- Always extract the FULL agent_spec before auditing — truncated specs will miss issues
- Pay special attention to tool_resources section as typos there cause silent failures
- Check the profile section too (display_name, comment)
- If the agent has a Cortex Analyst tool, verify the semantic_view reference exists and run the Semantic View Quality Checks above
- Non-determinism is normal — agents may take different paths to the same answer. If a use case requires highly consistent behavior, add more detailed orchestration instructions with explicit step-by-step patterns and examples

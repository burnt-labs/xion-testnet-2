# Release Documentation Prompts

This directory contains the prompt templates used by the automated release documentation workflow in `.github/workflows/create-release.yml`.

## Files

### `claude-api-prompt.md`
The main prompt template used when calling the Claude API to generate comprehensive upgrade documentation. This prompt instructs Claude to analyze GitHub comparison data and create detailed, professional upgrade guides.

### `fallback-template.md`
A simplified template used as a fallback when the Claude API is unavailable or fails. This provides a basic structure for upgrade documentation with placeholders for manual completion.

## Placeholder Variables

Both templates use placeholder variables that are automatically replaced by the workflow:

- `{{RELEASE_TAG}}` - The full release tag (e.g., `v22.0.0`)
- `{{CALCULATED_HEIGHT}}` - The calculated upgrade block height
- `{{PREVIOUS_VERSION}}` - The previous release version for comparison

## Usage

These templates are automatically loaded by the GitHub Actions workflow:

```bash
# Load and process the Claude API prompt
PROMPT=$(cat ./prompts/claude-api-prompt.md)
PROMPT="${PROMPT//\{\{RELEASE_TAG\}\}/$RELEASE_TAG}"
PROMPT="${PROMPT//\{\{CALCULATED_HEIGHT\}\}/$CALCULATED_HEIGHT}"
PROMPT="${PROMPT//\{\{PREVIOUS_VERSION\}\}/$PREVIOUS_VERSION}"

# Load and process the fallback template
FALLBACK_TEMPLATE=$(cat ./prompts/fallback-template.md)
# ... similar variable substitution
```

## Editing Guidelines

### For `claude-api-prompt.md`:
- Keep the prompt comprehensive but focused
- Include clear instructions for handling future releases
- Maintain the professional tone and technical accuracy requirements
- Ensure proper markdown formatting guidelines are included

### For `fallback-template.md`:
- Keep it simple and functional
- Use placeholder text that's clearly marked for manual replacement
- Focus on essential upgrade information
- Ensure all critical safety warnings are included

## Template Syntax

- Use `{{VARIABLE_NAME}}` for placeholders that will be replaced by the workflow
- Use proper markdown syntax for code blocks: ` ```bash ` 
- Keep line lengths reasonable for readability

## Future Releases Support

Both templates are designed to handle future releases where:
- Release binaries don't exist yet
- GitHub comparison data is incomplete
- Checksums are not available

Templates should gracefully acknowledge these limitations and provide appropriate guidance for preparation and monitoring.
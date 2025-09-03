# Release Documentation Prompts

This directory contains the prompt templates used by the automated release documentation workflow in `.github/workflows/create-release.yml`.

## Files

### `claude-api-prompt.md`
The main prompt template used when calling the Claude API to generate comprehensive release notes. This prompt instructs Claude to analyze GitHub comparison data and create detailed, professional release documentation.

### `release_notes_template.md` (in templates/ directory)
The release notes template that serves as both the target for AI-generated content and the fallback when AI generation fails. Contains placeholder values that are replaced with actual content when AI succeeds, or remain as placeholders for manual completion when AI fails.

## Placeholder Variables

The templates use placeholder variables that are automatically replaced by the workflow:

- `{{RELEASE_TAG}}` - The full release tag (e.g., `v22.0.0`)
- `{{CALCULATED_HEIGHT}}` - The calculated upgrade block height
- `{{PREVIOUS_VERSION}}` - The previous release version for comparison

## Usage

The workflow follows this simplified flow:

1. **Claude API succeeds** → AI-generated content replaces `release_notes_template.md`
2. **Claude API fails** → `release_notes_template.md` keeps its placeholder values
3. **Script uses template** → Copies the template (with or without AI content) to final release notes file

```bash
# Load and process the Claude API prompt
PROMPT=$(cat ./prompts/claude-api-prompt.md)
PROMPT="${PROMPT//\{\{RELEASE_TAG\}\}/$RELEASE_TAG}"
PROMPT="${PROMPT//\{\{CALCULATED_HEIGHT\}\}/$CALCULATED_HEIGHT}"
PROMPT="${PROMPT//\{\{PREVIOUS_VERSION\}\}/$PREVIOUS_VERSION}"

# If AI succeeds: copy AI content to template
# If AI fails: template keeps placeholder values
```

## Editing Guidelines

### For `claude-api-prompt.md`:
- Keep the prompt comprehensive but focused
- Include clear instructions for handling future releases
- Maintain the professional tone and technical accuracy requirements
- Ensure proper markdown formatting guidelines are included

### For `release_notes_template.md`:
- Use placeholder text that's clearly marked for manual replacement (e.g., `[--ADD-HERE-DESCRIPTION--]`)
- Structure it like actual release notes (changelog, contributors, upgrade info)
- Include all necessary sections: Overview, What's Changed, Upgrade Information, etc.
- Ensure Mintscan links are properly formatted

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
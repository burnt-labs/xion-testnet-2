# Release Documentation Prompts

This directory contains the prompt templates used by the automated release documentation workflow.

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
- Escape special characters that might interfere with shell processing
- Keep line lengths reasonable for readability

## Workflow Integration

The templates are loaded and processed by the GitHub Actions workflow:

1. The workflow reads the template file using `cat`
2. Placeholder variables are replaced using bash string substitution
3. The processed content is used either as a Claude API prompt or as direct template output

## Maintenance

When updating templates:

1. **Test locally first**: Verify that placeholder substitution works correctly
2. **Check formatting**: Ensure markdown syntax is preserved after variable substitution  
3. **Validate shell escaping**: Make sure special characters don't break the workflow
4. **Review output**: Test with both successful and failed Claude API scenarios

## Future Releases Support

Both templates are designed to handle future releases where:
- Release binaries don't exist yet
- GitHub comparison data is incomplete
- Checksums are not available

Templates should gracefully acknowledge these limitations and provide appropriate guidance for preparation and monitoring.

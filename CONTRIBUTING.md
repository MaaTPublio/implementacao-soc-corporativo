# Contributing to SOC Lab Implementation

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in the [Issues](https://github.com/MaaTPublio/implementacao-lab-soc/issues) section
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (OS, Wazuh version, pfSense version)
   - Relevant logs or screenshots

### Submitting Changes

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding standards below
   - Add tests if applicable
   - Update documentation
   - Test your changes

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```
   
   Use clear commit messages:
   - `feat: Add new feature`
   - `fix: Fix bug in script`
   - `docs: Update documentation`
   - `style: Format code`
   - `refactor: Refactor code`
   - `test: Add tests`

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Describe what your PR does
   - Reference any related issues
   - Wait for review

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Add comments for complex logic
- Use meaningful variable names
- Include error handling with `set -e`
- Add usage information in comments
- Make scripts executable: `chmod +x script.sh`

Example:
```bash
#!/bin/bash
# Script description
# Usage: ./script.sh <arg1> <arg2>

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <arg1> <arg2>"
    exit 1
fi

# Main logic
```

### XML Configuration

- Use proper indentation (2 spaces)
- Add comments for complex rules
- Group related configurations
- Validate XML syntax

Example:
```xml
<!-- Rule description -->
<rule id="100100" level="5">
  <if_sid>5551</if_sid>
  <description>Meaningful description</description>
  <group>category,</group>
</rule>
```

### Documentation

- Use Markdown format
- Include code examples
- Add screenshots for UI changes
- Keep language clear and concise
- Update table of contents if needed
- Use Portuguese for main docs (this is a Brazilian project)

## What to Contribute

### Priority Areas

1. **Custom Rules and Decoders**
   - pfSense log parsing improvements
   - New attack detection patterns
   - Better correlation rules

2. **Scripts**
   - Automation scripts
   - Deployment helpers
   - Testing utilities

3. **Documentation**
   - Tutorial improvements
   - Translation (PT-BR ↔ EN)
   - Use case examples
   - Troubleshooting guides

4. **Dashboards**
   - New visualizations
   - Dashboard templates
   - Alert configurations

5. **Integration**
   - New tool integrations
   - API improvements
   - Webhook examples

### Areas for Improvement

- Performance optimization
- Security enhancements
- Better error handling
- Additional testing
- Code refactoring

## Testing

Before submitting:

1. **Test your changes**
   - Run scripts in a test environment
   - Verify XML syntax
   - Check for errors in logs

2. **Document testing**
   - Describe how you tested
   - Include test results
   - Note any limitations

3. **Security testing**
   - No hardcoded credentials
   - No security vulnerabilities
   - Follow security best practices

## Code Review Process

1. Maintainer reviews PR
2. Feedback provided if needed
3. You make requested changes
4. Maintainer approves and merges
5. Changes deployed to main branch

## Community Guidelines

- Be respectful and constructive
- Help others in discussions
- Share knowledge and experiences
- Follow code of conduct

## Questions?

- Open an [Issue](https://github.com/MaaTPublio/implementacao-lab-soc/issues) for questions
- Check existing documentation
- Review closed issues for solutions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing! 🎉

# Contributing to macOS Server Optimisation Toolkit

First off, thank you for considering contributing to this project! Your help makes this toolkit better for everyone running macOS servers.

## Table of contents

- [Code of conduct](#code-of-conduct)
- [How can I contribute?](#how-can-i-contribute)
  - [Reporting bugs](#reporting-bugs)
  - [Suggesting enhancements](#suggesting-enhancements)
  - [Testing on different hardware](#testing-on-different-hardware)
  - [Improving documentation](#improving-documentation)
  - [Submitting code changes](#submitting-code-changes)
- [Development setup](#development-setup)
- [Coding standards](#coding-standards)
- [Commit message guidelines](#commit-message-guidelines)
- [Pull request process](#pull-request-process)
- [Issue guidelines](#issue-guidelines)
- [Documentation standards](#documentation-standards)
- [Security vulnerabilities](#security-vulnerabilities)
- [Recognition](#recognition)

## Code of conduct

This project follows a simple code of conduct:

- **Be respectful** — Treat everyone with respect and kindness
- **Be constructive** — Offer helpful feedback and suggestions
- **Be patient** — Remember that maintainers are volunteers
- **Be inclusive** — Welcome newcomers and help them contribute

## How can I contribute?

### Reporting bugs

Before submitting a bug report:

1. **Check existing issues** — Search [open issues](../../issues) to see if it's already reported
2. **Verify the bug** — Ensure it's reproducible and not a configuration issue
3. **Collect information** — Gather details about your environment

When submitting a bug report, include:

```markdown
**Environment:**
- macOS version: (e.g., 15.7.3 Sequoia)
- Hardware: (e.g., Mac mini 8,1, Intel i7)
- SIP status: (enabled/disabled)
- Script version: (run `./optimise.sh --version`)

**Description:**
Clear description of the bug.

**Steps to reproduce:**
1. Step one
2. Step two
3. ...

**Expected behaviour:**
What you expected to happen.

**Actual behaviour:**
What actually happened.

**Logs:**
Attach relevant logs from `logs/optimisation_*.log`
```

### Suggesting enhancements

Enhancement suggestions are welcome! Before submitting:

1. **Check existing requests** — Search issues for similar suggestions
2. **Consider scope** — Does it fit the project's purpose (server optimisation)?
3. **Provide context** — Explain the use case and benefits

Include in your suggestion:

- **Problem statement** — What limitation or need does this address?
- **Proposed solution** — How would you implement it?
- **Alternatives considered** — What other approaches did you consider?
- **Additional context** — Screenshots, links to documentation, etc.

### Testing on different hardware

We especially welcome testing on:

- **Apple Silicon Macs** (M1, M2, M3, M4 series)
- **Different macOS versions** (15.0 - 15.x)
- **Different Mac models** (iMac, Mac Pro, MacBook Pro in clamshell mode)

When reporting test results:

```markdown
**Hardware tested:**
- Model: (e.g., Mac Studio M2 Max)
- Chip: (e.g., Apple M2 Max)
- RAM: (e.g., 32GB)

**macOS version:** 15.x.x

**Test results:**
- [ ] Script runs without errors
- [ ] Services disable correctly
- [ ] Network tuning applies
- [ ] Power settings apply
- [ ] Backup/restore works
- [ ] No system instability observed

**Notes:**
Any observations, warnings, or issues encountered.
```

### Improving documentation

Documentation improvements are highly valued:

- Fix typos and grammatical errors
- Clarify confusing explanations
- Add missing information
- Update outdated content
- Add examples and use cases
- Improve code comments

### Submitting code changes

Code contributions should:

1. Follow the [coding standards](#coding-standards)
2. Include appropriate tests (manual testing steps at minimum)
3. Update documentation if behaviour changes
4. Not break existing functionality

## Development setup

### Prerequisites

- macOS 15.x (Sequoia) — or VM for testing
- Bash 3.2+ (macOS default)
- Git
- A test environment (VM recommended for destructive testing)

### Getting started

```bash
# Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/macos-optimisation-script.git
cd macos-optimisation-script

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ...

# Test your changes (always use --dry-run first!)
./optimise.sh --dry-run --verbose

# Run shellcheck for linting (if installed)
shellcheck optimise.sh backup_settings.sh restore.sh
```

### Testing safely

> **Warning:** Never test on production systems without backups!

1. **Use dry-run mode** — Always test with `--dry-run` first
2. **Use a VM** — Test destructive changes in a virtual machine
3. **Check logs** — Review `logs/` for any warnings or errors
4. **Test restore** — Verify backup/restore works before and after changes

## Coding standards

### Bash style guide

Follow these conventions for consistency:

```bash
# Use strict mode
set -euo pipefail

# Use lowercase for local variables
local my_variable="value"

# Use UPPERCASE for constants and exports
readonly CONFIG_DIR="/etc/myapp"
export PATH

# Use snake_case for function names
my_function_name() {
    # Function body
}

# Quote all variable expansions
echo "${variable}"
command --option="${value}"

# Use [[ ]] for conditionals (not [ ])
if [[ -f "${file}" ]]; then
    # ...
fi

# Use $(command) for command substitution (not backticks)
result=$(some_command)
```

### Script structure

Scripts should follow this structure:

```bash
#!/usr/bin/env bash
# Description of what the script does
# Usage: ./script.sh [options]

set -euo pipefail

# ============================================================================
# Constants and defaults
# ============================================================================

readonly VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Utility functions
# ============================================================================

log_info() { ... }
log_error() { ... }

# ============================================================================
# Core functions
# ============================================================================

main() {
    # Main logic
}

# ============================================================================
# Entry point
# ============================================================================

main "$@"
```

### Configuration file formats

**services.conf** (pipe-delimited):
```
# Comment explaining the service
DOMAIN|SERVICE_NAME|CATEGORY|DESCRIPTION
```

**sysctl.conf** (key=value):
```
# Comment explaining the parameter
key=value
```

**defaults.conf** (pipe-delimited):
```
# Comment explaining the preference
DOMAIN|KEY|TYPE|VALUE|DESCRIPTION
```

## Commit message guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change that neither fixes nor adds |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks |

### Examples

```bash
# Feature
feat(services): add support for disabling Handoff

# Bug fix
fix(restore): handle missing manifest.json gracefully

# Documentation
docs(README): add Apple Silicon compatibility notes

# Refactoring
refactor(backup): extract plist export to separate function
```

## Pull request process

### Before submitting

1. **Ensure tests pass** — Run `./optimise.sh --dry-run` without errors
2. **Run shellcheck** — Fix any linting warnings
3. **Update documentation** — If behaviour changes
4. **Rebase on main** — Keep your branch up to date

### Submission checklist

- [ ] Code follows project style guidelines
- [ ] Self-reviewed my own code
- [ ] Added comments for complex logic
- [ ] Updated documentation if needed
- [ ] Tested on macOS (specify version)
- [ ] No new warnings from shellcheck
- [ ] Commit messages follow guidelines

### PR template

```markdown
## Description
Brief description of changes.

## Type of change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Testing performed
- macOS version tested:
- Hardware tested on:
- Test steps:
  1. ...
  2. ...

## Checklist
- [ ] My code follows the project style guidelines
- [ ] I have tested my changes
- [ ] I have updated documentation accordingly
- [ ] My changes don't introduce new warnings
```

### Review process

1. **Automated checks** — Must pass (if configured)
2. **Maintainer review** — At least one approval required
3. **Address feedback** — Respond to review comments
4. **Merge** — Maintainer merges after approval

## Issue guidelines

### Good issue titles

```
# Good
fix: restore.sh fails when backup contains spaces in paths
feat: add support for disabling Universal Control
docs: clarify SIP requirements for Apple Silicon

# Bad
It doesn't work
Bug
Help needed
```

### Labels

| Label | Description |
|-------|-------------|
| `bug` | Something isn't working |
| `enhancement` | New feature request |
| `documentation` | Documentation improvements |
| `good first issue` | Good for newcomers |
| `help wanted` | Extra attention needed |
| `apple-silicon` | Apple Silicon related |
| `intel` | Intel Mac related |
| `wontfix` | Will not be addressed |

## Documentation standards

### Citations required

When adding claims about macOS behaviour:

1. **Cite authoritative sources** — Apple docs, man pages, RFCs
2. **Link to source** — Include URL
3. **Mark unverified claims** — Use warning callout

Example:
```markdown
According to [Apple Support HT202528](https://support.apple.com/en-us/101992),
serverperfmode is only available on Intel-based Macs.

> **Note:** The following is based on community testing and is not officially
> documented by Apple.
```

### Technical accuracy

- Verify claims before documenting
- Test commands before including them
- Include macOS version when behaviour is version-specific
- Acknowledge when documentation is based on reverse engineering

## Security vulnerabilities

**Do not open public issues for security vulnerabilities.**

Instead:

1. Email the maintainer directly (see Author section in README)
2. Include detailed description of the vulnerability
3. Provide steps to reproduce if possible
4. Allow reasonable time for a fix before disclosure

## Recognition

Contributors are recognised in the following ways:

- **Git history** — Your commits are permanently recorded
- **Release notes** — Significant contributions mentioned in changelog
- **Contributors list** — Added to repository contributors

### Hall of fame

Special recognition for:

- First-time contributors
- Major feature implementations
- Significant documentation improvements
- Extensive testing on new hardware

---

## Questions?

If you have questions about contributing:

1. Check existing [issues](../../issues) and [discussions](../../discussions)
2. Open a new discussion for general questions
3. Open an issue for specific bugs or feature requests

Thank you for contributing!

# version.mk
# Generic version management for builds (CMake, Docker, Make, etc.)
#
# NOTE: This uses the same git commands as VersionCommon.cmake to ensure consistency.
# The git commands here are functionally equivalent to VersionCommon.cmake:
#   - git rev-parse --abbrev-ref HEAD (for branch)
#   - git rev-parse --short=7 HEAD (for commit hash, equivalent to substring of full hash)
#   - git diff-index --quiet HEAD -- (for dirty detection)
#
# Provides version variables (exported with VER_ prefix):
#   VER_SEMVER        - semantic version from VERSION file (e.g., "0.1.0")
#   VER_GIT_COMMIT    - short git commit hash (e.g., "abc1234")
#   VER_GIT_BRANCH    - current git branch (e.g., "main")
#   VER_BUILD_TIME    - ISO 8601 timestamp (e.g., "2025-01-15 10:30:00")
#   VER_GIT_DIRTY     - "-dirty" if working tree has changes, "" otherwise
#   VER_VERSION_FULL  - complete version string (e.g., "0.1.0-abc1234-dirty")
#
# Provides targets:
#   version-info       - print all version information
#   version-semver     - print VER_SEMVER
#   version-commit     - print VER_GIT_COMMIT
#   version-branch     - print VER_GIT_BRANCH
#   version-full       - print VER_VERSION_FULL
#   version-build-time - print VER_BUILD_TIME

# VERSION file path (resolves in the working directory of the includer)
VERSION_FILE ?= VERSION

# Git command (can be overridden if needed)
GIT ?= git

# Extract version information using git commands (equivalent to VersionCommon.cmake)
VER_SEMVER        := $(shell test -f $(VERSION_FILE) && cat $(VERSION_FILE) || echo "0.0.0")
VER_GIT_COMMIT    := $(shell $(GIT) rev-parse --short=7 HEAD 2>/dev/null || echo "unknown")
VER_GIT_BRANCH    := $(shell $(GIT) rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
VER_BUILD_TIME    := $(shell date -u +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
# Check if git working tree is dirty (same logic as VersionCommon.cmake git_local_changes())
VER_GIT_DIRTY     := $(shell $(GIT) diff-index --quiet HEAD -- 2>/dev/null || echo "-dirty")
VER_VERSION_FULL  := $(VER_SEMVER)-$(VER_GIT_COMMIT)$(VER_GIT_DIRTY)

# Export variables for use by other makefiles
export VER_SEMVER
export VER_GIT_COMMIT
export VER_GIT_BRANCH
export VER_BUILD_TIME
export VER_GIT_DIRTY
export VER_VERSION_FULL

# Phony targets for querying version information
.PHONY: version version-info version-semver version-commit version-branch version-full version-build-time version-json version-validate

version:
	@echo "Version Management Targets:"
	@echo "  version-info       - Show all version information"
	@echo "  version-semver     - Print semantic version (e.g., 0.1.0)"
	@echo "  version-commit     - Print git commit hash (e.g., abc1234)"
	@echo "  version-branch     - Print git branch (e.g., main)"
	@echo "  version-full       - Print complete version string (e.g., 0.1.0-abc1234-dirty)"
	@echo "  version-build-time - Print build timestamp"
	@echo "  version-json       - Output version info as JSON"
	@echo "  version-validate   - Validate semantic version format"
	@echo ""
	@echo "Current version: $(VER_VERSION_FULL)"

version-semver:
	@echo "$(VER_SEMVER)"

version-commit:
	@echo "$(VER_GIT_COMMIT)"

version-branch:
	@echo "$(VER_GIT_BRANCH)"

version-full:
	@echo "$(VER_VERSION_FULL)"

version-build-time:
	@echo "$(VER_BUILD_TIME)"

version-info:
	@echo "Version Information:"
	@echo "  VER_SEMVER:       $(VER_SEMVER)"
	@echo "  VER_GIT_COMMIT:   $(VER_GIT_COMMIT)"
	@echo "  VER_GIT_BRANCH:   $(VER_GIT_BRANCH)"
	@echo "  VER_BUILD_TIME:   $(VER_BUILD_TIME)"
	@echo "  VER_GIT_DIRTY:    $(VER_GIT_DIRTY)"
	@echo "  VER_VERSION_FULL: $(VER_VERSION_FULL)"

version-json:
	@echo '{"semver":"$(VER_SEMVER)","commit":"$(VER_GIT_COMMIT)","branch":"$(VER_GIT_BRANCH)","build_time":"$(VER_BUILD_TIME)","dirty":"$(VER_GIT_DIRTY)","full":"$(VER_VERSION_FULL)"}'

version-validate:
	@if echo "$(VER_SEMVER)" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$$'; then \
		echo "✓ Version $(VER_SEMVER) is valid semantic version"; \
	else \
		echo "✗ Version $(VER_SEMVER) is NOT a valid semantic version" >&2; \
		echo "  Expected format: MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]" >&2; \
		echo "  Examples: 0.1.0, 0.1.0-alpha, 0.1.0-beta.1, 0.1.0+build.123" >&2; \
		exit 1; \
	fi

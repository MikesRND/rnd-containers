# Version Management Usage Examples

This document demonstrates how to use the enhanced `version.mk` in various programming languages and scenarios.

## Make Targets

### Basic Usage

```bash
# Show all version info
make version-info

# Get specific values
make version-semver     # 0.0.6
make version-commit     # f76a710
make version-full       # 0.0.6-f76a710-dirty

# Validate version format
make version-validate

# Get JSON output
make version-json
```

## JSON Integration Examples

### Python
```python
import subprocess
import json

def get_version_info():
    """Get version information from Make"""
    result = subprocess.run(
        ["make", "-f", "version.mk", "version-json"],
        capture_output=True,
        text=True,
        check=True
    )
    return json.loads(result.stdout)

# Usage
version = get_version_info()
print(f"Version: {version['full']}")
print(f"Commit: {version['commit']}")
```

### Go
```go
package main

import (
    "encoding/json"
    "fmt"
    "os/exec"
)

type VersionInfo struct {
    Semver    string `json:"semver"`
    Commit    string `json:"commit"`
    Branch    string `json:"branch"`
    BuildTime string `json:"build_time"`
    Dirty     string `json:"dirty"`
    Full      string `json:"full"`
}

func GetVersionInfo() (*VersionInfo, error) {
    cmd := exec.Command("make", "-f", "version.mk", "version-json")
    output, err := cmd.Output()
    if err != nil {
        return nil, err
    }

    var version VersionInfo
    if err := json.Unmarshal(output, &version); err != nil {
        return nil, err
    }

    return &version, nil
}

func main() {
    version, err := GetVersionInfo()
    if err != nil {
        panic(err)
    }
    fmt.Printf("Version: %s\n", version.Full)
}
```

### Node.js/JavaScript
```javascript
const { execSync } = require('child_process');

function getVersionInfo() {
    const output = execSync('make -f version.mk version-json', { encoding: 'utf8' });
    return JSON.parse(output);
}

// Usage
const version = getVersionInfo();
console.log(`Version: ${version.full}`);
console.log(`Branch: ${version.branch}`);
```

### Rust
```rust
use std::process::Command;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct VersionInfo {
    semver: String,
    commit: String,
    branch: String,
    build_time: String,
    dirty: String,
    full: String,
}

fn get_version_info() -> Result<VersionInfo, Box<dyn std::error::Error>> {
    let output = Command::new("make")
        .args(&["-f", "version.mk", "version-json"])
        .output()?;

    let json_str = String::from_utf8(output.stdout)?;
    let version: VersionInfo = serde_json::from_str(&json_str)?;

    Ok(version)
}

fn main() {
    match get_version_info() {
        Ok(version) => println!("Version: {}", version.full),
        Err(e) => eprintln!("Error: {}", e),
    }
}
```

### Bash/Shell Script
```bash
#!/bin/bash

# Get JSON and parse with jq (if available)
if command -v jq &> /dev/null; then
    VERSION_JSON=$(make -f version.mk version-json)
    SEMVER=$(echo "$VERSION_JSON" | jq -r .semver)
    COMMIT=$(echo "$VERSION_JSON" | jq -r .commit)
    echo "Version: $SEMVER (commit: $COMMIT)"
else
    # Fallback to individual targets
    SEMVER=$(make -f version.mk version-semver)
    COMMIT=$(make -f version.mk version-commit)
    echo "Version: $SEMVER (commit: $COMMIT)"
fi
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Get Version Info
  id: version
  run: |
    VERSION_JSON=$(make version-json)
    echo "version_json=$VERSION_JSON" >> $GITHUB_OUTPUT
    echo "semver=$(make version-semver)" >> $GITHUB_OUTPUT
    echo "commit=$(make version-commit)" >> $GITHUB_OUTPUT

- name: Validate Version
  run: make version-validate
```

### Docker Build
```dockerfile
# Multi-stage build with version info
FROM alpine:latest AS version
RUN apk add --no-cache make git
COPY version.mk VERSION ./
RUN make version-json > /version.json

FROM your-base-image
COPY --from=version /version.json /etc/app-version.json
```

## Version Validation in Pre-commit Hook

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
make version-validate || {
    echo "Error: Invalid semantic version in VERSION file"
    exit 1
}
```

## Embedding Version in Applications

### C/C++ with CMake
```cmake
# Get version at configure time
execute_process(
    COMMAND make -f ${CMAKE_SOURCE_DIR}/version.mk version-full
    OUTPUT_VARIABLE APP_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

add_definitions(-DAPP_VERSION="${APP_VERSION}")
```

### Python setuptools
```python
# setup.py
import subprocess

def get_version():
    result = subprocess.run(
        ["make", "-f", "version.mk", "version-semver"],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()

setup(
    name="your-package",
    version=get_version(),
    # ...
)
```

## Standardization Across Repositories

To use this versioning system across multiple repositories:

1. **Copy the version.mk file** to each repository
2. **Create a VERSION file** with your semantic version
3. **Ensure git is available** in your build environment
4. **Use the same targets** consistently across all repos

This provides a uniform interface regardless of the programming language or build system used in each repository.
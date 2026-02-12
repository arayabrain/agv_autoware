#!/bin/bash
# Disable agnocast to prevent kernel panic issues
# This script comments out agnocast-related configurations and excludes dependent packages from build

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Disabling agnocast..."

# 1. Comment out agnocast role in ansible/playbooks/universe.yaml
UNIVERSE_YAML="$SCRIPT_DIR/ansible/playbooks/universe.yaml"
if [ -f "$UNIVERSE_YAML" ]; then
    if grep -q "^    - role: autoware.dev_env.agnocast" "$UNIVERSE_YAML"; then
        sed -i \
            -e 's/^    - role: autoware.dev_env.agnocast/    # NOTE: agnocast is disabled due to kernel panic issues\n    # - role: autoware.dev_env.agnocast/' \
            -e 's/^      when: rosdistro == '\''humble'\''/    #   when: rosdistro == '\''humble'\''/' \
            "$UNIVERSE_YAML"
        echo "  - Commented out agnocast role in $UNIVERSE_YAML"
    else
        echo "  - agnocast role already commented out in $UNIVERSE_YAML"
    fi
fi

# 2. Comment out agnocast repository in repositories/autoware.repos
AUTOWARE_REPOS="$SCRIPT_DIR/repositories/autoware.repos"
if [ -f "$AUTOWARE_REPOS" ]; then
    if grep -q "^  middleware/external/agnocast:" "$AUTOWARE_REPOS"; then
        sed -i \
            -e 's|^  middleware/external/agnocast:|  # NOTE: agnocast is disabled due to kernel panic issues\n  # middleware/external/agnocast:|' \
            -e 's|^    type: git$|  #   type: git|' \
            -e 's|^    url: https://github.com/tier4/agnocast.git$|  #   url: https://github.com/tier4/agnocast.git|' \
            -e 's|^    version: 2.1.2$|  #   version: 2.1.2|' \
            "$AUTOWARE_REPOS"
        echo "  - Commented out agnocast repository in $AUTOWARE_REPOS"
    else
        echo "  - agnocast repository already commented out in $AUTOWARE_REPOS"
    fi
fi

# 3. Add COLCON_IGNORE to packages that depend on agnocastlib
PACKAGES=(
    "src/universe/autoware_universe/sensing/autoware_cuda_pointcloud_preprocessor"
    "src/universe/autoware_universe/common/autoware_agnocast_wrapper"
)

for pkg in "${PACKAGES[@]}"; do
    PKG_PATH="$SCRIPT_DIR/$pkg"
    if [ -d "$PKG_PATH" ]; then
        if [ ! -f "$PKG_PATH/COLCON_IGNORE" ]; then
            touch "$PKG_PATH/COLCON_IGNORE"
            echo "  - Added COLCON_IGNORE to $pkg"
        else
            echo "  - COLCON_IGNORE already exists in $pkg"
        fi
    else
        echo "  - Package directory not found: $pkg (skipped)"
    fi
done

echo "Done. agnocast has been disabled."

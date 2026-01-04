#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <sbom.spdx.json> <enrichment.json>"
	exit 1
fi

SBOM_FILE="$1"
ENRICHMENT_FILE="$2"

if [ ! -f "${SBOM_FILE}" ]; then
	echo "ERROR: SBOM file not found: ${SBOM_FILE}"
	exit 1
fi

if [ ! -f "${ENRICHMENT_FILE}" ]; then
	echo "ERROR: Enrichment file not found: ${ENRICHMENT_FILE}"
	exit 1
fi

echo "=== Enriching SBOM with manual license metadata ==="

jq --slurpfile enrichment "${ENRICHMENT_FILE}" '
  .packages |= map(
    . as $pkg |
    ($enrichment[0].packages[.name] // {}) as $override |
    if ($override | length) > 0 then
      . + {
        licenseDeclared: ($override.licenseDeclared // .licenseDeclared),
        licenseConcluded: ($override.licenseConcluded // .licenseConcluded)
      } + (
        if $override.sourceInfo then 
          {comment: "License source: \($override.sourceInfo)"} 
        else 
          {} 
        end
      )
    else
      .
    end
  )
' "${SBOM_FILE}" >"${SBOM_FILE}.enriched"

mv "${SBOM_FILE}.enriched" "${SBOM_FILE}"

echo "✓ SBOM enriched with manual license data"
echo ""
echo "=== Updated License Summary ==="
jq -r '.packages[] | "\(.name): \(.licenseConcluded // .licenseDeclared // "NOASSERTION")"' "${SBOM_FILE}"

package main

import future.keywords.in

# Deny if any CRITICAL vulnerability is found and not fixed
deny[msg] {
    some result in input.Results
    some vulnerability in result.Vulnerabilities
    vulnerability.Severity == "CRITICAL"
    vulnerability.Status != "fixed"
    msg := sprintf(
        "Critical vulnerability %s found in package %s, installed version %s",
        [
            vulnerability.VulnerabilityID,
            vulnerability.PkgName,
            vulnerability.InstalledVersion
        ]
    )
}

# Warn if any HIGH vulnerability is found
warn[msg] {
    some result in input.Results
    some vulnerability in result.Vulnerabilities
    vulnerability.Severity == "HIGH"
    msg := sprintf(
        "High vulnerability %s found in package %s",
        [
            vulnerability.VulnerabilityID,
            vulnerability.PkgName
        ]
    )
}

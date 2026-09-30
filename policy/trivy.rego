package main

deny contains msg if {
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

warn contains msg if {
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

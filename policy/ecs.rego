package main

deny contains msg if {
    input.networkMode != "awsvpc"
    msg := "ECS task definition must use awsvpc network mode"
}

deny contains msg if {
    not input.requiresCompatibilities[_] == "FARGATE"
    msg := "ECS task definition must include FARGATE compatibility"
}

deny contains msg if {
    some container in input.containerDefinitions
    not container.readonlyRootFilesystem
    msg := sprintf(
        "Container %s must use a read-only root filesystem",
        [container.name]
    )
}

deny contains msg if {
    some container in input.containerDefinitions
    not container.user
    msg := sprintf(
        "Container %s must define a non-root user",
        [container.name]
    )
}

deny contains msg if {
    some container in input.containerDefinitions
    container.user == "0"
    msg := sprintf(
        "Container %s must not run as root",
        [container.name]
    )
}

deny contains msg if {
    some container in input.containerDefinitions
    not container.healthCheck
    msg := sprintf(
        "Container %s must define an ECS health check",
        [container.name]
    )
}

deny contains msg if {
    some container in input.containerDefinitions
    not container.logConfiguration
    msg := sprintf(
        "Container %s must define log configuration",
        [container.name]
    )
}

deny contains msg if {
    some container in input.containerDefinitions
    some environment in container.environment
    regex.match(
        "(?i).*(password|secret|token|access_key).*",
        environment.name
    )
    msg := sprintf(
        "Possible secret %s must not be stored as plain environment data",
        [environment.name]
    )
}

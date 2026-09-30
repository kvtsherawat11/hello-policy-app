package main

import future.keywords.in

# Require awsvpc network mode
deny[msg] {
    input.networkMode != "awsvpc"
    msg := "ECS task definition must use awsvpc network mode"
}

# Require FARGATE compatibility
deny[msg] {
    not fargate_compatibility
    msg := "ECS task definition must include FARGATE compatibility"
}

fargate_compatibility {
    some c in input.requiresCompatibilities
    c == "FARGATE"
}

# Require read-only root filesystem
deny[msg] {
    some container in input.containerDefinitions
    not container.readonlyRootFilesystem
    msg := sprintf("Container %s must use a read-only root filesystem", [container.name])
}

# Require non-root user defined
deny[msg] {
    some container in input.containerDefinitions
    not container.user
    msg := sprintf("Container %s must define a non-root user", [container.name])
}

# Disallow root user
deny[msg] {
    some container in input.containerDefinitions
    container.user == "0"
    msg := sprintf("Container %s must not run as root", [container.name])
}

# Require health check
deny[msg] {
    some container in input.containerDefinitions
    not container.healthCheck
    msg := sprintf("Container %s must define an ECS health check", [container.name])
}

# Require log configuration
deny[msg] {
    some container in input.containerDefinitions
    not container.logConfiguration
    msg := sprintf("Container %s must define log configuration", [container.name])
}

# Disallow secrets in environment variables
deny[msg] {
    some container in input.containerDefinitions
    some environment in container.environment
    regex.match("(?i).*(password|secret|token|access_key).*", environment.name)
    msg := sprintf("Possible secret %s must not be stored as plain environment data", [environment.name])
}

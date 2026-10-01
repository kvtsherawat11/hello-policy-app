package dockerfile

import future.keywords.in

# Rule: Disallow 'latest' tag in FROM
deny[msg] {
    some i
    input[i].Cmd == "from"
    lower(input[i].Value[0]) == "latest"
    msg := "Docker base image must use the latest tag"
}

# Rule: Disallow ADD, recommend COPY
deny[msg] {
    some i
    input[i].Cmd == "add"
    msg := sprintf("Use COPY instead of ADD at Dockerfile instruction %d", [i])
}

# Rule: Require non-root USER
deny[msg] {
    not has_non_root_user
    msg := "Dockerfile must define a non-root USER"
}

has_non_root_user {
    some i
    input[i].Cmd == "user"
    user := lower(input[i].Value[0])
    user != "root"
    user != "0"
}

# Rule: Disallow passwords in ENV
deny[msg] {
    some i
    input[i].Cmd == "env"
    some value in input[i].Value
    contains(lower(value), "password=")
    msg := "Do not store passwords in Dockerfile ENV instructions"
}

# Rule: Disallow secrets in ENV
deny[msg] {
    some i
    input[i].Cmd == "env"
    some value in input[i].Value
    contains(lower(value), "secret=")
    msg := "Do not store secrets in Dockerfile ENV instructions"
}

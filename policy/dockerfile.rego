package main

deny contains msg if {
    some i
    input[i].Cmd == "from"
    lower(input[i].Value[0]) == "latest"
    msg := "Docker base image must not use the latest tag"
}

deny contains msg if {
    some i
    input[i].Cmd == "add"
    msg := sprintf(
        "Use COPY instead of ADD at Dockerfile instruction %d",
        [i]
    )
}

deny contains msg if {
    not has_non_root_user
    msg := "Dockerfile must define a non-root USER"
}

has_non_root_user if {
    some i
    input[i].Cmd == "user"
    user := lower(input[i].Value[0])
    user != "root"
    user != "0"
}

deny contains msg if {
    some i
    input[i].Cmd == "env"
    some value in input[i].Value
    contains(lower(value), "password=")
    msg := "Do not store passwords in Dockerfile ENV instructions"
}

deny contains msg if {
    some i
    input[i].Cmd == "env"
    some value in input[i].Value
    contains(lower(value), "secret=")
    msg := "Do not store secrets in Dockerfile ENV instructions"
}

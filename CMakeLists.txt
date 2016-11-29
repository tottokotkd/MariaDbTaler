cmake_minimum_required(VERSION 3.6)
project(MariaDbTaler)

set(SOURCE_FILES
        Sources/MariaDbDriver.swift
        Package.swift)

set(SWIFT_COMMAND
        swift build
        -Xlinker -L/usr/local/lib
        -Xcc -I/usr/local/include
        -Xswiftc -lmysqlclient)

add_custom_target(maria
        COMMAND ${SWIFT_COMMAND}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        SOURCES ${SOURCE_FILES})
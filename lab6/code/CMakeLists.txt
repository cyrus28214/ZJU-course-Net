cmake_minimum_required (VERSION 3.20)
project (Lab6)

# generate complile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(client
    client/client.cpp
    client/func.cpp
)

target_include_directories(client PRIVATE client/)
target_link_libraries(client PRIVATE pthread)

add_executable(server
    server/server.cpp
)

target_include_directories(server PRIVATE server/)
target_link_libraries(server PRIVATE pthread)
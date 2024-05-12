set(PROJECT z23_bringup)

cmake_minimum_required(VERSION 3.12)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

function(embed_resource resource_file_name source_file_name variable_name)
    file(READ ${resource_file_name} hex_content HEX)

    string(REPEAT "[0-9a-f]" 32 column_pattern)
    string(REGEX REPLACE "(${column_pattern})" "\\1\n" content "${hex_content}")

    string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1, " content "${content}")

    string(REGEX REPLACE ", $" "" content "${content}")

    set(array_definition "static const unsigned char ${variable_name}[] =\n{\n${content}\n};")

    set(source "// Auto generated file.\n${array_definition}\n")

    file(WRITE "${source_file_name}" "${source}")
endfunction()

include(CheckIPOSupported)

project(${PROJECT} C CXX ASM)
pico_sdk_init()

add_executable(${PROJECT} src/main.c)
add_custom_command(#$TARGET ${PROJECT}
    #PRE_BUILD
    OUTPUT pre-build.stamp
    COMMAND ../zasm/zasm ../src/test.S -o ../meminit.bin
    COMMAND rm -rf ../*.lst
    COMMAND "${CMAKE_COMMAND}"
            -Dresource_file_name=../meminit.bin
            -Dsource_file_name=../src/rom.h
            -Dvariable_name=rom
            -DCMAKE_CURRENT_SORUCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
            -P "${CMAKE_CURRENT_SOURCE_DIR}/embed_rom.cmake"
    COMMAND "${CMAKE_COMMAND}" -E touch pre-build.stamp
    # WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
add_custom_target(pre-build DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/pre-build.stamp")
add_dependencies(${PROJECT} pre-build)
add_custom_command(TARGET ${PROJECT}
    PRE_BUILD
    COMMAND "${CMAKE_COMMAND}" -E remove pre-build.stamp
)

check_ipo_supported(RESULT supported OUTPUT error)
# Enable LTO
if(supported)
    message(STATUS "IPO / LTO enabled")
    set_property(TARGET ${PROJECT} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
else()
    message(STATUS "IPO / LTO not supported: <${error}>")
endif()
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffunction-sections -Wl,--gc-sections")

target_link_libraries(${PROJECT} pico_stdlib)

pico_enable_stdio_usb(${PROJECT} 1)
pico_enable_stdio_uart(${PROJECT} 0)
pico_add_extra_outputs(${PROJECT})


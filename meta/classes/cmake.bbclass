# This software is a part of ISAR.
# Copyright (C) 2017 Mixed-Mode GmbH


# When inheriting in non cross context
# nothing has to be done here.
do_generate_cmake_toolchain_file() {
    :
}

do_generate_cmake_toolchain_file_class-cross() {
    cat > ${EXTRACTDIR}/toolchain.cmake <<EOF
# this one is important
SET(CMAKE_SYSTEM_NAME Linux)
#this one not so much
SET(CMAKE_SYSTEM_VERSION 1)

# specify the cross compiler
SET(CMAKE_C_COMPILER   ${TARGET_PREFIX}-gcc)
SET(CMAKE_CXX_COMPILER ${TARGET_PREFIX}-g++)

# where is the target environment
SET(CMAKE_PREFIX_PATH /usr/lib/${TARGET_PREFIX} /usr/include/${TARGET_PREFIX} )

# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF
}
addtask do_generate_cmake_toolchain_file after do_dh_make before do_build
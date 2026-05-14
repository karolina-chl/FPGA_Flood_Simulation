#!/bin/sh
#SBATCH --time=00:15:00
#SBATCH --nodes=1

TEST_FILE_PATH="test_files"

make flood

./flood $(< ${TEST_FILE_PATH}/small_dam.in)

./flood $(< ${TEST_FILE_PATH}/small_mountains.in)

./flood $(< ${TEST_FILE_PATH}/tiny_dam.in)

./flood $(< ${TEST_FILE_PATH}/tiny_mountains.in)

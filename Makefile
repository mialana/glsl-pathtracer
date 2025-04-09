format: ./src
	find . -path ./include -prune -o -type f \( -iname '*.h' -o -iname '*.cpp' \) -print | xargs clang-format -i
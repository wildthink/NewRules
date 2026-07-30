# About Package Project Tool
default:
    @echo '{{ style("warning") }}Workspace Project Tool Commands{{ NORMAL }}'
    @echo "Justfile @" $PWD
    @echo ""
    @just --list

release:
	swift build -c release --product clone
	mv .build/release/clone .

# make

build:
	swift build

update:
	swift package update

release:
	swift build -c release

run:
	swift run

# install: release
# 	install	
format:
	swift-format format --in-place --recursive "${PWD}/MachOView/Sources/"
	swift-format format --in-place --recursive "${PWD}/MachOView/Tests/"
	swift-format format --in-place "${PWD}/MachOView/Package.swift"

test:
	swift test

clean:
	rm -rf build
		

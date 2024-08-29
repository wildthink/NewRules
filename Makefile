
clone: .build/debug/clone
	mv .build/debug/clone .

release: .build/release/clone
	mv .build/release/clone .

.build/debug/clone:
	swift build --product clone

.build/release/clone:
	swift build -c release --product clone


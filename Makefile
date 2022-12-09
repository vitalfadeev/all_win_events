all:
	dub build

clean:
	rmdir /Q /S .dub
	del /Q *.exe
	del /Q *.pdb
	del /Q *.log
	del /Q mixins.d
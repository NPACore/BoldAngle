dist/MultiTiltRemote.exe: MultiTiltRemote.py
	test -r dist/MultiTiltRemote/ && rm -r dist/MultiTiltRemote/ || :
	docker run -v "$(PWD):/src/" cdrx/pyinstaller-windows "pyinstaller --onefile MultiTiltRemote.py"
	#docker run -v "$(PWD):/src/" cdrx/pyinstaller-windows

linux/dist/MultiTiltRemote: MultiTiltRemote.py
	mkdir -p linux
	pyinstaller --onefile --distpat linux/dist --workpath linux/build --specpath linux/ MultiTiltRemote.py

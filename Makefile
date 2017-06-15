all:

install:
	mkdir -p ~/bin
	cp mvn-download-artifact.sh ~/bin/mvn-download-artifact
	cp mvn-parse-pom.py ~/bin/mvn-parse-pom
	cp mvn-upload-artifact.sh ~/bin/mvn-upload-artifact
	dos2unix ~/bin/mvn-*


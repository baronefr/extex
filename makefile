demo:
	cp -r example/inputs .

clean-demo: main.tex test.tex
	rm -f main.tex test.tex

demo-minimal:
	cp -r example-minimal/* .

clean-demo-minimal: main.tex test.tex
	rm -f main.tex test.tex

clean-tex:
	rm main.*

clean-run:
	rm -rf .extex.build
	rm -f extex*.tex
	rm -rf extex-svg/ extex-pdf/

install:
	chmod +x extex.sh
	cp extex.sh ~/.local/bin/extex
	extex --help